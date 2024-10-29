(local names
       {:frozen-fort "The Frozen Fort"
        :tower2 "The Mage Lookout"
        :church "Frozen Grace"
        :tower1 "The Tower"
        :city1 "Iceville"
        :city2 "Subzero"
        :city3 "Frosthaven"
        :city4 "Colderado"
        :fort1 "The Icy Hold"
        :fort2 "Coldest"
        :fort3 "Big Blue"
        :fort4 "Four Flags"
        :walls1 "Windswept Walls"
        :walls2 "Snowy Retreat"
        :wall3  "Icicle's Refuge"
        :walls4 "Blizard"
        :village1 "The Cozy Village"
        :village2 "The Lonely Fir"
        :village3 "OnIce"
        :village4 "Tundra Calls"
        :inn "Friggin Cold Inn"
        :house1 "Alert"
        :house2 "Eureka"
        :house3 "Tulu"
        :garden1 "The Pond"
        :garden2 "The Tree"
        :garden3 "The Hedge"
        :garden4 "The Bush"
        :pond "Grace's Pond"
        :shrine "A Shrine to Grace"
        :fire "A Welcome Reprieve"
        :circle "The Cursed Circle"})

(local type-description
       {:tower "A windswept tower."
        :village "A quaint village."
        :city "A bustling city."
        :walls "Stout walls."
        :fort "A secure fortress."
        :pond "A placid pond"
        :garden "A sacred garden."
        :shrine "A sacred shrine."
        :circle "Something unholy"
        :frozen-fort "A cursed abomination"
        :inn "Warm fires await."
        :hamlet "A cozy hamlet."})

(local type-action
       {:tower "You can recruit engineers here."
        :village "You can recruit light infantry here."
        :city "A can recruit pikemen here."
        :walls "You can recruit cavalry here."
        :fort "You can recruit heavy infantry here."
        :pond "You can rejuvenate your army here."
        :garden "You can rejuvenate your army here."
        :shrine "You can rest your army here."
        :circle "You can raise unholy money here."
        :frozen-fort "You must defeat the Duke."
        :inn "You can rejuvenate your army here."
        :hamlet "You can recruit archers here."})

(local tile-names {:grass "Grassland"
        :field "Feilds"
        :ocean "Water"
        :trees :Forest
                   :hills :Hills
                   :desert :Desert
        :mountains :Mountains})



{: names : type-description : type-action : tile-names}
