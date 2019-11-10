package scalaam.modular.scheme

import scalaam.core._
import scalaam.language.sexp
import scalaam.language.scheme._
import scalaam.util.MonoidImplicits._

trait BigStepSchemeModFSemantics extends SchemeModFSemantics {
  // defining the intra-analysis
  override def intraAnalysis(cmp: IntraComponent) = new IntraAnalysis(cmp)
  class IntraAnalysis(component: IntraComponent) extends super.IntraAnalysis(component) with SchemeModFSemanticsIntra {
    // analysis entry point
    def analyze() = writeResult(component match {
      case MainComponent      => eval(program)
      case cmp: CallComponent => evalSequence(cmp.lambda.body)
    })
    // simple big-step eval
    private def eval(exp: SchemeExp): Value = exp match {
      case SchemeValue(value, _)                    => evalLiteralValue(value)
      case lambda: SchemeLambda                     => lattice.closure((lambda, component), None)
      case SchemeVarLex(_, lex)                     => lookupVariable(lex)
      case SchemeBegin(exps, _)                     => evalSequence(exps)
      case SchemeDefineVariable(id, vexp, _)        => evalDefineVariable(id, vexp)
      case SchemeDefineFunction(id, prs, bdy, pos)  => evalDefineFunction(id, prs, bdy, pos)
      case SchemeSetLex(_, lex, variable, _)        => evalSet(lex, variable)
      case SchemeIf(prd, csq, alt, _)               => evalIf(prd, csq, alt)
      case SchemeLet(bindings, body, _)             => evalLetExp(bindings, body)
      case SchemeLetStar(bindings, body, _)         => evalLetExp(bindings, body)
      case SchemeLetrec(bindings, body, _)          => evalLetExp(bindings, body)
      case SchemeNamedLet(name,bindings,body,pos)   => evalNamedLet(name,bindings,body,pos)
      case SchemeFuncall(fun, args, _)              => evalCall(fun, args)
      case SchemeAnd(exps, _)                       => evalAnd(exps)
      case SchemeOr(exps, _)                        => evalOr(exps)
      case SchemeQuoted(quo, _)                     => evalQuoted(quo)
      case _ => throw new Exception(s"Unsupported Scheme expression: $exp")
    }
    private def evalLiteralValue(literal: sexp.Value): Value = literal match {
      case sexp.ValueInteger(n)   => lattice.number(n)
      case sexp.ValueReal(r)      => lattice.real(r)
      case sexp.ValueBoolean(b)   => lattice.bool(b)
      case sexp.ValueString(s)    => lattice.string(s)
      case sexp.ValueCharacter(c) => lattice.char(c)
      case sexp.ValueSymbol(s)    => lattice.symbol(s)
      case sexp.ValueNil          => lattice.nil
      case _ => throw new Exception(s"Unsupported Scheme literal: $literal")
    }
    private def evalQuoted(quoted: sexp.SExp): Value = quoted match {
      case sexp.SExpId(id)          => lattice.symbol(id.name)
      case sexp.SExpValue(vlu,_)    => evalLiteralValue(vlu)
      case sexp.SExpPair(car,cdr,_) =>
        val carv = evalQuoted(car)
        val cdrv = evalQuoted(cdr)
        val pair = lattice.cons(carv,cdrv)
        val addr = allocAddr(PtrAddr(quoted))
        writeAddr(addr,pair)
        lattice.pointer(addr)
      case sexp.SExpQuoted(q,pos)   =>
        evalQuoted(sexp.SExpPair(sexp.SExpId(Identifier("quote",pos)),sexp.SExpPair(q,sexp.SExpValue(sexp.ValueNil,pos),pos),pos))
    }
    private def evalDefineVariable(id: Identifier, exp: SchemeExp): Value = {
      val value = eval(exp)
      defineVariable(id,value)
      value
    }
    private def evalDefineFunction(id: Identifier, prs: List[Identifier], body: List[SchemeExp], pos: Position): Value = {
      val lambda = SchemeLambda(prs,body,pos)
      val value = lattice.closure((lambda,component),Some(id.name))
      defineVariable(id,value)
      value
    }
    private def evalSequence(exps: List[SchemeExp]): Value =
      exps.foldLeft(lattice.bottom)((_,exp) => eval(exp))
    private def evalSet(lex: LexicalRef, exp: SchemeExp): Value = {
      val newValue = eval(exp)
      setVariable(lex,newValue)
      newValue
    }
    private def evalIf(prd: SchemeExp, csq: SchemeExp, alt: SchemeExp): Value =
      conditional(eval(prd), eval(csq), eval(alt))
    private def evalLetExp(bindings: List[(Identifier,SchemeExp)], body: List[SchemeExp]): Value = {
      bindings.foreach { case (id,exp) => defineVariable(id, eval(exp)) }
      evalSequence(body)
    }
    private def evalNamedLet(id: Identifier, bindings: List[(Identifier,SchemeExp)], body: List[SchemeExp], pos: Position): Value = {
      val (prs,ags) = bindings.unzip
      val lambda = SchemeLambda(prs,body,pos)
      val closure = lattice.closure((lambda,component),Some(id.name))
      defineVariable(id,closure)
      val argsVals = ags.map(argExp => (argExp, eval(argExp)))
      applyFun(lambda,closure,argsVals)
    }
    // R5RS specification: if all exps are 'thruty', then the value is that of the last expression
    private def evalAnd(exps: List[SchemeExp]): Value =
      if (exps.isEmpty) { lattice.bool(true) } else { evalAndLoop(exps) }
    private def evalAndLoop(exps: List[SchemeExp]): Value = (exps: @unchecked) match {
      case exp :: Nil => eval(exp)
      case exp :: rst => conditional(eval(exp),evalAndLoop(rst),lattice.bool(false))
    }
    private def evalOr(exps: List[SchemeExp]): Value = exps.foldRight(lattice.bool(false)) { (exp,acc) =>
      val vlu = eval(exp)
      conditional(vlu,vlu,acc)
    }
    private def evalCall(fun: SchemeExp, args: List[SchemeExp]): Value = {
      val funVal = eval(fun)
      val argVals = args.map(eval)
      applyFun(fun,funVal,args.zip(argVals))
    }
  }
}

//abstract class AdaptiveSchemeModFAnalysis(program: SchemeExp) extends AdaptiveModAnalysis(program)
//                                                              with AdaptiveSchemeModFSemantics