in=$1
convert -define icon:auto-resize=128,64,48,32,16 -gravity center  $in.png   $in.ico
