package main

import (
	"context"
	"dagger/pipely/internal/dagger"
	"errors"
	"fmt"

	"github.com/containerd/platforms"
)

const (
	// https://hub.docker.com/_/golang/tags?name=1.24
	golangVersion = "1.24.7@sha256:2c5f7a0c252a17cf6aa30ddee15caa0f485ee29410a6ea64cddb62eea2b07bdf"

	// https://github.com/nabsul/tls-exterminator
	tlsExterminatorVersion = "93583389e8bab9b519466d95e69e594682d8de5b"

	// https://github.com/DarthSim/overmind/releases
	overmindVersion = "2.5.1"

	// https://hub.docker.com/r/timberio/vector/tags?name=debian
	vectorVersion = "0.49.0-debian@sha256:6a56f8ee78e014d53a32fd7c6f6be9c18244fe861d938932fad8d6e65d3f5926"

	// https://github.com/Orange-OpenSource/hurl/releases
	hurlVersion = "7.0.0"

	// https://github.com/hatoo/oha/releases
	ohaVersion = "1.10.0"
)

type Env int

const (
	Dev Env = iota
	Test
	Prod
)

type Pipely struct {
	// Golang container
	Golang *dagger.Container
	// Varnish container
	Varnish *dagger.Container
	// Varnish PURGE token
	VarnishPurgeToken *dagger.Secret
	// Source code
	Source *dagger.Directory
	// Container image tag
	Tag string
	// App proxy
	AppProxy *Proxy
	// Feeds proxy
	FeedsProxy *Proxy
	// Assets proxy
	AssetsProxy *Proxy
}

func New(
	ctx context.Context,

	// +defaultPath="./"
	source *dagger.Directory,

	// +default="dev"
	tag string,

	// https://hub.docker.com/_/varnish/tags
	// +default="7.7.3@sha256:9310a9cbdb61b632afb83fff44fa7c71b90f987a0587d23fc159e3b22334d577"
	varnishVersion string,

	// +default=9000
	varnishPort int,

	// +default="60s"
	berespTtl string,

	// +default="24h"
	berespGrace string,

	// +optional
	purgeToken *dagger.Secret,

	// +default="5000:changelog-2025-05-05.fly.dev:"
	appProxy string,

	// +default="5010:feeds.changelog.place:"
	feedsProxy string,

	// +default="5020:changelog.place:cdn.changelog.com"
	assetsProxy string,

	// https://ui.honeycomb.io/changelog/datasets/pipely/overview
	// +default="pipely"
	honeycombDataset string,

	// +optional
	honeycombApiKey *dagger.Secret,

	// https://dev.maxmind.com/geoip/updating-databases/#directly-downloading-databases
	// +optional
	maxMindAuth *dagger.Secret,

	// +default="us-east-1"
	awsRegion string,

	// +optional
	awsLocalProductionS3BucketSuffix string,

	// +optional
	awsAccessKeyId *dagger.Secret,

	// +optional
	awsSecretAccessKey *dagger.Secret,
) (*Pipely, error) {
	pipely := &Pipely{
		Golang:            dag.Container().From("golang:" + golangVersion),
		Tag:               tag,
		Source:            source,
		VarnishPurgeToken: purgeToken,
	}

	pipely.Varnish = dag.Container().From("varnish:"+varnishVersion).
		WithUser("root"). // a bunch of commands fail if we are not root, so YOLO & sandbox with Firecracker, Kata Containers, etc.
		WithEnvVariable("VARNISH_HTTP_PORT", fmt.Sprintf("%d", varnishPort)).
		WithExposedPort(varnishPort).
		WithEnvVariable("BERESP_TTL", berespTtl).
		WithEnvVariable("BERESP_GRACE", berespGrace).
		WithEnvVariable("HONEYCOMB_DATASET", honeycombDataset).
		WithEnvVariable("AWS_REGION", awsRegion)

	if pipely.VarnishPurgeToken != nil {
		pipely.Varnish = pipely.Varnish.
			WithSecretVariable("PURGE_TOKEN", pipely.VarnishPurgeToken)
	}

	if honeycombApiKey != nil {
		pipely.Varnish = pipely.Varnish.
			WithSecretVariable("HONEYCOMB_API_KEY", honeycombApiKey)
	}

	if awsAccessKeyId != nil {
		if awsSecretAccessKey == nil {
			return nil, errors.New("--aws-secret-access-key is required")
		}

		pipely.Varnish = pipely.Varnish.
			WithSecretVariable("AWS_ACCESS_KEY_ID", awsAccessKeyId).
			WithSecretVariable("AWS_SECRET_ACCESS_KEY", awsSecretAccessKey).
			WithEnvVariable("S3_BUCKET_SUFFIX", awsLocalProductionS3BucketSuffix)
	}

	if maxMindAuth != nil {
		geoLite2CityArchive := dag.HTTP("https://download.maxmind.com/geoip/databases/GeoLite2-City/download?suffix=tar.gz", dagger.HTTPOpts{
			AuthHeader: maxMindAuth,
		})
		pipely.Varnish = pipely.Varnish.
			WithExec([]string{"mkdir", "-p", "/usr/local/share/GeoIP"}).
			WithMountedFile("/tmp/geolite2-city.tar.gz", geoLite2CityArchive).
			WithExec([]string{"tar", "-zxvf", "/tmp/geolite2-city.tar.gz", "-C", "/usr/local/share/GeoIP", "--strip-components=1"}).
			WithExec([]string{"ls", "/usr/local/share/GeoIP/GeoLite2-City.mmdb"}).
			WithEnvVariable("GEOIP_ENRICHED", "true")
	}

	app, err := NewProxy(appProxy)
	if err != nil {
		return nil, err
	}
	pipely.AppProxy = app

	feeds, err := NewProxy(feedsProxy)
	if err != nil {
		return nil, err
	}
	pipely.FeedsProxy = feeds

	assets, err := NewProxy(assetsProxy)
	if err != nil {
		return nil, err
	}
	pipely.AssetsProxy = assets

	return pipely, nil
}

func (m *Pipely) app() *dagger.Container {
	tlsExterminator := m.Golang.
		WithExec([]string{"go", "install", "github.com/nabsul/tls-exterminator@" + tlsExterminatorVersion}).
		File("/go/bin/tls-exterminator")

	overmind := m.Golang.
		WithExec([]string{"go", "install", "github.com/DarthSim/overmind/v2@v" + overmindVersion}).
		File("/go/bin/overmind")

	vectorContainer := dag.Container().From("timberio/vector:" + vectorVersion)

	procfile := fmt.Sprintf(`varnish: docker-varnish-entrypoint
app: tls-exterminator %s
feeds: tls-exterminator %s
assets: tls-exterminator %s
logs: bash -c 'coproc VJS { varnish-json-response; }; if [ -z "${VJS_PID}" ]; then echo "ERROR: Failed to start varnish-json-response coprocess." >&2; exit 1; fi; trap "kill ${VJS_PID} 2>/dev/null" EXIT; vector <&${VJS[0]}'
`, m.AppProxy.TlsExterminator, m.FeedsProxy.TlsExterminator, m.AssetsProxy.TlsExterminator)

	return m.Varnish.
		// Configure various environment variables
		WithEnvVariable("BACKEND_APP_FQDN", m.AppProxy.Fqdn).
		WithEnvVariable("BACKEND_APP_HOST", "localhost").
		WithEnvVariable("BACKEND_APP_PORT", m.AppProxy.Port).
		WithEnvVariable("BACKEND_FEEDS_FQDN", m.FeedsProxy.Fqdn).
		WithEnvVariable("BACKEND_FEEDS_HOST", "localhost").
		WithEnvVariable("BACKEND_FEEDS_PORT", m.FeedsProxy.Port).
		WithEnvVariable("BACKEND_ASSETS_FQDN", m.AssetsProxy.Fqdn).
		WithEnvVariable("BACKEND_ASSETS_HOST", "localhost").
		WithEnvVariable("BACKEND_ASSETS_PORT", m.AssetsProxy.Port).
		WithEnvVariable("ASSETS_HOST", m.AssetsProxy.Host).
		// Add tls-exterminator
		WithFile("/usr/local/bin/tls-exterminator", tlsExterminator).
		// Prepare apt packages
		WithEnvVariable("DEBIAN_FRONTEND", "noninteractive").
		WithEnvVariable("TERM", "xterm-256color").
		WithExec([]string{"apt-get", "update"}).
		// Install tmux
		WithExec([]string{"apt-get", "install", "--yes", "tmux"}).
		WithExec([]string{"tmux", "-V"}).
		// Install vector.dev
		WithFile("/usr/bin/vector", vectorContainer.File("/usr/bin/vector")).
		WithDirectory("/usr/share/vector", vectorContainer.Directory("/usr/share/vector")).
		WithDirectory("/usr/share/doc/vector", vectorContainer.Directory("/usr/share/doc/vector")).
		WithDirectory("/etc/vector", vectorContainer.Directory("/etc/vector")).
		WithDirectory("/var/lib/vector", vectorContainer.Directory("/var/lib/vector")).
		WithExec([]string{"vector", "--version"}).
		// Install & configure overmind
		WithFile("/usr/local/bin/overmind", overmind).
		WithNewFile("/Procfile", procfile).
		WithWorkdir("/").
		WithEntrypoint([]string{"overmind", "start", "--timeout=30", "--no-port", "--auto-restart=all"})
}

func (m *Pipely) withConfigs(c *dagger.Container, env Env) *dagger.Container {
	return m.withVectorConfig(
		m.withVarnishJsonResponse(
			m.withVarnishConfig(c),
		),
		env)
}

func (m *Pipely) withVarnishConfig(c *dagger.Container) *dagger.Container {
	return c.
		WithDirectory(
			"/etc/varnish",
			m.Source.Directory("varnish/vcl"))
}

func (m *Pipely) withVarnishJsonResponse(c *dagger.Container) *dagger.Container {
	return c.WithFile(
		"/usr/local/bin/varnish-json-response",
		m.Source.File("varnish/varnish-json-response.bash"),
		dagger.ContainerWithFileOpts{
			Permissions: 755,
		})
}

func (m *Pipely) withVectorConfig(c *dagger.Container, env Env) *dagger.Container {
	ctx := context.Background()

	containerWithVectorConfigs := c.
		WithEnvVariable("VECTOR_CONFIG", "/etc/vector/*.yaml").
		WithFile(
			"/etc/vector/vector.yaml",
			m.Source.File("vector/pipedream.changelog.com/default.yaml"))

	if env != Prod {
		containerWithVectorConfigs = containerWithVectorConfigs.
			WithFile(
				"/etc/vector/debug_varnish.yaml",
				m.Source.File("vector/pipedream.changelog.com/debug_varnish.yaml"))
	}

	geoipEnriched, _ := c.EnvVariable(ctx, "GEOIP_ENRICHED")
	if geoipEnriched == "true" {
		containerWithVectorConfigs = containerWithVectorConfigs.
			WithFile(
				"/etc/vector/geoip.yaml",
				m.Source.File("vector/pipedream.changelog.com/geoip.yaml"))
	}

	if geoipEnriched == "true" && env != Prod {
		containerWithVectorConfigs = containerWithVectorConfigs.
			WithFile(
				"/etc/vector/debug_varnish_geoip.yaml",
				m.Source.File("vector/pipedream.changelog.com/debug_varnish_geoip.yaml")).
			WithFile(
				"/etc/vector/debug_s3.yaml",
				m.Source.File("vector/pipedream.changelog.com/debug_s3.yaml"))
	}

	return containerWithVectorConfigs.
		WithExec([]string{"vector", "validate", "--skip-healthchecks"})
}

// Test container with various useful tools - use `just` as the starting point
func (m *Pipely) Test(ctx context.Context) *dagger.Container {
	return m.withConfigs(
		m.local(ctx),
		Test)
}

// Production container for local use with various useful debugging tools - use `just` as the starting point
func (m *Pipely) LocalProduction(ctx context.Context) *dagger.Container {
	return m.withConfigs(
		m.local(ctx),
		Dev)
}

func (m *Pipely) local(ctx context.Context) *dagger.Container {
	hurlArchive := dag.HTTP("https://github.com/Orange-OpenSource/hurl/releases/download/" + hurlVersion + "/hurl-" + hurlVersion + "-" + altArchitecture(ctx) + "-unknown-linux-gnu.tar.gz")

	// https://github.com/davecheney/httpstat
	httpstat := m.Golang.
		WithExec([]string{"go", "install", "github.com/davecheney/httpstat@v1.2.1"}).
		File("/go/bin/httpstat")

	// https://github.com/fabio42/sasqwatch
	sasqwatch := m.Golang.
		WithExec([]string{"go", "install", "github.com/fabio42/sasqwatch@8564c29ceaa03d5211b8b6d7a3012f9acf691fd1"}).
		File("/go/bin/sasqwatch")

	// https://github.com/xxxserxxx/gotop
	gotop := m.Golang.
		WithExec([]string{"go", "install", "github.com/xxxserxxx/gotop/v4/cmd/gotop@bba42d08624edee8e339ac98c1a9c46810414f78"}).
		File("/go/bin/gotop")

	// https://github.com/showwin/speedtest-go
	speedtest := m.Golang.
		WithExec([]string{"go", "install", "github.com/showwin/speedtest-go@v1.7.10"}).
		File("/go/bin/speedtest-go")

	p, _ := dag.DefaultPlatform(ctx)
	platform := platforms.MustParse(string(p))
	oha := dag.HTTP("https://github.com/hatoo/oha/releases/download/v" + ohaVersion + "/oha-linux-" + platform.Architecture)

	return m.app().
		// Install hurl.dev + dependencies (curl & libxml2)
		WithExec([]string{"apt-get", "install", "--yes", "curl"}).
		WithExec([]string{"curl", "--version"}).
		WithExec([]string{"apt-get", "install", "--yes", "libxml2"}).
		WithExec([]string{"mkdir", "-p", "/opt/hurl"}).
		WithMountedFile("/opt/hurl.tar.gz", hurlArchive).
		WithExec([]string{"tar", "-zxvf", "/opt/hurl.tar.gz", "-C", "/opt/hurl", "--strip-components=1"}).
		WithExec([]string{"ln", "-sf", "/opt/hurl/bin/hurl", "/usr/local/bin/hurl"}).
		WithExec([]string{"hurl", "--version"}).
		// Install htop
		WithExec([]string{"apt-get", "install", "--yes", "htop"}).
		WithExec([]string{"htop", "-V"}).
		// Install procps
		WithExec([]string{"apt-get", "install", "--yes", "procps"}).
		WithExec([]string{"ps", "-V"}).
		// Install neovim
		WithExec([]string{"apt-get", "install", "--yes", "neovim"}).
		WithExec([]string{"nvim", "--version"}).
		// Install jq
		WithExec([]string{"apt-get", "install", "--yes", "jq"}).
		WithExec([]string{"jq", "--version"}).
		// Install httpstat
		WithFile("/usr/local/bin/httpstat", httpstat).
		WithExec([]string{"httpstat", "-v"}).
		// Install sasqwatch
		WithFile("/usr/local/bin/sasqwatch", sasqwatch).
		WithExec([]string{"sasqwatch", "--version"}).
		// Install gotop
		WithFile("/usr/local/bin/gotop", gotop).
		WithExec([]string{"gotop", "--version"}).
		// Install speedtest-go
		WithFile("/usr/local/bin/speedtest-go", speedtest).
		WithExec([]string{"speedtest-go", "--version"}).
		// Install oha
		WithFile("/usr/local/bin/oha", oha, dagger.ContainerWithFileOpts{
			Permissions: 755,
		}).
		WithExec([]string{"oha", "--version"}).
		// Install just.systems
		WithExec([]string{"bash", "-c", "curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin"}).
		WithFile("/justfile", m.Source.File("container/justfile")).
		WithExec([]string{"just"}).
		// Add test directory
		WithDirectory("/test", m.Source.Directory("test")).
		// Add dics directory
		WithDirectory("/docs", m.Source.Directory("docs")).
		// Add welcome message
		WithMountedFile("/tmp/welcome.bashrc", m.Source.File("container/welcome.bashrc")).
		WithExec([]string{"bash", "-c", "cat /tmp/welcome.bashrc >> ~/.bashrc"})
}

func altArchitecture(ctx context.Context) string {
	p, _ := dag.DefaultPlatform(ctx)
	platform := platforms.MustParse(string(p))

	switch platform.Architecture {
	case "amd64":
		return "x86_64"
	case "arm64":
		return "aarch64"
	default:
		return platform.Architecture
	}
}

// Test VCL via VTC
func (m *Pipely) TestVarnish(ctx context.Context) *dagger.Container {
	return m.Test(ctx).WithExec([]string{"just", "test-vtc"})
}

// Test acceptance
func (m *Pipely) TestAcceptance(ctx context.Context) *dagger.Container {
	pipely := m.Test(ctx).
		AsService(dagger.ContainerAsServiceOpts{UseEntrypoint: true})

	testAcceptanceCmd := []string{"just", "test-acceptance-local", "--variable", "proto=http", "--variable", "host=pipely:9000"}
	if m.VarnishPurgeToken != nil {
		purgeToken, err := m.VarnishPurgeToken.Plaintext(ctx)
		if err != nil {
			panic(err)
		}
		testAcceptanceCmd = append(testAcceptanceCmd, "--variable", "purge_token="+purgeToken)
	}

	return m.Test(ctx).
		WithServiceBinding("pipely", pipely).
		WithServiceBinding("www.pipely", pipely).
		WithExec(testAcceptanceCmd)
}

// Test acceptance report
func (m *Pipely) TestAcceptanceReport(ctx context.Context) *dagger.Directory {
	return m.TestAcceptance(ctx).Directory("/var/opt/hurl/test-acceptance-local")
}

// Publish app container
func (m *Pipely) Publish(
	ctx context.Context,

	// +default="ghcr.io/thechangelog/pipely"
	image string,

	// +default="ghcr.io"
	registryAddress string,

	registryUsername string,

	registryPassword *dagger.Secret,
) (string, error) {
	return m.withConfigs(m.app(), Prod).
		WithLabel("org.opencontainers.image.url", "https://pipely.tech").
		WithLabel("org.opencontainers.image.description", "A single-purpose, single-tenant CDN running Varnish Cache (open source) on Fly.io").
		WithLabel("org.opencontainers.image.authors", "@"+registryUsername).
		WithRegistryAuth(registryAddress, registryUsername, registryPassword).
		Publish(ctx, image+":"+m.Tag)
}
