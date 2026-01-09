"""LangGraph state and graph definition."""
from typing import TypedDict, List, Dict, Any, Optional, Literal
from langgraph.graph import StateGraph, END
from agents import (
    classify_intent,
    generate_sql,
    execute_query,
    generate_chart_spec,
    generate_coach_response,
    detect_anomalies,
    explain_anomalies
)


class GraphState(TypedDict):
    """State for LangGraph."""
    user_question: str
    tenant_id: str
    conversation_history: List[Dict[str, str]]
    intent: Optional[str]
    sql_queries: List[str]
    query_results: Optional[Dict[str, Any]]
    chart_specs: List[Dict[str, Any]]
    anomalies: List[Dict[str, Any]]
    final_answer: str
    sql_used: Optional[str]


def router_node(state: GraphState) -> GraphState:
    """Route based on intent."""
    intent = classify_intent(
        state["user_question"],
        state.get("conversation_history", [])
    )
    state["intent"] = intent
    return state


def data_node(state: GraphState) -> GraphState:
    """Generate and execute SQL query."""
    sql = None
    try:
        sql = generate_sql(
            state["user_question"],
            state["intent"],
            state["tenant_id"],
            state.get("conversation_history", [])
        )
        
        state["sql_queries"] = state.get("sql_queries", []) + [sql]
        state["sql_used"] = sql
        
        # Execute query
        query_results = execute_query(sql, state["tenant_id"])
        state["query_results"] = query_results
    except Exception as e:
        # Attach SQL to exception for better error messages
        if sql:
            e.sql_used = sql
        # Store SQL in state for error display
        state["sql_used"] = sql if sql else "SQL generation failed"
        # Re-raise with SQL context
        raise Exception(f"SQL execution failed: {str(e)}\n\nSQL used:\n{state['sql_used']}")
    
    return state


def dashboard_node(state: GraphState) -> GraphState:
    """Generate chart specifications."""
    if not state.get("query_results"):
        return state
    
    chart_spec = generate_chart_spec(
        state["query_results"],
        state["user_question"]
    )
    
    state["chart_specs"] = state.get("chart_specs", []) + [chart_spec]
    return state


def anomaly_node(state: GraphState) -> GraphState:
    """Detect anomalies."""
    if not state.get("query_results"):
        return state
    
    anomalies = detect_anomalies(state["query_results"])
    state["anomalies"] = anomalies
    
    if anomalies:
        explanation = explain_anomalies(
            anomalies,
            state["user_question"],
            state["query_results"]
        )
        # Add to final answer
        state["final_answer"] = state.get("final_answer", "") + f"\n\n{explanation}"
    
    return state


def coach_node(state: GraphState) -> GraphState:
    """Generate coach response."""
    answer = generate_coach_response(
        state["user_question"],
        state.get("query_results", {}),
        state.get("chart_specs", [None])[0] if state.get("chart_specs") else None,
        state.get("conversation_history", [])
    )
    
    state["final_answer"] = answer
    return state


def summary_node(state: GraphState) -> GraphState:
    """Generate summary response."""
    if not state.get("query_results"):
        state["final_answer"] = "No data available to summarize."
        return state
    
    # Use coach agent for summary
    answer = generate_coach_response(
        f"Summarize this data: {state['user_question']}",
        state["query_results"],
        conversation_history=state.get("conversation_history", [])
    )
    
    state["final_answer"] = answer
    return state


def decide_next(state: GraphState) -> Literal["dashboard", "anomaly", "coach", "summary", "end"]:
    """Decide next step based on intent."""
    intent = state.get("intent")
    
    if intent == "dashboard":
        return "dashboard"
    elif intent == "anomaly":
        return "anomaly"
    elif intent == "summary":
        return "summary"
    else:
        return "coach"


# Build graph
def create_graph() -> StateGraph:
    """Create LangGraph workflow."""
    workflow = StateGraph(GraphState)
    
    # Add nodes
    workflow.add_node("router", router_node)
    workflow.add_node("data", data_node)
    workflow.add_node("dashboard", dashboard_node)
    workflow.add_node("anomaly", anomaly_node)
    workflow.add_node("coach", coach_node)
    workflow.add_node("summary", summary_node)
    
    # Set entry point
    workflow.set_entry_point("router")
    
    # Add edges
    workflow.add_edge("router", "data")
    workflow.add_conditional_edges(
        "data",
        decide_next,
        {
            "dashboard": "dashboard",
            "anomaly": "anomaly",
            "coach": "coach",
            "summary": "summary",
            "end": END
        }
    )
    
    # All paths end at coach/summary, then END
    workflow.add_edge("dashboard", "coach")
    workflow.add_edge("anomaly", "coach")
    workflow.add_edge("coach", END)
    workflow.add_edge("summary", END)
    
    return workflow.compile()


# Singleton graph instance
graph = create_graph()


