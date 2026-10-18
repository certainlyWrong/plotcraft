#!/usr/bin/env bash
# Builds the Plotcraft MCP server into a single executable: build/plotcraft-mcp
set -euo pipefail
cd "$(dirname "$0")/../packages/plotcraft_mcp"
dart pub get
mkdir -p ../../build
dart compile exe bin/plotcraft_mcp.dart -o ../../build/plotcraft-mcp
echo "Built $(cd ../../build && pwd)/plotcraft-mcp"
