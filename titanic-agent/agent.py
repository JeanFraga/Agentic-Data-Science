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

# Initialize tools - try with just the FunctionTool first
bq_tool = FunctionTool(query_bigquery)

# Create agent with just BigQuery tool to avoid multiple tool conflict
root_agent = Agent(
    model='gemini-2.0-flash-001',
    name='titanic_data_scientist',
    description='An expert data science agent specializing in Titanic dataset analysis. I can query the Titanic dataset, perform statistical analysis, create visualizations, and build machine learning models to predict passenger survival.',
    instruction='''You are a specialized data science agent for analyzing the Titanic dataset. Your capabilities include:

1. **Data Exploration**: Query and explore the Titanic dataset stored in BigQuery
2. **Statistical Analysis**: Perform descriptive statistics, correlation analysis, and hypothesis testing
3. **Data Visualization**: Create charts, plots, and visualizations to understand patterns
4. **Machine Learning**: Build predictive models for passenger survival
5. **Feature Engineering**: Create new features from existing data
6. **Model Evaluation**: Assess model performance and provide insights

The Titanic dataset contains passenger information including:
- PassengerId, Name, Sex, Age, SibSp, Parch
- Ticket, Fare, Cabin, Embarked
- Survived (target variable)

Always provide clear explanations of your analysis, interpret results in business context, and suggest actionable insights. Use the BigQuery tool for data queries and when you need to perform code calculations, use your built-in reasoning capabilities to analyze the data.

Available BigQuery table: titanic in the test_dataset
Sample queries you can execute:
- SELECT * FROM titanic LIMIT 10
- SELECT COUNT(*) FROM titanic
- SELECT Survived, COUNT(*) as count FROM titanic GROUP BY Survived''',
    tools=[bq_tool]
)
