# Fix: jose Import Error

The error is caused by a conflicting `jose` package (Python 2) instead of `python-jose`.

## Quick Fix

Run this in your terminal:

```bash
cd /Users/rajasaikatukuri/Documents/health-pipeline/health-intelligence/backend

# Remove old venv
rm -rf venv

# Create new venv
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Uninstall any conflicting jose package
pip uninstall -y jose 2>/dev/null || true

# Install correct dependencies
pip install -r requirements.txt
```

**Or use the fix script:**
```bash
./fix_dependencies.sh
```

## What Was Wrong

- Old `jose` package (Python 2) was installed
- We need `python-jose` (Python 3)
- The imports were conflicting

## After Fix

Start the backend:
```bash
source venv/bin/activate
python3 main.py
```

**This should work now!** ✅





