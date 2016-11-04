import scalaz._
import scalaz.Scalaz._

/** A (join semi-)lattice L should support the following operations */
trait JoinLattice[L] extends Monoid[L] with PartialOrdering[L] {
  /** A lattice has a bottom element */
  def bottom: L
  /** Elements of the lattice can be joined together */
  def join(x: L, y: L): L
  def append(x: L, y: => L): L = join(x, y) /* A lattice is trivially a monoid by using join as append */
  def zero: L = bottom /* And bottom as zero */
  /** Subsumption between two elements can be checked */
  def subsumes(x: L, y: L): Boolean
  def lteq(x: L, y: L): Boolean = subsumes(y, x) /* A lattice has a partial order, defined by subsumes */
  def tryCompare(x: L, y: L): Option[Int] = (subsumes(x, y), subsumes(y, x)) match {
    case (true, true) => Some(0) // x >= y and y >= x => x = y
    case (true, false) => Some(1) // x >= y and x != y
    case (false, true) => Some(-1) // y >= x and x != y
    case (false, false) => None // not comparable
  }

  /** We have some more components for convenience */
  /** A name identifying the lattice */
  def name: String
  /** It should state whether it supports abstract counting or not. (TODO: this is probably not the best place for that) */
  def counting: Boolean

  /** Some elements may contain addresses in there and are therefore not considered as primitive values */
  def isPrimitiveValue(x: L): Boolean
  /** Cardinality of this value */
  def cardinality(x: L): Cardinality
}

object JoinLattice {
  def apply[L : JoinLattice]: JoinLattice[L] = implicitly[JoinLattice[L]]
}

/** Cardinality represents how much information a lattice value represents */
trait Cardinality
case object CardinalityInf extends Cardinality
case class CardinalityNumber(n: Int) extends Cardinality
/* TODO: In some cases we might not want to have cardinalities for values such
 * as numbers, strings, etc. For example, cardinality of {Int, clo(...),
 * clo(...)}  is infinity, while it would make more sense to have it as either 2
 * or 3. We might want to split cardinalities between pointer-like values
 * (closures, primitive functions, cons, etc.) to primitive-like values (ints,
 * strings, etc.). One just needs to change the following objects to case
 * classes and adapt the monoid.
 */
object CardinalityPrimitiveLikeInf {
  def apply(): Cardinality = CardinalityInf
}
object CardinalityPrimitiveLikeNumber {
  def apply(n: Int): Cardinality = CardinalityNumber(n)
}
object Cardinality {
  implicit val cardinalityAddMonoid: Monoid[Cardinality] = new Monoid[Cardinality] {
    def zero: Cardinality = CardinalityNumber(0)
    def append(x: Cardinality, y: => Cardinality): Cardinality = (x, y) match {
      case (CardinalityInf, _) | (_, CardinalityInf) => CardinalityInf
      case (CardinalityNumber(m), CardinalityNumber(n)) => CardinalityNumber(m + n)
    }
  }
}

/**
 * We define here some domains that can will be useful to build a lattice for
 * most languages.
 */
trait LatticeElement[L] extends Order[L] with Monoid[L] with Show[L] {
  def name: String
  def bottom: L
  def top: L
  def join(x: L, y: => L): L
  def subsumes(x: L, y: => L): Boolean
  def eql[B : BoolLattice](x: L, y: L): B
  def cardinality(x: L): Cardinality

  /* For Monoid[L] */
  final def zero: L = bottom
  final def append(x: L, y: => L): L = join(x, y)
}

object LatticeElement {
  def apply[L : LatticeElement]: LatticeElement[L] = implicitly[LatticeElement[L]]

  implicit def ofSet[A]: LatticeElement[Set[A]] = new LatticeElement[Set[A]] {
    def name = "OfSet"
    def bottom: Set[A] = Set.empty
    def top: Set[A] = throw new Error("OfSet lattice has no top value")
    def join(x: Set[A], y: => Set[A]): Set[A] = x ++ y
    def subsumes(x: Set[A], y: => Set[A]): Boolean = y.subsetOf(x)
    def eql[B : BoolLattice](x: Set[A], y: Set[A]): B =
      if (x.size == 1 && y.size == 1 && x == y) { BoolLattice[B].inject(true) }
      else if (x.intersect(y).isEmpty) { BoolLattice[B].inject(false) }
      else { BoolLattice[B].top }
    def order(x: Set[A], y: Set[A]): Ordering =
      throw new Error("Cannot define an order since A is not required to be ordered")
    def cardinality(x: Set[A]): Cardinality = CardinalityNumber(x.size)
  }
}

/** A lattice for strings */
trait StringLattice[S] extends LatticeElement[S] {
  def inject(s: String): S
  def length[I : IntLattice](s: S): I
  def append(s1: S, s2: S): S
}

object StringLattice {
  def apply[S : StringLattice]: StringLattice[S] = implicitly[StringLattice[S]]
}

/** A lattice for booleans */
trait BoolLattice[B] extends LatticeElement[B] {
  def inject(b: Boolean): B
  def isTrue(b: B): Boolean
  def isFalse(b: B): Boolean
  def not(b: B): B
}

object BoolLattice {
  def apply[B : BoolLattice]: BoolLattice[B] = implicitly[BoolLattice[B]]
}

/** A lattice for integers */
trait IntLattice[I] extends LatticeElement[I] {
  def inject(n: Int): I
  def ceiling(n: I): I
  def toFloat[F : FloatLattice](n: I): F
  def random(n: I): I
  def plus(n1: I, n2: I): I
  def minus(n1: I, n2: I): I
  def times(n1: I, n2: I): I
  def div(n1: I, n2: I): I
  def modulo(n1: I, n2: I): I
  def lt[B : BoolLattice](n1: I, n2: I): B
  def toString[S : StringLattice](n: I): S
}

object IntLattice {
  def apply[I : IntLattice]: IntLattice[I] = implicitly[IntLattice[I]]
}

/** A lattice for floats */
trait FloatLattice[F] extends LatticeElement[F] {
  def inject(n: Float): F
  def ceiling(n: F): F
  def log(n: F): F
  def random(n: F): F
  def plus(n1: F, n2: F): F
  def minus(n1: F, n2: F): F
  def times(n1: F, n2: F): F
  def div(n1: F, n2: F): F
  def lt[B : BoolLattice](n1: F, n2: F): B
  def toString[S : StringLattice](n: F): S
}

object FloatLattice {
  def apply[F : FloatLattice]: FloatLattice[F] = implicitly[FloatLattice[F]]
}

/** A lattice for characters */
trait CharLattice[C] extends LatticeElement[C] {
  def inject(c: Char): C
}

object CharLattice {
  def apply[C : CharLattice]: CharLattice[C] = implicitly[CharLattice[C]]
}

/** A lattice for symbols */
trait SymbolLattice[Sym] extends LatticeElement[Sym] {
  def inject(sym: String): Sym
}

object SymbolLattice {
  def apply[Sym : SymbolLattice]: SymbolLattice[Sym] = implicitly[SymbolLattice[Sym]]
}

/**
 * Some implementations of these abstract domains
 */
object ConcreteString {
  type S = ISet[String]
  implicit val isString = new StringLattice[S] {
    def name = "ConcreteString"
    private def showString(s: String) = "\"" + s + "\""
    override def shows(x: S): String = if (x.size == 1) { showString(x.elems.head) } else { "{" + x.toList.map(showString _).mkString(",") + "}" }
    def top: S = throw new Error("Concrete lattice has no top value")
    val bottom: S = ISet.empty
    def join(x: S, y: => S) = x.union(y)
    def subsumes(x: S, y: => S) = y.isSubsetOf(x)

    def inject(x: String): S = ISet.singleton(x)
    def length[I : IntLattice](s: S): I = s.foldMap(s => IntLattice[I].inject(s.size))
    def append(s1: S, s2: S): S = s1.foldMap(s1 => s2.map(s2 => s1 + s2))
    def eql[B : BoolLattice](s1: S, s2: S): B = s1.foldMap(s1 => s2.foldMap(s2 => BoolLattice[B].inject(s1 == s2)))

    def order(x: S, y: S): Ordering = Order[ISet[String]].order(x, y)
    def cardinality(x: S): Cardinality = CardinalityPrimitiveLikeNumber(x.toList.length)
  }
}

object ConcreteBoolean {
  type B = ISet[Boolean]
  implicit val isBoolean: BoolLattice[B] = new BoolLattice[B] {
    def name = "ConcreteBoolean"
    private def showBool(b: Boolean) = if (b) "#t" else "#f"
    override def shows(x: B): String = if (x.size == 1) { showBool(x.elems.head) } else { "{" + x.elems.map(showBool _).mkString(",") + "}" }
    val bottom: B = ISet.empty
    val top: B = ISet.fromList(List(true, false))
    def join(x: B, y: => B) = x.union(y)
    def subsumes(x: B, y: => B) = y.isSubsetOf(x)

    def inject(x: Boolean): B = ISet.singleton(x)
    def isTrue(b: B): Boolean = b.contains(true)
    def isFalse(b: B): Boolean = b.contains(false)
    def not(b: B): B = b.map(x => !x)
    def eql[B1 : BoolLattice](b1: B, b2: B): B1 = b1.foldMap(b1 => b2.foldMap(b2 => BoolLattice[B1].inject(b1 == b2)))

    def order(x: B, y: B): Ordering = implicitly[Order[ISet[Boolean]]].order(x, y)
    def cardinality(x: B): Cardinality = CardinalityPrimitiveLikeNumber(x.toList.length)
  }
}

object ConcreteInteger {
  type I = ISet[Int]
  implicit val isInteger = new IntLattice[I] {
    def name = "ConcreteInteger"
    override def shows(x: I): String = if (x.size == 1) { x.elems.head.toString } else { "{" + x.elems.mkString(",") + "}" }
    val bottom: I = ISet.empty
    def top: I = throw new Error("Concrete lattice has no top value")
    def join(x: I, y: => I) = x.union(y)
    def subsumes(x: I, y: => I) = y.isSubsetOf(x)

    def inject(x: Int): I = ISet.singleton(x)
    def ceiling(n: I): I = n
    def toFloat[F : FloatLattice](n: I): F = n.foldMap(n => FloatLattice[F].inject(n))
    def random(n: I): I = n.map(n => SchemeOps.random(n))
    def plus(n1: I, n2: I): I = n1.foldMap(n1 => n2.map(n2 => n1 + n2))
    def minus(n1: I, n2: I): I = n1.foldMap(n1 => n2.map(n2 => n1 - n2))
    def times(n1: I, n2: I): I = n1.foldMap(n1 => n2.map(n2 => n1 * n2))
    def div(n1: I, n2: I): I = n1.foldMap(n1 => n2.map(n2 => n1 / n2))
    def modulo(n1: I, n2: I): I = n1.foldMap(n1 => n2.map(n2 => SchemeOps.modulo(n1, n2)))
    def lt[B : BoolLattice](n1: I, n2: I): B = n1.foldMap(n1 => n2.foldMap(n2 => BoolLattice[B].inject(n1 < n2)))
    def eql[B : BoolLattice](n1: I, n2: I): B = n1.foldMap(n1 => n2.foldMap(n2 => BoolLattice[B].inject(n1 == n2)))
    def toString[S : StringLattice](n: I): S = n.foldMap(n => StringLattice[S].inject(n.toString))

    def order(x: I, y: I): Ordering = implicitly[Order[ISet[Int]]].order(x, y)
    def cardinality(x: I): Cardinality = CardinalityPrimitiveLikeNumber(x.toList.length)
  }
}

object ConcreteFloat {
  type F = ISet[Float]
  implicit val isFloat = new FloatLattice[F] {
    def name = "ConcreteFloat"
    override def shows(x: F): String = if (x.size == 1) { x.elems.head.toString } else { "{" + x.elems.mkString(",") + "}" }
    val bottom: F = ISet.empty
    def top: F = throw new Error("Concrete lattice has no top value")
    def join(x: F, y: => F) = x.union(y)
    def subsumes(x: F, y: => F) = y.isSubsetOf(x)

    def inject(x: Float): F = ISet.singleton(x)
    def ceiling(n: F): F = n.map(_.ceil)
    def log(n: F): F = n.map(n => scala.math.log(n.toDouble).toFloat)
    def random(n: F): F = n.map(n => SchemeOps.random(n))
    def plus(n1: F, n2: F): F = n1.foldMap(n1 => n2.map(n2 => n1 + n2))
    def minus(n1: F, n2: F): F = n1.foldMap(n1 => n2.map(n2 => n1 - n2))
    def times(n1: F, n2: F): F = n1.foldMap(n1 => n2.map(n2 => n1 * n2))
    def div(n1: F, n2: F): F = n1.foldMap(n1 => n2.map(n2 => n1 / n2))
    def lt[B : BoolLattice](n1: F, n2: F): B = n1.foldMap(n1 => n2.foldMap(n2 => BoolLattice[B].inject(n1 < n2)))
    def eql[B : BoolLattice](n1: F, n2: F): B = n1.foldMap(n1 => n2.foldMap(n2 => BoolLattice[B].inject(n1 == n2)))
    def toString[S : StringLattice](n: F): S = n.foldMap(n => StringLattice[S].inject(n.toString))

    def order(x: F, y: F): Ordering = Order[ISet[Float]].order(x, y)
    def cardinality(x: F): Cardinality = CardinalityPrimitiveLikeNumber(x.toList.length)
  }
}

object ConcreteChar {
  type C = ISet[Char]
  implicit val isChar = new CharLattice[C] {
    def name = "ConcreteChar"
    private def showChar(c: Char) = s"#\\$c"
    override def shows(x: C): String = if (x.size == 1) { showChar(x.elems.head) } else { "{" + x.elems.map(showChar _).mkString(",") + "}" }

    val bottom: C = ISet.empty
    def top: C = throw new Error("Concrete lattice has no top value")
    def join(x: C, y: => C) = x.union(y)
    def subsumes(x: C, y: => C) = y.isSubsetOf(x)

    def inject(x: Char): C = ISet.singleton(x)
    def eql[B : BoolLattice](c1: C, c2: C): B = c1.foldMap(c1 => c2.foldMap(c2 => BoolLattice[B].inject(c1 == c2)))

    def order(x: C, y: C): Ordering = Order[ISet[Char]].order(x, y)
    def cardinality(x: C): Cardinality = CardinalityPrimitiveLikeNumber(x.toList.length)
  }
}

object ConcreteSymbol {
  sealed trait Symbol
  type Sym = ISet[String]
  implicit val isSymbol = new SymbolLattice[Sym] {
    def name = "ConcreteSymbol"
    override def shows(x: Sym): String = if (x.size == 1) { x.elems.head } else { "{" + x.elems.mkString(",") + "}" }

    val bottom: Sym = ISet.empty
    def top: Sym = throw new Error("Concrete lattice has no top value")
    def join(x: Sym, y: => Sym) = x.union(y)
    def subsumes(x: Sym, y: => Sym) = y.isSubsetOf(x)

    def inject(x: String): Sym = ISet.singleton(x)
    def eql[B : BoolLattice](s1: Sym, s2: Sym): B = s1.foldMap(s1 => s2.foldMap(s2 => BoolLattice[B].inject(s1 == s2)))

    def order(x: Sym, y: Sym): Ordering = implicitly[Order[ISet[String]]].order(x, y)
    def cardinality(x: Sym): Cardinality = CardinalityPrimitiveLikeNumber(x.toList.length)
  }
}

class BoundedInteger(bound: Int) {
  sealed trait I
  case object Top extends I
  case class Set(content: ISet[Int]) extends I
  implicit val isMonoid = new Monoid[I] {
    def zero: I = Set(ISet.empty)
    def append(x: I, y: => I) = x match {
      case Set(xs) => y match {
        case Set(ys) => Set(xs.union(ys))
        case Top => y
      }
      case Top => x
    }
  }
  implicit val isInteger = new IntLattice[I] {
    def name = s"BoundedInteger($bound)"
    override def shows(x: I): String = x match {
      case Set(xs) if xs.size == 1 => xs.elems.head.toString
      case Set(xs) => "{" + xs.elems.mkString(",") + "}"
      case Top => "Int"
    }
    val bottom: I = implicitly[Monoid[I]].zero
    val top: I = Top
    def join(x: I, y: => I) = implicitly[Monoid[I]].append(x, y)
    def subsumes(x: I, y: => I) = x match {
      case Set(xs) => y match {
        case Set(ys) => ys.isSubsetOf(xs)
        case Top => false
      }
      case Top => true
    }
    private def promote(x: ISet[Int]): I = x.findMax match {
      case Some(i) if Math.abs(i) > bound => Top
      case _ => x.findMin match {
        case Some(i) if Math.abs(i) > bound => Top
        case _ => Set(x)
      }
    }
    private def fold[L : LatticeElement](x: I, f: Int => L): L = x match {
      case Set(xs) => xs.foldMap(f)
      case Top => LatticeElement[L].top
    }
    private def foldI(x: I, f: Int => I) = x match {
      case Set(xs) => xs.foldMap(f)(isMonoid)
      case Top => Top
    }
    def inject(x: Int): I = promote(ISet.singleton(x))
    def ceiling(n: I): I = n
    def toFloat[F : FloatLattice](n: I): F = fold(n, n => FloatLattice[F].inject(n))
    def random(n: I): I = Top
    def plus(n1: I, n2: I): I = foldI(n1, n1 => foldI(n2, n2 => inject(n1 + n2)))
    def minus(n1: I, n2: I): I = foldI(n1, n1 => foldI(n2, n2 => inject(n1 - n2)))
    def times(n1: I, n2: I): I = foldI(n1, n1 => foldI(n2, n2 => inject(n1 * n2)))
    def div(n1: I, n2: I): I = foldI(n1, n1 => foldI(n2, n2 => inject(n1 / n2)))
    def modulo(n1: I, n2: I): I = foldI(n1, n1 => foldI(n2, n2 => inject(SchemeOps.modulo(n1, n2))))
    def lt[B : BoolLattice](n1: I, n2: I): B = fold(n1, n1 => fold(n2, n2 => BoolLattice[B].inject(n1 < n2)))
    def eql[B : BoolLattice](n1: I, n2: I): B = fold(n1, n1 => fold(n2, n2 => BoolLattice[B].inject(n1 == n2)))
    def toString[S : StringLattice](n: I): S = fold(n, n => StringLattice[S].inject(n.toString))

    def order(x: I, y: I): Ordering = (x, y) match {
      case (Set(xs), Set(ys)) => implicitly[Order[ISet[Int]]].order(xs, ys)
      case (Top, _: Set) => Ordering.GT
      case (_: Set, Top) => Ordering.LT
      case (Top, Top) => Ordering.EQ
    }
    def cardinality(x: I): Cardinality = x match {
      case Set(xs) => CardinalityPrimitiveLikeNumber(xs.toList.length)
      case Top => CardinalityPrimitiveLikeInf()
    }
  }
}

object Type {
  sealed trait T
  case object Top extends T
  case object Bottom extends T

  implicit val typeIsMonoid = new Monoid[T] {
    def zero: T = Bottom
    def append(x: T, y: => T): T = x match {
      case Top => Top
      case Bottom => y
    }
  }
  abstract class BaseInstance(typeName: String) extends LatticeElement[T] {
    def name = s"Type$typeName"
    override def shows(x: T): String = x match {
      case Top => typeName
      case Bottom => "⊥"
    }
    val bottom: T = Bottom
    val top: T = Top
    def join(x: T, y: => T) = typeIsMonoid.append(x, y)
    def meet(x: T, y: => T): T = x match {
      case Bottom => Bottom
      case Top => y
    }
    def subsumes(x: T, y: => T) = x match {
      case Top => true
      case Bottom => y match {
        case Top => false
        case Bottom => true
      }
    }
    def eql[B : BoolLattice](n1: T, n2: T): B = (n1, n2) match {
      case (Top, Top) => BoolLattice[B].top
      case _ => BoolLattice[B].bottom
    }
    // def order(x: T, y: T): Ordering = implicitly[Order[T]].order(x, y)
    def order(x: T, y: T): Ordering = (x, y) match {
      case (Top, Top) => Ordering.EQ
      case (Top, Bottom) => Ordering.GT
      case (Bottom, Top) => Ordering.LT
      case (Bottom, Bottom) => Ordering.EQ
    }
    def cardinality(x: T): Cardinality = x match {
      case Top => CardinalityInf
      case Bottom => CardinalityPrimitiveLikeNumber(0)
    }
  }
  implicit val typeIsLatticeElement: LatticeElement[T] = new BaseInstance("Type") {
  }
  implicit val typeIsString: StringLattice[T] = new BaseInstance("Str") with StringLattice[T] {
    def inject(x: String): T = Top
    def length[I : IntLattice](s: T) = s match {
      case Top => IntLattice[I].top
      case Bottom => IntLattice[I].bottom
    }
    def append(s1: T, s2: T) = (s1, s2) match {
      case (Bottom, _) => Bottom
      case (_, Bottom) => Bottom
      case (Top, _) => Top
      case (_, Top) => Top
    }
  }
  implicit val typeIsBoolean: BoolLattice[T] = new BaseInstance("Bool") with BoolLattice[T] {
    def inject(x: Boolean): T = Top
    def isTrue(b: T) = b == Top
    def isFalse(b: T) = b == Top
    def not(b: T) = b
    /* TODO: we could redefine cardinality for booleans, as they have max. two
     * values. But it makes sense to keep it as inf, because if it's top we have
     * lost all precision on that boolean */
    /*
    override def cardinality(x: T): Cardinality = x match {
      case Top => CardinalityPrimitiveLikeNumber(2)
      case Bottom => CardinalityPrimitiveLikeNumber(0)
    }*/
  }
  implicit val typeIsInteger: IntLattice[T] = new BaseInstance("Int") with IntLattice[T] {
    def inject(x: Int): T = Top
    def ceiling(n: T): T = n
    def toFloat[F : FloatLattice](n: T): F = n match {
      case Top => FloatLattice[F].top
      case Bottom => FloatLattice[F].bottom
    }
    def random(n: T): T = n
    def plus(n1: T, n2: T): T = meet(n1, n2)
    def minus(n1: T, n2: T): T = meet(n1, n2)
    def times(n1: T, n2: T): T = meet(n1, n2)
    def div(n1: T, n2: T): T = meet(n1, n2)
    def modulo(n1: T, n2: T): T = meet(n1, n2)
    def lt[B : BoolLattice](n1: T, n2: T): B = (n1, n2) match {
      case (Top, Top) => BoolLattice[B].top
      case _ => BoolLattice[B].bottom
    }
    def toString[S : StringLattice](n: T): S = n match {
      case Top => StringLattice[S].top
      case Bottom => StringLattice[S].bottom
    }
  }
  implicit val typeIsFloat: FloatLattice[T] = new BaseInstance("Float") with FloatLattice[T] {
    def inject(x: Float): T = Top
    def ceiling(n: T): T = n
    def log(n: T): T = n
    def random(n: T): T = n
    def plus(n1: T, n2: T): T = meet(n1, n2)
    def minus(n1: T, n2: T): T = meet(n1, n2)
    def times(n1: T, n2: T): T = meet(n1, n2)
    def div(n1: T, n2: T): T = meet(n1, n2)
    def lt[B : BoolLattice](n1: T, n2: T): B = (n1, n2) match {
      case (Top, Top) => BoolLattice[B].top
      case _ => BoolLattice[B].bottom
    }
    def toString[S : StringLattice](n: T): S = n match {
      case Top => StringLattice[S].top
      case Bottom => StringLattice[S].bottom
    }
  }
  implicit val typeIsChar: CharLattice[T] = new BaseInstance("Char") with CharLattice[T] {
    def inject(c: Char): T = Top
  }
  implicit val typeIsSymbol: SymbolLattice[T] = new BaseInstance("Sym") with SymbolLattice[T] {
    def inject(sym: String): T = Top
  }
}

class ConstantPropagation[A](implicit ordering: Order[A]) {
  sealed trait L
  case object Top extends L
  case class Constant(s: A) extends L
  case object Bottom extends L

  implicit val constantIsMonoid = new Monoid[L] {
    def zero: L = Bottom
    def append(x: L, y: => L): L = x match {
      case Top => Top
      case Constant(_) => y match {
        case Top => Top
        case Constant(_) => if (x == y) { x } else { Top }
        case Bottom => x
      }
      case Bottom => y
    }
  }

  abstract class BaseInstance(typeName: String) extends LatticeElement[L] {
    def name = s"ConstantPropagation$typeName"
    override def shows(x: L): String = x match {
      case Top => typeName
      case Constant(x) => x.toString
      case Bottom => "⊥"
    }
    val bottom: L = Bottom
    val top: L = Top
    def join(x: L, y: => L) = constantIsMonoid.append(x, y)
    def meet(x: L, y: => L): L = x match {
      case Bottom => Bottom
      case Constant(_) => y match {
        case Top => x
        case Constant(_) => if (x == y) { x } else { Bottom }
        case Bottom => Bottom
      }
      case Top => y
    }
    def subsumes(x: L, y: => L) = x match {
      case Top => true
      case Constant(_) => y match {
        case Top => false
        case Constant(_) => x == y
        case Bottom => true
      }
      case Bottom => y match {
        case Top => false
        case Constant(_) => false
        case Bottom => true
      }
    }
    def eql[B : BoolLattice](n1: L, n2: L): B = (n1, n2) match {
      case (Top, Top) => BoolLattice[B].top
      case (Top, Constant(_)) => BoolLattice[B].top
      case (Constant(_), Top) => BoolLattice[B].top
      case (Constant(x), Constant(y)) => BoolLattice[B].inject(x == y)
      case (Bottom, _) => BoolLattice[B].bottom
      case (_, Bottom) => BoolLattice[B].bottom
    }
    def order(x: L, y: L): Ordering = (x, y) match {
      case (Top, Top) => Ordering.EQ
      case (Top, _) => Ordering.GT
      case (Constant(_), Top) => Ordering.LT
      case (Constant(x), Constant(y)) => ordering.order(x, y)
      case (Constant(_), Bottom) => Ordering.GT
      case (Bottom, Bottom) => Ordering.EQ
      case (Bottom, _) => Ordering.LT
    }
    def cardinality(x: L): Cardinality = x match {
      case Top => CardinalityInf
      case _: Constant => CardinalityPrimitiveLikeNumber(1)
      case Bottom => CardinalityPrimitiveLikeNumber(0)
    }
  }
}

object StringConstantPropagation extends ConstantPropagation[String] {
  type S = L
  implicit val isString: StringLattice[S] = new BaseInstance("Str") with StringLattice[S] {
    def inject(x: String): S = Constant(x)
    def length[I : IntLattice](s: S) = s match {
      case Top => IntLattice[I].top
      case Constant(s) => IntLattice[I].inject(s.size)
      case Bottom => IntLattice[I].bottom
    }
    def append(s1: S, s2: S) = (s1, s2) match {
      case (Bottom, _) => Bottom
      case (_, Bottom) => Bottom
      case (Top, _) => Top
      case (_, Top) => Top
      case (Constant(x), Constant(y)) => Constant(x ++ y)
    }
  }
}

object IntegerConstantPropagation extends ConstantPropagation[Int] {
  type I = L
  implicit val isInteger: IntLattice[I] = new BaseInstance("Int") with IntLattice[I] {
    def inject(x: Int): I = Constant(x)
    def ceiling(n: I): I = n
    def toFloat[F : FloatLattice](n: I): F = n match {
      case Top => FloatLattice[F].top
      case Constant(x) => FloatLattice[F].inject(x)
      case Bottom => FloatLattice[F].bottom
    }
    def random(n: I): I = n match {
      case Constant(x) => Constant(SchemeOps.random(x))
      case _ => n
    }
    private def binop(op: (Int, Int) => Int, n1: I, n2: I) = (n1, n2) match {
      case (Top, Top) => Top
      case (Top, Constant(_)) => Top
      case (Constant(_), Top) => Top
      case (Constant(x), Constant(y)) => Constant(op(x, y))
      case _ => Bottom
    }
    def plus(n1: I, n2: I): I = binop(_ + _, n1, n2)
    def minus(n1: I, n2: I): I = binop(_ - _, n1, n2)
    def times(n1: I, n2: I): I = binop(_ * _, n1, n2)
    def div(n1: I, n2: I): I = binop(_ / _, n1, n2)
    def modulo(n1: I, n2: I): I = binop(SchemeOps.modulo _, n1, n2)
    def lt[B : BoolLattice](n1: I, n2: I): B = (n1, n2) match {
      case (Top, Top) => BoolLattice[B].top
      case (Top, Constant(_)) => BoolLattice[B].top
      case (Constant(_), Top) => BoolLattice[B].top
      case (Constant(x), Constant(y)) => BoolLattice[B].inject(x < y)
      case _ => BoolLattice[B].bottom
    }
    def toString[S : StringLattice](n: I): S = n match {
      case Top => StringLattice[S].top
      case Constant(x) => StringLattice[S].inject(x.toString)
      case Bottom => StringLattice[S].bottom
    }
  }
}

object FloatConstantPropagation extends ConstantPropagation[Float] {
  type F = L
  implicit val isFloat: FloatLattice[F] = new BaseInstance("Float") with FloatLattice[F] {
    def inject(x: Float) = Constant(x)
    def ceiling(n: F): F = n
    def random(n: F): F = n match {
      case Constant(x) => Constant(SchemeOps.random(x))
      case _ => n
    }
    def log(n: F): F = n match {
      case Constant(x) => Constant(scala.math.log(x.toDouble).toFloat)
      case _ => n
    }
    private def binop(op: (Float, Float) => Float, n1: F, n2: F) = (n1, n2) match {
      case (Top, Top) => Top
      case (Top, Constant(_)) => Top
      case (Constant(_), Top) => Top
      case (Constant(x), Constant(y)) => Constant(op(x, y))
      case _ => Bottom
    }
    def plus(n1: F, n2: F): F = binop(_ + _, n1, n2)
    def minus(n1: F, n2: F): F = binop(_ - _, n1, n2)
    def times(n1: F, n2: F): F = binop(_ * _, n1, n2)
    def div(n1: F, n2: F): F = binop(_ / _, n1, n2)
    def lt[B : BoolLattice](n1: F, n2: F): B = (n1, n2) match {
      case (Top, Top) => BoolLattice[B].top
      case (Top, Constant(_)) => BoolLattice[B].top
      case (Constant(_), Top) => BoolLattice[B].top
      case (Constant(x), Constant(y)) => BoolLattice[B].inject(x < y)
      case _ => BoolLattice[B].bottom
    }
    def toString[S : StringLattice](n: F): S = n match {
      case Top => StringLattice[S].top
      case Constant(x) => StringLattice[S].inject(x.toString)
      case Bottom => StringLattice[S].bottom
    }
  }
}

object CharConstantPropagation extends ConstantPropagation[Char] {
  type C = L
  implicit val isChar: CharLattice[C] = new BaseInstance("Char") with CharLattice[C] {
    def inject(x: Char) = Constant(x)
  }
}

object SymbolConstantPropagation extends ConstantPropagation[String] {
  type Sym = L
  implicit val isSymbol: SymbolLattice[Sym] = new BaseInstance("Sym") with SymbolLattice[Sym] {
    def inject(x: String) = Constant(x)
  }
}
