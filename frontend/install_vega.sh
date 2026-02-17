#!/bin/bash
# Install vega dependencies

cd "$(dirname "$0")"

echo "Installing vega dependencies..."
npm install vega@5.25.0 vega-lite@5.16.3 --legacy-peer-deps --save

echo ""
echo "✅ Vega dependencies installed!"
echo ""
echo "Now restart the dev server:"
echo "  npm run dev"






