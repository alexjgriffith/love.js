;; hexgrid.fnl - alexjgriffith

;; should this be refactored?

;; Constants
(local grid-default {:ground 6 :river [] :road [] :features [] :units [] :visible [] :visited []})
(local neighbour-offsets-odd [[-1 -1 4] [0 -1 5] [1 -1 6] [1 0 1] [0 1 2] [-1 0 3]])
(local neighbour-offsets-even [[-1 0 4] [0 -1 5] [1 0 6] [1 1 1] [0 1 2] [-1 1 3]])

(local love (require :love))

(import-macros {: hex : setgmeta : getgmeta : log} :macro)

(local {: deep-clone} (require :src.utils))

(local hexgrid {})
(local resources (require :src.resources))

;; roads and water
(fn make-indexable-hex []  ;; https://www.redblobgames.com/grids/hexagons/more-pixel-to-hex.html
  (local resources (require :src.resources))
  (local hexindexdata (love.image.newImageData resources.pixel->triangle))
  (local hexindeximage (love.graphics.newImage hexindexdata))
  (let [(ox oy) (values 16 15)
        (iw ih) (hexindeximage:getDimensions)
        grid (require :lib.grid)
        g (grid.new iw ih)]
    (g:apply (fn [_ x y data key]
               (let [(r g b) (hexindexdata:getPixel x y)
                     index (math.floor (* 256 r))
                     angle (math.floor (* 256 g))
                     offsets-even [[0 0] [1 1] [2 0] [0 1] [1 2] [2 1]]
                     offsets-odd [[0 0] [1 0] [2 0] [0 1] [1 1] [2 1]]]
                 (tset data key [(. offsets-even index) (. offsets-odd index) angle]))))
    (fn [mx my]
      (let [section-j (math.floor (/ (- my oy) ih))
            even (= (% section-j 2) 0)
            stagger (* (/ 48 2) (% (+ section-j 0) 2))
            section-i (math.floor (/ (- mx ox  stagger) iw))
            ip (- mx (+ (* section-i iw) stagger ox))
            jp (- my (+ (* section-j ih) oy))
            [[offset-x offset-y]
             [offset-x-odd offset-y-odd] angle]  (g:get ip jp)
            t (+ (* (math.floor (/ (+ section-j 1) 2)) 3) (* -1 (% section-j 2)))
            r (+ (* 2 section-i) (* 1 (% section-j 2)))]
        
        (values (+ (if even offset-x offset-x-odd) r)
                (+ (if even offset-y offset-y-odd) t)
                angle
                section-i section-j
                (+ (* section-i iw) stagger ox)
                (+ (* section-j ih) oy)
                (+ ox ip) (+ oy jp)
                offset-x offset-y)))))

(local pixel-to-hex (make-indexable-hex))

(fn hex-to-pixel [hi hj hw hh]
  (let [oy (if (= (% hi 2) 0) (/ hh 2) 0)]
    (values (+ (* hi hw) 0) (+ (* hj hh) oy))))

(local neighbour-map  
       {:even (collect [i [x y] (ipairs neighbour-offsets-even)] (values (.. x "," y) i))
        :odd (collect [i [x y] (ipairs neighbour-offsets-odd)] (values (.. x "," y) i))})

(fn neighbour [i j a]
  (let [[oi oj ap] (if (= (% i 2) 0) (. neighbour-offsets-even a) (. neighbour-offsets-odd a))]
    (values (+ i oi) (+ j oj) ap)))

(fn hexgrid.tile-angle [hg i1 j1 i2 j2]
  (let [(dx dy) (values (- i2 i1) (- i2 i1))]
    (. neighbour-map (if (= (% i1 2) 0) :even :odd) (.. dx "," dy))))

(fn hexgrid.get [hg i j what?]
  (let [ret (hg.grid:get (math.min (math.max i 0) (- hg.grid.w 1))
                         (math.min (math.max j 0) (- hg.grid.h 1)))]
    (if what? (. ret what?) ret)))

(fn hexgrid.get-unit [hg i j what?]
  (. (hg:get i j :units) 1))

(fn hexgrid.get-feature [hg i j what?]
  (. (hg:get i j :features) 1))

(fn hexgrid.get-tile [hg i j]
  (local {:atlas { :index {: rmap}}} (require :src.resources))
  (. rmap (hexgrid.get hg i j :ground)))


(fn hexgrid.get-feature-type [hg i j]
  (let [feature (hexgrid.get hg i j :feature 1)]
    (when feature (feature:get-type))))

(fn hexgrid.neighbours [hg i j what?]
  (let [offsets (if (= (% i 2) 0)
                    neighbour-offsets-even
                    neighbour-offsets-odd)]
    (collect [_i [ox oy _a] (ipairs offsets)] (hexgrid.get hg (+ i ox) (+ j oy) what?))))

(local  {:map {:river river-tile}} (require :src.atlas-index))
(fn hexgrid.river-crossing-directions [hg i j]
  (collect [_ v (ipairs (hexgrid.get hg i j :river))] (values (- v river-tile) true)))

(fn hexgrid.river-crossing [hg i1 j1 i2 j2]
  (let [crossings (hexgrid.river-crossing-directions hg i1 j1)
        angle (hexgrid.tile-angle hg i1 j1 i2 j2)]
    (if (. crossings angle) true false)))


(fn toggle-unit-editor [hg unit]
  (let [state (require :src.state)
        editor state.editor
        frames state.frames]
    (when (= editor.name :editor)
      (tset hg :editing-unit unit)
      (state.frames:activate :unit-editor)
      )
    )
  )

(fn unit-new-id []
  (let [state (require :src.state)
        {: last-unit-id} state]
    (assert (and last-unit-id (< last-unit-id 100)) (string.format "Game cannot handle more than 100 units."))
    (set state.last-unit-id (+ 1 (or last-unit-id 0)))
    state.last-unit-id))

(fn hexgrid.unit-moveto [hg unit new-i new-j]
  (let [old-table (. (hg:get unit.i unit.j) :units)
        new-table (. (hg:get new-i new-j) :units)
        px (+ (* hg.tw new-i) 0)
        py (+ (* hg.th (- new-j 0)) (if (= 0 (% new-i 2)) 0 -15) (- 16) )
        old-index (accumulate [ret nil i v (ipairs old-table)] (if (= v unit) i ret))
        fennel (require :lib.fennel)]
    (assert old-index (.. (string.format "Unit not present in grid.\n\n") (fennel.view unit)))
    (table.remove old-table old-index)
    (tset unit :i new-i)
    (tset unit :j new-j)
    (unit:moveto px py)
    (table.insert new-table unit)))

(fn hexgrid.clear-visible [hg]
  (local lume (require :lib.lume))
  (hg.grid:apply
   (fn [v] (lume.clear v.visible))))

(fn hexgrid.clear-visited [hg]
  (local lume (require :lib.lume))
  (hg.grid:apply
   (fn [v] (lume.clear v.visited))))

(fn hexgrid.visit-index [hg index team]
  ;; (pp (string.format "visiting %s %s" index team ))
  (let [(i j) (hg.grid:_index->xy index)
        tab (hg:get i j)]
    (tset tab :visited team true)))

(fn hexgrid.can-view-index [hg index team]
  (let [(i j) (hg.grid:_index->xy index)
        tab (hg:get i j)]
    ;; (pp [:visible tab team])
    (tset tab :visible team true)))

(fn unit-remove [hg unit]
  (let [old-table (. (hg:get unit.i unit.j) :units)
        old-index (accumulate [ret nil i v (ipairs old-table)] (if (= v unit) i ret))
        unit-index (accumulate [ret nil i v (ipairs hg.objects)] (if (= v unit) i ret))
        fennel (require :lib.fennel)]
    (assert old-index (.. (string.format "Unit not present in grid.\n\n") (fennel.view unit)))
    (table.remove hg.objects unit-index)
    (table.remove old-table old-index)))

(fn hexgrid.unit-remove [hg unit]
  (unit-remove hg unit))

(fn unit-create [hg i j un dont-insert-into-tab?]
  (let [px (+ (* hg.tw i) 0)
        py (+ (* hg.th (- j 0)) (if (= 0 (% i 2)) 0 -15) (- 16) )
        unit (require :src.unit)
        tab (. (hg:get i j) :units)
        un (unit.create un px py)]
    (log [:unit-create-position px py])
    (tset un :i i)
    (tset un :j j)
    (table.insert hg.objects un)
    (when (not dont-insert-into-tab?)
      (table.insert tab un))
    un))

(fn feature-new-id []
  (let [state (require :src.state)
        {: last-feature-id} state]
    (assert (and last-feature-id (< last-feature-id 100)) (string.format "Game cannot handle more than 100 features."))
    (set state.last-feature-id (+ 1 (or last-feature-id 0)))
    state.last-feature-id))

(fn feature-remove [hg feature]
  (let [old-table (. (hg:get feature.i feature.j) :features)
        old-index (accumulate [ret nil i v (ipairs old-table)] (if (= v feature) i ret))
        feature-index (accumulate [ret nil i v (ipairs hg.objects)] (if (= v feature) i ret))
        fennel (require :lib.fennel)]
    (assert old-index (.. (string.format "Feature not present in grid.\n\n") (fennel.view feature)))
    (table.remove hg.objects feature-index)
    (table.remove old-table old-index)))

(fn feature-create [hg i j un dont-insert-into-tab?]
  (let [px (+ (* hg.tw i) 0)
        py (+ (* hg.th (- j 0)) (if (= 0 (% i 2)) 0 -15) (- 16) )
        feature (require :src.feature)
        tab (. (hg:get i j) :features)
        un (feature.create un px py)]
    (log [:feature-create-position px py])
    (tset un :i i)
    (tset un :j j)
    (table.insert hg.objects un)
    (when (not dont-insert-into-tab?) (table.insert tab un))
    un))

(fn hexgrid.draw-layer [hg layer-name sublayer-name x y function?]
  (local lg love.graphics)
  (lg.push)
  (lg.translate x y)
  (let [layer (. hg :spritebatch layer-name sublayer-name)
        grid (. hg :grid)]
    (assert layer (string.format "Layer %s does not exist." layer-name))
    (match (type layer)
      :userdata (lg.draw layer) ;; Spritebatch
      :table (grid:apply       ;; grid of tables
              (if function?
                  function? ;;
                  (fn [value x y]
                    (let [px (+ (* hg.tw x) 0)
                          py (+ (* hg.th y) (if (= 0 (% x 2)) 0 -15))
                          base (hg.atlas.quad-grid:get value 0)
                          overlayer (hg.atlas.quad-grid:get value 0)]
                      (each [_ i (ipairs base)] (lg.draw hg.atlas.image i px py))
                      (each [_ i (ipairs overlayer)] (lg.draw hg.atlas.image i px py))))))))
  (lg.pop))

(fn hexgrid.mouse->hex [g mx my]
  (local (hi hj angle) (pixel-to-hex mx my))
  (local (ox oy) (hex-to-pixel hi hj 24 30))
  (local (ni nj na) (neighbour hi hj angle))
  (local (nox noy) (hex-to-pixel ni nj 24 30))
  (values hi hj angle ox oy ni nj na nox noy))

(fn set-grid [{: grid} tileortable layout default?]
  (grid:apply
   (fn [_ x y data key]
     (match layout
       :single (tset data key tileortable)
       :dense (tset data key (. tileortable key))
       :sparse (do
                 (assert "Sparse tables need to be provided with a default value.")
                 (if (. tileortable key)
                     (let [tile (. tileortable key)
                           base (deep-clone default? 3)]
                       (each [key value (ipairs base)]
                         ;; lets us expand our gridmap data structure
                         ;; without redoing our maps
                         (when (not (. tile key)) (tset tile key value)))
                       (tset data key tile))
                     
                     (tset data key (when default? (deep-clone default? 3)))
                     ))))))

(fn set-spritebatch [hg layer-name sublayer?]
  (let [sublayer (or sublayer? :base)
        layer (. hg :spritebatch layer-name sublayer)
        grid (. hg :grid)
        layer-index (. {:overlayer 1 :base 0} sublayer)]
    (layer:clear)
    (grid:apply
     (fn [value x y _data _key]
       (let [tile-id (. value layer-name)
             px (+ (* hg.tw x) 0)
             py (+ (* hg.th y) (if (= 0 (% x 2)) 0 -15))]
         ;; clean this up and make call outs for each tile type
         (match (values (type tile-id) tile-id)
           
           (:number 6) ;; water autotile
           (let [offsets (if (= (% x 2) 0)
                             neighbour-offsets-even
                             neighbour-offsets-odd)
                 v (accumulate [acc 0 i [ox oy] (ipairs offsets)]
                     (let [iswater (= (hexgrid.get hg (+ x ox) (+ y oy) :ground) 6)]
                       (if (not iswater)
                           (+ acc (^ 2 (- i 1)))
                           acc
                           )))]
             (when (= sublayer :base)
               (layer:add (hg.atlas.quad-grid:get (+ v (* 16 10)) layer-index) px py)))
           
           (:number _) (layer:add (hg.atlas.quad-grid:get tile-id layer-index) px py)
           (:table _) (each [_ tile (ipairs tile-id)]
                    (layer:add (hg.atlas.quad-grid:get tile layer-index) px py)))
         )))))

(fn dtobi [digit]
  "Digit to binary iterator"
  (var q 0)
  (var r 0)
  (var p (/ digit 2))
  (var last 1)
  (var index 0)
  (fn []    
    (set q (math.floor p))
    (set r (* (- p q) 2)) ;; either 0.5 * 2 or 0 * 2
    (set p (/ q 2))
    (set index (+ index 1))
    (when (> last 0)
      (set last q)
      (values index (= r 1)))))

(fn dtob [dig]
  (icollect [_index bin (dtobi dig)] bin))

(fn binary-index [dig]
  (icollect [index bin (dtobi dig)] (when bin index)))

(fn btod [binary]
  (accumulate [ret 0 i v (ipairs binary)]
    (if v
        (+ ret (^ 2 (- i 1)))
        ret)))
;; replace with autotile
(fn set-border-spritebatch [hg border-tiles]
  (let [layer (. hg :spritebatch :border :base)
        grid (. hg :grid)
        layer-index 0]
    (layer:clear)    
    (each [index _angles (pairs border-tiles)]
      (let [(x y) (grid:_index->xy index) ;; take index get i j
            offsets (if (= (% x 2) 0)  ;; determine neighbour offsets based on current column
                        neighbour-offsets-even
                        neighbour-offsets-odd) 
            v (accumulate [acc 0 i [ox oy] (ipairs offsets)]
                (let [n-index (grid:_xy->index (+ x ox) (+  y oy))
                      isborder (. border-tiles n-index)] ;; need to handle max and min
                  (if (not isborder) (+ acc (^ 2 (- i 1))) acc)))
            px (+ (* hg.tw x) 0)
            py (+ (* hg.th y) (if (= 0 (% x 2)) 0 -15))]
        (layer:add (hg.atlas.quad-grid:get (+ (. hg.atlas.index.map :outline-auto) v) layer-index) px py)))))

(fn set-pathing-spritebatch [hg path]
  (fn get-angle [index-1 index-2]
    (let [(x1 y1) (hg.grid:_index->xy index-1)
          (x2 y2) (hg.grid:_index->xy index-2)
          (dx dy) (values (- x2 x1) (- y2 y1))]
      (or (. neighbour-map (if (= (% x1 2) 0) :even :odd) (.. dx "," dy)) 7)))
  (let [layer (. hg :spritebatch :pathing :base)
        grid (. hg :grid)
        layer-index 0]
    (layer:clear)
    (each [key index (ipairs path)]
      (let [(i j) (grid:_index->xy index)
            tile-id (. hg.atlas.index.map :pathing)
            px (+ (* hg.tw i) 0)
            py (+ (* hg.th j) (if (= 0 (% i 2)) 0 -15))]
        (when (. path (- key 1))
          :leadin
          (local a (get-angle index (. path (- key 1))))
          (layer:add (hg.atlas.quad-grid:get (+ tile-id a) layer-index) px py))
        (when (. path (+ key 1))
          :leadout
          (local a (get-angle index (. path (+ key 1))))
          (layer:add (hg.atlas.quad-grid:get (+ tile-id a) layer-index) px py))))))

(fn hexgrid.set [hg mx my value remove? editor? update?]
  (let [(i j a _ox _oy ni nj na) (hg:mouse->hex mx my)
        index (. hg.atlas.index.map value)
        t (. hg.atlas.index.type value)]
    (fn get-last-occurance [tab v2]
      (accumulate [ret nil i v1 (ipairs tab)] (if (= v1 v2) i ret)))
    (fn setonce [tab v2]
      (let [last-occurance (get-last-occurance tab v2)]
        (when (not last-occurance) (table.insert tab v2)))) 
    (fn remove [tab v2]
      (let [last-occurance (get-last-occurance tab v2)]
        (when last-occurance (table.remove tab last-occurance))))
    ;; could each of these be broken out into their own module? ground, road, river, 
    (match t
      :ground (do
                (log [:set i j value index t])
                (let [tab  (hg:get i j)
                      previous tab.ground]
                  (if remove?
                      (tset tab :ground 6) ;; replace ground with water
                      (tset tab :ground index))
                  (when (~= tab.ground previous)
                    (set-spritebatch hg :ground :base)
                    (set-spritebatch hg :ground :overlayer))))
      :road 
      (let [tab (. (hg:get i j) :road)]
        (log [:set i j value index t])
        (if remove?
            (remove tab (+ index a))
            (setonce tab (+ index a)))
        (set-spritebatch hg :road))
      
      :river
      (let
          [tab1 (. (hg:get i j) :river)
           tab2 (. (hg:get ni nj) :river)]
        (log [:set i j value index t])
        (if remove?
            (do (remove tab1 (+ index a))
                (remove tab2 (+ index na)))
            (do (setonce tab1 (+ index a))
                (setonce tab2 (+ index na))))
        (set-spritebatch hg :river))
      :feature (when (not update?)
                 (let [tab (. (hg:get i j) :features)]
                   (log [:set i j value index t tab])
                   (if remove?
                       (when (. tab 1) (feature-remove hg (. tab 1)))
                       (do
                         (when (. tab 1) (feature-remove hg (. tab 1)))
                         (feature-create hg i j {:name value :team 1 :stars 1 :id (feature-new-id)})))))
      :unit (when (not update?)
              (let [tab (. (hg:get i j) :units)]
                (log [:set i j value index t tab])
                (if remove?
                    (when (. tab 1) (unit-remove hg (. tab 1)))
                    (do
                      (if (and editor? (. tab 1))
                          (toggle-unit-editor hg (. tab 1))
                          (. tab 1)
                          (when (. tab 1) (unit-remove hg (. tab 1)))
                          (unit-create hg i j {:quad-name value :team (if (= value :small-goblin) 2 3) :stars 1 :id (unit-new-id)})))
              )))
      )))

(local _default-objects-update-ret {:type :tile})
(fn hexgrid.update [hg dt mx my _focus]
  ;;(each [key value (ipairs hg.objects)] (when value.update (value:update dt hg)))
  (local objects (require :src.objects))  
  (local (hi hj angle ox oy _ni _nj _na _nox _noy) (hg:mouse->hex mx my))
  (local tile (hg:get hi hj))
  (tset _default-objects-update-ret :tile tile)
  (local {: atlas} (require :src.resources))
  (tset _default-objects-update-ret :id tile.ground)
  (tset _default-objects-update-ret :name (. atlas.index.rmap tile.ground))
  (local over (objects.update hg.objects _default-objects-update-ret))
  (table.sort hg.objects (fn [a b] (< (+ a.y (or a.sort-oy 0) (or a.h 32)) (+ b.y (or b.sort-oy 0) (or b.h 32)))))
  (values over hi hj))

(local move-border-shader (love.graphics.newShader :assets/shaders/move-border.glsl))

(local fogofwar (love.graphics.newCanvas 1920 1080))
(fn hexgrid.draw [hg mx my camera focus]
  (local lg love.graphics)
  (local (hi hj angle ox oy ni nj na nox noy) (hg:mouse->hex mx my))
  (lg.setColor 1 1 1 1)
  (hg:draw-layer :ground :base 0 -16)
  (hg:draw-layer :river :base 0 -16)
  (hg:draw-layer :road :base 0 -16)
  (lg.setColor (hex :982229))
  (lg.setShader move-border-shader)
  (hg:draw-layer :border :base 0 -16)
  (lg.setShader)
  (hg:draw-layer :pathing :base 0 -16)
  (lg.setColor 1 1 1 1)
  (local (over-callback object-callback) (let [objects (require :src.objects)]
                                           (objects.draw hg.objects focus)))
  ;; (lg.push)
  ;; ;; (lg.reset)
  ;; (hg.grid:apply (fn [_ i j]
  ;;                  (let [px (+ (* hg.tw i) 8)
  ;;                        py (+ (* hg.th (- j 0)) (if (= 0 (% i 2)) 0 -15) (+ 8))
  ;;                        index (hg.grid:_xy->index i j)
  ;;                        tile (. hg.grid.data index)]
  ;;                    (lg.print (string.format "%s" tile.ground)
  ;;                              px py))
                 
  ;;                  ))
  ;; (lg.pop)
  (hg:draw-layer :features :base 0 -16)
  (hg:draw-layer :units :base 0 -16)
  ;; (pp hg.units)
  (local {: over-ui-function} (require :src.ui))
  (local over-ui (over-ui-function))
  ;; draw reticle
  (when (and (not over-callback) (not over-ui))
    (lg.push)
    (lg.translate 0 (+ -16 -15))
    (lg.setColor (hex :ffffffff))
    (when focus (lg.draw hg.atlas.image (hg.atlas.quad-grid (+ 16 7) 0) ox oy))
    (lg.pop))

  (hg:draw-layer :ground :overlayer 0 -16)

  (local {: snow : camera} (require :src.state))
  (lg.push)
  (lg.translate (- camera.x) (- camera.y))
  (lg.setColor (hex :252046))
  (snow:draw)
  (lg.setColor 1 1 1 1)
  ;; (fogofwar:clear)
  (lg.pop)
  (lg.push :all)
  ;;(lg.reset)
  ;; (lg.translate (- camera.x) (- camera.y))
  ;; (lg.setCanvas fogofwar)
  ;; (lg.clear 0 0 0 0)
  ;; (lg.setBlendMode :replace)
  (lg.setColor (hex :131826))
  (hg:draw-layer :visibility :base 0 -16)
  (lg.setColor 1 1 1 1)
  ;; (lg.setCanvas)
  (lg.setBlendMode :alpha)
  (lg.pop)
  (lg.draw fogofwar)
  
  (lg.push)
  (object-callback)
  (if over-callback
      (over-callback))
  (when (and focus (not over-callback))
    (lg.setColor (hex :ffffffff))
    (lg.translate 0 (+ -16 -15))
    (lg.setColor (hex :ffffff99))
    (local {: editor} (require :src.state))
    (when (= editor.tile :river)
      (lg.draw hg.atlas.image (hg.atlas.quad-grid (+ 16 angle) 1) ox oy)
      (lg.draw hg.atlas.image (hg.atlas.quad-grid (+ 16 na) 1) nox noy))
    (when (or (= editor.tile :road))
      (lg.draw hg.atlas.image (hg.atlas.quad-grid (+ 16 angle) 1) ox oy))
    )
  (lg.pop)

  ;; (lg.push :all)
  ;; (lg.reset)
  ;; (lg.setColor 1 1 1 1)
  ;; (local {: camera} (require :src.state))
  ;; (lg.translate (* camera.x camera.scale) (* camera.y camera.scale))
  ;; (lg.rectangle :fill (* camera.scale 10) (* camera.scale 10) (* 100 camera.scale) (* 100 camera.scale))
  ;; (local {: fonts} (require :src.resources))
  ;; (lg.setFont fonts.text)
  ;; (each [_ obj (ipairs hg.objects)]
  ;;   (when (= obj.type :unit)
  ;;     (local message (.. "Unit: " obj.id))
  ;;     ;;(lg.print message (* camera.scale obj.x) (* camera.scale obj.y))
  ;;     (local w (fonts.text:getWidth message))
  ;;     (local h (fonts.text:getHeight message))
  ;;     (local padding 20)
  ;;     (lg.setColor 1 1 1 1)
  ;;     (lg.setLineWidth 8)
  ;;     (lg.rectangle :line  (- (* camera.scale obj.x) padding) (- (* camera.scale obj.y) padding)
  ;;                   (+ w (* 2 padding)) (+ h (* 2 padding)))
  ;;     (lg.setColor 0 0 0 1)
  ;;     (lg.rectangle :fill  (- (* camera.scale obj.x) padding) (- (* camera.scale obj.y) padding)
  ;;                   (+ w (* 2 padding)) (+ h (* 2 padding)))
  ;;     (lg.setColor 1 1 1 1)
  ;;     (lg.print message (* camera.scale obj.x) (* camera.scale obj.y)    )
  ;;   ))
  ;; (lg.pop)

  ;; (local {: atlas} (require :src.resources))
  ;; (hg.grid:apply (fn [_ i j]
  ;;                  (let [px (+ (* hg.tw i) 8)
  ;;                        py (+ (* hg.th (- j 0)) (if (= 0 (% i 2)) 0 -15) (+ 8))
  ;;                        index (hg.grid:_xy->index i j)
  ;;                        tile (. hg.grid.data index)]
                     
  ;;                    (lg.draw atlas.image (atlas.quad-grid:get 6 0) px py)
  ;;                    )                 
  ;;                  ))  
  )

(fn hexgrid.draw-fog-of-war [hg]
  ;;(hg:draw-layer :visibility :base 0 -16)
  )


(fn hexgrid.draw-editor [hg mx my camera focus]
  (local lg love.graphics)
  (local (hi hj angle ox oy ni nj na nox noy) (hg:mouse->hex mx my))
  (lg.setColor 1 1 1 1)
  (hg:draw-layer :ground :base 0 -16)
  (hg:draw-layer :river :base 0 -16)
  (hg:draw-layer :road :base 0 -16)

  (local (_over-callback object-callback) (let [objects (require :src.objects)]
                                            (objects.draw hg.objects focus :editor)))
  ;; draw reticle
  (local {: editor} (require :src.state))
  (lg.push :all)
  (lg.translate 0 (+ -16 -15))
  (lg.setColor (hex :ff7777ff))
  (when focus
    (let [quad-index (. hg.atlas.index.map editor.tile)]
      (when quad-index
        (lg.draw hg.atlas.image (hg.atlas.quad-grid quad-index 0) ox oy)
        (lg.draw hg.atlas.image (hg.atlas.quad-grid quad-index 1) ox oy)))
    (lg.draw hg.atlas.image (hg.atlas.quad-grid (+ 16 7) 0) ox oy))
  (lg.pop)
  (hg:draw-layer :ground :overlayer 0 -16)
  (object-callback)
  (when focus
    (lg.setColor (hex :ffffffff))
    (lg.translate 0 (+ -16 -15))
    (lg.setColor (hex :ffffff99))
    (when (= editor.tile :river)
      (lg.draw hg.atlas.image (hg.atlas.quad-grid (+ 16 angle) 1) ox oy)
      (lg.draw hg.atlas.image (hg.atlas.quad-grid (+ 16 na) 1) nox noy))
    (when (or (= editor.tile :road))
      (lg.draw hg.atlas.image (hg.atlas.quad-grid (+ 16 angle) 1) ox oy))

    ))

(fn hexgrid.generate-navigation-functions [hg]
  (local neighbours [])
  (local strict-neighbours [])
  ;;(local self [])
  ;;mountain,hills,grassland,field,desert,forest,water
  (local tile-costs [100 99 33 33 33 66 100])
  (local tile-view-costs [200 99 33 33 33 66 33])
  (local tile-view-bonus [0 33 0 0 0 0 0])
  (local tile-passable-list [false true true true true true false])
  (hg.grid:apply
   (fn [_ i j _data key]
     ;;(tset self key [i j (neighbour i j a)] (hg.grid:_xy->index i j -1))
     (tset strict-neighbours key (fcollect [a 1 6] (let [(ni nj) (neighbour i j a)] (hg.grid:_xy->index ni nj -1))))
     (tset neighbours key (fcollect [a 1 6] (let [(ni nj) (neighbour i j a)]
                                              (let [index (hg.grid:_xy->index ni nj nil)]
                                              [index] )
                                              )))))
  (local callbacks
         {:get-neighbours (fn [index] (let [n (. neighbours index)]
                                               (each [_ v (ipairs n)]
                                                 (tset v 2 (?. hg.grid.data (. v 1) :ground)))
                                               ;; (pp n)
                                               n
                                               ))
          :get-neighbours-strict (fn [index]  (. strict-neighbours index))
          :get-self (fn [index] (?. hg.grid.data index :ground))
          :tile-cost (fn [tile-type]
                       (. tile-costs (+ tile-type 1)))
          :tile-view-cost (fn [tile-type]
                            (. tile-view-costs (+ tile-type 1)))
          :tile-view-bonus (fn [tile-type]
                            (. tile-view-bonus (+ tile-type 1)))
          :tile-passable (fn [_index tile-type]
                           (. tile-passable-list (+ tile-type 1)))
          })
  (local navigate (require :src.navigate))
  (fn path-to [_hg path i j]
    (local index (hg.grid:_xy->index i j -1))
    (if (= index -1)
        nil
        (navigate.path-to path index callbacks.tile-passable)))

  (fn set-outer-ring [_hg path]
    ;; (tset hg :outer-ring-table (navigate.outer-ring path callbacks.get-neighbours-strict hg.outer-ring-table))
    (set-border-spritebatch hg path))
  
  (fn generate-path [_hg i j limit]
    (local index (hg.grid:_xy->index i j -1))
    (assert (~= index -1) "Index out of range of map")
    (navigate.generate-path index limit callbacks.get-neighbours callbacks.tile-cost callbacks.tile-passable))

  (fn generate-view [_hg i j limit]
    (local index (hg.grid:_xy->index i j -1))
    (assert (~= index -1) "Index out of range of map")
    (navigate.generate-view index limit callbacks.get-neighbours callbacks.tile-view-cost callbacks.get-self callbacks.tile-view-bonus))

  {: path-to : set-outer-ring  : generate-path : generate-view}
  )

(fn hexgrid.clear-outer-ring [hg path]
  (hg.spritebatch.border.base:clear))


(fn hexgrid.set-path [hg path]
  (set-pathing-spritebatch hg path))

(fn hexgrid.clear-pathing [hg]
  (hg.spritebatch.pathing.base:clear))

(fn hexgrid.serialize [hg]
  (fn serialize [value _x _y _data _index]
    (local is-default (accumulate [ret true key value (pairs value)]
                        (match (type value)
                          :number (and ret (= value (. grid-default key)))
                          :table (and ret (= (# value) 0))
                          _ ret)))
    (when (not is-default)
      (collect [key v (pairs value)]
        (values key (match key
          :features (icollect [_ feature (ipairs v)] (feature:serialize))
          :units (icollect [_ unit (ipairs v)] (unit:serialize))
          _ v)))))
  (local ret {})
  (hg.grid:apply serialize ret)
  ret)


(fn hexgrid._test-reload [hg]
  (local data (hg:serialize))
  (local hg2 (hexgrid.make-hex-grid 100 100 data))
  (each [k v (pairs hg2)] (tset hg k v))
  )

(fn hexgrid.save [hg file]
  (local data (hg:serialize))
  (local fennel (require :fennel))
  (local f (io.open (.. (love.filesystem.getSource) file) :w))
  (if f
    (do (f:write (fennel.view {:w hg.w :h hg.h : data}))
        (f:close)
        :saving)
    (.. :cant-open-file: (.. (love.filesystem.getSource) file))))

(fn import [module]
  (local fennel (require :lib.fennel))
  (local lume (require :lib.lume))
  (when (. package.loaded module)
    (tset package.loaded module nil))
  (require module))

(fn hexgrid.load [module]
  (let [{: w : h : data &as module} (import module)
        hg2 (hexgrid.make-hex-grid w h data)]
    hg2))

(fn hexgrid.over-load [hg module]
  (let [{: w : h : data &as module} (require module)
        hg2 (hexgrid.make-hex-grid w h data)]
    (if hg (each [k v (pairs hg2)] (tset hg k v))
        hg2)))

(fn hexgrid.blank [hg module]
  (local state (require :src.state))
  (set state.hexgrid (hexgrid.make-hex-grid 100 100)))

(fn hexgrid.get-team-units [hg team]
  (icollect [_ obj (ipairs hg.objects)] (when (= obj.team team) obj)))


(let [can-see-quad (resources.atlas.quad-grid:get resources.atlas.index.map.can-see 0)
      has-seen-quad (resources.atlas.quad-grid:get resources.atlas.index.map.has-seen 0)
      hasnt-seen-quad (resources.atlas.quad-grid:get resources.atlas.index.map.hasnt-seen 0)]
  ;;(pp hasnt-seen-quad)
  (fn hexgrid.set-visibility-spritebatch [hg team]
    ;; Should be called on map load, at the start of each turn, after a move,
    ;; after any change to a unit / team
    (let [base hg.spritebatch.visibility.base]
      ;; spritebatch starts iteration at 1
      (base:clear)
      (hg.grid:apply
       (fn [d x y _data key]
         (let [{: visible : visited} d
               can-see (. visible team)
               has-seen (. visited team)
               px (+ (* hg.tw (+ 0 x)) 0)
               py (+ (* hg.th y) (if (= 0 (% x 2)) 0 -15))]
           ;; (if (and (not can-see) has-seen) (pp :haasseen))
           (base:add
                     (if can-see can-see-quad
                         has-seen has-seen-quad
                         hasnt-seen-quad
                         )
                     px py))))))
  (fn hexgrid.init-visibility-spritebatch [hg]
    (let [base hg.spritebatch.visibility.base]
      (base:clear)
      (hg.grid:apply (fn [_ x y]
                       (let [px (+ (* hg.tw (+ 0 x)) 0)
                             py (+ (* hg.th y) (if (= 0 (% x 2)) 0 -15))]
                             (base:add hasnt-seen-quad px py))))
      ))
  ) ;; let end

(setgmeta hexgrid hexgrid)

(fn hexgrid.make-hex-grid [w h gr?]
  (local love (require :love))
  (let [{: atlas} (require :src.resources)
        (tw th) (values 24 30)
        gr (or gr? [])
        g (require :lib.grid)
        grid (g.new w h)
        spritebatch
        {:ground
         {:base (love.graphics.newSpriteBatch atlas.image (* w h))
          :overlayer (love.graphics.newSpriteBatch atlas.image (* w h))}
         :river
         {:base (love.graphics.newSpriteBatch atlas.image (* w h 6))}
         :border
         {:base (love.graphics.newSpriteBatch atlas.image (* w h 6))}
         :pathing
         {:base (love.graphics.newSpriteBatch atlas.image (* w h 6))}         
         :road
         {:base (love.graphics.newSpriteBatch atlas.image (* w h 6))}
         :features
         {:base (love.graphics.newSpriteBatch atlas.image (* w h 1))
          :overlayer (love.graphics.newSpriteBatch atlas.image (* w h 1))}
         :units
         {:base (love.graphics.newSpriteBatch atlas.image (* w h 6))}
         :visibility
         {:base (love.graphics.newSpriteBatch atlas.image (* w h))
          :overlayer (love.graphics.newSpriteBatch atlas.image (* w h))}
         }
        objects []
        hg (setmetatable {: grid : spritebatch : objects
                          : tw : th : w : h  : atlas
                          } (getgmeta hexgrid))]
    (set-grid hg gr :sparse grid-default)
    (grid:apply (fn [{: units : features &as tile} i j _data _key]
                  (when (> (# units) 0)
                    (let [new-units []]
                      (for [index 1 (# units)]
                        (let [un (. units index)
                              {: _name } (. units index)]
                          (let [unit-built (unit-create hg i j un true)]
                            ;; deserialize features
                            (tset new-units index unit-built)
                            ;; (table.insert hg.objects unit-built)
                            (tset units index unit-built)
                            )))
                      ))
                  (when (> (# features) 0)
                    (let [new-features {}]
                      (for [index 1 (# features)]
                        (let [un (. features index)
                              {: _name } (. features index)]
                          (let [feature-built (feature-create hg i j un true)]
                            ;; deserialize features
                            (tset new-features index feature-built)
                            ;;(table.insert hg.objects feature-built)
                            (tset features index feature-built)
                            )))
                      ))
                  ))
    (set-spritebatch hg :road)
    (set-spritebatch hg :river)
    (set-spritebatch hg :ground :base)
    (set-spritebatch hg :ground :overlayer)
    (hexgrid.init-visibility-spritebatch hg)
    (local {: path-to : set-outer-ring : generate-path : generate-view}
           (hexgrid.generate-navigation-functions hg))
    (tset hg :path-to path-to)
    (tset hg :set-outer-ring set-outer-ring)
    (tset hg :generate-path generate-path)
    (tset hg :generate-view generate-view)
    hg))

hexgrid
