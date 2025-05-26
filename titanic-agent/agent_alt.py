#!/usr/bin/env python3
"""
Alternative Titanic agent configuration with code execution
Tests different approaches to enable both BigQuery and code execution
"""

from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from google.adk.code_executors import BuiltInCodeExecutor
from google.cloud import bigquery
import pandas as pd
from typing import Any, Dict
import os

def query_bigquery(query: str) -> Dict[str, Any]:
    """
    Execute a BigQuery SQL query on the Titanic dataset.
    
    Args:
        query: SQL query to execute. Available table: titanic
        
    Returns:
        Dictionary containing query results, columns, and metadata
    """
    try:
        client = bigquery.Client(project='agentic-data-science-460701')
        
        # Add project and dataset context if not specified
        if "FROM " in query.upper() and "." not in query.split("FROM")[1].split()[0]:
            # Replace table name with fully qualified name
            parts = query.split()
            for i, part in enumerate(parts):
                if part.upper() == "FROM" and i + 1 < len(parts):
                    table_name = parts[i + 1].split()[0].strip(",();")
                    if "." not in table_name:
                        parts[i + 1] = parts[i + 1].replace(
                            table_name, 
                            f"`agentic-data-science-460701.test_dataset.{table_name}`"
                        )
                    break
            query = " ".join(parts)
        
        # Execute query
        job = client.query(query)
        results = job.result()
        
        # Convert to pandas DataFrame for easier handling
        df = results.to_dataframe()
        
        # Limit output size for display
        if len(df) > 100:
            display_df = df.head(100)
            truncated = True
        else:
            display_df = df
            truncated = False
        
        return {
            "success": True,
            "rows_returned": len(df),
            "rows_displayed": len(display_df),
            "truncated": truncated,
            "data": display_df.to_dict('records'),
            "columns": list(df.columns),
            "query_executed": query
        }
        
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "query_executed": query
        }

# Initialize tools
bq_tool = FunctionTool(query_bigquery)

# Try agent with code executor only (no custom tools)
code_only_agent = Agent(
    model='gemini-2.0-flash-001',
    name='titanic_code_analyst',
    description='A Titanic data analyst focused on code-based analysis and visualization.',
    instruction='''You are a data scientist specializing in Python-based analysis of the Titanic dataset. 
    
You can write and execute Python code to:
- Load data from CSV files
- Perform statistical analysis 
- Create visualizations with matplotlib/seaborn
- Build machine learning models with scikit-learn
- Analyze data patterns and correlations

When users ask about the Titanic dataset, write Python code to analyze the data.
Use pandas, numpy, matplotlib, seaborn, and scikit-learn as needed.''',
    code_executor=BuiltInCodeExecutor()
)

# Try agent with just BigQuery tool (no code executor) 
bigquery_only_agent = Agent(
    model='gemini-2.0-flash-001',
    name='titanic_bigquery_analyst',
    description='A Titanic data analyst specialized in BigQuery SQL analysis.',
    instruction='''You are a data scientist specializing in BigQuery SQL analysis of the Titanic dataset.

You can:
- Query the Titanic dataset using SQL
- Perform statistical analysis with SQL aggregations
- Answer questions about passenger demographics and survival
- Provide insights based on SQL query results

The Titanic dataset is available in BigQuery with these columns:
- PassengerId, Survived, Pclass, Name, Sex, Age, SibSp, Parch, Ticket, Fare, Cabin, Embarked

Use SQL queries to analyze the data and provide insights.''',
    tools=[bq_tool]
)

# Default export (the working configuration)
root_agent = bigquery_only_agent

if __name__ == "__main__":
    print("🧪 Testing Alternative Agent Configurations")
    print("=" * 50)
    
    print(f"📊 BigQuery-only Agent: {bigquery_only_agent.name}")
    print(f"   Tools: {len(bigquery_only_agent.tools) if bigquery_only_agent.tools else 0}")
    print(f"   Code Executor: {type(bigquery_only_agent.code_executor).__name__ if bigquery_only_agent.code_executor else 'None'}")
    
    print(f"📊 Code-only Agent: {code_only_agent.name}")
    print(f"   Tools: {len(code_only_agent.tools) if code_only_agent.tools else 0}")
    print(f"   Code Executor: {type(code_only_agent.code_executor).__name__ if code_only_agent.code_executor else 'None'}")
    
    print(f"\n🎯 Active Agent: {root_agent.name}")
    print("This configuration avoids the multiple tools conflict.")
