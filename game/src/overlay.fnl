;; overlay.fnl

(local resources (require :src.resources))
(local love (require :love))
(local lg love.graphics)
(local padding 20)
(local flux (require :lib.flux))

(import-macros {: hex-to-rgb : hex : getgmeta : setgmeta} :macro)

(fn draw [dont-draw]
  (local (w h) (love.window.getMode))
  (local font resources.fonts.text)
  (local message "")
  (local width (font:getWidth message))
  (local height (font:getHeight message))
  (local (x y) (values (- w width (* 2 padding)) (- h height (* 2 padding))))
  (lg.push :all)
  (lg.reset)
  (lg.setFont font)
  (when (not dont-draw)
    (lg.setColor 0 0 0 1)
    (lg.rectangle :fill
                  (- x padding )
                  (- y height 0  )
                  (+ width (* 2 padding))
                  (+ height (* 2 padding)) 10)
    (lg.setColor (hex-to-rgb :7f7f7f))
    (lg.print message x y)    
    )
  (lg.pop))

(macro clone-from-module [module ...]
  ;;((fn [tab] (collect [#key# #value# (pairs #tab#)] (values #key# #value#))))
  `(let [{:clone clone#} (require :lib.lume)]
     (-> ,module (require) (?. ,(unpack [...])) (or []) (clone#))))

(fn window-mid-top-right [font message]
  (local (window-w window-h) (love.window.getMode))
  (local (message-w message-h) (values (font:getWidth message)
                                       (font:getHeight message)))
  (values (-> window-w (- message-w) (/ 2)) (-> window-h (- message-h) (/ 2))
          message-w message-h))

(fn window-upper-top-right [font message]
  (local (window-w window-h) (love.window.getMode))
  (local (message-w message-h) (values (font:getWidth message)
                                       (font:getHeight message)))
  (values (-> window-w (- message-w) (/ 2)) (-> window-h (- message-h) (/ 8))
          message-w message-h))


(local new-day-overlay {})

(fn new-day-overlay.draw [self]
  (local {: font : black : x : y : w : h
          : padding : background : message
          : alpha}
         self)
  (tset black 4 alpha)
  (tset background 4 alpha)
  (lg.push :all)
  (lg.reset)
  (lg.setFont font)
  (lg.setColor background)
  (lg.rectangle :fill
                (- x (* 100 padding))
                (- y padding)
                (+ w (* 2 (* 100 padding)))
                (+ h (* 2 padding)))
  (lg.setColor black)
  (lg.setLineWidth 4)
  (lg.rectangle :line
                (- x (* 100 padding))
                (- y padding)
                (+ w (* 2 (* 100 padding)))
                (+ h (* 2 padding)))
  (lg.print message x (+ y 4))
  (lg.pop))

(fn new-day-overlay.fade-out [self]
  (let [seconds 3
        fade-in-seconds 0.2
        fade-out-seconds 1]
    (pp self.black)
    (local transform (flux.to self fade-in-seconds {:alpha 1}))
    (local transform2 (transform:after self fade-out-seconds {:alpha 0}))
    (transform2:delay seconds)
    self))

(fn make-message [day] (: "Day %s of Operation Gnomic Freedom Dawns" :format day))

(fn new-day-overlay.next [self day]
  (set self.message (make-message day))
  (set self.black (clone-from-module :src.params :colours :text))
  (set self.background (clone-from-module :src.params :colours :background))
  (set (self.x self.y self.w self.h) (window-upper-top-right self.font self.message))
  (set self.alpha 1)
  (self:fade-out))

(setgmeta new-day-overlay new-day-overlay)

(fn new-day-overlay.init [day]
  (local font resources.fonts.text)
  (local message (make-message day))
  (local black (clone-from-module :src.params :colours :text))
  (local background (clone-from-module :src.params :colours :background))
  (local (x y w h) (window-upper-top-right font message))
  (local self
         (setmetatable
          {: font : black : x : y : w : h : padding : background : message
           :alpha 0}
          (getgmeta new-day-overlay)))
  (self:fade-out))

(local transition-draw-down {})

(fn transition-draw-down.draw [self]
  (let [{: percent-height} self
        (width height) (love.window.getMode)]
    (local black (hex :131826))
    (lg.push :all)
    (lg.reset)
    (lg.setColor black)
    (lg.rectangle :fill 0 0 width (* percent-height height))
    (lg.pop)))

(fn transition-draw-down.start [self callback]
  (local seconds 0.6)
  (: (flux.to self seconds {:percent-height 1})
     :oncomplete callback))

(fn transition-draw-down.lift [self callback]
  (local seconds 0.6)
  (: (flux.to self seconds {:percent-height 0})
     :oncomplete callback))

(fn transition-draw-down.reset [self]
  (tset self :percent-height 0))

(setgmeta transition-draw-down transition-draw-down)

(fn transition-draw-down.init []
  (setmetatable {:percent-height 0} (getgmeta transition-draw-down)))

{: draw : new-day-overlay : transition-draw-down}
