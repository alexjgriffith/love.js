(local base-cost 10)

(local recruitment-cost {:light-infantry base-cost
                         :archers base-cost
                         :pike (* 3 base-cost)
                         :heavy-infantry (* 4 base-cost)                         
                         :cavalry (* 5 base-cost)
                         :engineer (* 10 base-cost)
                         })

(local base-money-raised 5)
(local money-raised-tile-multiplier {:desert 0
                                     :fields 5
                                     :grass 3
                                     :forest 3
                                     :hills 1
                                     :mountains 0
                                     :ocean 0})


(local money-raised-unit-multiplier
       {:light-infantry 1
        :archers 1
        :pike 2
        :heavy-infantry 2
        :cavalry 5
        :engineer 0})

(local money-raised-feature-multiplier {:tower 1 :village 1.5 :city 3 :walls 1 :fort 2
                                       :pond 0 :garden 0 :shrine 0 :circle 5 :frozen-fort 1
                                       :hamlet 1 :inn 1})

(fn raise-money [army-type tile-type feature-type?]
  (* base-money-raised
     (or (. money-raised-tile-multiplier tile-type) 1)
     (or (. money-raised-unit-multiplier army-type) 1)
     (or (?. money-raised-feature-multiplier feature-type?) 1))
  )

(fn get-recruit-cost [army-type]
  (or (. recruitment-cost army-type) 0))

{: raise-money : get-recruit-cost}
