; fennel-ls: macro-file.

(local {: effects} (require :src.resources))

(fn play-footsteps []
  (effects.footsteps:setVolume 0.2)
  (effects.footsteps:setLooping true)
  (effects.footsteps:stop)
  (effects.footsteps:play))

(fn stop-footsteps []
  (effects.footsteps:stop))


(fn play-footsteps-wood []
  (effects.footsteps-wood:setVolume 0.5)
  (effects.footsteps-wood:setLooping true)
  (effects.footsteps-wood:stop)
  (effects.footsteps-wood:play))

(fn stop-footsteps-wood []
  (effects.footsteps-wood:stop))

(var last-hover nil)
(fn hover []
  (when last-hover
    (last-hover:stop))
  (set last-hover (. effects (.. :hover (math.random 1 4))))
  (last-hover:play))

(fn click []
  (effects.click:stop)
  (effects.click:play))

(fn hurt []
  (effects.hurt:stop)
  (effects.hurt:play))

(fn talk []
  (effects.talk:stop)
  (effects.talk:play))

(fn talk2 []
  (effects.talk2:stop)
  (effects.talk2:play))

(fn talk3 []
  (effects.talk3:stop)
  (effects.talk3:play))

(fn talk4 []
  (effects.talk4:stop)
  (effects.talk4:play))

(fn talk5 []
  (effects.talk5:stop)
  (effects.talk5:play))

(fn talk6 []
  (effects.talk6:stop)
  (effects.talk6:play))

(fn land []
  (effects.land:stop)
  (effects.land:play))

(fn jump []
  (effects.bounce:stop)
  (effects.bounce:play))

(fn page []
  (effects.page:stop)
  (effects.page:play))

(fn chop []
  (effects.chop:stop)
  (effects.chop:play))

(macro make-sound-function [sound]
  `(fn ,sound []
     (,(sym (.. :effects. (tostring sound) ::stop)))
     (,(sym (.. :effects. (tostring sound) ::play)))))

(make-sound-function howl)

(make-sound-function scifi)

(make-sound-function door)

(fn fire [volume]
  (effects.fire:setVolume volume))

{: play-footsteps
 : stop-footsteps
 : play-footsteps-wood
 : stop-footsteps-wood
 : hover
 : click
 : hurt
 : land
 : talk
 : talk2
 : talk3
 : talk4
 : talk5
 : talk6
 : jump
 : page
 : fire
 : chop
 : howl
 : scifi
 : door}
