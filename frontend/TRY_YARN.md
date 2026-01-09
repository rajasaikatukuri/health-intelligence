# Alternative: Use Yarn Instead of npm

npm is having issues with vega dependencies. Try using Yarn instead.

## Install Yarn

```bash
brew install yarn
```

## Install Dependencies

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/frontend

# Clean up
rm -rf node_modules package-lock.json yarn.lock

# Install with yarn
yarn install

# Start
yarn dev
```

Yarn handles peer dependencies better and should resolve the vega-crossfilter issue.

---

## Or: Use Simplified Package (No Vega Direct Dependencies)

If yarn doesn't work, we can use a version that only includes vega-embed (which bundles everything):

```bash
# Backup current package.json
cp package.json package.json.backup

# Use simplified version
cp package-simple.json package.json

# Install
npm install

# Start
npm run dev
```

This uses only `vega-embed` which includes vega and vega-lite internally.

---

**Try yarn first - it usually handles these dependency conflicts better!** 🚀





