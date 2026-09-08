#!/usr/bin/env bash
# Exports code coverage for the SwiftNetworkKit library target after `swift test --enable-code-coverage`.
# Produces:
#   .build/coverage/coverage.lcov   - lcov file (Codecov / editors)
#   .build/coverage/summary.md      - per-file + TOTAL table (Markdown)
#   .build/coverage/total.txt       - single line-coverage percentage, e.g. "87.01"
set -euo pipefail

OUT=".build/coverage"
mkdir -p "$OUT"

BIN_PATH="$(swift build --show-bin-path)"
PROFDATA="$(find "$BIN_PATH/codecov" -name 'default.profdata' | head -1)"
XCTEST="$(find "$BIN_PATH" -name '*.xctest' | head -1)"

if [[ "$OSTYPE" == darwin* ]]; then
  BIN="$XCTEST/Contents/MacOS/$(basename "$XCTEST" .xctest)"
else
  BIN="$XCTEST"
fi

# Only measure the shipping library, not tests / demo / dependencies.
IGNORE='(Tests|NetworkKitDemo|\.build|checkouts|Fixtures)'

xcrun llvm-cov export -format=lcov -instr-profile "$PROFDATA" "$BIN" \
  -ignore-filename-regex="$IGNORE" > "$OUT/coverage.lcov"

xcrun llvm-cov report -instr-profile "$PROFDATA" "$BIN" \
  -ignore-filename-regex="$IGNORE" > "$OUT/report.txt"

TOTAL_LINE="$(grep '^TOTAL' "$OUT/report.txt")"
PCT="$(echo "$TOTAL_LINE" | awk '{print $(NF-3)}' | tr -d '%')"
echo "$PCT" > "$OUT/total.txt"

{
  echo "## Code coverage"
  echo
  echo "**Line coverage: ${PCT}%** (library target only)"
  echo
  echo '```'
  xcrun llvm-cov report -instr-profile "$PROFDATA" "$BIN" \
    -ignore-filename-regex="$IGNORE" | tail -n +3
  echo '```'
} > "$OUT/summary.md"

echo "coverage: ${PCT}%  ->  $OUT/"
