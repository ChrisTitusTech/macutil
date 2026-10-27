#!/bin/bash
#
# Legacy entry point kept for compatibility.
#
# It used to create three bundles by lipo-ing only the apphost binary and then
# copying the x64 native libraries into the "universal" bundle. That produced
# an app that crashes on Apple Silicon (libSkiaSharp.dylib / libAvaloniaNative
# .dylib were x64-only).
#
# The implementation now lives in packaging/build_app.sh, which merges every
# Mach-O file and signs the result.
#
# Usage: ./deploy_macos.sh [extra options, see packaging/build_app.sh --help]
#
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$PROJECT_DIR/packaging/build_app.sh" --universal --out "$PROJECT_DIR/dist" "$@"
