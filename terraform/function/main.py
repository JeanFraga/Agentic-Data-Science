import functions_framework
import os
import logging
from google.cloud import bigquery
from google.cloud import storage
import pandas as pd
import io

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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
        csv_content = blob.download_as_text()
        
        # Read CSV into pandas DataFrame
        df = pd.read_csv(io.StringIO(csv_content))
        logger.info(f"Successfully read CSV with {len(df)} rows and {len(df.columns)} columns")
        
        # Clean column names (remove spaces, special characters)
        df.columns = df.columns.str.replace(' ', '_').str.replace('/', '_').str.lower()
        
        # Get dataset and table references
        dataset_ref = bigquery_client.dataset(dataset_id)
        table_ref = dataset_ref.table(table_id)
        
        # Configure the load job
        job_config = bigquery.LoadJobConfig(
            # Automatically detect schema
            autodetect=True,
            # Overwrite the table if it exists
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            # Skip header row since pandas DataFrame doesn't include it
            skip_leading_rows=0,
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
