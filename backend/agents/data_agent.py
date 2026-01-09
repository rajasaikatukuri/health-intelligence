"""Data agent for generating and executing SQL queries."""
from typing import Dict, List, Any
from langchain.schema import HumanMessage, SystemMessage
from athena_client import athena_client
from cache import cache
from llm_client import llm_client
from config import settings


def generate_sql(user_question: str, intent: str, tenant_id: str, conversation_history: list = None) -> str:
    """
    Generate SQL query from user question.
    
    Always includes tenant_id filter for security.
    """
    system_prompt = f"""You are a SQL query generator for health data analytics.
Generate SQL queries for AWS Athena (Presto SQL dialect).

Available tables:
1. gold_daily_features: Daily aggregated features
   - Columns: day, steps_total, distance_km_total, active_kcal_total, basal_kcal_total, 
              flights_total, hr_avg, hr_max, hr_min, tenant_id, dt
   - Partitioned by: tenant_id, dt

2. gold_weekly_features: Weekly aggregated features
   - Columns: week_start, steps_week, distance_km_week, active_kcal_week, basal_kcal_week,
              flights_week, hr_avg_week, hr_max_week, hr_min_week, tenant_id, week_start
   - Partitioned by: tenant_id, week_start

3. gold_daily_by_type: Daily aggregations by data type
   - Columns: day, data_type, samples, sum_value, avg_value, min_value, max_value, tenant_id, dt
   - Partitioned by: tenant_id, dt

4. silver_health: Raw data view
   - Columns: tenant_id, day, date_parsed, week_start, data_type, value, timestamp_unix, etc.

CRITICAL SECURITY RULES:
- ALWAYS include WHERE tenant_id = '{tenant_id}' in every query
- Use partition pruning: dt >= DATE_FORMAT(DATE_ADD('day', -{settings.default_lookback_days}, CURRENT_DATE), '%Y-%m-%d')
- Never query across tenants
- Use gold tables for aggregations (faster, cheaper)

SQL Requirements:
- Use Presto SQL syntax (Athena)
- No timestamp with timezone types
- Partition keys (tenant_id, dt/week_start) must be in WHERE clause
- Use proper SQL syntax: parentheses must match, CASE statements must have END
- For date comparisons, use: dt >= '2024-01-01' (string format)
- For date arithmetic, use: DATE_ADD('day', -7, CURRENT_DATE)

CRITICAL: Return ONLY the COMPLETE SQL query. Do NOT include:
- Explanatory text before the query (e.g., "Here is the SQL:")
- Explanatory text after the query
- Markdown formatting unless necessary
- Any text that is not SQL code

IMPORTANT: The SQL query MUST be complete and executable:
- If using WITH clauses, include ALL CTEs and a final SELECT statement
- All parentheses must be balanced
- All statements must be complete (no truncated queries)
- The query must end with a valid SELECT statement (not just a CTE definition)

Start your response directly with SELECT, WITH, or another SQL keyword.

Example valid SQL for simple query:
SELECT day, steps_total, hr_avg 
FROM health_data_lake.gold_daily_features 
WHERE tenant_id = '{tenant_id}' 
  AND dt >= DATE_FORMAT(DATE_ADD('day', -30, CURRENT_DATE), '%Y-%m-%d')
ORDER BY day DESC

Example valid SQL for comparison (last 7 days vs previous 7 days):
WITH last_7_days AS (
  SELECT 
    SUM(steps_total) as steps,
    AVG(hr_avg) as avg_hr,
    SUM(active_kcal_total) as calories
  FROM health_data_lake.gold_daily_features
  WHERE tenant_id = '{tenant_id}'
    AND dt >= DATE_FORMAT(DATE_ADD('day', -7, CURRENT_DATE), '%Y-%m-%d')
    AND dt < DATE_FORMAT(CURRENT_DATE, '%Y-%m-%d')
),
prev_7_days AS (
  SELECT 
    SUM(steps_total) as steps,
    AVG(hr_avg) as avg_hr,
    SUM(active_kcal_total) as calories
  FROM health_data_lake.gold_daily_features
  WHERE tenant_id = '{tenant_id}'
    AND dt >= DATE_FORMAT(DATE_ADD('day', -14, CURRENT_DATE), '%Y-%m-%d')
    AND dt < DATE_FORMAT(DATE_ADD('day', -7, CURRENT_DATE), '%Y-%m-%d')
)
SELECT 
  'Last 7 Days' as period,
  l.steps,
  l.avg_hr,
  l.calories
FROM last_7_days l
UNION ALL
SELECT 
  'Previous 7 Days' as period,
  p.steps,
  p.avg_hr,
  p.calories
FROM prev_7_days p"""

    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=f"Generate SQL for: {user_question}\nIntent: {intent}")
    ]
    
    if conversation_history:
        context = "\n".join([f"User: {h.get('user', '')}\nSQL: {h.get('sql', 'N/A')}" for h in conversation_history[-2:]])
        messages.insert(1, HumanMessage(content=f"Previous queries:\n{context}"))
    
    sql = llm_client.invoke(messages).strip()
    
    # Log raw response for debugging
    import logging
    logging.basicConfig(level=logging.DEBUG)
    logger = logging.getLogger(__name__)
    logger.debug(f"Raw LLM response:\n{sql}")
    
    # Clean SQL (remove markdown code blocks if present)
    if sql.startswith("```sql"):
        sql = sql[6:]
    if sql.startswith("```"):
        sql = sql[3:]
    if sql.endswith("```"):
        sql = sql[:-3]
    sql = sql.strip()
    
    # Remove any terminal output artifacts (e.g., @bash (171-201))
    import re
    sql = re.sub(r'@bash\s*\([^)]+\)', '', sql)
    sql = re.sub(r'@\w+\s*\([^)]+\)', '', sql)  # Remove any @command (numbers) patterns
    sql = sql.strip()
    
    # Extract SQL from text that may contain explanations
    # Find the first SQL keyword (SELECT, WITH, CREATE, etc.)
    sql_keywords = ['SELECT', 'WITH', 'CREATE', 'INSERT', 'UPDATE', 'DELETE', 'ALTER', 'DROP']
    sql_upper = sql.upper()
    
    # Find the first SQL keyword
    first_keyword_pos = -1
    first_keyword = None
    for keyword in sql_keywords:
        pos = sql_upper.find(keyword)
        if pos != -1 and (first_keyword_pos == -1 or pos < first_keyword_pos):
            first_keyword_pos = pos
            first_keyword = keyword
    
    if first_keyword_pos > 0:
        # Remove text before the first SQL keyword
        sql = sql[first_keyword_pos:]
    
    # Final cleanup - be more careful about preserving complete SQL
    sql = sql.strip()
    
    # Remove any trailing explanatory text (common patterns)
    # But be careful not to cut off valid SQL
    lines = sql.split('\n')
    cleaned_lines = []
    in_sql_block = True
    
    for i, line in enumerate(lines):
        line_stripped = line.strip()
        if not line_stripped:
            # Empty lines are OK in SQL
            cleaned_lines.append(line)
            continue
            
        line_upper = line_stripped.upper()
        
        # Stop if we hit clear explanatory text (but only if we're not in the middle of SQL)
        if line_upper.startswith(('NOTE:', 'THIS', 'THE QUERY', 'HERE IS', 'EXPLANATION:', 'REMEMBER:', 'TIP:', 'NOTE THAT')):
            # Only break if this is clearly separate from SQL (not part of a string literal)
            break
        
        # Check if line looks like SQL continuation
        # SQL can have: keywords, identifiers, operators, literals, comments
        is_sql_line = (
            line_upper.startswith(('SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'GROUP', 'ORDER', 'HAVING', 
                                   'WITH', 'AS', 'CASE', 'WHEN', 'THEN', 'ELSE', 'END', 'JOIN', 
                                   'INNER', 'LEFT', 'RIGHT', 'ON', 'UNION', 'INTERSECT', 'EXCEPT', 
                                   'LIMIT', 'OFFSET', '--', '/*', '(', ')', ',', ';')) or
            line_upper.startswith(('=', '<', '>', '<=', '>=', '!=', '<>', '+', '-', '*', '/', '%', '||')) or
            line_upper.startswith(('LIKE', 'IN', 'IS', 'NULL', 'NOT', 'EXISTS', 'BETWEEN', 'CAST', 
                                   'COUNT', 'SUM', 'AVG', 'MAX', 'MIN', 'COALESCE', 'DATE_', 'CURRENT_')) or
            line_stripped.startswith("'") or  # String literal
            line_stripped.startswith('"') or  # String literal
            line_stripped[0].isdigit() or      # Number
            line_stripped.startswith('@') or   # Variable (but this might be terminal output)
            (line_stripped[0].isalpha() and len(line_stripped) > 0)  # Identifier
        )
        
        # Special check: if line starts with '@' and contains 'bash' or looks like terminal output, skip it
        if line_stripped.startswith('@') and ('bash' in line_stripped.lower() or re.match(r'@\w+\s*\(\d+-\d+\)', line_stripped)):
            break
            
        if is_sql_line:
            cleaned_lines.append(line)
        elif i == 0:
            # First line must be SQL
            cleaned_lines.append(line)
        else:
            # If we've been collecting SQL and hit something that doesn't look like SQL,
            # it might be explanatory text - but be conservative
            # Only break if it's clearly not SQL (e.g., starts with lowercase word that's not a SQL keyword)
            if line_stripped and not any(line_stripped.startswith(prefix) for prefix in ['--', '/*', "'", '"', '(', ')', ',']):
                # Check if it's a complete sentence (has period and capital letter)
                if '.' in line_stripped and line_stripped[0].isupper() and len(line_stripped.split()) > 3:
                    break
            cleaned_lines.append(line)
    
    sql = '\n'.join(cleaned_lines).strip()
    
    # Remove trailing semicolon if present (Athena doesn't require it)
    if sql.endswith(';'):
        sql = sql[:-1].strip()
    
    # Validate SQL completeness
    open_parens = sql.count('(')
    close_parens = sql.count(')')
    if open_parens != close_parens:
        import logging
        logging.basicConfig(level=logging.WARNING)
        logger = logging.getLogger(__name__)
        logger.warning(f"SQL has unbalanced parentheses: {open_parens} open, {close_parens} close")
    
    # Check for incomplete WITH clauses - if we have WITH but no final SELECT, it's incomplete
    sql_upper_clean = re.sub(r'\s+', ' ', sql.upper())
    if sql_upper_clean.startswith('WITH'):
        # Count WITH clauses - each should have AS (SELECT ...)
        with_count = sql_upper_clean.count('WITH')
        as_count = sql_upper_clean.count(' AS (')
        # Should have at least one final SELECT after all WITH clauses
        final_select_pos = sql_upper_clean.rfind(' SELECT ')
        if final_select_pos == -1 or as_count < with_count:
            import logging
            logging.basicConfig(level=logging.WARNING)
            logger = logging.getLogger(__name__)
            logger.warning(f"SQL WITH clause may be incomplete. WITH count: {with_count}, AS count: {as_count}, Final SELECT: {final_select_pos != -1}")
    
    # Log the full SQL for debugging
    import logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    logger.info(f"Generated SQL (full, {len(sql)} chars):\n{sql}")
    
    return sql


def execute_query(sql: str, tenant_id: str, use_cache: bool = True) -> Dict[str, Any]:
    """Execute SQL query with caching."""
    # Validate SQL before executing
    sql_upper = sql.upper().strip()
    if not sql_upper.startswith(('SELECT', 'WITH', 'CREATE', 'INSERT', 'UPDATE', 'DELETE')):
        raise ValueError(f"Invalid SQL query. Must start with SELECT, WITH, CREATE, etc. Got: {sql[:100]}")
    
    # Check cache
    cache_key = athena_client.get_query_cache_key(sql, tenant_id)
    
    if use_cache:
        cached_result = cache.get(cache_key)
        if cached_result:
            cached_result['cached'] = True
            return cached_result
    
    # Execute query
    try:
        result = athena_client.execute_query(sql, tenant_id)
    except Exception as e:
        # Attach SQL to exception for better error messages
        e.sql_used = sql
        raise
    
    # Cache result
    if use_cache:
        cache.set(cache_key, result)
    
    result['cached'] = False
    return result


