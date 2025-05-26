#!/usr/bin/env python3
"""
Test script for Titanic Data Science Agent
Validates BigQuery connectivity and basic agent functionality
"""

import os
import sys
import asyncio
from pathlib import Path

# Add the current directory to Python path
sys.path.insert(0, str(Path(__file__).parent))

from agent import root_agent
from google.adk.sessions.memory_session_service import MemorySessionService
from google.adk.runners import Runner
from google.genai import types

async def test_agent():
    """Test the Titanic data science agent"""
    
    # Create session service
    session_service = MemorySessionService()
    
    # Create runner
    runner = Runner(
        app_name="titanic-data-science",
        agent=root_agent,
        session_service=session_service
    )
    
    # Test queries
    test_queries = [
        "What tables are available in the dataset?",
        "Show me the first 5 rows of the titanic table",
        "How many passengers survived vs died?",
        "What is the average age of passengers?"
    ]
    
    user_id = "test-user"
    session_id = "test-session-001"
    
    print("🚢 Testing Titanic Data Science Agent...")
    print("=" * 50)
    
    for i, query in enumerate(test_queries, 1):
        print(f"\n📊 Test {i}: {query}")
        print("-" * 40)
        
        try:
            message = types.Content(parts=[types.Part(text=query)])
            
            # Run the agent
            events = []
            async for event in runner.run_async(
                user_id=user_id,
                session_id=session_id,
                new_message=message
            ):
                events.append(event)
                if hasattr(event, 'content') and event.content:
                    print(f"Response: {event.content}")
                    
        except Exception as e:
            print(f"❌ Error: {str(e)}")
            continue
            
        print("\n" + "="*50)
    
    print("\n✅ Agent testing completed!")

if __name__ == "__main__":
    asyncio.run(test_agent())
