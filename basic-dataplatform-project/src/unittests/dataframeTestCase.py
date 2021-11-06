import unittest

from atc.spark import Spark

from typing import Dict, List, Any
from pyspark.sql import DataFrame

class DataframeTestCase(unittest.TestCase):
    spark = Spark.get()

    @classmethod
    def setUpClass(cls):
        pass
    
    def assertDataframeEqual(self, df_first: DataFrame, df_second: DataFrame, orderBy: List[str] = None, dictMargin: Dict[str, Any] = None):
        # Assert df columns and types are equal
        self.assertListEqual(sorted(df_first.dtypes), sorted(df_second.dtypes), "Dataframe schema is wrong!")

        # Ensure column order after schema assert
        df_second = df_second.select(df_first.columns)

        if orderBy is not None:
            df_first = df_first.orderBy(orderBy)
            df_second = df_second.orderBy(orderBy)

        if dictMargin is not None:
            # Assert the column that have accepted margins from dictMargin
            for c, margin in dictMargin.items():
                df_first_data = [row[c] for row in df_first.select(c).collect()]
                df_second_data = [row[c] for row in df_second.select(c).collect()]

                for i in range(len(df_first_data)):
                    self.assertAlmostEqual(df_first_data[i], df_second_data[i], delta=margin, msg=f"Dataframe column {c} has wrong data!")
        
            # Drop the columns already asserted
            df_first = df_first.drop(*dictMargin.keys())
            df_second = df_second.drop(*dictMargin.keys())

        # Assert the rest of the columns
        self.assertEqual(df_first.collect(), df_second.collect(), "Dataframe data is wrong!")
        
    @classmethod
    def tearDownClass(cls):
        pass