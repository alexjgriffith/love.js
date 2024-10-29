;; team.fnl

(local team {})

(import-macros {: getgmeta : setgmeta} :macro)

(fn team.get-units [team]
  ;; not sure if this is the best idea
  (local units (team.hexgrid:get-team-units team.team))
  ;; (pp (icollect [_ u (ipairs units)] u.id))
  ;; (pp (debug.info 1))
  ;; (pp (debug.getinfo 3))
  (assert (= :table (type units)) "Units drawn from hexgrid are not a table")
  units
  )

(fn team.collect-cash [team]
  (local units (team:get-units))
  (var ret 0)
  (each [_ unit (ipairs units)]
    (local tile-type  (team.hexgrid:get-tile unit.i unit.j))
    (local feature-type (team.hexgrid:get-feature-type unit.i unit.j))
    (set ret (+ ret (unit:collect-cash tile-type feature-type))))
  ret)

(fn team.update-units [team]
  (local units (team:get-units))
  (each [_ unit (ipairs units)] (unit:next-turn team.hexgrid)))

(fn team.end-turn [team]
  (set team.cash (+ team.cash (math.max 0 (team:collect-cash))))
  (team:update-units))

(fn team.can-move [team]
  (accumulate [ret false _ u (ipairs (team:get-units))]
    (if (u:can-move team.hexgrid) true ret)))

(fn team.next-unit [team dont-iterate?]
  (local units (team:get-units))
  (fn member [arr id]
    (when arr (accumulate [ret false _ a (ipairs arr)] (if (= id a) a ret))))
  (fn distance [u1 u2] (math.sqrt (+ (^ (- u1.x u2.x) 2) (^ (- u1.y u2.y) 2))))
  (local hg team.hexgrid)
  (fn closest [u1 arr]
    (when u1
      (var max-distance 10e8)
      (local ret (accumulate [ret nil _i u2 (ipairs arr)]
                   (let [new-distance (distance u1 u2)]
                     (if (and (< new-distance max-distance) (u2:can-move hg) (~= u2 u1))
                         (do (set max-distance new-distance) u2)
                         ret))))
      ret))
  
  (fn first-valid [arr]
    (when arr (accumulate [ret nil _ u (ipairs arr)] (do (if (u:can-move hg) u ret)))))
  
  (local last-unit (or (member units team.last-unit) (first-valid units)))
  (if last-unit
    (let [next-unit (closest last-unit units)]
      (tset team :last-unit (if dont-iterate? last-unit next-unit))
      (values (~= nil next-unit)))
    (values false)))

(fn team.start-turn [team]
  (each [_ unit (ipairs (team:get-units))]
    ;; (when team.player (set unit._team_canmove true))
    (unit:generate-path team.hexgrid))
  (when team.player (team.next-unit team :dont-iterate))
  team.player)

(fn team.expend-cash [team cash]
  (set team.cash (- team.cash cash)) )

(fn team.no-units [team]
  (= 0 (# (team:get-units))))

(fn team.update-visibility [team]
  (let [units (team:get-units)]
    (each [_ u (ipairs units)]
      (u:set-view team.hexgrid))))

(setgmeta team team)
(fn team.init [hexgrid team cash player?]
  (setmetatable
   {:last-unit nil
    : team
    : cash
    : hexgrid
    :player (if player? true false)}
   (getgmeta team)))

team
