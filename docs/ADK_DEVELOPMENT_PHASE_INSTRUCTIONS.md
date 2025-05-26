# ADK Development Phase Instructions
## End-to-End Agentic Data Science with Google Agent Development Kit

### Overview
This document outlines the comprehensive development plan for transitioning to Google's new Agent Development Kit (ADK) to create an end-to-end agentic Data Science solution. The implementation will manage infrastructure, IAM roles, and Vertex AI (including the new Agent Engine) to create AI tools for Data Science projects using the Titanic dataset.

### Current Project Status
- ✅ **Existing Infrastructure**: Cloud Functions, BigQuery, Terraform-managed resources
- ✅ **Agent SDK Integration**: Basic natural language ML capabilities
- ✅ **Testing Environments**: Poetry-based local deployment framework
- 🔄 **Migration Target**: Google ADK with Vertex AI Agent Engine and `adk web` frontend

---

## Phase 1: Environment Setup and Prerequisites

### 1.0 Terraform Infrastructure Overview

#### Infrastructure as Code Benefits
All ADK infrastructure is managed through Terraform for:
- **Consistency**: Reproducible deployments across environments
- **Security**: Proper IAM permissions and access controls
- **Maintainability**: Version-controlled infrastructure changes
- **Compliance**: Auditable infrastructure provisioning

#### Key Terraform Resources
- **Service Accounts**: ADK Agent, BigQuery ML Agent, Vertex AI Agent
- **IAM Permissions**: Minimal required permissions following security best practices
- **BigQuery Dataset**: Titanic dataset with proper access controls
- **Secret Manager**: Secure storage for Gemini API key
- **Storage Buckets**: ADK artifacts and temporary data storage

### 1.1 Google Cloud Platform Configuration

#### Required Services & APIs
```bash
# Enable required Google Cloud APIs
gcloud services enable aiplatform.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable compute.googleapis.com
```

#### Project Environment Variables
```bash
# Core project configuration
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export REGION="us-central1"  # ADK-supported region
export DATASET_ID="titanic_dataset"
export BQ_LOCATION="US"
```

### 1.2 ADK Installation and Setup

#### Local Development Environment
```bash
# Install ADK
pip install google-adk

# Install additional dependencies
pip install google-cloud-bigquery
pip install google-cloud-aiplatform
pip install google-cloud-storage
pip install pandas
pip install scikit-learn
```

#### Verify ADK Installation
```powershell
# Test ADK web interface
adk web --help

# Verify ADK version
adk --version
```

### 1.3 Service Account Creation (Terraform-Managed)

#### Infrastructure as Code Approach
All service accounts and IAM permissions are now managed through Terraform for consistency and reproducibility.

#### Service Accounts Defined in Terraform
The following service accounts are automatically created via `terraform/permissions.tf`:

1. **ADK Agent Service Account** (`adk-agent-sa`): For agent execution and orchestration
2. **BigQuery ML Service Account** (`bqml-agent-sa`): For ML operations and AutoML model creation  
3. **Vertex AI Service Account** (`vertex-agent-sa`): For Vertex AI operations and Agent Engine integration

#### Apply Terraform Configuration
```bash
# Navigate to terraform directory
cd terraform/

# Initialize Terraform (if not already done)
terraform init

# Plan the deployment (review changes)
terraform plan -var="gemini_api_key=YOUR_GEMINI_API_KEY"

# Apply the configuration
terraform apply -var="gemini_api_key=YOUR_GEMINI_API_KEY"
```

#### Alternative: Use PowerShell Setup Script
For a streamlined setup experience, use the provided PowerShell script:

```powershell
# Run the setup script with required parameters
.\scripts\setup-adk-terraform.ps1 -ProjectId "your-project-id" -GeminiApiKey "your-api-key"

# Generate service account keys for local development
.\scripts\setup-adk-terraform.ps1 -ProjectId "your-project-id" -GeminiApiKey "your-api-key" -GenerateKeys

# Plan-only mode to review changes
.\scripts\setup-adk-terraform.ps1 -ProjectId "your-project-id" -GeminiApiKey "your-api-key" -PlanOnly
```

#### Verify Service Account Creation
```bash
# List all service accounts to verify creation
gcloud iam service-accounts list --filter="displayName:(*ADK* OR *BigQuery ML* OR *Vertex AI*)"

# Get service account emails from Terraform outputs
terraform output adk_agent_service_account_email
terraform output bqml_agent_service_account_email  
terraform output vertex_agent_service_account_email
```

#### GitHub Secrets Configuration
For automated deployment via GitHub Actions, configure the following secrets:

```bash
# Required GitHub Secrets (add via GitHub repository settings > Secrets and variables > Actions)
# 
# Core Secrets:
# - GCP_PROJECT_ID: Your Google Cloud Project ID
# - GCP_REGION: Deployment region (e.g., "us-central1") 
# - GCP_ENVIRONMENT: Environment name (e.g., "dev", "staging", "prod")
# - GCP_SERVICE_ACCOUNT_KEY: GitHub Actions service account key (JSON format)
# - GEMINI_API_KEY: Your Gemini API key for AI functionality
#
# The GitHub Actions workflow will automatically use these secrets for Terraform deployment

# Verify secrets are properly configured
gh secret list  # If you have GitHub CLI installed
```

#### Infrastructure as Code Benefits
- **Consistency**: All environments use identical configurations
- **Version Control**: IAM changes are tracked in git
- **Security**: Service account permissions follow least privilege principle
- **Automation**: GitHub Actions deploys infrastructure changes automatically
- **Rollback**: Easy rollback to previous infrastructure states

---

## Phase 2: Data Preparation and BigQuery Setup

### 2.1 Titanic Dataset Preparation (Terraform-Managed)

#### BigQuery Dataset Creation
The BigQuery dataset is automatically created via Terraform configuration with proper IAM permissions:

```bash
# The dataset is created automatically by Terraform
# Verify dataset creation
bq ls --datasets --project_id=$PROJECT_ID

# Check specific dataset
bq show $PROJECT_ID:$DATASET_ID
```

#### Dataset Configuration Details
The Terraform configuration (`terraform/main.tf`) creates:
- **Dataset ID**: `titanic_dataset` (configurable via `var.dataset_id`)
- **Location**: `US` (configurable via `var.bq_location`)
- **Access Control**: 
  - OWNER: Current user and BigQuery ML Agent
  - READER: ADK Agent and Vertex AI Agent
  - Standard project readers/writers access

#### Load Titanic Dataset
```python
# titanic_data_loader.py
import pandas as pd
from google.cloud import bigquery
import os

def load_titanic_data():
    """Load Titanic dataset into BigQuery."""
    client = bigquery.Client(project=os.environ['PROJECT_ID'])
    
    # Download Titanic dataset (or use local file)
    # For this example, we'll create a sample structure
    titanic_schema = [
        bigquery.SchemaField("PassengerId", "INTEGER"),
        bigquery.SchemaField("Survived", "INTEGER"),
        bigquery.SchemaField("Pclass", "INTEGER"),
        bigquery.SchemaField("Name", "STRING"),
        bigquery.SchemaField("Sex", "STRING"),
        bigquery.SchemaField("Age", "FLOAT"),
        bigquery.SchemaField("SibSp", "INTEGER"),
        bigquery.SchemaField("Parch", "INTEGER"),
        bigquery.SchemaField("Ticket", "STRING"),
        bigquery.SchemaField("Fare", "FLOAT"),
        bigquery.SchemaField("Cabin", "STRING"),
        bigquery.SchemaField("Embarked", "STRING"),
    ]
    
    dataset_id = os.environ['DATASET_ID']
    table_id = f"{dataset_id}.titanic_train"
    
    job_config = bigquery.LoadJobConfig(
        schema=titanic_schema,
        skip_leading_rows=1,
        source_format=bigquery.SourceFormat.CSV,
    )
    
    # Load from CSV file or URL
    uri = "gs://your-bucket/titanic.csv"  # Update with actual data source
    load_job = client.load_table_from_uri(uri, table_id, job_config=job_config)
    load_job.result()  # Wait for job to complete
    
    print(f"Loaded {load_job.output_rows} rows into {table_id}")

if __name__ == "__main__":
    load_titanic_data()
```

### 2.2 BigQuery ML Setup

#### Enable BigQuery ML Features
```sql
-- Enable BigQuery ML in the dataset
-- This is automatically available, no additional setup required
SELECT 1; -- Placeholder query
```

---

## Phase 3: ADK Agent Development

### 3.1 Project Structure

```
adk_titanic_agent/
├── agents/
│   ├── __init__.py
│   ├── data_scientist_agent.py
│   ├── bigquery_agent.py
│   ├── ml_agent.py
│   └── orchestrator_agent.py
├── tools/
│   ├── __init__.py
│   ├── bigquery_tools.py
│   ├── ml_tools.py
│   └── data_analysis_tools.py
├── config/
│   ├── agent_config.py
│   └── models.py
├── tests/
│   └── test_agents.py
├── pyproject.toml
├── .env
└── README.md
```

### 3.2 Core Agent Implementation

#### Main Orchestrator Agent
```python
# agents/orchestrator_agent.py
"""Main orchestrator agent for the Titanic data science project."""

import os
from google.adk.agents import Agent
from google.adk.tools import ToolContext
from .data_scientist_agent import data_scientist_agent
from .bigquery_agent import bigquery_agent
from .ml_agent import ml_agent

def create_orchestrator_agent():
    """Create the main orchestrator agent."""
    
    system_prompt = """
    You are a Senior Data Scientist Agent specialized in the Titanic survival prediction problem.
    
    Your capabilities include:
    1. Data exploration and analysis using BigQuery
    2. Feature engineering and data preprocessing
    3. Machine learning model creation using BigQuery ML
    4. Model evaluation and interpretation
    5. Generating insights and recommendations
    
    You have access to specialized sub-agents:
    - BigQuery Agent: For data querying and exploration
    - ML Agent: For machine learning model creation and evaluation
    - Data Scientist Agent: For advanced analytics and visualization
    
    When a user asks a question, determine which agent(s) to use and coordinate their responses.
    Always provide clear explanations of your analysis and methodology.
    """
    
    agent = Agent(
        model="gemini-2.0-flash-001",
        name="titanic_orchestrator",
        instruction=system_prompt,
        tools=[
            data_scientist_agent,
            bigquery_agent,
            ml_agent,
        ]
    )
    
    return agent

# Initialize the main agent
orchestrator_agent = create_orchestrator_agent()
```

#### BigQuery Agent
```python
# agents/bigquery_agent.py
"""BigQuery agent for data querying and exploration."""

import os
from google.adk.agents import Agent
from google.adk.tools import ToolContext
from google.cloud import bigquery
from tools.bigquery_tools import (
    execute_query,
    get_table_schema,
    get_table_info,
    explore_data,
)

def create_bigquery_agent():
    """Create BigQuery agent for data operations."""
    
    system_prompt = """
    You are a BigQuery specialist agent. Your role is to:
    
    1. Execute SQL queries against the Titanic dataset
    2. Provide data exploration and summary statistics
    3. Help with data quality assessment
    4. Generate insights from data analysis
    
    Always write efficient, well-commented SQL queries.
    Provide clear explanations of query results.
    """
    
    agent = Agent(
        model="gemini-2.0-flash-001",
        name="bigquery_agent",
        instruction=system_prompt,
        tools=[
            execute_query,
            get_table_schema,
            get_table_info,
            explore_data,
        ]
    )
    
    return agent

bigquery_agent = create_bigquery_agent()
```

#### Machine Learning Agent
```python
# agents/ml_agent.py
"""Machine learning agent using BigQuery ML."""

import os
from google.adk.agents import Agent
from google.adk.tools import ToolContext
from tools.ml_tools import (
    create_bqml_model,
    evaluate_model,
    make_predictions,
    explain_model,
    list_models,
)

def create_ml_agent():
    """Create ML agent for BigQuery ML operations."""
    
    system_prompt = """
    You are a Machine Learning specialist agent focused on BigQuery ML.
    
    Your responsibilities include:
    1. Creating and training ML models using BigQuery ML
    2. Evaluating model performance
    3. Making predictions on new data
    4. Explaining model behavior and feature importance
    5. Recommending model improvements
    
    For the Titanic dataset, focus on:
    - Binary classification for survival prediction
    - Feature engineering (age groups, family size, etc.)
    - Model interpretability and fairness
    - Boosting algorithms (as preferred by the user)
    
    Always explain your modeling choices and provide performance metrics.
    """
    
    agent = Agent(
        model="gemini-2.0-flash-001",
        name="ml_agent",
        instruction=system_prompt,
        tools=[
            create_bqml_model,
            evaluate_model,
            make_predictions,
            explain_model,
            list_models,
        ]
    )
    
    return agent

ml_agent = create_ml_agent()
```

### 3.3 Tool Implementation

#### BigQuery Tools
```python
# tools/bigquery_tools.py
"""BigQuery tools for data operations."""

from google.cloud import bigquery
from google.adk.tools import ToolContext
import pandas as pd
import os

def execute_query(query: str, tool_context: ToolContext) -> str:
    """Execute a BigQuery SQL query and return results."""
    client = bigquery.Client(project=os.environ['PROJECT_ID'])
    
    try:
        query_job = client.query(query)
        results = query_job.result()
        
        # Convert to pandas DataFrame for easier handling
        df = results.to_dataframe()
        
        if len(df) == 0:
            return "Query executed successfully but returned no results."
        
        # Limit output for readability
        max_rows = 100
        if len(df) > max_rows:
            summary = f"Query returned {len(df)} rows. Showing first {max_rows} rows:\n\n"
            summary += df.head(max_rows).to_string()
            summary += f"\n\n... ({len(df) - max_rows} more rows not shown)"
            return summary
        else:
            return f"Query returned {len(df)} rows:\n\n{df.to_string()}"
            
    except Exception as e:
        return f"Error executing query: {str(e)}"

def get_table_schema(table_name: str, tool_context: ToolContext) -> str:
    """Get the schema of a BigQuery table."""
    client = bigquery.Client(project=os.environ['PROJECT_ID'])
    dataset_id = os.environ['DATASET_ID']
    
    try:
        table_ref = client.dataset(dataset_id).table(table_name)
        table = client.get_table(table_ref)
        
        schema_info = []
        for field in table.schema:
            schema_info.append(f"- {field.name}: {field.field_type} ({field.mode})")
        
        return f"Schema for table {table_name}:\n" + "\n".join(schema_info)
        
    except Exception as e:
        return f"Error getting table schema: {str(e)}"

def explore_data(table_name: str, tool_context: ToolContext) -> str:
    """Perform basic data exploration on a table."""
    dataset_id = os.environ['DATASET_ID']
    project_id = os.environ['PROJECT_ID']
    
    exploration_query = f"""
    SELECT 
        COUNT(*) as total_rows,
        COUNT(DISTINCT PassengerId) as unique_passengers,
        AVG(Age) as avg_age,
        COUNT(CASE WHEN Survived = 1 THEN 1 END) as survivors,
        COUNT(CASE WHEN Survived = 0 THEN 1 END) as non_survivors,
        COUNT(CASE WHEN Sex = 'male' THEN 1 END) as males,
        COUNT(CASE WHEN Sex = 'female' THEN 1 END) as females
    FROM `{project_id}.{dataset_id}.{table_name}`
    """
    
    return execute_query(exploration_query, tool_context)
```

#### ML Tools
```python
# tools/ml_tools.py
"""Machine learning tools using BigQuery ML."""

from google.cloud import bigquery
from google.adk.tools import ToolContext
import os

def create_bqml_model(
    model_name: str, 
    model_type: str = "BOOSTED_TREE_CLASSIFIER",
    tool_context: ToolContext = None
) -> str:
    """Create a BigQuery ML model for Titanic survival prediction."""
    
    project_id = os.environ['PROJECT_ID']
    dataset_id = os.environ['DATASET_ID']
    
    # Feature engineering in the model creation
    create_model_query = f"""
    CREATE OR REPLACE MODEL `{project_id}.{dataset_id}.{model_name}`
    OPTIONS(
        model_type='{model_type}',
        input_label_cols=['Survived'],
        auto_class_weights=TRUE,
        max_iterations=50
    ) AS
    SELECT
        Survived,
        Pclass,
        Sex,
        Age,
        SibSp,
        Parch,
        Fare,
        Embarked,
        -- Feature engineering
        CASE 
            WHEN Age IS NULL THEN 'Unknown'
            WHEN Age < 18 THEN 'Child'
            WHEN Age < 60 THEN 'Adult'
            ELSE 'Senior'
        END as age_group,
        SibSp + Parch as family_size,
        CASE 
            WHEN SibSp + Parch = 0 THEN 'Alone'
            WHEN SibSp + Parch <= 3 THEN 'Small_Family'
            ELSE 'Large_Family'
        END as family_type
    FROM `{project_id}.{dataset_id}.titanic_train`
    WHERE Age IS NOT NULL  -- Remove rows with missing age for now
    """
    
    client = bigquery.Client(project=project_id)
    
    try:
        query_job = client.query(create_model_query)
        query_job.result()  # Wait for completion
        
        return f"Successfully created model '{model_name}' using {model_type}. Model is ready for evaluation and predictions."
        
    except Exception as e:
        return f"Error creating model: {str(e)}"

def evaluate_model(model_name: str, tool_context: ToolContext) -> str:
    """Evaluate a BigQuery ML model."""
    
    project_id = os.environ['PROJECT_ID']
    dataset_id = os.environ['DATASET_ID']
    
    evaluation_query = f"""
    SELECT
        *
    FROM
        ML.EVALUATE(MODEL `{project_id}.{dataset_id}.{model_name}`)
    """
    
    client = bigquery.Client(project=project_id)
    
    try:
        query_job = client.query(evaluation_query)
        results = query_job.result()
        
        eval_results = []
        for row in results:
            eval_results.append(dict(row))
        
        if eval_results:
            result = eval_results[0]
            return f"""
Model Evaluation Results for '{model_name}':
- Accuracy: {result.get('accuracy', 'N/A'):.4f}
- Precision: {result.get('precision', 'N/A'):.4f}
- Recall: {result.get('recall', 'N/A'):.4f}
- F1 Score: {result.get('f1_score', 'N/A'):.4f}
- AUC: {result.get('roc_auc', 'N/A'):.4f}
- Log Loss: {result.get('log_loss', 'N/A'):.4f}
            """
        else:
            return "No evaluation results found. Model may not be trained yet."
            
    except Exception as e:
        return f"Error evaluating model: {str(e)}"

def explain_model(model_name: str, tool_context: ToolContext) -> str:
    """Get feature importance from a BigQuery ML model."""
    
    project_id = os.environ['PROJECT_ID']
    dataset_id = os.environ['DATASET_ID']
    
    explain_query = f"""
    SELECT
        feature,
        importance
    FROM
        ML.GLOBAL_EXPLAIN(MODEL `{project_id}.{dataset_id}.{model_name}`)
    ORDER BY importance DESC
    """
    
    client = bigquery.Client(project=project_id)
    
    try:
        query_job = client.query(explain_query)
        results = query_job.result()
        
        explanations = []
        for row in results:
            explanations.append(f"- {row.feature}: {row.importance:.4f}")
        
        if explanations:
            return f"Feature Importance for model '{model_name}':\n" + "\n".join(explanations)
        else:
            return "No feature importance data available for this model."
            
    except Exception as e:
        return f"Error getting model explanation: {str(e)}"
```

---

## Phase 4: Vertex AI Agent Engine Integration

### 4.1 Deploy Agent to Vertex AI Agent Engine

#### Deployment Configuration
```python
# deploy_to_vertex.py
"""Deploy ADK agent to Vertex AI Agent Engine."""

from google.cloud import aiplatform
from google.adk.deploy import VertexAIAgentEngine
import os

def deploy_agent():
    """Deploy the orchestrator agent to Vertex AI Agent Engine."""
    
    # Initialize Vertex AI
    aiplatform.init(
        project=os.environ['PROJECT_ID'],
        location=os.environ['REGION']
    )
    
    # Deploy configuration
    deployment_config = {
        "display_name": "Titanic Data Science Agent",
        "description": "ADK-powered agent for Titanic survival prediction analysis",
        "serving_config": {
            "machine_type": "n1-standard-4",
            "min_replica_count": 1,
            "max_replica_count": 3,
        },
        "environment_variables": {
            "PROJECT_ID": os.environ['PROJECT_ID'],
            "DATASET_ID": os.environ['DATASET_ID'],
            "REGION": os.environ['REGION'],
        }
    }
    
    # Deploy using ADK Vertex AI integration
    deployment = VertexAIAgentEngine.deploy(
        agent_file="agents/orchestrator_agent.py",
        agent_name="orchestrator_agent",
        config=deployment_config
    )
    
    print(f"Agent deployed successfully. Endpoint: {deployment.endpoint}")
    return deployment

if __name__ == "__main__":
    deploy_agent()
```

### 4.2 Local Testing with ADK Web

#### ADK Web Configuration
```python
# adk_config.py
"""Configuration for ADK web interface."""

import os
from agents.orchestrator_agent import orchestrator_agent

# Configure ADK web interface
def get_adk_config():
    """Get ADK web configuration."""
    return {
        "agent": orchestrator_agent,
        "port": 8080,
        "host": "localhost",
        "debug": True,
        "title": "Titanic Data Science Agent",
        "description": "AI-powered data science agent for Titanic survival prediction",
        "environment": {
            "PROJECT_ID": os.environ.get('PROJECT_ID'),
            "DATASET_ID": os.environ.get('DATASET_ID', 'titanic_dataset'),
            "REGION": os.environ.get('REGION', 'us-central1'),
        }
    }
```

#### Launch ADK Web Interface
```python
# run_adk_web.py
"""Launch ADK web interface for local testing."""

import os
import logging
from google.adk.web import start_web_server
from adk_config import get_adk_config
from agents.orchestrator_agent import orchestrator_agent

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    """Launch the ADK web interface."""
    
    # Ensure environment variables are set
    required_vars = ['PROJECT_ID', 'GOOGLE_APPLICATION_CREDENTIALS']
    missing_vars = [var for var in required_vars if not os.environ.get(var)]
    
    if missing_vars:
        logger.error(f"Missing required environment variables: {missing_vars}")
        return
    
    logger.info("Starting ADK web interface...")
    logger.info(f"Project: {os.environ['PROJECT_ID']}")
    logger.info(f"Dataset: {os.environ.get('DATASET_ID', 'titanic_dataset')}")
    logger.info(f"Region: {os.environ.get('REGION', 'us-central1')}")
    
    # Get configuration
    config = get_adk_config()
    
    # Start the web server
    try:
        start_web_server(
            agent=orchestrator_agent,
            host=config["host"],
            port=config["port"],
            debug=config["debug"]
        )
    except Exception as e:
        logger.error(f"Failed to start ADK web server: {e}")
        raise

if __name__ == "__main__":
    main()
```

#### Environment Setup for ADK Web
```powershell
# setup_adk_environment.ps1
"""Setup script for ADK web environment."""

# Set environment variables for local development
$env:PROJECT_ID = "your-project-id"
$env:DATASET_ID = "titanic_dataset"
$env:REGION = "us-central1"
$env:GOOGLE_APPLICATION_CREDENTIALS = "path\to\service-account-key.json"

# Install required packages
pip install google-adk
pip install google-cloud-bigquery
pip install google-cloud-aiplatform

# Verify installation
adk --version

# Start ADK web interface
python run_adk_web.py
```

#### Quick Start Commands
```powershell
# Navigate to project directory
cd "path\to\your\agentic-data-science\adk_titanic_agent"

# Set up environment (first time only)
.\setup_adk_environment.ps1

# Start ADK web interface
adk web

# Alternative: Use custom launcher
python run_adk_web.py
```

---

## Phase 5: Testing and Validation

### 5.1 Local Testing Strategy

#### Test Scenarios
```python
# tests/test_agents.py
"""Test cases for ADK agents."""

import unittest
import os
from agents.orchestrator_agent import orchestrator_agent
from agents.bigquery_agent import bigquery_agent
from agents.ml_agent import ml_agent

class TestTitanicAgents(unittest.TestCase):
    """Test cases for Titanic data science agents."""
    
    def setUp(self):
        """Set up test environment."""
        self.test_queries = [
            "What is the survival rate in the Titanic dataset?",
            "Show me the age distribution of passengers",
            "Create a machine learning model to predict survival",
            "What features are most important for survival prediction?",
            "Evaluate the performance of the survival model",
        ]
    
    def test_data_exploration(self):
        """Test basic data exploration capabilities."""
        query = "What is the survival rate by passenger class?"
        response = bigquery_agent.query(query)
        self.assertIsNotNone(response)
        self.assertIn("survival", response.lower())
    
    def test_model_creation(self):
        """Test ML model creation."""
        query = "Create a boosted tree model to predict survival"
        response = ml_agent.query(query)
        self.assertIsNotNone(response)
        self.assertIn("model", response.lower())
    
    def test_orchestrator_routing(self):
        """Test orchestrator agent routing."""
        query = "Analyze the Titanic data and create a prediction model"
        response = orchestrator_agent.query(query)
        self.assertIsNotNone(response)

if __name__ == "__main__":
    unittest.main()
```

### 5.2 Integration Testing

#### End-to-End Test Script
```bash
#!/bin/bash
# test_e2e.sh - End-to-end testing script

set -e

echo "Starting end-to-end testing..."

# Set environment variables
export PROJECT_ID=$(gcloud config get-value project)
export DATASET_ID="titanic_dataset"
export REGION="us-central1"

# Test 1: Data availability
echo "Testing data availability..."
bq query --use_legacy_sql=false "SELECT COUNT(*) as row_count FROM \`${PROJECT_ID}.${DATASET_ID}.titanic_train\`"

# Test 2: Local ADK agent
echo "Testing local ADK agent..."
python -c "
from agents.orchestrator_agent import orchestrator_agent
response = orchestrator_agent.query('What is the survival rate?')
print('Agent Response:', response)
"

# Test 3: Model creation
echo "Testing model creation..."
python -c "
from agents.ml_agent import ml_agent
response = ml_agent.query('Create a boosted tree model for survival prediction')
print('Model Creation Response:', response)
"

echo "End-to-end testing completed successfully!"
```

---

## Phase 6: Production Deployment and Monitoring

### 6.1 Terraform Infrastructure Updates

#### Add Vertex AI Agent Engine Resources
```hcl
# terraform/vertex_ai.tf
"""Vertex AI Agent Engine infrastructure."""

resource "google_vertex_ai_reasoning_engine" "titanic_agent" {
  display_name = "Titanic Data Science Agent"
  description  = "ADK-powered agent for Titanic survival analysis"
  location     = var.region

  reasoning_engine_spec {
    package_spec {
      python_package_spec {
        executor_image_uri = "gcr.io/${var.project_id}/adk-titanic-agent:latest"
        package_uris       = ["gs://${var.project_id}-agent-packages/adk-titanic-agent.tar.gz"]
      }
    }
  }

  depends_on = [
    google_bigquery_dataset.titanic_dataset,
    google_storage_bucket.agent_packages
  ]
}

resource "google_storage_bucket" "agent_packages" {
  name     = "${var.project_id}-agent-packages"
  location = var.region
}

resource "google_bigquery_dataset" "titanic_dataset" {
  dataset_id  = "titanic_dataset"
  location    = "US"
  description = "Titanic dataset for survival prediction analysis"
}
```

### 6.2 CI/CD Pipeline Updates

#### GitHub Actions Workflow
```yaml
# .github/workflows/deploy-adk-agent.yml
name: Deploy ADK Agent

on:
  push:
    branches: [ main ]
    paths: [ 'adk_titanic_agent/**' ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        pip install google-adk
        pip install -r adk_titanic_agent/requirements.txt
    
    - name: Authenticate to Google Cloud
      uses: google-github-actions/auth@v2
      with:
        credentials_json: ${{ secrets.GCP_SA_KEY }}
    
    - name: Set up Cloud SDK
      uses: google-github-actions/setup-gcloud@v2
    
    - name: Build and package agent
      run: |
        cd adk_titanic_agent
        python setup.py sdist
    
    - name: Upload package to Cloud Storage
      run: |
        gsutil cp adk_titanic_agent/dist/*.tar.gz gs://${{ secrets.PROJECT_ID }}-agent-packages/
    
    - name: Deploy to Vertex AI Agent Engine
      run: |
        cd adk_titanic_agent
        python deploy_to_vertex.py
    
    - name: Run integration tests
      run: |
        cd adk_titanic_agent
        python -m pytest tests/ -v
```

---

## Phase 7: Usage Examples and Documentation

### 7.1 Example User Interactions

#### Data Exploration Examples
```
User: "What can you tell me about the Titanic dataset?"

Agent: "I'll analyze the Titanic dataset for you. Let me start by exploring the basic characteristics of the data.

[Calling BigQuery Agent...]

The Titanic dataset contains 891 passenger records with the following key insights:
- Overall survival rate: 38.4% (342 survivors out of 891 passengers)
- Gender distribution: 64.8% male, 35.2% female
- Class distribution: 24.2% first class, 20.7% second class, 55.1% third class
- Average age: 29.7 years (177 passengers have missing age data)

Key survival patterns:
- Female survival rate: 74.2%
- Male survival rate: 18.9%
- First class survival rate: 63.0%
- Third class survival rate: 24.2%

Would you like me to create visualizations or dive deeper into any specific aspect?"
```

#### Model Creation Examples
```
User: "Create a machine learning model to predict passenger survival using a boosting algorithm."

Agent: "I'll create a boosted tree classifier model for survival prediction using BigQuery ML.

[Calling ML Agent...]

Creating model with the following approach:
1. Using BOOSTED_TREE_CLASSIFIER algorithm (as requested)
2. Including engineered features:
   - Age groups (Child, Adult, Senior)
   - Family size (SibSp + Parch)
   - Family type (Alone, Small_Family, Large_Family)
3. Handling missing values appropriately
4. Using automatic class weights for balanced training

[Model training in progress...]

✅ Model 'titanic_survival_boosted' created successfully!

Model Performance:
- Accuracy: 83.2%
- Precision: 79.1%
- Recall: 76.8%
- F1 Score: 77.9%
- AUC: 88.5%

Top 5 Most Important Features:
1. Sex: 0.4521
2. Fare: 0.2103
3. Age: 0.1456
4. Pclass: 0.0987
5. Family_size: 0.0654

The model shows strong predictive performance, with gender being the most important factor for survival prediction, followed by fare amount and passenger age."
```

### 7.2 Advanced Use Cases

#### Feature Engineering and Model Comparison
```
User: "Compare different model types and recommend the best approach for survival prediction."

Agent: "I'll create and compare multiple model types to find the optimal approach for Titanic survival prediction.

[Creating models...]

1. Boosted Tree Classifier
2. Logistic Regression  
3. Random Forest (via AutoML Tables)

[Training and evaluating models...]

Model Comparison Results:

| Model Type | Accuracy | Precision | Recall | F1 Score | AUC |
|------------|----------|-----------|--------|----------|-----|
| Boosted Tree | 83.2% | 79.1% | 76.8% | 77.9% | 88.5% |
| Logistic Regression | 81.1% | 77.3% | 74.2% | 75.7% | 85.2% |
| AutoML Tables | 84.7% | 81.2% | 78.9% | 80.0% | 89.8% |

**Recommendation:** AutoML Tables provides the best overall performance with the highest accuracy (84.7%) and AUC (89.8%). However, the Boosted Tree model offers excellent interpretability and faster inference.

**Business Recommendation:** 
- Use AutoML Tables for highest accuracy in production
- Use Boosted Tree for explainable AI requirements
- Consider ensemble methods combining both approaches

Would you like me to implement the recommended approach or explore specific model optimizations?"
```

---

## Phase 8: Monitoring and Maintenance

### 8.1 Performance Monitoring

#### Monitoring Dashboard Configuration
```python
# monitoring/agent_metrics.py
"""Monitoring configuration for ADK agents."""

from google.cloud import monitoring_v3
from google.cloud import logging
import os

def setup_monitoring():
    """Set up monitoring for ADK agents."""
    
    project_id = os.environ['PROJECT_ID']
    
    # Custom metrics for agent performance
    metrics = [
        {
            "name": "agent_query_latency",
            "description": "Time taken to process agent queries",
            "unit": "ms"
        },
        {
            "name": "agent_query_success_rate", 
            "description": "Success rate of agent queries",
            "unit": "percentage"
        },
        {
            "name": "bigquery_query_count",
            "description": "Number of BigQuery queries executed",
            "unit": "count"
        },
        {
            "name": "ml_model_predictions",
            "description": "Number of ML model predictions made",
            "unit": "count"
        }
    ]
    
    # Set up alerting policies
    alerts = [
        {
            "name": "High Agent Latency",
            "condition": "agent_query_latency > 10000",  # 10 seconds
            "notification": "email:admin@company.com"
        },
        {
            "name": "Low Success Rate",
            "condition": "agent_query_success_rate < 0.95",  # Below 95%
            "notification": "email:admin@company.com"
        }
    ]
    
    return metrics, alerts
```

### 8.2 Maintenance Tasks

#### Regular Maintenance Script
```python
# maintenance/agent_maintenance.py
"""Regular maintenance tasks for ADK agents."""

import schedule
import time
from google.cloud import bigquery
from google.cloud import aiplatform
import os

def cleanup_old_models():
    """Clean up old BigQuery ML models."""
    client = bigquery.Client(project=os.environ['PROJECT_ID'])
    dataset_id = os.environ['DATASET_ID']
    
    # List models older than 30 days
    query = f"""
    SELECT model_id, creation_time
    FROM `{os.environ['PROJECT_ID']}.{dataset_id}.INFORMATION_SCHEMA.MODELS`
    WHERE creation_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND model_id LIKE 'temp_%'
    """
    
    results = client.query(query).result()
    
    for row in results:
        model_id = row.model_id
        # Delete temporary models
        delete_query = f"DROP MODEL `{os.environ['PROJECT_ID']}.{dataset_id}.{model_id}`"
        client.query(delete_query).result()
        print(f"Deleted old model: {model_id}")

def update_model_performance_metrics():
    """Update model performance tracking."""
    # Implementation for tracking model drift and performance
    pass

def backup_agent_configurations():
    """Backup agent configurations and models."""
    # Implementation for backup procedures
    pass

# Schedule maintenance tasks
schedule.every().day.at("02:00").do(cleanup_old_models)
schedule.every().hour.do(update_model_performance_metrics)
schedule.every().week.do(backup_agent_configurations)

if __name__ == "__main__":
    while True:
        schedule.run_pending()
        time.sleep(3600)  # Check every hour
```

---

## Implementation Timeline

### Week 1: Foundation Setup
- [ ] Set up Google Cloud environment and APIs
- [ ] Create service accounts and IAM policies
- [ ] Install and configure ADK
- [ ] Load Titanic dataset into BigQuery

### Week 2: Core Agent Development  
- [ ] Implement BigQuery agent and tools
- [ ] Implement ML agent and BQML tools
- [ ] Create orchestrator agent
- [ ] Basic local testing with `adk web`

### Week 3: Advanced Features
- [ ] Implement feature engineering tools
- [ ] Add model comparison capabilities
- [ ] Create evaluation and explanation tools
- [ ] Enhanced error handling and validation

### Week 4: Testing and Deployment
- [ ] Comprehensive testing suite
- [ ] Deploy to Vertex AI Agent Engine
- [ ] Set up monitoring and alerting
- [ ] Documentation and user guides

### Week 5: Production Hardening
- [ ] Performance optimization
- [ ] Security hardening
- [ ] CI/CD pipeline setup
- [ ] Maintenance procedures

---

## Success Metrics

### Technical Metrics
- Agent response time < 5 seconds for simple queries
- Agent response time < 30 seconds for complex ML tasks
- 95%+ query success rate
- Model accuracy > 80% on Titanic dataset

### Business Metrics
- User satisfaction score > 4.0/5.0
- Reduction in time to insights by 50%
- Increased model creation efficiency by 75%
- Zero security incidents

### Operational Metrics
- 99.9% uptime for ADK web interface
- < 1 minute deployment time for updates
- Automated model retraining pipeline
- Complete audit trail for all operations

---

## Risk Mitigation

### Technical Risks
- **API Rate Limits**: Implement exponential backoff and request queuing
- **Model Performance Degradation**: Automated model monitoring and retraining
- **Data Quality Issues**: Comprehensive data validation and cleaning

### Security Risks  
- **Unauthorized Access**: Least privilege IAM, service account rotation
- **Data Exposure**: Encryption at rest and in transit, audit logging
- **Code Injection**: Input sanitization, parameterized queries

### Operational Risks
- **Service Dependencies**: Health checks, graceful degradation
- **Cost Overruns**: Budget alerts, resource quotas
- **Compliance Issues**: Data governance, retention policies

---

## Next Steps

1. **Immediate Actions (This Week)**:
   - Set up development environment
   - Create initial service accounts
   - Load Titanic dataset

2. **Short Term (Next 2 Weeks)**:
   - Implement core agents
   - Basic local testing
   - Initial ML model creation

3. **Medium Term (Next Month)**:
   - Production deployment
   - Monitoring setup
   - User acceptance testing

4. **Long Term (3+ Months)**:
   - Advanced features
   - Multi-dataset support
   - Enterprise integrations

This comprehensive plan provides a roadmap for implementing a production-ready agentic Data Science solution using Google's ADK and Vertex AI Agent Engine, specifically tailored for the Titanic survival prediction use case while maintaining scalability for future enhancements.
