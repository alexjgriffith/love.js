(local lume (require :lib.lume))
(local love (require :love))

(local gnome-first-names (lume.split (love.filesystem.read :/assets/data/gnome-first-names.txt) "\n"))
(local gnome-titles (lume.split (love.filesystem.read :/assets/data/gnome-titles.txt) "\n"))


(local goblin-names (lume.split (love.filesystem.read :/assets/data/goblin-names.txt) "\n"))

(fn generate [what]
  (match what
    :duke "The Frozen Duke"
    :goblin (. goblin-names (math.random (# goblin-names)))
    :gnome (.. (. gnome-first-names (math.random (# gnome-first-names))) " "
               (. gnome-titles (math.random (# gnome-titles))))))

{: generate}


