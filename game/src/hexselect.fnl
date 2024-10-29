(local love (require :love))
(local lg love.graphics)

(import-macros {: hex} :macro)

(fn ttset [array index ...]
  ;; the output is bugged
  (when (not (. array index)) (tset array index []))
  (each [i2 v (ipairs [...])] (tset array index i2 v)))

(local hexselect {})
(let [{:atlas {: index}} (require :src.resources)]
  (tset hexselect :map index.map)
  (tset hexselect :order index.tiles))


(local transform (love.math.newTransform))

(fn hexselect.compile [frame mx my draw-array draw-index]
  (local frames (require :src.frames))
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
  (local w (values 4))
  (local h (math.ceil (/ (# hexselect.order) w)))
  (local padding 0)
  (local handle-y 20)
  (local tile-size 32)
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
    (lg.rectangle :fill 0 0 (* w tile-size scale) (* h tile-size scale) 0)
    (lg.setColor (hex :000000))
    (lg.rectangle :line 0 0 (* w tile-size scale) (* h tile-size scale) 0)
    (lg.setColor (hex :ffffff)))  

  (knob (fn [] (lg.push :all)))
  (knob (fn [] (lg.setLineWidth 3)))

  (within :handle mx my x y (* w tile-size scale) handle-y [] (button (hex :666666)) (button (hex :111111)) )
  
  (within :background mx my 0 handle-y (* w tile-size scale) (* h tile-size scale) [] background nil)
  
  (knob (fn [] (lg.setColor (hex :ffffff))))
  
  (each [key value (ipairs hexselect.order)]
    (local option (. hexselect.map value))
    (fn tile-ffalse []
      (lg.push)
      (lg.setColor 1 1 1 1)
      (lg.draw hexgrid.atlas.image (hexgrid.atlas.quad-grid:get option 0) 0 (* scale -15) 0 scale)
      (lg.draw hexgrid.atlas.image (hexgrid.atlas.quad-grid:get option 1) 0 (* scale -15) 0 scale)
      (lg.pop))
    (fn tile-ftrue [x y w h]
      (lg.push)
      (lg.setColor 1 1 1 1)
      (lg.draw hexgrid.atlas.image (hexgrid.atlas.quad-grid:get option 0) 0 (* scale -15) 0 scale)
      (lg.setColor 0 0 0 1)
      (lg.draw hexgrid.atlas.image (hexgrid.atlas.quad-grid:get (+ 16 7) 0) 0 (* scale -15) 0 scale)
      (lg.setColor 1 1 1 1)
      (lg.draw hexgrid.atlas.image (hexgrid.atlas.quad-grid:get option 1) 0 (* scale -15) 0 scale)
      (lg.pop))
    (within :tile mx my 0 0 (* scale tile-size) (* scale tile-size) [value] tile-ffalse tile-ftrue)

    (within :tile-ox mx my (* scale tile-size) 0 0 0 [ ] (fn []) nil)
    (when (= 0 (% key w))
      (within :tile-oy mx my (- (* w (* scale tile-size))) (* scale tile-size) 0 0 [ ] (fn []) nil)))
  (knob (fn [] (lg.pop)))
  (values index (+ padding (* scale tile-size w)) (+ handle-y padding (* scale tile-size y)) last-hover-index event-name event-index event-action event-args nil)
  )

(fn hexselect.mousepressed [frames frame x y button]
  (local {: mouse} frames)
  (local button-name (. [:left :right :middle] button))
  (when frames.last-hover
        (frames:bring-frame-to-front frame.z)
        (tset frames :selected frames.last-hover))
  (if (= button-name :left)
      (match frames.selected.name
             :background :nil
              :handle (frames:header-mousepressed frame x y)
               :tile (let [{: editor} (require :src.state)]
                       ;; (pp frames.selected)
                       (editor:set-tile (. frames.selected.args 1)))
                :close :setframenotactive)))

(fn hexselect.mousereleased [frames frame x y button]
  (local {: mouse} frames)
  (local button-name (. [:left :right :middle] button))
  (if (and (= button-name :left) mouse.selected)
      (do (set frames.selected nil)
          (frames:header-mousereleased))))


(fn hexselect.mousemoved [frames frame x y]
  (local {: mouse} frames)
  (when (and mouse.left frames.selected)
    (match frames.selected.name
           :handle (frames:header-mousemoved frame x y))))

(fn hexselect.set-list [name]
  (let [{:atlas {: index}} (require :src.resources)]
    (tset hexselect :order (. index name))))

(fn iterate-list-generator [options]
  (let [l (# options)]
    (var index 1)
    (fn [backwards?]
      (set index (+ index (if backwards? -1 1)))
      (when (> index l) (set index 1))
      (when (< index 1) (set index l))
      (hexselect.set-list (. options index))
      )))



;; used to toggle between different groups of tiles
(tset hexselect :next (iterate-list-generator [:tiles :units :features1 :features2]))

hexselect
