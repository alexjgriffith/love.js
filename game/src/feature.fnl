(local love (require :love))

(local feature {})

(import-macros {: setgmeta : getgmeta} :macro)


(fn feature.serialize [un]
  {:id un.id :name un.name :type :feature})

(fn feature.update [un dt])

(fn feature.draw [un]
  (local lg love.graphics)
  (lg.draw un.image un.body-quad un.x un.y))

(fn feature.outline [un]
  (local lg love.graphics)
  (lg.draw un.image un.outline-quad un.x un.y))

(fn feature.draw-sprite [un ...]
  (local {: sprites} (require :src.resources))
  (love.graphics.draw sprites.image (sprites.quad-grid:get un.tile-id 0)  ...))

(local feature-types {:tower [:tower1 :tower2 :church]
                      :village [:village1 :village2 :village3 :village4]
                      :hamlet [:house1 :house2 :house3]
                      :inn [:inn]
                      :city [:city1 :city2 :city3 :city4]
                      :fort [:fort1 :fort2 :fort3 :fort4]
                      :walls [:walls1 :walls2 :walls3 :walls4]
                      :garden [:garden1 :garden2 :garden3 :garden4]
                      :pond [:pond]
                      :shrine [:shrine]
                      :fire [:fire]
                      :circle [:circle]
                      :frozen-fort [:frozen-fort]
                      })

(local fortification-level {:tower 1 :village 0 :city 1 :walls 2 :fort 3 :pond 0 :garden 0 :shrine 0 :circle 0 :frozen-fort 4 :inn 0 :hamlet 0})


(local health-multiplier {:tower 1 :village 1.1 :city 1.1 :walls 1.1 :fort 1.1 :pond 3 :garden 1.5 :shrine 1.2 :circle 0 :frozen-fort 0.8 :inn 2 :hamlet 1})

(fn invert-table [tab]
  (local ret [])
  (each [key subtab (pairs tab)]
    (each [_ val (pairs subtab)]
      (tset ret val key)))
  ret)

(local recruitment-type {:tower :engineer :village :light-infantry :city :pike :walls :cavalry :fort :heavy-infantry
                         :pond nil :garden nil :shrine nil :circle nil :frozen-fort nil
                         :inn :light-infantry :hamlet :archers})


(local feature-types-map (invert-table feature-types))

(fn feature.get-health-multiplier [feature]
  (or (. health-multiplier feature.fature-type) 1))

(fn feature.get-type [feature]
  feature.feature-type)

(setgmeta feature feature)
(fn feature.create [un x y]
  (local {:atlas {: image :index {: map} : quad-grid}} (require :src.resources))
  (assert (. map un.name) (string.format "Name %s not defined in index in atlas-index." un.name))
  (let [tile-id (. map un.name)
        base 0
        overlayer 1
        feature-type (. feature-types-map un.name)
        out {:name un.name
             : x : y
             : image
             : tile-id
             :feature-type feature-type
             :fortification-level (. fortification-level feature-type)
             :recruitment-type (. recruitment-type feature-type)
             :id un.id
             :type :feature
             :body-quad (quad-grid:get tile-id base)
             :outline-quad (quad-grid:get tile-id overlayer)
             :sort-oy (+ -0.1 (* (math.random) -0.1))
             :h 32
             }]
    (setmetatable out (getgmeta feature))))

feature
