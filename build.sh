#!/bin/bash
set -e

# Rust Env
export CARGO_PROFILE_RELEASE_LTO="fat"
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1
export CARGO_PROFILE_RELEASE_PANIC="abort"
export CARGO_PROFILE_RELEASE_STRIP="true"
export CARGO_PROFILE_RELEASE_OPT_LEVEL=3
export CARGO_PROFILE_RELEASE_INCREMENTAL="false"

# Go Env
export GOAMD64=v3
export CGO_ENABLED=0

# 1. Build Shadowsocks-rust
git clone https://github.com/shadowsocks/shadowsocks-rust.git ss-src
cd ss-src
SS_TAG=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
git checkout "$SS_TAG"
cargo build --release --no-default-features --features "server,aead-cipher-2022" --bin ssserver
strip -s target/release/ssserver
mv target/release/ssserver ../ssserver
cd ..

# 2. Build Shadow-TLS
git clone https://github.com/ihciah/shadow-tls.git stls-src
cd stls-src
STLS_TAG=$(curl -s https://api.github.com/repos/ihciah/shadow-tls/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
git checkout "$STLS_TAG"
cargo build --release --bin shadow-tls
strip -s target/release/shadow-tls
mv target/release/shadow-tls ../shadow-tls
cd ..

# 3. Build Node Exporter
git clone https://github.com/prometheus/node_exporter.git node-src
cd node-src
NODE_TAG=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
git checkout "$NODE_TAG"
go build -ldflags="-s -w" -o ../node_exporter
cd ..

# 4. Build Blackbox Exporter
git clone https://github.com/prometheus/blackbox_exporter.git black-src
cd black-src
BLACK_TAG=$(curl -s https://api.github.com/repos/prometheus/blackbox_exporter/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
git checkout "$BLACK_TAG"
go build -ldflags="-s -w" -o ../blackbox_exporter
cd ..

# 5. Build Mosdns
git clone https://github.com/IrineSistiana/mosdns.git mosdns-src
cd mosdns-src
MOS_TAG=$(curl -s https://api.github.com/repos/IrineSistiana/mosdns/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
git checkout "$MOS_TAG"
go build -ldflags="-s -w -X main.version=$MOS_TAG" -trimpath -o ../mosdns
cd ..

echo "All builds finished."
