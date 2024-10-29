(local love (require :love))
(local lg love.graphics)

(local {: format} (require :src.utils))

(import-macros {: hex} :macro)

(local unit-editor {})

(fn ttset [array index ...]
  ;; the output is bugged
  (when (not (. array index)) (tset array index []))
  (each [i2 v (ipairs [...])] (tset array index i2 v)))

(local transform (love.math.newTransform))

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
  
    (fn without [x y w h ffalse r sx sy ox oy kx ky]
      (when r (transform:rotate r))
      (when sx (transform:scale sx (or sy sx)))
      (transform:translate x y)
      (set index (+ index 1))
      (ttset draw-array index (.. event-name "." :without)  ffalse ffalse false x y w h r sx sy ox oy kx ky))
  (fn knob [ffalse]
    (set index (+ index 1))
    (ttset draw-array index (.. event-name "." :knob) ffalse ffalse false 0 0 0 0 nil nil nil nil))
  (local tile-size 32)
  (local w (* tile-size 4 2))
  (local h (- (* tile-size 8 2) 25))
  (local padding 0)
  (local handle-y 20)
  (local scale 4)
  (local {: x : y :data {: hexgrid}} frame)
  (local {: fonts : draw-icon : draw-tile} (require :src.resources))
  (local unit frame.data.hexgrid.editing-unit)
  (local row-number  (math.ceil (/ (fonts.text:getWidth unit.name) (- w 20))))
  
  (fn button [colour outline-colour?]
    (fn [x y w h]
      (lg.setColor colour)  
      (lg.rectangle :fill 0 0 w h)
      (lg.setColor (or outline-colour? (hex :000000)))
      (lg.rectangle :line 0 0 w h)))
  (fn background []
    (lg.setColor (hex :ffffff))  
    (lg.rectangle :fill 0 0 (* w 1) (+ (* row-number 25) (* h 1)) 0)
    (lg.setColor (hex :000000))
    (lg.rectangle :line 0 0 (* w 1) (+ (* row-number 25) (* h 1)) 0)
    (lg.setColor (hex :ffffff)))
  
  (knob (fn [] (lg.push :all) (lg.setLineWidth 3)))
  (within :handle mx my x y (* w 1) handle-y [] (button (hex :666666)) (button (hex :111111)) )
  (within :exit mx my (- (* w 1) 32) 0 32 handle-y  []
          (button (hex :aa6666)) (button (hex :661111)))
  ;; (knob (fn []  (lg.translate 0 -1)))
  (knob (fn [] (lg.translate (- (- (* w 1) 32)) 0)))
  (transform:translate (- (- (* w 1) 32)) 0)
  (within :background mx my 0 (- handle-y 1) (* w 1) (+ (* 25 row-number) (* h 1)) [] background nil)

  ;;name and title
  (knob (fn []
          (lg.setFont fonts.text)
          (lg.setColor 0 0 0 1)
          (lg.translate 10 10)
          (lg.printf unit.name 0 0 (- w 20) :center)
          (lg.translate 0 (* row-number 25))
          (lg.setFont fonts.mid-text)
          (lg.printf unit.race 0 0 (- w 20) :center)
          (lg.setColor 1 1 1 1)
          (lg.translate 20 20)
          (draw-icon  :dot2 0 0 0 scale)
          (lg.translate (* scale 12) 0)
          (draw-icon (if (> unit.stars 1) :dot2 :dot1) 0 0 0 scale)
          (lg.translate (* scale 12) 0)
          (draw-icon (if (> unit.stars 2) :dot2 :dot1) 0 0 0 scale)
          (lg.translate (* scale 12) 0)
          (draw-icon (if (> unit.stars 3) :dot2 :dot1) 0 0 0 scale)
          ;; (- (+ 20 25 10))
          (lg.translate (- (+ (* 12 3 scale) 20 10)) 40)
          ))
    
  (fn team-quad [colour selected]
    (fn []
      (lg.setColor 1 1 1 1)
      (local suffix (if (= selected colour) 2 1))
      (local name (.. colour suffix))
      ;; (lg.rectangle :fill 0 0 16 16)
      (draw-icon name 0 0 0 scale)))
  
    (transform:translate 0 (+ 20 (* 25 row-number) 10 40 ))
    (local current-colour (. [:white :blue :yellow :red] unit.team))
    (knob (fn [] (lg.translate 0 0)))
    (within :team-white mx my 0 0 (* 16 scale) (* 16 scale) [] (team-quad :white current-colour) (team-quad :white current-colour))
    (within :team-blue mx my (* 16 scale) 0 (* 16 scale) (* 16 scale) [] (team-quad :blue current-colour) (team-quad :blue current-colour))
    (within :team-yellow mx my (* 16 scale) 0 (* 16 scale) (* 16 scale) [] (team-quad :yellow current-colour) (team-quad :yellow current-colour))
    (within :team-red mx my (* 16 scale) 0 (* 16 scale) (* 16 scale) [] (team-quad :red current-colour) (team-quad :red current-colour))
    

;; (without (+ 10 (- (* 16 scale 3))) 50 0 0 (fn []))
  (local army-names [:light-infantry :archers :pike :heavy-infantry :cavalry :siege])
  (local lume (require :lib.lume))
  (each [i army-name (ipairs army-names)]
    ;;(without x y w h function ...)
    (within army-name mx my
            (if (= 1 i)
                (+ 10 (- (* 16 scale 3))) (- (+ 160 40)))
            (if (= i 1)
                (+ 50 30) 50) 0 0
            [:hover] (fn [] (lg.setFont fonts.mid-text)
                       (lg.setColor 0 0 0 1)
                       (lg.print (-> (. (lume.split army-name "-") 1) (string.gsub "^%l" string.upper)))
                       (lg.print (format "[%s]" (unit:army-type-count army-name)) 110 0)
                       ))
    
    (within :modify-army mx my 160 -10 (* 8 scale) (* 8 scale) [army-name :add-army]
            (fn [] 
              (lg.setColor 1 1 1 1)
              (draw-icon :up1 0 0 0 4))
            (fn [] 
              (lg.setColor 1 1 1 1)
              (draw-icon :up2 0 0 0 4))
            )
    (within :modify-army mx my 40 0 (* 8 scale) (* 8 scale) [army-name :remove-army]
            (fn [] 
              (lg.setColor 1 1 1 1)
              (draw-icon :down1 0 0 0 4))
            (fn [] 
              (lg.setColor 1 1 1 1)
              (draw-icon :down2 0 0 0 4))
            )
    )

    (within :ai mx my (- (+ 160 40)) 50 0 0
          []
          (fn [] (lg.setFont fonts.mid-text)
            (lg.setColor 0 0 0 1)
             (lg.print  (format "AI [%s]" (or unit.ai "UNDEF")) 0)            
            ))
    
  (within :modify-ai mx my 160 -10 (* 8 scale) (* 8 scale) [:previous-ai]
            (fn [] 
              (lg.setColor 1 1 1 1)
              (draw-icon :up1 0 0 0 4))
            (fn [] 
              (lg.setColor 1 1 1 1)
              (draw-icon :up2 0 0 0 4))
            )
    (within :modify-ai mx my 40 0 (* 8 scale) (* 8 scale) [:next-ai]
            (fn [] 
              (lg.setColor 1 1 1 1)
              (draw-icon :down1 0 0 0 4))
            (fn [] 
              (lg.setColor 1 1 1 1)
              (draw-icon :down2 0 0 0 4))
            )
  
  (within :portrait mx my (- (+ 160 40)) 50 0 0
          []
          (fn [] (lg.setFont fonts.mid-text)
            (lg.setColor 0 0 0 1)
            ;; (lg.print unit.quad-name 0 0)
            (lg.setColor 1 1 1 1)
            (draw-tile unit.quad-name (- (* 4 1)) (- (* 4 32)) 0 4)
            ))
  (within :next-protrait mx my 180 10 (* 8 scale) (* 8 scale) [unit.quad-name]
            (fn [] 
              (lg.setColor 1 1 1 1)
              (draw-icon :down1 0 0 0 4))
            (fn [] 
              (lg.setColor 1 1 1 1)
              (draw-icon :down2 0 0 0 4))
            )
  
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
          (+ padding (* 1 w))
          (+ handle-y padding (* 1 h) (* 25 row-number))
          last-hover-index
          event-name
          event-index
          event-action
          event-args nil)
)

(local quad-name-map
       {:gnome1 :gnome2
        :gnome2 :gnome3
        :gnome3 :gnome4
        :gnome4 :gnome5
        :gnome5 :gnome6
        :gnome6 :gnome7
        :gnome7 :gnome8
        :gnome8 :gnome9
        :gnome9 :gnome1
        :small-goblin :medium-goblin
        :medium-goblin :large-goblin
        :large-goblin :orc
        :orc :small-goblin
        :frozen-duke :frozen-duke
        })

(fn unit-editor.mousepressed [frames frame x y button]
  (local {: mouse} frames)
  (local button-name (. [:left :right :middle] button))
  (when frames.last-hover
        (frames:bring-frame-to-front frame.z)
        (tset frames :selected frames.last-hover))
  (var unit nil)
  (when frame.data.hexgrid.editing-unit
    (set unit frame.data.hexgrid.editing-unit))
  (if (= button-name :left)
      (match frames.selected.name
        :background :nil
        :team-white (when unit (set unit.team 1))
        :team-blue (when unit (set unit.team 2))
        :team-yellow (when unit (set unit.team 3))
        :team-red (when unit (set unit.team 4))
        :modify-army (let [[army-type action] frames.selected.args]
                       (pp [:action action army-type])
                       (when unit
                         ((. unit action) unit army-type)))
        :next-protrait (let [[quad-name] frames.selected.args
                             next-quad-name (. quad-name-map quad-name)]
                            (unit:change-quad-name next-quad-name))
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
