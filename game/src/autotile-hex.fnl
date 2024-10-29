;; autotlie-hex.fnl

;; Libraries
(local love (require :love))
(local {: newQuad : newCanvas : newImage : push : pop : draw
        : newShader : setShader : setCanvas : setColor : rectangle} love.graphics)

;; Module Locals
(local (w h) (values 32 48))

(local default-mask-rects
       [[0 0 32 48 0 0] [1 0 32 48 0 0] [2 0 32 48 0 0] [3 0 32 48 0 0] [4 0 32 48 0 0] [5 0 32 48 0 0]
        [0 0 32 48 0 0] [1 0 32 48 0 0] [2 0 32 48 0 0] [3 0 32 48 0 0] [4 0 32 48 0 0] [5 0 32 48 0 0]
        [0 1 64 64 -40 -16] [1 1 64 64 -16 -31] [2 1 64 64 8 -16] [3 1 64 64 8 14] [4 1 64 64 -16 29] [5 1 64 64 -40 14]
        [0 2 64 64 -40 14] [1 2 64 64 -40 -16] [2 2 64 64 -16 -31] [3 2 64 64 8 -16] [4 2 64 64 8 14] [5 2 64 64 -16 29]])

(local water-auto-input
       {:name :water
        :image-filename :/assets/sprites/HexAutoTileDesign.png
        :tile-mask-rects default-mask-rects
        :tile-source-rects [[0 4 32 48] [1 4 32 48] [1 3 64 64] [1 3 64 64]]
        :canvas-w (* w 6)
        :canvas-h (* h 4)})

(local water2-auto-input
       {:name :water
        :image-filename :/assets/sprites/HexAutoTileDesign.png
        :tile-mask-rects default-mask-rects
        :tile-source-rects [[4 4 32 48] [5 4 32 48] [3 3 64 64] [3 3 64 64]]
        :canvas-w (* w 6)
        :canvas-h (* h 4)})

(local outline-auto-input
       {:name :water
        :image-filename :/assets/sprites/HexAutoTileDesign.png
        :tile-mask-rects default-mask-rects
        :tile-source-rects [[8 4 32 48] [9 4 32 48] [5 3 64 64] [5 3 64 64]]
        :canvas-w (* w 6)
        :canvas-h (* h 4)})


(local outline2-auto-input
       {:name :water
        :image-filename :/assets/sprites/HexAutoTileDesign.png
        :tile-mask-rects default-mask-rects
        :tile-source-rects [[0 6 32 48] [1 6 32 48] [1 4 64 64] [1 4 64 64]]
        :canvas-w (* w 6)
        :canvas-h (* h 4)})

(local mask-shader (newShader "/assets/shaders/mask.glsl"))

;; Internal Functions
(fn new-quad [i j tw th iw ih]
  (let [x (* (- i 0) tw)
        y (* (- j 0) th)]
    (newQuad x y tw th iw ih)))

(fn new-quads [array iw ih extend?]
  (collect [name [i j tw th] (pairs array) &into (or extend? [])]
    (values name (new-quad i j tw th iw ih))))

(fn make-auto-tile [{: name : image-filename : tile-mask-rects : tile-source-rects : canvas-w : canvas-h}]
  (local canvas (newCanvas canvas-w canvas-h))
  (local image (newImage image-filename))
  (local (iw ih) (image:getDimensions))
  (local mask-quads (new-quads tile-mask-rects iw ih))
  (local source-quads (new-quads tile-source-rects iw ih))
  (local quads (new-quads (fcollect [i 1 (* 6 4)] [(% (- i 1) 6) (math.floor (/ (- i 1) 6)) w h]) canvas-w canvas-h))
  (push :all)
  (setCanvas canvas)
  (setColor 1 1 1 1)

  (setShader mask-shader)
  (mask-shader:send :mask_image image)
  (mask-shader:send :size [iw ih])
  (for [index 1 (* 6 4)]
    (let [i (% (- index 1) 6)
          j (math.floor (/ (- index 1) 6))
          [_ _ _ _ ox oy] (. tile-mask-rects index)
          mask-quad (. mask-quads index)
          source-quad (. source-quads (+ j 1))
          ]
      (mask-shader:send :mask_quad [(mask-quad:getViewport)])
      (mask-shader:send :source_quad [(source-quad:getViewport)])
      ;; (local a 0.5)
      ;; (local colours [[1 1 0 a] [1 0 1 a] [0 1 1 a] [1 0 0 a] [0 1 0 a] [0 0 1 a]])
      ;; (setColor (. colours (+ i 1)))
      (draw image source-quad
            (+ (* w i) ox)
            (+ (* h j) oy))
      )
    )
  (setCanvas)
  (pop)
  (local tile-canvas (newCanvas (* w (^ 2 6)) h))
  (push)
  (setCanvas tile-canvas)
  ;; comb
  ;; (for [i 0 15] (print (string.format "%s %s %s %s" (bool i 1) (bool i 2) (bool i 3) (bool i 4))))
  (local floor math.floor)
  (fn bool-value [bin index len]
    (fn bool [j i] (% (-> (/ j (^ 2 (- i 1))) (floor)) 2))
    (let [i (if (< index 1) (+ len index)
                (> index len) (+ (% (- index 1) len) 1)
                index)]
      (= (bool bin i) 1)))
  (local viewport-quad (newQuad 0 0 w h canvas-w canvas-h))
  (fcollect [index 0 (- (^ 2 6) 1)]
    (for [i 1 6]
      (let [j (match (values (bool-value index i 6) (bool-value index (- i 1) 6))
                (false false) 1
                (true false) 3 ;; these may be swapped
                (false true) 4
                (true true) 2
                )]
        (viewport-quad:setViewport (* w (- i 1)) (* h (- j 1)) w h)
        (draw canvas viewport-quad (* w (- index 0)) 0)
        )
      )
      )
  (setCanvas)
  (pop)
  {: name :image tile-canvas : quads}
  )

{:water (fn [] (make-auto-tile water-auto-input))
 :water2 (fn [] (make-auto-tile water2-auto-input))
 :outline (fn [] (make-auto-tile outline-auto-input))
 :outline2 (fn [] (make-auto-tile outline2-auto-input))}
