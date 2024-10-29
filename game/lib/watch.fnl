(local files {})
(fn set-callback [file callback]
  (tset files file :callback callback))

(fn watch [file callback]
  (tset files file {:time (-> (love.filesystem.getInfo file) (. :modtime))
                    :callback callback}))

(fn update []
  (each [file {: time : callback} (pairs files)]
    (local recent-time (-> (love.filesystem.getInfo file) (. :modtime)))
    (when (~= time recent-time)
      (callback)
      (tset  files file :time recent-time))
    ))

{: watch : update : set-callback}
