# Set category and convert underscores and whitespaces to plusses
category=$1
category=$(echo $category | tr ' _' '+')

# Set base query
basequery="https://commons.wikimedia.org/w/api.php?action=query&format=json\
&prop=imageinfo&generator=categorymembers&iiprop=url\
&gcmtitle=Category%3A+$category&gcmtype=file&gcmlimit=500"

# Set initial query
apiquery=$basequery

# Query API and collect the URLs
while [ -z $done ]; do
  response=$($(echo "curl --silent $apiquery"))

  # Extract image URLs
  urls+=( $(echo $response | jq ".query.pages[].imageinfo[].url") )

  # Update the query to fetch next batch of results
  if echo $response | grep -q "\"gcmcontinue\":"; then
    gcmcont=$(echo $response | jq ".continue.gcmcontinue")
    apiquery=$(echo $basequery\&gcmcontinue=$gcmcont)
  else
    done=1
  fi
done

# Grab all the files
for url in "${urls[@]}"; do
  # First sed command removes the quotation marks, second escapes quotation
  # marks that are part of the filename
  wget --restrict-file-names=nocontrol -c\
  "$(echo $url | sed -e 's/^"//' -e 's/"$//' | sed 's/"/\\"/')"
done
