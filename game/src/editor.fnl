;; editor.fnl

;; Local Variables
(local love (require :love))
(import-macros {: getgmeta : setgmeta : log} :macro)

;; Internal Function

(fn real->game [camera mx my]
  (values (-> mx (- (* camera.x camera.scale)) (/ camera.scale) (math.floor))
          (-> my (- (* camera.y camera.scale)) (/ camera.scale) (math.floor))))

(local (left-mouse right-mouse middle-mouse) (values :left-mouse :right-mouse :middle-mouse))
(local mouse-names [left-mouse right-mouse middle-mouse])
(local mouse-map  {left-mouse :left right-mouse :right middle-mouse :middle})

;;keynames
(local (start close end update get is-active?) (values 1 2 3 4 5 6))

;; **********
;;    API
;; **********
(local editor {})

(local editor-pan-mt
       (do (var (_sx _sy _cx _cy _x _y _active)
                (values 0 0 0 0 0 0 false))
           {start (fn [command _ x? y?]
                     (local camera command.camera)
                     (set _sx (or x? 0))
                     (set _sy (or y? 0))
                     (set _x (or x? 0))
                     (set _y (or y? 0))
                     (set _cx camera.x)
                     (set _cy camera.y)
                     (set _active true)
                     (values (- _sx _x) (- _sy _y)))
            close (fn [command] (set _active false))
            end (fn [command _ x? y?]
                   (local camera command.camera)
                   (set _x (or x? 0))
                   (set _y (or y? 0))
                   (set _active false)
                   (values (- _sx _x) (- _sy _y)))
            update (fn [command _ x? y?]
                      (local camera command.camera)
                      (when _active
                        (set _x (or x? 0))
                        (set _y (or y? 0))
                        (set camera.x (- _cx (-> (- _sx _x) (/ camera.scale))))
                        (set camera.y (- _cy (-> (- _sy _y) (/ camera.scale)))))
                    (values (- _sx _x) (- _sy _y)))
            get (fn [command] (values (- _sx _x) (- _sy _y)))
            is-active? (fn [command] _active)}))

(setgmeta editor-pan-mt editor-pan-mt)

(fn editor.pan-generator [camera]
  (setmetatable {:name :pan : camera} (getgmeta editor-pan-mt)))

(fn editor.draw [{: camera : mouse} draw-call draw-overlay? clear-colour?]
  (local lg love.graphics)
  (local {: mx : my} mouse)
  (lg.push :all)
  (when clear-colour? (lg.clear clear-colour?))
  (draw-call camera mx my)
  (when draw-overlay? (draw-overlay? camera mx my))
  (lg.pop))

(fn editor.update [{: camera : mouse} dt callback ...]
  (callback dt camera mouse.mx mouse.my ...))

(local editor-draw-mt
       {start (fn [command {: tile} x y]
                 (when tile (let [(mx my) (real->game command.camera x y)]
                              (command.hexgrid:set mx my tile command.remove? :editor)))
                 (set command._active true))
        close (fn [command] (set command._active false))
        end (fn [command _editor _x _y] (set command._active false))
        update (fn [command {: tile} x y]
                  (when command._active
                      (log tile)
                      (when tile (let [(mx my) (real->game command.camera x y)]
                                   (command.hexgrid:set mx my tile command.remove? :editor :update)))))
        is-active? (fn [command] command._active)})

(setgmeta editor-draw-mt editor-draw-mt)

(fn editor.draw-generator [camera hexgrid remove?]
  (setmetatable {:name :draw :_active false : camera : hexgrid : remove?} (getgmeta editor-draw-mt)))

(local editor-move-mt
       {start (fn [command _ _]
                (local camera (. command :camera))
                (local speed (* (/ 1 60) command.speed (* 4 (/ 1 camera.scale))))
                (match command.direction
                  :left (set camera.x (+ camera.x speed))
                  :right (set camera.x (- camera.x speed))
                  :up (set camera.y (+ camera.y speed))
                  :down (set camera.y (- camera.y speed))
                  )
                (set command._active true))
        close (fn [command] (set command._active false))
        end (fn [command _editor _x _y] (set command._active false))
        update (fn [command _ dt]
                 (local camera (. command :camera))
                 (local speed (* dt command.speed (* 4 (/ 1 camera.scale))))
                 (match command.direction
                  :left (set camera.x (+ camera.x speed))
                  :right (set camera.x (- camera.x speed))
                  :up (set camera.y (+ camera.y speed))
                  :down (set camera.y (- camera.y speed))
                  )
                 )
        is-active? (fn [command] command._active)})

(setgmeta editor-move-mt editor-move-mt)


(fn editor.keyboard-move-generator [camera direction speed?]
  (setmetatable {:name :draw :_active false : camera : direction :keyboard true :speed (or speed? 10)} (getgmeta editor-move-mt)))

(fn editor.wheelmoved [{: camera : commands &as editor} x y]
  (let [p camera.scale
        is-active (accumulate [ret false _command-name command (pairs commands)] (or ret (: command is-active?)))
        n (math.min (if (= editor.name :gameplay) 8 8) (math.max (if (= editor.name :gameplay) 2 1)
                                                                 (* camera.scale (+ 1 (* 0.1 y)) )))
        (mx my) (love.mouse.getPosition)
        ox  (* mx  (/ (- n p) (* p n)))
        oy  (* my  (/ (- n p) (* p n)))]
    (when (not is-active)
      (set camera.scale n)
      (set camera.x (- camera.x ox))
      (set camera.y (- camera.y oy)))))

(fn editor.mousepressed [{: mouse : commands &as editor} x y button]
  (var button-name (. mouse-names button))
  (when (and  (= button-name left-mouse) (love.keyboard.isDown :space)) (set button-name middle-mouse))
  ;; (tset mouse (. mouse-map button-name) true)
  (when (. commands button-name) (: (. commands button-name) start editor x y)))

(fn editor.mousereleased [{: mouse : commands &as editor} x y button]
  (var button-name (. mouse-names button))
  (when (and  (= button-name left-mouse) (love.keyboard.isDown :space)) (set button-name middle-mouse))
  (when (. commands button-name) (: (. commands button-name) end editor x y)))

(fn editor.mousemoved [{: commands : mouse &as editor} x y]
  (set mouse.mx x)
  (set mouse.my y)  
  (each [_ command (pairs commands)]
    (when (not command.keyboard) (: command update editor x y))))

(fn editor.update-keyboard [{: commands &as editor} dt]
  (each [_ command (pairs commands)]
    (when (and command.keyboard command._active)
      (: command update editor dt))))

(fn editor.keypressed [{: commands &as editor} key code isrepeat]
  ;; (pp commands)
  (when (. commands key) (: (. commands key) start editor)))

(fn editor.keyreleased [{: commands &as editor} key code]
  (when (. commands key) (: (. commands key) end editor)))

(fn editor.set-tile [self tile]
  (set self.tile tile)
  (log self.tile))

(fn editor.switch [ed name callback camera mouse ...]
  (local commands (callback ed.camera ed.mouse ...))
  (each [_ command (pairs ed.commands)]
    (when (. command close) (: command close)))
  (set ed.commands commands)
  (set ed.camera camera)
  (set ed.name name)
  (set ed.mouse mouse)
  ed)

(setgmeta editor editor)

(fn editor.init [name callback camera mouse ...]
  (local commands (callback camera mouse ...))
  (setmetatable {: name : camera : mouse : commands} (getgmeta editor)))

(set editor.keywords {: start : close : end : update : get : is-active?
                      : left-mouse : right-mouse : middle-mouse})

editor 
