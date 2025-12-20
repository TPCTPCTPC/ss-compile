#!/bin/bash
set -e

export CARGO_PROFILE_RELEASE_LTO="fat"           
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1     
export CARGO_PROFILE_RELEASE_PANIC="abort"       
export CARGO_PROFILE_RELEASE_STRIP="true"        
export CARGO_PROFILE_RELEASE_OPT_LEVEL=3         
export CARGO_PROFILE_RELEASE_INCREMENTAL="false" 

echo "Cloning upstream repository..."
git clone https://github.com/shadowsocks/shadowsocks-rust.git
cd shadowsocks-rust

echo "Checking for the latest official release..."
LATEST_TAG=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo "Error: Could not find latest release tag."
    exit 1
fi

echo "Found latest release: $LATEST_TAG"
echo "Checking out to $LATEST_TAG..."
git checkout "$LATEST_TAG"

echo "Building with Custom Environment Variables..."
echo "   - RUSTFLAGS: '$RUSTFLAGS'"
echo "   - LTO: Fat"
echo "   - Codegen Units: 1"
echo "   - Incremental: False"

cargo build --release \
    --no-default-features \
    --features "server,aead-cipher-2022" \
    --bin ssserver

mv target/release/ssserver ../ssserver

echo "✅ Build finished! Binary ($LATEST_TAG) is at: ./ssserver"
