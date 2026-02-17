"""Coach agent for explaining trends and providing health insights."""
from typing import Dict, List, Any
from langchain.schema import HumanMessage, SystemMessage
from llm_client import llm_client


def generate_coach_response(
    user_question: str,
    query_results: Dict[str, Any],
    chart_spec: Dict[str, Any] = None,
    conversation_history: list = None
) -> str:
    """
    Generate coach response explaining data and providing insights.
    
    Can optionally use web search for additional context.
    """
    system_prompt = """You are a health and fitness coach AI assistant.
Your role is to:
1. Explain health data trends and patterns in simple, understandable language
2. Provide actionable insights and recommendations
3. Help users understand what their data means
4. Answer health-related questions based on the data

Guidelines:
- Be encouraging and positive
- Use simple language (avoid medical jargon)
- Provide actionable advice
- Reference specific numbers from the data
- Explain what trends mean for health
- Be careful not to provide medical advice (encourage consulting healthcare providers for medical concerns)

If asked about general health topics, you can provide educational information."""

    # Format data summary
    columns = query_results.get('columns', [])
    rows = query_results.get('rows', [])
    
    data_summary = f"Data columns: {', '.join(columns)}\n"
    data_summary += f"Number of records: {len(rows)}\n"
    
    if rows:
        # Show summary statistics
        data_summary += "\nSample data:\n"
        for i, row in enumerate(rows[:5]):
            data_summary += f"  {i+1}. {row}\n"
    
    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=f"""User question: {user_question}

{data_summary}

{('Chart visualization is available' if chart_spec else 'No chart available')}

Provide a helpful, encouraging response that explains the data and answers the user's question.""")
    ]
    
    if conversation_history:
        context = "\n".join([
            f"User: {h.get('user', '')}\nAssistant: {h.get('assistant', '')[:100]}..."
            for h in conversation_history[-3:]
        ])
        messages.insert(1, HumanMessage(content=f"Recent conversation:\n{context}"))
    
    response = llm_client.invoke(messages)
    return response.strip()






