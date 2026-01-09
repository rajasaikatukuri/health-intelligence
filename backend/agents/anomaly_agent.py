"""Anomaly detection agent."""
from typing import Dict, List, Any, Tuple
from langchain.schema import HumanMessage, SystemMessage
from llm_client import llm_client
import statistics


def detect_anomalies(query_results: Dict[str, Any], metric_column: str = None) -> List[Dict[str, Any]]:
    """
    Detect anomalies in query results.
    
    Returns list of anomalies with descriptions.
    """
    rows = query_results.get('rows', [])
    columns = query_results.get('columns', [])
    
    if not rows:
        return []
    
    # Find metric column
    if not metric_column:
        # Look for common metric columns
        for col in ['value', 'steps_total', 'hr_avg', 'distance_km_total', 'active_kcal_total']:
            if col in columns:
                metric_column = col
                break
        
        if not metric_column:
            # Use first numeric column
            for col in columns:
                if col not in ['tenant_id', 'dt', 'day', 'week_start']:
                    metric_column = col
                    break
    
    if not metric_column:
        return []
    
    # Extract values
    values = []
    for row in rows:
        if metric_column in row:
            try:
                val = float(row[metric_column])
                values.append(val)
            except (ValueError, TypeError):
                continue
    
    if len(values) < 3:
        return []
    
    # Statistical anomaly detection (Z-score method)
    mean = statistics.mean(values)
    stdev = statistics.stdev(values) if len(values) > 1 else 0
    
    if stdev == 0:
        return []
    
    anomalies = []
    threshold = 2.5  # Z-score threshold
    
    for i, row in enumerate(rows):
        if metric_column in row:
            try:
                val = float(row[metric_column])
                z_score = abs((val - mean) / stdev)
                
                if z_score > threshold:
                    anomalies.append({
                        'row_index': i,
                        'row_data': row,
                        'metric': metric_column,
                        'value': val,
                        'z_score': z_score,
                        'type': 'high' if val > mean else 'low'
                    })
            except (ValueError, TypeError):
                continue
    
    return anomalies


def explain_anomalies(
    anomalies: List[Dict[str, Any]],
    user_question: str,
    query_results: Dict[str, Any]
) -> str:
    """Generate explanation of detected anomalies."""
    if not anomalies:
        return "No significant anomalies detected in the data."
    
    system_prompt = """You are a data analyst explaining anomalies in health data.
Explain detected anomalies in clear, understandable language.
Focus on what the anomalies mean for the user's health and activity patterns."""

    anomaly_summary = f"Found {len(anomalies)} anomalies:\n"
    for i, anomaly in enumerate(anomalies[:5]):  # Limit to 5
        anomaly_summary += f"\n{i+1}. {anomaly['metric']}: {anomaly['value']} (Z-score: {anomaly['z_score']:.2f}, Type: {anomaly['type']})\n"
        anomaly_summary += f"   Context: {anomaly['row_data']}\n"
    
    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=f"""User question: {user_question}

{anomaly_summary}

Explain these anomalies and what they might mean for the user's health data.""")
    ]
    
    response = llm_client.invoke(messages)
    return response.strip()





