; Changes:
; * removed: 2
; * added: 1
; * swaps: 0
; * negated predicates: 3
; * swapped branches: 3
; * calls to id fun: 2
(letrec ((apply-append (lambda (args)
                         (if (null? args)
                            ()
                            (if (null? (cdr args))
                               (<change>
                                  (car args)
                                  (if (not (null? (cddr args)))
                                     (append (car args) (cadr args))
                                     (if (null? (cdddr args))
                                        (append (car args) (append (cadr args) (caddr args)))
                                        (error "apply-append" args))))
                               (<change>
                                  (if (null? (cddr args))
                                     (append (car args) (cadr args))
                                     (if (null? (cdddr args))
                                        (append (car args) (append (cadr args) (caddr args)))
                                        (error "apply-append" args)))
                                  (car args))))))
         (lexico (lambda (base)
                   (letrec ((lex-fixed (lambda (fixed lhs rhs)
                                         (letrec ((check (lambda (lhs rhs)
                                                           (if (null? lhs)
                                                              fixed
                                                              (let ((probe (base (car lhs) (car rhs))))
                                                                 (if (let ((__or_res (eq? probe 'equal))) (if __or_res __or_res (eq? probe fixed)))
                                                                    (check (cdr lhs) (cdr rhs))
                                                                    'uncomparable))))))
                                            (check lhs rhs))))
                            (lex-first (lambda (lhs rhs)
                                         (if (null? lhs)
                                            'equal
                                            (let ((probe (base (car lhs) (car rhs))))
                                               (if (let ((__or_res (eq? probe 'less))) (if __or_res (<change> __or_res (eq? probe 'more)) (<change> (eq? probe 'more) __or_res)))
                                                  (lex-fixed probe (cdr lhs) (cdr rhs))
                                                  (if (eq? probe 'equal)
                                                     (lex-first (cdr lhs) (cdr rhs))
                                                     (if (<change> (eq? probe 'uncomparable) (not (eq? probe 'uncomparable)))
                                                        'uncomparable
                                                        #f))))))))
                      lex-first)))
         (make-lattice (lambda (elem-list cmp-func)
                         (cons elem-list cmp-func)))
         (lattice->elements car)
         (lattice->cmp cdr)
         (zulu-select (lambda (test lst)
                        (letrec ((select-a (lambda (ac lst)
                                             (if (null? lst)
                                                (reverse! ac)
                                                (select-a
                                                   (let ((head (car lst)))
                                                      (if (test head)
                                                         (<change>
                                                            (cons head ac)
                                                            ac)
                                                         (<change>
                                                            ac
                                                            (cons head ac))))
                                                   (cdr lst))))))
                           (select-a () lst))))
         (reverse! (letrec ((rotate (lambda (fo fum)
                                     (let ((next (cdr fo)))
                                        (<change>
                                           (set-cdr! fo fum)
                                           ())
                                        (if (null? next) fo (rotate next fo))))))
                     (lambda (lst)
                        (if (null? lst) () (rotate lst ())))))
         (select-map (lambda (test func lst)
                       (letrec ((select-a (lambda (ac lst)
                                            (if (<change> (null? lst) (not (null? lst)))
                                               (reverse! ac)
                                               (select-a (let ((head (car lst))) (if (test head) (cons (func head) ac) ac)) (cdr lst))))))
                          (select-a () lst))))
         (map-and (lambda (proc lst)
                    (if (null? lst)
                       #t
                       (letrec ((drudge (lambda (lst)
                                          (let ((rest (cdr lst)))
                                             (if (null? rest)
                                                (proc (car lst))
                                                (if (proc (car lst)) (drudge rest) #f))))))
                          (drudge lst)))))
         (maps-1 (lambda (source target pas new)
                   (let ((scmp (lattice->cmp source))
                         (tcmp (lattice->cmp target)))
                      (let ((less (select-map (lambda (p) (eq? 'less (scmp (car p) new))) cdr pas))
                            (more (select-map (lambda (p) (eq? 'more (scmp (car p) new))) cdr pas)))
                         (zulu-select
                            (lambda (t)
                               (if (map-and (lambda (t2) (memq (tcmp t2 t) (__toplevel_cons 'less (__toplevel_cons 'equal ())))) less)
                                  (map-and
                                     (lambda (t2)
                                        (<change>
                                           ()
                                           (__toplevel_cons 'more (__toplevel_cons 'equal ())))
                                        (memq (tcmp t2 t) (__toplevel_cons 'more (__toplevel_cons 'equal ()))))
                                     more)
                                  #f))
                            (lattice->elements target))))))
         (maps-rest (lambda (source target pas rest to-1 to-collect)
                      (if (null? rest)
                         (to-1 pas)
                         (let ((next (car rest))
                               (rest (cdr rest)))
                            (<change>
                               (to-collect
                                  (map
                                     (lambda (x)
                                        (maps-rest source target (cons (cons next x) pas) rest to-1 to-collect))
                                     (maps-1 source target pas next)))
                               ((lambda (x) x)
                                  (to-collect
                                     (map
                                        (lambda (x)
                                           (maps-rest source target (cons (cons next x) pas) rest to-1 to-collect))
                                        (maps-1 source target pas next)))))))))
         (maps (lambda (source target)
                 (make-lattice
                    (maps-rest
                       source
                       target
                       ()
                       (lattice->elements source)
                       (lambda (x)
                          (list (map cdr x)))
                       (lambda (x)
                          (apply-append x)))
                    (lexico (lattice->cmp target)))))
         (count-maps (lambda (source target)
                       (maps-rest source target () (lattice->elements source) (lambda (x) 1) sum)))
         (sum (lambda (lst)
                (if (null? lst) 0 (+ (car lst) (sum (cdr lst))))))
         (run (lambda ()
                (let* ((l2 (make-lattice
                             (__toplevel_cons 'low (__toplevel_cons 'high ()))
                             (lambda (lhs rhs)
                                (if (eq? lhs 'low)
                                   (if (eq? rhs 'low)
                                      'equal
                                      (if (eq? rhs 'high)
                                         'less
                                         (error "make-lattice base")))
                                   (if (eq? lhs 'high)
                                      (if (eq? rhs 'low)
                                         'more
                                         (if (eq? rhs 'high)
                                            'equal
                                            (error "make-lattice base")))
                                      (error "make-lattice base"))))))
                       (l3 (maps l2 l2))
                       (l4 (maps l3 l3)))
                   (<change>
                      (count-maps l2 l2)
                      ())
                   (count-maps l3 l3)
                   (count-maps l2 l3)
                   (count-maps l3 l2)
                   (count-maps l4 l4)))))
   (<change>
      (= (run) 120549)
      ((lambda (x) x) (= (run) 120549))))