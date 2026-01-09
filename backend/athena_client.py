"""AWS Athena client for querying health data."""
import time
import hashlib
import json
from typing import Dict, List, Optional, Any
import boto3
from botocore.exceptions import ClientError
from config import settings


class AthenaClient:
    """Client for executing Athena queries with tenant isolation."""
    
    def __init__(self):
        self.athena = boto3.client('athena', region_name=settings.aws_region)
        self.s3 = boto3.client('s3', region_name=settings.aws_region)
    
    def _ensure_tenant_filter(self, sql: str, tenant_id: str) -> str:
        """Ensure SQL includes tenant_id filter."""
        sql_upper = sql.upper()
        
        # Check if WHERE clause exists
        if "WHERE" in sql_upper:
            # Check if tenant_id filter already exists
            if f"tenant_id = '{tenant_id}'" in sql or f"tenant_id = \"{tenant_id}\"" in sql:
                return sql
            
            # Add tenant_id filter to existing WHERE
            # Find WHERE and add tenant_id condition
            where_pos = sql_upper.find("WHERE")
            where_clause = sql[where_pos + 5:].strip()
            
            # Add tenant_id filter
            if "tenant_id" not in where_clause.upper():
                sql = sql[:where_pos + 5] + f" tenant_id = '{tenant_id}' AND ({where_clause})"
        else:
            # Add WHERE clause with tenant_id
            sql = f"{sql} WHERE tenant_id = '{tenant_id}'"
        
        return sql
    
    def execute_query(
        self,
        sql: str,
        tenant_id: str,
        timeout: int = None
    ) -> Dict[str, Any]:
        """
        Execute Athena query with tenant isolation.
        
        Args:
            sql: SQL query (will be modified to include tenant_id filter)
            tenant_id: Tenant ID for data isolation
            timeout: Query timeout in seconds
            
        Returns:
            Dictionary with 'columns', 'rows', 'query_id', 'execution_time'
        """
        timeout = timeout or settings.max_query_timeout
        
        # Ensure tenant_id filter
        sql = self._ensure_tenant_filter(sql, tenant_id)
        
        # Replace ${tenant_id} placeholder if present
        sql = sql.replace("${tenant_id}", tenant_id)
        
        # Start query execution
        try:
            response = self.athena.start_query_execution(
                QueryString=sql,
                QueryExecutionContext={
                    'Database': settings.athena_database
                },
                ResultConfiguration={
                    'OutputLocation': f's3://{settings.s3_results_bucket}/{settings.s3_results_prefix}'
                },
                WorkGroup=settings.athena_workgroup
            )
            
            query_id = response['QueryExecutionId']
            
            # Poll for completion
            start_time = time.time()
            while True:
                execution = self.athena.get_query_execution(QueryExecutionId=query_id)
                status = execution['QueryExecution']['Status']['State']
                
                if status == 'SUCCEEDED':
                    break
                elif status in ['FAILED', 'CANCELLED']:
                    reason = execution['QueryExecution']['Status'].get('StateChangeReason', 'Unknown error')
                    raise Exception(f"Query failed: {reason}")
                
                if time.time() - start_time > timeout:
                    self.athena.stop_query_execution(QueryExecutionId=query_id)
                    raise Exception(f"Query timeout after {timeout} seconds")
                
                time.sleep(2)
            
            execution_time = time.time() - start_time
            
            # Get results
            results = self.athena.get_query_results(QueryExecutionId=query_id)
            
            # Parse results
            columns = [col['Name'] for col in results['ResultSet']['ResultSetMetadata']['ColumnInfo']]
            rows = []
            
            for row in results['ResultSet']['Rows'][1:]:  # Skip header
                values = []
                for i, col in enumerate(row['Data']):
                    value = col.get('VarCharValue', '')
                    # Try to parse as number if possible
                    try:
                        if '.' in value:
                            values.append(float(value))
                        else:
                            values.append(int(value))
                    except (ValueError, TypeError):
                        values.append(value)
                rows.append(dict(zip(columns, values)))
            
            return {
                'columns': columns,
                'rows': rows,
                'query_id': query_id,
                'execution_time': execution_time,
                'sql': sql
            }
            
        except ClientError as e:
            raise Exception(f"AWS error: {str(e)}")
    
    def get_query_cache_key(self, sql: str, tenant_id: str) -> str:
        """Generate cache key for query."""
        cache_string = f"{sql}:{tenant_id}"
        return hashlib.md5(cache_string.encode()).hexdigest()


# Singleton instance
athena_client = AthenaClient()

