import dlt
from config import LANDING_BASE
from utils import load_auto_loader, add_metadata_col

@dlt.table(
    name="suppliers_raw",
    comment="Bronze: raw supplier data via Auto Loader. Supports CSV, JSON, and Parquet.",
    table_properties={"quality": "bronze"},
)
def suppliers_raw():
    # Load data with Auto Loader - supports csv, json, parquet
    df = load_auto_loader(
        source_path=f"{LANDING_BASE}/suppliers/",
        file_format="csv"  # Change to 'json' or 'parquet' as needed
    )
    
    # Add metadata columns (file_name, file_path, ingestion_date)
    return add_metadata_col(df)
