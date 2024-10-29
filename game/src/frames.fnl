(local love (require :love))

(local frames {})

;; module local transient state, if this gets replace between frames
;; we are fine. 
(local draw-array [])
(var draw-index 0)
(var draw-array-end 0)
(var event-name nil)
(var event-index nil)
(var event-action nil)
(var event-args nil)
(var event-beep nil)

(fn compile [list mx my]
  (var last-hover-index nil)
  (each [_i frame (ipairs list)]
    (let [(next-draw-index w h next-last-hover-index next-event-name
                           next-event-index next-event-action next-event-args next-event-beep)
          (frame.callbacks.compile frame mx my draw-array draw-index)]
      (set frame.w w)
      (set frame.h h)

      (when next-last-hover-index
        (set last-hover-index next-last-hover-index)
        (set event-name next-event-name)
        (set event-index next-event-index)
        (set event-action next-event-action)
        (set event-args next-event-args)
        (set event-beep next-event-beep))
      (set draw-index next-draw-index)))
  (when last-hover-index
    (love.event.push :mouse-over event-name event-index event-action event-args event-beep)
    (tset draw-array last-hover-index 4 true)
    (local temp (. draw-array last-hover-index 3))
    (tset draw-array last-hover-index 2 temp)
    )
  ;;[ff ft o x y w h r s s]
  (set draw-array-end draw-index)
  (set draw-index 0))

(local transform (love.math.newTransform))
(fn render [draw-array transform]
  (local lg love.graphics)
  (lg.reset) ;; avoid resets for better webgl performance
  ;; add shader to only draw within the bounds of the frame
  ;; (pp :new-frame)
  ;; (pp [(# draw-array) draw-array-end])
  ;; (lg.push :all)
  (for [i 1 (- draw-array-end 0)]
    (let [block (. draw-array i)
          [name fun _ _ x y w h r sx sy ox oy kx ky] block]
      ;; (pp block)      
      (love.graphics.applyTransform (transform:setTransformation x y r sx sy ox oy kx ky))
      (fun x y w h))
    )
  ;; (lg.pop)
  )


(fn frames.update [self dt mx my]
  (local (w h) (love.window.getMode))
  (each [z frame (ipairs self.list)]
    (set frame.z z)
    (set frame.x (math.min frame.x (- w 10)))
    (set frame.y (math.min frame.y (- h 10))))
  (compile self.list mx my))

(fn frames.draw [_self]
  (render draw-array transform))

(fn frames.set-hover [self frame frame-index name args key frame-number]
  (tset self.last-hover :frame-index frame-index)
  (tset self.last-hover :key key)
  (tset self.last-hover :frame frame)
  (tset self.last-hover :name name)
  (tset self.last-hover :args args)
  (tset self.last-hover :frame-number frame-number))

(fn frames.new-hover? [self key]
  (~= self.last-hover.key key))

(fn frames.add [self name x y data active callbacks]
  (table.insert (if active self.list self.inactive)
                {:name name :x x :y y :data data
                 :active active : callbacks :z (if active (+ (# self.list) 1) 0)}))

(fn frames.deactivate [self name]
  (let [index-to-remove []]
    (each [key frame (ipairs self.list)]
      (when (= name (. frame.name))
        (set frame.active false)
        (table.insert self.inactive frame)
        (table.insert index-to-remove key)))
    (each [_ index (ipairs index-to-remove)]
      (table.remove self.list index))))

(fn frames.activate [self name]
  (let [index-to-remove []]
    (each [key frame (ipairs self.inactive)]
      (when (= name (. frame.name))
        (set frame.active true)
        (table.insert self.list frame)
        (set frame.z (# self.list))
        (table.insert index-to-remove key)))
    (each [_ index (ipairs index-to-remove)]
      (table.remove self.inactive index))))

(fn frames.call [self callback-name ...]
  ;;(pp1 [:focus self.focus])
  (when self.focus
        (let [function (?. self.list self.last-hover.frame-index :callbacks callback-name)
              frame (?. self.list self.last-hover.frame-index)
              (mx my) (love.mouse.getPosition)
              within (or (= callback-name :mousemoved) (pointWithin mx my frame.x frame.y (or frame.w 0) (or frame.h 0)))]
          ;; (pp [callback-name within mx my frame.x frame.y frame.w frame.h])
          (when (and  within function) (function self frame ...)))))

(fn frames.bring-frame-to-front [self frame-index]
  (let [frame (. self.list frame-index)]
    (for [i frame-index (- (# self.list) 1)]
      (tset self.list i (. self.list (+ i 1))))
    (tset self.list (# self.list) frame)))

(set frames.header {})

(fn frames.header-mousepressed [self frame x y]
  (set self.ox frame.x)
  (set self.oy frame.y)
  (set self.cx x)
  (set self.cy y)
  )

(fn frames.header-mousereleased [self]
  (set self.ox nil)
  (set self.oy nil)
  (set self.cx nil)
  (set self.cy nil)  )

(fn frames.header-mousemoved [self frame x y]
  (when (and self.ox self.oy)
    (set frame.x (+ self.ox (- x self.cx)))
    (set frame.y (+ self.oy (- y self.cy)))))

(fn frames.set-focus [self value]
  (set self.focus value))

(fn frames.reset-focus [self]
  (set self.focus nil))

(fn frames.init [mouse]  
  (setmetatable
   {:list []
    :inactive []
    :focus nil
    : mouse
    :last-hover {:key nil :frame nil :name nil :args nil :frame-index nil}}
   {:__index (require :src.frames)}))

frames
