(local flux (require :lib.flux))

(local colour {:r 0 :g 0 :b 0 :alpha 1})
(local transition-time 0.5)

(fn in [callback]
  (local tween (flux.to colour transition-time {:alpha 0}))
  (when callback (tween:oncomplete callback)))

(fn slowin [callback]
  (tset colour :alpha 1)
  (local tween (flux.to colour 2 {:alpha 0}))
  (when callback (tween:oncomplete callback)))


(fn veryslowin [callback]
  (tset colour :alpha 1)
  (local tween (flux.to colour 5 {:alpha 0}))
  (when callback (tween:oncomplete callback)))


(fn out [callback]
  (local tween (flux.to colour transition-time {:alpha 1}))
  (when callback (tween:oncomplete callback)))

(fn outin [callback]
  (local tween (flux.to colour transition-time {:alpha 1}))
  (when callback (tween:oncomplete callback))
  (tween:after colour transition-time {:alpha 0}))


(fn draw []
  (love.graphics.push :all)
  (love.graphics.setColor colour.r colour.g colour.b colour.alpha)
  (love.graphics.rectangle :fill 0 0 (* 4 1920) (* 4 1080))
  ;; (love.graphics.clear colour.r colour.g colour.b colour.alpha)
  (love.graphics.pop))

{: in : out : draw : outin : slowin : veryslowin}
