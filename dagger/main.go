package main

import (
	"context"
	"dagger/pipely/internal/dagger"
	"fmt"

	"github.com/containerd/platforms"
)

const (
	// https://hub.docker.com/_/golang/tags?name=1.24
	golangVersion = "1.24.2@sha256:30baaea08c5d1e858329c50f29fe381e9b7d7bced11a0f5f1f69a1504cdfbf5e"

	// https://github.com/mattn/goreman/releases
	goremanVersion = "v0.3.16"

	// https://github.com/nabsul/tls-exterminator
	tlsExterminatorVersion = "4226223f2380319e73300bc7d14fd652c56c6b4e"
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
	// +default="7.7.0@sha256:3677549b54558d31781d7bc5cf7eedb7dc529c8c2bdd658b5051bee38bddf716"
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
		WithExec([]string{"go", "install", "github.com/mattn/goreman@" + goremanVersion}).
		File("/go/bin/goreman")

	procfile := fmt.Sprintf(`pipely: docker-varnish-entrypoint
app: tls-exterminator %s
feeds: tls-exterminator %s
assets: tls-exterminator %s
`, m.AppProxy.TlsExterminator, m.FeedsProxy.TlsExterminator, m.AssetsProxy.TlsExterminator)

	return m.Varnish.
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
		WithFile("/usr/local/bin/tls-exterminator", tlsExterminator).
		WithFile("/usr/local/bin/goreman", goreman).
		WithNewFile("/Procfile", procfile).
		WithWorkdir("/").
		WithEntrypoint([]string{"goreman", "--set-ports=false", "start"})
}

func (m *Pipely) withVarnishConfig(c *dagger.Container) *dagger.Container {
	return c.
		WithFile("/etc/varnish/default.vcl", m.Source.File("vcl/pipedream.changelog.com.vcl"))
}

// Test container with various useful tools - use `just` as the starting point
func (m *Pipely) Test(ctx context.Context) *dagger.Container {
	p, _ := dag.DefaultPlatform(ctx)
	platform := platforms.MustParse(string(p))

	var altArchitecture string
	switch platform.Architecture {
	case "amd64":
		altArchitecture = "x86_64"
	case "arm64":
		altArchitecture = "aarch64"
	default:
		altArchitecture = platform.Architecture
	}

	// https://github.com/Orange-OpenSource/hurl/releases
	hurlArchive := dag.HTTP("https://github.com/Orange-OpenSource/hurl/releases/download/6.1.1/hurl-6.1.1-" + altArchitecture + "-unknown-linux-gnu.tar.gz")

	return m.withVarnishConfig(
		m.app().
			WithUser("root").
			WithEnvVariable("DEBIAN_FRONTEND", "noninteractive").
			WithEnvVariable("TERM", "xterm-256color").
			WithExec([]string{"apt-get", "update"}).
			WithExec([]string{"mkdir", "-p", "/opt/hurl"}).
			WithMountedFile("/opt/hurl.tar.gz", hurlArchive).
			WithExec([]string{"tar", "-zxvf", "/opt/hurl.tar.gz", "-C", "/opt/hurl", "--strip-components=1"}).
			WithExec([]string{"ln", "-sf", "/opt/hurl/bin/hurl", "/usr/local/bin/hurl"}).
			WithExec([]string{"apt-get", "install", "--yes", "curl"}).
			WithExec([]string{"curl", "--version"}).
			WithExec([]string{"apt-get", "install", "--yes", "libxml2"}).
			WithExec([]string{"hurl", "--version"}).
			WithExec([]string{"bash", "-c", "curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin"}).
			WithFile("/justfile", m.Source.File("container.justfile")).
			WithExec([]string{"just"}).
			WithDirectory("/test", m.Source.Directory("test")),
	)
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

	// github.com/xxxserxxx/gotop
	gotop := m.Golang.
		WithExec([]string{"go", "install", "github.com/xxxserxxx/gotop/v4/cmd/gotop@bba42d08624edee8e339ac98c1a9c46810414f78"}).
		File("/go/bin/gotop")

	p, _ := dag.DefaultPlatform(ctx)
	platform := platforms.MustParse(string(p))
	// https://github.com/hatoo/oha/releases
	oha := dag.HTTP("https://github.com/hatoo/oha/releases/download/v1.8.0/oha-linux-" + platform.Architecture)

	return m.Test(ctx).
		WithExec([]string{"apt-get", "install", "--yes", "tmux"}).
		WithExec([]string{"tmux", "-V"}).
		WithExec([]string{"apt-get", "install", "--yes", "htop"}).
		WithExec([]string{"htop", "-V"}).
		WithExec([]string{"apt-get", "install", "--yes", "procps"}).
		WithExec([]string{"ps", "-V"}).
		WithExec([]string{"apt-get", "install", "--yes", "neovim"}).
		WithExec([]string{"nvim", "--version"}).
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
	return m.withVarnishConfig(m.app()).
		WithLabel("org.opencontainers.image.url", "https://pipely.tech").
		WithLabel("org.opencontainers.image.description", "A single-purpose, single-tenant CDN running Varnish Cache (open source) on Fly.io").
		WithLabel("org.opencontainers.image.authors", "@"+registryUsername).
		WithRegistryAuth(registryAddress, registryUsername, registryPassword).
		Publish(ctx, image+":"+m.Tag)
}
