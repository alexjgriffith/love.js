(local love (require :love))

(local unit {})

(import-macros {: setgmeta : getgmeta} :macro)

(local flag-quads
       (let [quad-names [:flagwhite :flagblue :flagyellow :flagred]
             base 0
             {:atlas {:index {: map} : quad-grid}} (require :src.resources)]
         (icollect [_ name (ipairs quad-names)]
           (do (assert (. map name) (string.format "Name %s not defined in index in atlas-index." name))
               (quad-grid:get (. map name) base)))))

(local flag-quads-outline
       (let [quad-names [:flagwhite :flagblue :flagyellow :flagred]
             outline 1
             {:atlas {:index {: map} : quad-grid}} (require :src.resources)]
         (icollect [_ name (ipairs quad-names)]
           (do (assert (. map name) (string.format "Name %s not defined in index in atlas-index." name))
               (quad-grid:get (. map name) outline)))))

(local star-quads
       (let [quad-names [:star1 :star2 :star3 :star4]
             base 0
             {:atlas { :index {: map} : quad-grid}} (require :src.resources)]
         (icollect [_ name (ipairs quad-names)] (quad-grid:get (. map name) base))))

(local star-quads-outline
       (let [quad-names [:star1 :star2 :star3 :star3]
             outline 1
             {:atlas { :index {: map} : quad-grid}} (require :src.resources)]
         (icollect [_ name (ipairs quad-names)] (quad-grid:get (. map name) outline))))

(fn unit.update [un dt])

(fn unit.draw [un]
  (local lg love.graphics)
  (assert (. flag-quads un.team) (string.format "Indexing flag-quads %s undefined" un.team))
  (assert (. star-quads un.stars) (string.format "Indexing star-quads %s undefined" un.stars))
  (lg.draw un.image (. flag-quads un.team) un.x un.y)
  (lg.draw un.image (. star-quads un.stars) un.x un.y)
  (lg.draw un.image un.body-quad un.x un.y)
  )

(fn unit.outline [un]
  (local lg love.graphics)
  (lg.draw un.image (. flag-quads-outline un.team) un.x un.y)
  (lg.draw un.image (. star-quads-outline un.stars) un.x un.y)
  (lg.draw un.image un.outline-quad un.x un.y))

(fn unit.moveto [un x y]
  (set un.x x)
  (set un.y y))

(fn unit.expend-energy [un energy]
  (set un.energy (math.max 0 (- un.energy energy))))

(fn unit.update-health [un multiplier]
  (each [_ army (ipairs un.army)]
    (tset army :energy (math.min 100 (+ army.energy (* multiplier 34))))
    (tset army :moral (math.min 100 (+ army.moral (* multiplier 34))))
    (tset army :manpower (math.min 100 (+ army.manpower (* multiplier 34))))))

(fn unit.next-turn [un hg]
  (local feature (hg:get-feature un.i un.j))
  (local health-multiplier (or (when feature (feature:get-health-multiplier)) 1))
  (un:update-health health-multiplier)
  (set un.energy 99)
  (when (not un._sleep)
    (set un._skip-turn false))
  )

(local army-types
       {:light-infantry {:energy 100 :manpower 100 :moral 100 :modifier :default :army-type :light-infantry}
        :archers {:energy 100 :manpower 100 :moral 100 :modifier :default :army-type :archers}
        :heavy-infantry {:energy 100 :manpower 100 :moral 100 :modifier :default :army-type :heavy-infantry}
        :pike {:energy 100 :manpower 100 :moral 100 :modifier :default :army-type :pike}
        :cavalry {:energy 100 :manpower 100 :moral 100 :modifier :default :army-type :cavalry}
        :engineer {:energy 100 :manpower 100 :moral 100 :modifier :default :army-type :engineer}})



(fn generate-unit [t]
  (local lume (require :lib.lume))
  (lume.clone (. army-types t)))
(fn unit.add-army [un t]
  (when (< un.stars 4)
    (tset un :stars (+ un.stars 1))
    ;; (tset un :army t (+ 1 (. un.army t)))
      (table.insert un.army (generate-unit t))
    ))

(fn unit.remove-army [un t]
  (local index (accumulate [index nil in {: army-type} (ipairs un.army)] (if (= army-type t) in index)))
  (when (and (> un.stars 1) index)
    (tset un :stars (- un.stars 1))
    ;;(tset un :army t (- (. un.army t) 1))
    (table.remove un.army index)))

(fn unit.army-type-count [un t]
  (accumulate [acc 0 in {: army-type} (ipairs un.army)] (if (= army-type t) (+ 1 acc) acc)))

(fn unit.next-ai [un])

(fn unit.previous-ai [un])

(fn unit.change-quad-name [un quad-name]
  (tset un :quad-name quad-name)
  (local {:atlas {: image :index {: map : unit-map} : quad-grid}} (require :src.resources))
  (local tile-id (. map un.quad-name))
  (tset un :body-quad (quad-grid:get tile-id 0))
  (tset un :outline-quad (quad-grid:get tile-id 1))
  )

(fn unit.serialize [un]
  (local lume (require :lib.lume))
  {:type :unit :stars un.stars :team un.team :id un.id :name un.name :energy un.energy
   :quad-name un.quad-name :race un.race :army (icollect [_ ar (ipairs un.army)] (lume.clone ar))})

(local gambits [:force-center :pivot-left :lower-pikes :burst-pustules :slag-off :raise-flag :eat-mushrooms])

(local gambit-preference {:force-center 1 :pivot-left 1 :lower-pikes 1
                          :burst-pustules 1 :slag-off 1 :raise-flag 1
                          :eat-mushrooms 1})

(fn unit.draw-sprite [un ...]
  (local {: sprites} (require :src.resources))
  (love.graphics.draw sprites.image (sprites.quad-grid:get un.tile-id 0)  ...)
  )

(fn unit.collect-cash [un tile-type]
  (local recruitments (require :src.recruitments))
  (var ret 0)
  (each [_ army (ipairs un.army)]
    (set ret (+ ret (recruitments.raise-money army.army-type tile-type))))
  ret)

(fn unit.generate-path [un hexgrid]
  (set un.path (hexgrid:generate-path un.i un.j un.energy)))

(fn unit.hire-army [un army-type]
  (table.insert un.army (generate-unit army-type)))

(fn unit.fire-army-index [un index]
  (table.remove un.army index))

(fn unit.visit [un hg path]
  (local hexgrid (require :src.hexgrid))
  (each [_ index (ipairs path)]
    (let [(i j) (hg.grid:_index->xy index)
          view (hg:generate-view i j un.sight-distance)]
    (each [v _ (pairs view)]
      (hexgrid.visit-index hg v un.team)))))

(fn unit.set-view [un hg]
  (local hexgrid (require :src.hexgrid))
  (set un.view (hg:generate-view un.i un.j un.sight-distance))
  (each [index _ (pairs un.view)]
    (hexgrid.can-view-index hg index un.team )))

(fn unit.set-team [un team]
  (set un.team team)
  (let [signal (require :lib.signal)]
    (signal.emit :unit-set-team un team))
  un)

(fn unit.path-length [un]
  (accumulate [ret 0 _ _ (pairs un.path)] (+ ret 1)))

(fn unit.can-move [un hg]
  ;; slow
  (if (or (not un.path) (not (= (un:path-length) 1)))
   (un:generate-path hg))
  (and (> (un:path-length) 1) (not un._skip-turn)))

(fn unit.skip-turn [un]
  (set un._skip-turn true))

(fn unit.fortify [un]
  (set un._fortified true))

(fn unit.sleep [un]
  (set un._sleep true))

(fn unit.wake [un]
  (set un._sleep false)
  (set un._skip-turn false))


(local lume (require :lib.lume))
(setgmeta unit unit)

(fn unit.create [un x y]
  (local {:atlas {: image :index {: map : unit-map} : quad-grid}} (require :src.resources))
  (assert (. map un.quad-name) (string.format "Name %s not defined in index in atlas-index." un.quad-name))
  (when (not un.army)
    (set un.army {}))
  (local sgambit (lume.shuffle gambits)) 
  (let [tile-id (. map un.quad-name)
        ng (require :src.name-generation)
        base 0
        overlayer 1
        out {:name (or un.name (ng.generate (. unit-map un.quad-name)))
             :quad-name un.quad-name
             : tile-id
             :race (. unit-map un.quad-name)
             :gambits (collect [_ i (ipairs sgambit)] (values i (. gambit-preference i)))
             :leader-modifier :default
             :type :unit
             : x : y
             : image
             :stars un.stars
             :team un.team
             :id un.id
             :body-quad (quad-grid:get tile-id base)
             :outline-quad (quad-grid:get tile-id overlayer)
             :sort-oy (/ (math.random) 100)
             :h 32
             :energy (or un.energy 99)
             :_skip-turn false
             :_fortified false
             :_sleeping false
             :sight-distance 66
             :army (if (and un.army (. un.army 1) (. un.army 1 :energy)) un.army [(generate-unit :light-infantry)])
             }]
    (setmetatable out (getgmeta unit)))
  )

unit
