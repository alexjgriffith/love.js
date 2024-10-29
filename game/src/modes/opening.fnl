(local gamestate (require :lib.gamestate))
(local sounds (require :src.sounds))
(local pallet (require :src.pallet))
(local resources (require :src.resources))
(local fade (require :lib.fade))
(local overlay (require :src.overlay))
(local params (require :src.params))

(local {: wrap-text : scroll-text} (require :lib.text))

(local font resources.fonts.big-text)

(local text-width 600)
(var background [0 0 0 1])
(local speed 20) ;; chars / second

(local text (->
             "After a long voyage at sea your ship, laden with gnomic mercenaries, lands on the frozen horizon.

After a generation of strife and turmoil at the hands of the Frozen Duke you are here to lift the yoke of tyranny.

Muster your forces and march north, through the frozen wasteland of the Frozen Horizon, and liberate your people.

[CLICK]" (wrap-text text-width font)))

(local update-text (scroll-text text speed (fn [] (sounds.talk5))))

(fn enter [self _previous]
  (fade.in))

(var printed "")
(fn update [self dt]
  (set printed (update-text (or dt (/ 1 60)))))

(fn draw-message [self]
  (local lg love.graphics)
  (local (w h) (love.window.getMode))
  (lg.clear background)
  (lg.setFont resources.fonts.big-text)
  (lg.printf printed (/ (- w text-width) 2) (- (/ h 2) 300) text-width)
  (fade.draw))

(fn draw [self]
  (draw-message)
  (overlay.draw)
  )

(fn action []
  (if (>= (# printed) (# text))
      (do (sounds.hurt) (fade.out (fn [] (set printed "") (gamestate.switch (require :src.modes.tips) :src.modes.game))))
      (do (sounds.hurt) (update-text 0 :skip))))

(fn mousepressed [self key code] (action))

(fn keypressed [self key]
  (local [interact-1 interact-2] params.keybindings.interact)
  (match key
    interact-1 (action)
    interact-2 (action)
    :space (action)
    ))

{: draw : update : enter : keypressed : mousepressed}
