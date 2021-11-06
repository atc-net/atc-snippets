from dataplatform.landingzone.etlExampleOrchestrator import getOrchestrator

# COMMAND ----------

orchestrator = getOrchestrator()
orchestrator.execute()