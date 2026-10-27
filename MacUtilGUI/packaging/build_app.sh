#!/bin/bash
#
# Builds a runnable MacUtil .app bundle (Apple Silicon, Intel or Universal).
#
# Usage:
#   ./packaging/build_app.sh                  # current architecture, output in ./dist
#   ./packaging/build_app.sh --universal      # x64 + arm64 merged into one .app
#   ./packaging/build_app.sh --rid osx-x64
#   ./packaging/build_app.sh --out ~/Applications
#   ./packaging/build_app.sh --universal --sign "Developer ID Application: Name (TEAMID)"
#   ./packaging/build_app.sh --universal --sign "Developer ID Application: ..." --notarize macutil
#
# Why not `dotnet publish` straight into the release?
#   * Single-file bundles (PublishSingleFile + IncludeNativeLibrariesForSelfExtract)
#     unpack the native libs at startup into ~/.net/<app>/<hash>/. On Apple Silicon
#     macOS refuses to load those copies ("different Team IDs") because the extracted
#     files are ad-hoc signed while the host process is Developer ID signed.
#   * Trimming breaks Avalonia/F#/Tomlyn reflection.
#   * The bundle also needs a proper Info.plist, an icon, an executable bit, and a
#     signature; a bare `dotnet publish` output has none of that.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_FILE="$PROJECT_DIR/MacUtilGUI.fsproj"

APP_NAME="MacUtil"
EXEC_NAME="MacUtilGUI"
BUNDLE_ID="com.macutil.gui"
ICON_NAME="MacUtilGUI.icns"
MIN_MACOS="12.0"
COPYRIGHT="Copyright © 2025 CT Tech Group LLC. All rights reserved."

# Version: $VERSION wins, then the value in the project file.
VERSION="${VERSION:-$(sed -n 's:.*<CFBundleShortVersionString>\(.*\)</CFBundleShortVersionString>.*:\1:p' "$PROJECT_FILE" | head -n1)}"
VERSION="${VERSION:-0.0.0}"

# Ad-hoc by default so forks without a Developer ID still produce a usable app.
SIGN_IDENTITY="${MACOS_SIGN_IDENTITY:--}"
NOTARY_PROFILE="${MACOS_NOTARY_PROFILE:-}"

OUT_DIR="$PROJECT_DIR/dist"
BUILD_DIR="$PROJECT_DIR/bin/packaging"
RIDS=()
UNIVERSAL=false
MAKE_ZIP=true

info()  { printf '\033[0;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[0;32m  ✓\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
die()   { printf '\033[0;31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Builds a runnable MacUtil .app bundle (Apple Silicon, Intel or Universal).

Usage:
  ./packaging/build_app.sh                  # current architecture, output in ./dist
  ./packaging/build_app.sh --universal      # x64 + arm64 merged into one .app
  ./packaging/build_app.sh --rid osx-x64
  ./packaging/build_app.sh --out ~/Applications
  ./packaging/build_app.sh --universal --sign "Developer ID Application: Name (TEAMID)"
  ./packaging/build_app.sh --universal --sign "Developer ID Application: ..." --notarize macutil

Options:
  -r, --rid <rid>        Runtime identifier to build (repeatable): osx-arm64, osx-x64
  -u, --universal        Build both architectures and merge them into one .app
  -o, --out <dir>        Output directory (default: ./dist)
  -s, --sign <identity>  codesign identity; "-" (default) means ad-hoc signing
      --notarize <name>  notarytool keychain profile, requires --sign
      --no-zip           Do not create the .zip archive
  -h, --help             Show this help
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    -r|--rid)        RIDS+=("$2"); shift 2 ;;
    -u|--universal)  UNIVERSAL=true; shift ;;
    -o|--out)        OUT_DIR="$2"; shift 2 ;;
    -s|--sign)       SIGN_IDENTITY="$2"; shift 2 ;;
    --notarize)      NOTARY_PROFILE="$2"; shift 2 ;;
    --no-zip)        MAKE_ZIP=false; shift ;;
    -h|--help)       usage ;;
    *) die "Unknown option: $1 (try --help)" ;;
  esac
done

if $UNIVERSAL; then
  RIDS=(osx-x64 osx-arm64)
elif [ ${#RIDS[@]} -eq 0 ]; then
  case "$(uname -m)" in
    arm64) RIDS=(osx-arm64) ;;
    x86_64) RIDS=(osx-x64) ;;
    *) die "Unsupported host architecture: $(uname -m)" ;;
  esac
fi

command -v dotnet >/dev/null || die "dotnet SDK not found. Install .NET 9: https://dotnet.microsoft.com/download"
mkdir -p "$OUT_DIR" "$BUILD_DIR"

suffix_for_rid() {
  case "$1" in
    osx-arm64) echo "arm64" ;;
    osx-x64)   echo "x64" ;;
    *) die "Unsupported runtime identifier: $1" ;;
  esac
}

publish_rid() {
  local rid="$1"
  local out="$BUILD_DIR/$rid"
  info "Publishing $rid (self-contained, no single-file, no trimming)"
  rm -rf "$out"
  dotnet publish "$PROJECT_FILE" \
    --configuration Release \
    --runtime "$rid" \
    --self-contained true \
    -p:PublishSingleFile=false \
    -p:PublishTrimmed=false \
    -p:PublishReadyToRun=false \
    -p:DebugType=none \
    --nologo \
    --output "$out" >/dev/null
  [ -x "$out/$EXEC_NAME" ] || die "publish output for $rid is missing $EXEC_NAME"
  ok "$rid published"
}

write_plist() {
  local dest="$1"
  local plist="$SCRIPT_DIR/Info.plist.in"
  local content
  content="$(cat "$plist")"
  content="${content//__BUNDLE_ID__/$BUNDLE_ID}"
  content="${content//__EXECUTABLE__/$EXEC_NAME}"
  content="${content//__ICON__/$ICON_NAME}"
  content="${content//__VERSION__/$VERSION}"
  content="${content//__MIN_MACOS__/$MIN_MACOS}"
  content="${content//__COPYRIGHT__/$COPYRIGHT}"
  printf '%s\n' "$content" > "$dest"
}

# Copies a publish output into Contents/MacOS and adds Info.plist + icon.
assemble_bundle() {
  local payload_dir="$1"
  local bundle="$2"

  rm -rf "$bundle"
  mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
  cp -R "$payload_dir"/. "$bundle/Contents/MacOS/"
  write_plist "$bundle/Contents/Info.plist"
  [ -f "$PROJECT_DIR/$ICON_NAME" ] && cp "$PROJECT_DIR/$ICON_NAME" "$bundle/Contents/Resources/"
  chmod +x "$bundle/Contents/MacOS/$EXEC_NAME"
  ok "bundle assembled: $bundle"
}

# Merges every Mach-O file of two single-architecture publishes into one bundle.
build_universal_payload() {
  local dest="$1"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -R "$BUILD_DIR/osx-arm64"/. "$dest"/

  local missing=0 merged=0 skipped=0
  while IFS= read -r -d '' file; do
    local rel="${file#"$dest"/}"
    local other="$BUILD_DIR/osx-x64/$rel"
    [ -f "$other" ] || continue
    if file -b "$other" | grep -q 'Mach-O' && ! file -b "$file" | grep -q 'universal binary'; then
      if lipo -create "$file" "$other" -output "$file.tmp" 2>/dev/null; then
        mv "$file.tmp" "$file"
        merged=$((merged + 1))
      else
        rm -f "$file.tmp"
        skipped=$((skipped + 1))
      fi
    fi
  done < <(find "$dest" -type f -print0)

  # Files that only exist in the x64 payload (rare, but keeps the bundle complete)
  while IFS= read -r -d '' file; do
    local rel="${file#"$BUILD_DIR/osx-x64"/}"
    if [ ! -e "$dest/$rel" ]; then
      cp -p "$file" "$dest/$rel"
      missing=$((missing + 1))
    fi
  done < <(find "$BUILD_DIR/osx-x64" -type f -print0)

  ok "universal payload: $merged binaries merged, $missing x64-only files copied, $skipped skipped"
}

sign_bundle() {
  local bundle="$1"
  local runtime_opts=()
  local common=()

  # Empty arrays need the "+..." guard: macOS ships bash 3.2, where
  # "${arr[@]}" is an unbound-variable error under `set -u`.
  if [ "$SIGN_IDENTITY" = "-" ]; then
    warn "Signing ad-hoc (no Developer ID). macOS will still warn on first launch."
  else
    runtime_opts=(--options runtime --timestamp)
    common=(--entitlements "$PROJECT_DIR/MacUtilGUI.entitlements")
  fi

  # --deep is normally discouraged, but here Contents/MacOS holds ~230 files
  # (managed assemblies next to the apphost). A shallow signing pass treats them
  # as unsigned nested code and aborts with:
  #   code object is not signed at all In subcomponent: .../System.Xml.*.dll
  codesign --force --deep --sign "$SIGN_IDENTITY" \
    ${runtime_opts[@]+"${runtime_opts[@]}"} ${common[@]+"${common[@]}"} "$bundle"
  codesign --verify --deep --strict "$bundle" || die "signature verification failed"
  ok "signed with: $SIGN_IDENTITY"
}

zip_bundle() {
  local bundle="$1"
  local zip_path="$OUT_DIR/$(basename "$bundle" .app).zip"
  rm -f "$zip_path"
  # ditto keeps the executable bit and symlinks; `zip` from the CLI does not
  # when the archive is built on some systems.
  ditto -c -k --sequesterRsrc --keepParent "$bundle" "$zip_path"
  ok "archive: $zip_path"
}

notarize() {
  local bundle="$1"
  local zip_path="$OUT_DIR/$(basename "$bundle" .app).zip"
  [ -n "$NOTARY_PROFILE" ] || return 0
  [ "$SIGN_IDENTITY" != "-" ] || die "--notarize needs a Developer ID identity (--sign)"
  info "Submitting to Apple notary service (profile: $NOTARY_PROFILE)"
  xcrun notarytool submit "$zip_path" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$bundle"
  xcrun stapler validate "$bundle"
  ok "notarized and stapled"
}

main() {
  local rid
  for rid in "${RIDS[@]}"; do
    publish_rid "$rid"
  done

  local bundles=()

  if $UNIVERSAL; then
    build_universal_payload "$BUILD_DIR/universal"
    local bundle="$OUT_DIR/$APP_NAME-Universal.app"
    assemble_bundle "$BUILD_DIR/universal" "$bundle"
    bundles+=("$bundle")
  else
    for rid in "${RIDS[@]}"; do
      local bundle="$OUT_DIR/$APP_NAME-$(suffix_for_rid "$rid").app"
      assemble_bundle "$BUILD_DIR/$rid" "$bundle"
      bundles+=("$bundle")
    done
  fi

  local bundle
  for bundle in "${bundles[@]}"; do
    info "Finalizing $(basename "$bundle")"
    sign_bundle "$bundle"
    if $MAKE_ZIP; then
      zip_bundle "$bundle"
      notarize "$bundle"
    fi
    xattr -dr com.apple.quarantine "$bundle" 2>/dev/null || true
  done

  echo
  ok "Done (version $VERSION)"
  for bundle in "${bundles[@]}"; do
    printf '    %s (%s)\n' "$bundle" "$(du -sh "$bundle" | cut -f1)"
  done
  cat <<'EOF'

Next steps:
  * Install:   cp -R dist/MacUtil-arm64.app /Applications/
  * First run of an unsigned build (Gatekeeper):
      right click the app > Open, or
      xattr -dr com.apple.quarantine /Applications/MacUtil-arm64.app
  * Scripts that touch protected folders need Full Disk Access:
      System Settings > Privacy & Security > Full Disk Access > add MacUtil
EOF
}

main "$@"
