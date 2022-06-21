package maf.util

object FunctionUtils:
    /**
     * Adds the "after" operator so that it runs function composition. Example <code>extract after eval</code> first runs eval and then extract on the
     * output of eval
     */
    extension [A, C](f: C => A)
        def after[B](g: B => C): B => A = (b) => f(g(b))
        def andThen[B](g: A => B): C => B = (c) => g(f(c))

    def fix[T](init: T)(f: T => T): T =
        def loop(prev: T): T =
            val next = f(prev)
            if next == prev then next else loop(next)

        loop(init)
