"""Router agent for intent classification."""
from typing import Literal
from langchain.schema import HumanMessage, SystemMessage
from llm_client import llm_client


INTENT_TYPES = Literal[
    "summary",
    "trend",
    "comparison",
    "dashboard",
    "anomaly",
    "coach",
    "general"
]


def classify_intent(user_question: str, conversation_history: list = None) -> str:
    """
    Classify user intent from question.
    
    Returns one of: summary, trend, comparison, dashboard, anomaly, coach, general
    """
    system_prompt = """You are an intent classifier for a health data analytics system.
Classify the user's question into one of these intents:

- summary: Questions asking for summaries, overviews, or general statistics
- trend: Questions about trends, patterns, or changes over time
- comparison: Questions comparing different time periods or metrics
- dashboard: Questions asking to create or show dashboards/visualizations
- anomaly: Questions about anomalies, outliers, or unusual patterns
- coach: Questions asking for advice, explanations, or health coaching
- general: General questions that don't fit other categories

Respond with ONLY the intent name, nothing else."""

    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=f"Question: {user_question}")
    ]
    
    if conversation_history:
        context = "\n".join([f"User: {h.get('user', '')}" for h in conversation_history[-3:]])
        messages.insert(1, HumanMessage(content=f"Recent conversation:\n{context}"))
    
    intent = llm_client.invoke(messages).strip().lower()
    
    # Validate intent
    valid_intents = ["summary", "trend", "comparison", "dashboard", "anomaly", "coach", "general"]
    if intent not in valid_intents:
        # Default to general if invalid
        return "general"
    
    return intent






