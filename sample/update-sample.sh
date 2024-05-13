gamefile=$1
size=$(du -b $gamefile | awk '{print $1}')
ln -s $(pwd)/$gamefile $(pwd)/release/$gamefile
ln -s $(pwd)/$gamefile $(pwd)/compat/$gamefile 
cat index.html.in | sed "s/{{{size}}}/${size}/g" | sed "s/{{{gamefile}}}/${gamefile}/g" > index.html
