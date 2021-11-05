; Changes:
; * removed: 3
; * added: 7
; * swaps: 4
; * negated predicates: 0
; * swapped branches: 0
; * calls to id fun: 8
(letrec ((foldr (lambda (f base lst)
                  (letrec ((foldr-aux (lambda (lst)
                                        (if (null? lst)
                                           base
                                           (f (car lst) (foldr-aux (cdr lst)))))))
                     (foldr-aux lst))))
         (result ())
         (display2 (lambda (i)
                     (set! result (cons i result))))
         (newline2 (lambda ()
                     (set! result (cons 'newline result))))
         (error2 (lambda (e)
                   (set! result (cons (list 'error e) result))))
         (maak-buffer (lambda ()
                        (<change>
                           (let ((inhoud ()))
                              (letrec ((newValue (lambda (value)
                                                   (set! inhoud (append inhoud (list value)))))
                                       (returnSum (lambda ()
                                                    (foldr + 0 inhoud)))
                                       (flush (lambda ()
                                                (set! inhoud ())))
                                       (value (lambda (pos)
                                                (list-ref inhoud pos)))
                                       (dispatch (lambda (msg)
                                                   (if (eq? msg 'newValue)
                                                      newValue
                                                      (if (eq? msg 'return)
                                                         inhoud
                                                         (if (eq? msg 'returnSum)
                                                            (returnSum)
                                                            (if (eq? msg 'flush)
                                                               (flush)
                                                               (if (eq? msg 'value)
                                                                  value
                                                                  (if (eq? msg 'size)
                                                                     (length inhoud)
                                                                     (error "wrong message"))))))))))
                                 dispatch))
                           ((lambda (x) x)
                              (let ((inhoud ()))
                                 (letrec ((newValue (lambda (value)
                                                      (set! inhoud (append inhoud (list value)))))
                                          (returnSum (lambda ()
                                                       (foldr + 0 inhoud)))
                                          (flush (lambda ()
                                                   (set! inhoud ())))
                                          (value (lambda (pos)
                                                   (list-ref inhoud pos)))
                                          (dispatch (lambda (msg)
                                                      (if (eq? msg 'newValue)
                                                         newValue
                                                         (if (eq? msg 'return)
                                                            inhoud
                                                            (if (eq? msg 'returnSum)
                                                               (returnSum)
                                                               (if (eq? msg 'flush)
                                                                  (flush)
                                                                  (if (eq? msg 'value)
                                                                     value
                                                                     (if (eq? msg 'size)
                                                                        (length inhoud)
                                                                        (error "wrong message"))))))))))
                                    dispatch))))))
         (buffer (maak-buffer)))
   (<change>
      ((buffer 'newValue) 3)
      ((lambda (x) x) ((buffer 'newValue) 3)))
   ((buffer 'newValue) 9)
   (letrec ((res1 (if (= (buffer 'returnSum) 12)
                    (if (equal? (buffer 'return) (__toplevel_cons 3 (__toplevel_cons 9 ())))
                       (if (begin (buffer 'flush))
                          (null? (buffer 'return))
                          #f)
                       #f)
                    #f))
            (make-counter (lambda ()
                            (<change>
                               (let ((state 0))
                                  (letrec ((increment (lambda ()
                                                        (set! state (+ state 1))))
                                           (read (lambda ()
                                                   state))
                                           (reset (lambda ()
                                                    (set! state 0)))
                                           (dispatch (lambda (msg)
                                                       (if (eq? msg 'increment)
                                                          (increment)
                                                          (if (eq? msg 'read)
                                                             (read)
                                                             (if (eq? msg 'reset)
                                                                (reset)
                                                                (error "wrong message")))))))
                                     dispatch))
                               ((lambda (x) x)
                                  (let ((state 0))
                                     (letrec ((increment (lambda ()
                                                           (set! state (+ state 1))))
                                              (read (lambda ()
                                                      (<change>
                                                         state
                                                         ((lambda (x) x) state))))
                                              (reset (lambda ()
                                                       (set! state 0)))
                                              (dispatch (lambda (msg)
                                                          (if (eq? msg 'increment)
                                                             (increment)
                                                             (if (eq? msg 'read)
                                                                (read)
                                                                (if (eq? msg 'reset)
                                                                   (reset)
                                                                   (error "wrong message")))))))
                                        dispatch))))))
            (maak-verkeersteller (lambda ()
                                   (let ((voorbijgereden (make-counter))
                                         (buffer (maak-buffer)))
                                      (<change>
                                         ()
                                         (display
                                            (lambda (start end)
                                               ((lambda (x) x)
                                                  (if (= start end)
                                                     (newline)
                                                     (begin
                                                        (display2 "Tussen ")
                                                        (display2 start)
                                                        (display2 " en ")
                                                        +
                                                        'value
                                                        (display2 " uur : ")
                                                        (display2 "Tussen ")
                                                        ((lambda (x) x) (display2 ((buffer 'value) start)))
                                                        (display2 " auto's")
                                                        (newline2)
                                                        ((lambda (x) x) (loop (+ start 1) end))))))))
                                      (letrec ((newCar (lambda ()
                                                         (voorbijgereden 'increment)))
                                               (newHour (lambda ()
                                                          ((buffer 'newValue) (voorbijgereden 'read))
                                                          (voorbijgereden 'reset)))
                                               (newDay (lambda ()
                                                         (letrec ((loop (lambda (start end)
                                                                          (if (= start end)
                                                                             (newline)
                                                                             (begin
                                                                                (display2 "Tussen ")
                                                                                (display2 start)
                                                                                (display2 " en ")
                                                                                (display2 (+ start 1))
                                                                                (display2 " uur : ")
                                                                                (display2 ((buffer 'value) start))
                                                                                (display2 " auto's")
                                                                                (newline2)
                                                                                (loop (+ start 1) end))))))
                                                            (if (= (buffer 'size) 24)
                                                               (begin
                                                                  (loop 0 24)
                                                                  (buffer 'flush)
                                                                  (voorbijgereden 'reset))
                                                               (error2 "no 24 hours have passed")))))
                                               (dispatch (lambda (msg)
                                                           (if (eq? msg 'newCar)
                                                              (newCar)
                                                              (if (eq? msg 'newHour)
                                                                 (newHour)
                                                                 (if (eq? msg 'newDay)
                                                                    (newDay)
                                                                    (error2 "wrong message")))))))
                                         dispatch))))
            (verkeersteller (maak-verkeersteller)))
      (verkeersteller 'newCar)
      (verkeersteller 'newCar)
      (<change>
         ()
         (__toplevel_cons
            "Tussen "
            (__toplevel_cons
               'newline
               (__toplevel_cons
                  " auto's"
                  (__toplevel_cons
                     0
                     (__toplevel_cons
                        " uur : "
                        (__toplevel_cons
                           12
                           (__toplevel_cons
                              " en "
                              (__toplevel_cons
                                 11
                                 (__toplevel_cons
                                    "Tussen "
                                    (__toplevel_cons
                                       'newline
                                       (__toplevel_cons
                                          " auto's"
                                          (__toplevel_cons
                                             1
                                             (__toplevel_cons
                                                " uur : "
                                                (__toplevel_cons
                                                   11
                                                   (__toplevel_cons
                                                      " en "
                                                      (__toplevel_cons
                                                         10
                                                         (__toplevel_cons
                                                            "Tussen "
                                                            (__toplevel_cons
                                                               'newline
                                                               (__toplevel_cons
                                                                  " auto's"
                                                                  (__toplevel_cons
                                                                     2
                                                                     (__toplevel_cons
                                                                        " uur : "
                                                                        (__toplevel_cons
                                                                           10
                                                                           (__toplevel_cons
                                                                              " en "
                                                                              (__toplevel_cons
                                                                                 9
                                                                                 (__toplevel_cons
                                                                                    "Tussen "
                                                                                    (__toplevel_cons
                                                                                       'newline
                                                                                       (__toplevel_cons
                                                                                          " auto's"
                                                                                          (__toplevel_cons
                                                                                             2
                                                                                             (__toplevel_cons
                                                                                                " uur : "
                                                                                                (__toplevel_cons
                                                                                                   9
                                                                                                   (__toplevel_cons
                                                                                                      " en "
                                                                                                      (__toplevel_cons
                                                                                                         8
                                                                                                         (__toplevel_cons
                                                                                                            "Tussen "
                                                                                                            (__toplevel_cons
                                                                                                               'newline
                                                                                                               (__toplevel_cons
                                                                                                                  " auto's"
                                                                                                                  (__toplevel_cons
                                                                                                                     0
                                                                                                                     (__toplevel_cons
                                                                                                                        " uur : "
                                                                                                                        (__toplevel_cons
                                                                                                                           8
                                                                                                                           (__toplevel_cons
                                                                                                                              " en "
                                                                                                                              (__toplevel_cons
                                                                                                                                 7
                                                                                                                                 (__toplevel_cons
                                                                                                                                    "Tussen "
                                                                                                                                    (__toplevel_cons
                                                                                                                                       'newline
                                                                                                                                       (__toplevel_cons
                                                                                                                                          " auto's"
                                                                                                                                          (__toplevel_cons
                                                                                                                                             0
                                                                                                                                             (__toplevel_cons
                                                                                                                                                " uur : "
                                                                                                                                                (__toplevel_cons
                                                                                                                                                   7
                                                                                                                                                   (__toplevel_cons
                                                                                                                                                      " en "
                                                                                                                                                      (__toplevel_cons
                                                                                                                                                         6
                                                                                                                                                         (__toplevel_cons
                                                                                                                                                            "Tussen "
                                                                                                                                                            (__toplevel_cons
                                                                                                                                                               'newline
                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                  " auto's"
                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                     1
                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                        " uur : "
                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                           6
                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                              " en "
                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                 5
                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                       'newline
                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                          " auto's"
                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                             0
                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                   5
                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                      " en "
                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                         4
                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                            (__toplevel_cons
                                                                                                                                                                                                               'newline
                                                                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                                                                  " auto's"
                                                                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                                                                     0
                                                                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                                                                        " uur : "
                                                                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                                                                           4
                                                                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                                                                              " en "
                                                                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                                                                 3
                                                                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                                                                       'newline
                                                                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                                                                          " auto's"
                                                                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                                                                             3
                                                                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                                                                   3
                                                                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                                                                      " en "
                                                                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                                                                         2
                                                                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                                                                            (__toplevel_cons
                                                                                                                                                                                                                                                               'newline
                                                                                                                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                                                                                                                  " auto's"
                                                                                                                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                                                                                                                     0
                                                                                                                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                                                                                                                        " uur : "
                                                                                                                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                                                                                                                           2
                                                                                                                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                                                                                                                              " en "
                                                                                                                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                                                                                                                 1
                                                                                                                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                                                                                                                       'newline
                                                                                                                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                                                                                                                          " auto's"
                                                                                                                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                                                                                                                             2
                                                                                                                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                                                                                                                   1
                                                                                                                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                                                                                                                      " en "
                                                                                                                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                                                                                                                         0
                                                                                                                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                                                                                                                            (__toplevel_cons (__toplevel_cons 'error2 (__toplevel_cons "no 24 hours have passed" ())) ())))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))
      (verkeersteller 'newHour)
      (<change>
         (verkeersteller 'newHour)
         (verkeersteller 'newCar))
      (<change>
         (verkeersteller 'newCar)
         (verkeersteller 'newHour))
      (verkeersteller 'newCar)
      (verkeersteller 'newCar)
      (verkeersteller 'newHour)
      (verkeersteller 'newHour)
      (<change>
         ()
         __toplevel_cons)
      (verkeersteller 'newHour)
      (verkeersteller 'newCar)
      (verkeersteller 'newHour)
      (verkeersteller 'newHour)
      (verkeersteller 'newHour)
      (<change>
         (verkeersteller 'newCar)
         ())
      (<change>
         (verkeersteller 'newCar)
         (verkeersteller 'newHour))
      (<change>
         (verkeersteller 'newHour)
         (verkeersteller 'newCar))
      (verkeersteller 'newCar)
      (<change>
         (verkeersteller 'newCar)
         ((lambda (x) x) (verkeersteller 'newCar)))
      (<change>
         ()
         (__toplevel_cons
            " auto's"
            (__toplevel_cons
               0
               (__toplevel_cons
                  " uur : "
                  (__toplevel_cons
                     8
                     (__toplevel_cons
                        " en "
                        (__toplevel_cons
                           7
                           (__toplevel_cons
                              "Tussen "
                              (__toplevel_cons
                                 'newline
                                 (__toplevel_cons
                                    " auto's"
                                    (__toplevel_cons
                                       0
                                       (__toplevel_cons
                                          " uur : "
                                          (__toplevel_cons
                                             7
                                             (__toplevel_cons
                                                " en "
                                                (__toplevel_cons
                                                   6
                                                   (__toplevel_cons
                                                      "Tussen "
                                                      (__toplevel_cons
                                                         'newline
                                                         (__toplevel_cons
                                                            " auto's"
                                                            (__toplevel_cons
                                                               1
                                                               (__toplevel_cons
                                                                  " uur : "
                                                                  (__toplevel_cons
                                                                     6
                                                                     (__toplevel_cons
                                                                        " en "
                                                                        (__toplevel_cons
                                                                           5
                                                                           (__toplevel_cons
                                                                              "Tussen "
                                                                              (__toplevel_cons
                                                                                 'newline
                                                                                 (__toplevel_cons
                                                                                    " auto's"
                                                                                    (__toplevel_cons
                                                                                       0
                                                                                       (__toplevel_cons
                                                                                          " uur : "
                                                                                          (__toplevel_cons
                                                                                             5
                                                                                             (__toplevel_cons
                                                                                                " en "
                                                                                                (__toplevel_cons
                                                                                                   4
                                                                                                   (__toplevel_cons
                                                                                                      "Tussen "
                                                                                                      (__toplevel_cons
                                                                                                         'newline
                                                                                                         (__toplevel_cons
                                                                                                            " auto's"
                                                                                                            (__toplevel_cons
                                                                                                               0
                                                                                                               (__toplevel_cons
                                                                                                                  " uur : "
                                                                                                                  (__toplevel_cons
                                                                                                                     4
                                                                                                                     (__toplevel_cons
                                                                                                                        " en "
                                                                                                                        (__toplevel_cons
                                                                                                                           3
                                                                                                                           (__toplevel_cons
                                                                                                                              "Tussen "
                                                                                                                              (__toplevel_cons
                                                                                                                                 'newline
                                                                                                                                 (__toplevel_cons
                                                                                                                                    " auto's"
                                                                                                                                    (__toplevel_cons
                                                                                                                                       3
                                                                                                                                       (__toplevel_cons
                                                                                                                                          " uur : "
                                                                                                                                          (__toplevel_cons
                                                                                                                                             3
                                                                                                                                             (__toplevel_cons
                                                                                                                                                " en "
                                                                                                                                                (__toplevel_cons
                                                                                                                                                   2
                                                                                                                                                   (__toplevel_cons
                                                                                                                                                      "Tussen "
                                                                                                                                                      (__toplevel_cons
                                                                                                                                                         'newline
                                                                                                                                                         (__toplevel_cons
                                                                                                                                                            " auto's"
                                                                                                                                                            (__toplevel_cons
                                                                                                                                                               0
                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                  " uur : "
                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                     2
                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                        " en "
                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                           1
                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                              "Tussen "
                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                 'newline
                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                    " auto's"
                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                       2
                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                          " uur : "
                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                             1
                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                " en "
                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                   0
                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                      "Tussen "
                                                                                                                                                                                                      (__toplevel_cons (__toplevel_cons 'error2 (__toplevel_cons "no 24 hours have passed" ())) ())))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))
      (verkeersteller 'newHour)
      (verkeersteller 'newCar)
      (verkeersteller 'newHour)
      (verkeersteller 'newHour)
      (verkeersteller 'newHour)
      (verkeersteller 'newHour)
      (verkeersteller 'newCar)
      (verkeersteller 'newHour)
      (verkeersteller 'newCar)
      (<change>
         (verkeersteller 'newHour)
         (verkeersteller 'newHour))
      (<change>
         (verkeersteller 'newHour)
         (verkeersteller 'newHour))
      (verkeersteller 'newCar)
      (verkeersteller 'newHour)
      (verkeersteller 'newHour)
      (verkeersteller 'newCar)
      (verkeersteller 'newHour)
      (verkeersteller 'newHour)
      (verkeersteller 'newCar)
      (<change>
         (verkeersteller 'newCar)
         ())
      (verkeersteller 'newHour)
      (verkeersteller 'newCar)
      (verkeersteller 'newHour)
      (verkeersteller 'newCar)
      (verkeersteller 'newDay)
      (<change>
         (verkeersteller 'newHour)
         (verkeersteller 'newDay))
      (<change>
         (verkeersteller 'newDay)
         (verkeersteller 'newHour))
      (equal?
         result
         (__toplevel_cons
            'newline
            (__toplevel_cons
               'newline
               (__toplevel_cons
                  " auto's"
                  (__toplevel_cons
                     1
                     (__toplevel_cons
                        " uur : "
                        (__toplevel_cons
                           24
                           (__toplevel_cons
                              " en "
                              (__toplevel_cons
                                 23
                                 (__toplevel_cons
                                    "Tussen "
                                    (__toplevel_cons
                                       'newline
                                       (__toplevel_cons
                                          " auto's"
                                          (__toplevel_cons
                                             1
                                             (__toplevel_cons
                                                " uur : "
                                                (__toplevel_cons
                                                   23
                                                   (__toplevel_cons
                                                      " en "
                                                      (__toplevel_cons
                                                         22
                                                         (__toplevel_cons
                                                            "Tussen "
                                                            (__toplevel_cons
                                                               'newline
                                                               (__toplevel_cons
                                                                  " auto's"
                                                                  (__toplevel_cons
                                                                     2
                                                                     (__toplevel_cons
                                                                        " uur : "
                                                                        (__toplevel_cons
                                                                           22
                                                                           (__toplevel_cons
                                                                              " en "
                                                                              (__toplevel_cons
                                                                                 21
                                                                                 (__toplevel_cons
                                                                                    "Tussen "
                                                                                    (__toplevel_cons
                                                                                       'newline
                                                                                       (__toplevel_cons
                                                                                          " auto's"
                                                                                          (__toplevel_cons
                                                                                             0
                                                                                             (__toplevel_cons
                                                                                                " uur : "
                                                                                                (__toplevel_cons
                                                                                                   21
                                                                                                   (__toplevel_cons
                                                                                                      " en "
                                                                                                      (__toplevel_cons
                                                                                                         20
                                                                                                         (__toplevel_cons
                                                                                                            "Tussen "
                                                                                                            (__toplevel_cons
                                                                                                               'newline
                                                                                                               (__toplevel_cons
                                                                                                                  " auto's"
                                                                                                                  (__toplevel_cons
                                                                                                                     1
                                                                                                                     (__toplevel_cons
                                                                                                                        " uur : "
                                                                                                                        (__toplevel_cons
                                                                                                                           20
                                                                                                                           (__toplevel_cons
                                                                                                                              " en "
                                                                                                                              (__toplevel_cons
                                                                                                                                 19
                                                                                                                                 (__toplevel_cons
                                                                                                                                    "Tussen "
                                                                                                                                    (__toplevel_cons
                                                                                                                                       'newline
                                                                                                                                       (__toplevel_cons
                                                                                                                                          " auto's"
                                                                                                                                          (__toplevel_cons
                                                                                                                                             0
                                                                                                                                             (__toplevel_cons
                                                                                                                                                " uur : "
                                                                                                                                                (__toplevel_cons
                                                                                                                                                   19
                                                                                                                                                   (__toplevel_cons
                                                                                                                                                      " en "
                                                                                                                                                      (__toplevel_cons
                                                                                                                                                         18
                                                                                                                                                         (__toplevel_cons
                                                                                                                                                            "Tussen "
                                                                                                                                                            (__toplevel_cons
                                                                                                                                                               'newline
                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                  " auto's"
                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                     1
                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                        " uur : "
                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                           18
                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                              " en "
                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                 17
                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                       'newline
                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                          " auto's"
                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                             0
                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                   17
                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                      " en "
                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                         16
                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                            (__toplevel_cons
                                                                                                                                                                                                               'newline
                                                                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                                                                  " auto's"
                                                                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                                                                     1
                                                                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                                                                        " uur : "
                                                                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                                                                           16
                                                                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                                                                              " en "
                                                                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                                                                 15
                                                                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                                                                       'newline
                                                                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                                                                          " auto's"
                                                                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                                                                             1
                                                                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                                                                   15
                                                                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                                                                      " en "
                                                                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                                                                         14
                                                                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                                                                            (__toplevel_cons
                                                                                                                                                                                                                                                               'newline
                                                                                                                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                                                                                                                  " auto's"
                                                                                                                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                                                                                                                     0
                                                                                                                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                                                                                                                        " uur : "
                                                                                                                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                                                                                                                           14
                                                                                                                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                                                                                                                              " en "
                                                                                                                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                                                                                                                 13
                                                                                                                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                                                                                                                       'newline
                                                                                                                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                                                                                                                          " auto's"
                                                                                                                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                                                                                                                             0
                                                                                                                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                                                                                                                   13
                                                                                                                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                                                                                                                      " en "
                                                                                                                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                                                                                                                         12
                                                                                                                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                                                                                                                            (__toplevel_cons
                                                                                                                                                                                                                                                                                                               'newline
                                                                                                                                                                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                                                                                                                                                                  " auto's"
                                                                                                                                                                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                                                                                                                                                                     0
                                                                                                                                                                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                                                                                                                                                                        " uur : "
                                                                                                                                                                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                                                                                                                                                                           12
                                                                                                                                                                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                                                                                                                                                                              " en "
                                                                                                                                                                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                 11
                                                                                                                                                                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                       'newline
                                                                                                                                                                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                          " auto's"
                                                                                                                                                                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                             1
                                                                                                                                                                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                   11
                                                                                                                                                                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                      " en "
                                                                                                                                                                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                         10
                                                                                                                                                                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                                                                                                                                                                            (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                               'newline
                                                                                                                                                                                                                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                  " auto's"
                                                                                                                                                                                                                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                     2
                                                                                                                                                                                                                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                        " uur : "
                                                                                                                                                                                                                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                           10
                                                                                                                                                                                                                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                              " en "
                                                                                                                                                                                                                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                 9
                                                                                                                                                                                                                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                                                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                       'newline
                                                                                                                                                                                                                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                          " auto's"
                                                                                                                                                                                                                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                             2
                                                                                                                                                                                                                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                   9
                                                                                                                                                                                                                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                      " en "
                                                                                                                                                                                                                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                         8
                                                                                                                                                                                                                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                                                                                                                                                                                                                            (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                               'newline
                                                                                                                                                                                                                                                                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                  " auto's"
                                                                                                                                                                                                                                                                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                     0
                                                                                                                                                                                                                                                                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                        " uur : "
                                                                                                                                                                                                                                                                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                           8
                                                                                                                                                                                                                                                                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                              " en "
                                                                                                                                                                                                                                                                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                 7
                                                                                                                                                                                                                                                                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                                                                                                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                       'newline
                                                                                                                                                                                                                                                                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                          " auto's"
                                                                                                                                                                                                                                                                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                             0
                                                                                                                                                                                                                                                                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                                                                                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                   7
                                                                                                                                                                                                                                                                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                      " en "
                                                                                                                                                                                                                                                                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                         6
                                                                                                                                                                                                                                                                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                                                                                                                                                                                                                                                                            (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                               'newline
                                                                                                                                                                                                                                                                                                                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  " auto's"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     1
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                        " uur : "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                           6
                                                                                                                                                                                                                                                                                                                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              " en "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 5
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       'newline
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          " auto's"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   5
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      " en "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         4
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               'newline
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  " auto's"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        " uur : "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           4
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              " en "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 3
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       'newline
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          " auto's"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             3
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   3
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      " en "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         2
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               'newline
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  " auto's"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        " uur : "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           2
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              " en "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 1
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    "Tussen "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       'newline
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          " auto's"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             2
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                " uur : "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   1
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      " en "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         (__toplevel_cons
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            "Tussen "
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            (__toplevel_cons (__toplevel_cons 'error2 (__toplevel_cons "no 24 hours have passed" ())) ())))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))