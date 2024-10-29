;; fennel-ls: macro-file.
(local debug-mode false)
(local log-file (when debug-mode :log.txt))

(local once-array {})
(fn once [& body]
  `(let [fennel# (require :lib.fennel)
         body-string# (fennel#.view ,body)
         in-array?# (. ,once-array body-string#)]
     (when (not in-array?#)
       (tset ,once-array body-string# true)
       (pp ,once-array)
       (print body-string#))))

(fn debug [& body]
  (when debug-mode `(unpack ,body)))

(fn log [& body]
  (when log-file
    `(let [love# (require :love)
           fennel# (require :lib.fennel)]
       (when (not (love#.filesystem.isFused))
          (let [file# (or _G._log-file (io.open (.. (love#.filesystem.getSource) :logs/ ,log-file) :a))]
            (when file#
              (file#:write (fennel#.view (unpack ,body)))
              (file#:write "\n")
              (when (not _G._log-file) (file#:close))
              ))))))

(fn clear-log []
  (when log-file
    `(let [love# (require :love)
           fennel# (require :lib.fennel)]
       (when (not (love#.filesystem.isFused))
          (let [file# (io.open (.. (love#.filesystem.getSource) :logs/ ,log-file) :w)]
            (when file#
              (file#:write (fennel#.view (.. (os.date) "\n\n")))
              (file#:close)))))))

(fn setgevent [event-name function unique-suffix?]
  "Ensure that signals are properly set when the module is reset."
  `(let [estring# ,(tostring event-name)
         fstring# ,(.. (tostring function) (or unique-suffix? ""))
         signals# (require :lib.signal)
         valid-events# (require :src.events.valid-events)]
     (assert (. valid-events# estring#) (string.format "Event name `%s` not defined in valid events" estring#))
     (when (not (. _G :_events)) (tset _G :_events {}))
     (when (not (. _G :_events estring#)) (tset _G :_events estring# {}))
     (when (. _G :_events estring# fstring#)
       (signals#.remove estring#  (. _G :_events estring# fstring#)))
     (tset _G :_events estring# fstring# ,function)
     (signals#.register estring#  (. _G :_events estring# fstring#))))

(fn setgmeta [module name-value]
  `(let [mstring# ,(tostring module)]
     (when (not (. _G :_components)) (tset _G :_components {}))
     (when (not (. _G :_components mstring#)) (tset _G :_components mstring# {}))
     (when (not (. _G :_components mstring# :__index)) (tset _G :_components mstring# :__index {}))
     (each [key# value# (pairs ,name-value)]
       (tset _G :_components mstring# :__index key# value#))))

(fn getgmeta [module]
  `(let [mstring# ,(tostring module)]
     (?. _G :_components mstring#)))

(fn incr [x by]
  `(do (set ,x (+ ,x (or ,by 1))) ,x))

(fn incrb [x by limit]
  `(if (> (+ ,x ,by) ,limit) (set ,x 1) (set ,x (+ ,x ,by))))

(fn insert [t key value]
  `(if (. ,t ,key) (table.insert (. ,t ,key) ,value) (tset ,t ,key [,value])))

;; is it worth it
;; load all text in one go and store it in resources
(fn gtext [string]
  "Get text from global text resouce table."
  `(let [params# (require :src.params)
         resources# (require :src.resources)]
     (?. resources# :text ,string params#.language)))

(fn stext [key language string]
  "Set text from global text resouce table."
  `(let [resources# (require :src.resources)]
     (when (not (. resources# :text ,key)) (tset resources# :text ,key {}))
     (when (not (. resources# :text ,key ,language)) (tset resources# :text ,key ,language {}))
     (tset resources# :text ,key ,language ,string)))

(fn hex-to-rgb [hexsymbol]
  ;; #7f7f7f
  (fn map [t fun]
    "Apply function fun to each member of table t returning a new table."
    (local rtn {})
    (each [key value (pairs t)]
      (tset rtn key (fun value)))
    rtn)
  (fn hex-to-dec [hex]
    "Takes a two digit hex and returns an dec between 0 and 255."
    (let [first (string.sub hex 1 1)
          second (string.sub hex 2 2)
          to-dec {"0" 0 "1" 1 "2" 2
                  "3" 3 "4" 4 "5" 5
                  "6" 6 "7" 7 "8" 8
                  "9" 9
                  "A" 10  "a" 10
                  "B" 11 "b" 11
                  "C" 12 "c" 12
                  "D" 13 "d" 13
                  "E" 14 "e" 14
                  "F" 15 "f" 15}]
      (+ (* 16 (. to-dec first))  (. to-dec second))))
  (let [hex (tostring hexsymbol)
        hexcodes [(string.sub hex 1 2)
                  (string.sub hex 3 4)
                  (string.sub hex 5 6)
                  "FF"]]
    (-> hexcodes
        (map hex-to-dec)
        (map (fn [x] (/ x 255.0))))))

(fn hex [hex]
  "Takes either a hex as a string with 6 (:rrggbb) chars or 8 chars (:rrggbbaa).
In the case where there are 6 chars the final two alpha chars are set to ff.

(import-macros {: hex} :hex)
(hex :0d2b45)
(hex :203c5633)
"
  (local hex-map {:0 0 :1 1 :2 2 :3 3 :4 4 :5 5 :6 6 :7 7 :8 8 :9 9
                  :a 10 :b 11 :c 12 :d 13 :e 14 :f 15
                  :A 10 :B 11 :C 12 :D 13 :E 14 :F 15})
  (let [hex8 (if (= (# hex) 8) hex (.. hex "ff"))]
    (fcollect [i 1 8 2]
      (/ (+ (* 16 (. hex-map (string.sub hex8 i i)))
            (. hex-map (string.sub hex8 (+ i 1) (+ i 1)))) 255.0))))

{: incr : incrb : insert : debug : log : clear-log : once : setgevent : setgmeta : getgmeta
 : gtext : stext : hex-to-rgb : hex}
