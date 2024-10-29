(local love (require :love))

(fn focus-camera-on-unit [unit]
  (let [{: camera : editor} (require :src.state)
        current-unit unit
        (w h) (love.window.getMode)
        s camera.scale]
    (when current-unit
      (let [new-x (- (/ (- w 250 32 32) 2 s) current-unit.x)
            new-y (- (/ (- h 48 48) 2 s) current-unit.y)
            flux (require :lib.flux)]
        (: (flux.to camera 1 {:x new-x :y new-y} 1)
           :oncomplete (fn [] (pp :move-completed)))))))

{: focus-camera-on-unit}
