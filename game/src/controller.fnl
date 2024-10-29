;; controller.fnl

(import-macros {: setgmeta : getgmeta} :macro)
(local love (require :love))
(local signal (require :lib.signal))

(local _combat (require :src.combat)) ;; recieves signals
(local _discussion (require :src.discussion)) ;; recieves signals

(local hover-controler {})
(local unit-controller (if _G._unit-controller _G._unit-controller (do (set _G._unit-controller {}) _G._unit-controller)))

(local {: over-ui-function} (require :src.ui))

(fn select-unit [command unit?]
  (local hg command.hexgrid)
  (do (signal.emit :controller-unit-click command hg hg.hover)
      (local state (require :src.state))
      (when (= (. (or unit? hg.hover.over) :team) state.player-team)
        (unit-controller.enter command unit?))))

(fn hover-controler.end [command]
  (local hg command.hexgrid)
  (when (not (over-ui-function))
    (match hg.hover.over.type
      :tile (signal.emit :controller-tile-click command hg hg.hover)
      :unit (select-unit command)
      :feature (signal.emit :controller-feature-click command hg hg.hover)
      )))

(fn unit-controller.enter [command unit?]
  (local hg command.hexgrid)
  (print (string.format "Selecting unit %s." (or (?. unit? :id) (?. hg.hover :over :id))))
  ;; (pp hg.hover)
  (local {:over ounit} hg.hover)
  (local unit (or unit? ounit))
  ;; (when unit
  ;;   (local {: teams} (require :src.state))
  ;;   (local team (. teams unit.team))
  ;;   (pp [:team team])
  ;;   (set team.last-unit unit)
  ;;   )
  
  ;;(tset unit :path (hg.generate-path hg hi hj unit.energy))
  (unit:generate-path hg)
  (tset command :active-unit unit)
  (tset command :state :unit)
  (hg.set-outer-ring hg unit.path)
  (unit-controller.update command))

(fn unit-controller.exit [command]
  (print (string.format "Forcing exit while unit %s is selected." (?. command :active-unit :id)))
  (local hg command.hexgrid)
  (command.active-unit:generate-path hg)
  ;; (local {:over unit : hi : hj} hg.hover)
  ;;(tset commannd :state :hover)
  (local {: cursors} (require :src.resources))
  (love.mouse.setCursor cursors.normal)
  (tset command :active-unit nil)
  (hg.clear-outer-ring hg)
  (hg.clear-pathing hg)
  (tset command :state :hover))

(fn unit-controller.end [command]
  (local hg command.hexgrid)
  (local {:over obj : hi : hj} hg.hover)
  (when (not (over-ui-function))
    (tset command :state :hover)
    (match command.unit-status
      :move (do 
              (local cost (. command.active-unit.path (. command.active-unit.pathing 1) 2))
              (command.active-unit:expend-energy cost)
              (hg:unit-moveto command.active-unit hi hj)
              (command.active-unit:visit hg command.active-unit.pathing)
              (signal.emit :controller-feature-click command hg hg.hover)
              (signal.emit :controller-moveto hg command.active-unit.pathing)
              (unit-controller.enter command command.active-unit)
              ;; (unit-controller.exit command)
              )
      :attack (do
                ;;(local current (. command.active-unit.pathing (# command.active-unit.pathing)))
                ;;(local (ci cj) (hg.grid:_index->xy current))
                (local target (. command.active-unit.pathing 1))
                (local (ti tj) (hg.grid:_index->xy target))
                (local index (. command.active-unit.pathing 2))
                (local (i j) (hg.grid:_index->xy index))
                (local cost (. command.active-unit.path (. command.active-unit.pathing 2) 2))
                ;;(pp [ci cj ti tj i j command.active-unit.pathing])
                (command.active-unit:expend-energy cost)
                (hg:unit-moveto command.active-unit i j)
                (signal.emit "controller-attack" hg i j ti tj)
                ;; (unit-controller.exit command)
                (local {: cursors} (require :src.resources))
                (love.mouse.setCursor cursors.normal)
                (unit-controller.enter command command.active-unit)
                )
      :hover (do (unit-controller.exit command) (hover-controler.end command))
      :x (do
           (signal.emit "controller-x" hg command.active-unit.i command.active-unit.j hi hj)
           (unit-controller.exit command)
           
           (hover-controler.end command))
      :inactive :do-nothing
      _ (do (unit-controller.exit command) (hover-controler.end command)))
    )
  )

(fn unit-controller.update [command]
  (local unit command.active-unit)
  (local hexgrid  command.hexgrid)
  (local {: cursors} (require :src.resources))

  ;; (pp hexgrid.hover)
  (when command.active-unit
    (tset unit :pathing (hexgrid:path-to unit.path hexgrid.hover.hi hexgrid.hover.hj)))
  (local over-team-unit (and (= :unit hexgrid.hover.over.type)
                             (= hexgrid.hover.over.team command.active-unit.team)))
  (local over-enemy-unit (or (and (= :unit hexgrid.hover.over.type)
                                  (= hexgrid.hover.over.team 4))
                             (and (= :tile hexgrid.hover.over.type)
                                  (?. hexgrid.hover.over.tile.units 1 :team)
                                  (= (?. hexgrid.hover.over.tile.units 1 :team) 4))))
  
  (local over-q-unit (or (and (= :unit hexgrid.hover.over.type)
                              (or (= hexgrid.hover.over.team 2)
                                  (= hexgrid.hover.over.team 3)))
                             (and (= :tile hexgrid.hover.over.type)
                                  (?. hexgrid.hover.over.tile.units 1 :team)
                                  (or (= (?. hexgrid.hover.over.tile.units 1 :team) 2)
                                      (= (?. hexgrid.hover.over.tile.units 1 :team) 3)))))
  
  (local not-over-team-tile (or (and (= hexgrid.hover.over.type :tile)
                                     (~= (?. hexgrid.hover.over.tile.units 1 :team) command.active-unit.team))))
  
  (local over-navigable-terrain (and
                                 command.active-unit command.active-unit.pathing
                                 (> (# command.active-unit.pathing) 0)))
  (local over-feature (= hexgrid.hover.over.type :feature))
  ;; (pp1 hexgrid.hover.over)
  (if (and (or over-enemy-unit not-over-team-tile) over-navigable-terrain)
      (do (when unit.pathing (hexgrid:set-path unit.pathing)))
      (hexgrid:clear-pathing))
  (local attack-path-blocked (let [pathing (?. command :active-unit :pathing)
                                   second (when pathing (. pathing 2))
                                   unit (?. hexgrid.grid.data second :units 1)]
                               (and unit (not (and pathing (< (# pathing) 3)))) ))
  ;; (pp command.state)
  (if (and over-enemy-unit over-navigable-terrain (not attack-path-blocked))
      (do (when (not (= :attack command.unit-status))
            (love.mouse.setCursor cursors.sword))
          (set command.unit-status :attack))

      (and over-q-unit over-navigable-terrain (not attack-path-blocked))
      (do (when (not (= :attack command.unit-status))
            (love.mouse.setCursor cursors.q))
          (set command.unit-status :attack))      
      
      (and over-navigable-terrain not-over-team-tile (not over-enemy-unit))
      (do (when (not (= command.unit-status :move))
            (love.mouse.setCursor cursors.move))
          (set command.unit-status :move))
      
      (or
       over-feature
       over-team-unit)
      (do (when (not (= command.unit-status :hover))
         (love.mouse.setCursor cursors.normal))
          (set command.unit-status :hover))

      (over-ui-function)
      (do (love.mouse.setCursor cursors.normal)
          (set command.unit-status :inactive))
      
      (do (love.mouse.setCursor cursors.x)
          (set command.unit-status :x))
   ))

;; import keywords
(local {:keywords {: start : close : end : update :get _get : is-active?}} (require :src.editor))

(local controller-mt
       {
        start
        (fn [command]
          (when (?. command.state-map command.state :end)
            ((. command.state-map command.state :end) command)))
        
        close
        (fn  [command]
          (tset command :active false)
          (when (?. command.state-map command.state :exit)
            ((. command.state-map command.state :exit) command))
          (tset command :state :hover))

        end
        (fn [command _editor _x _y]
          :nothing)
        
        update
        (fn [command _editor _x _y]
          (when (?. command.state-map command.state :update)
            ((. command.state-map command.state :update) command)))
        
        is-active?
        (fn [command _editor] command.active)
        })


(setgmeta controller-mt controller-mt)

(local controller {})
(fn controller.init [hg]  
  (setmetatable {:hexgrid hg :states [:hover :unit :feature :tile]
                 :state :hover :active false
                 :state-map {:hover hover-controler :unit unit-controller}
                 :active-unit nil}
                (getgmeta controller-mt)))

(fn controller.select-unit [command unit]
  (set command.hexgrid.hover {:over unit :hi unit.i :hj unit.j})
  ;; (: command close)
  (select-unit command)
  (: command update)
  ;;(: command end)
  )

controller
