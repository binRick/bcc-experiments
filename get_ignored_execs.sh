( \
 cat .ignored_execs.txt 

 ) \
    |tr '\n' '|'|sed 's/|$//g'
