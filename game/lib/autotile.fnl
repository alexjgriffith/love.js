(local autotile {})

(tset autotile :bitmap-3x3-simple
"
000 000 000 000
010 011 111 110
010 01_ _1_ _10

010 01_ _1_ _10
010 011 111 110
010 01_ _1_ _10

010 01_ _1_ _10
010 011 111 110
000 000 000 000

000 000 000 000
010 011 111 110
000 000 000 000
")

(tset autotile :bitmap-3x3-simple-alt
"
_0_ _0_ _0_ _0_
010 011 111 110
_1_ _1_ _1_ _1_

_1_ _1_ _1_ _1_
010 011 111 110
_1_ _1_ _1_ _1_

_1_ _1_ _1_ _1_
010 011 111 110
_0_ _0_ _0_ _0_

_0_ _0_ _0_ _0_
010 011 111 110
_0_ _0_ _0_ _0_
")

(tset autotile :bitmap-2x2
"
_0_ _11 110 _0_
110 011 111 111
11_ _11 111 111

110 011 1_1 111
111 111 _1_ 111
011 111 1_1 110

_11 111 111 11_
011 111 111 110
_0_ _0_ 011 11_

000 _0_ 011 11_
010 011 111 110
000 _11 110 _0_
")

(tset autotile :bitmap-1
"
___
_1_
___
")

(fn n [t i w d]
  (fn check [t i oy ox d]
    (local row (math.floor (/ (+ i oy -1) w)))
    (local index (+ i oy ox))
    (local index-row (math.floor (/ (- index 1) w)))
    (if (and (= index-row row) (. t index))
        (. t index)
        d))
  [(check t i (- w) -1 d) ;; tl
   (check t i (- w) 0  d) ;; t
   (check t i (- w) 1  d) ;; tr
   (check t i 0 1 d)      ;; r
   (check t i w 1 d)      ;; br
   (check t i w 0  d)     ;; b
   (check t i w -1 d)     ;; bl
   (check t i 0 -1 d)])   ;; l

;; (fn f-n [t i w d]  
;;   (let [r [(. t i)]
;;         t2 (n t i w d)]
;;     (each [k v (ipairs t2)]
;;       (table.insert r  v))
;;     r))

(fn autotile.parse-bitmap [text w]
  (let [l (length text)
        t []
        t2 []
        t3 []]
    (for [i 1 l]
      (match (string.sub text i (+ i 0))
        "\n" :skip
        " " :skip
        tile (table.insert t tile)))
    (for [i 1 (length t)]
      (when (and (= 1 (% (math.floor (/ i (* 3 w))) 3))
                 (= 2 (% (math.floor (% i (* 3 w))) 3)))
        (table.insert t2 (n t i (* 3 w) "_"))))
    (each [i list (ipairs t2)]
      (let [r [0]]
        (fn increment-r [k]
          (each [i v (ipairs r)]
            (tset r i (+ v (^ 2 k)))))
        (fn expand-r [k]
          (local l (length r))
          (for [i 1 l]
            (local v (. r i))
            (tset r i (+ v (^ 2 k)))
            (table.insert r v)))
        (each [k l (ipairs list)]
          (match l
            :0 :nil
            :1 (increment-r (- k 1))
            :_  (expand-r (- k 1))))
        (each [_ v (ipairs r)]
          (tset t3 v i))))
    t3))


(fn autotile.match-key-fast [map width bitmap]
  (let [t []
        height (math.floor (/ (# map) width))
        w (- width 0)
        h (- height 1)]
    (for [r 0 h]
      (for [c 1 w]
        ;; there are a lot of branches in this inner loop, is there
        ;; a way to speed this up?
        (local ch (. map (+ 0 (+ c 0) (* (+ r 0) w))))
        (var j 0)
        ;; tl
        (if (or (= r 0) (= c 1)
                (= ch (. map (+ 0 (+ c -1) (* (+ r -1) w)))))
            (set j (+ j (^ 2 0))))
        ;; t
        (if (or (= r 0)
                (= ch (. map (+ 0 (+ c 0) (* (+ r -1) w)))))
            (set j (+ j (^ 2 1))))
        ;; tr
        (if (or (= r 0) (= c w)
                (= ch (. map (+ 0 (+ c 1) (* (+ r -1) w)))))
            (set j (+ j (^ 2 2)))
            )
        ;; r
        (if (or (= c w)
                (= ch (. map (+ 0 (+ c 1) (* (+ r 0) w)))))
            (set j (+ j (^ 2 3)))
            )
        ;; br
        (if (or (= r h) (= c w)
                (= ch (. map (+ 0 (+ c 1) (* (+ r 1) w)))))
            (set j (+ j (^ 2 4)))
            )
        ;; b
        (if (or (= r h)
                (= ch (. map (+ 0 (+ c 0) (* (+ r 1) w)))))
            (set j (+ j (^ 2 5)))
            )
        ;; bl
        (if (or (= r h) (= c 1)
                (= ch (. map (+ 0 (+ c -1) (* (+ r 1) w)))))
            (set j (+ j (^ 2 6)))
            )
        ;; l
        (if (or (= c 1)
                (= ch (. map (+ 0 (+ c -1) (* (+ r 0) w)))))
            (set j (+ j (^ 2 7)))
            )
        (table.insert t (match ch
                          1  (or (. bitmap  j) 13)
                          0 (+ 1 12))) ;; blank autotile slot
        ))
    t))

autotile
