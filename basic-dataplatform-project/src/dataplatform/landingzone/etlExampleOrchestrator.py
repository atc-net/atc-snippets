from atc.etl import Orchestration
from atc.extractors import Extractor
from atc.etl.transformer import Transformer
from atc.etl.loader import Loader

from pyspark.sql import DataFrame
import pyspark.sql.functions as F
import pyspark.sql.types as T

def getOrchestrator():
    orchestrator = Orchestration \
        .extract_from(Extractor()) \
        .transform_with(ExampleEventTransformer()) \
        .load_into(Loader()) \
        .build()

    return orchestrator

class ExampleEventTransformer(Transformer):
    def __init__(self):
        pass

    def process(self, df: DataFrame) -> DataFrame:
        df = df.drop("someColumns")

        df = df.withColumn("date", F.to_date(F.col("timestamp")))

        df = df.withColumn("someData1", F.lit("someValue"))

        df = df.withColumn("someDat2", F.col("someDat2").cast(T.LongType()))

        return df