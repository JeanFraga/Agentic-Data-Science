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

"""Tools for the root Titanic data science agent."""

from google.adk.tools import ToolContext
from google.adk.tools.agent_tool import AgentTool

from .sub_agents import bigquery_agent, analytics_agent


async def call_bigquery_agent(
    question: str,
    tool_context: ToolContext,
):
    """
    Call the BigQuery agent to execute database queries and retrieve data.
    
    Args:
        question: The question or query request for the database
        tool_context: Context for tool execution
    """
    agent_tool = AgentTool(agent=bigquery_agent)
    return await agent_tool.run_async(
        args={"request": question}, tool_context=tool_context
    )


async def call_analytics_agent(
    question: str,
    tool_context: ToolContext,
):
    """
    Call the Analytics agent to perform data analysis, visualization, and statistics.
    
    Args:
        question: The analysis request or question
        tool_context: Context for tool execution
    """
    agent_tool = AgentTool(agent=analytics_agent)
    return await agent_tool.run_async(
        args={"request": question}, tool_context=tool_context
    )
