;;
;; colour
;;
;; Copyright (c) 2020 alexjgriffith
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy of
;; this software and associated documentation files (the "Software"), to deal in
;; the Software without restriction, including without limitation the rights to
;; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is furnished to do
;; so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.
;;

(local colour {:_version "0.1.0"})

(local math-max math.max)
(local math-min math.min)
(local math-floor math.floor)
(local math-exp math.exp)
(local table-insert table.insert)
(local table-concat table.concat)
;; (local unpack (or unpack table.unpack))
(local string-char string.char)

;; Utilities
(fn map [t fun]
  "Apply functino fun to each member of table t returning a new table."
  (local rtn {})
  (each [key value (pairs t)]
    (tset rtn key (fun value)))
  rtn)

(fn max [t]
  "Return the maximum numeric value in table t."
    (var ret (. t 1))
    (for [i 2 (# t)]
         (let [v (. t i)]
           (when (> v ret)
             (set ret v))))
    ret)

(fn min [t]
  "Return the minimum numeric value in table t."
    (var ret (. t 1))
    (for [i 2 (# t)]
         (let [v (. t i)]
           (when (< v ret)
             (set ret v))))
    ret)

(fn int-clamp-0-255 [value]
  "Clamp value between 0 and 255."
  (math-min (math-max (math-floor (* 255 value)) 0) 255))

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

;; API
(fn colour.hex-to-rgba [hex]
  "Convert a HEX code into a percent RGB.

Returns an array [R G B A] A is alway 1.0.
Example:
(colour.hex-to-rgba :#4f3645)"
  (let [hexcodes [(string.sub hex 2 3)
                  (string.sub hex 4 5)
                  (string.sub hex 6 7)
                  "FF"]]
    (-> hexcodes
        (map hex-to-dec)
        (map (fn [x] (/ x 255.0)))
        )
    )
  )

(fn colour.hsl-to-rgb [hin s l a]
  "Convert HSL to RGB.
Note A remains unchanged."
    (var [r g b] [0 0 0])
    (local h (/ hin 360))
    (local hue2rgb (fn hue2rgb [p q tin]
                       (var t tin)
                       (when (< t  0) (set t (+ t 1)))
                       (when (> t  1) (set t (- t 1)))
                       (if
                        (< t  (/ 1 6)) (+ p (* t 6 (+ q (- p))))
                        (< t  (/ 1 2)) q
                        (< t  (/ 2 3)) (+ p (* (+ (/ 2 3) (- t)) 6 (+ q (- p))))
                        p)))
    (if (= s 0)
        (set [r g b] [l l l])
        (let [q (if (< l 0.5) (* l (+ 1 s)) (+ l s (- (* l s))))
              p (+ (* 2 l) (- q))]
          (set r  (hue2rgb p q (+ h (/ 1 3))))
          (set g  (hue2rgb p q h))
          (set b  (hue2rgb p q (+ h (- (/ 1 3)))))))
    [r g b a])

(fn colour.normalize [te min? max?]
  "Normalize numeric table te within min? and max? or min and max of te.

BROKEN! Need to update to actually work with min? and max?"
  (let [max (or max? (max te))
        min (or min? (min te))]
        (map te (fn [e] (/ (+ e (- min)) (+ max (- min)))))))

(fn colour.sigmoid [x vmax xmid k]
  "Return the sigmoid y for the independent variable x and
parameters including vmax xmid and k."
    (/ vmax (+ 1 (math-exp (- (* k (+ x (- xmid))))))))

(fn colour.noise [noise width height off freq amp]
  "Generate an array based on funciton noise.
Example noise function love.math.noise"
    (var value {})
    (var val 0)
    (for [i 1 width]
         (for [j 1 height]
              (set val 0)
              (for [k 1 6]
                   (set val (+ val (* (/ amp k) (noise
                                                 (+ off (* freq k (/ i width)))
                                                 (+ off (* freq k (/ j height))))))))
              (table-insert value val)))
    (colour.normalize value))

(fn colour.rgb-to-byte [[r g b a]]
  "Take 0 - 255 ranged rgba and convert them into a list of chars."
  (string-char
   (int-clamp-0-255 r) (int-clamp-0-255 g) (int-clamp-0-255 b) (int-clamp-0-255 a)))

(fn colour.rgb-array-to-bytedata [array]
  "Convert rgb array to bytedata"
  (local rgb-to-byte colour.rgb-to-byte)
  (local tab [])
  (each [_ rgb (ipairs array)]
    (table-insert tab (rgb-to-byte rgb)))
  (table-concat tab ""))

(fn colour.hsl-array-to-bytedata [array]
  "Convert hsl array to bytedata suitible for love newImage"
  (local rgb-to-byte colour.rgb-to-byte)
  (local hsl-to-rgb colour.hsl-to-rgb)
  (local tab [])
  (each [_ rgb (ipairs array)]
    ;;(pp rgb)
    (table-insert tab (rgb-to-byte (hsl-to-rgb (unpack rgb)))))
  (table-concat tab ""))

colour
