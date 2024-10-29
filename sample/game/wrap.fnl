(print :preloaded)
(each [key value (pairs _G.package.preload)] (print (.. key " " (type value))))
(print :loaded)
(each [key value (pairs _G.package.loaded)] (print (.. key " " (type value))))

(local js-http (require :js-http))
(pp (js-http.call "console.log(1001)"))
(global root (js-http.make :https://algg2024.alexjgriffith.com))
(pp (getmetatable root))
(root:request "handle" "/request" "GET" "{}" "")

(pp :HELLO_WORLD)

(global _js_eval (fn [call] (fennel.eval call)))
