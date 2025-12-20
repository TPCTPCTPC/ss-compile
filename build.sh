#!/bin/bash
set -e

export CARGO_PROFILE_RELEASE_LTO="fat"
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1
export CARGO_PROFILE_RELEASE_PANIC="abort"
export CARGO_PROFILE_RELEASE_STRIP="true"
export CARGO_PROFILE_RELEASE_OPT_LEVEL=3
export CARGO_PROFILE_RELEASE_INCREMENTAL="false"

git clone https://github.com/shadowsocks/shadowsocks-rust.git
cd shadowsocks-rust

LATEST_TAG=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
git checkout "$LATEST_TAG"

cargo build --release --no-default-features --features "server,aead-cipher-2022" --bin ssserver

mv target/release/ssserver ../ssserver
