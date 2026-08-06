from pyspark.sql import SparkSession

spark = SparkSession.builder.getOrCreate()

CATALOG = spark.conf.get("catalog", "dev")
LANDING_BASE = spark.conf.get("volume", f"/Volumes/{CATALOG}/bronze/raw")