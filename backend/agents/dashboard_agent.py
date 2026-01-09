"""Dashboard agent for generating Vega-Lite chart specifications."""
from typing import Dict, List, Any
from langchain.schema import HumanMessage, SystemMessage
from llm_client import llm_client
import json


def generate_chart_spec(
    query_results: Dict[str, Any],
    user_question: str,
    chart_type: str = "auto"
) -> Dict[str, Any]:
    """
    Generate Vega-Lite chart specification from query results.
    
    Returns dict with 'spec_type' and 'spec' (Vega-Lite JSON).
    """
    system_prompt = """You are a chart generator for health data visualizations.
Generate Vega-Lite JSON specifications for data visualizations.

Given query results, create an appropriate chart:
- Time series: Use line or area charts
- Comparisons: Use bar charts
- Distributions: Use histograms or box plots
- Multiple metrics: Use faceted charts or layered charts

Vega-Lite Requirements:
- Use proper data format (array of objects)
- Include proper encoding (x, y, color, etc.)
- Set appropriate scales and axes
- Include titles and labels
- Make charts responsive (width: "container")

Return ONLY valid JSON, no markdown, no explanations."""

    # Format query results for LLM
    columns = query_results.get('columns', [])
    rows = query_results.get('rows', [])
    
    # Limit rows for chart generation (too many rows = complex charts)
    sample_rows = rows[:100] if len(rows) > 100 else rows
    
    data_summary = {
        "columns": columns,
        "row_count": len(rows),
        "sample_rows": sample_rows[:10]  # Show first 10 as example
    }
    
    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=f"""User question: {user_question}
Chart type preference: {chart_type}

Query results:
Columns: {columns}
Total rows: {len(rows)}
Sample data: {json.dumps(sample_rows[:10], default=str)}

Generate a Vega-Lite specification that visualizes this data appropriately.
Return ONLY the JSON specification, wrapped in a JSON object with 'spec_type' and 'spec' keys.""")
    ]
    
    response = llm_client.invoke(messages).strip()
    
    # Parse JSON response
    try:
        # Remove markdown code blocks if present
        if response.startswith("```json"):
            response = response[7:]
        if response.startswith("```"):
            response = response[3:]
        if response.endswith("```"):
            response = response[:-3]
        response = response.strip()
        
        chart_spec = json.loads(response)
        
        # Ensure proper structure
        if 'spec_type' not in chart_spec:
            chart_spec['spec_type'] = 'vega-lite'
        
        if 'spec' not in chart_spec:
            # Assume entire response is the spec
            chart_spec = {
                'spec_type': 'vega-lite',
                'spec': chart_spec
            }
        
        # Add data to spec
        if 'data' not in chart_spec['spec']:
            chart_spec['spec']['data'] = {'values': rows}
        
        return chart_spec
        
    except json.JSONDecodeError:
        # Fallback: Create simple chart
        return create_fallback_chart(columns, rows, user_question)


def create_fallback_chart(columns: List[str], rows: List[Dict], question: str) -> Dict[str, Any]:
    """Create a simple fallback chart when LLM fails."""
    # Find date/time column
    date_col = None
    for col in ['day', 'date', 'dt', 'week_start', 'timestamp']:
        if col in columns:
            date_col = col
            break
    
    # Find numeric columns
    numeric_cols = [col for col in columns if col not in ['tenant_id', 'dt', date_col] and date_col]
    
    if not numeric_cols:
        numeric_cols = [col for col in columns if col != 'tenant_id']
    
    if not date_col and numeric_cols:
        # Bar chart
        return {
            'spec_type': 'vega-lite',
            'spec': {
                'data': {'values': rows},
                'mark': 'bar',
                'encoding': {
                    'x': {'field': numeric_cols[0], 'type': 'quantitative'},
                    'y': {'field': columns[0] if columns else 'value', 'type': 'nominal'}
                },
                'title': question[:50]
            }
        }
    elif date_col and numeric_cols:
        # Line chart
        return {
            'spec_type': 'vega-lite',
            'spec': {
                'data': {'values': rows},
                'mark': 'line',
                'encoding': {
                    'x': {'field': date_col, 'type': 'temporal'},
                    'y': {'field': numeric_cols[0], 'type': 'quantitative'}
                },
                'title': question[:50],
                'width': 'container'
            }
        }
    else:
        # Simple table visualization
        return {
            'spec_type': 'vega-lite',
            'spec': {
                'data': {'values': rows},
                'mark': 'rect',
                'encoding': {
                    'x': {'field': columns[0], 'type': 'nominal'},
                    'y': {'field': columns[1] if len(columns) > 1 else 'value', 'type': 'nominal'},
                    'color': {'field': numeric_cols[0] if numeric_cols else columns[-1], 'type': 'quantitative'}
                }
            }
        }





