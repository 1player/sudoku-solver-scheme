(use (srfi 1))

(define sudoku '())

(define CANDIDATES (list #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9))

(define (intersperse-every n l x)
  (let loop ((i n)
             (l l)
             (result '()))
    (cond ((null? l) (reverse result))
          ((zero? i) (loop n l (cons x result)))
          (else (loop (- i 1) (cdr l) (cons (car l) result))))))

(define (skip-missing l)
  (let loop ((result '())
             (l l))
    (cond ((null? l) (reverse result))
          ((equal? #\space (car l)) (loop result (cdr l)))
          (else (loop (cons (car l) result) (cdr l))))))

(define (read-sudoku fp)
    (define (loop fp sudoku)
      (define c (read-char fp))
      (cond ((eof-object? c) '())
            ((equal? c #\newline) (reverse sudoku))
            ((equal? c #\0) (loop fp (cons #\space sudoku)))
            (else (loop fp (cons c sudoku)))))
    (list->vector (loop fp '())))

(define (sudoku-row n sudoku)
  (let loop ((i (* n 9))
             (count 9)
             (row '()))
    (if (zero? count)
        (reverse row)
        (loop (+ i 1) (- count 1) (cons (vector-ref sudoku i) row)))))

(define (sudoku-col n sudoku)
  (let loop ((i n)
             (count 9)
             (col '()))
    (if (zero? count)
        (reverse col)
        (loop (+ i 9) (- count 1) (cons (vector-ref sudoku i) col)))))

(define (sudoku-quadrant n sudoku)
  (define q (quotient n 3))
  (define r (remainder n 3))
  (define x (+ (* 3 r) (* (* 9 3) q)))
  (let loop ((i x)
             (row-count 3)
             (col-count 3)
             (result '()))
    (cond ((zero? row-count)
           (reverse result))
          ((zero? col-count)
           (loop (+ i 6) (- row-count 1) 3 result))
          (else
            (loop (+ i 1) row-count (- col-count 1) (cons (vector-ref sudoku i) result))))))

(define (quadrant-of x y)
  (+ (* 3 (quotient y 3)) (quotient x 3)))

(define (pos-of x y)
  (+ (* y 9) x))

(define (coords-of i)
  (cons (remainder i 9) (quotient i 9)))

(define (has-value? x y sudoku)
  (let* ((pos (pos-of x y))
        (c (vector-ref sudoku pos)))
    (not (eq? #\space c))))

(define (candidates x y sudoku)
  (define pos (pos-of x y))
  (define cur (vector-ref sudoku pos))
  (if (has-value? x y sudoku)
      (list cur)
      (begin
        (define in-row (sudoku-row y sudoku))
        (define in-col (sudoku-col x sudoku))
        (define in-quadrant (sudoku-quadrant (quadrant-of x y) sudoku))
        (lset-difference eq? CANDIDATES in-col in-row in-quadrant))))

(define (missing-positions sudoku)
  (let loop ((i 0)
             (count (* 9 9))
             (missing '()))
    (define coords (coords-of i))
    (define x (car coords))
    (define y (cdr coords))
    (cond ((zero? count) (reverse missing))
          ((has-value? x y sudoku) (loop (+ i 1) (- count 1) missing))
          (else (loop (+ i 1) (- count 1) (cons coords missing))))))

(define (solve sudoku)
  (let loop ((empties (missing-positions sudoku)))
    (if (null? empties)
        (begin
          (display "."))
        (begin
          (define empti (car empties))
          (define x (car empti))
          (define y (cdr empti))
          (define possible (candidates x y sudoku))
          (if (null? (cdr possible))
              (begin
                (define i (pos-of x y))
                (vector-set! sudoku i (car possible))
                (loop (missing-positions sudoku)))
              (loop (cdr empties)))))))

(define (display-sudoku sudoku)
  (define (display-row n sudoku)
    (display "|")
    (display (list->string (intersperse-every 3 (sudoku-row n sudoku) #\|)))
    (display "|")
    (newline))
  (define (loop n)
    (define i (* n 3))
    (display "+---+---+---+\n")
    (display-row (+ i 0) sudoku)
    (display-row (+ i 1) sudoku)
    (display-row (+ i 2) sudoku))
  (loop 0)
  (loop 1)
  (loop 2)
  (display "+---+---+---+\n"))

(define (solve-sudokus fp)
  (set! sudoku (read-sudoku fp))
  (if (not (zero? (vector-length sudoku)))
      (begin
        (solve sudoku)
        (solve-sudokus fp))
      (display "Nothing to do.\n")))

(call-with-input-file "0.txt" solve-sudokus)