(local fennel (require :lib.fennel))
(fn pp [x] (print (fennel.view x)))

(local simulation (require :src.simulation))

;;(local sample (simulation.example [:light-infantry :light-infantry] [:light-infantry :heavy-infantry] 0 :hills nil))

(local unit-types [:light-infantry :archers :heavy-infantry :pike :engineer])

(fn random-units [n]
  (fcollect [_ 1 n] (. unit-types (math.random (- (# unit-types) 0)))))


;; (local sample (simulation.example [:archers :archers :heavy-infantry :heavy-infantry ] [:cavalry :engineer :engineer :pike] 4 :hills nil))



(fn run-simulation [sample]
  (for [_ 1 12]
    (simulation.tick sample)
    (let [overview (simulation.overview sample)]
      ;; (pp sample._debug-log)
      (each [_ {: energy : state : energy-impact : manpower : manpower-impact : moral : moral-impact : army-type}
             (ipairs overview.offence-armies)]
        (print (string.format "%s O: en:%s (%s) mp:%s (%s) mo:%s (%s) state:%s type:%s"
                              (- overview.turn 1) energy energy-impact manpower manpower-impact moral moral-impact state army-type)))
      (each [_ {: energy : state : energy-impact : manpower : manpower-impact : moral : moral-impact : army-type}
             (ipairs overview.defence-armies)]
        (print (string.format "%s D: en:%s (%s) mp:%s (%s) mo:%s (%s) state:%s type:%s"
                              (- overview.turn 1) energy energy-impact manpower manpower-impact moral moral-impact state army-type))))))

(math.randomseed (os.time))
(for [i 1 1000]
  (let [offence (random-units (math.random 4))
        defence (random-units (math.random 4))
        sample (simulation.example offence defence 0 :grass false false nil)]
    
    (print (.. "\n########\nSimulation # " i "\n########"))
    (print (accumulate [ret "" i o (ipairs offence)] (.. o (if (= i 1) "" ", ") ret)))
    (print (accumulate [ret "" i o (ipairs defence)] (.. o (if (= i 1) "" ", ") ret)))
    (run-simulation sample)
    ))


(print (.. "\n########\nSimulation # " "CUSTOM" "\n########"))
(run-simulation (simulation.example [:heavy-infantry] [:cavalry] 0 :grass false false nil))
