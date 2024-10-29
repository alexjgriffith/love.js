;; visibility-events.fnl
(local state (require :src.state))

;; make it very clear this module accesses state
;; We don't know what the handler wants to do with
;; the signal so we don't know what to include in
;; the event message.

(import-macros {: setgmeta : getgmeta} :macro)

(local visibility {})

(fn visibility.update [_hg]
  (state.hexgrid:clear-visible)
  (each [_ team (ipairs state.teams)] (team:update-visibility))
  ;; (each [_ team (ipairs state.teams)] (team:update-visited pathing))
  (state.hexgrid:set-visibility-spritebatch state.player-team))

(setgmeta visibility visibility)

(fn init []
  (local signal (require :lib.signal))
  (local vistab (. (getgmeta visibility) :__index))
  (fn visfun [...] (vistab.update ...))
  (signal.register :controller-moveto visfun)
  (signal.register :next-turn visfun)
  (signal.register :game-start visfun)
  (signal.register :unit-set-team visfun)
  )

{: init}
