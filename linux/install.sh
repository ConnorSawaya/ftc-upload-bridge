#!/usr/bin/env bash
# Set up Connor's Raspberry Pi USB bridge on a Linux computer.
# Run from the repository root: bash linux/install.sh [--yes]
# Pi firmware and the shared ftc-bridge command stay in their original locations.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
SERVER="$REPO/mcp/server.py"
YES=""
case "${1:-}" in
  --yes) YES=1 ;;
  "") ;;
  *) echo "usage: bash linux/install.sh [--yes]" >&2; exit 2 ;;
esac
[[ "$(uname -s)" == Linux ]] || { echo "This installer is for Linux." >&2; exit 1; }

ok()   { printf '  [ok] %s\n' "$*"; }
warn() { printf '  [!] %s\n' "$*"; }
skip() { printf '  - %s\n' "$*"; }
ask() {
  [[ -n "$YES" ]] && return 0
  [[ -t 0 ]] || return 1
  local answer
  read -r -p "  $1 [Y/n] " answer
  [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
}

echo "Checking this Linux computer"
missing=()
for tool in bash ssh tar python3 perl ip ping sha256sum; do
  if ! command -v "$tool" >/dev/null 2>&1; then missing+=("$tool"); fi
done
if (( ${#missing[@]} )); then
  warn "Missing: ${missing[*]}"
  echo "On Ubuntu/Debian install: sudo apt install openssh-client tar python3 perl iproute2 iputils-ping coreutils"
  exit 1
fi
ok "SSH, network tools, Python, and shell utilities"

if command -v adb >/dev/null 2>&1 || [[ -x "$HOME/Android/Sdk/platform-tools/adb" ]] || [[ -x "${ANDROID_HOME:-/nonexistent}/platform-tools/adb" ]] || [[ -x "${ANDROID_SDK_ROOT:-/nonexistent}/platform-tools/adb" ]]; then
  ok "adb"
else
  warn "adb not found: install Android Studio's SDK Platform-Tools or your distribution's adb package"
fi
if command -v java >/dev/null 2>&1 || [[ -d /opt/android-studio/jbr ]]; then
  ok "Java"
else
  warn "Java not found: Android Studio includes a JDK, or install a compatible JDK for your FTC project"
fi

echo "Terminal command"
mkdir -p "$HOME/.local/bin"
ln -sfn "$REPO/ftc-bridge" "$HOME/.local/bin/ftc-bridge"
ok "ftc-bridge -> ~/.local/bin/ftc-bridge"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) warn "~/.local/bin isn't on PATH; add it to your shell configuration, then open a new shell" ;;
esac

echo "Pi SSH access"
if [[ -f "$HOME/.ssh/ftcpi" && -f "$HOME/.ssh/ftcpi.pub" ]]; then
  skip "Existing ~/.ssh/ftcpi key preserved"
else
  "$REPO/ftc-bridge" key >/dev/null
  ok "Created ~/.ssh/ftcpi key"
fi
echo "  To authorize this Linux computer, run ftc-bridge key and add the public key"
echo "  from an already-authorized computer: ftc-bridge add-key \"<public key>\""

UV="$(command -v uv || true)"
if [[ -n "$UV" ]]; then
  echo "AI apps (MCP)"
  if command -v claude >/dev/null 2>&1; then
    if claude mcp get ftc-bridge >/dev/null 2>&1; then skip "Claude Code: already added"
    elif ask "Add ftc-bridge to Claude Code?"; then
      if claude mcp add --scope user ftc-bridge -- "$UV" run "$SERVER" >/dev/null; then ok "Claude Code"; else warn "Claude Code setup failed"; fi
    fi
  fi
  if command -v codex >/dev/null 2>&1; then
    if codex mcp get ftc-bridge >/dev/null 2>&1; then skip "Codex: already added"
    elif ask "Add ftc-bridge to Codex?"; then
      if codex mcp add ftc-bridge -- "$UV" run "$SERVER" >/dev/null; then ok "Codex"; else warn "Codex setup failed"; fi
    fi
  fi
  if command -v opencode >/dev/null 2>&1; then
    if grep -qs '"ftc-bridge"' "$HOME/.config/opencode/opencode.json" "$HOME/.config/opencode/opencode.jsonc"; then
      skip "OpenCode: already added"
    elif ask "Add ftc-bridge to OpenCode?"; then
      if opencode mcp add --global ftc-bridge -- "$UV" run "$SERVER" >/dev/null; then ok "OpenCode"; else warn "OpenCode setup failed"; fi
    fi
  fi
else
  warn "uv not installed: optional MCP registration skipped (https://docs.astral.sh/uv/)"
fi

echo "Checking Pi USB link"
if ping -c 1 -W 2 10.12.194.1 >/dev/null 2>&1; then
  ok "Pi responds at 10.12.194.1"
else
  warn "Pi not reachable yet: connect its USB data port, then check the USB Ethernet interface with ip addr"
fi
echo
echo "Done. Run ftc-bridge health once the Pi is connected and this computer's SSH key is authorized."
