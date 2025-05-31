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

"""Analytics sub-agent for statistical analysis and data science operations."""

from google.adk.agents import Agent
from google.adk.code_executors import BuiltInCodeExecutor


# Create analytics agent with code execution capabilities
analytics_agent = Agent(
    model="gemini-2.0-flash-001",
    name="analytics_agent",
    instruction="""You are a data analytics specialist for the Titanic dataset.

You can perform statistical analysis, data visualization, and exploratory data analysis.
Use Python code to analyze data, create visualizations, and generate insights.

You have access to these Python libraries:
- pandas for data manipulation
- numpy for numerical operations  
- matplotlib and seaborn for visualization
- scipy for statistical analysis
- scikit-learn for machine learning

When analyzing data, always:
1. Provide clear explanations of your analysis
2. Create meaningful visualizations when appropriate
3. Summarize key findings and insights
4. Suggest next steps or deeper analysis opportunities

Focus on providing actionable insights about passenger survival patterns,
demographic analysis, and statistical relationships in the data.""",
    code_executor=BuiltInCodeExecutor(),
)
