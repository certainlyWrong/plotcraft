#!/usr/bin/env bash
# Renders every screen, one test process each, so state never leaks between them.
cd "$(dirname "$0")/../.."
names=$(grep -o "testWidgets('[^']*'" tool/screenshots/screens_test.dart | sed "s/testWidgets('//;s/'$//")
while IFS= read -r name; do
  [ -n "$1" ] && [[ "$name" != *"$1"* ]] && continue
  out=$(flutter test tool/screenshots/screens_test.dart --plain-name "$name" --timeout 120s 2>&1 | tail -3)
  if echo "$out" | grep -q "All tests passed"; then echo "ok   $name"; else echo "FAIL $name"; echo "$out"; fi
done <<< "$names"
