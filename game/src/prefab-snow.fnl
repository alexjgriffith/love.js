;; prefab-snow.fnl

(local snow {})

(local love (require :love))

(local preview true)

(fn snow.update [self dt]
  (self.part:update dt))

(fn snow.draw [self]
  (when self.part
    ;;(love.graphics.push "all")
    ;;(love.graphics.setColor 1 1 1 1)    
    (love.graphics.draw self.part 0 0)
    ;; (love.graphics.pop)
    ))

(fn ff [self frames]
    (for [_i 1 frames]
      (self.part:update 0.0166)))

(local snow-mt {:__index {
                          :update snow.update
                          :draw snow.draw}})

(fn setup-part [snow-canvas]
  (local part (love.graphics.newParticleSystem snow-canvas 3000))

  (part:setParticleLifetime 2 5)
  (if preview
      (part:setEmissionRate 100)
      (part:setEmissionRate 50000))
  (part:setSizeVariation 0.1)
  (part:setSpeed 100 200)
  (part:setSpin 0.1 1)
  (part:setSpread 0.25)
  ;;(part:setEmissionArea :uniform 1280 1280)

  (part:setEmissionArea :uniform 1000 500)
  (part:setDirection 0.25)
  ;; (part:setLinearAcceleration -20 -20 20 20)
  (part:setRotation -1 1)
  (if preview
      (part:setColors 1 1 1 1 1 1 1 1)
      (part:setColors 1 1 1 1 1 1 1 0))
  part
)

(fn snow.reset [self]
  (tset self :part (setup-part self.snow-canvas)))

(fn snow.prefab [brush])

(fn snow.serialize [self] self.brush)

(fn snow.create [image quad?]
  (local snow-canvas (love.graphics.newCanvas 4 4))
  (love.graphics.push "all")
  (love.graphics.setCanvas snow-canvas)
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.draw image quad?)
  (love.graphics.setCanvas)
  (love.graphics.pop)
  (local part (setup-part snow-canvas))
  (local ret (setmetatable {:type :snow
                            : part
                            : snow-canvas
                            :active true} snow-mt))
  (ff ret 200)
  ret)

snow
