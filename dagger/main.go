package main

import (
	"context"
	"dagger/pipely/internal/dagger"
	"fmt"

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

	// +default="7.4.3@sha256:c36e73e14650a021b0b8a8c748cac07a7d7b65052dc6395d193faed169c5b294"
	varnishVersion string,

	// +default=9000
	varnishPort int,

	// +default="1.23.6@sha256:77a21b3e354c03e9f66b13bc39f4f0db8085c70f8414406af66b29c6d6c4dd85"
	golangVersion string,

	// +default="4226223f2380319e73300bc7d14fd652c56c6b4e"
	tlsExterminatorVersion string,

	// +default="5000:changelog-2024-01-12.fly.dev"
	changelogProxy string,

	// +default="5010:feeds.changelog.place"
	feedsProxy string,

	// +default="v0.3.16"
	goremanVersion string,

	// +default="localhost"
	backendFqdn string,

	// +default="localhost"
	backendHost string,

	// +default="5000"
	backendPort string,
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
changelog: tls-exterminator %s
feeds: tls-exterminator %s
`, changelogProxy, feedsProxy)

	pipely.App = dag.Container().
		From("varnish:"+varnishVersion).
		WithEnvVariable("VARNISH_HTTP_PORT", "9000").
		WithEnvVariable("BACKEND_FQDN", backendFqdn).
		WithEnvVariable("BACKEND_HOST", backendHost).
		WithEnvVariable("BACKEND_PORT", backendPort).
		WithExposedPort(varnishPort).
		WithFile("/etc/varnish/default.vcl", source.File("default.vcl")).
		WithFile("/usr/local/bin/tls-exterminator", tlsExterminator).
		WithFile("/usr/local/bin/goreman", goreman).
		WithNewFile("/Procfile", procfile).
		WithWorkdir("/").
		WithEntrypoint([]string{"goreman", "start"})

	return pipely, nil
}

// Debug container with various useful tools - use just as the starting point
func (m *Pipely) Debug(ctx context.Context) *dagger.Container {
	httpstat := m.Golang.
		WithExec([]string{"go", "install", "github.com/davecheney/httpstat@v1.2.1"}).
		File("/go/bin/httpstat")

	sasqwatch := m.Golang.
		WithExec([]string{"go", "install", "github.com/fabio42/sasqwatch@8564c29ceaa03d5211b8b6d7a3012f9acf691fd1"}).
		File("/go/bin/sasqwatch")

	gotop := m.Golang.
		WithExec([]string{"go", "install", "github.com/xxxserxxx/gotop/v4/cmd/gotop@bba42d08624edee8e339ac98c1a9c46810414f78"}).
		File("/go/bin/gotop")

	p, _ := dag.DefaultPlatform(ctx)
	platform := platforms.MustParse(string(p))
	oha := dag.HTTP("https://github.com/hatoo/oha/releases/download/v1.8.0/oha-" + platform.OS + "-" + platform.Architecture)

	return m.App.
		WithUser("root").
		WithEnvVariable("DEBIAN_FRONTEND", "noninteractive").
		WithEnvVariable("TERM", "xterm-256color").
		WithExec([]string{"apt-get", "update"}).
		WithExec([]string{"apt-get", "install", "--yes", "curl"}).
		WithExec([]string{"curl", "--version"}).
		WithExec([]string{"apt-get", "install", "--yes", "tmux"}).
		WithExec([]string{"tmux", "-V"}).
		WithExec([]string{"apt-get", "install", "--yes", "htop"}).
		WithExec([]string{"htop", "-V"}).
		WithExec([]string{"apt-get", "install", "--yes", "neovim"}).
		WithExec([]string{"nvim", "--version"}).
		WithFile("/usr/local/bin/httpstat", httpstat).
		WithFile("/usr/local/bin/sasqwatch", sasqwatch).
		WithFile("/usr/local/bin/gotop", gotop).
		WithFile("/usr/local/bin/oha", oha, dagger.ContainerWithFileOpts{
			Permissions: 755,
		}).
		WithFile("/justfile", m.Source.File("container.justfile")).
		WithExec([]string{"bash", "-c", "curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin"})
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
