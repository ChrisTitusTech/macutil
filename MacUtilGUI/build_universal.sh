#!/bin/bash
#
# Legacy entry point kept for compatibility.
# The implementation lives in packaging/build_app.sh (it produces a .app bundle
# that actually runs on Apple Silicon; the old lipo-only approach copied the
# x64 native libraries into the "universal" bundle and crashed on arm64).
#
# Usage: ./build_universal.sh [extra options, see packaging/build_app.sh --help]
#
exec "$(cd "$(dirname "$0")" && pwd)/packaging/build_app.sh" --universal "$@"
