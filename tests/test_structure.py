#!/usr/bin/env python3
"""
Simple validation test for the cleaned up Titanic agent structure
"""

import sys
import os

# Add the titanic-agent directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'titanic-agent'))

def test_imports():
    """Test that all imports work correctly"""
    print("🧪 Testing Agent Structure")
    print("=" * 40)
    
    try:
        print("1. Testing main agent import...")
        from titanic_agent.agent import root_agent
        print("   ✅ Main agent imported successfully")
        
        print("2. Testing sub-agents import...")
        from titanic_agent.sub_agents.bigquery.agent import bigquery_agent
        from titanic_agent.sub_agents.analytics.agent import analytics_agent
        print("   ✅ Sub-agents imported successfully")
        
        print("3. Testing tools import...")
        from titanic_agent.tools import call_bigquery_agent, call_analytics_agent
        print("   ✅ Tools imported successfully")
        
        print("4. Validating agent configuration...")
        print(f"   Root agent model: {root_agent.model}")
        print(f"   Root agent tools: {len(root_agent.tools)} tools")
        print(f"   BigQuery agent model: {bigquery_agent.model}")
        print(f"   Analytics agent model: {analytics_agent.model}")
        print("   ✅ Agent configuration valid")
        
        print("\n🎉 All tests passed! Agent structure is properly configured.")
        return True
        
    except ImportError as e:
        print(f"   ❌ Import error: {e}")
        return False
    except Exception as e:
        print(f"   ❌ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    success = test_imports()
    exit(0 if success else 1)
