# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""BigQuery sub-agent for Titanic data science operations."""

from google.adk.agents import Agent
from google.adk.tools import FunctionTool
from google.cloud import bigquery
import pandas as pd
from typing import Any, Dict


def execute_query(query: str) -> Dict[str, Any]:
    """
    Execute a BigQuery SQL query on the Titanic dataset.
    
    Args:
        query: SQL query to execute. Available table: titanic in test_dataset
        
    Returns:
        Dictionary containing query results, columns, and metadata    """
    try:
        import os
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'agentic-data-science-460701')
        client = bigquery.Client(project=project_id)
        
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
                            f"`{project_id}.test_dataset.{table_name}`"
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


def get_table_schema() -> Dict[str, Any]:
    """
    Get the schema information for the Titanic dataset.
    
        Returns:
        Dictionary containing table schema and metadata
    """
    try:
        import os
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'agentic-data-science-460701')
        client = bigquery.Client(project=project_id)
        
        # Get table reference
        table_ref = client.dataset("test_dataset").table("titanic")
        table = client.get_table(table_ref)
        
        # Extract schema information
        schema_info = []
        for field in table.schema:
            schema_info.append({
                "name": field.name,
                "type": field.field_type,
                "mode": field.mode,
                "description": field.description or "No description"
            })
        
        return {
            "success": True,
            "table_name": "titanic",
            "dataset": "test_dataset",
            "num_rows": table.num_rows,
            "schema": schema_info,
            "created": table.created.isoformat() if table.created else None,
            "modified": table.modified.isoformat() if table.modified else None
        }
        
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


def count_records() -> Dict[str, Any]:
    """
    Get a quick count of records in the Titanic dataset.
    
    Returns:
        Dictionary containing record count and basic statistics
    """
    query = "SELECT COUNT(*) as total_records FROM titanic"
    return execute_query(query)


# Create BigQuery agent with tools
bigquery_agent = Agent(
    model="gemini-2.0-flash-001",
    name="bigquery_agent",
    instruction="""You are a BigQuery specialist for the Titanic dataset analysis.

You have access to the Titanic dataset in BigQuery with the following columns:
- PassengerId: Unique identifier for each passenger
- Survived: Whether the passenger survived (0 = No, 1 = Yes)
- Pclass: Ticket class (1 = 1st, 2 = 2nd, 3 = 3rd)
- Name: Passenger name
- Sex: Gender of the passenger
- Age: Age of the passenger
- SibSp: Number of siblings/spouses aboard
- Parch: Number of parents/children aboard
- Ticket: Ticket number
- Fare: Passenger fare
- Cabin: Cabin number
- Embarked: Port of embarkation (C = Cherbourg, Q = Queenstown, S = Southampton)

You can execute SQL queries, get schema information, and provide data insights.
Always provide clear, accurate responses about the dataset.""",
    tools=[
        FunctionTool(execute_query),
        FunctionTool(get_table_schema),
        FunctionTool(count_records),
    ],
)
