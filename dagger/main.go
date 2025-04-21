package main

import (
	"context"
	"dagger/pipely/internal/dagger"
	"errors"
	"fmt"
	"strings"

	"github.com/containerd/platforms"
)

type Pipely struct {
	// Container with all dependencies wired up correctly & ready for production
	App *dagger.Container
	// Golang container
	Golang *dagger.Container
	// Varnish container
	Varnish *dagger.Container
	// Source code
	Source *dagger.Directory
	// Container image tag
	Tag string
}

func New(
	ctx context.Context,

	// +defaultPath="./"
	source *dagger.Directory,

	// +default="dev"
	tag string,

	// https://hub.docker.com/_/varnish/tags
	// +default="7.7.0@sha256:d632bc833d17a9555126205315ea4de9c634d0b05d96757b9dbab30c8430e312"
	varnishVersion string,

	// +default=9000
	varnishPort int,

	// +default="60s"
	berespTtl string,

	// +default="24h"
	berespGrace string,

	// https://hub.docker.com/_/golang/tags?name=1.23
	// +default="1.23.8@sha256:87bb94031b23532885cbda15e9a365a5805059648a87ed1b67a1352dd7360fe4"
	golangVersion string,

	// https://github.com/mattn/goreman
	// +default="v0.3.16"
	goremanVersion string,

	// https://github.com/nabsul/tls-exterminator
	// +default="4226223f2380319e73300bc7d14fd652c56c6b4e"
	tlsExterminatorVersion string,

	// +default="5000:changelog-2024-01-12.fly.dev"
	appProxy string,

	// +default="5010:feeds.changelog.place"
	feedsProxy string,
) (*Pipely, error) {
	pipely := &Pipely{
		Golang:  dag.Container().From("golang:" + golangVersion),
		Varnish: dag.Container().From("varnish:" + varnishVersion),
		Tag:     tag,
		Source:  source,
	}

	tlsExterminator := pipely.Golang.
		WithExec([]string{"go", "install", "github.com/nabsul/tls-exterminator@" + tlsExterminatorVersion}).
		File("/go/bin/tls-exterminator")

	goreman := pipely.Golang.
		WithExec([]string{"go", "install", "github.com/mattn/goreman@" + goremanVersion}).
		File("/go/bin/goreman")

	procfile := fmt.Sprintf(`pipely: docker-varnish-entrypoint
app: tls-exterminator %s
feeds: tls-exterminator %s
`, appProxy, feedsProxy)

	appPortAndFqdn := strings.Split(appProxy, ":")
	if len(appPortAndFqdn) != 2 {
		return nil, errors.New("--app-proxy must be of format 'PORT:FQDN'")
	}
	appPort := appPortAndFqdn[0]
	appFqdn := appPortAndFqdn[1]

	feedsPortAndFqdn := strings.Split(feedsProxy, ":")
	if len(feedsPortAndFqdn) != 2 {
		return nil, errors.New("--feeds-proxy must be of format 'PORT:FQDN'")
	}
	feedsPort := feedsPortAndFqdn[0]
	feedsFqdn := feedsPortAndFqdn[1]

	pipely.App = dag.Container().
		From("varnish:"+varnishVersion).
		WithEnvVariable("VARNISH_HTTP_PORT", "9000").
		WithEnvVariable("BACKEND_APP_FQDN", appFqdn).
		WithEnvVariable("BACKEND_APP_HOST", "localhost").
		WithEnvVariable("BACKEND_APP_PORT", appPort).
		WithEnvVariable("BACKEND_FEEDS_FQDN", feedsFqdn).
		WithEnvVariable("BACKEND_FEEDS_HOST", "localhost").
		WithEnvVariable("BACKEND_FEEDS_PORT", feedsPort).
		WithEnvVariable("BERESP_TTL", berespTtl).
		WithEnvVariable("BERESP_GRACE", berespGrace).
		WithExposedPort(varnishPort).
		WithFile("/etc/varnish/default.vcl", source.File("default.vcl")).
		WithFile("/usr/local/bin/tls-exterminator", tlsExterminator).
		WithFile("/usr/local/bin/goreman", goreman).
		WithNewFile("/Procfile", procfile).
		WithWorkdir("/").
		WithEntrypoint([]string{"goreman", "--set-ports=false", "start"})

	return pipely, nil
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

	return m.App.
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
		WithDirectory("/test", m.Source.Directory("test"))
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
	return m.App.
		WithLabel("org.opencontainers.image.url", "https://pipely.tech").
		WithLabel("org.opencontainers.image.description", "A single-purpose, single-tenant CDN running Varnish Cache (open source) on Fly.io").
		WithLabel("org.opencontainers.image.authors", "@"+registryUsername).
		WithRegistryAuth(registryAddress, registryUsername, registryPassword).
		Publish(ctx, image+":"+m.Tag)
}
