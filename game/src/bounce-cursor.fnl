;; bounce-cursor.fnl

(local love (require :love))

(local period 0.5)
(var timer 0)
(var index 1)
(local max-index 2)

(local state (require :src.state))
(fn update [dt]
  (local {: cursors} (require :src.resources))
  (set timer (+ timer dt))
  (when (> timer period)
    (set timer 0)
    (set index (+ index 1))
    (when (> index max-index) (set index 1))
    (when (and (= state.editor.name :gameplay)
               state.editor.commands.left-mouse.unit-status
               (= state.editor.commands.left-mouse.unit-status :move)
               (= state.editor.commands.left-mouse.state :unit))
      (set cursors.move (. cursors (.. "move" index)))
      (love.mouse.setCursor (. cursors (.. "move" index)))
      ))
  )

{: update}
