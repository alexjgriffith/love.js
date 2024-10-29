;; https://github.com/love2d/love/blob/2deb6273c2588c7dd008daed7f15a627d8b880e4/src/modules/math/Transform.cpp#L37

(fn rotate [x y a]
    (local {: sin : cos} math)
    (values (- (* x (cos a)) (* y (sin a))) (+ (* x (sin a)) (* y (cos a)))))

(fn scale [x y sx sy]
  (values (* x sx) (* y sy)))

(fn create [] {})

;; TRS
(fn point-rotation [angle
                    sprite-ox sprite-oy
                    pivot-x pivot-y
                    bb-ox bb-oy
                    sprite-x sprite-y
                    sx? sy? flip-h? flip-v? _sprite_kx _sprite_ky]
  (let [nx (- bb-ox pivot-x)
        ny (- bb-oy pivot-y)
        (bb-xr bb-yr) (rotate nx ny (* (or flip-h? 1) angle))
        (bb-xrs bb-yrs) (scale bb-xr bb-yr (* (or sx? 1) (or flip-h? 1)) (* (or sy? sx? 1) (or flip-v? 1)))
        bb-xro (+ bb-xrs sprite-x (* (or flip-h? 1) sprite-ox))
        bb-yro (+ bb-yrs sprite-y (* (or flip-v? 1) sprite-oy))]
    (values bb-xro bb-yro)))

{: point-rotation}
