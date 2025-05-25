import functions_framework
import os
import logging
from google.cloud import bigquery
from google.cloud import storage
import pandas as pd
import io
import json
import google.generativeai as genai
from google.cloud import aiplatform
import sqlparse
from typing import Dict, Any, List

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Gemini API
def initialize_gemini():
    """Initialize Gemini API with API key from environment variables"""
    api_key = os.environ.get('GEMINI_API_KEY')
    if api_key:
        genai.configure(api_key=api_key)
        return genai.GenerativeModel('gemini-pro')
    else:
        logger.warning("GEMINI_API_KEY not found in environment variables")
        return None

class AgentSDK:
    """Agent SDK for natural language ML model creation and querying"""
    
    def __init__(self, project_id: str):
        self.project_id = project_id
        self.bigquery_client = bigquery.Client(project=project_id)
        self.gemini_model = initialize_gemini()
        
    def natural_language_to_sql(self, question: str, dataset_id: str = "test_dataset") -> str:
        """Convert natural language question to SQL query"""
        if not self.gemini_model:
            raise ValueError("Gemini API not configured")
            
        # Get table schema information
        tables_info = self._get_dataset_schema(dataset_id)
        
        prompt = f"""
        Convert the following natural language question to a SQL query for BigQuery.
        
        Available tables and their schemas:
        {tables_info}
        
        Question: {question}
        
        Rules:
        1. Use only the tables and columns shown above
        2. Return only the SQL query, no explanations
        3. Use proper BigQuery syntax
        4. Include the project and dataset in table names: `{self.project_id}.{dataset_id}.table_name`
        
        SQL Query:
        """
        
        try:
            response = self.gemini_model.generate_content(prompt)
            sql_query = response.text.strip()
            
            # Clean up the response - remove markdown formatting if present
            if sql_query.startswith("```sql"):
                sql_query = sql_query[6:]
            if sql_query.endswith("```"):
                sql_query = sql_query[:-3]
                
            return sql_query.strip()
        except Exception as e:
            logger.error(f"Error generating SQL from natural language: {e}")
            raise
    
    def create_ml_model_from_natural_language(self, description: str, dataset_id: str = "test_dataset") -> Dict[str, Any]:
        """Create a BigQuery ML model based on natural language description"""
        if not self.gemini_model:
            raise ValueError("Gemini API not configured")
            
        tables_info = self._get_dataset_schema(dataset_id)
        
        prompt = f"""
        Create a BigQuery ML model based on the following description.
        
        Available tables and their schemas:
        {tables_info}
        
        Description: {description}
        
        Generate a CREATE OR REPLACE MODEL statement for BigQuery ML.
        
        Rules:
        1. Use only the tables and columns shown above
        2. Choose appropriate model type (LINEAR_REG, LOGISTIC_REG, KMEANS, etc.)
        3. Include proper feature selection and target variable
        4. Use project.dataset.model_name format: `{self.project_id}.{dataset_id}.model_name`
        5. Return only the SQL statement, no explanations
        
        CREATE MODEL SQL:
        """
        
        try:
            response = self.gemini_model.generate_content(prompt)
            create_model_sql = response.text.strip()
            
            # Clean up the response
            if create_model_sql.startswith("```sql"):
                create_model_sql = create_model_sql[6:]
            if create_model_sql.endswith("```"):
                create_model_sql = create_model_sql[:-3]
                
            # Execute the model creation
            job = self.bigquery_client.query(create_model_sql)
            job.result()  # Wait for completion
            
            return {
                "status": "success",
                "model_sql": create_model_sql,
                "message": "ML model created successfully"
            }
            
        except Exception as e:
            logger.error(f"Error creating ML model: {e}")
            raise
    
    def query_data(self, sql_query: str) -> Dict[str, Any]:
        """Execute SQL query and return results"""
        try:
            # Validate SQL syntax
            parsed = sqlparse.parse(sql_query)
            if not parsed:
                raise ValueError("Invalid SQL query")
                
            job = self.bigquery_client.query(sql_query)
            results = job.result()
            
            # Convert results to list of dictionaries
            rows = []
            for row in results:
                rows.append(dict(row))
                
            return {
                "status": "success",
                "data": rows,
                "row_count": len(rows)
            }
            
        except Exception as e:
            logger.error(f"Error executing query: {e}")
            raise
    
    def _get_dataset_schema(self, dataset_id: str) -> str:
        """Get schema information for all tables in the dataset"""
        try:
            dataset_ref = self.bigquery_client.dataset(dataset_id)
            tables = list(self.bigquery_client.list_tables(dataset_ref))
            
            schema_info = []
            for table in tables:
                full_table = self.bigquery_client.get_table(table.reference)
                schema_info.append(f"Table: {table.table_id}")
                for field in full_table.schema:
                    schema_info.append(f"  - {field.name}: {field.field_type}")
                schema_info.append("")
                
            return "\n".join(schema_info)
            
        except Exception as e:
            logger.error(f"Error getting dataset schema: {e}")
            return "Schema information unavailable"

@functions_framework.cloud_event
def load_titanic_to_bigquery(cloud_event):
    """
    Cloud Function triggered when titanic.csv is uploaded to the temp bucket.
    Automatically loads the CSV data into BigQuery.
    """
    try:
        # Get environment variables
        project_id = os.environ.get('PROJECT_ID')
        dataset_id = os.environ.get('DATASET_ID', 'test_dataset')
        table_id = os.environ.get('TABLE_ID', 'titanic')
        
        # Get event data
        data = cloud_event.data
        bucket_name = data['bucket']
        file_name = data['name']
        
        logger.info(f"Processing file: {file_name} from bucket: {bucket_name}")
        
        # Validate that this is the titanic.csv file
        if file_name != 'titanic.csv':
            logger.info(f"Ignoring file {file_name}, not titanic.csv")
            return
        
        # Initialize clients
        storage_client = storage.Client(project=project_id)
        bigquery_client = bigquery.Client(project=project_id)
          # Download the CSV file from Cloud Storage
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        
        logger.info(f"Downloading {file_name} from {bucket_name}")
        try:
            csv_content = blob.download_as_text()
        except UnicodeDecodeError:
            # Try with different encodings if UTF-8 fails
            logger.info("UTF-8 decoding failed, trying latin-1 encoding")
            csv_bytes = blob.download_as_bytes()
            try:
                csv_content = csv_bytes.decode('latin-1')
            except UnicodeDecodeError:
                logger.info("latin-1 decoding failed, trying cp1252 encoding")
                csv_content = csv_bytes.decode('cp1252', errors='replace')
          # Read CSV into pandas DataFrame
        df = pd.read_csv(io.StringIO(csv_content))
        logger.info(f"Successfully read CSV with {len(df)} rows and {len(df.columns)} columns")
        logger.info(f"Column names: {list(df.columns)}")
        
        # Clean column names (remove spaces, special characters)
        df.columns = df.columns.str.replace(' ', '_').str.replace('/', '_').str.lower()
        logger.info(f"Cleaned column names: {list(df.columns)}")
        
        # Get dataset and table references
        dataset_ref = bigquery_client.dataset(dataset_id)
        table_ref = dataset_ref.table(table_id)
          # Configure the load job
        job_config = bigquery.LoadJobConfig(
            # Create schema from DataFrame columns
            schema=[
                bigquery.SchemaField(col, "STRING") for col in df.columns
            ],
            # Overwrite the table if it exists
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            # Skip header row since we're defining schema manually
            skip_leading_rows=1,
            source_format=bigquery.SourceFormat.CSV,
        )
        
        # Create a temporary CSV in memory from the DataFrame
        csv_buffer = io.StringIO()
        df.to_csv(csv_buffer, index=False)
        csv_buffer.seek(0)
        
        # Load data into BigQuery
        logger.info(f"Loading data into {project_id}.{dataset_id}.{table_id}")
        load_job = bigquery_client.load_table_from_file(
            csv_buffer,
            table_ref,
            job_config=job_config
        )
        
        # Wait for the job to complete
        load_job.result()
        
        # Get the loaded table
        table = bigquery_client.get_table(table_ref)
        
        logger.info(f"Successfully loaded {table.num_rows} rows into {table.table_id}")
        
        # Log table schema
        schema_info = [f"{field.name}: {field.field_type}" for field in table.schema]
        logger.info(f"Table schema: {schema_info}")
        
        return {
            'status': 'success',
            'message': f'Successfully loaded {table.num_rows} rows into {project_id}.{dataset_id}.{table_id}',
            'rows_loaded': table.num_rows,
            'columns': len(table.schema)
        }
        
    except Exception as e:
        logger.error(f"Error processing file {file_name}: {str(e)}")
        raise e

@functions_framework.http
def main(request):
    """
    HTTP Cloud Function that provides Agent SDK endpoints for natural language ML interactions.
    Supports multiple endpoints via query parameters.
    """
    try:
        # Set CORS headers for web interface
        if request.method == 'OPTIONS':
            headers = {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
                'Access-Control-Max-Age': '3600'
            }
            return ('', 204, headers)

        headers = {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        }

        # Get environment variables
        project_id = os.environ.get('PROJECT_ID')
        if not project_id:
            return json.dumps({'error': 'PROJECT_ID not configured'}), 500, headers

        # Initialize Agent SDK
        agent = AgentSDK(project_id)
        
        # Get endpoint from query parameter
        endpoint = request.args.get('endpoint', 'health')
        
        if endpoint == 'health':
            return json.dumps({
                'status': 'healthy',
                'project_id': project_id,
                'endpoints': ['natural_language_query', 'create_ml_model', 'execute_query']
            }), 200, headers
            
        elif endpoint == 'natural_language_query':
            if request.method != 'POST':
                return json.dumps({'error': 'POST method required'}), 405, headers
                
            request_json = request.get_json(silent=True)
            if not request_json or 'question' not in request_json:
                return json.dumps({'error': 'Missing required field: question'}), 400, headers
                
            question = request_json['question']
            dataset_id = request_json.get('dataset_id', 'test_dataset')
            
            try:
                sql_query = agent.natural_language_to_sql(question, dataset_id)
                results = agent.query_data(sql_query)
                
                return json.dumps({
                    'status': 'success',
                    'question': question,
                    'generated_sql': sql_query,
                    'results': results
                }), 200, headers
                
            except Exception as e:
                return json.dumps({'error': str(e)}), 500, headers
                
        elif endpoint == 'create_ml_model':
            if request.method != 'POST':
                return json.dumps({'error': 'POST method required'}), 405, headers
                
            request_json = request.get_json(silent=True)
            if not request_json or 'description' not in request_json:
                return json.dumps({'error': 'Missing required field: description'}), 400, headers
                
            description = request_json['description']
            dataset_id = request_json.get('dataset_id', 'test_dataset')
            
            try:
                result = agent.create_ml_model_from_natural_language(description, dataset_id)
                return json.dumps(result), 200, headers
                
            except Exception as e:
                return json.dumps({'error': str(e)}), 500, headers
                
        elif endpoint == 'execute_query':
            if request.method != 'POST':
                return json.dumps({'error': 'POST method required'}), 405, headers
                
            request_json = request.get_json(silent=True)
            if not request_json or 'sql_query' not in request_json:
                return json.dumps({'error': 'Missing required field: sql_query'}), 400, headers
                
            sql_query = request_json['sql_query']
            
            try:
                results = agent.query_data(sql_query)
                return json.dumps(results), 200, headers
                
            except Exception as e:
                return json.dumps({'error': str(e)}), 500, headers
                
        else:
            return json.dumps({'error': f'Unknown endpoint: {endpoint}'}), 404, headers
            
    except Exception as e:
        logger.error(f"Unexpected error in main function: {e}")
        return json.dumps({'error': 'Internal server error'}), 500, headers
