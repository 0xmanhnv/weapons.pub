# Domain to base search string dc
dc_string=""
for dc in $(echo $domain | tr "." "\n")
do
    dc_string=$dc_string"dc=$dc,"
done
dc_string=`echo $dc_string | sed 's/,*$//g'`