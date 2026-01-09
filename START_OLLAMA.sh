#!/bin/bash
# Start Ollama LLM server

echo "=========================================="
echo "🤖 Starting Ollama LLM Server"
echo "=========================================="
echo ""

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed!"
    echo ""
    echo "Install with:"
    echo "  brew install ollama"
    echo ""
    echo "Or download from: https://ollama.ai"
    exit 1
fi

# Check if Ollama is already running
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama is already running"
    echo ""
    echo "Checking available models..."
    ollama list
    exit 0
fi

echo "Starting Ollama server..."
echo ""

# Start Ollama in background
ollama serve > /dev/null 2>&1 &
OLLAMA_PID=$!

# Wait for Ollama to start
echo "Waiting for Ollama to start..."
for i in {1..10}; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama started successfully (PID: $OLLAMA_PID)"
        break
    fi
    sleep 1
done

# Check if we have the model
echo ""
echo "Checking for llama3 model..."
if ollama list | grep -q "llama3"; then
    echo "✅ llama3 model is available"
else
    echo "⚠️  llama3 model not found. Pulling it now..."
    echo "   This may take a few minutes..."
    ollama pull llama3
    echo "✅ llama3 model downloaded"
fi

echo ""
echo "=========================================="
echo "✅ Ollama is ready!"
echo "=========================================="
echo ""
echo "📍 Ollama API: http://localhost:11434"
echo "🤖 Model: llama3"
echo ""
echo "🛑 To stop Ollama: kill $OLLAMA_PID"
echo "   Or: pkill ollama"
echo ""




