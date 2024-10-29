;; pre-combat.fnl

;; change music, lower blackout ;; push combat
(local gamestate (require :lib.gamestate))

(local pre-combat {})
(fn pre-combat.enter [from to [hexgrid ci cj ti tj] _defence-unit]
  (local state (require :src.state))
  (fn switch-to-combat []
    (local combat (require :src.combat))
    (combat.begin hexgrid ci cj ti tj))
  (state.transition-draw-down:start switch-to-combat))

(fn pre-combat.leave [_]
  (local state (require :src.state))
  (state.transition-draw-down:lift (fn [])))

(fn pre-combat.draw [_]
  (local game (require :src.modes.game))
  (game:draw))


pre-combat
