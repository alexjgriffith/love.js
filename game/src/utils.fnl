(fn deep-clone [table depth? d?]
    (let [d (or d? 1)
          depth (or depth? 1)
          ret []]
      (each [key value (pairs table)]
        (tset ret key (match (type value)
                        :table (if (< d depth) (deep-clone value depth (+ d 1)) value)
                         _ value)))
      ret))

(fn within-gen []
  (local within-last-frame {})
  
  (var mouse-pressed false)
  (fn [no-update?]
    (local signal (require :lib.signal))
    (local (mx my) (love.mouse.getPosition))
    (local mouse-down (love.mouse.isDown [1 2]))
    (when (not mouse-down) (set mouse-pressed false))
    (local click? (if (and mouse-down (not mouse-pressed)) (do (set mouse-pressed true) true) false ))
    (local update (not no-update?))
  (fn [x y w h pass? fail? trigger-fun? click-fun?]
    (let [(tmx tmy) (love.graphics.inverseTransformPoint mx my)
          (tx ty) (love.graphics.transformPoint x y)
          key (string.format "%s,%s,%s,%s" tx ty w h)
          t (. within-last-frame key)
          o (and update (pointWithin tmx tmy x y w h))
          click (and o click?)
          ]
      
      (when o (tset within-last-frame key true))
      (when (not o) (tset within-last-frame key false))
      (when (and o (not t)) (signal.emit :hover))
      (when click (signal.emit :click))
      (values o (and o (not t)) click
              (if o (when pass? (pass?)) (when fail? (fail?)))
              (when (and (and o (not t)) trigger-fun?) (trigger-fun?))
              (when (and click click-fun?) (click-fun?)))))))

;; FUCK LUA 5.1 PUC
(local format
       (if (not _G.jit)
         (fn [layout ...]
          (string.format
           (unpack (icollect [_ v (ipairs [...])]
                     (tostring v)))))
         string.format))

(local random
       (if (not _G.jit)
           (fn [low? high?]
             (let [h (math.modf (or high? low? 1))
                   (l fl) (math.modf (if high? 1 low?))]
               (match low?
                 nil (math.random)
                 _ (+ (math.random l h) fl))))
           math.random))

{: deep-clone : within-gen : random : format}
