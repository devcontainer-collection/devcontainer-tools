#!/bin/bash

# strip.sh - Universal binary stripper for C++, Rust, Linux/Windows/macOS (no bare-metal)
# Usage:
#   $ sh ./strip.sh --bin <binary-path> --target-triple <triple>
#   or
#   $ sh ./strip.sh --bin <binary-path> --os <os> --arch <arch>
#   or docker container runtime native
#   $ sh ./strip.sh --bin <binary-path> --native

set -e

# --- Parse args ---
BIN=""
TARGET_TRIPLE=""
OS=""
ARCH=""
USE_NATIVE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bin)
      BIN="$2"
      shift 2
      ;;
    --target-triple)
      TARGET_TRIPLE="$2"
      shift 2
      ;;
    --os)
      OS="$2"
      shift 2
      ;;
    --arch)
      ARCH="$2"
      shift 2
      ;;
    --native)
      USE_NATIVE=1
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# --- Validation ---
if [ -z "$BIN" ]; then
  echo "Error: --bin <binary-path> is required."
  exit 1
fi

if [ ! -f "$BIN" ]; then
  echo "Error: binary not found: $BIN"
  exit 1
fi

if [ "$USE_NATIVE" -eq 1 ]; then
  echo "[strip] Native runtime: using 'strip'"
  strip "$BIN"
  echo "[strip] Done: $BIN"
  exit 0
fi

# --- Resolve OS/ARCH from triple if provided ---
if [ -n "$TARGET_TRIPLE" ]; then
  # Handle 3 or 4 part triples: <arch>-<vendor>-<os>-<abi>
  IFS='-' read -r ARCH VENDOR OS ABI <<< "$TARGET_TRIPLE"
fi

if [ -z "$OS" ] || [ -z "$ARCH" ]; then
  echo "Error: OS and ARCH must be specified (via --target-triple or --os/--arch)"
  exit 1
fi

echo "[strip] Binary: $BIN"
echo "[strip] Target: $OS-$ARCH"

# --- Select strip command ---
strip_cmd=""

case "$OS" in
  linux)
    case "$ARCH" in
      x86_64)   strip_cmd="x86_64-linux-gnu-strip" ;;
      aarch64)  strip_cmd="aarch64-linux-gnu-strip" ;;
      armv7 | armv7a | arm) strip_cmd="arm-linux-gnueabihf-strip" ;;
    esac
    ;;
  windows)
    case "$ARCH" in
      x86_64)   strip_cmd="x86_64-w64-mingw32-strip" ;;
      aarch64)  strip_cmd="aarch64-w64-mingw32-strip" ;;
    esac
    ;;
  macos)
    echo "[strip] Automatic stripping for macOS is not supported in this script."
    echo "[strip] Please run 'strip \"$BIN\"' directly on your macOS host system."
    echo "[strip] Refer to the macOS developer documentation for more details: https://developer.apple.com/documentation/command_line_tools/strip"
    exit 0
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

if [ -z "$strip_cmd" ]; then
  echo "Unsupported architecture: $ARCH for OS: $OS"
  exit 1
fi

echo "[strip] Using: $strip_cmd"
$strip_cmd "$BIN"
echo "[strip] Done: $BIN"
