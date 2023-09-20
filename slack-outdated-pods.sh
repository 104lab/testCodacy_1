

echo "run pod outdated to slack"


#比較字串裡面的版號
function compare_string(){
    #ex:FirebaseRemoteConfig 3.6.0 -> 4.9.0 (latest version 5.9.0)
    
    ver1=$(echo "$1" | sed 's/^\(.*\) \([0-9]\).\(.*\) -> \(.*\) \([0-9]\).\(.*\))/\2/')
    ver2=$(echo "$1" | sed 's/^\(.*\) \([0-9]\).\(.*\) -> \(.*\) \([0-9]\).\(.*\))/\5/')
    
    #echo "$ver1 $ver2"
    
    retval=""
    if [ $ver1 = $ver2 ]
    then
        retval=$1
    else
        retval=":warning:$1"
    fi
    
    echo "$retval"
}

function joinArray() {
  (($#)) || return 1 # At least delimiter required
  local -- delim="$1" str IFS=
  shift
  str="${*/#/$delim}" # Expand arguments with prefixed delimiter (Empty IFS)
  echo "${str:${#delim}}" # Echo without first delimiter
}


LIST=$(pod outdated | sed -ne '/^The following pod updates are available:$/{s///; :a' -e 'n;p;ba' -e '}')
#echo "${OUTPUT}" > outdated.txt
#LIST=$(< outdated.txt)
#echo "pod outdated ＝ \n$LIST"
#LIST=$(< outdated.txt)
#LIST="FirebaseRemoteConfig 3.6.0 -> 4.9.0 (latest version 5.9.0)"
SAVEIFS=$IFS   # Save current IFS
IFS=$'\n'      # Change IFS to new line
array=($LIST) # split to array $names
IFS=$SAVEIFS   # Restore IFS

for (( i=0; i<${#array[@]}; i++ ))
do
    array[i]=$( compare_string "${array[i]}" )
done


varLast=$( joinArray $'\n' "${array[@]}" )


echo "compare $varLast"


curl -X POST --data-urlencode "payload={\"channel\": \"#cac_travis_ci\", \"username\": \"iOS Library\", \"text\": \"${OUTPUT_SCHEME_NAME}_pod版本比較:\n\n $varLast\", \"icon_emoji\": \":cac_ios:\"}" https://hooks.slack.com/services/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


