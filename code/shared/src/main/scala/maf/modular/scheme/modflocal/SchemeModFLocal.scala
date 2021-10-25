package maf.modular.scheme.modflocal

import maf.modular._
import maf.modular.scheme._
import maf.core._
import maf.language.scheme._
import maf.language.scheme.primitives._
import maf.util.benchmarks.Timeout
import maf.language.CScheme._
import maf.lattice.interfaces.BoolLattice
import maf.lattice.interfaces.LatticeWithAddrs

abstract class SchemeModFLocal(prg: SchemeExp) extends ModAnalysis[SchemeExp](prg) with SchemeSemantics with GlobalStore[SchemeExp]:
    inter: SchemeDomain with SchemeModFLocalSensitivity =>

    // more shorthands
    type Cmp = Component
    type Dep = Dependency
    type Sto = LocalStore[Adr, Val]
    type Dlt = Delta[Adr, Val]
    type Cnt = AbstractCount
    type Anl = SchemeLocalIntraAnalysis

    //
    // INITIALISATION
    //

    lazy val initialExp: Exp = program
    lazy val initialEnv: Env = BasicEnvironment(initialBds.map(p => (p._1, p._2)).toMap)
    lazy val initialSto: Sto = LocalStore.from(initialBds.map(p => (p._2, p._3)))

    private def shouldCount(adr: Adr): Boolean = adr match
        case _: PtrAddr[_] => true
        case _             => false

    given p: (Adr => Boolean) = shouldCount

    private lazy val initialBds: Iterable[(String, Adr, Val)] =
      primitives.allPrimitives.view
        .filterKeys(initialExp.fv)
        .map { case (name, p) =>
          (name, PrmAddr(name), lattice.primitive(p.name))
        }

    //
    // COMPONENTS
    //

    sealed trait Component extends Serializable:
        def exp: Exp
        def env: Env
        val ctx: Ctx
        val sto: Sto
    case object MainComponent extends Component:
        val exp = initialExp
        val env = initialEnv
        val ctx = initialCtx
        val sto = initialSto
        override def toString = "main"
    case class CallComponent(lam: Lam, env: Env, ctx: Ctx, sto: Sto) extends Component:
        def exp = SchemeBody(lam.body)
        override def toString = s"${lam.lambdaName} [$ctx] [$sto]"

    def initialComponent: Cmp = MainComponent
    def expr(cmp: Cmp): Exp = cmp.exp

    //
    // RESULTS
    //

    type Res = Map[Cmp, (Val, Dlt)]

    var results: Res = Map.empty
    case class ResultDependency(cmp: Cmp) extends Dependency

    //
    // STORE STUFF
    //

    enum AddrPolicy:
      case Local
      case Widened

    var fixedPolicies: Map[Adr, AddrPolicy] = Map.empty
    def customPolicy(adr: Adr): AddrPolicy = AddrPolicy.Local
    def policy(adr: Adr): AddrPolicy =
      fixedPolicies.get(adr) match
          case Some(ply) => ply
          case None      => customPolicy(adr)

    var store: Map[Adr, Val] = Map.empty

    def extendV(anl: Anl, sto: Sto, adr: Adr, vlu: Val): Dlt =
      policy(adr) match
          case AddrPolicy.Local   => sto.extend(adr, vlu)
          case AddrPolicy.Widened => anl.writeAddr(adr, vlu) ; Delta.empty 
    def updateV(anl: Anl, sto: Sto, adr: Adr, vlu: Val): Dlt =
      policy(adr) match
          case AddrPolicy.Local   => sto.update(adr, vlu)
          case AddrPolicy.Widened => anl.writeAddr(adr, vlu) ; Delta.empty
    def lookupV(anl: Anl, sto: Sto, adr: Adr): Val =
      policy(adr) match
          case AddrPolicy.Local   => sto(adr)
          case AddrPolicy.Widened => anl.readAddr(adr)

    def eqA(sto: Sto): MaybeEq[Adr] = new MaybeEq[Adr] {
      def apply[B: BoolLattice](a1: Adr, a2: Adr): B =
        if a1 == a2 then
          policy(a1) match
            case AddrPolicy.Local => 
              sto.content.get(a1) match
                case Some((_, CountOne)) => BoolLattice[B].inject(true)
                case _                   => BoolLattice[B].top
            case AddrPolicy.Widened => BoolLattice[B].top
        else BoolLattice[B].inject(false)
    }

    def withRestrictedStore(rs: Set[Adr])(blk: A[Val]): A[Val] =
      (anl, env, sto, ctx) =>
        val gcs = anl.StoreGC.collect(sto, rs)
        blk(anl, env, gcs, ctx).map { (v, d) =>
          val gcd = anl.DeltaGC(gcs).collect(d, lattice.refs(v) ++ d.updates)
          (v, sto.replay(gcs, gcd))
        }

    override protected def applyClosure(cll: Cll, lam: Lam, ags: List[Val], fvs: Iterable[(Adr, Val)]): A[Val] =
      withRestrictedStore(ags.flatMap(lattice.refs).toSet ++ fvs.flatMap((_, vlu) => lattice.refs(vlu))) {
        super.applyClosure(cll, lam, ags, fvs)
      }

    //
    // ANALYSISM MONAD
    //

    type A[X] = (Anl, Env, Sto, Ctx) => Option[(X, Dlt)]

    given analysisM: AnalysisM[A] with
        // MONAD
        def unit[X](x: X) =
          (_, _, _, _) => Some((x, Delta.empty))
        def map[X, Y](m: A[X])(f: X => Y) =
          (anl, env, sto, ctx) => m(anl, env, sto, ctx).map((x, d) => (f(x), d))
        def flatMap[X, Y](m: A[X])(f: X => A[Y]) =
          (anl, env, sto, ctx) => 
            for 
              (x0, d0) <- m(anl, env, sto, ctx)
              (x1, d1) <- f(x0)(anl, env, sto.integrate(d0), ctx)
            yield (x1, sto.compose(d1, d0))
        // MONADJOIN
        def mbottom[X] = 
          (_, _, _, _) => None
        def mjoin[X: Lattice](x: A[X], y: A[X]) =
          (anl, env, sto, ctx) =>
            (x(anl, env, sto, ctx), y(anl, env, sto, ctx)) match
              case (None, yres) => yres
              case (xres, None) => xres
              case (Some((x1, d1)), Some((x2, d2))) => Some((Lattice[X].join(x1,x2), sto.join(d1,d2)))
        // MONADERROR
        def fail[X](err: Error) =
          mbottom // we are not interested in errors here (at least, not yet ...)
        // STOREM
        def addrEq =
          (_, _, sto, _) => Some((eqA(sto), Delta.empty))
        def extendSto(adr: Adr, vlu: Val) =
          (anl, _, sto, _) => Some(((), extendV(anl, sto, adr, vlu)))
        def updateSto(adr: Adr, vlu: Val) =
          (anl, _, sto, _) => Some(((), updateV(anl, sto, adr, vlu)))
        def lookupSto(adr: Adr) =
          (anl, _, sto, _) => Some((lookupV(anl, sto, adr), Delta.empty))
        // CTX STUFF
        def getCtx =
          (_, _, _, ctx) => Some((ctx, Delta.empty))
        def withCtx[X](f: Ctx => Ctx)(blk: A[X]): A[X] =
          (anl, env, sto, ctx) => blk(anl, env, sto, f(ctx))
        // ENV STUFF
        def getEnv =
          (_, env, _, _) => Some((env, Delta.empty))
        def withEnv[X](f: Env => Env)(blk: A[X]): A[X] =
          (anl, env, sto, ctx) => blk(anl, f(env), sto, ctx)
        // CALL STUFF
        def call(lam: Lam): A[Val] =
          (anl, env, sto, ctx) => anl.call(CallComponent(lam, env, ctx, sto))

    //
    // THE INTRA-ANALYSIS
    //

    def intraAnalysis(cmp: Component) = new SchemeLocalIntraAnalysis(cmp)
    class SchemeLocalIntraAnalysis(cmp: Cmp) extends IntraAnalysis(cmp) with GlobalStoreIntra { intra =>
      
      // local state
      var results = inter.results

      def call(cmp: Cmp): Option[(Val, Dlt)] = 
        spawn(cmp)
        register(ResultDependency(cmp))
        results.get(cmp)

      def analyzeWithTimeout(timeout: Timeout.T): Unit =
        eval(cmp.exp)(this, cmp.env, cmp.sto, cmp.ctx).foreach { (v, d) =>
          val rgc = (v, DeltaGC(cmp.sto).collect(d, lattice.refs(v) ++ d.updates))
          val old = results.getOrElse(cmp, (lattice.bottom, Delta.empty))
          if rgc != old then
            results = results + (cmp -> rgc)
            trigger(ResultDependency(cmp))
        }

      override def doWrite(dep: Dependency): Boolean = dep match
          case ResultDependency(cmp) =>
            val old = inter.results.getOrElse(cmp, (lattice.bottom, Delta.empty))
            val cur = intra.results(cmp)
            if old != cur then
                inter.results += cmp -> cur
                true
            else false
          case _ => super.doWrite(dep)

      trait AGC[X] extends AbstractGarbageCollector[X, Adr]:
        def moveLocal(addr: Adr, from: X, to: X): (X, Set[Adr])
        def move(addr: Adr, from: X, to: X): (X, Set[Adr]) =
          policy(addr) match
            case AddrPolicy.Local => moveLocal(addr, from, to)
            case AddrPolicy.Widened => (to, lattice.refs(readAddr(addr)))

      object StoreGC extends AGC[Sto]:
          def fresh(cur: Sto) = LocalStore.empty
          def moveLocal(addr: Adr, from: Sto, to: Sto): (Sto, Set[Adr]) =
            from.content.get(addr) match
              case None             => (to, Set.empty)
              case Some(s @ (v, _)) => (LocalStore(to.content + (addr -> s)), lattice.refs(v))

      case class DeltaGC(sto: Sto) extends AGC[Dlt]:
          def fresh(cur: Dlt) = cur.copy(delta = Map.empty) //TODO: this always carries over the set of updated addrs
          def moveLocal(addr: Adr, from: Dlt, to: Dlt): (Dlt, Set[Adr]) =
            from.delta.get(addr) match
              case None => sto.content.get(addr) match
                case None => (to, Set.empty)
                case Some((v, _)) => (to, lattice.refs(v))
              case Some(s @ (v, _)) => (to.copy(delta = to.delta + (addr -> s)), lattice.refs(v))
    }

//TODO: widen resulting values
//TODO: GC at every step? (ARC?)

trait SchemeModFLocalAnalysisResults extends SchemeModFLocal with AnalysisResults[SchemeExp]:
    this: SchemeModFLocalSensitivity with SchemeDomain =>

    var resultsPerIdn = Map.empty.withDefaultValue(Set.empty)

    override def extendV(anl: Anl, sto: Sto, adr: Adr, vlu: Val) =
        adr match
            case _: VarAddr[_] | _: PtrAddr[_] =>
              resultsPerIdn += adr.idn -> (resultsPerIdn(adr.idn) + vlu)
            case _ => ()
        super.extendV(anl, sto, adr, vlu)

    override def updateV(anl: Anl, sto: Sto, adr: Adr, vlu: Val) =
        adr match
            case _: VarAddr[_] | _: PtrAddr[_] =>
              resultsPerIdn += adr.idn -> (resultsPerIdn(adr.idn) + vlu)
            case _ => ()
        super.updateV(anl, sto, adr, vlu)
