(local gamestate (require :lib.gamestate))
(local sounds (require :src.sounds))
(local pallet (require :src.pallet))
(local resources (require :src.resources))
(local fade (require :lib.fade))
(local overlay (require :src.overlay))
(local params (require :src.params))

(local text-width 600)
(var colour [1 1 1 1])
(var background [0 0 0 1])

(fn enter [self _previous]
  (fade.slowin))

(fn update [self dt])

(fn draw-title []
  (local lg love.graphics)
  (local (w h) (love.window.getMode))
  (lg.clear background)
  (lg.push :all)
  (lg.setColor 1 1 1 1)
  (lg.setFont resources.fonts.title)
  (lg.printf "Frozen Horizon II" 0 (- (/ h 2) 300) w :center)
  (lg.printf "Gnomic Vengeance" 0 (- (/ h 2) 240) w :center)
  (lg.setFont resources.fonts.subtitle)
  (lg.printf "2024 Spring Lisp Game Jam" 0 (- (/ h 2) 100) w :center)
  (lg.printf "[CLICK]" 0 (+ (/ h 2) 30) w :center)
  (lg.printf "Game By: AlexJGriffith" 0 (+ (/ h 2) 230) w :center)
  (lg.pop)
  )

(fn draw [self]
  (draw-title)
  (overlay.draw)
  (fade.draw)
  )

(fn action []
  (do (sounds.hurt) (fade.outin (fn [] (gamestate.switch (require :src.modes.opening))))))

(fn mousepressed [self key code]
  (action))

(fn keypressed [self key]
  (local [interact-1 interact-2] params.keybindings.interact)
  (match key
    interact-1 (action)
    interact-2 (action)
    :space (action)))

{: draw : update : enter : keypressed : mousepressed }
