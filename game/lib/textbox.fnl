; fennel-ls: macro-file.
(local love (require :love))
(local lg love.graphics)

(local {: scroll-text : wrap-text} (require :lib.text))

;; (import-macros {: once} :macro)

(local test-text "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")

(local empty-string (fn [] ""))

(local default-params
       {:font (lg.getFont)
        :text-width 600
        :text-height 200
        :speed 40
        :update-text-function empty-string
        :next-char-callback empty-string
        :text ""
        :printed ""
        :visible false
        :discussion-system nil
        :name nil})

(fn init [{: text-font : text-wdith : text-height : speed
           : update-text-function : next-char-callback : visible
           : discussion-system
           &as options}]
  (local state (require :src.state))
  (set state.textbox {})
  (local lume (require :lib.lume))
  (set state.textbox.params (lume.clone default-params))
  (local {:textbox {: params}} (require :src.state))
  (each [key value (pairs options)]
    (when value (tset params key value)))) 

(fn load-text [text]
  (local {:textbox {: params}} (require :src.state))
  (let [{: text-width : font : speed : next-char-callback} params]
    (scroll-text (wrap-text text text-width font) speed next-char-callback)))

(fn display [text questions? name? next-char-callback?]
  (local {:textbox {: params}} (require :src.state))
  (set params.printed "")
  (set params.text text)
  (set params.visible true)
  (set params.questions (or questions? []))
  (set params.name (or name? nil))
  (set params.next-char-callback (or next-char-callback? empty-string))
  (set params.update-text-function (load-text text)))

(fn hide []
  (local {:textbox {: params}} (require :src.state))
  (set params.visible false))

(fn update [dt]
  (local {:textbox {: params}} (require :src.state))
  (when params.visible (set params.printed (params.update-text-function dt))))

(fn next* [option?]
  (local {:textbox {: params}} (require :src.state))
  (params.update-text-function 0 :skip))

(fn finished? []
  (local {:textbox {: params}} (require :src.state))
  (<= (# params.text) (# params.printed)))

(fn draw-text [text]
  (local {:textbox {: params}} (require :src.state))
  (let [(w h) (love.window.getMode)
        {: text-width : font : text-height} params
        margin 10]
    (lg.push :all)
    (lg.setFont font)
    (lg.setColor 0 0 0 1)
    (lg.rectangle :fill  (- (/ (- w text-width) 2) margin)
                  (-  h text-height 40 margin)
                  (+ text-width (* 2 margin)) (+ text-height (* 2 margin)) 5)
    (lg.setColor 1 1 1 1)
    (lg.printf text (/ (- w text-width) 2) (-  h 40 text-height) text-width)
    (lg.pop)))

(fn draw-questions []
  (local {:textbox {: params}} (require :src.state))
  (when (finished?)
    (lg.push :all)
    (let [(w h) (love.window.getMode)
          font params.font
          height (font:getHeight "l")
          width (- 580 20 50)
          margin 10
          x-offset 50
           y-offset (- h 40 )
          line-height 1.5
          ]
      (lg.translate x-offset y-offset)
      (lg.setFont font)
      (font:setLineHeight line-height)
      (each [j _ (ipairs params.questions)]
        (local qlen (# params.questions))
        (local i (- qlen j -1))
        (local question (. params.questions i))
        (when (< i 8)
          (lg.setColor 0 0 0 1)
          (local count (.. (tostring i) ": "))
          (local string  question)
          (local (text l) (wrap-text string width font))
          (local hl (* height (* l line-height)))
          (lg.translate 0 (- (+ hl (* 2 margin))))
          (lg.rectangle :fill 0 0 580 (+ hl (* 2 margin)) 5)
          (lg.setColor 1 1 1 1)
          ;;(lg.print string margin 0)
          (lg.print count margin margin)
          (lg.print text (+ 50 margin) margin)
          (lg.translate 0 (- margin))))
      (font:setLineHeight 1)
      )
    (lg.pop)
    ))

(fn draw-name [name]
  (local {:textbox {: params}} (require :src.state))
  (let [(w h) (love.window.getMode)
        {: text-width : font : text-height} params
        margin 10
        height (font:getHeight name)]
    (lg.push :all)
    (lg.setFont font)
    (lg.setColor 0 0 0 1)
    (lg.rectangle :fill
                  (- (/ (- w text-width) 2) margin)
                  (-  h text-height 40 (* 4 margin) height)
                  (+ (font:getWidth name) (* 2 margin))
                  (+ height (* 2 margin))
                  5)
    (lg.setColor 1 1 1 1)
    (lg.print name (/ (- w text-width) 2) (-  h 40 text-height height (* 3 margin)) )
    (lg.pop)))


(fn draw []
  (local {:textbox {: params}} (require :src.state))
  (lg.push :all)
  (lg.scale 1)
  (draw-text params.printed)
  (when (> (# params.questions) 0) (draw-questions))
  (when params.name (draw-name params.name))
  (lg.pop))

{: init : update : draw  : test-text : display : hide :next next* : finished?}
