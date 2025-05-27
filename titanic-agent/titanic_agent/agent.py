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

"""Titanic Data Science Multi-Agent System using Google ADK."""

import os
from datetime import date

from google.genai import types
from google.adk.agents import Agent
from google.adk.agents.callback_context import CallbackContext
from google.adk.tools import load_artifacts

from .sub_agents import bigquery_agent, analytics_agent
from .tools import call_bigquery_agent, call_analytics_agent

date_today = date.today()


def setup_before_agent_call(callback_context: CallbackContext):
    """Setup the agent with database and schema context."""
    
    # Setting up database settings in session state
    if "database_settings" not in callback_context.state:
        db_settings = dict()
        db_settings["use_database"] = "BigQuery"
        db_settings["project_id"] = "agentic-data-science-460701"
        db_settings["dataset"] = "test_dataset"
        db_settings["table"] = "titanic"
        callback_context.state["all_db_settings"] = db_settings

    # Add schema information to instruction
    schema_info = """
    The Titanic dataset schema:
    - PassengerId: Unique identifier for each passenger
    - Survived: Target variable (0 = No, 1 = Yes)
    - Pclass: Ticket class (1 = 1st, 2 = 2nd, 3 = 3rd)
    - Name: Passenger name
    - Sex: Gender (male/female)
    - Age: Age in years
    - SibSp: Number of siblings/spouses aboard
    - Parch: Number of parents/children aboard
    - Ticket: Ticket number
    - Fare: Passenger fare
    - Cabin: Cabin number
    - Embarked: Port of embarkation (C = Cherbourg, Q = Queenstown, S = Southampton)
    
    Table location: `agentic-data-science-460701.test_dataset.titanic`
    """
    
    callback_context._invocation_context.agent.instruction = (
        callback_context._invocation_context.agent.instruction + schema_info
    )


root_agent = Agent(
    model="gemini-2.0-flash-001",
    name="titanic_data_science_agent",
    description="A multi-agent system for comprehensive Titanic dataset analysis using BigQuery and advanced analytics.",
    instruction="""You are a specialized data science multi-agent system for analyzing the Titanic dataset. 

Your capabilities include:
1. **Database Operations**: Query and explore the Titanic dataset in BigQuery
2. **Statistical Analysis**: Perform descriptive statistics, correlations, and hypothesis testing
3. **Data Visualization**: Create charts and plots for data exploration
4. **Machine Learning**: Build predictive models for survival prediction

You coordinate between specialized sub-agents:
- BigQuery Agent: Handles all database queries and data retrieval
- Analytics Agent: Performs data analysis, visualization, and statistical computations

Always provide clear explanations of analysis results and suggest actionable insights based on the data.""",
    global_instruction=f"""
    You are a Titanic Data Science Multi-Agent System.
    Today's date: {date_today}
    
    Use your sub-agents effectively:
    - For data queries: Use the BigQuery agent
    - For analysis and visualization: Use the Analytics agent
    """,
    tools=[
        call_bigquery_agent,
        call_analytics_agent,
        load_artifacts,
    ],
    before_agent_callback=setup_before_agent_call,
    generate_content_config=types.GenerateContentConfig(temperature=0.1),
)
