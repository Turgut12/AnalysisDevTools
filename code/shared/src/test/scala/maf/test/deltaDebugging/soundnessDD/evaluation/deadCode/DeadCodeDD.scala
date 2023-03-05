package maf.test.deltaDebugging.soundnessDD.evaluation.deadCode

import maf.deltaDebugging.gtr.GTR
import maf.deltaDebugging.gtr.transformations.TransformationManager
import maf.language.scheme.{SchemeExp, SchemeLambda}
import maf.test.deltaDebugging.soundnessDD.evaluation.*

object DeadCodeDD:
  var dataCollector = new DataCollector
  var bugName = "noneYet"
  var maxSteps: Long = Long.MaxValue

  def reduce(startProgram: SchemeExp,
             program: SchemeExp,
             soundnessTester: DeadCodeTester,
             benchmark: String): Unit =

    var oracleInvocations = 0
    var oracleTreeSizes: List[Int] = List()

    val startTime = System.currentTimeMillis()
    var topCalledLambdas: Set[Int] = Set()

    val reduced = GTR.reduce(
      program,
      p => {
        oracleInvocations += 1
        oracleTreeSizes = oracleTreeSizes.::(p.size)
        soundnessTester.runWithMaxStepsAndIdentifyDeadCode(p, benchmark, maxSteps) match
          case (Some((failureMsg, calledLambdas, evalSteps)), _) =>
            maxSteps = evalSteps
            topCalledLambdas = calledLambdas
            p.findUndefinedVariables().isEmpty && failureMsg.nonEmpty

          case (None, (runTime, analysisTime)) =>
            false
      },
      identity,
      TransformationManager.allTransformations,
      Some(candidateTree => {
        candidateTree.deleteChildren(exp => {
          exp match
            case lambda: SchemeLambda =>
              !topCalledLambdas.contains(lambda.hashCode())
            case _ => false
        })
      })
    )

    val endTime = System.currentTimeMillis()
    val totalReductionTime = endTime - startTime

    val reductionData = ReductionData(
      benchmark = benchmark,
      bugName = bugName,
      origSize = startProgram.size,
      reducedSize = reduced.size,
      reductionTime = totalReductionTime,
      reductionPercentage = 1 - (reduced.size.toDouble / startProgram.size),
      oracleTreeSizes = oracleTreeSizes
    )

    dataCollector.addReductionData(reductionData)