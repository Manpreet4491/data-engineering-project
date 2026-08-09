import dlt
from config import LANDING_BASE
from utils import load_auto_loader, add_metadata_col

@dlt.table(
    name="sales_raw",
    comment="Bronze: raw sales transactions via Auto Loader. Supports CSV, JSON, and Parquet.",
    table_properties={"quality": "bronze"},
)
@dlt.expect("valid_sale_id", "sale_id IS NOT NULL")
@dlt.expect("has_amount", "sale_amount IS NOT NULL AND sale_amount >= 0")
def sales_raw():
    # Load data with Auto Loader - supports csv, json, parquet
    df = load_auto_loader(
        source_path=f"{LANDING_BASE}/sales/",
    )
    
    # Add metadata columns (file_name, file_path, ingestion_date)
    return add_metadata_col(df)
