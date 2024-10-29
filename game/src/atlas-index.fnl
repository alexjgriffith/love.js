;; atlas-index.fnl

(fn i [x y]
  (let [w 16]
    (+ x (* w y))))

(local features1 [:frozen-fort :tower2 :church :tower1 :city1 :city2 :city3 :city4 :fort1 :fort2 :fort3 :fort4 :walls1 :walls2 :wall3 :walls4])
(local features2 [:village1 :village2 :village3 :village4 :inn :house1 :house2 :house3 :garden1 :garden2 :garden3 :garden4 :pond :shrine :fire :circle])

(local index
       {:map
        {:mountains 0 :hills 1 :grass 2 :field 3 :desert 4 :trees 5 :ocean 6
         :water-auto (i 0 10)
         :outline-auto (i 0 14)
         :road (i 0 4)
         :river (i 0 5)
         :coast (i 0 6)
         :border (i 8 5)
         :pathing (i 8 4)
         :hasnt-seen (i 10 1)
         :has-seen (i 11 1)
         :can-see (i 13 1)
         ;;  :walls1 (i 0 2) :tower1 (i 1 2) :house1 (i 2 2) :church (i 3 2) :tower2 (i 4 2) :city1 (i 5 2) :house2 (i 6 2) :house3 (i 7 2)
         ;; :garden (i 0 3) :walls2 (i 1 3) :pond (i 2 3) :shrine (i 3 3) :fire (i 4 3) :circle (i 5 3)
       :star4 (i 0 6)
       :star1 (i 1 6)
       :star2 (i 2 6)
       :star3 (i 3 6)
       :flagwhite (i 0 7)
       :flagblue (i 1 7)
       :flagyellow (i 2 7)
       :flagred (i 3 7)
         :small-goblin (i 0 8)
         :medium-goblin (i 1 8)
         :large-goblin (i 2 8)
         :orc (i 3 8)
         :frozen-duke (i 4 8)
       :gnome1 (i 0 9)
       :gnome2 (i 1 9)
       :gnome3 (i 2 9)
       :gnome4 (i 3 9)
       :gnome5 (i 4 9)
       :gnome6 (i 5 9)
       :gnome7 (i 6 9)
       :gnome8 (i 7 9)
       :gnome9 (i 8 9)
       }

        :tiles
        [:mountains :hills :grass :field :desert :trees :ocean :road :river]
        :features1 features1
        :features2 features2

        :units
        [:small-goblin :medium-goblin :large-goblin :orc :gnome1 :gnome2 :gnome3 :gnome4 :gnome5 :gnome6 :gnome7 :gnome8 :gnome9 :frozen-duke]
        
        :unit-map
        {:small-goblin :goblin :medium-goblin :goblin :large-goblin :goblin :orc :goblin
         :gnome1 :gnome :gnome2 :gnome :gnome3 :gnome :gnome4 :gnome :gnome5 :gnome :gnome6 :gnome :gnome7 :gnome :gnome8 :gnome :gnome9 :gnome
         :frozen-duke :duke}
 
        :type
        {:mountains :ground :hills :ground :grass :ground :field :ground :desert :ground :trees :ground :ocean :ground
         ;; :walls1 :feature :tower1 :feature :house1 :feature :church :feature :tower2 :feature :city1 :feature :house2 :feature :house3 :feature
         ;; :garden :feature :walls :feature :pond :feature :shrine :feature :fire :feature :circle :feature
         :road :road
         :river :river
         :coast :coast
         :small-goblin :unit :medium-goblin :unit :large-goblin :unit :orc :unit
         :gnome1 :unit :gnome2 :unit :gnome3 :unit :gnome4 :unit :gnome5 :unit :gnome6 :unit :gnome7 :unit
         :gnome8 :unit :gnome9 :unit
         :frozen-duke :unit
        }

        :icons {:down1 [0 4] :down2 [2 4] :up1 [1 4] :up2 [3 4] :sword [4 0]
                :white1 [0 1] :white2 [0 2] :blue1 [1 1] :blue2 [1 2] :yellow1 [ 2 1] :yellow2 [2 2] :red1 [3 1] :red2 [3 2]
                :dot1 [0 3] :dot2 [1 3]}
        })

(each [in feature (ipairs features1)]
  (tset index.type feature :feature)
  (tset index.map feature (i (- in 1) 2)))

(each [in feature (ipairs features2)]
  (tset index.type feature :feature)
  (tset index.map feature (i (- in 1) 3)))

(tset index :rmap (collect [k v (pairs index.map)] (values v k)))

(tset index :unit-rmap (collect [k v (pairs index.unit-map)] (values v k)))

index
