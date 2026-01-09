#!/bin/bash
# Test login functionality

set -e

API_URL="http://localhost:8000"
USERNAME="rajasaikatukuri"

echo "=========================================="
echo "Testing Login Functionality"
echo "=========================================="
echo ""

# Step 1: Check if backend is running
echo "Step 1: Checking if backend is running..."
if curl -s "$API_URL/health" > /dev/null 2>&1; then
    echo "✅ Backend is running"
    HEALTH=$(curl -s "$API_URL/health")
    echo "   Response: $HEALTH"
else
    echo "❌ Backend is NOT running!"
    echo ""
    echo "Start it with:"
    echo "   cd backend && ./start.sh"
    exit 1
fi
echo ""

# Step 2: Test login endpoint
echo "Step 2: Testing login endpoint..."
echo "   POST $API_URL/api/auth/login"
echo "   Body: {\"username\": \"$USERNAME\"}"
echo ""

LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"$USERNAME\"}" \
    -w "\nHTTP_CODE:%{http_code}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
BODY=$(echo "$LOGIN_RESPONSE" | grep -v "HTTP_CODE")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Login successful!"
    echo ""
    echo "Response:"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""
    
    # Extract token
    TOKEN=$(echo "$BODY" | jq -r '.access_token' 2>/dev/null || echo "")
    TENANT_ID=$(echo "$BODY" | jq -r '.tenant_id' 2>/dev/null || echo "")
    
    if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
        echo "✅ Token received: ${TOKEN:0:20}..."
        echo "✅ Tenant ID: $TENANT_ID"
        echo ""
        
        # Step 3: Test /api/me endpoint
        echo "Step 3: Testing /api/me endpoint..."
        ME_RESPONSE=$(curl -s -X GET "$API_URL/api/me" \
            -H "Authorization: Bearer $TOKEN" \
            -w "\nHTTP_CODE:%{http_code}")
        
        ME_HTTP_CODE=$(echo "$ME_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
        ME_BODY=$(echo "$ME_RESPONSE" | grep -v "HTTP_CODE")
        
        if [ "$ME_HTTP_CODE" = "200" ]; then
            echo "✅ /api/me works!"
            echo "Response:"
            echo "$ME_BODY" | jq '.' 2>/dev/null || echo "$ME_BODY"
        else
            echo "❌ /api/me failed: HTTP $ME_HTTP_CODE"
            echo "Response: $ME_BODY"
        fi
    else
        echo "⚠️  Token not found in response"
    fi
else
    echo "❌ Login failed: HTTP $HTTP_CODE"
    echo ""
    echo "Response:"
    echo "$BODY"
    echo ""
    echo "Possible issues:"
    echo "  1. Backend not running"
    echo "  2. CORS issue"
    echo "  3. Authentication error"
    echo "  4. Check backend logs for errors"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "If login works here but not in browser:"
echo "  1. Check browser console (F12) for errors"
echo "  2. Check CORS settings"
echo "  3. Check network tab for failed requests"
echo "  4. Verify frontend is calling: $API_URL/api/auth/login"
echo ""
