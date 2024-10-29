(macro incf [x] `(do (set ,x (+ ,x 1)) ,x))
(macro incfb [x b] `(do (set ,x (+ ,x 1)) (when (> ,x ,b) (set ,x 1)) ,x))
(macro set1 [x] `(do (set ,x 1) ,x))

(local _mt {})

(fn parse-map [map]
  (let [hex-to-dec
      {:0 0 :1 1 :2 2 :3 3 :4 4 :5 5 :6 6 :7 7 :8 8
       :9 9 :A 10 :B 11 :C 12 :D 13 :E 14 :F 15}
      state {:step 1 :image-index 1 :x 1 :y 1}
      tiles []]
  (each [char (string.gmatch map "(.)")]
    (let [valid-char (. hex-to-dec char)]
      (when valid-char
        (match state.step
          1 (tset state :image-index valid-char)
          2 (tset state :x valid-char)
          3 (do (tset state :y valid-char)
                (table.insert tiles {:image-index (+ 1 state.image-index)
                                     :quad-index (+ 1 state.x (* state.y 16))})))
        (incfb state.step 3)
        )))
  tiles))

(fn make-quad-list-16x16 [pw x? y? iw? ih?]
  (let [w (* pw 4) h (* pw 4)
        x (or x? 0) y (or y? 0)
        iw (or iw? w) ih (or ih? h)
        tab {}]
    (for [row 1 16]
      (for [col 1 16]
        (let [xo (+ x (* pw (- col 1)))
              yo (+ y (* pw (- row 1)))]
          (table.insert tab (love.graphics.newQuad xo yo pw pw iw ih)))))
    tab))

;; slow but it will get the job done
(fn draw-basic [self]
  (local {: parsed-map : x : y : images : quad-lists : map-width : tile-width : map-width} self)
  (local lg love.graphics)
  (lg.push :all)
  (lg.translate x y)
  (each [index {: image-index : quad-index} (ipairs parsed-map)]
    (local image (. images image-index))
    (local quad (. quad-lists image-index quad-index))
    (local (x y) (values (* tile-width (% (- index 1) map-width))
                         (* tile-width (math.floor (/ (- index 1) map-width)))))
    (lg.draw image quad x y))
  (lg.pop))

(tset _mt :__index {:draw draw-basic})

(fn new [raw-map image map-width tile-width]
  (local (iw ih) (image:getDimensions))
  (local m {:x 0
            :y 0
            :tile-width tile-width
            :map-width map-width
            :raw-map raw-map
            :parsed-map (parse-map raw-map)
            :images [image]
            :quad-lists [(make-quad-list-16x16 tile-width 0 0 iw ih)]})
  (setmetatable m _mt)
  m)

{: new}
