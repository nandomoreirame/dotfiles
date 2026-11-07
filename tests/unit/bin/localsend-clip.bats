#!/usr/bin/env bats

# Unit tests for bin/utils/localsend-clip
#
# Run:
#   ./tests/run-tests unit/bin/localsend-clip.bats
#
# Stubs on PATH:
#   wl-paste     prints FAKE_CLIP
#   openssl      `s_client -connect H:P` prints "CERT-PHONE" for hosts in
#                FAKE_PHONE_HOSTS, "CERT-OTHER" for FAKE_OTHER_HOSTS, else
#                fails; `x509` copies stdin (so the cert hash is the hash of
#                that marker)
#   curl         logs "URL <url>" and the request body (the --cert/--key
#                contents go to calls.log.tls, the key path to .keypath), writes FAKE_BODY to
#                the -o file and prints FAKE_HTTP (prepare) / 200 (upload)
#   notify-send  logs its arguments
# LOCALSEND_PREFS points at a fixture shaped like LocalSend's
# shared_preferences.json.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/localsend-clip"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"
    NOTIFY_LOG="$TEST_DIR/notify.log"

    mkdir -p "$STUB_DIR"
    : > "$CALL_LOG"
    : > "$NOTIFY_LOG"

    cat > "$STUB_DIR/wl-paste" <<'STUB'
#!/usr/bin/env bash
printf '%s' "$FAKE_CLIP"
STUB
    cat > "$STUB_DIR/openssl" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "x509" ]; then cat; exit 0; fi
host=""
while [ $# -gt 0 ]; do
    [ "$1" = "-connect" ] && host="${2%:*}"
    shift
done
for h in $FAKE_PHONE_HOSTS; do [ "$h" = "$host" ] && { printf 'CERT-PHONE'; exit 0; }; done
for h in $FAKE_OTHER_HOSTS; do [ "$h" = "$host" ] && { printf 'CERT-OTHER'; exit 0; }; done
exit 1
STUB
    cat > "$STUB_DIR/curl" <<'STUB'
#!/usr/bin/env bash
out=""
while [ $# -gt 1 ]; do
    [ "$1" = "-o" ] && out="$2"
    [ "$1" = "--cert" ] && echo "CERT $(cat "$2")" >> "$CALL_LOG.tls"
    [ "$1" = "--key" ] && { echo "KEY $(cat "$2")" >> "$CALL_LOG.tls"; echo "$2" >> "$CALL_LOG.keypath"; }
    shift
done
echo "URL $1" >> "$CALL_LOG"
cat >> "$CALL_LOG"
echo >> "$CALL_LOG"
case "$1" in
    */upload\?*) printf '200' ;;
    *)
        [ -n "$out" ] && printf '%s' "${FAKE_BODY:-}" > "$out"
        printf '%s' "${FAKE_HTTP:-204}"
        ;;
esac
STUB
    cat > "$STUB_DIR/notify-send" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "$NOTIFY_LOG"
STUB
    chmod +x "$STUB_DIR"/*

    PHONE_FP="$(printf 'CERT-PHONE' | sha256sum | cut -d' ' -f1 | tr 'a-f' 'A-F')"
    export LOCALSEND_PREFS="$TEST_DIR/shared_preferences.json"
    jq -n --arg fp "$PHONE_FP" '{
        "flutter.ls_alias": "Desktop",
        "flutter.ls_port": 53317,
        "flutter.ls_security_context": ({certificateHash: "DESKTOPHASH", certificate: "DESKTOPCERT", privateKey: "secret"} | tojson),
        "flutter.ls_favorites": [
            ({id: "1", fingerprint: $fp, ip: "192.0.2.53", port: 53317, alias: "iPhone 12", customAlias: false} | tojson)
        ]
    }' > "$LOCALSEND_PREFS"

    export CALL_LOG NOTIFY_LOG
    export FAKE_CLIP="hello \"world\""
    export FAKE_PHONE_HOSTS="192.0.2.53"
    export FAKE_OTHER_HOSTS=""
    export PATH="$STUB_DIR:$PATH"
}

teardown() {
    temp_del "$TEST_DIR"
}

prepare_body() {
    # The JSON body sent to prepare-upload (the line after its URL line).
    grep -A1 '^URL .*/prepare-upload$' "$CALL_LOG" | tail -n1
}

@test "sends the clipboard text as a LocalSend message to the favorite" {
    run "$SCRIPT" "iPhone 12"

    [ "$status" -eq 0 ]
    grep -qx "URL https://192.0.2.53:53317/api/localsend/v2/prepare-upload" "$CALL_LOG"
    body="$(prepare_body)"
    [ "$(jq -r '.info.alias' <<< "$body")" = "Desktop" ]
    [ "$(jq -r '.info.fingerprint' <<< "$body")" = "DESKTOPHASH" ]
    [ "$(jq -r '.files[].fileType' <<< "$body")" = "text/plain" ]
    [ "$(jq -r '.files[].preview' <<< "$body")" = 'hello "world"' ]
    [ "$(jq -r '.files[].size' <<< "$body")" -eq "$(printf '%s' 'hello "world"' | wc -c)" ]
    grep -q "iPhone 12" "$NOTIFY_LOG"
}

@test "never puts the private key in the request" {
    run "$SCRIPT" "iPhone 12"

    [ "$status" -eq 0 ]
    ! grep -q "secret" "$CALL_LOG"
}

@test "presents the desktop certificate as client cert and removes the key" {
    run "$SCRIPT" "iPhone 12"

    [ "$status" -eq 0 ]
    grep -qx "CERT DESKTOPCERT" "$CALL_LOG.tls"
    grep -qx "KEY secret" "$CALL_LOG.tls"
    [ ! -e "$(head -n1 "$CALL_LOG.keypath")" ]
}

@test "uploads the text when the receiver asks for the file" {
    export FAKE_HTTP=200
    export FAKE_BODY='{"sessionId":"S1","files":{"F1":"T1"}}'

    run "$SCRIPT" "iPhone 12"

    [ "$status" -eq 0 ]
    grep -qx "URL https://192.0.2.53:53317/api/localsend/v2/upload?sessionId=S1&fileId=F1&token=T1" "$CALL_LOG"
    grep -A1 '^URL .*/upload?' "$CALL_LOG" | tail -n1 | grep -qx 'hello "world"'
}

@test "finds the device on the subnet when its stored IP is stale" {
    export FAKE_PHONE_HOSTS="192.0.2.60"
    export FAKE_OTHER_HOSTS="192.0.2.53"

    run "$SCRIPT" "iPhone 12"

    [ "$status" -eq 0 ]
    grep -qx "URL https://192.0.2.60:53317/api/localsend/v2/prepare-upload" "$CALL_LOG"
    ! grep -q "192.0.2.53" "$CALL_LOG"
}

@test "warns and sends nothing when the device does not answer" {
    export FAKE_PHONE_HOSTS=""

    run "$SCRIPT" "iPhone 12"

    [ "$status" -ne 0 ]
    [ ! -s "$CALL_LOG" ]
    grep -q "LocalSend" "$NOTIFY_LOG"
}

@test "warns and sends nothing when the clipboard has no text" {
    export FAKE_CLIP=""

    run "$SCRIPT" "iPhone 12"

    [ "$status" -ne 0 ]
    [ ! -s "$CALL_LOG" ]
    [ -s "$NOTIFY_LOG" ]
}

@test "reports a rejected transfer" {
    export FAKE_HTTP=403

    run "$SCRIPT" "iPhone 12"

    [ "$status" -ne 0 ]
    grep -qi "reject" "$NOTIFY_LOG"
}

@test "fails on an alias that is not a favorite" {
    run "$SCRIPT" "Pixel"

    [ "$status" -ne 0 ]
    [ ! -s "$CALL_LOG" ]
    [[ "$output" == *"Pixel"* ]]
}
