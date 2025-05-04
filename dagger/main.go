package main

import (
	"context"
	"dagger/pipely/internal/dagger"
	"fmt"

	"github.com/containerd/platforms"
)

const (
	// https://hub.docker.com/_/golang/tags?name=1.24
	golangVersion = "1.24.4@sha256:db5d0afbfb4ab648af2393b92e87eaae9ad5e01132803d80caef91b5752d289c"

	// https://github.com/mattn/goreman/releases
	goremanVersion = "0.3.16"

	// https://github.com/nabsul/tls-exterminator
	tlsExterminatorVersion = "4226223f2380319e73300bc7d14fd652c56c6b4e"

	// https://hub.docker.com/r/timberio/vector/tags?name=debian
	vectorVersion = "0.47.0-debian@sha256:a7c96178b5dd0800bb6a4a58559b61bca919a43979cd4c3ef12399175eea5ac7"

	// https://github.com/Orange-OpenSource/hurl/releases
	hurlVersion = "6.1.1"

	// https://github.com/hatoo/oha/releases
	ohaVersion = "1.8.0"
)

type Pipely struct {
	// Golang container
	Golang *dagger.Container
	// Varnish container
	Varnish *dagger.Container
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
	// +default="7.7.1@sha256:18c3eeba5e929068aa46fd1b8de8345dc3c4b488d957a0953fff9916341b4587"
	varnishVersion string,

	// +default=9000
	varnishPort int,

	// +default="60s"
	berespTtl string,

	// +default="24h"
	berespGrace string,

	// +default="5000:changelog-2025-05-05.fly.dev:"
	appProxy string,

	// +default="5010:feeds.changelog.place:"
	feedsProxy string,

	// +default="5020:changelog.place:cdn2.changelog.com"
	assetsProxy string,
) (*Pipely, error) {
	pipely := &Pipely{
		Golang: dag.Container().From("golang:" + golangVersion),
		Tag:    tag,
		Source: source,
	}

	pipely.Varnish = dag.Container().From("varnish:"+varnishVersion).
		WithEnvVariable("VARNISH_HTTP_PORT", fmt.Sprintf("%d", varnishPort)).
		WithExposedPort(varnishPort).
		WithEnvVariable("BERESP_TTL", berespTtl).
		WithEnvVariable("BERESP_GRACE", berespGrace)

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

	goreman := m.Golang.
		WithExec([]string{"go", "install", "github.com/mattn/goreman@v" + goremanVersion}).
		File("/go/bin/goreman")

	vectorContainer := dag.Container().From("timberio/vector:" + vectorVersion)

	procfile := fmt.Sprintf(`varnish: docker-varnish-entrypoint
app: tls-exterminator %s
feeds: tls-exterminator %s
assets: tls-exterminator %s
logs: varnish-json-response | vector
`, m.AppProxy.TlsExterminator, m.FeedsProxy.TlsExterminator, m.AssetsProxy.TlsExterminator)

	return m.Varnish.
		WithUser("root").
		With(func(c *dagger.Container) *dagger.Container {
			return c.WithEnvVariable("BACKEND_APP_FQDN", m.AppProxy.Fqdn).
				WithEnvVariable("BACKEND_APP_HOST", "localhost").
				WithEnvVariable("BACKEND_APP_PORT", m.AppProxy.Port).
				WithEnvVariable("BACKEND_FEEDS_FQDN", m.FeedsProxy.Fqdn).
				WithEnvVariable("BACKEND_FEEDS_HOST", "localhost").
				WithEnvVariable("BACKEND_FEEDS_PORT", m.FeedsProxy.Port).
				WithEnvVariable("BACKEND_ASSETS_FQDN", m.AssetsProxy.Fqdn).
				WithEnvVariable("BACKEND_ASSETS_HOST", "localhost").
				WithEnvVariable("BACKEND_ASSETS_PORT", m.AssetsProxy.Port).
				WithEnvVariable("ASSETS_HOST", m.AssetsProxy.Host)
		}).
		WithFile("/usr/local/bin/tls-exterminator", tlsExterminator).
		WithFile("/usr/local/bin/goreman", goreman).
		With(func(c *dagger.Container) *dagger.Container {
			return c.WithFile("/usr/bin/vector", vectorContainer.File("/usr/bin/vector")).
				WithDirectory("/usr/share/vector", vectorContainer.Directory("/usr/share/vector")).
				WithDirectory("/usr/share/doc/vector", vectorContainer.Directory("/usr/share/doc/vector")).
				WithDirectory("/etc/vector", vectorContainer.Directory("/etc/vector")).
				WithDirectory("/var/lib/vector", vectorContainer.Directory("/var/lib/vector")).
				WithExec([]string{"vector", "--version"})
		}).
		WithNewFile("/Procfile", procfile).
		WithWorkdir("/").
		WithEntrypoint([]string{"goreman", "--set-ports=false", "start"})
}

func (m *Pipely) withConfigs(c *dagger.Container) *dagger.Container {
	return m.withVectorConfig(
		m.withVarnishJsonResponse(
			m.withVarnishConfig(c)))
}

func (m *Pipely) withVarnishConfig(c *dagger.Container) *dagger.Container {
	return c.
		WithFile(
			"/etc/varnish/default.vcl",
			m.Source.File("varnish/pipedream.changelog.com.vcl"))
}

func (m *Pipely) withVarnishJsonResponse(c *dagger.Container) *dagger.Container {
	return c.
		WithFile(
			"/usr/local/bin/varnish-json-response",
			m.Source.File("varnish/varnish-json-response.bash"),
			dagger.ContainerWithFileOpts{
				Permissions: 755,
			})
}

func (m *Pipely) withVectorConfig(c *dagger.Container) *dagger.Container {
	return c.
		WithFile(
			"/etc/vector/vector.yaml",
			m.Source.File("vector/pipedream.changelog.com.yaml")).
		WithExec([]string{"vector", "validate", "--skip-healthchecks"})
}

// Test container with various useful tools - use `just` as the starting point
func (m *Pipely) Test(ctx context.Context) *dagger.Container {
	hurlArchive := dag.HTTP("https://github.com/Orange-OpenSource/hurl/releases/download/" + hurlVersion + "/hurl-" + hurlVersion + "-" + altArchitecture(ctx) + "-unknown-linux-gnu.tar.gz")

	return m.withConfigs(
		m.app().
			WithEnvVariable("DEBIAN_FRONTEND", "noninteractive").
			WithEnvVariable("TERM", "xterm-256color").
			WithExec([]string{"apt-get", "update"}).
			With(func(c *dagger.Container) *dagger.Container {
				return c.WithExec([]string{"mkdir", "-p", "/opt/hurl"}).
					WithMountedFile("/opt/hurl.tar.gz", hurlArchive).
					WithExec([]string{"tar", "-zxvf", "/opt/hurl.tar.gz", "-C", "/opt/hurl", "--strip-components=1"}).
					WithExec([]string{"ln", "-sf", "/opt/hurl/bin/hurl", "/usr/local/bin/hurl"}).
					WithExec([]string{"apt-get", "install", "--yes", "curl"}).
					WithExec([]string{"curl", "--version"}).
					WithExec([]string{"apt-get", "install", "--yes", "libxml2"}).
					WithExec([]string{"hurl", "--version"})
			}).
			With(func(c *dagger.Container) *dagger.Container {
				return c.WithExec([]string{"bash", "-c", "curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin"}).
					WithFile("/justfile", m.Source.File("container.justfile")).
					WithExec([]string{"just"})
			}).
			WithDirectory("/test", m.Source.Directory("test")),
	)
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
	pipely, err := m.Test(ctx).
		AsService(dagger.ContainerAsServiceOpts{UseEntrypoint: true}).
		Start(ctx)
	if err != nil {
		panic(err)
	}

	return m.Test(ctx).
		WithServiceBinding("pipely", pipely).
		WithExec([]string{"just", "test-acceptance-local", "--variable", "host=http://pipely:9000", "--verbose"})
}

// Test acceptance report
func (m *Pipely) TestAcceptanceReport(ctx context.Context) *dagger.Directory {
	return m.TestAcceptance(ctx).Directory("/var/opt/hurl/test-acceptance-local")
}

// Debug container with various useful tools - use `just` as the starting point
func (m *Pipely) Debug(ctx context.Context) *dagger.Container {
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

	p, _ := dag.DefaultPlatform(ctx)
	platform := platforms.MustParse(string(p))
	oha := dag.HTTP("https://github.com/hatoo/oha/releases/download/v" + ohaVersion + "/oha-linux-" + platform.Architecture)

	return m.Test(ctx).
		WithExec([]string{"apt-get", "install", "--yes", "tmux"}).
		WithExec([]string{"tmux", "-V"}).
		WithExec([]string{"apt-get", "install", "--yes", "htop"}).
		WithExec([]string{"htop", "-V"}).
		WithExec([]string{"apt-get", "install", "--yes", "procps"}).
		WithExec([]string{"ps", "-V"}).
		WithExec([]string{"apt-get", "install", "--yes", "neovim"}).
		WithExec([]string{"nvim", "--version"}).
		WithExec([]string{"apt-get", "install", "--yes", "jq"}).
		WithExec([]string{"jq", "--version"}).
		WithFile("/usr/local/bin/httpstat", httpstat).
		WithExec([]string{"httpstat", "-v"}).
		WithFile("/usr/local/bin/sasqwatch", sasqwatch).
		WithExec([]string{"sasqwatch", "-v"}).
		WithFile("/usr/local/bin/gotop", gotop).
		WithExec([]string{"gotop", "-v"}).
		WithFile("/usr/local/bin/oha", oha, dagger.ContainerWithFileOpts{
			Permissions: 755,
		}).
		WithExec([]string{"oha", "--version"})
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
	return m.withConfigs(m.app()).
		WithLabel("org.opencontainers.image.url", "https://pipely.tech").
		WithLabel("org.opencontainers.image.description", "A single-purpose, single-tenant CDN running Varnish Cache (open source) on Fly.io").
		WithLabel("org.opencontainers.image.authors", "@"+registryUsername).
		WithRegistryAuth(registryAddress, registryUsername, registryPassword).
		Publish(ctx, image+":"+m.Tag)
}
