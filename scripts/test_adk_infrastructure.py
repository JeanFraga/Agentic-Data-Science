#!/usr/bin/env python3
"""
Test script to verify Gemini API access after ADK infrastructure deployment.
This script tests both direct API access and Secret Manager access to the Gemini API key.
"""

import os
import sys
from typing import Optional

def test_direct_gemini_api(api_key: str) -> bool:
    """Test direct access to Gemini API with provided key."""
    try:
        import google.generativeai as genai
        
        # Configure the API
        genai.configure(api_key=api_key)
        
        # Test with a simple prompt using the current model name
        model = genai.GenerativeModel('gemini-1.5-flash')
        response = model.generate_content("Hello, Gemini! Please respond with 'API test successful'")
        
        print(f"✅ Direct API Test: {response.text.strip()}")
        return True
        
    except ImportError:
        print("❌ google-generativeai library not installed. Run: pip install google-generativeai")
        return False
    except Exception as e:
        print(f"❌ Direct API test failed: {e}")
        return False

def test_secret_manager_access(project_id: str = "agentic-data-science-460701") -> Optional[str]:
    """Test access to Gemini API key from Secret Manager."""
    try:
        from google.cloud import secretmanager
        
        client = secretmanager.SecretManagerServiceClient()
        
        # Access the secret
        secret_name = "gemini-api-key"
        name = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
        
        response = client.access_secret_version(request={"name": name})
        secret_value = response.payload.data.decode("UTF-8")
        
        print(f"✅ Secret Manager Access: Retrieved key {secret_value[:10]}...")
        return secret_value
        
    except ImportError:
        print("❌ google-cloud-secret-manager library not installed. Run: pip install google-cloud-secret-manager")
        return None
    except Exception as e:
        print(f"❌ Secret Manager access failed: {e}")
        return None

def verify_service_accounts():
    """Verify ADK service accounts are created."""
    try:
        import subprocess
        
        # Check if gcloud is available
        result = subprocess.run(
            ["gcloud", "iam", "service-accounts", "list", 
             "--filter=displayName:(*ADK* OR *BigQuery ML* OR *Vertex AI*)",
             "--format=value(email)"],
            capture_output=True, text=True, check=True
        )
        
        accounts = result.stdout.strip().split('\n') if result.stdout.strip() else []
        
        if accounts and accounts != ['']:
            print("✅ ADK Service Accounts Found:")
            for account in accounts:
                print(f"   - {account}")
            return True
        else:
            print("❌ No ADK service accounts found")
            return False
            
    except subprocess.CalledProcessError as e:
        print(f"❌ Error checking service accounts: {e}")
        return False
    except FileNotFoundError:
        print("❌ gcloud CLI not found. Please install Google Cloud SDK")
        print("   Alternative: Check service accounts in GCP Console at:")
        print("   https://console.cloud.google.com/iam-admin/serviceaccounts")
        return False

def test_terraform_api_key():
    """Test direct access using API key from terraform.tfvars."""
    try:
        tfvars_path = "terraform/terraform.tfvars"
        if not os.path.exists(tfvars_path):
            print("❌ terraform.tfvars not found")
            return False
            
        with open(tfvars_path, 'r') as f:
            content = f.read()
            
        # Extract API key from tfvars
        for line in content.split('\n'):
            if 'gemini_api_key' in line and '=' in line:
                api_key = line.split('=')[1].strip().strip('"').strip("'")
                print(f"✅ Found API key in terraform.tfvars: {api_key[:10]}...")
                return test_direct_gemini_api(api_key)
                
        print("❌ gemini_api_key not found in terraform.tfvars")
        return False
        
    except Exception as e:
        print(f"❌ Error reading terraform.tfvars: {e}")
        return False

def main():
    """Main test function."""
    print("🧪 ADK Infrastructure Test Suite")
    print("=" * 50)
    
    # Test 1: Verify service accounts
    print("\n1. Checking ADK Service Accounts...")
    sa_test = verify_service_accounts()
    
    # Test 2: Test Secret Manager access
    print("\n2. Testing Secret Manager Access...")
    api_key = test_secret_manager_access()
    
    # Test 3: Test direct API access (if key available from Secret Manager)
    if api_key:
        print("\n3. Testing Direct Gemini API Access (from Secret Manager)...")
        api_test = test_direct_gemini_api(api_key)
    else:
        print("\n3. Testing Direct Gemini API Access (from terraform.tfvars)...")
        api_test = test_terraform_api_key()
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Summary:")
    print(f"   Service Accounts: {'✅ PASS' if sa_test else '❌ FAIL'}")
    print(f"   Secret Manager:   {'✅ PASS' if api_key else '❌ FAIL'}")
    print(f"   Gemini API:       {'✅ PASS' if api_test else '❌ FAIL'}")
    
    if api_test:  # API test is most important for now
        print("\n🎉 Gemini API connectivity confirmed! Ready for ADK development.")
        if not sa_test:
            print("💡 Service accounts will be created when Terraform is deployed.")
        return 0
    else:
        print("\n⚠️  Gemini API test failed. Check your API key configuration.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
