#!/bin/bash
# visa-itinerary-gen dependency check
# This script only CHECKS for dependencies — it does NOT install anything.
# If a dependency is missing, it prints the install command for the user to run manually.

set -e

echo "=== visa-itinerary-gen dependency check ==="
echo ""

MISSING=0

# 1. Check node
if ! command -v node &> /dev/null; then
  echo "✗ Node.js — missing. Install from https://nodejs.org/"
  MISSING=1
else
  echo "✓ Node.js found"
fi

# 2. Check flyai-cli
if ! command -v flyai &> /dev/null; then
  echo "✗ flyai-cli — missing. Run: npm i -g @fly-ai/flyai-cli"
  MISSING=1
else
  echo "✓ flyai-cli found"
fi

# 3. Check python3
if ! command -v python3 &> /dev/null; then
  echo "✗ Python 3 — missing. Install from https://python.org/"
  MISSING=1
else
  echo "✓ Python 3 found"
fi

# 4. Check playwright
if ! python3 -c "import playwright" &> /dev/null 2>&1; then
  echo "✗ playwright — missing. Run: pip3 install playwright && python3 -m playwright install chromium"
  MISSING=1
else
  echo "✓ playwright found"
fi

echo ""

if [ $MISSING -eq 1 ]; then
  echo "=== Some dependencies are missing. Please install them and run this check again. ==="
  exit 1
fi

# 5. Verify flyai works
echo "Verifying flyai..."
flyai fliggy-fast-search --query "test" > /dev/null 2>&1 && echo "✓ flyai verified" || echo "⚠ flyai returned error (may still work)"

echo ""
echo "=== All dependencies satisfied ==="
echo ""
echo "Usage: Ask your AI assistant:"
echo '  "帮我生成一份签证行程单，4个人4月底从杭州去意大利和法国"'
echo ""
