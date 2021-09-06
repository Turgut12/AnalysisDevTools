package maf.util.datastructures

/**
 * When using `s1 ++ s2` with the default Scala Set implementation, it can be significantly more efficient to use `s2 ++ s1` if s1 is smaller than s2
 */
object SmartUnion:
  def sunion[A <: B, B](s1: Set[A], s2: Set[B]): Set[B] = if s1.size < s2.size then s2 ++ s1 else s1 ++ s2
  def sunionList[A](s: List[Set[A]]): Set[A] = s.foldLeft(Set.empty)(sunion)

object SmartAppend:
  def sappend[E](l1: List[E], l2: List[E]): List[E] = if l1.size < l2.size then l1 ::: l2 else l2 ::: l1
