#!/bin/bash
set -e

# Helper: fetch latest tag with API fallback to git tags
fetch_latest_tag() {
    local repo="$1"
    local tag
    tag=$(curl -s --connect-timeout 5 "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$tag" ]; then
        echo "⚠️  API rate-limited, falling back to git tags for $repo" >&2
        tag=$(git tag --sort=-version:refname | head -1 || true)
    fi
    if [ -z "$tag" ]; then
        echo "❌ Could not determine latest tag for $repo" >&2
        exit 1
    fi
    echo "$tag"
}

# Helper: select the newest alpha tag from the cloned repository.
fetch_latest_alpha_tag() {
    local tag
    tag=$(git tag --list 'v*-alpha.*' --sort=-version:refname | head -1 || true)
    if [ -z "$tag" ]; then
        echo "❌ Could not determine latest alpha tag" >&2
        exit 1
    fi
    echo "$tag"
}

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
SS_TAG=$(fetch_latest_tag shadowsocks/shadowsocks-rust)
git checkout "$SS_TAG"
cargo build --release --no-default-features --features "server,aead-cipher-2022" --bin ssserver
strip -s target/release/ssserver
mv target/release/ssserver ../ssserver
cd ..

# 2. Build Shadow-TLS
git clone https://github.com/ihciah/shadow-tls.git stls-src
cd stls-src
STLS_TAG=$(fetch_latest_tag ihciah/shadow-tls)
git checkout "$STLS_TAG"
cargo build --release --bin shadow-tls
strip -s target/release/shadow-tls
mv target/release/shadow-tls ../shadow-tls
cd ..

# 3. Build Node Exporter
git clone https://github.com/prometheus/node_exporter.git node-src
cd node-src
NODE_TAG=$(fetch_latest_tag prometheus/node_exporter)
git checkout "$NODE_TAG"
go build -ldflags="-s -w" -o ../node_exporter
cd ..

# 4. Build Blackbox Exporter
git clone https://github.com/prometheus/blackbox_exporter.git black-src
cd black-src
BLACK_TAG=$(fetch_latest_tag prometheus/blackbox_exporter)
git checkout "$BLACK_TAG"
go build -ldflags="-s -w" -o ../blackbox_exporter
cd ..

# 5. Build Mosdns
git clone https://github.com/IrineSistiana/mosdns.git mosdns-src
cd mosdns-src
MOS_TAG=$(fetch_latest_tag IrineSistiana/mosdns)
git checkout "$MOS_TAG"
go build -ldflags="-s -w -X main.version=$MOS_TAG" -trimpath -o ../mosdns
cd ..

# 6. Build Sing-Box
git clone https://github.com/SagerNet/sing-box.git sing-box-src
cd sing-box-src
SING_TAG=$(fetch_latest_tag SagerNet/sing-box)
git checkout "$SING_TAG"
SING_VERSION=${SING_TAG#v}
SING_LDFLAGS=$(cat release/LDFLAGS)
go build -trimpath -buildvcs=false -tags "with_quic" \
    -ldflags="-X 'github.com/sagernet/sing-box/constant.Version=$SING_VERSION' $SING_LDFLAGS -s -w -buildid=" \
    -o ../sing-box ./cmd/sing-box

# Build the newest alpha without optional build tags. Keep the target at
# GOAMD64=v3 while stripping local paths and injecting the upstream version.
SING_ALPHA_TAG=$(fetch_latest_alpha_tag)
git checkout "$SING_ALPHA_TAG"
SING_ALPHA_VERSION=${SING_ALPHA_TAG#v}
SING_ALPHA_LDFLAGS=$(cat release/LDFLAGS)
go build -trimpath -buildvcs=false \
    -ldflags="-X 'github.com/sagernet/sing-box/constant.Version=$SING_ALPHA_VERSION' $SING_ALPHA_LDFLAGS -s -w -buildid=" \
    -o ../sing-box-alpha ./cmd/sing-box
cd ..

# 7. Build Realm
git clone https://github.com/zhboner/realm.git realm-src
cd realm-src
REALM_TAG=$(fetch_latest_tag zhboner/realm)
git checkout "$REALM_TAG"
cargo build --release --no-default-features --features "batched-udp,brutal-shutdown" --bin realm
strip -s target/release/realm
mv target/release/realm ../realm
cd ..

# 8. Build AnyTLS
git clone https://github.com/anytls/anytls-go.git anytls-src
cd anytls-src
ANYTLS_TAG=$(fetch_latest_tag anytls/anytls-go)
git checkout "$ANYTLS_TAG"
go build -trimpath -buildvcs=false -ldflags="-s -w" -o ../anytls-server ./cmd/server
go build -trimpath -buildvcs=false -ldflags="-s -w" -o ../anytls-client ./cmd/client
cd ..

echo "All builds finished."
