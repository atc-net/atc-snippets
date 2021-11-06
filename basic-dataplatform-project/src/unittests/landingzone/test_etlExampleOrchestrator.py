import unittest
from unittests.dataframeTestCase import DataframeTestCase
from unittests.testHelperFucs import getDatetimeUtc

from datetime import date
import pyspark.sql.functions as F
import pyspark.sql.types as T

from dataplatform.landingzone.etlExampleOrchestrator import ExampleEventTransformer

class Test_TransformFunction(DataframeTestCase):
    inputSchema = ...

    expectedSchema = ...

    def test_Trasformer(self):
        inputData = ...

        df_input = self.spark.createDataFrame(data=inputData, schema=self.inputSchema)

        expectedData = ...

        df_expected = self.spark.createDataFrame(expectedData, self.expectedSchema)

        transformer = ExampleEventTransformer()
        df_transformed = transformer.process(df_input)

        self.assertDataframeEqual(
            df_first=df_expected,
            df_second=df_transformed
        )

if __name__ == "__main__":
    unittest.main()