(local signal (require :lib.signal))

(fn make-play [sound-file volume?]
  (local t (match (type sound-file) :string :one :table :random))
  (local sound
         (match t
           :one (do (local s (love.audio.newSource sound-file :static))
                    (s:setVolume (or volume? 1))
                    s)
           :random (icollect [_ sf (ipairs sound-file)]
                     (do (local s (love.audio.newSource sf :static))
                         (s:setVolume (or volume? 1))
                         s))))
  
  (fn []
    (match t
      :one (do (sound:stop) (sound:play))
      :random (let [s (. sound (math.random (# sound)))] (s:stop) (s:play)))))

(local footsteps (make-play :assets/sounds/footsteps-short.ogg 1.5))

(local fire-out (make-play :assets/sounds/fire-out.ogg))

(local hurt (make-play :assets/sounds/talk.ogg))

(local tile (make-play :assets/sounds/talk2.ogg))

(local unit (make-play :assets/sounds/talk3.ogg))

(local feature (make-play :assets/sounds/talk4.ogg))

(local click (make-play :assets/sounds/page.ogg))

(local hover (make-play [:assets/sounds/sfx-hover-1.ogg
                         :assets/sounds/sfx-hover-2.ogg
                         :assets/sounds/sfx-hover-3.ogg
                         :assets/sounds/sfx-hover-4.ogg] 1.5))

(signal.remove :controller-attack fire-out)
(signal.register :controller-attack fire-out)

(signal.remove :controller-x hurt)
(signal.register :controller-x hurt)

(signal.remove :controller-moveto footsteps)
(signal.register :controller-moveto footsteps)


(signal.remove :controller-unit-click unit)
(signal.register :controller-unit-click unit)

(signal.remove :controller-tile-click tile)
(signal.register :controller-tile-click tile)

(signal.remove :controller-feature-click feature)
(signal.register :controller-feature-click feature)

(signal.remove :click click)
(signal.register :click click)

(signal.remove :hover hover)
(signal.register :hover hover)

(signal.remove :next-turn hurt)
(signal.register :next-turn hurt)
