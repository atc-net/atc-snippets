# Databricks notebook source
print("Creating LandingZone Databases")

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE DATABASE IF NOT EXISTS landingzone;

# COMMAND ----------

print("Creating LandingZone Tables")

# COMMAND ----------

# MAGIC %sql
# MAGIC DROP TABLE IF EXISTS landingzone.testTable;
# MAGIC CREATE TABLE IF NOT EXISTS landingzone.testTable(
# MAGIC   someData1 STRING,
# MAGIC   someDat2 BIGINT,
# MAGIC   timestamp TIMESTAMP,
# MAGIC   date DATE)
# MAGIC USING delta
# MAGIC PARTITIONED BY (date)
# MAGIC TBLPROPERTIES (delta.autoOptimize.optimizeWrite = true, delta.autoOptimize.autoCompact = true)
# MAGIC COMMENT "Discription"
# MAGIC LOCATION "/mnt/landingzone/testTable";

# COMMAND ----------

print("LandingZone environment prepared!")