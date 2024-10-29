;; navigate.fnl

(fn make-2-queue []
  (local queue-fns {:get (fn [q] (when (<= q.index (# q.data))
                                   (set q.index (+ q.index 2))
                                   (values (. q.data (- q.index 2)) (. q.data (- q.index 1)))
                                   ))
                    :put (fn [q value1 value2]
                           (table.insert q.data value1)
                           (table.insert q.data value2))
                    :empty (fn [q] (< (# q.data) q.index))
                    :clear (fn [q] (for [i 1 (# q.data)]
                                     (set q.index 1)
                                     (tset q.data i nil)))
                  })
  (local queue-mt {:__index queue-fns})
  (setmetatable {:data [] :index 1} queue-mt))

(local front (make-2-queue))

(fn generate-path [index1 limit get-neighbours tile-cost tile-passable]
  " Use bredth first search to get paths to all tiles within a cost limit.
index1 (number)
limit (number)
(get-neighbours index (number))
(tile-cost tile-type (number))
(tile-passable tile-type index)
"
  ;; breadth first search with cost limit  
  (front:clear)
  (front:put index1 0)
  (local path {index1 [:START 0]}) ;; start indicator and 0 accumulated cost
  (while (not (front:empty))
    (local (current-index current-cost) (front:get))
    (var leaf true)
    (each [_ [next-index tile-type] (ipairs (get-neighbours current-index))]
      (let [additional-cost (tile-cost tile-type)
            next-cost (do (+ current-cost additional-cost))
            previous (. path next-index)
            previous-next-cost (when previous (. previous 2))]
        (if (or (> next-cost limit) (not (tile-passable next-index tile-type)))
            :dont-continue
            (when (or (not previous-next-cost) (> previous-next-cost (+ current-cost additional-cost)))
              (set leaf false)
              (front:put next-index next-cost)
              (tset path next-index [current-index next-cost tile-type])))))
    (when leaf
      (tset path current-index 4 :edge)))
  path
  )

(fn generate-view [index1 limit get-neighbours tile-view-cost get-self tile-view-bonus]
  " Use bredth first search to get what is visible to a unit.
index1 (number)
limit (number)
(get-neighbours index (number))
(tile-cost tile-type (number))
(tile-passable tile-type index)
"
  ;; breadth first search with cost limit  
  (front:clear)
  (front:put index1 0)
  (local path {index1 [:START 0]}) ;; start indicator and 0 accumulated cost
  (local bonus (tile-view-bonus (get-self index1)))
  (while (not (front:empty))
    (local (current-index current-cost) (front:get))
    (each [_ [next-index tile-type] (ipairs (get-neighbours current-index))]
      (let [additional-cost (tile-view-cost tile-type)
            next-cost (do (+ current-cost additional-cost))
            previous (. path next-index)
            previous-next-cost (when previous (. previous 2))]
        (if (> next-cost (+ limit bonus))
            (do "see one last tile"
                (when (or (not previous-next-cost) (> previous-next-cost (+ current-cost additional-cost)))
              (tset path next-index [current-index next-cost tile-type]))
                )
            (when (or (not previous-next-cost) (> previous-next-cost (+ current-cost additional-cost)))
              (front:put next-index next-cost)
              (tset path next-index [current-index next-cost tile-type]))))))
  path)


(fn _path-to-helper [path index2 ]
  (local ret [])
  (var previous index2)
  (while (~= previous :START)
    (table.insert ret previous)
    (set previous (. path previous 1)))
  ret
  )

(fn outer-ring [path get-neighbours-strict ret?]
  "
(get-neighbours-strict index default) => [-1 -1 2 3 4]"
  (local ret (or ret? []))
  (each [key _value (pairs ret)] (tset ret key nil)) ;; clear ret
  (each [index _ (pairs path)]
    (var narray [])
    (var all-neighbours true )
    (each [i n (ipairs (get-neighbours-strict index -1))]
      (let [has-neighbour (. path n)]
        (when (not has-neighbour)
          (table.insert narray i)
          (set all-neighbours false)
          ;;(set narray (+ narray (^ (- i 1) 2)))
          )))    
    (when (not all-neighbours) (tset ret index narray)))
  ret)

(fn path-to [path index2 tile-passable]
  (local [previous cost tile-type] (or (. path index2) [false 100 6]))
  (if
   (= previous :START)
   (values [] cost)
   (or (not previous) (not (tile-passable index2 tile-type)))
   nil
   (values (_path-to-helper path index2) cost)
   ))

{: generate-path : generate-view : path-to : outer-ring}
