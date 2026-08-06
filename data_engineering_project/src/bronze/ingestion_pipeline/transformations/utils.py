"""Shared utility functions for the ingestion pipeline."""

from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import col, current_timestamp
from config import LANDING_BASE

# Get or create spark session (globally available in SDP)
spark = SparkSession.builder.getOrCreate()


def add_metadata_col(df: DataFrame) -> DataFrame:
    """Add metadata columns to dataframe.
    
    Adds:
    - file_name: Source file name
    - file_path: Full source file path
    - ingestion_date: Timestamp when data was ingested
    
    Args:
        df: Input DataFrame
        
    Returns:
        DataFrame with metadata columns added
    """
    return (
        df.withColumn("file_name", col("_metadata.file_name"))
        .withColumn("file_path", col("_metadata.file_path"))
        .withColumn("ingestion_date", current_timestamp())
    )


def load_auto_loader(source_path: str, file_format: str, schema_location: str = None):
    """Load data using Auto Loader with support for CSV, JSON, and Parquet.
    
    Args:
        source_path: Path to source files (e.g., f"{LANDING_BASE}/customers/")
        file_format: File format - 'csv', 'json', or 'parquet'
        schema_location: Optional schema checkpoint location. Defaults to {LANDING_BASE}/_schemas/{folder_name}
        
    Returns:
        Streaming DataFrame
    """
    # Extract folder name for schema location if not provided
    if schema_location is None:
        folder_name = source_path.rstrip('/').split('/')[-1]
        schema_location = f"{LANDING_BASE}/{folder_name}"
    
    # Base Auto Loader configuration
    reader = (
        spark.readStream.format("cloudFiles")
        .option("cloudFiles.format", file_format)
        .option("cloudFiles.schemaLocation", schema_location)
        .option("cloudFiles.inferColumnTypes", "true")
    )
    
    # Format-specific options
    if file_format == "csv":
        reader = reader.option("header", "true")
    elif file_format == "json":
        # JSON can handle both single-line and multi-line
        reader = reader.option("multiLine", "true")
    # Parquet doesn't need additional options
    
    return reader.load(source_path)
