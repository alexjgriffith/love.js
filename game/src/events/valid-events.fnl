(macro make-pair-table [...]
  (let [ret {}]
    (each [_ v (ipairs [...]) ]
      (tset ret v true)
      )
    ret))

(make-pair-table
 "game-update"
 "game-start"
 "next-turn"
 "next-unit"
 "hover"
 "button-hover"
 "click"
 "controller-attack"
 "controller-moveto"
 "controller-unit-click"
 "controller-tile-click"
 "controller-feature-click"
 "begin-combat"
 "combat-skip-click"
 "combat-over"
 "ui-selected-init"
 "ui-hire-army"
 "ui-fire-army"
 "unit-set-team")
