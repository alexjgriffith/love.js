;; combat.fnl

(local signal (require :lib.signal))
(local gamestate (require :lib.gamestate))

(import-macros {: getgmeta : setgmeta : hex} :macro)

;; (let [a [{:i 2} {:i 1} {:i 2} {:i 2} {:i 1} {:i 2}]] (flanked a (. a 2) (fn [a b] (= a.i b.i))))
(fn flanked [unit-table unit comparison]
  (fn wrap [v l u]
    (if (> v u) (+ l (- v u))
        (< v l) (+ 1 (- u (- l v)))
        v))  
  (let [unit-position (accumulate [ret 0 i un (ipairs unit-table)]
                        (if (= un unit) i ret))
        upper (-> (+ unit-position 1) (wrap 1 6))
        lower (-> (- unit-position 1) (wrap 1 6))]
    (values
     (accumulate [ret false i un (ipairs unit-table)]
       (if (and (~= un unit) (comparison un unit) (~= i upper) (~= i lower))
           true ret))
     unit-position
     upper
     lower)))

(fn pad [str len]
  (let [l (# (string.format "%s" str))
        d (- len l)]
    (var ret str)
    (for [i 1 d] (set ret (.. " " ret)))
    ret))

(local {: within-gen : format } (require :src.utils))
(local within-g (within-gen))
(fn draw-combat [sim period offence defence]
  (local lg love.graphics)
  (local (ww wh) (love.window.getMode))
  (local within (within-g))
  (local (fw fh) (values 700 600))
  (local (t r) (values (math.floor (/ (- ww fw) 2))
                       (math.floor (/ (- wh fh) 2))))
  (local {: fonts} (require :src.resources))
  (local {: colours} (require :src.params))
  (fn outline-colour [] (lg.setColor colours.text))
  (fn background-colour [] (lg.setColor colours.background))
  (fn shadow-colour [] (lg.setColor [0 0 0 0.5]))  
  (fn text-colour [] (lg.setColor colours.text))
  (fn state-colour [state]
    (match state
      :hold (background-colour)
      :skirmish (lg.setColor (hex :cad73c));; (hex ))
      :charge (lg.setColor (hex :dd8c52))
      :bind (lg.setColor (hex :1f6c66))
      :break (lg.setColor (hex :982229))
      :pursue (lg.setColor (hex :948ecb))
      :retreat (lg.setColor (hex :1f6c66))
      :seige (lg.setColor (hex :5aae94)))
      )
    
  (local padding 10)
  (lg.translate t r)
  (background-colour)
  (lg.rectangle :fill 0 0 fw fh)
  (lg.setLineWidth 4)
  (outline-colour)
  (lg.rectangle :line 0 0 fw fh)

  (lg.push)
  (lg.translate 0 padding)
  (lg.setFont fonts.text)
  (lg.printf "Attacker" padding 0 (- fw (* 2 padding)) :left)
  (lg.printf "Defender" padding 0 (- fw (* 2 padding)) :right)  
  (lg.printf "Combat" 0 0 fw :center)
  (local title-height (fonts.text:getHeight "Combat"))
  (lg.translate (/ fw 2) (+ title-height padding))
  (lg.print (.. "Turn: " (- sim.turn 1)) -100 10)
  ;; spinner
  (lg.translate 60 0 )
  (text-colour)
  (local radius 20)
  (lg.arc :fill 0 radius radius  0 (* (- 1 period) (* 2 math.pi)))
  (lg.arc :line 0 radius radius  0 (* (- 1 period) (* 2 math.pi)))
  (background-colour)
  (lg.arc :line 0 radius (- radius 10)  0 (* 2 math.pi))
  (lg.arc :fill 0 radius (- radius 10)  0 (* 2 math.pi))
  (lg.pop)

  (lg.push)
  (text-colour)
  (lg.setFont fonts.text)
  (lg.translate padding (+ padding 100))
  (lg.printf offence.name 0 0 (- (/ fw 2) (* padding 2)) :center)
  (lg.translate 0 50)
  (lg.setFont fonts.mid-text)
  (fn draw-unit [unit]
    (lg.push)
    (state-colour unit.state)
    (lg.rectangle :fill 0 0 (- (/ fw 2) (* padding 2)) 50)
    (text-colour)
    (lg.rectangle :line 0 0 (- (/ fw 2) (* padding 2)) 50)
    (lg.translate 5 5)
    (lg.print (.. unit.army-type " (" unit.state ")"))
    (lg.translate 0 22)
    (lg.print (.. "en:" (pad unit.energy 3) ", " "mp:" (pad unit.manpower 3) ", " "mo:" (pad unit.moral 3)))
    (lg.pop))
  
  (each [i unit (ipairs sim.offence-armies)]
    (draw-unit unit)
    (lg.translate 0 (+ 50 padding)))
  (lg.pop)

  (lg.push)
  (text-colour)
  (lg.setFont fonts.text)
  (lg.translate (+ (/ fw 2) padding) (+ padding 100))
  (lg.printf defence.name 0 0 (- (/ fw 2) (* padding 2)) :center)
  (lg.setFont fonts.mid-text)
  (lg.translate 0 50)
  ;; draw defence armies
  (each [i unit (ipairs sim.defence-armies)]
    (draw-unit unit)
    (lg.translate 0 (+ 50 padding)))
  (lg.pop)

  (lg.push)
  (lg.translate 0 400)
  (lg.setFont fonts.text)
  (when sim.bind (lg.printf "Bind!" 0 0 fw :center))
  (lg.translate 0 30)
  (when sim.charge-event (lg.printf "Charge!" 0 0 fw :center))
  (lg.translate 0 40)
  (lg.push)
  (lg.setFont fonts.mid-text)
  (lg.printf (format "Defender Flanked:%s " sim.flanked) padding 0 (- fw (* padding 2)))
  (lg.translate 0 25)
  (lg.printf (format "Terrain:%s " sim.terrain) padding 0 (- fw (* padding 2)))
  (lg.translate 0 25)
  (lg.printf (format "River Crossing:%s " sim.crossing) padding 0 (- fw (* padding 2)))
  (lg.translate 0 25)
  (lg.printf (format "Fortress Level:%s " sim.fortress-level) padding 0 (- fw (* padding 2)))
  (lg.translate 0 25)
  (lg.printf (format "Siege:%s " sim.siege) padding 0 (- fw (* padding 2)))  
  (lg.pop)

  (lg.translate (/ fw 2) 0)
  (lg.translate 40 40)
  (shadow-colour)
  (lg.translate 0 6)
  (lg.rectangle :fill -2 0 (+ 4 250) 40)
  (local (o t) (within 2 -6 254 40 nil nil
                       (fn [] (signal.emit :button-hover))
                       (fn []
                         (signal.emit :combat-skip-click sim offence defence))
                       ))
  (when (not o) (lg.translate 0 -6))
  (background-colour)
  (lg.rectangle :fill 0 0 250 40)
  (outline-colour)
  (lg.rectangle :line 0 0 250 40)
  (lg.setFont fonts.text)
  (lg.printf "SKIP" 0 10 250 :center)
  ;; (when t (pp :hover))
  (lg.pop)
  
  
  )

(local combat {})

(local simulation (require :src.simulation))

(local max-turns 12)

(fn combat.step [cs]
  (values
   cs
   (if (<= cs.sim.turn max-turns)
       (do (set cs.overview (simulation.overview (simulation.tick cs.sim))) true)
       false)))

(fn combat.enter [from to args offence-unit defence-unit]
  (local state (require :src.state))
  (tset state :combat-sim {:sim args.sim :period 1 :offence-unit offence-unit :defence-unit defence-unit}))

(fn combat.draw [_]
  (local {:combat-sim {: sim : period : offence-unit : defence-unit}} (require :src.state))
  (local game (require :src.modes.game))
  (game:draw :no-ui)
  (draw-combat sim period offence-unit defence-unit))



(fn combat.update [_ dt]
  (local {:combat-sim obj} (require :src.state))
  (local {: sim : period : offence-unit : defence-unit} obj)
  (local turn-time 1)
  (set obj.period (- period (* dt (/ 1 turn-time))))
  ;; (set obj.period 0.3)
  (when (< obj.period 0)
    (set obj.period 1)
    (simulation.tick sim))
  
  (when (> sim.turn 12)
    (signal.emit :combat-over sim offence-unit defence-unit)
    )
  )

(fn combat.fastforward [sim]
  (while (<= sim.turn 13)
    (simulation.tick sim))
  )

(setgmeta combat combat)

(fn combat.begin [_hg ci cj ti tj]
  (local {: hexgrid} (require :src.state))
  ;; (pp [:begin-fight _hg ci cj ti tj])
  ;; (pp [ ])
  ;; (. (hexgrid:get ci cj :units) 1)
  (let [offence-unit (. (hexgrid:get ci cj :units) 1)
        defence-unit (. (hexgrid:get ti tj :units) 1)
        crossing (hexgrid:river-crossing ci cj ti tj)
        terrain-index (hexgrid:get ti tj :ground)
        terrain-map {0 :mountains 1 :hills 2 :grass 3 :field 4 :desert 5 :trees 6 :ocean}
        terrain (. terrain-map terrain-index)
        surrounding-units (hexgrid:neighbours ci cj :units)
        flanked (flanked surrounding-units offence-unit (fn [{:team teama} {:team teamb}] (= teama teamb)))
        defending-unit {:leader {:modifier defence-unit.leader-modifier :gambits defence-unit.gambits}
                        :armies defence-unit.army}
        attacking-unit {:leader {:modifier offence-unit.leader-modifier :gambits offence-unit.gambits}
                        :armies offence-unit.army}
        combat-modifiers {:defence [] :offence []}
        fortress-level 0
        feature nil
        sim (simulation.load defending-unit attacking-unit combat-modifiers fortress-level terrain
                             flanked crossing feature)
        cs (setmetatable {:sim sim :overview nil} (getgmeta combat))
        ]
    (combat.step cs)
    (gamestate.push combat cs offence-unit defence-unit)
    )
  )



(fn combat.over [sim offence defence]
  ;; (pp sim)
  ;; (pp sim.offence-armies)
  ;; (pp sim.defence-armies)
  ;; (pp "\n\n#### OFFENCE")
  ;; (pp offence)
  ;; (pp "\n\n#### DEFENCE")
  ;; (pp defence)
  (each [i army (ipairs  sim.offence-armies)]
    (when (?. offence :army i)
      (tset offence :army i :energy 100)
      (tset offence :army i :manpower army.manpower)
      (tset offence :army i :moral army.moral)))
  (each [i army (ipairs sim.defence-armies)]
    (when (?. defence :army i)
      (tset defence :army i :energy 100)
      (tset defence :army i :manpower army.manpower)
      (tset defence :army i :moral army.moral))
    )
  (local offence-lost (icollect [_ army (ipairs defence.army)] (when (= army.manpower 0) army)))
  (local defence-lost (icollect [_ army (ipairs offence.army)] (when (= army.manpower 0) army)))
  (tset defence :army (icollect [_ army (ipairs defence.army)] (when (> army.manpower 0) army)))
  (tset offence :army (icollect [_ army (ipairs offence.army)] (when (> army.manpower 0) army)))
  (local post-combat (require :src.post-combat))
  (local defence-elim (= (# defence.army) 0))
  (local offence-elim (= (# offence.army) 0))
  (local outcome (if
                  (and (not offence-elim) (not defence-elim)) :tie
                  (and (not offence-elim) defence-elim) :offence-win
                  (and offence-elim (not defence-elim)) :defence-win
                  (and offence-elim defence-elim) :mutal))
  (local {: hexgrid} (require :src.state))
  (when defence-elim (hexgrid:unit-remove defence))
  (when offence-elim (hexgrid:unit-remove offence))
  (gamestate.pop)
  (gamestate.pop)
  (gamestate.push post-combat outcome offence-lost defence-lost)
  )

(signal.remove :combat-over combat.over)
(signal.register :combat-over combat.over)
(signal.register :combat-begin combat.begin)
(signal.register :combat-skip-click combat.fastforward)
combat
