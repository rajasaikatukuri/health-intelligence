"""FastAPI main application."""
from fastapi import FastAPI, Depends, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from auth import verify_token, get_tenant_id_from_token, dev_login
from graph import graph, GraphState
from config import settings

app = FastAPI(title="Health Intelligence Platform", version="1.0.0")

# CORS Configuration - Parse from environment variable
cors_origins_list = [
    origin.strip() 
    for origin in settings.cors_origins.split(",") 
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)


# Request/Response models
class ChatRequest(BaseModel):
    message: str


class ChartSpec(BaseModel):
    spec_type: str
    spec: Dict[str, Any]


class ChatResponse(BaseModel):
    answer: str
    charts: Optional[List[ChartSpec]] = None
    sql_used: Optional[str] = None
    query_results: Optional[Dict[str, Any]] = None


class LoginRequest(BaseModel):
    username: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str
    tenant_id: str
    username: str


class MeResponse(BaseModel):
    tenant_id: str
    username: str


# Session storage (in production, use Redis or database)
sessions: Dict[str, List[Dict[str, str]]] = {}


def get_tenant_id(authorization: Optional[str] = Header(None)) -> str:
    """Extract tenant_id from JWT token."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing authorization")
    
    token = authorization.replace("Bearer ", "")
    return get_tenant_id_from_token(token)


@app.post("/api/auth/login", response_model=LoginResponse)
def login(request: LoginRequest):
    """Dev login: username = tenant_id."""
    return dev_login(request.username)


@app.get("/api/me", response_model=MeResponse)
def get_me(tenant_id: str = Depends(get_tenant_id), authorization: Optional[str] = Header(None)):
    """Get current user info."""
    token = authorization.replace("Bearer ", "")
    payload = verify_token(token)
    
    return MeResponse(
        tenant_id=tenant_id,
        username=payload.get("username", "unknown")
    )


@app.post("/api/chat", response_model=ChatResponse)
def chat(
    request: ChatRequest,
    tenant_id: str = Depends(get_tenant_id),
    authorization: Optional[str] = Header(None)
):
    """
    Chat endpoint for health data queries.
    
    Returns natural language answer, optional charts, and SQL used.
    """
    # Get conversation history
    session_key = f"{tenant_id}:{authorization}"
    conversation_history = sessions.get(session_key, [])
    
    # Limit history to last 10 messages
    if len(conversation_history) > 10:
        conversation_history = conversation_history[-10:]
    
    # Initialize state
    initial_state: GraphState = {
        "user_question": request.message,
        "tenant_id": tenant_id,
        "conversation_history": conversation_history,
        "intent": None,
        "sql_queries": [],
        "query_results": None,
        "chart_specs": [],
        "anomalies": [],
        "final_answer": "",
        "sql_used": None
    }
    
    # Run graph
    try:
        final_state = graph.invoke(initial_state)
    except Exception as e:
        # Include SQL in error for debugging
        error_detail = str(e)
        if hasattr(e, 'sql_used'):
            error_detail += f"\n\nSQL used: {e.sql_used}"
        elif 'sql_used' in locals():
            error_detail += f"\n\nSQL used: {sql_used}"
        raise HTTPException(status_code=500, detail=f"Error processing query: {error_detail}")
    
    # Update conversation history
    conversation_history.append({
        "user": request.message,
        "assistant": final_state.get("final_answer", "")
    })
    sessions[session_key] = conversation_history
    
    # Build response
    charts = None
    if final_state.get("chart_specs"):
        charts = [
            ChartSpec(**spec) for spec in final_state["chart_specs"]
        ]
    
    return ChatResponse(
        answer=final_state.get("final_answer", "No response generated."),
        charts=charts,
        sql_used=final_state.get("sql_used"),
        query_results=final_state.get("query_results")
    )


@app.post("/api/chat/explain-chart")
def explain_chart(
    chart_spec: ChartSpec,
    summary: str,
    tenant_id: str = Depends(get_tenant_id)
):
    """
    Explain a chart visualization.
    
    Takes chart spec and summary, returns explanation.
    """
    from agents.coach_agent import generate_coach_response
    
    explanation = generate_coach_response(
        f"Explain this chart: {summary}",
        {},  # No query results needed
        chart_spec.dict()
    )
    
    return {"explanation": explanation}


@app.get("/health")
def health():
    """
    Health check endpoint for Render.
    Returns 200 OK if service is healthy.
    """
    return {
        "status": "healthy",
        "service": "health-intelligence-backend",
        "aws_region": settings.aws_region,
        "athena_database": settings.athena_database
    }

@app.get("/")
def root():
    """Root endpoint."""
    return {
        "service": "Health Intelligence Platform API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    )

