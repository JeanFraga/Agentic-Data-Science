import streamlit as st
import requests
import json
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from typing import Dict, Any

# Configuration
st.set_page_config(
    page_title="Agent SDK - Natural Language ML",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 3rem;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .stTabs [data-baseweb="tab-list"] {
        gap: 2rem;
    }
    .stTabs [data-baseweb="tab"] {
        height: 50px;
        padding: 0px 24px;
        background-color: #f0f2f6;
        border-radius: 4px 4px 0px 0px;
    }
    .success-box {
        padding: 1rem;
        background-color: #d4edda;
        border: 1px solid #c3e6cb;
        border-radius: 0.375rem;
        color: #155724;
    }
    .error-box {
        padding: 1rem;
        background-color: #f8d7da;
        border: 1px solid #f5c6cb;
        border-radius: 0.375rem;
        color: #721c24;
    }
</style>
""", unsafe_allow_html=True)

# Configuration in sidebar
with st.sidebar:
    st.header("⚙️ Configuration")
    
    # Cloud Function URL
    function_url = st.text_input(
        "Cloud Function URL",
        value="https://us-central1-your-project.cloudfunctions.net/agent-sdk-api",
        help="Enter your deployed Cloud Function URL"
    )
    
    # Dataset selection
    dataset_id = st.selectbox(
        "BigQuery Dataset",
        ["test_dataset", "ml_dataset", "analytics"],
        index=0,
        help="Select the dataset to work with"
    )
    
    # Test connection
    if st.button("🔍 Test Connection"):
        try:
            response = requests.get(f"{function_url}?endpoint=health", timeout=10)
            if response.status_code == 200:
                st.success("✅ Connection successful!")
                data = response.json()
                st.json(data)
            else:
                st.error(f"❌ Connection failed: {response.status_code}")
        except Exception as e:
            st.error(f"❌ Connection error: {str(e)}")

# Main header
st.markdown('<h1 class="main-header">🤖 Agent SDK - Natural Language ML</h1>', unsafe_allow_html=True)
st.markdown("Transform natural language into powerful machine learning insights with Google Cloud BigQuery ML")

# Create tabs
tab1, tab2, tab3, tab4 = st.tabs(["💬 Natural Language Query", "🤖 Create ML Model", "📊 Execute SQL", "📈 Analytics Dashboard"])

def make_request(endpoint: str, data: Dict[str, Any]) -> Dict[str, Any]:
    """Make a request to the Cloud Function API"""
    try:
        url = f"{function_url}?endpoint={endpoint}"
        response = requests.post(url, json=data, timeout=30)
        
        if response.status_code == 200:
            return response.json()
        else:
            return {"error": f"API error: {response.status_code} - {response.text}"}
    except Exception as e:
        return {"error": f"Request failed: {str(e)}"}

# Tab 1: Natural Language Query
with tab1:
    st.header("💬 Ask Questions in Natural Language")
    st.markdown("Ask questions about your data in plain English, and get SQL queries with results automatically!")
    
    # Example questions
    with st.expander("📝 Example Questions"):
        examples = [
            "How many passengers survived on the Titanic?",
            "What was the average age of passengers by class?",
            "Show me the survival rate by gender and class",
            "Which passenger class had the highest survival rate?",
            "What is the distribution of passengers by embarkation port?"
        ]
        for example in examples:
            if st.button(f"Use: {example}", key=f"example_{example}"):
                st.session_state.question = example
    
    # Question input
    question = st.text_area(
        "Your Question:",
        value=st.session_state.get('question', ''),
        height=100,
        placeholder="e.g., How many passengers survived on the Titanic?"
    )
    
    col1, col2 = st.columns([1, 4])
    with col1:
        if st.button("🔮 Ask Question", type="primary"):
            if question.strip():
                with st.spinner("Generating SQL and executing query..."):
                    result = make_request("natural_language_query", {
                        "question": question,
                        "dataset_id": dataset_id
                    })
                    
                    if "error" in result:
                        st.markdown(f'<div class="error-box">❌ {result["error"]}</div>', unsafe_allow_html=True)
                    else:
                        st.markdown('<div class="success-box">✅ Query executed successfully!</div>', unsafe_allow_html=True)
                        
                        # Show generated SQL
                        st.subheader("📝 Generated SQL Query")
                        st.code(result["generated_sql"], language="sql")
                        
                        # Show results
                        st.subheader("📊 Results")
                        if result["results"]["data"]:
                            df = pd.DataFrame(result["results"]["data"])
                            st.dataframe(df, use_container_width=True)
                            
                            # Download button
                            csv = df.to_csv(index=False)
                            st.download_button(
                                label="📥 Download CSV",
                                data=csv,
                                file_name="query_results.csv",
                                mime="text/csv"
                            )
                        else:
                            st.info("No data returned from query")
            else:
                st.warning("Please enter a question")

# Tab 2: Create ML Model
with tab2:
    st.header("🤖 Create ML Models with Natural Language")
    st.markdown("Describe the machine learning model you want to create, and let AI generate the BigQuery ML code!")
    
    # Example descriptions
    with st.expander("📝 Example Model Descriptions"):
        ml_examples = [
            "Create a logistic regression model to predict passenger survival based on age, gender, and class",
            "Build a linear regression model to predict passenger fare based on class and embarkation port",
            "Create a clustering model to group passengers by their characteristics",
            "Build a classification model to predict passenger class based on age and fare"
        ]
        for example in ml_examples:
            if st.button(f"Use: {example}", key=f"ml_example_{example}"):
                st.session_state.ml_description = example
    
    # Model description input
    description = st.text_area(
        "Model Description:",
        value=st.session_state.get('ml_description', ''),
        height=120,
        placeholder="e.g., Create a logistic regression model to predict passenger survival based on age, gender, and class"
    )
    
    if st.button("🚀 Create ML Model", type="primary"):
        if description.strip():
            with st.spinner("Creating ML model..."):
                result = make_request("create_ml_model", {
                    "description": description,
                    "dataset_id": dataset_id
                })
                
                if "error" in result:
                    st.markdown(f'<div class="error-box">❌ {result["error"]}</div>', unsafe_allow_html=True)
                else:
                    st.markdown('<div class="success-box">✅ ML Model created successfully!</div>', unsafe_allow_html=True)
                    
                    # Show generated SQL
                    st.subheader("📝 Generated CREATE MODEL SQL")
                    st.code(result["model_sql"], language="sql")
                    
                    st.success(result["message"])
        else:
            st.warning("Please enter a model description")

# Tab 3: Execute SQL
with tab3:
    st.header("📊 Execute Custom SQL Queries")
    st.markdown("Write and execute custom SQL queries against your BigQuery dataset")
    
    # SQL input
    sql_query = st.text_area(
        "SQL Query:",
        height=200,
        placeholder=f"SELECT * FROM `your-project.{dataset_id}.titanic` LIMIT 10"
    )
    
    if st.button("▶️ Execute Query", type="primary"):
        if sql_query.strip():
            with st.spinner("Executing SQL query..."):
                result = make_request("execute_query", {
                    "sql_query": sql_query
                })
                
                if "error" in result:
                    st.markdown(f'<div class="error-box">❌ {result["error"]}</div>', unsafe_allow_html=True)
                else:
                    st.markdown(f'<div class="success-box">✅ Query executed successfully! ({result["row_count"]} rows returned)</div>', unsafe_allow_html=True)
                    
                    if result["data"]:
                        df = pd.DataFrame(result["data"])
                        st.dataframe(df, use_container_width=True)
                        
                        # Download button
                        csv = df.to_csv(index=False)
                        st.download_button(
                            label="📥 Download CSV",
                            data=csv,
                            file_name="sql_results.csv",
                            mime="text/csv"
                        )
                    else:
                        st.info("No data returned from query")
        else:
            st.warning("Please enter a SQL query")

# Tab 4: Analytics Dashboard
with tab4:
    st.header("📈 Analytics Dashboard")
    st.markdown("Quick insights and visualizations from your data")
    
    # Quick analytics queries
    quick_queries = {
        "Dataset Overview": f"SELECT COUNT(*) as total_rows FROM `your-project.{dataset_id}.titanic`",
        "Survival Rate": f"SELECT survived, COUNT(*) as count FROM `your-project.{dataset_id}.titanic` GROUP BY survived",
        "Class Distribution": f"SELECT pclass, COUNT(*) as count FROM `your-project.{dataset_id}.titanic` GROUP BY pclass ORDER BY pclass",
        "Age Distribution": f"SELECT CASE WHEN age < 18 THEN 'Child' WHEN age < 65 THEN 'Adult' ELSE 'Senior' END as age_group, COUNT(*) as count FROM `your-project.{dataset_id}.titanic` WHERE age IS NOT NULL GROUP BY age_group"
    }
    
    col1, col2 = st.columns(2)
    
    for i, (query_name, query) in enumerate(quick_queries.items()):
        col = col1 if i % 2 == 0 else col2
        
        with col:
            if st.button(f"📊 {query_name}", key=f"quick_{i}"):
                with st.spinner(f"Loading {query_name}..."):
                    result = make_request("execute_query", {"sql_query": query})
                    
                    if "error" not in result and result["data"]:
                        df = pd.DataFrame(result["data"])
                        st.subheader(query_name)
                        
                        if len(df.columns) == 2 and 'count' in df.columns:
                            # Create a simple bar chart
                            fig = px.bar(df, x=df.columns[0], y='count', 
                                       title=query_name)
                            st.plotly_chart(fig, use_container_width=True)
                        else:
                            st.dataframe(df, use_container_width=True)

# Footer
st.markdown("---")
st.markdown(
    "Built with ❤️ using Streamlit, Google Cloud Functions, BigQuery ML, and Gemini AI",
    help="This application demonstrates the power of natural language processing for machine learning operations"
)
