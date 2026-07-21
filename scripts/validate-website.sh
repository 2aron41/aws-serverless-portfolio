#!/usr/bin/env bash
set -euo pipefail

echo "Validating portfolio website files..."

if [ ! -d "website" ]; then
  echo "ERROR: website/ directory not found."
  exit 1
fi

if [ ! -f "website/index.html" ]; then
  echo "ERROR: website/index.html not found."
  exit 1
fi

if [ ! -f "website/styles.css" ]; then
  echo "ERROR: website/styles.css not found."
  exit 1
fi

if [ -f "website/index-.html" ]; then
  echo "ERROR: index-.html found. Did you mean index.html?"
  exit 1
fi

if grep -RniE "aws_access_key_id|aws_secret_access_key|BEGIN RSA PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY" website/ .github/ 2>/dev/null; then
  echo "ERROR: Possible secret found."
  exit 1
fi

if ! grep -q "styles.css" website/index.html; then
  echo "ERROR: index.html does not appear to reference styles.css."
  exit 1
fi

echo "Website validation passed."
