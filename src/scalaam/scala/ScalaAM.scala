package scalaam
import scalaam.core._


object Main {
  def main(args: Array[String]) = {
    ()
  }
}

object RunGabriel {
  def main(args: Array[String]) = {
    val benchmarks = List(
      "boyer",
      "browse",
      "cpstak",
      "dderiv",
      "deriv",
      "destruc",
      "diviter",
      "divrec",
      // "puzzle", // vectors
      "takl",
      // "triangl", // vectors
    )
    val pre = "test/gabriel/"
    val post = ".scm"

    benchmarks.foreach(b => {
      try {
        val timeout = Timeout.seconds(60)
        val (t, s) = SchemeRunAAMLKSS.run(pre + b + post, timeout, false)
        println(s"$b | $t | $s")
      } catch {
        case e: Exception => println(s"$b failed ($e)")
      }
    })
    Profiler.printResults()
  }
}

/* To be used with the console: `sbt console`, then scalaam.SchemeRunAAM.run(file) */
object SchemeRunAAM {
  import scalaam.language.scheme._
  import scalaam.machine._
  import scalaam.graph._
  import scalaam.lattice._

  val address   = NameAddress
  val timestamp = ZeroCFA[SchemeExp]()
  val lattice =
    new MakeSchemeLattice[SchemeExp, address.A, Type.S, Type.B, Type.I, Type.R, Type.C, Type.Sym]
  val sem = new BaseSchemeSemantics[address.A, lattice.L, timestamp.T, SchemeExp](
    address.Alloc[timestamp.T, SchemeExp])
  val machine = new AAM[SchemeExp, address.A, lattice.L, timestamp.T](sem)
  val graph   = new DotGraph[machine.State, machine.Transition]

  def run(file: String, timeout: Timeout.T = Timeout.seconds(10), outputDot: Boolean = true) : (Long, Int) = {
    val f       = scala.io.Source.fromFile(file)
    val content = f.getLines.mkString("\n")
    f.close()
    val t0     = System.nanoTime
    val result = machine.run[graph.G](SchemeParser.parse(content), timeout)
    val t1     = System.nanoTime
    val time   = (t1 - t0) / 1000000
    if (outputDot) result.toFile("foo.dot")
    import Graph.GraphOps
    val states = result.nodes
    (time, states)
  }
}

object SchemeRunAAMLKSS {
  import scalaam.language.scheme._
  import scalaam.machine._
  import scalaam.core._
  import scalaam.graph._
  import scalaam.lattice._

  val address   = NameAddress
  val timestamp = ZeroCFA[SchemeExp]()
  val lattice =
    new MakeSchemeLattice[SchemeExp, address.A, Type.S, Type.B, Type.I, Type.R, Type.C, Type.Sym]
  val sem = new BaseSchemeSemantics[address.A, lattice.L, timestamp.T, SchemeExp](
    address.Alloc[timestamp.T, SchemeExp])
  val machine = new AAMLKSS[SchemeExp, address.A, lattice.L, timestamp.T](sem)
  val graph   = new DotGraph[machine.State, machine.Transition]

  def run(file: String, timeout: Timeout.T = Timeout.seconds(10), outputDot: Boolean = true) = {
    val f       = scala.io.Source.fromFile(file)
    val content = f.getLines.mkString("\n")
    f.close()
    val t0     = System.nanoTime
    val result = machine.run[graph.G](SchemeParser.parse(content), timeout)
    val t1     = System.nanoTime
    val time = (t1 - t0) / 1000000
    if (outputDot) result.toFile("foo.dot")
    import Graph.GraphOps
    val states = result.nodes
    (time, states)
  }
}
