;; post-combat.fnl

(local love (require :love))
;; (local signal (require :lib.signal))
(local gamestate (require :lib.gamestate))
(local {: within-gen } (require :src.utils))

(import-macros {: getgmeta : setgmeta : hex} :macro)


(local within-g (within-gen))
(fn draw-post-combat [outcome offence defence]
  (local lg love.graphics)
  (local (ww wh) (love.window.getMode))
  (local within (within-g))
  (local (fw fh) (values 500 355))
  (local (t r) (values (math.floor (/ (- ww fw) 2))
                       (math.floor (/ (- wh fh) 2))))
  (local {: fonts} (require :src.resources))
  (local {: colours} (require :src.params))
  (fn outline-colour [] (lg.setColor colours.text))
  (fn background-colour [] (lg.setColor colours.background))
  (fn shadow-colour [] (lg.setColor [0 0 0 0.5]))  
  (fn text-colour [] (lg.setColor colours.text))
  (local padding 10)
  (lg.translate t r)
  (background-colour)
  (lg.rectangle :fill 0 0 fw fh)
  (lg.setLineWidth 4)
  (outline-colour)
  (lg.rectangle :line 0 0 fw fh)
  (lg.translate padding padding)
  (lg.setFont fonts.text)
  (lg.printf "Combat Summary" 0 0 fw :center)
  (lg.translate 0 50)
  (local outcomes {:offence "The attacker won" :defence "The defender won" :tie "Both armies stand" :mutal "Both armies fell."})
  (lg.printf (or (. outcomes outcome) :MISSING-OUTCOME) padding 0 (- fw (* padding 2)) :center)
  (lg.translate 0 50)
  (lg.printf "" padding 0 (- fw (* padding 2)))

  (lg.translate 0 180)
  (local (bw bh) (values (- fw (* 2 padding)) 40))
  (local next-over (within -2 4 (+ bw 4) bh
                           nil nil nil (fn []
                                         (gamestate.pop)
                                         ;; (signal.emit :combat-begin (unpack args))
                                         )))
  (lg.push)
  (shadow-colour)
  (lg.rectangle :fill -2 4 (+ 4 bw) bh)
  (if next-over (lg.translate 0 4))
  (background-colour)
  (lg.rectangle :fill 0 0 bw bh)        
  (outline-colour)
  (lg.rectangle :line 0 0 bw bh)
  (lg.setFont fonts.mid-text)
  (lg.translate 0 padding)
  (lg.printf "Leave Battlefield" 0 0 bw :center)
  (lg.pop)
)


(local post-combat {})
(fn post-combat.enter [from to outcome offence-lost defence-lost]
  (local state (require :src.state))
  (tset state :post-combat-outcome outcome)
  (tset state :post-combat-offence-lost offence-lost)
  (tset state :post-combat-defence-lost defence-lost))

(fn post-combat.draw [_]
  (local {: post-combat-outcome : post-combat-offence-lost : post-combat-defence-lost} (require :src.state))
  (local game (require :src.modes.game))
  (game:draw :no-ui)
  (draw-post-combat post-combat-outcome post-combat-offence-lost post-combat-defence-lost))


post-combat
