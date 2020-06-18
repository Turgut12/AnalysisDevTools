package scalaam.modular.scheme

import language.CScheme._
import scalaam.core._
import scalaam.language.CScheme._
import scalaam.language.scheme._
import scalaam.language.scheme.primitives.{SchemeAllocator, SchemeLatticePrimitives, SchemePrelude, SchemePrimitive, SchemePrimitives}
import scalaam.language.sexp
import scalaam.modular.components.ContextSensitiveComponents
import scalaam.modular.{GlobalStore, ModAnalysis, ReturnValue}
import scalaam.util.SmartHash

trait SmallStepModConcSemantics extends ModAnalysis[SchemeExp]
                                   with GlobalStore[SchemeExp]
                                   with ReturnValue[SchemeExp]
                                   with ContextSensitiveComponents[SchemeExp] {
  
  type Exp  = SchemeExp
  type Exps = List[Exp]

  implicit def view(c: Component): SchemeComponent
  trait SchemeComponent extends SmartHash { def body: SchemeExp }

  override lazy val program: SchemeExp = {
    val originalProgram = super.program
    val preludedProgram = SchemePrelude.addPrelude(originalProgram)
    CSchemeUndefiner.undefine(List(preludedProgram))
  }

 // def allocPID(): PID

  //XXXXXXXXXXX//
  // ADDRESSES //
  //XXXXXXXXXXX//

  // TODO: incorporate another addressing scheme...

  // Local addresses are simply made out of lexical information.
  sealed trait LocalAddr extends Address {
    def idn(): Identity
    override def toString() = this match {
      case VarAddr(id)  => s"var ($id)"
      case PtrAddr(exp) => s"ptr (${exp.idn})"
      case PrmAddr(nam) => s"prm ($nam)"
    }
  }
  case class VarAddr(id: Identifier)  extends LocalAddr { def printable = true;  def idn(): Identity =  id.idn }
  case class PtrAddr(exp: SchemeExp)  extends LocalAddr { def printable = false; def idn(): Identity =  exp.idn }
  case class PrmAddr(nam: String)     extends LocalAddr { def printable = true;  def idn(): Identity = Identity.none }

  override def intraAnalysis(component: Component): IntraAnalysis = new SmallStepIntra(component)

  //XXXXXXXXXXXXXXXXX//
  // ABSTRACT VALUES //
  //XXXXXXXXXXXXXXXXX//

  // Abstract values come from a Scala-AM Scheme lattice (a type lattice).
  type Prim = SchemePrimitive[Value, Addr]
  implicit val lattice: SchemeLattice[Value, Addr, Prim, Env]
  lazy val primitives: SchemePrimitives[Value, Addr] = new SchemeLatticePrimitives()

  case class Env(data: Map[String, Addr])

  //XXXXXXXXXXXXXXXXXXXXXXXXXX//
  // INTRA-COMPONENT ANALYSIS //
  //XXXXXXXXXXXXXXXXXXXXXXXXXX//

  class SmallStepIntra(cmp: Component) extends IntraAnalysis(cmp) with GlobalStoreIntra with ReturnResultIntra  {

    def newEnv(): Env = Env(Map())

    def extendEnv(id: Identifier, addr: LocalAddr, env: Env): Env = {
      val adr = ComponentAddr(component, addr)
      env.copy(data = env.data + (id.name -> adr))
    }
    def lookupEnv(id: Identifier, env: Env): Addr = env.data(id.name)

    def analyze(): Unit = {
      val initialState = Eval(component.body, newEnv(), Nil)
      var work: WorkList[State] = LIFOWorkList[State](initialState)
      var visited = Set[State]()
      var result  = lattice.bottom
      while(work.nonEmpty) {
        val state = work.head
        work = work.tail
        state match {
          case Kont(vl, Nil) =>
            result = lattice.join(result,vl)
          case _ if !visited.contains(state) =>
            val successors = step(state)
            work = work.addAll(successors)
            visited += state
          case _ => ()
        }
      }
      writeResult(result)
    }

    private def bind(variable: Identifier, vl: Value, env: Env): Env = {
      val addr = VarAddr(variable)
      writeAddr(addr, vl)
      extendEnv(variable, addr, env)
    }

    private def rebind(variable: Identifier, vl: Value, env: Env): Value = {
      writeAddr(lookupEnv(variable, env), vl)
      lattice.bottom
    }

    sealed trait State
    sealed trait Frame
    type Stack = List[Frame]

    case class Eval(expr: Exp, env: Env, stack: Stack) extends State
    case class Kont(vl: Value, stack: Stack) extends State

    case class SequenceFrame(exps: Exps, env: Env) extends Frame
    case class IfFrame(cons: Exp, alt: Exp, env: Env) extends Frame
    case class AndFrame(exps: Exps, env: Env) extends Frame
    case class OrFrame(exps: Exps, env: Env) extends Frame
    case class PairCarFrame(cdr: SchemeExp, env: Env, pair: Exp) extends Frame
    case class PairCdrFrame(car: Value, pair: Exp) extends Frame
    case class SetFrame(variable: Identifier, env: Env) extends Frame
    case class OperatorFrame(args: Exps, env: Env, fexp: SchemeFuncall) extends Frame
    case class OperandsFrame(todo: Exps, done: List[(Exp, Value)], env: Env, f: Value, fexp: SchemeFuncall) extends Frame // "todo" may also contain the expression currently evaluated.
    case class LetFrame(todo: List[(Identifier, Exp)], done: List[(Identifier, Value)], body: Exps, env: Env) extends Frame
    case class LetStarFrame(todo: List[(Identifier, Exp)], body: Exps, env: Env) extends Frame
    case class LetRecFrame(todo: List[(Identifier, Exp)], body: Exps, env: Env) extends Frame

    private def step(state: State): Set[State] = state match {
      case Eval(exp, env, stack) => eval(exp, env, stack)
      case Kont(vl, Nil) => throw new Exception("Cannot step a continuation state with an empty stack.")
      case Kont(vl, stack) => kont(vl, stack.head, stack.tail)
    }

    private def eval(exp: Exp, env: Env, stack: Stack): Set[State] = exp match {
      // Single-step evaluation.
      case l@SchemeLambda(_, _, _)                   => Set(Kont(lattice.closure((l, env), None), stack))
      case SchemeValue(value, _)                     => Set(Kont(evalLiteralValue(value), stack))
      case SchemeVar(id)                             => Set(Kont(readAddr(lookupEnv(id, env)), stack))
      case l@SchemeVarArgLambda(_, _, _, _)          => Set(Kont(lattice.closure((l, env), None), stack))

      // Multi-step evaluation.
      case c@SchemeFuncall(f, args, _)               => Set(Eval(f, env, OperatorFrame(args, env, c) :: stack))
      case SchemeIf(cond, cons, alt, _)              => evalIf(cond, cons, alt, env, stack)
      case SchemeLet(bindings, body, _)              => evalLet(bindings, List(), body, env, stack)
      case SchemeLetStar(bindings, body, _)          => evalLetStar(bindings, body, env, stack)
      case SchemeLetrec(bindings, body, _)           => evalLetRec(bindings, body, env, stack)
      case SchemeNamedLet(name, bindings, body, _)   => evalNamedLet(name, bindings, body, env, stack)
      case SchemeSet(variable, value, _)             => Set(Eval(value, env, SetFrame(variable, env) :: stack))
      case SchemeBegin(exps, _)                      => evalSequence(exps, env, stack)
      case SchemeAnd(exps, _)                        => evalAnd(exps, env, stack)
      case SchemeOr(exps, _)                         => evalOr(exps, env, stack)
      case e@SchemePair(car, cdr, _)                 => Set(Eval(car, env, PairCarFrame(cdr, env, e) :: stack))
      case SchemeSplicedPair(_, _, _)                => throw new Exception("Splicing not supported.")

      // Multithreading.
      case CSchemeFork(body, _)                      => ???
      case CSchemeJoin(body, _)                      => ???

      // Unexpected cases.
      case e                                         => throw new Exception(s"eval: unexpected expression type: ${e.label}.")
    }

    private def evalSequence(exps: Exps, env: Env, stack: Stack): Set[State] = exps match {
      case e :: Nil => Set(Eval(e, env, stack))
      case e :: exps => Set(Eval(e, env, SequenceFrame(exps, env) :: stack))
      case Nil => throw new Exception("Empty body should have been disallowed by compiler.")
    }

    private def evalIf(cond: Exp, cons: Exp, alt: Exp, env: Env, stack: Stack): Set[State] =
      Set(Eval(cond, env, IfFrame(cons, alt, env) :: stack))

    private def evalAnd(exps: Exps, env: Env, stack: Stack): Set[State] = exps match {
      case Nil => Set(Kont(lattice.bool(true), stack))
      case e :: exps => Set(Eval(e, env, AndFrame(exps, env) :: stack))
    }

    private def evalOr(exps: Exps, env: Env, stack: Stack): Set[State] = exps match {
      case Nil => Set(Kont(lattice.bool(false), stack))
      case e :: exps => Set(Eval(e, env, OrFrame(exps, env) :: stack))
    }

    private def evalArgs(todo: Exps, fexp: SchemeFuncall, f: Value, done: List[(Exp, Value)], env: Env, stack: Stack): Set[State] = todo match {
      case Nil => applyFun(fexp, f, done.reverse, env, stack) // Function application.
      case args@(arg :: _) => Set(Eval(arg, env, OperandsFrame(args, done, env, f, fexp) :: stack))
    }

    private def evalLet(todo: List[(Identifier, Exp)], done: List[(Identifier, Value)], body: Exps, env: Env, stack: Stack): Set[State] = todo match {
      case Nil =>
        val env2 = done.reverse.foldLeft(env)((env, bnd) => bind(bnd._1, bnd._2, env))
        evalSequence(body, env2, stack)
      case bnd@((_, exp) :: _) => Set(Eval(exp, env, LetFrame(bnd, done, body, env) :: stack))
    }

    private def evalLetStar(todo: List[(Identifier, Exp)], body: Exps, env: Env, stack: Stack): Set[State] = todo match {
      case Nil => evalSequence(body, env, stack)
      case bnd@((_, exp) :: _) => Set(Eval(exp, env, LetStarFrame(bnd, body, env) :: stack))
    }

    private def evalLetRec(bindings: List[(Identifier, Exp)], body: Exps, env: Env, stack: Stack): Set[State] = bindings match {
      case Nil => evalSequence(body, env, stack)
      case bnd@((_, exp) :: _) =>
        val env2 = bnd.map(_._1).foldLeft(env)((env, id) => bind(id, lattice.bottom, env))
        Set(Eval(exp, env, LetRecFrame(bnd, body, env2) :: stack))
    }

    private def continueLetRec(todo: List[(Identifier, Exp)], body: Exps, env: Env, stack: Stack): Set[State] = todo match {
      case Nil => evalSequence(body, env, stack)
      case bnd@((_, exp) :: _) => Set(Eval(exp, env, LetRecFrame(bnd, body, env) :: stack))
    }

    private def evalNamedLet(name: Identifier, bindings: List[(Identifier, Exp)], body: Exps, env: Env, stack: Stack): Set[State] = {
      val (form, actu) = bindings.unzip
      val lambda = SchemeLambda(form, body, name.idn)
      val clo = lattice.closure((lambda, env), Some(name.name))
      val env2 = bind(name, clo, env)
      val call = SchemeFuncall(lambda, actu, name.idn)
      evalArgs(actu, call, clo, Nil, env2, stack)
    }

    private def conditional(value: Value, t: State, f: State): Set[State] = conditional(value, Set(t), Set(f))
    private def conditional(value: Value, t: Set[State], f: Set[State]): Set[State] = {
      val tr = if (lattice.isTrue(value)) t else Set[State]()
      if (lattice.isFalse(value)) tr ++ f else tr
    }

    private def kont(vl: Value, frame: Frame, stack: Stack): Set[State] = frame match {
      case SequenceFrame(exps, env) => evalSequence(exps, env, stack)
      case IfFrame(cons, alt, env) => conditional(vl, Eval(cons, env, stack), Eval(alt,  env, stack))
      case AndFrame(exps, env) =>
        conditional(vl, evalAnd(exps, env, stack), Set[State](Kont(lattice.bool(false), stack)))
      case OrFrame(exps, env) =>
        conditional(vl, Set[State](Kont(lattice.bool(true), stack)), evalOr(exps, env, stack))
      case PairCarFrame(cdr, env, pair) => Set(Eval(cdr, env, PairCdrFrame(vl, pair) :: stack))
      case PairCdrFrame(carv, pair) => Set(Kont(allocateCons(pair)(carv, vl), stack))
      case SetFrame(variable, env) => Set(Kont(rebind(variable, vl, env), stack)) // Returns bottom.
      case OperatorFrame(args, env, fexp) => evalArgs(args, fexp, vl, List(), env, stack)
      case OperandsFrame(todo, done, env, f, fexp) => evalArgs(todo.tail, fexp, f, (todo.head, vl) :: done, env, stack)
      case LetFrame(todo, done, body, env) => evalLet(todo.tail, (todo.head._1, vl) :: done, body, env, stack)
      case LetStarFrame(todo, body, env) =>
        val env2 = bind(todo.head._1, vl, env)
        evalLetStar(todo.tail, body, env2, stack)
      case LetRecFrame(todo, body, env) =>
        rebind(todo.head._1, vl, env)
        continueLetRec(todo.tail, body, env, stack)
    }

    //====================//
    // EVALUATION HELPERS //
    //====================//

    // primitives glue code
    // TODO[maybe]: while this should be sound, it might be more precise to not immediately write every value update to the global store ...
    case object StoreAdapter extends Store[Addr,Value] {
      def lookup(a: Addr): Option[Value] = Some(readAddr(a))
      def extend(a: Addr, v: Value): Store[Addr, Value] = { writeAddr(a,v) ; this }
      // all the other operations should not be used by the primitives ...
      def content                               = throw new Exception("Operation not allowed!")
      def keys                                  = throw new Exception("Operation not allowed!")
      def restrictTo(a: Set[Addr])              = throw new Exception("Operation not allowed!")
      def forall(p: ((Addr, Value)) => Boolean) = throw new Exception("Operation not allowed!")
      def join(that: Store[Addr, Value])        = throw new Exception("Operation not allowed!")
      def subsumes(that: Store[Addr, Value])    = throw new Exception("Operation not allowed!")
    }

    // Evaluate literals by in injecting them in the lattice.
    protected def evalLiteralValue(literal: sexp.Value): Value = literal match {
      case sexp.ValueInteger(n)   => lattice.number(n)
      case sexp.ValueReal(r)      => lattice.real(r)
      case sexp.ValueBoolean(b)   => lattice.bool(b)
      case sexp.ValueString(s)    => lattice.string(s)
      case sexp.ValueCharacter(c) => lattice.char(c)
      case sexp.ValueSymbol(s)    => lattice.symbol(s)
      case sexp.ValueNil          => lattice.nil
      case _ => throw new Exception(s"Unsupported Scheme literal: $literal")
    }

    protected def applyPrimitives(fexp: SchemeFuncall, fval: Value, args: List[(SchemeExp,Value)], stack: Stack): Set[State] = {
      lattice.getPrimitives(fval).map(prm => Kont(
        prm.call(fexp, args, StoreAdapter, allocator) match {
          case MayFailSuccess((vlu,_))  => vlu
          case MayFailBoth((vlu,_),_)   => vlu
          case MayFailError(_)          => lattice.bottom
        },
        stack)
      ).toSet
    }

    protected def applyClosures(fun: Value, args: List[(SchemeExp,Value)], env: Env, stack: Stack): Set[State] = {
      val arity = args.length
      lattice.getClosures(fun).flatMap({
        case ((SchemeLambda(prs,body,_),_), _) if prs.length == arity =>
          val env2 = prs.zip(args.map(_._2)).foldLeft(env)({case (env, (f, a)) => bind(f, a, env)})
          evalSequence(body, env2, stack)
        case ((SchemeVarArgLambda(prs,vararg,body,_),_), _) if prs.length <= arity =>
          val (fixedArgs, varArgs) = args.splitAt(prs.length)
          val fixedArgVals = fixedArgs.map(_._2)
          val varArgVal = allocateList(varArgs)
          val env2 = bind(vararg, varArgVal, prs.zip(fixedArgVals).foldLeft(env)({case (env, (f, a)) => bind(f, a, env)}))
          evalSequence(body, env2, stack)
        case _ => Set()
      })
    }

    protected def applyFun(fexp: SchemeFuncall, fval: Value, args: List[(SchemeExp,Value)], env: Env, stack: Stack): Set[State] =
      if(args.forall(_._2 != lattice.bottom))
        applyClosures(fval,args, env, stack) ++ applyPrimitives(fexp, fval, args, stack)
      else
        Set(Kont(lattice.bottom, stack))

    //====================//
    // ALLOCATION HELPERS //
    //====================//

    protected def allocateCons(pairExp: SchemeExp)(car: Value, cdr: Value): Value = {
      val addr = allocAddr(PtrAddr(pairExp))
      val pair = lattice.cons(car,cdr)
      writeAddr(addr,pair)
      lattice.pointer(addr)
    }

    protected def allocateList(elms: List[(SchemeExp,Value)]): Value = elms match {
      case Nil                => lattice.nil
      case (exp,vlu) :: rest  => allocateCons(exp)(vlu,allocateList(rest))
    }

    val allocator: SchemeAllocator[Addr] = new SchemeAllocator[Addr] {
      def pointer(exp: SchemeExp): Addr = allocAddr(PtrAddr(exp))
    }
  }
}
