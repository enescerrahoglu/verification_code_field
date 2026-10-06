#!/usr/bin/env bash
# Deploy verification_code_field to pub.dev.
#
# Run:
#   chmod +x deploy.sh && ./deploy.sh
#
# Dry run (format, analyze, test, publish --dry-run only):
#   ./deploy.sh --dry-run

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

echo "==> Formatting Dart code"
dart format .

echo "==> Analyzing package"
flutter analyze

echo "==> Running package tests"
flutter test

echo "==> Analyzing example"
(
  cd example
  flutter analyze
)

echo "==> Checking pubspec for publish"
flutter pub publish --dry-run

if [[ "$DRY_RUN" == true ]]; then
  echo "==> Dry run complete. Skipping publish."
  exit 0
fi

echo "==> Publishing to pub.dev"
flutter pub publish

echo "==> Done"
