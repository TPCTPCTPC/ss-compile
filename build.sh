#!/bin/bash
set -e

export CARGO_PROFILE_RELEASE_LTO="fat"
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1
export CARGO_PROFILE_RELEASE_PANIC="abort"
export CARGO_PROFILE_RELEASE_STRIP="true"
export CARGO_PROFILE_RELEASE_OPT_LEVEL=3
export CARGO_PROFILE_RELEASE_INCREMENTAL="false"

git clone https://github.com/shadowsocks/shadowsocks-rust.git ss-src
cd ss-src
SS_TAG=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
git checkout "$SS_TAG"
cargo build --release --no-default-features --features "server,aead-cipher-2022" --bin ssserver
strip -s target/release/ssserver
mv target/release/ssserver ../ssserver
cd ..

git clone https://github.com/ihciah/shadow-tls.git stls-src
cd stls-src
STLS_TAG=$(curl -s https://api.github.com/repos/ihciah/shadow-tls/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
git checkout "$STLS_TAG"
cargo build --release --bin shadow-tls
strip -s target/release/shadow-tls
mv target/release/shadow-tls ../shadow-tls
cd ..

echo "✅ All builds finished: ./ssserver, ./shadow-tls"
