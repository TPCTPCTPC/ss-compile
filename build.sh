#!/bin/bash
set -e

git clone https://github.com/shadowsocks/shadowsocks-rust.git
cd shadowsocks-rust

LATEST_TAG=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
git checkout "$LATEST_TAG"

sed -i 's/\[profile.release\]/\[profile.trash\]/' Cargo.toml

cat >> Cargo.toml <<EOF
[profile.release]
lto = "fat"
codegen-units = 1
panic = "abort"
strip = true
opt-level = 3
incremental = false
EOF

cargo build --release --no-default-features --features "server,aead-cipher-2022" --bin ssserver

mv target/release/ssserver ../ssserver
