#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; V="$ROOT/.vscode"; }

# Strip // line comments and trailing commas so JSONC parses under jq.
jsonc_to_json() {
    python3 -c '
import re, sys
text = open(sys.argv[1]).read()
text = "".join(line for line in text.splitlines(True) if not re.match(r"^\s*//", line))
prev = None
while prev != text:
    prev = text
    text = re.sub(r",(\s*[}\]])", r"\1", text)
sys.stdout.write(text)
' "$1"
}

@test "settings carry no mcp servers" {
    run grep -nE 'mcpServers|homelab|marginalia|mcp-client' "$V/settings.json"
    [ "$status" -ne 0 ]
}

@test "settings parse as json with trailing commas removed" {
    jsonc_to_json "$V/settings.json" | jq -e . >/dev/null
}

@test "the color theme names the migrated package" {
    grep -q '"workbench.colorTheme": "Terminal Noir"' "$V/settings.json"
    jq -e '.contributes.themes[] | select(.label == "Terminal Noir")' "$ROOT/configs/vscode/terminal-noir/package.json" >/dev/null
}

@test "keybindings and extensions parse" {
    jsonc_to_json "$V/keybindings.json" | jq -e . >/dev/null
    run jq -e '.recommendations | length > 0' "$V/extensions.json"
    [ "$status" -eq 0 ]
}

@test "snippets exist and hold no personal data" {
    [ -n "$(ls "$V/snippets")" ]
    run grep -rnE "nando""moreira|@gmail|/home/[a-z]" "$V"
    [ "$status" -ne 0 ]
}
