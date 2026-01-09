# Fix: vega-crossfilter Dependency Issue

The issue is that `vega-embed` has a dependency on `vega-crossfilter@~4.1.4` which doesn't exist.

## Solution: Use Only vega-embed

I've simplified `package.json` to only use `vega-embed`, which bundles vega and vega-lite internally.

## Install

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/frontend

# Clean up
rm -rf node_modules package-lock.json

# Install
npm install
```

This should work because `vega-embed` includes everything needed.

## If Still Fails: Use npm with force

```bash
npm install --force
```

Or:

```bash
npm install --legacy-peer-deps --force
```

## After Installation

Start the frontend:

```bash
npm run dev
```

---

**The simplified package.json should work!** ✅





