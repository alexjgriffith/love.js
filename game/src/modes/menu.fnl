;; (local viewport (require :src.viewport))
(local gamestate (require :lib.gamestate))
(local sounds (require :src.sounds))
(local pallet (require :src.pallet))
(local resources (require :src.resources))
(local fade (require :lib.fade))
(local lg love.graphics)
(local params (require :src.params))

(local {: wrap-text} (require :lib.text))

(local credits "Credits

Game Code - Alexander Griffith 
Sprite Art - Alexander Griffith
Music - CYBER CY
Font (Not Jam UI)
Sounds Effects - NeadSimic, Nicole Marie, InspectorJ (CCBY 3/4)
Sounds Effects - Blender Foundation, MentalSanityOff (CCBY 3/4)
Library (lume, flux, json) - RXI (MIT/X11)
Library (anim8,bump) - Enrique Cota (MIT)
Engine (LÖVE) - LÖVE Dev Team (Zlib)
Language (Fennel) - Calvin Rose (MIT/X11)
Web Support (Love.js) - Davidobot

[TAB]")

(local controls "
Controls

[TAB]")

(var mode :menu)
(fn enter [self previous]
  (local (mx my) (love.mouse.getPosition))
  (set mode :menu)
  (set self.pressed nil)
  (set self.released nil)
  (set self.key nil)
  (sounds.click)
  (set self.active true)
  (set self.mx mx)
  (set self.my my)
  ;; (love.mouse.setVisible true)
  (set self.previous previous))

(fn leave [self]
  (set self.active false)
  (sounds.hurt)
  ;; (love.mouse.setVisible false)
  )

(fn update [self dt])

(fn love.handlers.menu-click [button x y]
  (match button
    :Controls (set mode :controls)
    :Back (set mode :menu)
    :Clues (set mode :clues)
    :Credits (set mode :credits)
    ;;:Controls (set mode :controls)
    :Return (gamestate.pop)
    :Restart (do (gamestate.switch (require :src.modes.title))
                 (local resources (require :src.resources))
                 (local state (require :src.state))
                 (when (not dev) (resources.bgm:stop) (resources.bgm:play))
                 (state.init))
    :Quit (love.event.quit)
    ))

(local white [1 1 1 1])
(local black [0 0 0 1])
(local padding (* 4 5))
(local margin 20)
(var draw-menu-list-active-button nil)
(var not-over-button true)
(local keybind-options [:a :b :c :d :e :f :g :h :i :j :k :l :m :n :o
                        :p :q :r :s :t :u :v :w
                        :x :y :z ";" "'" :. :/ "[" "]" "\\" "`" :1 :2 :3 :4
                        :5 :6 :7 :8 :9 :0 :- :+
                        :backspace :delete :enter :space])

(fn hover-click [self mx my w h button-name]
  (local (x y) (love.graphics.inverseTransformPoint mx my))
  (local active (pointWithin x y 0 0 w h))
  (when active
    (when self.released
      (sounds.click)
      (love.event.push :menu-click button-name)
      (set self.released nil))
    (when (~= button-name draw-menu-list-active-button) (sounds.hover))
    (set draw-menu-list-active-button button-name)
    (set not-over-button false))
  active)

(fn draw-text-option [self button-name font action option mx my w? h?]
  (fn hover-set [self mx my w h button-name]
    (local lume (require :lib.lume))
    (local (x y) (love.graphics.inverseTransformPoint mx my))
    (local active (pointWithin x y 0 0 w h))
    (when active
      (if (~= button-name draw-menu-list-active-button)
          (do (set self.key nil) (sounds.hover))
          ;;(when (and self.key (. keybind-options self.key))
          (when (and self.key (lume.find keybind-options self.key))
            (local params (require :src.params))
            (tset params.keybindings action option self.key)
            (sounds.hurt)
            (set self.key nil)))
      (set draw-menu-list-active-button button-name)
      (set not-over-button false))
    active)
  (local w (or w? (font:getWidth button-name)))
  (local h (or h? (font:getHeight button-name)))
  (local button-width (+ padding padding w))  
  (local button-height (+ padding padding h))
  (local active (hover-set self mx my button-width button-height button-name))
  (lg.setFont font)
  (lg.setColor (if active white black))
  (lg.rectangle :fill 0 0 button-width button-height)
  (lg.setColor (if active black white))
  (lg.rectangle :line 0 0 button-width button-height)
  (lg.printf  button-name padding padding w :center)
  active)


(fn draw-button [self button-name font mx my w? h?]  
  (local w (or w? (font:getWidth button-name)))
  (local h (or h? (font:getHeight button-name)))
  (local button-width (+ padding padding w))  
  (local button-height (+ padding padding h))
  (local active (hover-click self mx my button-width button-height button-name))
  (lg.setFont font)
  (lg.setColor (if active white black))
  (lg.rectangle :fill 0 0 button-width button-height)
  (lg.setColor (if active black white))
  (lg.rectangle :line 0 0 button-width button-height)
  (lg.printf  button-name padding padding w :center)
  (lg.translate 0 (+ button-height margin))
  active)

(fn draw-control-options [self w h button-name]
  (local {: mx : my} self)
  (local options keybind-options)
  (local font resources.fonts.title)
  (local text-height (font:getHeight "C"))
  (local text-width (font:getWidth "Option 2 "))
  (local controls [:Actions :interact :left :right :up :down])
  (var title "Controls")  
  (local button-height (+ padding padding text-height))
  (local button-width (+ padding padding text-width))
  
  (local total-height (+ (+ text-height padding)
                       (* (# controls) button-height)
                       (* (- (# controls) 1) margin)
                       (+ button-height padding)))
  (local total-width (+ (* 3 button-width) (* 2 padding)))

  (local oy (math.floor (/ (- h total-height) 2)))
  (local ox (math.floor (/ (- w total-width) 2)))
  (local params (require :src.params))
  (lg.push :all)
  (lg.translate ox oy)
  (lg.setFont font)
  (lg.setLineWidth 4)
  (lg.setColor black)
  (lg.rectangle :fill (- padding) (- padding)
                (+ total-width (* 2 padding))
                (+ total-height  (* 2 padding)))
  (lg.setColor white)
  (lg.rectangle :line (- padding) (- padding)
                (+ total-width (* 2 padding))
                (+ total-height  (* 2 padding)))
  (lg.setColor white)
  ;; (lg.printf title 0 0 total-width :center)
  (lg.translate 0 (+ text-height padding))
  (each [index name (ipairs controls)]
    (local [option-1 option-2] (. params.keybindings name))
    (lg.setColor white)
    (lg.printf name 0 0 button-width :center)
    (lg.translate (+ padding button-width) 0)
    (if (= index 1)
        (lg.printf option-1 0 0 button-width :center)
        (when
            (draw-text-option self option-1 font name 1 mx my text-width text-height)
          (set title (string.format "(Press key to set %s)" name))
          ))
    (lg.translate (+ padding button-width) 0)
    (if (= index 1)
        (lg.printf option-2 0 0 button-width :center)
        (when (draw-text-option self option-2 font name 2 mx my text-width text-height)
          (set title (string.format "(Press key to set %s)" name))
          ))
    (if (= index 1)
        (lg.translate 0 (+ text-height padding))
        (lg.translate 0 (+ button-height padding)))
    (lg.translate (* -2 (+ padding button-width)) 0)
    )
  (lg.translate (+ button-width padding) 0)
  (draw-button self :Back font mx my text-width text-height)
  (lg.reset)
  (lg.setFont font)
  (lg.translate ox oy)
  (lg.setColor white)
  (lg.printf title 0 0 total-width :center)  
  (lg.pop)
  )

(fn draw-menu-list [self w h]
  (local {: mx : my} self)
  (local font resources.fonts.title)
  (local options ["Credits" "Return" "Restart" "Quit"])
  (local text-height (font:getHeight "C"))
  (local text-width
         (accumulate [max-width 0
                      _i text (ipairs options)]
           (math.max max-width (font:getWidth text))))
  (local button-height (+ padding padding text-height))
  (local button-width (+ padding padding text-width))
  (local total-height (+ (* (# options) button-height)
                         (* (- (# options) 1) margin)))
  (local oy (math.floor (/ (- h total-height) 2)))
  (local ox (math.floor (/ (- w button-width) 2)))
  (lg.push :all)
  (lg.translate ox oy)
  (lg.setFont font)
  (lg.setLineWidth 4)
  (lg.setColor white)
  (lg.rectangle :fill (- padding) (- padding)
                (+ button-width (* 2 padding))
                (+ total-height  (* 2 padding)))
  (lg.setColor black)
  (lg.rectangle :line (- padding) (- padding)
                (+ button-width (* 2 padding))
                (+ total-height  (* 2 padding)))
  (each [i button (ipairs options)]
    (local (x y) (love.graphics.inverseTransformPoint mx my))
    (local active (pointWithin x y 0 0 button-width button-height))
    (when active
      (when self.released
        (sounds.click)
        (love.event.push :menu-click button)
        (set self.released nil))
      (when (~= button draw-menu-list-active-button) (sounds.hover))
      (set draw-menu-list-active-button button))
    (when active
      (set not-over-button false))
    (lg.setColor (if active black white))
    (lg.rectangle :fill 0 0 button-width button-height)
    (lg.setColor (if active white black))
    (lg.rectangle :line 0 0 button-width button-height)
    (lg.printf  button padding padding text-width :center)
    (lg.translate 0 (+ button-height margin))
    )
  (lg.pop)
  )

(fn draw-credits [self w h]
  (local {: mx : my} self)
  (local font resources.fonts.subtitle)
  (local text-height (font:getHeight "Credits"))
  (local text-width (font:getWidth "Sounds Effects - NeadSimic, Nicole Marie, InspectorJ (CCBY 3/4)   "))
  (local credit-lines 17)
  (local total-height (* text-height credit-lines 1.0))
  (local oy (math.floor (/ (- h total-height) 2)))
  (local ox (math.floor (/ (- w text-width) 2)))
  (lg.push :all)
  (lg.translate ox oy)
  (lg.setColor black)
  (lg.rectangle :fill (- padding) (- padding)
                (+ text-width (* 2 padding))
                (+ total-height  (* 2 padding)))  
  (lg.setColor white)
  (lg.setFont font)
  (lg.setLineWidth 4)
  (lg.rectangle :line (- padding) (- padding)
                (+ text-width (* 2 padding))
                (+ total-height  (* 2 padding)))    
  (lg.printf credits 0 0 text-width :center)
  (lg.pop)
  )

(fn draw-controls [self w h]
  (local {: mx : my} self)
  (local font resources.fonts.subtitle)
  (local text-height (font:getHeight "controls"))
  (local text-width (font:getWidth "Sounds Effects - NeadSimic, Nicole Marie, InspectorJ (CCBY 3/4)   "))
  ;; (local text-width (- w padding))
  (local credit-lines 18)
  (local total-height (* text-height credit-lines 1.0))
  (local oy (math.floor (/ (- h total-height) 2)))
  (local ox (math.floor (/ (- w text-width) 2)))
  (lg.push :all)
  (lg.translate ox oy)
  (lg.setColor black)
  (lg.rectangle :fill (- padding) (- padding)
                (+ text-width (* 2 padding))
                (+ total-height  (* 2 padding)))  
  (lg.setColor white)
  (lg.setFont font)
  (lg.setLineWidth 4)
  (lg.rectangle :line (- padding) (- padding)
                (+ text-width (* 2 padding))
                (+ total-height  (* 2 padding)))    
  (lg.printf controls 0 0 text-width :center)
  (lg.pop)
  )


(fn draw-clues [self w h]
  (local {: mx : my} self)
  (local font resources.fonts.subtitle)
  (local text-height (font:getHeight "Credits"))
  (local text-width (font:getWidth "Comming soon...  "))
  (local credit-lines 5)
  (local total-height (* text-height credit-lines 1.0))
  (local oy (math.floor (/ (- h total-height) 2)))
  (local ox (math.floor (/ (- w text-width) 2)))
  (local clues "Clues

Comming soon...

[TAB]")
  (lg.push :all)
  (lg.translate ox oy)
  (lg.setColor black)
  (lg.rectangle :fill (- padding) (- padding)
                (+ text-width (* 2 padding))
                (+ total-height  (* 2 padding)))  
  (lg.setColor white)
  (lg.setFont font)
  (lg.setLineWidth 4)
  (lg.rectangle :line (- padding) (- padding)
                (+ text-width (* 2 padding))
                (+ total-height  (* 2 padding)))    
  (lg.printf clues 0 0 text-width :center)
  (lg.pop)
  )

(var message "")

(fn draw [self]
  (local (w h) (love.window.getMode))
  (when (and self.previous self.previous.draw)
    (self.previous.draw))
  (lg.push :all)
  (lg.reset)
  (lg.setColor 1 1 1 1)
  ;; (lg.print message 0 0)
  (set not-over-button true)
  (match mode
    :menu (draw-menu-list self w h)
    :controls (draw-controls self w h)
    :credits (draw-credits self w h)
    :clues (draw-clues self w h))
  (when not-over-button
    (set draw-menu-list-active-button nil))  
  (lg.pop)
  (set self.released nil)
  )

(fn keypressed [self key]
  (set self.key key))

(fn keyreleased [self key]
  (set self.key nil))

(fn mousepressed [self x y button]
  (set self.pressed {: x : y : button}))

(fn mousereleased [self x y button]
  (set self.released {: x : y : button}))

(fn mousemoved [self mx my]
    (set self.mx mx)
  (set self.my my)
  (set message  (string.format "x = %s y = %s" mx my)))

{: draw : update : enter : leave
 : keypressed : keyreleased
 : mousepressed : mousereleased : mousemoved}
