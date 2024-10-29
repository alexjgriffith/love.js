(local love (require :love))
(local gamestate (require :lib.gamestate))

(import-macros {: log : clear-log : debug} :macro)

(var menu nil)
;; make these into handlers to avoid
;; popping and pushing before drawing
(fn love.handlers.push-mode [mode callback]
  (gamestate.push (require mode) callback))

(fn love.handlers.pop-mode [...]
  (gamestate.pop ...))

(var fs false)
(fn toggle-fullscreen []
  ;; (local (w h flags) (love.window.getMode))
  ;; (tset flags :fullscreen (not flags.fullscreen))
  ;; (if flags.fullscreen
  ;;     (love.window.setMode w h flags)
  ;;     (love.window.setMode 1280 720 flags))
  (love.resize (love.window.getMode))
  (when (not _G.web)
    (if fs
        (let [(w h) (love.window.getDesktopDimensions 1)]
          (love.window.setMode 1280 720)
          (set fs false))
        (let [(w h) (love.window.getDesktopDimensions 1)]
          (love.window.setMode w h))
        (set fs true))

    ))

(var mute false)

(fn toggle-mute []
  (set mute (not mute))
  (if mute
      (love.audio.setVolume 0)
      (love.audio.setVolume 1)))

(local force-release false)

(fn love.load [args argc]
  (local params (require :src.params))
  (set _G.dev false)
  (when (and (= (. args 1) :dev) (not force-release))
    (tset params :dev true)
    (tset _G :_log-file (io.open (.. (love.filesystem.getSource) :logs/log.txt) :a))
    (set _G.dev true)
    (pp "Entering in Dev Mode")
    (local debug-events (require :src.events.debug-events))
    (debug-events.register)
    )
  (local first-mode (if _G.dev :src.modes.game :src.modes.title))
  (clear-log)
  (when (= :Web (love.system.getOS)) (set _G.web true))
  ;; (when (not _G.web)
  ;;   (let [(w h) (love.window.getDesktopDimensions 1)] (love.window.setMode w h)))
  (love.graphics.setDefaultFilter :nearest :nearest)
  (local resources (require :src.resources))
  (local _ (require :src.sound-events))
  (love.mouse.setCursor resources.cursors.normal)
  (when _G.dev (toggle-mute))
  (resources.bgm:play)
  (set menu (require :src.modes.menu))
  (let [gamestate (require :lib.gamestate)]
    (gamestate.registerEvents)
    (gamestate.switch (require first-mode)))  
  (when (not _G.web)
    (let [repl (require :lib.stdio)] (repl:start))))

(fn love.draw [])

(fn love.resize [w h])

(fn love.quit []
  (when _G._log-file
        (_G._log-file:write "QUIT\n")
        (_G._log-file:flush)
        (_G._log-file:close))
  true
  )

(fn love.update [dt]
  (local flux (require :lib.flux))
  (local sounds (require :src.sounds))
  (local timer (require :lib.timer))
  (when _G.dev
    ;; (require :src.update-components)
    (local watch (require :lib.watch))
    ;; (love.audio.setVolume 0.3)
    (watch.update))
  (local {: snow} (require :src.state))
  (when snow (snow:update dt))
  (flux.update (or dt (/ 1 60)))
  )

(fn toggle-menu []
  (if menu.active
      (do
        (gamestate.pop))
      (do
        (gamestate.push menu))))

(fn love.draw []
  (love.graphics.reset)
  (love.graphics.rectangle :line 0 0 1280 720))

(fn love.keypressed [key]
  (local ctrl (love.keyboard.isDown :lctrl))
  (if (not ctrl)
    (match key
      :f11 (toggle-fullscreen)
      :f10 (toggle-menu)
      )
    (match key
      :m (toggle-mute)))
  )
