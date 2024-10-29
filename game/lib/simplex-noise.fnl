(fn make-simplex-noise [radius? harmonics? width? height?]
  "Generate 2d tiling simplex noise tile.
The generated tile will be saved in the user save directory.
radius? The radius of the x and y orthogonal circles in 4 d space. Larger radius ~= higher frequency
harmonics? How many harmonics do you want to include? Default 3
width? The width of the tile generated
height? The height the tile generated
example: (make-simplex-noise 10)"
  (let [r (or radius? 10)
        n (or harmonics? 3)
        w (or width? 256)
        h (or height? width? 256)
        amplitude-decay 0.5
        radius-increase 2
        off-x (/ (math.random 1 100000) 100000)
        off-y (/ (math.random 1 100000) 100000)
        lg love.graphics
        canvas (lg.newCanvas w h)
        data (canvas:newImageData)]
    (fn cliffords-torus-mapping [r j i w h off-x? off-y?]
      (let [x1 (+ off-x (- r))
            off-x (or off-x? 0)
            off-y (or off-y? 0)
            x2 (+ off-x (+ r))
            y1 (+ off-y (- r))
            y2 (+ off-y (+ r))
            s (/ j w)
            t (/ i h)
            dx (- x2 x1)
            dy (- y2 y1)
            nx (+ x1 (* (/ dx (* 2 math.pi)) (math.cos (* s 2 math.pi) ))) 
            ny (+ y1 (* (/ dy (* 2 math.pi)) (math.cos (* t 2 math.pi) ))) 
            nz (+ x1 (* (/ dx (* 2 math.pi)) (math.sin (* s 2 math.pi) ))) 
            nw (+ y1 (* (/ dy (* 2 math.pi)) (math.sin (* t 2 math.pi) )))
            r (love.math.noise nx ny nz nw)]
        r))
    (for [i 1 h]
      (for [j 1 w]
        (var value 0)
        (var amplitude 1)
        (var radius r)
        (for [harmonic 1 n]
          (local rand (cliffords-torus-mapping radius j i w h off-x off-y))
          (set value  (+ value (* amplitude rand)))
          (set radius (* radius radius-increase))
          (set amplitude (* amplitude amplitude-decay)))
        (set value (* 1.75 (/ value n)))
        (data:setPixel (- i 1) (- j 1) value value value 1)))
    (data:encode "png" (.. "simplex-noise-r=" r "h=" n ".png"))))


(fn noise-array [radius width]
  (let [r radius
        n 1
        w width
        amplitude-decay 0.5
        radius-increase 2
        off-x (/ (math.random 1 100000) 100000)
        off-y (/ (math.random 1 100000) 100000)
        lg love.graphics
        ret []]
    (fn index-circle [radius index count off-x off-y]
      (let [step (/ (* 2 math.pi) count)
            angle (* step (- index 1))
            dx (* radius (math.cos angle))
            dy (* radius (math.sin angle))
            x (+ off-x dx)
            y (+ off-y dy)]
        (love.math.noise x y)))
    (for [i 1 w]      
      (var value 0)
      (var amplitude 1)
      (var radius r)
        (for [harmonic 1 n]
          (local rand (index-circle radius i w off-x off-y))
          (set value  (+ value (* amplitude rand)))
          (set radius (* radius radius-increase))
          (set amplitude (* amplitude amplitude-decay)))
        (set value (* 1 (/ value n)))
        (table.insert ret value))
    ret))

{: make-simplex-noise : noise-array}
