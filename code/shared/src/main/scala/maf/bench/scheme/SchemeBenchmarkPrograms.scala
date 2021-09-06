package maf.bench.scheme

import java.io.File

import maf.util.datastructures.SmartUnion

import scala.util.Random

// null values are used here due to Java interop
import scala.language.unsafeNulls

object SchemeBenchmarkPrograms:

  def files(dir: File): Array[File] =
    val lst = dir.listFiles()
    if lst == null then Array()
    else lst

  // Just include an entire folder of programs, except some that are explicitly specified. The directory name should not end with a "/".
  def fromFolderR(directory: String)(exclude: String*): Set[String] =
    def recur(dir: File): Array[File] =
      val here = files(dir)
      val (dr, noDr) = here.partition(_.isDirectory)
      noDr ++ dr.flatMap(recur)
    val root = new File(directory)
    val base = root.getAbsolutePath.nn.length - directory.length
    recur(root).map(_.getAbsolutePath.nn.substring(base).nn).toSet -- exclude.map(file => s"$directory/$file")

  def fromFolder(directory: String)(exclude: String*): Set[String] =
    val root = new File(directory)
    val base = root.getAbsolutePath.nn.length - directory.length
    files(root).filter(!_.isDirectory).map(_.getAbsolutePath.nn.substring(base).nn).toSet -- exclude.map(file => s"$directory/$file")

  // Only include certain listed programs.
  def toFolder(directory: String)(include: String*): Set[String] = include.map(file => s"$directory/$file").toSet

  // SEQUENTIAL ////////////////////////////////////////////////////////////////////////////////////////////////////////

  lazy val ad: Set[String] = fromFolder("test/R5RS/ad")(
    "bfirst.scm", // Unbound identifier: create-graph
    "bst.scm", // Tail of empty list BUT THERE IS NO CODE TO RUN? TODO Look at this.
    "btree.scm", // Lacks a body.
    "stspaceCODE.scm" // Tail of empty list BUT THERE IS NO CODE TO RUN? TODO Look at this.
  )
  lazy val gabriel: Set[String] = fromFolder("test/R5RS/gabriel")()
  lazy val gambit: Set[String] = fromFolder("test/R5RS/gambit")(
    "trav1.scm", // Needs append in the abstract interpreter (not as a preluded primitive)
    "compiler.scm", // Can be analyzed. Need input model in concrete.
    "scheme.scm", // Can be analyzed. "Error in program" -> what error?
    "slatex.scm", // Can be analyzed, but requires the input file to be modelled in concrete
    // Can be enabled when call-cc is supported in the interpreter.
    "ctak.scm", // Can be analyzed. Needs call-with-current-continuation in concrete.
    "fibc.scm", // Can be analyzed. Needs call-cc in concrete.
    "puzzle.scm" // Can be analyzed. Needs call-with-current-continuation in concrete.
  )
  lazy val icp1: Set[String] = fromFolder("test/R5RS/icp")(
    "icp_1c_ambeval.scm", // Can be analyzed. Need input model in concrete.
    "icp_4_qeval.scm" // Needs define-syntax and delay.
  )
  lazy val rosetta: Set[String] = fromFolder("test/R5RS/rosetta")()
  lazy val scp1: Set[String] = fromFolder("test/R5RS/scp1")(
    "circus.scm" // Vararg append not supported by concrete interpreter.
  )
  lazy val scp1_compressed: Set[String] = fromFolder("test/R5RS/scp1-compressed")()
  lazy val scp1_singleFile: Set[String] = Set("test/R5RS/scp1-compressed/all.scm")
  lazy val sigscheme: Set[String] = fromFolder("test/R5RS/sigscheme")()
  lazy val theLittleSchemer: Set[String] = fromFolder("test/R5RS/WeiChenRompf2019/the-little-schemer")(
    "ch4.scm", // No main code (only definitions).
    "ch5.scm", // No main code (only definitions).
    "ch7.scm", // No main code (only definitions).
    "ch9.scm", // Unbound identifier: will-stop?
    "ch10.scm" // Tail of empty list BUT THERE IS NO CODE TO RUN? TODO Look at this.
  )
  lazy val toplas98: Set[String] = fromFolder("test/R5RS/WeiChenRompf2019/toplas98")(
    "handle.scm", // Uses defmacro (not standard r5rs).
    "maze.scm", // Uses read, bitwise-and and bitwise-or (not standard R5RS, but racket-specific)
    "nucleic.sch", // Made it parse by replacing vector literals, but does not have proper main code.
    "nucleic2.sch", // Uses macros (define-syntax).
    "splay.scm", // Uses () instead of '(), and #(1 2 3) syntax for vectors, also has unsupported match functions.
    "graphs.scm", // Can be analyzed. Uses read.
    "nbody.scm", // Can be analyzed. Uses read
    "nbody-processed.scm", // Can be analyzed. Uses read.
    "dynamic.scm" // Can be analyzed. Uses read
  )
  lazy val WCR2019: Set[String] = fromFolder("test/R5RS/WeiChenRompf2019")(
    ".DS_Store",
    "mbrotZ.sch", // Uses read, complex numbers
    "solovay-strassen.scm", // Program seems erroneous.
    "earley.sch" // Can be analyzed. Uses read.
  )
  lazy val various: Set[String] = fromFolder("test/R5RS/various")(
    ".DS_Store",
    "pico.scm", // Used def-macro, no main body + need to incorporate pico.ini file.
    "quasiquoting.scm", // Uses unquote-splicing.
    "Streams.scm", // Uses define-macro.
    "callcc.scm" // call/cc not yet support in concrete interpreter
  )
  lazy val WeiChenRompf2019: Set[String] = SmartUnion.sunionList(List(theLittleSchemer, toplas98, WCR2019))
  lazy val sequentialBenchmarks: Set[String] =
    SmartUnion.sunionList(List(ad, gabriel, gambit, icp1, rosetta, scp1, sigscheme, WeiChenRompf2019, various))

  def selectRandomSeq(n: Int): Set[String] = Random.shuffle(sequentialBenchmarks).take(n)

  // CONCURRENT ////////////////////////////////////////////////////////////////////////////////////////////////////////

  lazy val savina: Set[String] = fromFolder("test/concurrentScheme/actors/savina")()
  lazy val soter: Set[String] = fromFolder("test/concurrentScheme/actors/soter")()
  lazy val actors: Set[String] = savina ++ soter ++ fromFolder("test/concurrentScheme/actors")()
  lazy val futures: Set[String] = fromFolder("test/concurrentScheme/futures")()
  lazy val futuresVariations: Set[String] = fromFolder("test/concurrentScheme/futures/variations")()
  lazy val threads: Set[String] = fromFolder("test/concurrentScheme/threads")()
  lazy val threadsVariations: Set[String] = fromFolder("test/concurrentScheme/threads/variations")()
  lazy val concurrentBenchmarks: Set[String] =
    SmartUnion.sunionList(List(actors, futures, futuresVariations, savina, soter, threads, threadsVariations))

  def selectRandomPar(n: Int): Set[String] = Random.shuffle(concurrentBenchmarks).take(n)

  // ALL ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

  lazy val allBenchmarks: Set[String] = SmartUnion.sunion(concurrentBenchmarks, sequentialBenchmarks)
