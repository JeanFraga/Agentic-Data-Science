---
applyTo: '**'
---
Coding standards, domain knowledge, and preferences that AI should follow.

# Agentic Data Science Platform Development Instructions

## Phase: Google Agent Development Kit (ADK) Integration

### Overview
Implement an end-to-end agentic data science solution using Google's Agent Development Kit (ADK) for infrastructure management, IAM configuration, and Vertex AI integration with the new Agent Engine.

### Core Objectives
- Build AI tools for agentic data science workflows
- Implement automated infrastructure and IAM role management
- Integrate Vertex AI Agent Engine for intelligent decision-making
- Create a conversational interface for data analysis and ML model creation
- Use github actions for CI/CD and deployment
- Test locally using the Titanic dataset in bigquery and adk web

### Target Dataset
- **Primary Dataset**: Titanic dataset (ideal for ML model development and testing)
- **Expected Capabilities**: 
    - Answer analytical questions about the data
    - Generate prediction models automatically
    - Utilize BigQuery AutoML with boosting algorithms

### Technical Requirements

#### Agent Development Kit Setup
- Reference: https://google.github.io/adk-docs/
- Follow quickstart guide for initial setup
- Implement local testing using `adk web` command

#### Infrastructure Components
- **BigQuery**: Data storage and AutoML model training
- **Vertex AI**: Agent Engine integration for intelligent workflows
- **IAM**: Dedicated service accounts with minimal required permissions
- **Infrastructure as Code**: Automated provisioning and management

#### Security Configuration
- Create dedicated service account(s) following security best practices
- Configure minimal IAM permissions for:
    - Gemini API requests
    - BigQuery ML model operations
    - Vertex AI Agent Engine access
- Implement proper credential management for local development

#### Agent Capabilities
- **Data Analysis**: Respond to user queries about dataset characteristics
- **Model Creation**: Automatically trigger BigQuery AutoML based on user requests
- **Decision Making**: Intelligent determination of when to run AutoML vs other operations
- **Conversational Interface**: Natural language interaction for data science tasks

### Development Workflow
1. Set up ADK development environment
2. Configure service accounts and IAM permissions
3. Implement infrastructure automation
4. Integrate Vertex AI Agent Engine
5. Build conversational data science agent
6. Test with Titanic dataset scenarios
7. Validate end-to-end workflows

### Testing Strategy
- Local development using `adk web`
- Titanic dataset validation scenarios
- IAM permission verification
- End-to-end workflow testing
- Security compliance validation

### Links and Resources
- [ADK Documentation](https://google.github.io/adk-docs/)
- [BigQuery AutoML Guide](https://cloud.google.com/bigquery-automl/docs)
- [Vertex AI Agent Engine Overview](https://cloud.google.com/vertex-ai/docs/agent-engine)
- [IAM Best Practices](https://cloud.google.com/iam/docs/best-practices)
- [Sample Agents using BigQuery](https://github.com/google/adk-samples)
