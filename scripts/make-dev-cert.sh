#!/usr/bin/env bash
# One-time setup: creates a self-signed "Sticker Translator Dev" code-signing certificate
# in your login keychain, so every rebuild keeps the same identity and macOS remembers
# the screen permission. Remove it any time in Keychain Access (search "Sticker Translator Dev").
set -euo pipefail
# macOS's own LibreSSL: Homebrew OpenSSL 3 writes .p12 files the keychain can't import.
NAME="Sticker Translator Dev"
if security find-certificate -c "$NAME" >/dev/null 2>&1; then
    echo "\"$NAME\" already exists."; exit 0
fi
DIR="$(mktemp -d)"; trap 'rm -rf "$DIR"' EXIT
cat > "$DIR/cert.cnf" <<CNF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $NAME
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
CNF
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$DIR/cert.cnf" \
    -keyout "$DIR/key.pem" -out "$DIR/cert.pem" 2>/dev/null
/usr/bin/openssl pkcs12 -export -inkey "$DIR/key.pem" -in "$DIR/cert.pem" -name "$NAME" \
    -out "$DIR/id.p12" -passout pass:temp
security import "$DIR/id.p12" -k ~/Library/Keychains/login.keychain-db -P temp -T /usr/bin/codesign
echo "Created \"$NAME\". Next: ./scripts/run.sh, then re-grant screen permission one last time."
