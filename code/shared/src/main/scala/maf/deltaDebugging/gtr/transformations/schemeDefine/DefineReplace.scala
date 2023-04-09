package maf.deltaDebugging.gtr.transformations.schemeDefine

import maf.deltaDebugging.gtr.transformations.Transformation
import maf.deltaDebugging.gtr.transformations.schemeDefine.DefineDrop.addTree
import maf.deltaDebugging.gtr.transformations.traits.Replacing
import maf.language.scheme.{SchemeDefineVariable, SchemeExp, SchemeLambdaExp, SchemeVarExp}

object DefineReplace extends Transformation:
  override val name: String = "DefineReplace"

  override protected def transformAndAdd(tree: SchemeExp, node: SchemeExp): Unit =
    node match
      case SchemeDefineVariable(name, value: SchemeLambdaExp, idn) =>
        None
      case definition@SchemeDefineVariable(name, value, idn) =>
        val defDropped = tree.deleteChildren(exp => exp eq definition)
        defDropped match
          case Some(defDroppedTree) =>
            val trees = Replacing.replaceIdWithAllValues(defDroppedTree, name)
            addTrees(trees)
          case _ =>
      case _ =>