(local editor (require :src.editor))
(local controller (require :src.controller))
(local love (require :love))
(local lume (require :lib.lume))

(local state {:editor nil
              :hexgrid nil
              :frames nil
              :hexgrid nil
              :editor-commands {}
              :camera {:x 0 :y 0 :scale 4}
              :mouse {:mx 0 :my 0 :left nil :right nil :midle nil :back nil :forward nil}
              :objects []
              :last-unit-id 0
              :day 1
              :team-turn 1
              :teams []
              :player-team 1
              :snow nil
              :new-day-overlay nil})

(local default-camera {:x (- (+ (* 24 25) -100)) :y (- (+ (* 30 75) 250)) :scale 4})

(fn editor-command-callback [hexgrid]
  (fn [camera mouse]
    {:middle-mouse (editor.pan-generator camera)
     :left-mouse (editor.draw-generator camera hexgrid)
     :right-mouse (editor.draw-generator camera hexgrid :remove)
     }))

(fn gameplay-command-callback [hexgrid]
  (fn [camera mouse]
    {:middle-mouse (editor.pan-generator camera)
     :left-mouse (controller.init hexgrid)
     :left (editor.keyboard-move-generator camera :left 100)
     :right (editor.keyboard-move-generator camera :right 100)
     :up (editor.keyboard-move-generator camera :up 100)
     :down (editor.keyboard-move-generator camera :down 100)
     :a (editor.keyboard-move-generator camera :left 100)
     :d (editor.keyboard-move-generator camera :right 100)
     :w (editor.keyboard-move-generator camera :up 100)
     :s (editor.keyboard-move-generator camera :down 100)     
     }))

(fn init []
  (local state (require :src.state))
  (local frames (require :src.frames))
  (local hexgrid (require :src.hexgrid))
  (local hexselect (require :src.hexselect))
  (set state.mouse (let [(mx my) (love.mouse.getPosition)]
                     {: mx : my :left nil :right nil :middle nil :back nil :forward nil}))
  (set state.camera (lume.clone default-camera))
  (set state.hexgrid (hexgrid.load :assets.levels.level))
  (set state.editor-commands {:editor (editor-command-callback state.hexgrid)
                              :gameplay (gameplay-command-callback state.hexgrid)})
  (set state.editor (editor.init :editor state.editor-commands.editor state.camera state.mouse))
  (set state.frames (frames.init state.mouse))
  (local unit-editor (require :src.unit-editor))
  (state.frames:add :hex-options 100 100 {:hexgrid state.hexgrid} true hexselect)
  (state.frames:add :unit-editor 120 120 {:hexgrid state.hexgrid} true unit-editor)
  (state.frames:deactivate :unit-editor)
  (set state.day 1)
  (set state.last-unit-id 0)
  (set state.last-feature-id 0)
  (set state.objects [])
  (set state.team-turn 1)
  (set state.player-team 1)
  (local team (require :src.team))
  (tset state.teams 1 (team.init state.hexgrid 1 30 true))
  (tset state.teams 2 (team.init state.hexgrid 2 0 false))
  (tset state.teams 3 (team.init state.hexgrid 3 0 false))
  (tset state.teams 4 (team.init state.hexgrid 4 0 false))  
  (let [snow (require :src.prefab-snow)
        resources (require :src.resources)]
    ;;(when state.snow (state.snow:release))
    (set state.snow (snow.create resources.snowImage)))
  (set state.new-day-overlay
       (let [{: new-day-overlay} (require :src.overlay)]
         (new-day-overlay.init 1)))
  (set state.transition-draw-down
       (let [{: transition-draw-down} (require :src.overlay)]
         (transition-draw-down.init)))
  (collectgarbage :collect)
  )

(local mt {:__index {: init}})

(setmetatable state mt)

state
