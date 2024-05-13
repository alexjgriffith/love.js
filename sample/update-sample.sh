size=$(du -b game.love | awk '{print $1}')
cat index.html.in | sed "s/{{{size}}}/${size}/g" > index.html
