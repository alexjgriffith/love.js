;; discussion.fnl
(local love (require :love))

(local signal (require :lib.signal))
(local gamestate (require :lib.gamestate))
(local {: within-gen } (require :src.utils))

(import-macros {: getgmeta : setgmeta : hex} :macro)


(local within-g (within-gen))
(fn draw-discussion [args defence]
  (local lg love.graphics)
  (local (ww wh) (love.window.getMode))
  (local within (within-g))
  (local (fw fh) (values 500 300))
  (local (t r) (values (math.floor (/ (- ww fw) 2))
                       (math.floor (/ (- wh fh) 2))))
  (local {: fonts} (require :src.resources))
  (local {: colours} (require :src.params))
  (fn outline-colour [] (lg.setColor colours.text))
  (fn background-colour [] (lg.setColor colours.background))
  (fn shadow-colour [] (lg.setColor [0 0 0 0.5]))  
  ;;(fn text-colour [] (lg.setColor colours.text))
  (local padding 10)
  (lg.translate t r)
  (background-colour)
  (lg.rectangle :fill 0 0 fw fh)
  (lg.setLineWidth 4)
  (outline-colour)
  (lg.rectangle :line 0 0 fw fh)
  (lg.translate padding padding)
  (lg.setFont fonts.text)
  (lg.printf defence.name 0 0 fw :center)
  (lg.translate 0 50)

  (lg.printf "Welcome Friend! I see you have come to join our struggle against the the Frozen Duke. We would gladly join your forces." padding 0 (- fw (* padding 2)))

  (lg.translate 0 180)
  (local (bw bh) (values (- fw (* 2 padding)) 40))
  (local next-over (within -2 4 (+ bw 4) bh
                           nil nil nil
                           (fn []
                             (local {: hexgrid} (require :src.state))
                             ;; required for swapping between units
                             ;; making sure combat energy is correct etc
                             (defence:next-turn hexgrid)
                             (defence:set-team 1)                            
                             (gamestate.pop))))
  (shadow-colour)
  (lg.rectangle :fill -2 4 (+ 4 bw) bh)
  (if next-over (lg.translate 0 4))
  (background-colour)
  (lg.rectangle :fill 0 0 bw bh)        
  (outline-colour)
  (lg.rectangle :line 0 0 bw bh)
  (lg.setFont fonts.mid-text)
  (lg.translate 0 padding)
  (lg.printf "Take on New Unit" 0 0 bw :center)
)


(local discussion {})

(fn discussion.enter [from to args defence-unit]
  (local state (require :src.state))
  (tset state :discussion-args args)
  (tset state :discussion-defence-unit defence-unit))

(fn discussion.draw [_]
  (local {: discussion-args : discussion-defence-unit} (require :src.state))
  (local game (require :src.modes.game))
  (game:draw :no-ui)
  (draw-discussion discussion-args discussion-defence-unit))

(fn discussion.update [_ dt]
  (require :src.discussion))


(setgmeta discussion discussion)

(fn discussion.begin [_ ci cj ti tj]
  (local {: hexgrid} (require :src.state))
  (let [offence-unit (. (hexgrid:get ci cj :units) 1)
        defence-unit (. (hexgrid:get ti tj :units) 1)
        pre-combat (require :src.pre-combat)
        ;; post-combat (require :src.post-combat)
        ]
    (match defence-unit.team
      1 :nothing
      2 (gamestate.push discussion [hexgrid ci cj ti tj] defence-unit)
      3 (gamestate.push discussion [hexgrid ci cj ti tj] defence-unit)
      4 (gamestate.push pre-combat [hexgrid ci cj ti tj] defence-unit)
      )
    
    ))

(signal.register :controller-attack discussion.begin)

discussion
