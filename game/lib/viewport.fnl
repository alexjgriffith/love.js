(local max-ratio (/ 36 10))
;; (local max-ratio (/ 16 9))
;;(local base-height 720)
(local base-height 1080)
(local base-scale 4)
(local (w h) (values (* max-ratio base-height) base-height))
(local canvas (love.graphics.newCanvas w h))
(local viewportTransform (love.math.newTransform 0 0))
(local renderTransform (love.math.newTransform 0 0))
(local debugWindowTransform (love.math.newTransform 0 0))
(var gsw w)
(var gsh h)

(set _G.debug-viewport false)
;; handle default window ratio 16 / 9 or 4 / 3offset
;; so windows that are wider than this simply grow outwards
(fn draw [callback]
  (local lg love.graphics)
  (lg.setCanvas canvas)
  (lg.clear 1 1 1 1)
  (lg.applyTransform viewportTransform)
  (callback)
  (lg.reset)
  (lg.setCanvas canvas)
  (lg.applyTransform renderTransform)
  (lg.setCanvas)
  (lg.draw canvas)
  (when _G.debug-viewport
    (lg.push :all)
    (lg.reset)
    (lg.scale 0.1)
    (lg.draw canvas)
    (lg.applyTransform debugWindowTransform)
    (lg.setColor 1 1 0 1)
    (lg.rectangle :line 5 5 (- gsw 10) (- gsh 10))  
    (lg.pop)))

(fn resize [sw sh]
  (local s (/ sh h))
  (set gsw sw)
  (set gsh sh)
  (local ratio (/ sw sh))
  (local canvas-width w)
  (local window-width (* ratio base-height))
  (local view-width sw)
  (local x (/ (- (math.max window-width canvas-width) (math.min window-width canvas-width)) 2))  
  (when _G.debug-viewport
    (pp [:resize-viewport s w h sw sh max-ratio base-height ratio canvas-width window-width x]))
  (viewportTransform:setTransformation x 0 0 1 1)
  (renderTransform:setTransformation (* s (- x)) 0 0  s s)
  (debugWindowTransform:setTransformation x 0 0 (/ 1 s) (/ 1 s)))

(fn init []
  (local (sw sh) (love.window.getMode))
  (resize sw sh))

(fn mouse-pos []
  (local (mx my) (love.mouse.getPosition))
  (viewportTransform:inverseTransformPoint (renderTransform:inverseTransformPoint mx my)))

(fn inverse-transform-point [mx my]
  (viewportTransform:inverseTransformPoint (renderTransform:inverseTransformPoint mx my)))

(fn transform-point [mx my]
  (viewportTransform:transformPoint (renderTransform:transformPoint mx my)))

(fn update [])

{: draw : update : resize : init : mouse-pos : inverse-transform-point : transform-point}
