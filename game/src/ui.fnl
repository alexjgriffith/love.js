(local signal (require :lib.signal))
(local {: within-gen } (require :src.utils))

(import-macros {: hex} :macro)

(local within-g (within-gen))

(fn draw [state dont-update?]
  (local ui-events (require :src.ui-events))
  (local lg love.graphics)
  (local within (within-g dont-update?))
  (local {: fonts} (require :src.resources))
  (local {: colours} (require :src.params))
  (fn outline-colour [] (lg.setColor colours.text))
  (fn background-colour [] (lg.setColor colours.background))
  (fn shadow-colour [] (lg.setColor [0 0 0 0.5]))  
  (fn text-colour [] (lg.setColor colours.text))
  (local padding 10)
  (local (ww wh) (love.window.getMode))
  (local (fw fh) (values 250 wh))
  (local (fx fy) (values (- ww fw) 0))
  (lg.push)
  (lg.setLineWidth 4)
  (lg.translate fx fy)
  (background-colour)
  (lg.rectangle :fill 0 0 fw fh)
  (outline-colour)
  (lg.rectangle :line 2 2 (- fw 4) (- fh 4))

  (lg.push)
  (lg.translate padding padding)
  (lg.setFont fonts.text)
  (lg.print (string.format "Day: %s" state.day))
  (lg.translate 0 30)
  (lg.print (string.format "Gold: %s" (. state.teams state.player-team :cash)))
  (lg.translate 0 30)
  (lg.line 0 0 (- fw (* 2 padding)) 0)
  (lg.translate 0 30)
  (lg.setFont fonts.mid-text)
  (local {: names : type-description : type-action : tile-names} (require :src.feature-names))
  (when ui-events.tile (lg.printf (string.format "%s" (. tile-names ui-events.tile)) 0 0 (- fw (* padding 2)) :center))
  (lg.translate 0 40)

  ;; #######
  ;; Features
  ;; #######  
  (when ui-events.feature
    (lg.printf (string.format "%s" (. names ui-events.feature.name)) 0 0 (- fw (* padding 2)) :center)
    (lg.setFont fonts.small-text)
    (lg.translate 0 20)
    (lg.printf (string.format
                "%s\n%s"
                (. type-description ui-events.feature.feature-type)
                (. type-action ui-events.feature.feature-type))
               0 0 (- fw (* padding 2)) :center))
  (lg.translate 0 50)

  ;; #######
  ;; Units
  ;; #######  
  (when ui-events.unit
    (lg.setFont fonts.mid-text)
    (lg.printf (string.format "%s"  ui-events.unit.name) 0 0 (- fw (* padding 2)) :center)    
    (lg.setFont fonts.small-text)
    (lg.translate 0 60)
    (local recruitment-type (?. ui-events.feature :recruitment-type))
    (local player-army? (= state.player-team (?. ui-events.unit :team)))
    (local {: get-recruit-cost} (require :src.recruitments))
    (local gold (. state.teams state.player-team :cash))
    (local armyh 70)
    (local army-size (# ui-events.unit.army))
    (for [i 1 4]
      (local army (. ui-events.unit.army i))
      
      ;; #######
      ;; CURRENT Units
      ;; #######              
      (when army
        (background-colour)
        (lg.rectangle :fill 2 2 (- (- fw (* padding 2)) 4) (- armyh 4))
        (outline-colour)
        (lg.rectangle :line 2 2 (- (- fw (* padding 2)) 4) (- armyh 4))
        (lg.push)
        (lg.setFont fonts.mid-text)
        (lg.translate padding padding)
        (lg.print army.army-type)
        (lg.translate 0 25)
        (lg.setFont fonts.small-text)
        ;;(lg.print "Manpower:\nMoral:")
        ;; MORAL
        (lg.setColor (hex :7cae44))
        (lg.rectangle :fill 0 0 (* (/ army.moral 100) (/ fw 4)) 20)
        (outline-colour)
        (lg.rectangle :line 0 0 (/ fw 4) 20)
        (lg.translate (+ (/ fw 4) padding) 0)
        ;; MANPOWER
        (lg.setColor (hex :b43626))
        (lg.rectangle :fill 0 0 (* (/ army.manpower 100) (/ fw 4)) 20)        
        (outline-colour)
        (lg.rectangle :line 0 0 (/ fw 4) 20)

        (when (and player-army?
                    (> army-size 1)
                   )
          (lg.translate (+ (/ fw 4) padding) 0)
          (local next-over (within -2 4 (+ 4 (/ fw 4)) 20
                                   nil nil nil (fn []
                                                 (ui-events.unit:fire-army-index i)
                                                 (signal.emit :ui-fire-army ui-events.unit i))))
          
          (shadow-colour)
          (lg.rectangle :fill -2 4 (+ 4 (/ fw 4)) 20)
          (if next-over (lg.translate 0 4))
          (background-colour)
          (lg.rectangle :fill 0 0 (/ fw 4) 20)        
          (outline-colour)
          (lg.rectangle :line 0 0 (/ fw 4) 20)
          (lg.setFont fonts.small-text)
          (lg.translate 15 6)
          (lg.print :FIRE)
          )
        
        (lg.pop)
        )

      ;; #######
      ;; HIRE Units
      ;; #######        
      (when (and recruitment-type (not army) player-army?)
        (local cost (get-recruit-cost recruitment-type))
        (local can-afford (>= gold cost))
        (local next-over
               (when can-afford
                 (within -2 -4 (+ (- fw (* padding 2)) 4)
                         (+ armyh  4)
                         nil nil nil (fn []
                                       (ui-events.unit:hire-army recruitment-type)
                                       (: (. state.teams ui-events.unit.team) :expend-cash cost)
                                       (signal.emit :ui-hire-army ui-events.unit recruitment-type cost)))))
        
        (shadow-colour)
        (lg.rectangle :fill 0 0 (- fw (* padding 2)) armyh)
        (when (not next-over) (lg.translate 0 -4))
        (if can-afford
            (lg.setColor (hex :acc977))
            (lg.setColor (hex :9eaeab))
            )
        (lg.rectangle :fill 2 2 (- (- fw (* padding 2)) 4) (- armyh 4))
        (outline-colour)
        (lg.rectangle :line 2 2 (- (- fw (* padding 2)) 4) (- armyh 4))
        (lg.push)
        (lg.translate padding padding)
        (lg.setFont fonts.mid-text)
        (lg.print (.. "Hire Cost: " cost "G"))
        (lg.translate 0 30)
        (lg.print recruitment-type  )
        (lg.pop)
        (when (not next-over) (lg.translate 0 4))
        )
      (lg.translate 0 (+ armyh padding 4)))
    
    )  
  (lg.translate 20 40)
  (lg.push)
  (local {: sprites} (require :src.resources))
  (lg.setColor 1 1 1 1)
  (lg.scale 4)
  (lg.pop)
  (lg.pop)
  (lg.push)
  (local nth 100)
  (lg.translate padding (- fh nth))
  (shadow-colour)
  (lg.rectangle :fill 0 0 (- fw (* padding 2)) (- nth padding))
  (local next-unit? (let [state (require :src.state)
                          team (. state :teams state.player-team)]
                      (team:next-unit true)))
  (local next-over (within -2 -4 (+ (- fw (* padding 2)) 4) (+ (- nth padding) 4)
                           nil nil nil (fn [] (signal.emit (if next-unit? :next-unit :next-turn)))))
  (when (not next-over) (lg.translate 0 -4))
  (outline-colour)
  (lg.rectangle :fill 0 0 (- fw (* padding 2)) (- nth padding))
  (background-colour)
  (lg.rectangle :line 8 8 (- fw (* padding 2) 16) (- nth padding 16))
  (background-colour)
  (lg.setFont fonts.text)
  (lg.translate (- (/ fw 4) padding) 22)
  (lg.printf (if next-unit? "Next Unit" "Next Turn") 0 0 (/ fw 2) :center)
  (lg.pop)
  (lg.pop)

  )


(fn over-ui-function []
  (local (ww wh) (love.window.getMode))
  (local (fw fh) (values 250 wh))
  (local (fx fy) (values (- ww fw) 0))
  (local (mx my) (love.mouse.getPosition))                   
  (pointWithin mx my fx fy ww wh))

{: draw : over-ui-function}
