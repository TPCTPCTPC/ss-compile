# ss-compile

Optimized Linux amd64 builds for SLOMO proxy and observability binaries.

The scheduled GitHub Action publishes a rolling `nightly` release with:

- `ssserver`
- `shadow-tls`
- `realm`
- `anytls-server`
- `anytls-client`
- `node_exporter`
- `blackbox_exporter`
- `mosdns`
- `sing-box`

The workflow targets modern x86 servers with x86-64-v3 / `GOAMD64=v3`
optimizations and stripped release binaries.
