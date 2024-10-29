(local state (require :src.state))

(local unit (require :src.unit))

(fn enter [_s _f]
  (tset state :units (fcollect [i 1 40] (unit.create {:name (. [:small-goblin :medium-goblin :large-goblin :orc :gnome1 :gnome2 :gnome3 :gnome4 :gnome5 :gnome6 :gnome7 :gnome8 :gnome9] (math.random 13)) :team (math.random 4) :stars (math.random 4) :id i } (- (math.random 300) 20) (- (math.random 200) 30))))
  (local (h w) (love.window.getMode))
  (tset state :hover-canvas (love.graphics.newCanvas (/ h 8) (/ w 8)))
  )

(local unit-shader (love.graphics.newShader :assets/shaders/unit.glsl))


(fn update [_s dt]
  (table.sort state.units (fn [a b] (< (+ a.y a.sort-oy a.h) (+ b.y b.sort-oy b.h)))))

(fn draw [_s ]
  (local lg love.graphics)
  (lg.push :all)
  (lg.reset)
  (lg.setCanvas state.hover-canvas)
  (lg.clear 0 0 0 0)
  (lg.setColor 1 1 1 1)
  (lg.setShader unit-shader)
  (lg.scale 0.5)
  (each [key unit (ipairs state.units)]
    (unit-shader:send :id (/ unit.id 256))
    (unit:draw)
    )
  (lg.setCanvas)
  (lg.pop)
  (local (mx my) (love.mouse.getPosition))
  (local hover-canvas-data (state.hover-canvas:newImageData))
  (local id (math.floor (* 256 (hover-canvas-data:getPixel (math.floor (/ mx 8)) (math.floor (/ my 8))))))

  (lg.clear 1 1 0 1)
  (lg.setColor 1 1 1 1)
  (lg.push :all)
  ;; (lg.draw state.hover-canvas)
  (lg.scale 4)
  (lg.setColor 1 1 1 1)
  (each [k unit (ipairs state.units)]
    (unit:draw)
    (when (= id unit.id) (unit:outline)))  
  (lg.pop)

  (lg.setColor 0 0 0 1)
  (lg.print id 10 10)
  (lg.print (love.timer.getFPS) 10 30)
  )


{: update : enter : draw}
