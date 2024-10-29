;; simulation.fnl
(local fennel (require :lib.fennel))
(fn pp [x] (print (fennel.view x)))

(local damage-variance 0.1)

(local stats
       {:light-infantry {:skirmish 10 :arrowfire  0 :shock  3 :anti-shock  2 :bind  3 :retreat  1 :pursue  7 :org  2 :siege  0 :sally  7 :bindable  true :overrunable false}
        :archers        {:skirmish  5 :arrowfire 10 :shock  2 :anti-shock  1 :bind  2 :retreat  1 :pursue  2 :org  2 :siege  0 :sally  0 :bindable  true :overrunable false}
        :heavy-infantry {:skirmish  5 :arrowfire  0 :shock  7 :anti-shock  3 :bind 10 :retreat  4 :pursue  2 :org 10 :siege  0 :sally  3 :bindable  true :overrunable false}
        :pike           {:skirmish  0 :arrowfire  0 :shock  2 :anti-shock 10 :bind  5 :retreat  6 :pursue  1 :org  8 :siege  0 :sally  0 :bindable  true :overrunable false}
        :cavalry        {:skirmish  5 :arrowfire  0 :shock 10 :anti-shock  1 :bind  0 :retreat 10 :pursue 10 :org  8 :siege  0 :sally 10 :bindable false :overrunable false}
        :engineer       {:skirmish  0 :arrowfire  0 :shock  0 :anti-shock  0 :bind  0 :retreat  1 :pursue  0 :org  0 :siege 10 :sally  0 :bindable false :overrunable  true}})

(local base-state-changes
       {
        :hold     {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :skirmish {:hold  0 :skirmish 10 :charge 0  :bind  0 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :charge   {:hold  0 :skirmish  0 :charge 10 :bind  0 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :bind     {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :pursue  {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue 10 :retreat  0 :break  0 :sally 0 :siege  0}
        :retreat  {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat 10 :break  0 :sally 0 :siege  0}
        :break    {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 10 :sally 0 :siege  0}
        :sally    {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :siege    {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}})

(local terrain-offence-stats-effects ;; multiplicitive
       {:hills     {:skirmish 1.1  :arrowfire 0.9  :shock 0.75   :anti-shock  1   :bind  0.9  :reatreat 0.75  :pursue 0.7  :siege 0.5}
        :grass     {:skirmish 1    :arrowfire 1.2  :shock 1.25   :anti-shock  1   :bind  1    :reatreat 1     :pursue   1.2  :siege   1}
        :field     {:skirmish 1    :arrowfire 1.2  :shock  1     :anti-shock  1   :bind  1    :reatreat 1     :pursue   1.2  :siege   1}
        :desert    {:skirmish 1    :arrowfire 1.2  :shock  1     :anti-shock  1   :bind  1    :reatreat 1     :pursue   1  :siege   1}
        :trees     {:skirmish 1.5  :arrowfire 0.9  :shock  0.9     :anti-shock  2   :bind  1    :reatreat 1     :pursue  0.9  :siege   1}
        :ocean     {:skirmish 1    :arrowfire 1    :shock  1     :anti-shock  1   :bind  1    :reatreat 1     :pursue   1  :siege   1}
        :mountains {:skirmish 2    :arrowfire 1    :shock  0.25  :anti-shock  2   :bind  0.25 :reatreat 0.25  :pursue 0.25 :siege 0.25}
        :crossing  {:skirmish 0.8  :arrowfire 1.2  :shock 0.5   :anti-shock  1   :bind  0.8  :reatreat 0.5    :pursue 0.7  :siege 0.5}
        :flanked   {:skirmish 1.2  :arrowfire 1.2  :shock 1   :anti-shock  1   :bind  1.5  :reatreat 1.2    :pursue 2  :siege 1.2}} ;; the defender is flanked (i.e. oposite 3 sides)
       )

(local terrain-defence-stats-effects ;; multiplicitive
       {:hills     {:skirmish 1.3  :arrowfire 1.1  :shock 0.75   :anti-shock  1.2   :bind  1.2  :reatreat 1.2  :pursue  0.7  :siege 1}
        :grass     {:skirmish 1    :arrowfire 1.2  :shock 1.1   :anti-shock  1   :bind  1    :reatreat 1     :pursue   1.1  :siege   1}
        :field     {:skirmish 1    :arrowfire 1.2  :shock  1     :anti-shock  1   :bind  1    :reatreat 1     :pursue  1.1 :siege   1}
        :desert    {:skirmish 1    :arrowfire 1.2  :shock  1     :anti-shock  1   :bind  1    :reatreat 1     :pursue   1  :siege   1}
        :trees     {:skirmish 1.5  :arrowfire 0.9  :shock  0.9     :anti-shock  2   :bind  1    :reatreat 1     :pursue  0.9  :siege   1}
        :ocean     {:skirmish 1    :arrowfire 1    :shock  1     :anti-shock  1   :bind  1    :reatreat 1     :pursue   1  :siege   1}
        :mountains {:skirmish 2    :arrowfire 1    :shock  0.25  :anti-shock  2   :bind  0.25 :reatreat 0.25  :pursue 0.25 :siege 1}
        :crossing  {:skirmish 1.2  :arrowfire 1.3  :shock  1   :anti-shock  1.1   :bind  1.3  :reatreat 1.25    :pursue 0.7  :siege 1}
        :flanked   {:skirmish 1  :arrowfire 1  :shock 1   :anti-shock  1   :bind  0.9  :reatreat 0.8    :pursue 0.75  :siege 1}})

(local leader-stats-effects ;; multiplicitive
       {:coward        {:skirmish 1  :arrowfire 1      :shock 1   :anti-shock  1   :bind  0.9  :reatreat 1.1  :pursue 1  :siege 1}
        :chaser        {:skirmish 1    :arrowfire 1  :shock 1   :anti-shock  1   :bind  1    :reatreat 0.8     :pursue   1.2  :siege   1}
        :flanker       {:skirmish 1    :arrowfire 1    :shock  1.2     :anti-shock  0.9   :bind  0.9    :reatreat 1     :pursue   1.2  :siege   1}
        :siege-captain {:skirmish 1    :arrowfire 1  :shock  0.8     :anti-shock  1.4   :bind  0.9    :reatreat 0.9     :pursue   0.8  :siege   1.2}
        :skirmisher    {:skirmish 1.6  :arrowfire 0.9  :shock  0.9     :anti-shock  0.9   :bind  0.9    :reatreat 0.9     :pursue  0.9  :siege   1}
        :knight        {:skirmish 0.8    :arrowfire 0.8    :shock  1.4     :anti-shock  1   :bind  1    :reatreat 1     :pursue   1  :siege   1}
        :pikeman       {:skirmish 1    :arrowfire 1    :shock  0.8  :anti-shock  1.2   :bind  1 :reatreat 1  :pursue 1 :siege 1}
        :hero      {:skirmish 1    :arrowfire 1    :shock  1  :anti-shock  1   :bind  1 :reatreat 1  :pursue 1 :siege 1}
        :default      {:skirmish 1    :arrowfire 1    :shock  1  :anti-shock  1   :bind  1 :reatreat 1  :pursue 1 :siege 1}
        }
       )

(local unit-stats-effects ;; multiplicitive
       {:fresh         {:skirmish 1    :arrowfire 1  :shock 1   :anti-shock  0.7   :bind  0.7  :reatreat 2  :pursue 0.6  :siege 1}
        :light         {:skirmish 1.2    :arrowfire 1.2  :shock 0.8   :anti-shock  0.8   :bind  0.8    :reatreat 1.2     :pursue   1  :siege   1}
        :vetran        {:skirmish 1.1    :arrowfire 1.1    :shock  1.2     :anti-shock 1.2   :bind  1.2    :reatreat 1     :pursue   1  :siege   1}
        :default      {:skirmish 1    :arrowfire 1    :shock  1  :anti-shock  1   :bind  1 :reatreat 1  :pursue 1 :siege 1}
        :easy        {:skirmish 0.8    :arrowfire 0.8    :shock  0.8  :anti-shock  0.8   :bind  0.8 :reatreat 0.8  :pursue 0.8 :siege 0.8}
        :hard        {:skirmish 1.2    :arrowfire 1.2    :shock  1.2  :anti-shock  1.2   :bind  1.2  :reatreat 1.2  :pursue 1.2 :siege 1.2}
        }
       )

(local gambit-stats-effects ;; multiplicitive
       {:pikesdown        {:skirmish 1    :arrowfire 1    :shock 1   :anti-shock  1.2   :bind  1   :reatreat 1  :pursue 1  :siege 1}
        :fumble-weapons   {:skirmish 1    :arrowfire 1    :shock 1   :anti-shock  0.8   :bind  0.8  :reatreat 1  :pursue 1  :siege 1}
        :slingmud         {:skirmish 1    :arrowfire 1    :shock 0.6   :anti-shock  1   :bind  1    :reatreat 1     :pursue   1  :siege   1}
        :inspire-horse    {:skirmish 1    :arrowfire 1    :shock 1.2   :anti-shock  1   :bind  1    :reatreat 1     :pursue   1  :siege   1}
        :sheildwall       {:skirmish 1    :arrowfire 1    :shock 1   :anti-shock  1   :bind  1.2    :reatreat 1     :pursue   1  :siege   1}
        :force-center      {:skirmish 1    :arrowfire 1    :shock 1   :anti-shock  1.2   :bind  1.2    :reatreat 1     :pursue   1  :siege   1}
        :holdflanks       {:skirmish 1    :arrowfire 1    :shock 1   :anti-shock  1.4   :bind  1    :reatreat 1     :pursue   1  :siege   1}
        :default          {:skirmish 1    :arrowfire 1    :shock 1   :anti-shock  1   :bind  1    :reatreat 1     :pursue   1  :siege   1}
        }
       )

(local battle-transform-table
       {:light-infantry  {:hold {:hold 0 :skirmish 10}}
        :archers         {:hold {:hold 5 :skirmish 5}   :skirmish   {:hold 5 :skirmish 5}}
        :heavy-infantry  {:hold {:skirmish 4 :charge 6 :hold 0} :skirmish   {:skirmish 5 :charge 5 }}
        :pike            {:hold {:hold 10 :skirmish 0}}
        :cavalry         {:hold {:skirmish 2 :charge 8 :hold 0} :skirmish   {:skirmish 5 :charge 5 }}
        :engineer           {}
        })

(local siege-defence-transform-table
       {:light-infantry  {:hold {:hold 5 :sally 5}}
        :archers         {}
        :heavy-infantry  {:hold {:hold 8 :sally 2}}
        :pike            {}
        :cavalry         {:hold {:hold 8 :sally 2}}
        :engineer           {}
        })

(local siege-offence-transform-table
       {:light-infantry  {}
        :archers         {}
        :heavy-infantry  {}
        :pike            {}
        :cavalry         {}
        :engineer           {:hold {:hold 5 :siege 10} :siege {:hold 5 :siege 10}}
        })

(local bind-transform-table
       {
        :hold     {:hold  0 :skirmish  0 :charge 0  :bind 10 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :skirmish {:hold  0 :skirmish  0 :charge 0  :bind 10 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :charge   {:hold  0 :skirmish  0 :charge 0  :bind 10 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :bind     {:hold  0 :skirmish  0 :charge 0  :bind 10 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :pursue   {:hold  0 :skirmish  0 :charge 0  :bind 10 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :retreat  {:hold  0 :skirmish  0 :charge 0  :bind 10 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :break    {:hold  0 :skirmish  0 :charge 0  :bind 10 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :sally    {:hold  0 :skirmish  0 :charge 0  :bind 10 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
        :siege    {:hold  0 :skirmish  0 :charge 0  :bind 10 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}})


(local break-transform-table
       {
        :hold     {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 10 :sally 0 :siege  0}
        :skirmish {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 10 :sally 0 :siege  0}
        :charge   {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 10 :sally 0 :siege  0}
        :bind     {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 10 :sally 0 :siege  0}
        :pursue  {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 10 :sally 0 :siege  0}
        :retreat  {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 10 :sally 0 :siege  0}
        :break    {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 10 :sally 0 :siege  0}
        :sally    {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 10 :sally 0 :siege  0}
        :siege    {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 10 :sally 0 :siege  0}})

(local retreat-transform-table
       {
        :hold     {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat 10 :break 0 :sally 0 :siege  0}
        :skirmish {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat 10 :break 0 :sally 0 :siege  0}
        :charge   {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat 10 :break 0 :sally 0 :siege  0}
        :bind     {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat 10 :break 0 :sally 0 :siege  0}
        :pursue  {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat 10 :break 0 :sally 0 :siege  0}
        :retreat  {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat 10 :break 0 :sally 0 :siege  0}
        :break    {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat 10 :break 0 :sally 0 :siege  0}
        :sally    {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat 10 :break 0 :sally 0 :siege  0}
        :siege    {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat 10 :break 0 :sally 0 :siege  0}})

(local hold-transform-table
       {
        :hold     {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 0 :sally 0 :siege  0}
        :skirmish {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 0 :sally 0 :siege  0}
        :charge   {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 0 :sally 0 :siege  0}
        :bind     {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 0 :sally 0 :siege  0}
        :pursue  {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 0 :sally 0 :siege  0}
        :retreat  {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 0 :sally 0 :siege  0}
        :break    {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 0 :sally 0 :siege  0}
        :sally    {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 0 :sally 0 :siege  0}
        :siege    {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break 0 :sally 0 :siege  0}})



(local pursue-transform-table
       {
        :hold     {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue 10 :retreat  0 :break  0 :sally 0 :siege  0}
        :skirmish {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue 10 :retreat  0 :break  0 :sally 0 :siege  0}
        :charge   {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue 10 :retreat  0 :break  0 :sally 0 :siege  0}
        :pursue  {:hold  0 :skirmish  0 :charge 0  :bind  0 :pursue 10 :retreat  0 :break  0 :sally 0 :siege  0}
})


(local charge-transform-table
       {
        :charge   {:hold 10 :skirmish  0 :charge 0  :bind  0 :pursue  0 :retreat  0 :break  0 :sally 0 :siege  0}
})


(local unit-types {:light-infantry  true
                   :archers true
                   :heavy-infantry true
                   :pike true
                   :cavalry true  
                   :engineer true
                   })

(fn make-transform [name stats-tab state-change-tab op callback?]
  (fn [army stats state-change]
    (var cont true)
    (when callback? (set cont (callback? army)))
    (when cont
      (when state-change-tab
        (table.insert army.transform-history name)
        (table.insert army.transform-history-table state-change-tab)
        (each [from data (pairs state-change-tab)]
          (each [to value (pairs data)]
          (if (. unit-types from)
              ;; if targeted to a unit apply only to that unit
              (when (= from army.army-type)
                (let [from-p to]
                  (each [to-p new-value (pairs value)]
                    (tset state-change from-p to-p (op (. state-change from-p to-p) new-value))
                    ))
                )
              (let [new-value (op (. state-change from to) value)]
                (tset state-change from to new-value))))))
      (when (. stats-tab army.army-type)
        (let [stat-tab (. stats-tab army.army-type)]
          (each [key value (pairs stat-tab)]
            (tset stats key (op (. state-change key) value))))))
    (values army stats state-change)))

(fn replace [a b] b)
(fn add [a b] (+ a b))
(fn mul [a b] (* a b))
(local battle-transform (make-transform :battle {} battle-transform-table replace))
(local siege-defence-transform (make-transform :siege-o {} siege-defence-transform-table replace))
(local siege-offence-transform (make-transform :siege-d {} siege-offence-transform-table replace))
(local bind-transform (make-transform :bind {} bind-transform-table replace))
(local break-transform (make-transform :break {} break-transform-table replace))
(local pursue-transform (make-transform :pursue {} pursue-transform-table replace))
(local charge-transform (make-transform :charge {} charge-transform-table replace))
(local hold-transform (make-transform :hold {} hold-transform-table replace))
(local retreat-transform (make-transform :retreat {} retreat-transform-table replace))

(fn make-terrain-transform [side terrain-type]
  (make-transform (.. :terrain- side)
                      (if :offence
                          (. terrain-offence-stats-effects terrain-type)
                          (. terrain-defence-stats-effects terrain-type)
                          )
                      {}
                      mul))

(local terrain-transform (collect [_ key (ipairs [:hills :grass :field :desert :trees :ocean
                                                  :mountains :crossing :flanked])]
                           (values key {:offence (make-terrain-transform :offence key)
                                        :defence (make-terrain-transform :offence key)})))

(fn make-stats-transform [name tab]
  (collect [subname subtab (pairs tab)]
    (values subname (make-transform (.. name :- subname) subtab {} mul))))

(local leader-transform (make-stats-transform :leader leader-stats-effects))

(local unit-transform (make-stats-transform :leader unit-stats-effects))

(local gambit-transform (make-stats-transform :gambit gambit-stats-effects))

;; a serize of named transform functions that can be applied to individual units
(local modifier-transform-table {})

(local (cavalry-charge-rounds infantry-charge-rounds) (values 2 3))

(local (cavalry-break-rounds infantry-break-rounds) (values 3 4))

(local energy-costs {:hold -10 :skirmish 10 :charge 15 :bind 5 :pursue 20
                     :retreat 0 :break 0 :sally 33 :siege 25})

;; skills impact damage and moral
(local damage-multiplier {:skirmish 1
                          :arrowfire 0.5
                          :shock 3
                          :anti-shock 4 ;; pikes fucking hurt man
                          :bind 1
                          :pursue 2
                          :break 0.25 ;; this is the multiplier the broken unit applies
                          })

(local moral-multiplier {:skirmish 1
                         :arrowfire 1
                         :shock 2
                         :anti-shock 2
                         :bind 0.5
                         :pursue 8
                         :break 0 ;; no moral cost to chase
                         })

(local gambit {})
(local army {})

(fn apply-to-all-armies [armies fun ...]
  (each [_ army (ipairs armies)]
    (fun army ...)))

;; refactor
(fn gambit.increase-energy-generator [name value period other-army?]
  (fn [_sim our-army their-army]
    (if other-army?
        (apply-to-all-armies their-army army.increase-energy value)
        (apply-to-all-armies our-army army.increase-energy value))
    (values name value period other-army?)))

(fn gambit.increase-moral-generator [name value period other-army?]
  (fn [_sim our-army their-army]
    (if other-army?
        (apply-to-all-armies their-army army.increase-moral value)
        (apply-to-all-armies our-army army.increase-moral value))
    (values name value period other-army?)))

(fn gambit.increase-manpower-generator [name value period other-army?]
  (fn [_sim our-army their-army]
    (if other-army?
        (apply-to-all-armies their-army army.increase-manpower value)
        (apply-to-all-armies our-army army.increase-manpower value))
    (values name value period other-army?)
    ))

(fn gambit.set-gambit-stat-bonus [name value period other-army?]
  (fn [_sim our-army their-army]
    (if other-army?
        (apply-to-all-armies their-army army.set-gambit-stat-bonus value period)
        (apply-to-all-armies our-army army.set-gambit-stat-bonus value period))
    (values name value period other-army?)
    ))

(local gambits
       {:force-center   {:odds 0.8
                         :good (gambit.set-gambit-stat-bonus :force-center :force-center 2)
                         :bad (gambit.increase-energy-generator :force-center -10 1)
                         }
        :pivot-left     {:odds 0.7
                         :good (gambit.set-gambit-stat-bonus :pivot-left :holdflanks 4)
                         :bad (gambit.increase-energy-generator :pivot-left -10 1)
                         }
        :lower-pikes    {:odds 0.9
                         :good (gambit.set-gambit-stat-bonus :lower-pikes :pikesdown 4)
                         :bad  (gambit.set-gambit-stat-bonus :lower-pikes :fumble-weapons 8)
                         }
        :burst-pustules {:odds 0.5
                         :good (gambit.increase-moral-generator :burst-pustules -20 1 true)
                         :bad  (gambit.increase-manpower-generator :burst-pustules -20 1)
                         }
        :slag-off       {:odds 0.7
                         :good (gambit.increase-moral-generator :slag-off -20 1 true)
                         :bad  (gambit.increase-energy-generator :slag-off -20 1)
                         }
        :raise-flag     {:odds 0.5
                         :good (gambit.increase-moral-generator :raise-flag 20 1)     ;; the flag ralies the trools
                         :bad (gambit.increase-moral-generator :raise-flag 20 1 true) ;; the enemy thinks you are retreating
                         }
        :eat-mushrooms  {:odds 0.5
                         :good (gambit.increase-energy-generator :eat-mushrooms 20 1) ;; revitalizing mushrooms
                         :bad  (gambit.increase-moral-generator :eat-mushrooms -20 1)  ;; bad trip
                         }
        })

(fn call-gambit [sim gambit-name our-army their-army]
  (let [{: odds : good : bad} (or (. gambits gambit-name) {})
        roll (math.random 1)]
    (when odds
      (if (< odds roll)
          (values :good (good sim our-army their-army)) ;; returns (name value period other-army?)
          (values :bad (bad sim our-army their-army))))))


(local lume (require :lib.lume))
(local {: deep-clone} (require :src.utils))

(fn apply-transforms [chain ar stats state-change]
  (if (= (# chain) 0) (values ar stats state-change)
      (let [action (. chain 1)]
        (table.remove chain 1)
        (apply-transforms chain (action ar stats state-change)))))

(fn army.next-state [ar transform-chains]
  (local (_ stats state-changes)
         (let [(_ stats state-changes) (apply-transforms
                                        (. transform-chains ar.i)
                                        ar
                                        (deep-clone (. stats ar.army-type) 1)
                                        (deep-clone base-state-changes 2))]
           ;; pain in the ass if the unit doesn't have enough energy to repeat its action
           ;; it should rest. there is an issue with charge I need to figure out
           (if (army.insufficient-energy? ar (. state-changes ar.state) energy-costs)
               (apply-transforms
                [hold-transform]
                ar
                (deep-clone (. stats ar.army-type) 1)
                (deep-clone base-state-changes 2))
               (values ar stats state-changes))))
  ;; apply energy restrictions here.
  (local previous-state ar.state)
  (local next-state (lume.weightedchoice (. state-changes ar.state)))
  (set ar.stats stats)
  (set ar.state next-state)
  (set ar.arrowfire (if (and (= ar.state :hold) (> (. stats :arrowfire) 0)) true false))
  (values ar next-state previous-state))

(fn army.increase-energy [ar value]
  (set ar.energy-impact (+ ar.energy-impact value)))

(fn army.increase-moral [ar value]
  (set ar.moral-impact (+ ar.moral-impact value)))

(fn army.increase-manpower [ar value]
  (set ar.manpower-impact (+ ar.manpower-impact value)))

(fn army.set-gambit-stat-bonus [ar bonus period]
  (tset ar.gambit-stat-bonus bonus period))

(fn army.increase-energy [ar value])

(fn army.calculate-costs [army]
  (let [expended (. energy-costs army.state)]
    (set army.energy-impact (+ army.energy-impact expended))
    army
    ))

(fn army.apply-damage-moral-cost [army]
  (set army.pervious-energy army.energy)
  (set army.pervious-manpower army.manpower)
  (set army.pervious-moral army.moral)
  (set army.energy (math.max 0 (math.min army.max-energy (- army.energy army.energy-impact))))
  (set army.manpower (math.max 0 (- army.manpower army.manpower-impact)))
  (set army.moral (math.max 0 (- army.moral army.moral-impact)))
    army)

(fn army.reset-impacts [army]
  ;; (pp army.transform-history)
  (lume.clear army.transform-history)
  (lume.clear army.transform-history-table)
  (set army.energy-impact 0)
  (set army.manpower-impact 0)
  (set army.moral-impact 0)
  army)

(fn army.broken? [army bound]
  (or (and (= army.energy 0) (= army.state :bound)) (= army.moral 0)))

(fn army.pursue? [army]
  (> army.stats.pursue 0))

(fn army.eliminated? [army]
  ;; classified as "retreated"
  (= army.manpower 0))

(fn army.insufficient-energy? [army state-changes energy-cost]
  (accumulate [ret true name _ (pairs state-changes)]
    (if (> army.energy (. energy-cost name) ) false ret)))

(fn army.exhausted? [army]
  (= army.energy 0) )

(fn army.retreat? [army]
  (or army.break-complete (= army.manpower 0)))

(fn army.bound? [army bound]
  (and (and army.stats.bindable bound)))

(fn army.maintain-bind? [ar]
  (and ar.stats.bindable
       (~= ar.moral 0)
       (~= ar.energy 0)
       (~= ar.manpower 0)
       ))

(fn army.charge-over? [army]
  (and (= army.state :charge) army.charge-complete))

(fn army.update [ar bound]
  ;; call at the end of tick
  ;; incr broken
  (when (and (army.broken? ar bound) (not army.break-complete))
    (set ar.break-round (+ ar.break-round 1))
    (when (= ar.break-round ar.break-rounds-required)
      (set ar.break-complete true)))
  ;; reset charge turn to 0 if charge over
  (if (= ar.state :charge)
      (do (set ar.charge-round (+ 1 ar.charge-round))
        (when (> ar.charge-round (+ 0 ar.charge-rounds-required))
          (set ar.charge-round 1)
          (set ar.charge-complete true)
          ))
    (set ar.charge-complete false))

  (each [gambit time (pairs ar.gambit-stat-bonus)]
    (tset  ar.gambit-stat-bonus gambit (- time 1))
    (when (<= (- time 1) 0)
      ;; this may mess up pairs
      (tset ar.gambit-stat-bonus gambit nil)))
  
  (if (army.pursue? ar) (set ar.info.pursue true))
  (if (army.broken? ar) (set ar.info.broken true))
  (if (army.exhausted? ar) (set ar.info.exhausted true))
  (if (army.bound? ar bound) (set ar.info.bound true))
  (if (army.retreat? ar) (set ar.info.retreat true))
  ;; overwrite all info if army is dead
    (if (army.eliminated? ar)
      (set ar.info.eliminated true)
      (set ar.info.exhausted false)
      (set ar.info.broken false)
      (set ar.info.bound false)
      (set ar.info.retreat false)
      (set ar.info.pursue false))
  )

;; army type, modifier, moral, manpower, energy + stats
(fn load-army [army-type modifier moral manpower energy i]
  (local stats (deep-clone (. stats army-type ) 1))
  ;; (local state-changes (deep-clone base-state-changes 2))
  {:state :hold
   : stats
   : i
   :charge-round 1
   :charge-rounds-required (if (= army-type :cavalry) cavalry-charge-rounds infantry-charge-rounds)
   :charge-complete false
   :break-round 1
   :break-rounds-required (if (= army-type :cavalry) cavalry-break-rounds infantry-break-rounds)
   :break-complete false
   :info {:broken false  ;; used for visualization purposes
          :eliminated false
          :retreat false
          :exhausted false
          :bound false}
   :max-energy energy
   :transform-history []
   :transform-history-table []
   :original-stats (lume.clone stats)
   :moral-impact 0
   :energy-impact 0
   :manpower-impact 0
   :previous-moral moral
   :previous-energy energy
   :previous-manpower manpower
   :gambit-stat-bonus {}
   : army-type : modifier : moral : manpower : energy})




;; army: army-type modifier moral manpower energy
;; leader: modifier gambit
;; modifiers: modifier {:defender :attacker}
(local simulation {})
(fn simulation.example [defending-army-types attacking-army-types fortress-level terrain flanked crossing feature]
  (let [defending-unit {:leader {:modifier :default :gambits {:force-center 1 :pivot-left 1 :lower-pikes 1
                                                              :burst-pustules 1 :slag-off 1 :raise-flag 1
                                                              :eat-mushrooms 1}}
                        :armies (icollect [_ army-type (ipairs defending-army-types)]
                                  {:army-type army-type :modifier :default :moral 100 :manpower 100
                                              :energy 100})}
        attacking-unit {:leader {:modifier :default :gambits {:force-center 1 :pivot-left 1 :lower-pikes 1
                                                              :burst-pustules 1 :slag-off 1 :raise-flag 1
                                                              :eat-mushrooms 1}}
                        :armies (icollect [_ army-type (ipairs attacking-army-types)]
                                             {:army-type army-type :modifier :default :moral 100 :manpower 100
                                              :energy 100})}
        combat-modifiers {:defence [] :offence []}]
    (simulation.load defending-unit attacking-unit combat-modifiers fortress-level terrain flanked crossing feature))
  )

(fn simulation.load [defending-unit attacking-unit combat-modifiers fortress-level terrain flanked crossing feature]
  (let [{:leader defence-leader :armies defence-army-values} defending-unit
        {:leader offence-leader :armies offence-army-values} attacking-unit
        siege (> fortress-level 0)
        defence-modifiers combat-modifiers.defence
        offence-modifiers combat-modifiers.offence
        defence-armies (icollect [i {: army-type : modifier : moral : manpower : energy} (ipairs defence-army-values)]
                         (load-army army-type modifier moral manpower energy i))
        offence-armies (icollect [i {: army-type : modifier : moral : manpower : energy} (ipairs offence-army-values)]
                         (load-army army-type modifier moral manpower energy i))        
        ]
    {: offence-armies : defence-armies : siege
     : offence-leader : defence-leader 
     : offence-modifiers : defence-modifiers
     : fortress-level
     :charge-event false
     :bind-event false
     :turn 1
     :bind false
     ;; these will impact stats
     : terrain
     : flanked
     : feature ;; not implemented
     : crossing
     :offence-active-gambits []
     :defence-active-gambits []
     :_debug-log ""
     }
    )
  )

;; absolute-transforms
(fn unit-transforms [sim side transform-chains]
  (let [armies (. sim side)]
    (each [i _ar (ipairs armies)]
      (let [tab (. transform-chains i)]
        (if sim.siege
            (table.insert tab (if (= side :offence-armies) siege-offence-transform siege-defence-transform))
            (table.insert tab battle-transform)
            ))))
  transform-chains)

(fn charge-transforms [sim offensive-transform-chains defensive-transform-chains]
  ;; if an army has sucesfully completed their charge, have them hold
  (let [armies (. sim :offence-armies)]
    (each [i ar (ipairs armies)]
      (when (army.charge-over? ar) (table.insert (. offensive-transform-chains i) charge-transform))))
  (let [armies (. sim :defence-armies)]
    (each [i ar (ipairs armies)]
      (when (army.charge-over? ar) (table.insert (. defensive-transform-chains i) charge-transform))))
  (values offensive-transform-chains defensive-transform-chains)
  )

(fn pursue-transforms [sim offensive-transform-chains defensive-transform-chains]
  (fn any-broken [armies]
    (accumulate [ret false _ ar (ipairs armies)] (if (and (army.broken? ar) (not ar.broken-complete)) true ret)))
  (let [armies (. sim :offence-armies)
        broken (any-broken sim.defence-armies)]
    (when broken
      (each [i ar (ipairs armies)]
        (when (army.pursue? ar) (table.insert (. offensive-transform-chains i) pursue-transform)))))
  (let [armies (. sim :defence-armies)
        broken (any-broken sim.offence-armies)]
    (when broken
      (each [i ar (ipairs armies)]
        (when (army.pursue? ar) (table.insert (. defensive-transform-chains i) pursue-transform)))))
  
  (values offensive-transform-chains defensive-transform-chains)
  )

(fn bind-transforms [sim offensive-transform-chains defensive-transform-chains]
  ;; bind-transform
  (when sim.bind
    (let [armies (. sim :offence-armies)]
      (each [i ar (ipairs armies)]
        (when (army.bound? ar sim.bind) (table.insert (. offensive-transform-chains i) bind-transform))))
    (let [armies (. sim :defence-armies)]
      (each [i ar (ipairs armies)]
        (when (army.bound? ar sim.bind) (table.insert (. defensive-transform-chains i) bind-transform)))))
  (values offensive-transform-chains defensive-transform-chains))

(fn exhausted-transforms [sim offensive-transform-chains defensive-transform-chains]
  (let [armies (. sim :offence-armies)]
    (each [i ar (ipairs armies)]
      ;; (local energy-transform-table {:hold (collect [to cost (pairs energy-costs)] (values to (if (> cost ar.energy) 0 1)))})
      ;; this is multiplicitive to set to 0 in the case where there is not enough
      ;; energy for the action

      (when (and (army.exhausted? ar) (not (army.bound? ar sim.bind)))
        (table.insert (. offensive-transform-chains i) hold-transform))))
  (let [armies (. sim :defence-armies)]
    (each [i ar (ipairs armies)]
      ;; (local energy-transform-table {:hold (collect [to cost (pairs energy-costs)] (values to (if (> cost ar.energy) 0 1)))})
      ;; this is multiplicitive to set to 0 in the case where there is not enough
      ;; energy for the action
      (when (and (army.exhausted? ar) (not (army.bound? ar sim.bind)))
        (table.insert (. defensive-transform-chains i) hold-transform))))
  (values offensive-transform-chains defensive-transform-chains))

(fn break-transforms [sim offensive-transform-chains defensive-transform-chains]
  (let [armies (. sim :offence-armies)]
    (each [i ar (ipairs armies)]
      (when (army.broken? ar sim.bind)
        (if ar.broken-complete
            (table.insert (. defensive-transform-chains i) retreat-transform)
            (table.insert (. offensive-transform-chains i) break-transform)))))
  (let [armies (. sim :defence-armies)]
    (each [i ar (ipairs armies)]
      (when (army.broken? ar sim.bind)
        (if ar.broken-complete
            (table.insert (. defensive-transform-chains i) retreat-transform)
            (table.insert (. defensive-transform-chains i) break-transform)))))
  (values offensive-transform-chains defensive-transform-chains)
  )

(fn dead-transforms [sim offensive-transform-chains defensive-transform-chains]
  (let [armies (. sim :offence-armies)]
    (each [i ar (ipairs armies)]
      (when (army.retreat? ar sim.bind) 
        (table.insert (. offensive-transform-chains i) retreat-transform))))
  (let [armies (. sim :defence-armies)]
    (each [i ar (ipairs armies)]
      (when (army.retreat? ar sim.bind) 
        (table.insert (. defensive-transform-chains i) retreat-transform))))
  (values offensive-transform-chains defensive-transform-chains)
  )


(fn terrain-transforms [sim offensive-transform-chains defensive-transform-chains]
  ;; these can be % based
  (let [armies (. sim :offence-armies)]
    (each [i ar (ipairs armies)]
      (let [tab (. offensive-transform-chains i)]
        (when sim.flanked (table.insert tab (. terrain-transform :flanked :offence)))
        (when sim.crossing (table.insert tab (. terrain-transform :crossing :offence)))
        (when sim.terrain (table.insert tab (. terrain-transform sim.terrain :offence))))))
  (let [armies (. sim :defence-armies)]
    (each [i ar (ipairs armies)]
      (let [tab (. defensive-transform-chains i)]
        (when sim.flanked (table.insert tab (. terrain-transform :flanked :defence)))
        (when sim.crossing (table.insert tab (. terrain-transform :crossing :defence)))
        (when sim.terrain (table.insert tab (. terrain-transform sim.terrain :defence))))))
  (values offensive-transform-chains defensive-transform-chains))

(fn individual-transforms [sim offensive-transform-chains defensive-transform-chains]
  ;; these can be % based
  (let [armies (. sim :offence-armies)]
    (each [i ar (ipairs armies)]
      (let [tab (. offensive-transform-chains i)]        
        (when (. unit-transform ar.modifier) (table.insert tab (. unit-transform ar.modifier))))))
  (let [armies (. sim :defence-armies)]
    (each [i ar (ipairs armies)]
      (let [tab (. defensive-transform-chains i)]
        (when (. unit-transform ar.modifier) (table.insert tab (. unit-transform ar.modifier))))))
  (values offensive-transform-chains defensive-transform-chains))

(fn leader-transforms [sim offensive-transform-chains defensive-transform-chains]
    (let [armies (. sim :offence-armies)]
    (each [i ar (ipairs armies)]
      (let [tab (. offensive-transform-chains i)]
        (when (. leader-transform sim.offence-leader.modifier)
          (table.insert tab (. leader-transform sim.offence-leader.modifier)))
        (each [gambit time (pairs ar.gambit-stat-bonus)]
          (when (and time (> time 0) (. gambit-transform gambit))
            (table.insert tab (. gambit-transform gambit))))
        )))
  (let [armies (. sim :defence-armies)]
    (each [i ar (ipairs armies)]
      (let [tab (. defensive-transform-chains i)]
        (when (. leader-transform sim.defence-leader.modifier)
          (table.insert tab (. leader-transform sim.defence-leader.modifier)))
        (each [gambit time (pairs ar.gambit-stat-bonus)]
          (when (and time (> time 0) (. gambit-transform gambit))
            (table.insert tab (. gambit-transform gambit)))))))
  (values offensive-transform-chains defensive-transform-chains))


(fn simulation.tick [sim]
  (when (<= sim.fortress-level 0) (set sim.siege false))

  ;; check state and assemble transform-chain
  ;; check break
  ;; if enemy break set pursue-transform last
  ;; if turn=9 retreat both sides (break charges)

  ;; order of operations here is important
  ;; replace operations come first in reveres order of importance
  ;; multiplicitave operations come next
  ;; add operations come at the end
  (local
   (offensive-transform-chains defensive-transform-chains)
   (->> (values (unit-transforms sim :offence-armies [[] [] [] []])
                (unit-transforms sim :defence-armies [[] [] [] []]))
        (charge-transforms sim) ;; hold if charge complete (rep)
        (pursue-transforms sim) ;; persue if enemy flees (rep)
        (bind-transforms sim) ;; bind if bound (rep)
        (exhausted-transforms sim) ;; hold if exausted and not bound (rep)
        (break-transforms sim) ;; break if moral or energy is 0 and unit is bound (rep)
        (dead-transforms sim)  ;; set as retreated if unit manpower drops to 0 (rep)
        (terrain-transforms sim) ;; modifiers from terrain and adjacency bonus (mult)
        (individual-transforms sim) ;; special transforms for each individual unit (mult)
        (leader-transforms sim) ;; leader transforms (add)
       ))

  (fn apply-to-armies [sym fun offensive-args defensive-args]
    (each [_ ar (ipairs sim.offence-armies)] (fun ar (when offensive-args (unpack offensive-args))))
    (each [_ ar (ipairs sim.defence-armies)] (fun ar (when defensive-args (unpack defensive-args)))))
  (fn armies-match-state [armies state stat]
    (values
     (icollect [i un (ipairs armies)] (when (= un.state state) i))
     (icollect [_i un (ipairs armies)] (when (= un.state state) un))
     (accumulate [ret 0 _ un (ipairs armies )] (if (= un.state state) (+ ret (. un :stats stat)) ret))))
  (fn type-damage [a t]
    (values (values (* a (. moral-multiplier t)) (* a (. damage-multiplier t)))))
 
  ;; update army states
  (apply-to-armies sim army.next-state [offensive-transform-chains] [defensive-transform-chains])
  ;; (each [_ ar (ipairs sim.offence-armies)]
  ;;   (army.next-state ar offensive-transform-chain))

  ;; (each [_ ar (ipairs sim.defence-armies)]
  ;;   (army.next-state ar defensive-transform-chain))

  ;; reset impacts to 0
  (apply-to-armies sim army.reset-impacts)
  ;; resolve energy, moral and manpower costs based on current army states (without charge)
  (apply-to-armies sim army.calculate-costs)
  ;; (set sim.offence-energy-expended
  ;;       (icollect [_ ar (ipairs sim.offence-armies)] (army.calculate-costs ar)))

  ;; (set sim.defence-energy-expended
  ;;       (icollect [_ ar (ipairs sim.defence-armies)] (army.calculate-costs ar)))
  (set sim._debug-log "DEBUG::\n")
  (fn debug-log [str]
    (local fennel (require :lib.fennel))
    (set sim._debug-log (.. sim._debug-log (fennel.view str) "\n")))

  (fn apply-moral+damage [armies who moralp damagep]
    
    ;; (pp [who moral damage (# armies)])
    ;; cant use flaoting point random numbers in lua puc 5.1
    (let [moral-v (-> (math.random (math.floor (* (* damage-variance 2) 10000)))
                      (/ 10000) (- damage-variance) (+ 1))
          damage-v (-> (math.random (math.floor (* (* damage-variance 2) 10000)))
                      (/ 10000) (- damage-variance) (+ 1))
          moral (* moralp moral-v)
          damage (* damagep damage-v)]
      (match (type who)
        :string (match who :all (let [len (# armies)
                                      damage-applied (math.ceil (/ damage len))
                                      moral-applied (math.ceil (/ moral len))]
                                  (each [_ army (ipairs armies)]
                                    (set army.moral-impact (+ army.moral-impact moral-applied))
                                    (set army.manpower-impact (+ army.manpower-impact damage-applied)))))
        :table (let [len (# who)
                     damage-applied (math.ceil (/ damage len))
                     moral-applied (math.ceil (/ moral len))]
                 (each [_ id (ipairs who)]
                   (tset armies id :moral-impact (+ (. armies id :moral-impact) moral-applied))
                 (tset armies id :manpower-impact (+ (. armies id :manpower-impact) damage-applied))))
        :number (do
                  (tset armies who :moral-impact (+ (. armies who :moral-impact) moral))
                  (tset armies who :manpower-impact (+ (. armies who :manpower-impact) damage))))))
  
  ;; damage skirmishers and those being skirmished
  ;; check if which side has a skirmisher.
  ;; if both resolve damage and moral impact on each other
  ;; if one side, resolve damage and moral impact evenly accross other armies
  (let [(skirm-index-o _t-o skirm-o) (armies-match-state sim.offence-armies :skirmish :skirmish)
        (skirm-index-d _t-d skirm-d) (armies-match-state sim.defence-armies :skirmish :skirmish)]
    (fn skirmish-damage [a d]
      (if (= 0 a) (values 0 0)
          (= 0 d) (values (* a moral-multiplier.skirmish) 0) ;; no defending skirmisher = moral damage to army
           (values 0 (* a damage-multiplier.skirmish)))) ;; only defending skirmishers take a manpower hit
    (debug-log [:skirmish skirm-index-o skirm-o skirm-index-d skirm-d])
    (apply-moral+damage sim.defence-armies (if (= skirm-d 0) :all skirm-index-d) (skirmish-damage skirm-o skirm-d))
    (apply-moral+damage sim.offence-armies (if (= skirm-o 0) :all skirm-index-o) (skirmish-damage skirm-d skirm-o)))
  
  ;; damage those charging if arrowfire
  ;; if unit charging and opponent has unit with arrowfire available apply
  ;; damage and moral impact to charger
  ;; damage and moral not split amongs chargers but applied in full to all
  (let [charging-table-o (accumulate [ret [] i un (ipairs sim.offence-armies)]
                           (if (= un.state :charge)
                               (if (~= (type ret) :table)
                                       [i]
                                       (do (table.insert ret i) ret))
                               ret))
        arrowfire-o (accumulate [ret 0 _i un (ipairs sim.offence-armies)] (if (and (= un.state :hold) (> un.stats.arrowfire 0)) (+ ret un.stats.arrowfire) ret))
        charging-table-d (accumulate [ret [] i un (ipairs sim.defence-armies)]
                           (if (= un.state :charge)
                               (if (~= (type ret) :table)
                                       [i]
                                       (do (table.insert ret i) ret))
                               ret))
        arrowfire-d (accumulate [ret 0 _i un (ipairs sim.defence-armies)] (if (and (= un.state :hold) (> un.stats.arrowfire 0)) (+ ret un.stats.arrowfire) ret))]
    (debug-log [:arrowfire charging-table-o arrowfire-o charging-table-d arrowfire-d])
    (apply-moral+damage sim.defence-armies charging-table-d (type-damage arrowfire-o :arrowfire))
    (apply-moral+damage sim.offence-armies charging-table-o (type-damage arrowfire-d :arrowfire)))
  
  ;; damage charge resolution
  ;; upon charge completion apply charge damage and moral impact to opponent 
  ;; across other armies
  ;; take anti-shock damage and moral impact based on average opponent anti-shock value
  ;; anti-shock of units also charging is 0
  (let [[charging-table-o shock-o] ;; charging
        (accumulate [ret [[] 0] i un (ipairs sim.offence-armies)]
          (if (and (= un.state :charge) (= un.charge-round un.charge-rounds-required))
              (let [[units value] ret]
                (table.insert units i)
                [units (+ value un.stats.shock)])
              ret))
        [charged-table-o charged-anti-shock-o] (accumulate [ret [[] 0] _i un (ipairs sim.offence-armies)]
                                                 (if (and (> un.stats.anti-shock 0) (~= un.state :charge))
                                                     (let [[units value] ret]
                                                       (table.insert units un)
                                                       [units (+ value un.stats.anti-shock)])
                                                     ret))
        anti-shock-o (if (= (# charged-table-o) 0) 0 (/ charged-anti-shock-o (# charged-table-o)))

        [charging-table-d shock-d]
        (accumulate [ret [[] 0] i un (ipairs sim.defence-armies)]
          (if (and (= un.state :charge) (= un.charge-round un.charge-rounds-required))
              (let [[units value] ret]
                (table.insert units i)
                [units (+ value un.stats.shock)])
              ret))
        [charged-table-d charged-anti-shock-d] (accumulate [ret [[] 0] _i un (ipairs sim.defence-armies)]
                                                 (if (and (> un.stats.anti-shock 0) (~= un.state :charge))
                                                     (let [[units value] ret]
                                                       (table.insert units un)
                                                       [units (+ value un.stats.anti-shock)])
                                                     ret))
        anti-shock-d (if (= (# charged-table-d) 0) 0 (/ charged-anti-shock-d (# charged-table-d)))
        ]
    (debug-log [:charge charging-table-o shock-o charged-table-o charged-anti-shock-o anti-shock-o charging-table-d shock-d charged-table-d charged-anti-shock-d])
    ;; apply anti-shock damage to charging units
    (apply-moral+damage sim.defence-armies charging-table-d (type-damage anti-shock-o :anti-shock))
    (apply-moral+damage sim.offence-armies charging-table-o (type-damage anti-shock-d :anti-shock))

    ;; apply shock damage to all opponent units
    (apply-moral+damage sim.defence-armies :all (type-damage shock-o :shock))
    (apply-moral+damage sim.offence-armies :all (type-damage shock-d :shock))

    (if (> (+ shock-o shock-d) 0)        
        (set sim.charge-event false)
        (set sim.charge-event true))
    ) ;; charging
  
  ;; damage those bound
  ;; Damage all bindables on both sides by the average bind skill of opponent
  ;; damage is shared accross all units
  (let [bound-table-o (icollect [i un (ipairs sim.offence-armies)] (when (= un.state :bind) un))
        bound-index-o (icollect [i un (ipairs sim.offence-armies)] (when (= un.state :bind) i))
        bound-o (accumulate [ret 0 _ {:stats {: bind}} (ipairs bound-table-o)] (+ ret bind))
        bound-table-d (icollect [i un (ipairs sim.defence-armies)] (when (= un.state :bind) un))
        bound-index-d (icollect [i un (ipairs sim.defence-armies)] (when (= un.state :bind) i))
        bound-d (accumulate [ret 0 _ {:stats {: bind}} (ipairs bound-table-d)] (+ ret bind))]
    (debug-log [:bind bound-table-o bound-index-o bound-o bound-table-d bound-index-d bound-d])
    (apply-moral+damage sim.defence-armies bound-index-d (type-damage bound-o :bind))
    (apply-moral+damage sim.offence-armies bound-index-o (type-damage bound-d :bind)))

  
  ;; damage those who are broken and their who peruse
  ;; All presuewers and those broken are assumed to be in combat. Similar
  ;; to when bound apply damage to both but with modifiers
  (let [pursue-table-o (icollect [i un (ipairs sim.offence-armies)] (when (= un.state :pursue) un))
        pursue-index-o (icollect [i un (ipairs sim.offence-armies)] (when (= un.state :pursue) i))
        pursue-o (accumulate [ret 0 _ {:stats {: pursue}} (ipairs pursue-table-o)] (+ ret pursue))
        break-table-o (icollect [i un (ipairs sim.offence-armies)] (when (= un.state :break) un))
        break-index-o (icollect [i un (ipairs sim.offence-armies)] (when (= un.state :break) i))
        break-o (accumulate [ret 0 _ {:stats {: retreat}} (ipairs break-table-o)] (+ ret retreat))
        
        pursue-table-d (icollect [i un (ipairs sim.defence-armies)] (when (= un.state :pursue) un))
        pursue-index-d (icollect [i un (ipairs sim.defence-armies)] (when (= un.state :pursue) i))
        pursue-d (accumulate [ret 0 _ {:stats {: pursue}} (ipairs pursue-table-d)] (+ ret pursue))
        break-table-d (icollect [i un (ipairs sim.defence-armies)] (when (= un.state :break) un))
        break-index-d (icollect [i un (ipairs sim.defence-armies)] (when (= un.state :break) i))
        break-d (accumulate [ret 0 _ {:stats {: retreat}} (ipairs break-table-d)] (+ ret retreat))
        ]
    (debug-log [:bind break-index-d break-index-o break-d break-d pursue-o pursue-d pursue-index-d pursue-index-o])
    (apply-moral+damage sim.defence-armies break-index-d (type-damage pursue-o :pursue))
    (apply-moral+damage sim.offence-armies break-index-o (type-damage pursue-d :pursue))
    (apply-moral+damage sim.defence-armies pursue-index-d (type-damage break-o :break))
    (apply-moral+damage sim.offence-armies pursue-index-o (type-damage break-d :break))
    )
  
  ;; damage sally and siege + arrowfire
  ;; if sallying damage siege unit and take damage based on the anti-shock rating of the
  ;; army
  ;; All siege is damaged by arrowfire  
  (let [(sally-index _ sally) (armies-match-state sim.defence-armies :sally :sally)
        (_ _ arrowfire) (armies-match-state sim.defence-armies :hold :arrowfire)
        (siege-index _ siege) (armies-match-state sim.offence-armies :siege :siege)
        (_ _ anti-shock) (armies-match-state sim.offence-armies :hold :anti-shock)]
    (debug-log [:sally sally-index sally arrowfire siege-index siege anti-shock])
    (apply-moral+damage sim.defence-armies sally-index (type-damage anti-shock :anti-shock))
    (apply-moral+damage sim.offence-armies siege-index (type-damage sally :shock))
    (apply-moral+damage sim.offence-armies siege-index (type-damage arrowfire :arrowfire)))

  ;; apply-damage moral and cost
  (apply-to-armies sim army.apply-damage-moral-cost)
  
  ;; roll siege and update fortification level
  ;; If siege has not broken, roll for damage on fortification (default 33% per engine)
  (let [(_ _ siege) (armies-match-state sim.offence-armies :siege :siege)
        damaged (> siege (math.random 30))]
    ;; if siege % damage to fortification
    (when damaged (set sim.fortress-level (math.max 0 (- sim.fortress-level 1))))
    ;; if fortification = 0 siege ends and combat begins
    (when (<= sim.fortress-level 0) (set sim.siege false)))
  
  ;; if charge ended  do bind test


  (let [charging-o ;; charging
        (icollect [_i un (ipairs sim.offence-armies)]
            (when (and (= un.state :charge) (= un.charge-round un.charge-rounds-required)) un))
          charging-d ;; charging
          (icollect [_i un (ipairs sim.defence-armies)]
            (when (and (= un.state :charge) (= un.charge-round un.charge-rounds-required)) un))
          ;; charging (lume.merge charging-o charging-d)
          bind-o (accumulate [ret 0 _i ar (ipairs  sim.offence-armies)]
                   (if (army.maintain-bind? ar) (+ ret ar.stats.bind) ret))
          bind-d (accumulate [ret 0 _i ar (ipairs  sim.defence-armies)]
                   (if (army.maintain-bind? ar) (+ ret ar.stats.bind) ret))
        ]
    (var binding-turn false)
    (when (not sim.bind)
      (each [_ charging-unit (ipairs charging-o)]
        (when (and (> charging-unit.stats.bind (math.random 9)) (> bind-d 0))
          ;; aslo need to check if there are any units that may be bound
          (when (not sim.bind)
            (set binding-turn true))
          (set sim.bind true))) ;; one charge initiated a successful bind
      
      (each [_ charging-unit (ipairs charging-d)]
        (when (and (> charging-unit.stats.bind (math.random 9)) (> bind-o 0))
          ;; aslo need to check if there are any units that may be bound
          (when (not sim.bind)
            (set binding-turn true))
          (set sim.bind true))) ;; one charge initiated a successful bind
      )
    (set sim.unbind-event false)
    (when (and (not binding-turn) (or (= 0 bind-o) (= 0 bind-d))) ;; either force has failed and the bind is broken
        (when sim.bind (set sim.unbind-event true))
        (set sim.bind false)))

  ;; gambits, 1/4 chance a gambit will be called when the troops are bound
  (when sim.bind
    (when (and sim.offence-leader.gambits (> (math.random) 0.75))
      (let [gambit-name (lume.weightedchoice sim.offence-leader.gambits)
            (outcome name value period other-army?) (call-gambit sim gambit-name sim.offence-armies sim.defence-armies)]
        (tset sim.offence-active-gambits name  {: outcome : name : value : period : other-army?})
        ))
    (when (and sim.defence-leader.gambits (> (math.random) 0.75))
      (let [gambit-name (lume.weightedchoice sim.defence-leader.gambits)
            (outcome name value period other-army?) (call-gambit sim gambit-name sim.defence-armies sim.offence-armies)]
        (tset sim.defence-active-gambits name  {: outcome : name : value : period : other-army?})
        )))

  ;; increment gambit timers
  (each [gambit-name {: period &as _gam} (pairs sim.offence-active-gambits)]
    (tset sim.offence-active-gambits gambit-name :period (math.max -1 (- period 1))))
  (each [gambit-name {: period &as _gam} (pairs sim.defence-active-gambits)]
    (tset sim.defence-active-gambits gambit-name :period (math.max -1 (- period 1))))
  
  (apply-to-armies sim army.update [sim.bind] [sim.bind])
  (set sim.turn (+ sim.turn 1))
  sim
  )

(fn simulation.overview [sim]
  {:siege sim.siege
   :fortress-level sim.fortress-level
   :bind sim.bind
   :charge sim.charge
   :bind-event sim.bind-event
   :charge-event sim.charge-event
   :turn sim.turn
   :offence-modifier sim.offence-leader.modifier
   :defence-modifier sim.defence-leader.modifier
   :offence-gambits (icollect [_ gambit (pairs sim.offence-active-gambits)] (do
                                                                              (when (>= gambit.period 0) gambit)))
   :defence-gambits (icollect [_ gambit (pairs sim.defence-active-gambits)] (do
                                                                              (when (>= gambit.period 0) gambit)))
   :terrain sim.terrain ;; string
   :crossing sim.crossing
   :flanked sim.flanked
   :feature sim.feature ;; string
   :offence-armies (icollect [_ {: state : energy : manpower : moral : stats : original-stats : info
                                 : army-type : previous-energy : previous-manpower : previous-moral
                                 : energy-impact : manpower-impact : moral-impact : transform-history : modifier}
                              (ipairs sim.offence-armies)]
                     {: state : energy : manpower : moral : info : transform-history
                      : energy-impact : manpower-impact : moral-impact : army-type
                      : previous-energy : previous-manpower : previous-moral : modifier
                      })
   :defence-armies (icollect [_ {: state : energy : manpower : moral : stats : original-stats : info 
                                 : army-type : previous-energy : previous-manpower : previous-moral
                                 : energy-impact : manpower-impact : moral-impact : transform-history : modifier}
                              (ipairs sim.defence-armies)]
                     {: state : energy : manpower : moral : info : transform-history
                      : energy-impact : manpower-impact : moral-impact : army-type
                      : previous-energy : previous-manpower : previous-moral : modifier
                      })
   }
  )

(set simulation.terrains [:mountains :hills :grass :field :desert :trees :ocean])
(set simulation.army-types [:light-infantry :archers :heavy-infantry :pike :engineer])
(set simulation.leader-modifiers (icollect [name _ (pairs leader-stats-effects)] name))
(set simulation.unit-modifiers (icollect [name _ (pairs unit-stats-effects)] name))

simulation
