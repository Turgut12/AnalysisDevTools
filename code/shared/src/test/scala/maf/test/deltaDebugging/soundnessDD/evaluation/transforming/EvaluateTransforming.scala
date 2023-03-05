package maf.test.deltaDebugging.soundnessDD.evaluation.transforming

import maf.test.deltaDebugging.soundnessDD.evaluation.Evaluate
import maf.util.benchmarks.Statistics

object SaveTransforming:
  def save(): Unit = {
    Evaluate.save(
      List(
        new SchemeModFLocalAdaptiveTests1,
        new SchemeModFLocalAdaptiveTests2,
        new SchemeModFLocalAdaptiveTests3,
        new SchemeModFLocalAdaptiveTests4,
        new SchemeModFLocalAdaptiveTests5
      ),
      "transformingDataCollector",
      TransformingDD.dataCollector
    )
  }