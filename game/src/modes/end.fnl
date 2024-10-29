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

(local text-options {:death
             (->
              "Your final unit has fallen.

The Frozen Duke's reign will not be ended this day.

[CLICK]" (wrap-text text-width font))

                     :day-over
             (->
              "The curse of the Frozen Duke has been lifted from the Frozen Horizon.

This day is a great day from Gnomekind.

[CLICK]" (wrap-text text-width font))
                     })

(var text "")

(var update-text nil)

(fn enter [self _previous message]
  (set text (. text-options message))
  (set update-text (scroll-text text speed (fn [] (sounds.talk5))))
  (fade.in))

(var printed "")
(fn update [self dt]
  (set printed (update-text dt)))

(fn draw-message [self]
  (local lg love.graphics)
  (local (w h) (love.window.getMode))
  (lg.clear background)
  (lg.setFont resources.fonts.big-text)
  (lg.setColor 1 1 1 1)
  (lg.printf printed (/ (- w text-width) 2) (- (/ h 2) 300) text-width)
  (fade.draw))

(fn draw [self]
  (draw-message)
  (overlay.draw)
  )

(fn action []
  (if (>= (# printed) (# text))
      (do (sounds.hurt) (fade.outin (fn []
                                      (local state (require :src.state))
                                      (set printed "")
                                      (gamestate.switch (require :src.modes.title))
                                      (local resources (require :src.resources))
                                      ;; (local state (require :src.state))
                                      (when (not dev) (resources.bgm:stop) (resources.bgm:play))
                                      (state.init)
                                      )))
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
