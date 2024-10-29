;; Title: Grid
;; Author: AlexJGriffith
;; Description: A simple 2d grid data structure
;; Licence: MIT

;; Example
;; (let [g (grid.new 10 10)
;;       output []]
;;  check the value of the grid at 1,1
;;  (g 1 1)
;;  set the value of the grid at 1,1
;;  (g 1 1 2)
;;  Get the values of the grid between 2,2 and 4,4
;;  (g (fn [value x y data index] [value x y]) output  [2 2 4 4])
;;  Set the values between  2,2 and 4,4
;;  (g (fn [value x y data index] (tset data index 5)) nil [2 2 4 4]))

(local grid {})

;; 0,0 grid start point
(fn xy->index [x y w]
  (+ 1 x (* w y)))

(fn index->xy [index w]
  (values (% (- index 1) w) (-> index (- 1) (/ w) (math.floor))))

(set grid._xy->index (fn [g x y default?]
                       (if default?
                           (if (or (< x 0) (> x g.w) (< y 0) (> y g.h)) default?
                               (xy->index x y g.w)
                               )
                           (xy->index x y g.w))))

(set grid._index->xy (fn [g index] (index->xy index g.w)))

(fn rep [value len]
  (fcollect [i 1 len] value))

(fn grid.__fennelview [g]
  (local t (type (. g.data 1)))
  (var ret (string.format "#<GRID: %sx%s of %s>" g.w g.h t))
  ;; (when (or (not (= t :table))
  ;;           (not (= t :function))
  ;;           (not (= t :userdata)))
  ;;   (each [index value (ipairs g.data)]
  ;;     (set ret (.. ret value))
  ;;     (when (= 0 (% index g.w))
  ;;       (set ret (.. ret "\n"))))
  ;;  )
  ret)

(fn grid.apply-region [g fun out-table limit]
  (let [[x y w h] limit]
    (for [i x w]
      (for [j y h]
        (let [index (xy->index i j g.w)
              value (. g.data index)]
          (let [result (fun value i j g.data index)]
            (when out-table (tset out-table index result))))))
    (when out-table out-table)))

(fn grid.apply [g fun out-table]
  (each [key value (ipairs g.data)]
    (let [(x y) (index->xy key g.w)]
      (let [result (fun value x y g.data key)]
        (when out-table (tset out-table key result)))))
  (when out-table out-table))

(fn grid.get [g x y]
  (. g :data (xy->index x y g.w)))

(fn grid.get-clamp [g x y ox? oy?]
  (. g :data (xy->index (-> x (+ (or ox? 0)) (math.max 0) (math.min (- g.w 1)))
                        (-> y (+ (or oy? 0)) (math.max 0) (math.min (- g.h 1))) g.w)))

(fn grid.set [g x y v]
  (when (and (>= x 0) (>= y 0) (< x g.w) (< y g.w))
    (tset g :data (xy->index x y g.w) v)))

(fn grid.__call [g x|fun y|out-table? v?|limit?]
  (match (type x|fun)
    :function (if v?|limit?
                  (let [fun x|fun
                        out-table y|out-table?
                        limit v?|limit?]
                    (grid.apply-region g fun out-table limit))
                  (let [fun x|fun
                        out-table y|out-table?]
                    (grid.apply-region g fun out-table)))
    :number (let [x x|fun
                  y y|out-table?
                  v? v?|limit?]
              (when v?
                (grid.set g x y v?))
              (grid.get g x y))))

(fn grid.neighbors [g x y]
  (+ 1 (* 1 (g:get-clamp x y -1 -1))
     (* 2 (g:get-clamp x y 0 -1))
     (* 4 (g:get-clamp x y 1 -1))
     (* 8 (g:get-clamp x y 1 0))
     (* 16 (g:get-clamp x y 1 1))
     (* 32 (g:get-clamp x y 0 1))
     (* 64 (g:get-clamp x y -1 1))
     (* 128 (g:get-clamp x y -1 0))
     (* 256 (g:get-clamp x y 0 0))))

(fn grid.new [width height initial-data?]
  (setmetatable {:w width :h height :data (or initial-data? (rep 0 (* width height)))}
                {:__index grid :__fennelview grid.__fennelview :__call grid.__call}))

grid
