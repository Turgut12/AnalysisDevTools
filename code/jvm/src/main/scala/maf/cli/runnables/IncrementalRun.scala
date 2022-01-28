package maf.cli.runnables

import maf.bench.scheme.SchemeBenchmarkPrograms
import maf.language.CScheme.*
import maf.language.change.CodeVersion.*
import maf.language.scheme.SchemeExp
import maf.language.scheme.interpreter.SchemeInterpreter
import maf.language.scheme.primitives.SchemePrelude
import maf.modular.ModAnalysis
import maf.modular.incremental.IncrementalConfiguration.*
import maf.modular.scheme.modf.*
import maf.modular.incremental.*
import maf.modular.incremental.scheme.IncrementalSchemeAnalysisInstantiations.*
import maf.modular.incremental.ProgramVersionExtracter.*
import maf.modular.incremental.scheme.lattice.*
import maf.modular.incremental.scheme.modf.IncrementalSchemeModFBigStepSemantics
import maf.modular.scheme.PrmAddr
import maf.modular.worklist.LIFOWorklistAlgorithm
import maf.util.{Reader, Writer}
import maf.util.Writer.Writer
import maf.util.benchmarks.{Timeout, Timer}
import maf.util.graph.DotGraph
import maf.util.graph.DotGraph.*

import scala.concurrent.duration.*

object IncrementalRun extends App:

    // Runs the program with a concrete interpreter, just to check whether it makes sense (i.e., if the concrete interpreter does not error).
    // Useful when reducing a program when debugging the analysis.
    def interpretProgram(file: String): Unit =
        val prog = CSchemeParser.parseProgram(Reader.loadFile(file))
        val i = new SchemeInterpreter((_, _) => (), stack = true)
        print("*")
        i.run(prog, Timeout.start(Duration(3, MINUTES)), Old)
        print("*")
        i.run(prog, Timeout.start(Duration(3, MINUTES)), New)
        println("*")

    def modconcAnalysis(
        bench: String,
        config: IncrementalConfiguration,
        timeout: () => Timeout.T
      ): Unit =
        val text = CSchemeParser.parseProgram(Reader.loadFile(bench))
        val a = new IncrementalModConcAnalysisCPLattice(text, config) with IncrementalLogging[SchemeExp] {
          override def intraAnalysis(
              cmp: Component
            ) = new IntraAnalysis(cmp)
            with IncrementalSmallStepIntra
            with KCFAIntra
            with IncrementalGlobalStoreIntraAnalysis
            with IncrementalLoggingIntra {
            override def analyzeWithTimeout(timeout: Timeout.T): Unit =
                println(s"Analyzing $cmp")
                super.analyzeWithTimeout(timeout)
          }
        }
        a.analyzeWithTimeout(timeout())
        print(a.finalResult)
    //a.updateAnalysis(timeout())

    def modfAnalysis(bench: String, timeout: () => Timeout.T): Unit =
        def newAnalysis(text: SchemeExp, configuration: IncrementalConfiguration) =
          new IncrementalSchemeModFAnalysisTypeLattice(text, configuration)
            with IncrementalLogging[SchemeExp]
            with IncrementalDataFlowVisualisation[SchemeExp] {
            override def focus(a: Addr): Boolean = a.toString.toLowerCase().nn.contains("ret")

            override def intraAnalysis(cmp: SchemeModFComponent) = new IntraAnalysis(cmp)
              with IncrementalSchemeModFBigStepIntra
              with IncrementalGlobalStoreIntraAnalysis
              //  with AssertionModFIntra
              with IncrementalLoggingIntra
              with IncrementalVisualIntra
          }

        // Analysis from soundness tests.
        def base(program: SchemeExp) = new ModAnalysis[SchemeExp](program)
          with StandardSchemeModFComponents
          with SchemeModFNoSensitivity
          with SchemeModFSemanticsM
          with LIFOWorklistAlgorithm[SchemeExp]
          with IncrementalSchemeModFBigStepSemantics
          with IncrementalSchemeTypeDomain // IncrementalSchemeConstantPropagationDomain
          with IncrementalGlobalStore[SchemeExp]
          with IncrementalLogging[SchemeExp]
          //with IncrementalDataFlowVisualisation[SchemeExp]
          {
          override def focus(a: Addr): Boolean = false // a.toString.contains("VarAddr(n")
          var configuration: IncrementalConfiguration = ci
          mode = Mode.Fine
          override def intraAnalysis(
              cmp: Component
            ) = new IntraAnalysis(cmp) with IncrementalSchemeModFBigStepIntra with IncrementalGlobalStoreIntraAnalysis with IncrementalLoggingIntra
          //with IncrementalVisualIntra
        }

        try {
          println(s"***** $bench *****")
          //interpretProgram(bench)
          val text = getUpdated(CSchemeParser.parseProgram(Reader.loadFile(bench)))
          //println(text.prettyString())
          val a = base(text)
          a.logger.logU(bench)
          //a.logger.logU("BASE + INC")
          //println(a.configString())
          a.version = New
          val timeI = Timer.timeOnly {
            a.analyzeWithTimeout(timeout())
          }
          if a.finished then println(s"Initial analysis took ${timeI / 1000000} ms.")
          else
              println(s"Initial analysis timed out after ${timeI / 1000000} ms.")
              return
          //a.visited.foreach(println)
          //println(a.store.filterNot(_._1.isInstanceOf[PrmAddr]))
          //a.configuration = noOptimisations
          // a.flowInformationToDotGraph("logs/flowsA1.dot")
          val timeU = Timer.timeOnly {
            a.updateAnalysis(timeout())
          }
          if a.finished then println(s"Updating analysis took ${timeU / 1000000} ms.")
          else println(s"Updating analysis timed out after ${timeU / 1000000} ms.")
          // a.flowInformationToDotGraph("logs/flowsA2.dot")
          Thread.sleep(1000)
          val b = base(text)
          b.version = New
          b.logger.logU("REAN")
          val timeR = Timer.timeOnly {
            b.analyzeWithTimeout(timeout())
          }
          if b.finished then println(s"Full reanalysis took ${timeR / 1000000} ms.")
          else println(s"Full reanalysis timed out after ${timeR / 1000000} ms.")
          // b.flowInformationToDotGraph("logs/flowsB.dot")
          println("Done")
          //println(a.program.asInstanceOf[SchemeExp].prettyString())
          //println(a.store.filterNot(_._1.isInstanceOf[PrmAddr]))
        } catch {
          case e: Exception =>
            e.printStackTrace(System.out)
            val w = Writer.open("benchOutput/incremental/errors.txt")
            Writer.writeln(w, bench)
            Writer.writeln(w, e.getStackTrace().toString)
            Writer.writeln(w, "")
            Writer.close(w)
        }
    end modfAnalysis

    val modConcbenchmarks: List[String] = List()
    val modFbenchmarks: List[String] = List(
      "test/changes/scheme/leval.scm",
      //"test/changes/scheme/reinforcingcycles/cycleCreation.scm"
      //"test/R5RS/gambit/nboyer.scm",
      //"test/changes/scheme/generated/R5RS_gambit_nboyer-5.scm"
    )
    val standardTimeout: () => Timeout.T = () => Timeout.start(Duration(60, MINUTES))

    modConcbenchmarks.foreach(modconcAnalysis(_, ci_di_wi, standardTimeout))
    modFbenchmarks.foreach(modfAnalysis(_, standardTimeout))
    //println("Creating graphs")
    //createPNG("logs/flowsA1.dot", true)
    //createPNG("logs/flowsA2.dot", true)
    //createPNG("logs/flowsB.dot", true)
    println("Done")

// Prints the maximal heap size.
object Memorycheck extends App:
    def formatSize(v: Long): String =
        if v < 1024 then return s"$v B"
        val z = (63 - java.lang.Long.numberOfLeadingZeros(v)) / 10
        s"${v.toDouble / (1L << (z * 10))} ${" KMGTPE".charAt(z)}B"

    println(formatSize(Runtime.getRuntime.nn.maxMemory()))
