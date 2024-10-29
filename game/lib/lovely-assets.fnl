;; Author: AlexJGriffith
;; Date: 2023-09-20
;; Licence: MIT
;; Description: A cross platform Love2D library for hotloading assets

(local assets {})
(local update-time {})
(local update-queue {})
(local delay 0.5)
(local love (require :love))

(local file-extensions-loaders
       {:lua (fn [file-name] (love.filesystem.load file-name))
        :png (fn [file-name] (love.graphics.newImage file-name))
        :ogg (fn [file-name] (love.audio.newSource file-name))
        :txt (fn [file-name] (love.filesytem.read file-name))
        :json (fn [file-name] (love.filesytem.read file-name))
        :otf (fn [file-name] (fn [font-size]
                               (love.graphics.newFont file-name font-size)))
        :ttf (fn [file-name] (fn [font-size]
                               (love.graphics.newFont file-name font-size)))
        :default (fn [file-name] (love.filesystem.read file-name))})

(fn _get-time [file]
  (-> (love.filesystem.getInfo file)
      (. :modtime)))

(fn add [filename loader? process?]
  "Add a file to the asset library. This file will be checked for
changes every time update is called."
  (fn parse-file-name [file-name]
    (local (directory basename extension)
           (string.match file-name "(.-)([^\\/]-%.?([^%.\\/]*))$"))
    {: directory
     : basename
     : extension})
  
  (let [{: extension : basename : directory} (-> filename (parse-file-name))
        directoryp (-> directory
                       (string.gsub "^/" "")
                       (string.gsub "/$" "")
                       (string.gsub "[/]" "."))
        loader (or loader?
                   (?. file-extensions-loaders extension)
                   (. file-extensions-loaders :default))
        asset (loader filename)
        time (_get-time filename)]
    (when process?
      (process? asset))
    (table.insert update-time {:key [directoryp basename] : filename : time
                               : loader})
    (when (not (. assets directoryp))
      (tset assets directoryp {}))
    (tset assets directoryp basename asset)
    asset))

;; we need to make sure the file is not being saved by asprite.
(fn _add-to-update-queue [directory base loader filename]
  (tset update-queue (.. directory "." base)
        [delay directory base loader filename]))

(fn _update-queue [dt]
  (each [i [delay directory base loader filename] (pairs update-queue)]
    (let [next-delay (- delay dt)]
      (tset update-queue i 1 next-delay)
      (when (< delay 0)
        (tset assets directory base (loader filename))
        (tset update-queue (.. directory "." base) nil)))))

(fn _update-time []
  (each [i {:key [directory base] : filename : time : loader}
         (ipairs update-time)]
    (let [new-time (_get-time filename)]
      (when (~= new-time time)
        (tset update-time i :time new-time)
        (_add-to-update-queue directory base loader filename))))  )

(fn update [dt]
  "Check and see if any of the assets have been changed. If they have
reload them."
  (_update-queue dt)
  (_update-time))

{: assets
 : update
 : add
 : file-extensions-loaders
 : delay
 : _update-time
 : _update-queue}
