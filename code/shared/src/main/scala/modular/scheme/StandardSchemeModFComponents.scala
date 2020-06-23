package scalaam.modular.scheme

import scalaam.language.scheme._

trait StandardSchemeModFComponents extends SchemeModFSemantics {

  // In ModF, components are function calls in some context.

  // This abstract class is parameterised by the choice of two types of components:
  // * A MainComponent type representing the main function of the program.
  // * A CallComponent type representing function calls. CallComponents must have a parent pointer and lambda expression, contain a context and may contain a name.
  // The MainComponent should be unique and can hence be an object. CallComponents can be created using the `newCallComponent` function.
  // All components used together with this Scheme MODF analysis should be viewable as SchemeComponents.

  trait MainComponent extends SchemeComponent {
    def body: SchemeExp = program
    override def toString: String = "main"
  }
  trait CallComponent extends SchemeComponent {
    // Requires a closure and a context and may contain a name.
    def nam: Option[String]
    def clo: lattice.Closure
    def ctx: ComponentContext
    // convenience accessors
    lazy val (lambda, parent) = clo
    lazy val body: SchemeExp = SchemeBody(lambda.body)
    override def toString: String = nam match {
      case None => s"λ@${lambda.idn} ($parent) [${ctx.toString}]"
      case Some(name) => s"$name ($parent) [${ctx.toString}]"
    }
  }

  type ComponentContent = Option[lattice.Closure]
  def content(cmp: Component) = view(cmp) match {
    case _ : MainComponent => None
    case call: CallComponent => Some(call.clo)
  }
  def context(cmp: Component) = view(cmp) match {
    case _ : MainComponent => None
    case call: CallComponent => Some(call.ctx)
  }

  def componentParent(cmp: Component): Option[Component] = view(cmp) match {
    case _ : MainComponent => None
    case call: CallComponent => Some(call.parent)
  }
}

trait StandardSchemeModFSemantics extends StandardSchemeModFComponents {
  // Components are just normal SchemeComponents, without any extra fancy features.
  // Hence, to view a component as a SchemeComponent, the component itself can be used.
  type Component = SchemeComponent
  implicit def view(cmp: Component): SchemeComponent = cmp

  // Definition of the initial component.
  case object Main extends MainComponent
  // Definition of call components.
  case class Call(clo: lattice.Closure, nam: Option[String], ctx: ComponentContext) extends CallComponent

  lazy val initialComponent: SchemeComponent = Main
  def newComponent(clo: lattice.Closure, nam: Option[String], ctx: ComponentContext): SchemeComponent = Call(clo,nam,ctx)
}

trait StandardSchemeModConcSemantics extends SmallStepModConcSemantics {
  type Component = SchemeComponent
  implicit def view(c: Component): SchemeComponent = c

  // The main process of the program.
  case object MainComponent extends SchemeComponent {
    def body: Exp = program
    override def toString: String = "Main"
  }

  // A process created by the program.
  case class ProcessComponent(body: Exp, ctx: ComponentContext) extends SchemeComponent

  lazy val initialComponent: SchemeComponent = MainComponent
  def newComponent(body: Exp, ctx: ComponentContext): SchemeComponent = ProcessComponent(body, ctx)

  // Other required definitions.

  type ComponentContent = Option[Exp]
  def content(cmp: Component) = view(cmp) match {
    case MainComponent => None
    case p: ProcessComponent => Some(p.body)
  }
  def context(cmp: Component) = view(cmp) match {
    case MainComponent => None
    case p: ProcessComponent => Some(p.ctx)
  }
}