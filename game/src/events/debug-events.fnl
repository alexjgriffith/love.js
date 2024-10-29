;; debug-events.fnl
(local events (require :src.events.valid-events))

(local signal (require :lib.signal))

(tset _G :_A10F [])

(fn listen-gen [name]
  (fn encode [something] (tostring something))
  (fn summarize [...]
    (var ret "")
    (let [tab [...]]
      (when (> (# tab) 0)
        (set ret (.. ret (encode (. tab 1))))
        (when (> (# tab) 1)
          (for [i 2 (# tab)]
            (set ret (.. ret ", " (encode (. tab i))))
            ))))
    ret
    )
  (fn [...]
    (let [lume (require :lib.lume)
          args (summarize ...)
          ref (.. "_G._A10F." name)]
      (tset _G._A10F name (lume.clone [...]))
      (when (~= name :game-update)
        (print (string.format "Event:%s Args:%s Ref:%s"
                            name
                            args
                            ref)))
      (io.flush))))

(local event-functions
       (collect [event-name _ (pairs events)]
         (values event-name (listen-gen event-name))))

(fn register []
  (each [event-name event-function (pairs event-functions)]
    (signal.register event-name event-function)))

(fn unregister []
  (each [event-name event-function (pairs event-functions)]
    (signal.remove event-name event-function)))

{: register : unregister}
