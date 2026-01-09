# Fix: npm install Error

The error is about `vega-crossfilter` version mismatch. Here's how to fix it.

## Quick Fix

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/frontend

# Clean up
rm -rf node_modules package-lock.json

# Install with legacy peer deps (handles version conflicts)
npm install --legacy-peer-deps
```

**Or try without legacy flag:**
```bash
npm install
```

## Alternative: Use Yarn

If npm continues to have issues:

```bash
# Install yarn (if not installed)
brew install yarn

# Use yarn instead
yarn install
yarn dev
```

## What Was Wrong

- `vega-embed` has a dependency on `vega-crossfilter@~4.1.4`
- That exact version might not exist
- Using `--legacy-peer-deps` allows npm to use compatible versions

## After Fix

Start the frontend:
```bash
npm run dev
```

**This should work now!** ✅





