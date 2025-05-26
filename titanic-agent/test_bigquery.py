#!/usr/bin/env python3
"""
Simple test for BigQuery connectivity in the Titanic agent
"""

import os
import sys
from pathlib import Path

# Add the current directory to Python path
sys.path.insert(0, str(Path(__file__).parent))

from agent import query_bigquery

def test_bigquery_tool():
    """Test the BigQuery tool directly"""
    
    print("🔍 Testing BigQuery Tool for Titanic Dataset")
    print("=" * 50)
    
    # Test queries
    test_queries = [
        "SELECT table_name FROM `agentic-data-science-460701.test_dataset.INFORMATION_SCHEMA.TABLES`",
        "SELECT * FROM titanic LIMIT 5",
        "SELECT COUNT(*) as total_passengers FROM titanic",
        "SELECT Survived, COUNT(*) as count FROM titanic GROUP BY Survived"
    ]
    
    for i, query in enumerate(test_queries, 1):
        print(f"\n📊 Test {i}: {query}")
        print("-" * 40)
        
        try:
            result = query_bigquery(query)
            
            if result["success"]:
                print(f"✅ Success! Rows returned: {result['rows_returned']}")
                print(f"📋 Columns: {result['columns']}")
                
                # Show sample data
                if result["data"]:
                    print("📊 Sample data:")
                    for row in result["data"][:3]:  # Show first 3 rows
                        print(f"   {row}")
                        
                if result["truncated"]:
                    print(f"📄 Note: Results truncated (showing {result['rows_displayed']} of {result['rows_returned']} rows)")
                    
            else:
                print(f"❌ Error: {result['error']}")
                
        except Exception as e:
            print(f"❌ Exception: {str(e)}")
            
        print()
    
    print("✅ BigQuery tool testing completed!")

if __name__ == "__main__":
    test_bigquery_tool()
