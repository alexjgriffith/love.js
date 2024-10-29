;; this needs to be simplified next time...

(local love (require :love))
(local lg love.graphics)

(import-macros {: hex} :macro)

(local unit-editor {})

(local transform (love.math.newTransform))

(fn ttset [array index ...]
  ;; the output is bugged
  (when (not (. array index)) (tset array index []))
  (each [i2 v (ipairs [...])] (tset array index i2 v)))

(fn unit-editor.compile [frame mx my draw-array draw-index]
  (var event-name frame.name)
  (var event-index frame.z)
  (var event-args nil)
  (var event-action nil)
  (var last-hover-index nil)
  (var index draw-index)
  (transform:reset)
  (fn within [action mx my x y w h args ffalse ftrue r sx sy ox oy kx ky]
    (when r (transform:rotate r))
    (when sx (transform:scale sx (or sy sx)))
    (transform:translate x y)
    (let [(tmx tmy) (transform:inverseTransformPoint mx my)
          o (pointWithin tmx tmy 0 0 w h)]
      (set index (+ index 1))
      (ttset draw-array index (.. event-name "." action) ffalse (or ftrue ffalse) false x y w h r sx sy ox oy kx ky)
      (when o
        (set last-hover-index index)
        (set event-args args)
        (set event-action action))))
  (fn knob [ffalse]
    (set index (+ index 1))
    (ttset draw-array index (.. event-name "." :knob) ffalse ffalse false 0 0 0 0 nil nil nil nil))
  (local tile-size 32)
  (local w (* tile-size 4))
  (local h (* tile-size 6))
  (local padding 0)
  (local handle-y 20)
  (local scale 2)
  (local {: x : y :data {: hexgrid}} frame)
  (fn button [colour outline-colour?]
    (fn [x y w h]
      (lg.setColor colour)  
      (lg.rectangle :fill 0 0 w h)
      (lg.setColor (or outline-colour? (hex :000000)))
      (lg.rectangle :line 0 0 w h)))
  (fn background []
    (lg.setColor (hex :ffffff))  
    (lg.rectangle :fill 0 0 (* w scale) (* h scale) 0)
    (lg.setColor (hex :000000))
    (lg.rectangle :line 0 0 (* w scale) (* h scale) 0)
    (lg.setColor (hex :ffffff)))


  (knob (fn [] (lg.push :all) (lg.setLineWidth 3)))
  (within :handle mx my x y (* w scale) handle-y [] (button (hex :666666)) (button (hex :111111)) )
  (within :exit mx my (- (* w scale) 32) 0 32 handle-y  []
          (button (hex :aa6666)) (button (hex :661111)))
  (knob (fn [] (lg.translate (- (- (* w scale) 32)) 0)))
  (within :background mx my 0 handle-y (* w scale) (* h scale) [] background nil)

  ;; outline the unit
  (knob (fn [] (lg.pop)))
  (when frame.data.hexgrid.editing-unit
    (local {: camera} (require :src.state))
    (local unit frame.data.hexgrid.editing-unit)
    (knob (fn []
            (let [px (-> unit.x (+ camera.x) (* camera.scale) (math.floor))
                  py (-> unit.y (+ camera.y) (* camera.scale) (math.floor))
                  w (-> 32 (* camera.scale))
                  h (-> 48 (* camera.scale))]
              (lg.rectangle :line px py w h))))
    
    )
  (values index
          (+ padding (* scale w))
          (+ handle-y padding (* scale y))
          last-hover-index
          event-name
          event-index
          event-action
          event-args nil)
)


(fn unit-editor.mousepressed [frames frame x y button]
  (local {: mouse} frames)
  (local button-name (. [:left :right :middle] button))
  (when frames.last-hover
        (frames:bring-frame-to-front frame.z)
        (tset frames :selected frames.last-hover))
  (if (= button-name :left)
      (match frames.selected.name
        :background :nil
        :exit (frames:deactivate :unit-editor)
        :handle (frames:header-mousepressed frame x y)
        )))

(fn unit-editor.mousereleased [frames frame x y button]
  (local {: mouse} frames)
  (local button-name (. [:left :right :middle] button))
  (if (and (= button-name :left) mouse.selected)
      (do (set frames.selected nil)
          (frames:header-mousereleased))))


(fn unit-editor.mousemoved [frames frame x y]
  (local {: mouse} frames)
  (when (and mouse.left frames.selected)
    (match frames.selected.name
           :handle (frames:header-mousemoved frame x y))))

unit-editor
