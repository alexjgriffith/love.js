(fn wrap-text [text text-width font]
  (var display-text "")
  (local (_ wrapped-text) (font:getWrap text text-width))
  (each [_ line (ipairs wrapped-text)]
    (set display-text (.. display-text line "\n")))
  (values display-text (# wrapped-text)))

(fn scroll-text [text speed newchar-callback]
  (var printed "")
  (var timer 0)
  (local whitespace {" " true "." true "*" true "\n" true})
  (fn update [dt skip?]
    (when skip? (set timer (# text)))
    (set timer (+ timer (* dt speed)))
    (local next-printed (string.sub text 0 (math.min timer (# text))))
    (when (~= (# printed) (# next-printed))
      (when (not (. whitespace (. next-printed (# next-printed))))
        (newchar-callback))
      (set printed next-printed))
    printed))


{: wrap-text : scroll-text}
