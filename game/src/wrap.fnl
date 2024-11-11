(global _js_eval (fn [call] (fennel.eval call)))

(local json (require :lib.json))

(local js (require :js))

;; ;; Error: attempt to yield across metamethod/C-call boundary
;; ;; Issue with LUA PUC 5.1
;; (local repl-options
;;        {:readChunk (fn [{: stack-size}]
;;                      (let [input (coroutine.yield)]
;;                        ;; send event to js
;;                        (print (.. "> " input))
;;                        (.. input "\n")))
;;         :onValues (fn [vals]
;;                     (print (table.concat vals "\t"))
;;                     ;; send event to js
;;                     )
;;         :onError (fn [_ err] (print (.. "Error: " err)))
;;         :moduleName "lib.fennel"})

;; (local repl (coroutine.create (partial fennel.repl)))
;; (coroutine.resume repl repl-options)

;; (fn love.handlers.eval [data]
;;   (coroutine.resume repl data))

(local welcome-string (string.format "Welcome to Love2D 11.5 running with Fennel %s on PUC %s" fennel.version _VERSION))
(print welcome-string)

(fn love.handlers.eval [data]
  (print (.. "> " data))
  (pp (fennel.eval data)))

(fn love.handlers.echo [data]
  (pp data))

;; (js.send-custom-json-event :echo "{\"data\":1}")

(fn love.userevent [name data code]
  ;; (pp [name data code])
  (when (pcall (fn [] (. love.handlers name)))
    (love.event.push name data code)
    )
  ;; (match name
  ;;   :eval (love.event.push :eval data))
  )


(local websockets (require :websockets))

(local websocket (websockets.new "wss://echo.websocket.org" "echo" 1))

;; (js.example-event)

(fn love.load [])

(var str "")

(fn love.update [dt])

(fn love.keypressed [key]
  (match key
    :h (let [js (require :js)] (js.call "
{
var output = document.getElementById('output');
if (output.style.display == 'none'){
  output.style.display = 'block';
}
else {
  output.style.display = 'none';
}
}"
                                       ))))

(fn love.draw []
  (love.graphics.print "Hello world"))
