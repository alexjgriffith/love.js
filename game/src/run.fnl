(local love (require :love))
(local fennel (require :fennel))

(macro safely [f ...]  
  (let [{: dev} (require :src.params)]
    (if (not dev)
        `(,f ,...)
        `(let [gamestate# (require :lib.gamestate)]
           (xpcall ,f #(gamestate#.push (require :src.modes.error) $ (fennel.traceback)) ,...)))))


(fn no-handler-fun [name]
  (fn []
    (print (string.format "handler %s is not defined." name))))

(fn love.run []
  (love.graphics.setDefaultFilter :nearest :nearest)
  (when love.load
        (love.load (love.arg.parseGameArguments arg) arg))
  (when love.timer (love.timer.step))

  (var dt 0)

  (fn []
    (when love.event
          (love.event.pump)
          (each [name a b c d e f (love.event.poll)]
            (when (and (= name :quit) (or (not love.quit) (not (love.quit))))
              (lua "return a or 0"))
            (safely (or (. love.handlers name ) (no-handler-fun name)) a b c d e f)))

    (when love.timer (set dt (love.timer.step)))
    (when _G.dev (require :src.update-components))
    (when love.update (safely love.update dt))

    (when (and love.graphics (love.graphics.isActive))
      (love.graphics.origin)
      (love.graphics.clear (love.graphics.getBackgroundColor))
      (when love.draw
            (safely love.draw))

      (love.graphics.present)
      )
    (if love.timer (love.timer.sleep 0.001))
    )
  )
