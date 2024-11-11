(local fennel (require :lib.fennel))

(local repl-options
       {:readChunk (fn [{: stack-size}]
                     (coroutine.yield))
        :onValues (fn [vals]
                    (print (table.concat vals "\t"))
                    )
        :onError (fn [_ err] (print (.. "Error: " err)))
        :moduleName "lib.fennel"
        :env nil})



(local repl (coroutine.create (. (getmetatable fennel.repl) :__index :repl)))

(coroutine.resume repl repl-options)
