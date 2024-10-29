(local love (require :love))

(love.graphics.setDefaultFilter :nearest :nearest)

(fn make-quad-grid [image tw th]
  (let [(iw ih) (image:getDimensions)
        (columns rows) (values (/ iw tw) (/ ih th))
        grid (require :lib.grid)
        g (grid.new columns rows)]
    (g:apply (fn [_ x y data key]
               (tset data key (love.graphics.newQuad (* x tw) (* y th) tw th iw ih))))
    g))

(local atlas {:image (love.graphics.newImage "assets/sprites/Hex-Layout.png")
              :index (require :src.atlas-index)})

(set atlas.quad-grid (make-quad-grid atlas.image 32 48))


(local sprites {:image (love.graphics.newImage "assets/sprites/sprites.png")
              :index (require :src.atlas-index)})

(set sprites.quad-grid (make-quad-grid sprites.image 32 32))

(fn sprites.draw [sp name ...]
  (local tile-id (. sp.index.map name))
  ;; (pp [tile-id name])
  (love.graphics.draw sp.image (sp.quad-grid:get tile-id 0) ... ))

(local icon-image (love.graphics.newImage "assets/sprites/icons.png"))
(local quad-icons (let [{: icons} (require :src.atlas-index)
                            (w h) (icon-image:getDimensions)]
                        (collect [name [i j] (pairs icons)]
                          (values name (love.graphics.newQuad (*  i 16) (* j 16) 16 16 w h)))))


(fn get-quads [...]
  (values (unpack (icollect [_ name (ipairs [...])]
                    (. atlas.quad-grid (. atlas.index.map name))))))

(fn draw-tile [name ...]
  (let [(i j) (. atlas.index.map name)]
    (love.graphics.draw atlas.image (. atlas.quad-grid.data (+ i 1)) ...)))

(fn draw-icon [name ...]
  (love.graphics.draw icon-image (. quad-icons name) ...))

(when _G.dev
  (local watch (require :lib.watch))
  (watch.watch "/art/Hex-Layout.aseprite"
         (fn [] (match (love.system.getOS)
                  :Linux (os.execute "./export.sh"))
           ;; wait 2 frames to make sure the export is succsesful
           (love.timer.sleep (/ 2 60))
           (set atlas.image (love.graphics.newImage "assets/sprites/Hex-Layout.png")))))

(local pixel->triangle  "assets/sprites/pixel-hex-triangles.png")




;;(local cursorImage (love.graphics.newImage "assets/sprites/cursors.png"))
;; (local normalCursorCanvas (love.graphics.newCanvas (* 5 16) (* 5 16)))
;; (local normalCursorQuad (love.graphics.newQuad 0 0 16 16 (* 5 16) (* 5 16)))
;; (love.graphics.push :all)
;; (love.graphics.setCanvas normalCursorCanvas)
;; (love.graphics.scale 5)
;; (love.graphics.draw cursorImage normalCursorQuad)
;; (love.graphics.pop)
;; (local normalCursorImagedata (normalCursorCanvas:newImageData))
;; ;; (local normalCursor (love.mouse.newCursor normalCursorImagedata 0 0))
;; (local moveCursorCanvas (love.graphics.newCanvas (* 5 16) (* 5 16)))
;; (local moveCursorQuad (love.graphics.newQuad 16 0 16 16 (* 5 16) (* 5 16)))
;; (love.graphics.push :all)
;; (love.graphics.setCanvas moveCursorCanvas)
;; (love.graphics.scale 5)
;; (love.graphics.draw cursorImage moveCursorQuad)
;; (love.graphics.pop)
;; (local moveCursorImagedata (moveCursorCanvas:newImageData))
;; (local moveCursor (love.mouse.newCursor moveCursorImagedata (* 5 7) (* 5 13)))

;; (fn make-cursor [i j hx hy]
;;   (local (ox oy) (values (* (- i 1) 16) (* (- j 1) 16)))
;;   (local cursorCanvas (love.graphics.newCanvas (* 5 16) (* 5 16)))
;;   (local cursorQuad (love.graphics.newQuad ox oy 16 16 (* 5 16) (* 5 16)))
;;   (love.graphics.push :all)
;;   (love.graphics.setCanvas cursorCanvas)
;;   (love.graphics.scale 5)
;;   (love.graphics.draw cursorImage cursorQuad)
;;   (love.graphics.pop)
;;   (local cursorImagedata (cursorCanvas:newImageData))
;;   (love.mouse.newCursor cursorImagedata (* 5 hx) (* 5 hy))
;;   )

;; (local xCursor (make-cursor 3 1 8 8))
;; (local swordCursor (make-cursor 4 1 0 0))
;; (local moveCursor1 (make-cursor 1 2 7 13))
;; (local moveCursor2 (make-cursor 2 2 7 13))

(local normalCursor (love.mouse.newCursor "assets/sprites/cursor.png" 0 0))
(local xCursor (love.mouse.newCursor "assets/sprites/cursor-x.png" (* 8 5) (* 8 5)))
(local swordCursor (love.mouse.newCursor "assets/sprites/cursor-sword.png" 0 0))
(local moveCursor1 (love.mouse.newCursor "assets/sprites/cursor-down1.png" (* 5 7) (* 5 13)))
(local moveCursor2 (love.mouse.newCursor "assets/sprites/cursor-down2.png" (* 7 5) (* 13 5)))
(local panCursor (love.mouse.newCursor "assets/sprites/cursor-pan.png" (* 8 5) (* 8 5)))
(local qCursor (love.mouse.newCursor "assets/sprites/cursor-q.png" (* 8 5) (* 8 5)))
(local moveCursor moveCursor1)


(local snowImage (love.graphics.newImage "assets/sprites/snow.png"))

;; audio effects for reverb
(love.audio.setEffect "reverb" {:type "reverb" :earlygain 1 :decaytime 2 :roomrolloff 0 :density 0.8})

(fn add-reverb [source] (source:setEffect "reverb") source)

(fn loop [source] (source:setLooping true) source)

(fn set-volume [source level] (source:setVolume level) source)

(local bgm (love.audio.newSource :assets/music/winter.ogg (if _G.web :static :stream)))
(-> bgm (set-volume 1) (loop))

(fn load-sfx [name level? mods]
  (let [dir "assets/sounds/"
        suffix ".ogg"
        level (or level? 1)
        source-type :static
        source (love.audio.newSource (.. dir name suffix) source-type)]
    (source:setVolume level)
    (when mods (mods source))
    source))

(local effects
       {:hover1 (load-sfx :sfx-hover-1)
        :hover2 (load-sfx :sfx-hover-2)
        :hover3 (load-sfx :sfx-hover-3)
        :hover4 (load-sfx :sfx-hover-4)
        :talk (load-sfx :talk2 0.3 )
        :talk3 (load-sfx :talk3 0.08 )
        :talk4 (load-sfx :talk4 0.08 )
        :talk5 (load-sfx :talk5 0.08 )
        :talk6 (load-sfx :talk6 0.08 )
        :talk2 (load-sfx :sfx-hover-1 0.3 )
        :hurt (load-sfx :sfx-hurt 0.3)
        :page (load-sfx :page 0.3)
        :bounce (load-sfx :bounce 1.2)
        :click (load-sfx :sfx-click)
        :birds (load-sfx :birds 0)
        :fire (load-sfx :fire-mono 0)
        :fire-light (load-sfx :fire-light 0.2)
        :fire-out (load-sfx :fire-out 0.2)
        :chop (load-sfx :chop 0)
        :scifi (load-sfx :scifi 1)
        :howl (load-sfx :howl 1)
        :door (load-sfx :door 0.3 )
        :footsteps (load-sfx :footsteps-short 0.3)
        :footsteps-wood (load-sfx :footsteps-wood 0.5)
        })

(fn load-loop [name]
  (let [sound (load-sfx name 0)]
    (sound:setVolume 0)
    (sound:play)
    (sound:setLooping true)
    sound))

(effects.fire:play)
(effects.fire:setLooping true)
(effects.footsteps:setLooping true)
;; (effects.birds:play)
(effects.birds:setLooping true)

(local fonts
       {;;:text (love.graphics.newFont :assets/fonts/notjamui12.ttf 12)
        :small-text (love.graphics.newFont :assets/fonts/notjamui12.ttf 12)
        :t14 (love.graphics.newFont :assets/fonts/notjamui12.ttf 14)
        :t15 (love.graphics.newFont :assets/fonts/notjamui15.ttf 15)
        :t16 (love.graphics.newFont :assets/fonts/notjamui12.ttf 14)
        :mid-text (love.graphics.newFont :assets/fonts/notjamui12.ttf 18)
        :text (love.graphics.newFont :assets/fonts/notjamui12.ttf 24)
        :big-text (love.graphics.newFont :assets/fonts/notjamui12.ttf 30)
        :subtitle (love.graphics.newFont :assets/fonts/notjamui15.ttf 48)
        :title (love.graphics.newFont :assets/fonts/notjamui15.ttf 60)})

(local shaders
       {:default (love.graphics.newShader :assets/shaders/default.glsl)})

(fn load-translation-file [file text prefix]
  (let [string (love.filesystem.read (.. "assets/text/" file))
        csv (require :lib.csv)
        f (csv.openstring string  {:separator "," :header true})]
    (assert f (string.format "unable to open %s" (.. "assets/text/" file)))
    (each [line (f:lines)]
      (let [key (.. (or prefix "") line.key)]
        (tset text key {})
        (each [language value (pairs line)]
          (when (~= language :key)
            (tset text key language value)))))
    text))

(local text {})

(each [_ file (ipairs [:game-text])]
  (load-translation-file (.. file :.csv) text (.. file "-")))

;; it would be cool to watch and update this file live
;; would make editing autotiles much easier
(local autotile-hex (require :src.autotile-hex))
(local autotile {:water (autotile-hex.water)})

{: atlas
 :cursors {:normal normalCursor :move moveCursor :move1 moveCursor1 :move2 moveCursor2 :x xCursor :sword swordCursor
           :pan panCursor :q qCursor }
 : snowImage
 : pixel->triangle
 : effects
 : bgm
 : fonts
 : text
 : shaders
 : load-loop
 : draw-icon
 : draw-tile
 : get-quads
 : sprites
 : autotile
 }
