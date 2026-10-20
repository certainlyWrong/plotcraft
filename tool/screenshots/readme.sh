#!/usr/bin/env bash
# Renders the README screenshots from the bundled sample story into
# docs/screenshots/, one test process each so state never leaks between them.
cd "$(dirname "$0")/../.."
file=tool/screenshots/readme_test.dart
names=$(grep -o "testWidgets('[^']*'" $file | sed "s/testWidgets('//;s/'$//")
while IFS= read -r name; do
  [ -n "$1" ] && [[ "$name" != *"$1"* ]] && continue
  out=$(flutter test $file --plain-name "$name" --timeout 300s 2>&1 | tail -3)
  if echo "$out" | grep -q "All tests passed"; then echo "ok   $name"; else echo "FAIL $name"; echo "$out"; fi
done <<< "$names"
