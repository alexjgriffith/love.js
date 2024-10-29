;; game.fnl
(local love (require :love))
(local lg love.graphics)
(local state (require :src.state))
(local gamestate (require :lib.gamestate))
(local overlay (require :src.overlay))
(local fade (require :lib.fade))
(local resources (require :src.resources))
(local timer (require :lib.timer))
(local bounce-cursor (require :src.bounce-cursor))

(var map-focus true)
(var frame-number 0)

(import-macros {: debug : log :  insert : gtext : hex : incrb : setgevent} :macro)

(fn love.handlers.mouse-over [frame frame-index name args ding]
  (local fennel (require :lib.fennel))
  (local key (fennel.view [frame name args]))
  (when (and ding (state.frames:new-hover? key)) :play-ding)
  (state.frames:set-hover frame frame-index name args key frame-number)
  (state.frames:set-focus frame))


(fn get-next-team []
  (local previous-team state.team-turn)
  (set state.team-turn (+ state.team-turn 1))
  (when (> state.team-turn 4) (set state.team-turn 1))
  (values state.team-turn previous-team))

(fn start-player-turn [team]
  (when (= state.editor.name :gameplay)
    (team:start-turn)
    (when (. team :last-unit)
      (local {: select-unit} (require :src.controller))
      ;; This is fucked...
      (log :select-unit)
      (select-unit state.editor.commands.left-mouse (. team :last-unit))
      )
    )
  )

(fn game-start []
  (local state (require :src.state))
  (local player-team (. state.teams state.player-team))
  (start-player-turn player-team))

(setgevent :game-start game-start :game)

(fn next-unit []
  (let [team (. state.teams state.player-team)]
    (pp :next-unit)
    (team:next-unit)
    (when team.last-unit
      (local {: select-unit} (require :src.controller))
      (pp [:last-unit-id (?. team :last-unit :id)])
      (select-unit state.editor.commands.left-mouse (. team :last-unit))
      (local {: focus-camera-on-unit} (require :src.camera))
      (focus-camera-on-unit (. team :last-unit))
      )))

(fn skip-unit []
  (let [team (. state.teams state.player-team)]    
    (when team.last-unit
      (team.last-unit:skip-turn)
      (next-unit))))

(fn next-turn []
  (when (= state.editor.name :gameplay)
    (local {:keywords {: close}} (require :src.editor))
    (local last-unit state.editor.commands.left-mouse.active-unit)
    (: state.editor.commands.left-mouse close)
    (local (next-team previous-team) (get-next-team))
    (when last-unit (tset state.teams previous-team :last-unit last-unit))
    (when (= next-team 1)
      (set state.day (+ state.day 1))
      (state.new-day-overlay:next state.day))
    ;; maybe we hook this into listeners?
    
    (: (. state.teams previous-team) :end-turn)
    (local player-turn? (. state.teams next-team :player))
    (if player-turn? 
      (start-player-turn (. state.teams next-team))
      (do
        (local ai (require :src.ai))
        (:  (. state.teams next-team) :start-turn)
        (ai.run state next-turn)))))

(fn next-action []
  (when (= state.editor.name :gameplay)
    (let [team (. state.teams state.team-turn)
          player-turn? (. team :player)]
    (when player-turn?
      (if (team:can-move)
          (skip-unit)
          (next-turn))))))

(setgevent :next-turn next-turn :game)

(setgevent :next-unit skip-unit :game)

(fn init [_s]
  (local visibility-events (require :src.events.visibility-events))
  (visibility-events.init))

(fn toggle-editor-generator [initial-state states]
  (local state-map (collect [index name (ipairs states)] (values name index)))
  (var interface-state-number (. state-map initial-state))
  (fn []
    (print :toggling-editor)
    (local {: editor : editor-commands : camera : mouse} (require :src.state))
    (incrb interface-state-number 1 (# states))
    (local next-state-name (. states interface-state-number))
    (match next-state-name
      :editor (do (state.frames:activate :hex-options))
      :gameplay (do (state.frames:deactivate :hex-options)))
    (editor:switch next-state-name (. editor-commands next-state-name) camera mouse)
    ))

(local toggle-editor (toggle-editor-generator :editor [:editor :gameplay]))

(fn enter [_s _previous]
  (fade.veryslowin)
  (timer.clear)
  (let [state (require :src.state)] (state.init))
  (when (~= state.editor.name :gameplay) (toggle-editor))
  (let [signal (require :lib.signal)]
    (signal.emit :game-start)))

(fn game-draw [no-ui?]
  (set frame-number (+ frame-number 1))
  (set map-focus (not state.frames.focus))  
  ;; (when (not state.frames.focus) (set state.frames.last-hover.key nil))
  (state.editor:draw
   (fn [camera mx my]
     (local lg love.graphics)
     (lg.clear (hex :203c56))
     (lg.push)
     (lg.scale camera.scale)
     (lg.translate camera.x camera.y)
     (lg.setColor (hex :ffffff))
     (let [mxp (math.floor (- (/ mx camera.scale) camera.x))
           myp (math.floor (- (/ my camera.scale) camera.y))]
       (match state.editor.name
         :gameplay (do
                     (lg.push :all)
                     (state.hexgrid:draw mxp myp camera map-focus)
                     (lg.pop)
                     
                     )
         :editor (do
                   (lg.push :all)
                   (state.hexgrid:draw-editor mxp myp camera map-focus)
                   (lg.pop)))
       )
     (match state.editor.name
         :gameplay
         (do
           (lg.push)
           (lg.translate (- camera.x) (- camera.y))
           ;; (state.snow:draw)
           (lg.pop)
           (lg.push)
           (lg.setColor 1 1 1 1)
           (state.hexgrid:draw-fog-of-war)
           (lg.pop)
           
             ))
     (lg.pop)))
  (local (mx my) (love.mouse.getPosition))
  (match state.editor.name
    :gameplay (do
                (local ui (require :src.ui))
                (ui.draw state no-ui?)
                (state.new-day-overlay:draw)
                (state.transition-draw-down:draw)
                ))
                ;;(overlay.draw)))
  (state.frames:draw mx my)
  (state.frames:reset-focus))

(fn draw-fps []
  (local font resources.fonts.text)
  (local message (love.timer.getFPS))
  (local padding 20)
  (local width (font:getWidth message))
  (local height (font:getHeight message))
  (lg.push :all)
  (lg.setFont font)
  (lg.setColor 0 0 0 1)
  (lg.rectangle :fill (+ -2 (/ padding 2)) (+ -3 (/ padding 2))
                (+ width padding) (+ height padding) 10)  
  (lg.setColor (hex :7f7f7f))
  (lg.print message padding padding)
  (lg.pop))

(fn draw [_s no-ui?]
  (local params (require :src.params))
  (game-draw no-ui?)
  (when params.print-fps (draw-fps))
  (fade.draw))

(var pan-toggle false)
(fn update [_s dt]
  ;; (require :update-components)
  (local params (require :src.params))
  (local (mx my) (love.mouse.getPosition))
  (state.frames:update dt mx my)
  
  ;; at this point we will know if frames or a unit is selected
  ;; could also test to see if there is a specific hex
  ;; this callback does nothing
  (state.editor:update-keyboard dt)
  (state.editor:update
     dt
   (fn [dt camera mx my]
     (let [mxp (math.floor (- (/ mx camera.scale) camera.x))
           myp (math.floor (- (/ my camera.scale) camera.y))]
       (local (over hi hj) (state.hexgrid:update dt mxp myp map-focus))
       (tset state.hexgrid :hover {: over : hi : hj})
       )))
  (bounce-cursor.update dt)
  (when (= state.editor.name :gameplay)
    (local gamestate (require :lib.gamestate))
    (when (: (. state.teams state.player-team) :no-units)
      (gamestate.switch (require :src.modes.end) :death))
    (let [duke-alive (accumulate [ret false _i obj (ipairs state.hexgrid.objects)] (if (= :frozen-duke (?. obj :quad-name)) true ret))]
      (when (not duke-alive)
        (gamestate.switch (require :src.modes.end) :day-over)
        )
      )
    
    )
  (let [signal (require :lib.signal)]
    (signal.emit :game-update dt))
  )

(fn mousepressed [_s x y button]  
  (var button-name (. [:left :right :middle] button))
  ;;(local toggle-pan (love.keyboard.isDown :lctrl :space :lshift))
  (if pan-toggle (set button-name :middle))
  (tset state.mouse button-name true)
  (state.frames:call :mousepressed x y button)
  (when map-focus (state.editor:mousepressed x y (if pan-toggle 3 button))))

(fn mousereleased [_s x y button]
  (state.frames:call :mousereleased x y button)
  (when map-focus (state.editor:mousereleased x y (if pan-toggle 3 button)))
  (var button-name (. [:left :right :middle] button))
  ;;(local toggle-pan (love.keyboard.isDown :lctrl :space))
  (if pan-toggle (set button-name :middle))
  (tset state.mouse button-name false))

(fn mousemoved [_s x y button]
  (state.frames:call :mousemoved x y button)
  (when map-focus (state.editor:mousemoved x y))
  )

(fn wheelmoved [_s x y]
  (state.frames:call :wheelmoved x y)
  (when map-focus (state.editor:wheelmoved x y)))

(fn next-hex []
  (let [hexselect (require :src.hexselect)] (hexselect.next)))

(fn previous-hex []
  (let [hexselect (require :src.hexselect)] (hexselect.next :backwards)))


(fn pan-toggle-function []
  (set pan-toggle (not pan-toggle))
  (local {: cursors} (require :src.resources))
  (local {:keywords {: close}} (require :src.editor))
  (: state.editor.commands.left-mouse close)
  (if pan-toggle (love.mouse.setCursor cursors.pan)
      (love.mouse.setCursor cursors.normal)
      ))

(fn close-selection []
  (local {:keywords {: close}} (require :src.editor))
  (pp {:close-selection true : close})
  (: state.editor.commands.left-mouse close))

(local keypressed-table
       {"[" next-hex
        "]" previous-hex
        :ctrl-tab toggle-editor
        :f9 toggle-editor
        :return next-action
        :space next-action
        :tab next-action
        :p pan-toggle-function
        :P pan-toggle-function
        :escape close-selection
        })

(fn keypressed [_s key code isrepeat]
  (local ctrl (if (love.keyboard.isDown :lctrl :lctrl) :ctrl- ""))
  (local alt (if (love.keyboard.isDown :lalt :ralt) :alt- ""))
  (local shift (if (love.keyboard.isDown :lshift :rshift) :shift- ""))
  (local chord (.. ctrl alt shift key))
  ;; (print chord)
  (let [fun (. keypressed-table chord)]
    (when fun (fun))
    (when (not fun) (state.editor:keypressed key code isrepeat)))
  
)
(fn keyreleased [_s key code]
  (state.editor:keyreleased key code)
  )

{: enter : draw : update  : init
 : mousepressed : mousereleased : mousemoved : wheelmoved
 : keypressed : keyreleased}
