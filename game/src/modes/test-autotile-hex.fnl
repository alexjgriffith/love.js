;; Libraries
(local love (require :love))

;; Source Files
(local autotile-hex (require :src.autotile-hex))
(local state (require :src.state))


;; Mode Methods
(fn enter [_s _f]
  (tset state :water-autotile (autotile-hex.outline2))
  )

(fn init []
  (love.window.setMode (* 32 16) (* 48 4)))


(var first true)
(fn update [_s dt]
  (when first
    (love.graphics.captureScreenshot "outline2.png")
    (set first false))
  )

(fn draw [_s ]
  (love.graphics.clear 0.3 0.3 0.3 1)
  (love.graphics.push :all)
  ;; (love.graphics.reset)
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.draw state.water-autotile.image)
  (love.graphics.translate (- (* 32 16)) (* 48) )
  (love.graphics.draw state.water-autotile.image)
  (love.graphics.translate (- (* 32 16)) (* 48) )
  (love.graphics.draw state.water-autotile.image)
  (love.graphics.translate (- (* 32 16)) (* 48) )
  (love.graphics.draw state.water-autotile.image)
  (love.graphics.translate (- (* 32 16)) (* 48) )
  (love.graphics.draw state.water-autotile.image)  
  (love.graphics.pop)
  )


{: update : enter : draw : init}
