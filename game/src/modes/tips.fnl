(local gamestate (require :lib.gamestate))
(local sounds (require :src.sounds))
(local pallet (require :src.pallet))
(local timer (require :lib.timer))
(local resources (require :src.resources))
(local fade (require :lib.fade))
(local overlay (require :src.overlay))
(local params (require :src.params))

(local {: wrap-text : scroll-text} (require :lib.text))

(local font resources.fonts.big-text)

(local text-width 1200)
(var background [0 0 0 1])
(local speed 20) ;; chars / second

(local text-options  ["Let the struggle begin"] )

(var text "")
(var exit-handler nil)
(var next-state "")

(fn exit []
  (when exit-handler
    (timer.cancel exit-handler))
  (fade.out (fn [] (gamestate.switch (require next-state)))))

(fn enter [self _previous *next-state]
  (set next-state *next-state)
  (set text (. text-options (math.random (# text-options))))
  (fade.slowin)
  (set exit-handler (timer.after 3.5 exit))
  )

(fn draw-message [self]
  (local lg love.graphics)
  (local (w h) (love.window.getMode))
  (local padding 20)
  (lg.clear background)
  (lg.setFont resources.fonts.big-text)
  (lg.printf text padding (- (/ h 2) 50) (- w (* 2 padding)) :center)
  (fade.draw))

(fn draw [self]
  (draw-message)
  (overlay.draw)
  )

(fn update [self dt]
  (timer.update (or dt (/ 1 60))))

(fn keypressed [self key]
  (match key
    :space (do (sounds.hurt) (exit))
    :escape (do (sounds.hurt) (exit))
    :enter (do (exit)))
  )

{: draw : enter : keypressed : update}
