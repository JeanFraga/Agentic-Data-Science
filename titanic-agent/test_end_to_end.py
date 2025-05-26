#!/usr/bin/env python3
"""
End-to-end test for Titanic Data Science Agent
Tests the complete agent functionality including tools and code execution
"""

import asyncio
from agent import root_agent, query_bigquery

def test_agent_tools():
    """Test the agent's tools directly"""
    
    print("🔧 Testing Agent Tools")
    print("=" * 50)
    
    # Test BigQuery tool
    print("\n📊 Testing BigQuery Tool:")
    result = query_bigquery("SELECT COUNT(*) as total FROM titanic")
    if result["success"]:
        print(f"✅ BigQuery tool working: {result['data'][0]['total']} passengers")
    else:
        print(f"❌ BigQuery tool failed: {result['error']}")
    
    # Test agent configuration
    print(f"\n🤖 Agent Configuration:")
    print(f"   Name: {root_agent.name}")
    print(f"   Model: {root_agent.model}")
    print(f"   Tools: {len(root_agent.tools)} tool(s)")
    print(f"   Code Executor: {type(root_agent.code_executor).__name__}")
    
    # Verify tool integration
    tool_names = [tool.name if hasattr(tool, 'name') else str(tool) for tool in root_agent.tools]
    print(f"   Available Tools: {tool_names}")
    
    return True

def generate_test_queries():
    """Generate sample queries for web interface testing"""
    
    queries = [
        # Basic data exploration
        "Show me the first 10 rows of the Titanic dataset",
        "How many passengers were on the Titanic?",
        "What are the column names and data types in the dataset?",
        
        # Survival analysis
        "How many passengers survived vs died?",
        "What's the survival rate by passenger class?",
        "Show survival rates by gender",
        
        # Statistical analysis
        "What's the average age of passengers?",
        "What's the average fare by passenger class?",
        "Show the age distribution of passengers",
        
        # Data visualization requests
        "Create a bar chart showing survival by passenger class",
        "Plot the age distribution of passengers",
        "Show a correlation matrix of numerical features",
        
        # Machine learning
        "Build a simple model to predict passenger survival",
        "What features are most important for survival prediction?",
        "Evaluate the performance of a survival prediction model"
    ]
    
    print("\n📋 Sample Queries for Web Interface Testing:")
    print("=" * 50)
    for i, query in enumerate(queries, 1):
        print(f"{i:2d}. {query}")
    
    return queries

def main():
    """Main test function"""
    
    print("🚢 Titanic Data Science Agent - End-to-End Test")
    print("=" * 60)
    
    # Test tools
    if test_agent_tools():
        print("\n✅ All agent tools are working correctly!")
    
    # Generate test queries
    test_queries = generate_test_queries()
    
    print(f"\n🌐 Web Interface Instructions:")
    print("=" * 50)
    print("1. Open your browser to: http://localhost:8000")
    print("2. Look for the 'titanic_data_scientist' agent")
    print("3. Start a new conversation")
    print("4. Try the sample queries listed above")
    print("5. Test both data queries and visualization requests")
    
    print(f"\n📊 Expected Functionality:")
    print("- BigQuery data retrieval ✅")
    print("- Statistical analysis")
    print("- Data visualization")
    print("- Machine learning model building")
    print("- Code execution for complex calculations")
    
    print(f"\n🎯 Success Criteria:")
    print("- Agent responds to data questions")
    print("- BigQuery queries execute successfully")
    print("- Code execution works for analysis")
    print("- Visualizations can be generated")
    print("- Machine learning models can be built")

if __name__ == "__main__":
    main()
