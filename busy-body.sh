i=0
while true
do 
i=$((i+1))
echo $i > changed.txt
date >> changed.txt
git add .
git commit -m "change is good"
git push -u origin master
sleep 60
done
