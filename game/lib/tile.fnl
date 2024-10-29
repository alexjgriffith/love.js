;; Author AlexJGriffith
;; Licence MIT

;; Internal
(fn index-to-ij [index width]
  (values (math.floor (% (- index 1) width)) (math.floor (/  (- index 1)  width))))

(fn ij-to-index [i j width]
  (+ (* width (- j 1))  i))

(fn colrow [grid width height]
  (values
   (fn [tab index]
     (when (< index (* width height))
       (let [(i j) (index-to-ij (+ index 1) width)]
         (values (+ index 1) i j (. tab (+ index 1))))))
   grid
   0))


(fn autotile [array width]
  (local autotile (require :src.autotile))
  (local bitmap (autotile.parse-bitmap autotile.bitmap-2x2 4))
  (autotile.match-key-fast array width bitmap))

;; Layer API
(set _G.debug-tiles-obj false)
(local _layer_mt {})
(fn update-tile-spritebatch [layer]
  (layer.spritebatch:clear)
  (when (= :autotile layer.layer-type)
    (tset layer :tilegrid (autotile layer.rawgrid layer.width)))
  (each [index i j tile (colrow layer.tilegrid layer.width layer.height)]
    (let [x (* i layer.tilesize)
          y (* j layer.tilesize)          
          quad-name (. layer :tileset tile)
          quad (. layer :quads quad-name)]
      (layer.spritebatch:add quad x y)
      )))

(fn update-obj-spritebatch [layer objects]
  (layer.spritebatch:clear)
  (when _G.debug-tiles-obj (pp "updating obj spritebatch"))
  (each [i obj (ipairs layer.objs)]
    (when (objects obj)
      (let [x obj.x
            y obj.y
            quad (. layer :quads obj.quad)]
        (when _G.debug-tiles-obj (pp obj))
        (layer.spritebatch:add quad x y)))))

(fn encode-obj [layer]
  {:layer-type layer.layer-type
   :name layer.name
   :ox layer.ox
   :oy layer.oy
   :z layer.z
   :width layer.width
   :height layer.height
   :tileset-name layer.tileset-name
   ;; may be an issue with type vs t :/
   :objs (icollect [_ {: name : type : quad : x : y : w : h} (ipairs layer.objs)]
           {: name : type : quad : x : y : w : h})})

(fn decode-obj [layer map objects]  
  (let [spritebatch (love.graphics.newSpriteBatch map.image (* map.width map.height))]
    (local layer
           {:name layer.name
            :layer-type layer.layer-type
            :spritebatch spritebatch
            :tilesize map.tilesize
            :tileset-name layer.tileset-name
            :tileset (. map :tilesets layer.tileset-name)
            :quads map.quads
            :width layer.width
            :height layer.height            
            :ox layer.ox
            :oy layer.oy
            :z layer.z
            :objs (icollect [i obj (ipairs layer.objs)] (do
                                                          ;; (objects obj :create)
                                                          ;; -- this should be done when
                                                          ;; a map is activated in colliders
                                                            obj))
            })
    (setmetatable layer _layer_mt)
    (layer:update objects)
    layer))

(fn encode-grid [layer]
  (var rawgridstring "") 
  (each [index char (ipairs layer.rawgrid)]
    (set rawgridstring (.. rawgridstring char " ")))
    {:layer-type layer.layer-type
     :name layer.name
     :width layer.width
     :height layer.height     
     :ox layer.ox
     :oy layer.oy
     :z layer.z
     :tileset-name layer.tileset-name
     :rawgrid rawgridstring})

(fn decode-grid [layer map]  
  (let [spritebatch (love.graphics.newSpriteBatch map.image (* map.width map.height))
        rawgrid []
        parse-list layer.rawgrid]
    (each [char (string.gmatch parse-list "(%w)")]
      (table.insert rawgrid (tonumber char)))
    (local layer
           {:name layer.name
            :layer-type layer.layer-type
            :spritebatch spritebatch
            :tilesize map.tilesize
            :quads map.quads
            :width layer.width
            :height layer.height            
            :ox layer.ox
            :oy layer.oy
            :z layer.z
            :rawgrid rawgrid
            :tileset-name layer.tileset-name
            :tileset (. map :tilesets layer.tileset-name)
            :tilegrid (match layer.layer-type
                        :autotile (autotile rawgrid layer.width)
                        :dense rawgrid)
            })
    (setmetatable layer _layer_mt)
    (layer:update)
    layer))

(fn draw-layer-tile [layer raw?]
  (if (and raw? (= "autotile" layer.layer-type))
      (each [i j tile (colrow layer.rawgrid layer.width layer.height)]
        (when (~= tile 0)
          (love.graphics.rectangle :fill (* i layer.tilesize) (* j layer.tilesize)
                                   layer.tilesize layer.tilesize)))
      (love.graphics.draw layer.spritebatch)))

(fn draw-layer-objs [layer objects]
  (assert (= layer.layer-type :objs) "Layer type must be :objs.")
  (love.graphics.draw layer.spritebatch)
  (each [_index obj (ipairs layer.objs)] (objects obj :draw))
  )

(fn replace-tile [layer i j new-tile]
  (assert (~= layer.layer-type :objs) "Layer type must be autotile or dense.")
  (let [index (ij-to-index i j layer.width)]
    (tset layer.rawgrid index new-tile)))

(fn remove-obj-name [layer obj-name objects]
  (assert (= layer.layer-type :objs) "Layer type must be :objs.")
  (each [i value (ipairs layer.objs)]
    (when (= value.name obj-name)
      (objects value :delete)
      (table.remove layer.objs i)
      ;; early return so we don't bork the list with multiple removals
      (lua "return layer,true")))
  (values layer false))

;; creates-garbage
(fn remove-obj-position [layer x y objects]
  (assert (= layer.layer-type :objs) "Layer type must be :objs.")
  (when _G.debug-tiles-obj (pp (string.format "removing object by position x:%d y:%d" x y)))
  (each [i obj (ipairs layer.objs)]
    (when (pointWithin x y obj.x obj.y obj.w obj.h)
      (when _G.debug-tiles-obj (pp (string.format "removing object name:%s" obj.name)))
      ;; (objects obj :delete) -- do in brush
      (table.remove layer.objs i)
      ;; early return so we don't bork the list with multiple removals
      (lua "return layer,obj")))
  (values layer false))

(fn add-obj [layer obj objects]
  (assert (= layer.layer-type :objs) "Layer type must be :objs.")
  (when (objects obj :unique) (remove-obj-name layer obj.name objects))
  ;; (objects obj :create) do this in the brush if you want, not here
  (table.insert layer.objs obj)
  (pp ["Tiles add-obj " obj])
  obj)

(fn draw-layer [layer objects raw?]
  (match layer.layer-type
    :objs (draw-layer-objs layer objects)
    _ (draw-layer-tile layer raw?)))

(fn update-layer [layer objects?]
  (match layer.layer-type
    :objs (update-obj-spritebatch layer objects?)
    _ (update-tile-spritebatch layer)))

(fn encode-layer [layer]
  (match layer.layer-type
    :objs (encode-obj layer)
    _ (encode-grid layer)))

(fn decode-layer [layer map objects]
  (match layer.layer-type
    :objs (decode-obj layer map objects)
    _ (decode-grid layer map)))

(fn offset-layer [layer ox oy]
  (tset layer :ox ox)
  (tset layer :oy oy)
  layer)

(fn debug-sparse-tiles [layer]
  (assert (~= layer.layer-type :objs)
          "debug-sparse-tiles only works with dense and autotile layers.")
  (each [_ i j tile (colrow layer.tilegrid layer.width layer.height)]
    (let [x (* i layer.tilesize)
          y (* j layer.tilesize)
          quad-name (. layer :tileset tile)
          quad (. layer :quads quad-name)]
      (pp [i j tile x y quad-name])))
    )

(tset _layer_mt :__index {:update update-layer
                          :encode encode-layer
                          :decode decode-layer
                          :offset offset-layer
                          :draw draw-layer
                          :replace replace-tile
                          :add-obj add-obj
                          :remove-obj-by-name remove-obj-name
                          :remove-obj remove-obj-position
                          : debug-sparse-tiles})

;; Map API
(local _mt {})
(fn draw [map objects]
  (when map.layers
    ;;; (pp map)
    (table.sort map.layers (fn [a b] (< a.z b.z)))
    (each [_ layer (ipairs map.layers)]
      ;; (pp layer.name)
      ;;(draw layer.spritebatch)
      (layer:draw objects)
      )))

(fn encode [map]
  {:tilesize map.tilesize
   :width map.width
   :height map.height
   :tilesets map.tilesets
   :layers (icollect [_ layer (ipairs map.layers)] (layer:encode))})

(fn decode [map image quads objects]
  (local map_out {:tilesize map.tilesize
              :width map.width
              :height map.height
              :tilesets map.tilesets
              : quads
              : image
              }
         )
  (tset map_out :layers (icollect [_ layer (ipairs map.layers)]
                          (decode-layer layer map_out objects)))
  (setmetatable map_out _mt)
  map_out)

(fn add-tileset [map name tileset]
  ;; tileset = [quad-name quad-name ....]
  (tset map :tilesets name tileset))

(fn add-layer [map name z layer-type tileset?|objs? rawgrid|objects?]
  (let [spritebatch (love.graphics.newSpriteBatch map.image (* map.width map.height))
        layer {: name
               : layer-type
               : spritebatch
               :tilesize map.tilesize
               :quads map.quads
               :width map.width
               :height map.height
               :ox 0
               :oy 0
               :z z}]
    (setmetatable layer _layer_mt)
    (match layer-type
      :objs (do (tset layer :objs tileset?|objs?)
               (layer:update rawgrid|objects?))
      :autotile (do
                  (tset layer :tileset-name tileset?|objs?)
                  (tset layer :tileset (. map :tilesets tileset?|objs?))
                  (tset layer :tilegrid (autotile rawgrid|objects? map.width))
                  (tset layer :rawgrid rawgrid|objects?)
                  (layer:update))
      :dense (do
               (tset layer :tileset-name tileset?|objs?)
               (tset layer :tileset (. map :tilesets tileset?|objs?))
               (tset layer :tilegrid rawgrid|objects?)
               (tset layer :rawgrid rawgrid|objects?)
               (layer:update)
               ))
    (table.insert map.layers layer)
    (values map layer)))

(fn create [image quads width height tilesize]
  (local map {:tilesets {}
              :image image
              :quads quads
              :tilesize tilesize
              :width width
              :height height
              :layers []})
  (setmetatable map _mt)
  map)

(tset _mt :__index {: create
                    : draw
                    : add-layer
                    : add-tileset
                    : encode
                    : decode})

{: create : decode : index-to-ij : ij-to-index}
