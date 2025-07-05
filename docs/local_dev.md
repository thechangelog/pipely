# Local Development and Testing

You can start up a local instance of Pipely by running `just local-debug`. Once the container is built it will be started up with the name `pipely-debug` and you will be in a shell. From there, you have all the tools you need to run and experiment.

## Available Tools

The following tools are available inside the container:

- hurl - HTTP testing tool
- httpstat - HTTP request statistics
- htop - Process monitor
- gotop - System monitor
- oha - HTTP load testing
- jq - JSON processor
- neovim - Text editor
- varnish tools - varnishadm, varnishlog, varnishtop, varnishstat
- sasqwatch - Varnish log analysis
- just - Task runner (available via container.justfile)

## Available Commands

Like the project, the development container has its own `just` file to run several useful operations. Simply type `just` to view all your options.

## Running the Server

To work effectively on the container, you're going to want to start up tmux. This will allow you to run the server in one window, other commands in other windows, and to switch between them quickly and easily.

If you're not familiar with tmux, I highly recommend taking a quick tutorial, but to jump right in:

- Get into the local container with `just local-debug`.
- type `tmux`.
- Start the server with `just up`.
- Create a new window by pressing `ctrl-b` followed by `c`.
- Try fetching the front page from the locally running server with `curl http://localhost:9000`.
- Run a benchmark test such as `just bench-app-4-pipedream`.
- Switch back to the other window and check out the live logs feed with `ctrl-b b`.
- Quit the server with `ctrl-c`.
- Close your two tmux windows with `exit` and `exit`.
- Close your container prompt with `exit` again.

## Architecture

```
[localhost:9000] 
     ↓
[Varnish Cache] ← health checks backends
     ↓
[Dynamic Backend Selection]
     ↓
┌─────────────────┬─────────────────┬──────────────────┐
│   App Proxy     │  Feeds Proxy    │  Assets Proxy    │
│ (localhost:5000)│ (localhost:5010)│ (localhost:5020) │
│       ↓         │       ↓         │        ↓         │
│ TLS Terminator  │ TLS Terminator  │ TLS Terminator   │
│       ↓         │       ↓         │        ↓         │
│  External App   │ External Feeds  │ External Assets  │
└─────────────────┴─────────────────┴──────────────────┘
```
