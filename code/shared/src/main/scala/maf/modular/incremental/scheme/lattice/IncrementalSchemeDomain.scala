package maf.modular.incremental.scheme.lattice

import maf.core._
import maf.language.scheme.SchemeExp
import maf.language.scheme.primitives.{SchemeLatticePrimitives, SchemePrimitives}
import maf.lattice.{ConstantPropagation, Type}
import maf.modular.AbstractDomain
import maf.modular.incremental.scheme.modconc.IncrementalSchemeLattice
import maf.modular.scheme._

// TODO: put declarations in correct place (wrapper).
trait IncrementalAbstractDomain[Expr <: Expression] extends AbstractDomain[Expr] {
  def clean(v: Value): Value
  def addAddress(v: Value, source: Address): Value = addAddresses(v, Set(source))
  def addAddresses(v: Value, sources: Set[Address]): Value
}

trait IncrementalSchemeDomain extends IncrementalAbstractDomain[SchemeExp] with SchemeDomain {
  implicit override val lattice: IncrementalSchemeLattice[Value, Address]
}

trait IncrementalModularSchemeDomain extends IncrementalSchemeDomain {
  val modularLatticeWrapper: IncrementalModularSchemeLatticeWrapper
  type Value = modularLatticeWrapper.modularLattice.AL
  lazy val lattice = modularLatticeWrapper.modularLattice.incrementalSchemeLattice
  lazy val primitives = modularLatticeWrapper.primitives
}

trait IncrementalModularSchemeLatticeWrapper {
  type S
  type B
  type I
  type R
  type C
  type Sym
  val modularLattice: IncrementalModularSchemeLattice[Address, S, B, I, R, C, Sym]
  val primitives: SchemePrimitives[modularLattice.AL, Address]
}

object IncrementalSchemeTypeDomain extends IncrementalModularSchemeLatticeWrapper {
  type S = Type.S
  type B = ConstantPropagation.B
  type I = Type.I
  type R = Type.R
  type C = Type.C
  type Sym = Type.Sym
  lazy val modularLattice = new IncrementalModularSchemeLattice
  lazy val primitives = new SchemeLatticePrimitives()(modularLattice.incrementalSchemeLattice)
}

trait IncrementalSchemeTypeDomain extends IncrementalModularSchemeDomain {
  lazy val modularLatticeWrapper = IncrementalSchemeTypeDomain
}

object IncrementalSchemeConstantPropagationDomain extends IncrementalModularSchemeLatticeWrapper {
  type S = ConstantPropagation.S
  type B = ConstantPropagation.B
  type I = ConstantPropagation.I
  type R = ConstantPropagation.R
  type C = ConstantPropagation.C
  type Sym = ConstantPropagation.Sym
  lazy val modularLattice = new IncrementalModularSchemeLattice
  lazy val primitives = new SchemeLatticePrimitives()(modularLattice.incrementalSchemeLattice)
}

trait IncrementalSchemeConstantPropagationDomain extends IncrementalModularSchemeDomain {
  lazy val modularLatticeWrapper = IncrementalSchemeConstantPropagationDomain
}
