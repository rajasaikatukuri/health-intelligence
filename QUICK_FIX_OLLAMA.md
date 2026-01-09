# 🚀 Quick Fix: Start Ollama

## The Problem
Your backend needs Ollama to answer questions, but it's not running.

## The Solution (2 Steps)

### Step 1: Start Ollama

Open a **new terminal** and run:

```bash
ollama serve
```

Leave this terminal running. You should see Ollama start up.

### Step 2: Pull the Model (First Time Only)

In **another terminal**, run:

```bash
ollama pull llama3
```

This downloads the llama3 model (takes 2-5 minutes first time).

---

## Verify It's Working

In a new terminal:
```bash
curl http://localhost:11434/api/tags
```

Should return a JSON list of models.

---

## Then Try Your Question Again

Go back to your browser at http://localhost:3000 and ask:
**"Summarize my last 30 days"**

It should work now! 🎉

---

## Quick Reference

**Start Ollama:**
```bash
ollama serve
```

**Check if running:**
```bash
curl http://localhost:11434/api/tags
```

**Pull model (first time):**
```bash
ollama pull llama3
```

**Stop Ollama:**
Press `Ctrl+C` in the terminal where it's running




