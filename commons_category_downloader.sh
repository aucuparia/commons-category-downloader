#!/usr/bin/env bash

# Set category and convert underscores and whitespaces to plusses
category="$1"
category=$(echo "$category" | tr ' _' '+')

# Set base query
basequery="https://commons.wikimedia.org/w/api.php?action=query&format=json\
&prop=imageinfo&generator=categorymembers&iiprop=url\
&gcmtitle=Category%3A+$category&gcmtype=file&gcmlimit=500"

# Set initial query
apiquery="$basequery"

# Make temporary file
mktemp=$(mktemp)
trap 'rm -f "${mktemp:?}"' EXIT

# Query API and collect the URLs
while :; do
  response=$(curl --silent "$apiquery")

  # Extract image URLs
  echo "$response" | jq -rc ".query.pages[].imageinfo[].url" >> "$mktemp"

  # Update the query to fetch next batch of results
  if echo "$response" | grep -q "\"gcmcontinue\":"; then
    gcmcont=$(echo "$response" | jq -rc ".continue.gcmcontinue")
    apiquery="$basequery&gcmcontinue=$gcmcont"
  else
    break
  fi
done

# Grab all the files
wget --restrict-file-names=nocontrol -c -i "$mktemp"
