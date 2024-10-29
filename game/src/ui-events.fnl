(local signal (require :lib.signal))

(local selected {:unit nil :tile nil :tile nil})

(fn tile [_ hg {: hi : hj}]
  (tset selected :tile (hg:get-tile hi hj))
  (tset selected :feature (hg:get-feature hi hj))
  (tset selected :unit (hg:get-unit hi hj)))

(signal.remove :controller-tile-click tile)
(signal.register :controller-tile-click tile)

(signal.remove :controller-unit-click tile)
(signal.register :controller-unit-click tile)

(signal.remove :controller-feature-click tile)
(signal.register :controller-feature-click tile)

(signal.remove :ui-selected-init tile)
(signal.register :ui-selected-init tile)

;; (signal.remove :ui-fire-army fire-army)
;; (signal.register :ui-fire-army fire-army)

;; (signal.remove :ui-hire-army hire-army)
;; (signal.register :ui-hire-army hire-army)


selected
