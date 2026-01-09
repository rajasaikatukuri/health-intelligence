FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements (from backend directory)
COPY backend/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code (from backend directory)
COPY backend/ .

# Create logs directory
RUN mkdir -p /app/logs

# Expose port (Render provides PORT env var)
EXPOSE 8000

# Health check (Render uses its own health checks, this is for local testing)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8000}/health || exit 1

# Run application
# Render will set PORT environment variable automatically
# Use uvicorn directly for better compatibility with Render
CMD python3 -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}

