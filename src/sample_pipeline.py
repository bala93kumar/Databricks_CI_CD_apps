# Databricks notebook source
# COMMAND ----------
# MAGIC %md
# MAGIC # CI/CD Sample Pipeline
# MAGIC This notebook is automatically deployed and executed via Databricks Asset Bundles (DABs).

# COMMAND ----------
# 1. Retrieve environment parameters injected by Databricks Asset Bundle
dbutils.widgets.text("environment", "dev", "Target Environment")
dbutils.widgets.text("storage_account", "dummy_account", "ADLS Account")
dbutils.widgets.text("container_name", "data", "ADLS Container")

env = dbutils.widgets.get("environment")
storage_account = dbutils.widgets.get("storage_account")
container = dbutils.widgets.get("container_name")

print(f"=== Running Pipeline in [{env.upper()}] Environment ===")
print(f"Target Storage Account: {storage_account}")
print(f"Target Container: {container}")

# COMMAND ----------
# 2. Direct ABFSS URI (Modern zero-manual mount pattern)
abfss_base_path = f"abfss://{container}@{storage_account}.dfs.core.windows.net"
print(f"Target ABFSS URI: {abfss_base_path}")

# COMMAND ----------
# 3. Create Sample Raw Data
raw_sales = [
    {"order_id": 101, "customer": " acme corp ", "amount": 1250.0, "status": "COMPLETED"},
    {"order_id": 102, "customer": "beta llc", "amount": 0.0, "status": "COMPLETED"},
    {"order_id": 103, "customer": "gamma inc", "amount": 450.50, "status": "CANCELLED"},
    {"order_id": 104, "customer": "delta co", "amount": 890.25, "status": "COMPLETED"},
]

# COMMAND ----------
# 4. Apply Business Transformation Logic
# In production, import functions or run inline:
cleaned = [
    {
        "order_id": r["order_id"],
        "customer": r["customer"].strip().title(),
        "amount": round(float(r["amount"]), 2),
        "status": r["status"]
    }
    for r in raw_sales if r.get("status") == "COMPLETED" and r.get("amount", 0) > 0
]

df = spark.createDataFrame(cleaned)
display(df)

# COMMAND ----------
# 5. Pipeline completion signal
dbutils.notebook.exit(f"Successfully processed {len(cleaned)} records in {env}")
