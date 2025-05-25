# 🚀 Agent SDK Quick Start Guide

## Overview
The Agent SDK transforms your data science workflow by enabling natural language interactions with BigQuery ML. Ask questions in plain English and get automated SQL queries, ML models, and insights.

## 🎯 Quick Setup (5 Minutes)

### 1. Get Your Cloud Function URL
After deployment, your HTTP API function will be available at:
```
https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/agent-sdk-api
```

### 2. Launch the Web Interface
```powershell
cd "agent_sdk_ui"
.\launch.ps1
```

### 3. Configure the Interface
1. Open http://localhost:8501
2. Enter your Cloud Function URL in the sidebar
3. Test the connection with the "Test Connection" button

## 💬 Try These Examples

### Natural Language Queries
```
"How many passengers survived on the Titanic?"
"What was the average age of first-class passengers?"
"Show me survival rates by gender"
"Which embarkation port had the most passengers?"
```

### ML Model Creation
```
"Create a model to predict passenger survival based on age and class"
"Build a clustering model to group passengers by characteristics"
"Make a regression model to predict ticket prices"
```

## 🛠️ Development Workflow

### For Data Scientists:
1. **Ask Questions**: Use natural language to explore data
2. **Create Models**: Describe ML models in plain English
3. **Iterate**: Refine queries and models based on results
4. **Export**: Download results as CSV for further analysis

### For Developers:
1. **API Integration**: Use HTTP endpoints in your applications
2. **Custom Queries**: Execute raw SQL when needed
3. **Monitoring**: Check Cloud Function logs for performance
4. **Extensions**: Add new endpoints to the function

## 🎨 Web Interface Features

### 📊 Analytics Dashboard
- Quick dataset overview
- Survival rate visualizations
- Class distribution charts
- Age group analysis

### 💾 Data Export
- Download query results as CSV
- Copy generated SQL queries
- Save model creation scripts

### ⚙️ Configuration
- Multiple dataset support
- Connection testing
- Real-time error feedback

## 🔧 API Integration

### Python Example:
```python
import requests

# Natural language query
response = requests.post(
    "YOUR_FUNCTION_URL?endpoint=natural_language_query",
    json={"question": "How many passengers survived?"}
)
result = response.json()
```

### JavaScript Example:
```javascript
const response = await fetch(
    'YOUR_FUNCTION_URL?endpoint=natural_language_query',
    {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            question: "What was the survival rate by class?"
        })
    }
);
const data = await response.json();
```

## 🎯 Common Use Cases

### Business Analytics
- "Show quarterly revenue trends"
- "What are our top-performing products?"
- "Analyze customer churn patterns"

### Data Exploration
- "Find outliers in the dataset"
- "Show correlation between variables"
- "Summarize data quality issues"

### ML Model Development
- "Create a recommendation model"
- "Build a fraud detection classifier"
- "Develop a demand forecasting model"

## 🚨 Troubleshooting

### Connection Issues
- Verify Cloud Function URL is correct
- Check if functions are deployed successfully
- Ensure API keys are configured

### Query Errors
- Check dataset permissions
- Verify table names exist
- Review generated SQL for syntax

### Model Creation Issues
- Ensure sufficient data for training
- Check column types and nulls
- Verify BigQuery ML quotas

## 📚 Learn More

- [BigQuery ML Documentation](https://cloud.google.com/bigquery-ml/docs)
- [Gemini AI API Guide](https://ai.google.dev/docs)
- [Cloud Functions Documentation](https://cloud.google.com/functions/docs)

## 🎉 You're Ready!

Start exploring your data with natural language! The Agent SDK makes machine learning accessible to everyone on your team.

**Happy analyzing! 🔍✨**
