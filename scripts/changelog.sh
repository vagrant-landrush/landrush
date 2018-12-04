#!/bin/bash

programname=$0
function usage()
{
    echo "usage: $programname -m milestone"
    echo "  -m  milestone id"
    exit 1
}



# Given a milestone id, generates a sorted list of issues for this milestone.
# Can be used to generate content for CHANGELOG.md
function milestone_issues()
{
  # get the raw data
  milestone_data="`curl -s https://api.github.com/repos/vagrant-landrush/landrush/issues?per_page=100\&milestone=$milestone\&state=closed`"

  issue_list=`echo $milestone_data | jq '.[] | "- Issue [#" + (.number|tostring) + "](" + .url + ") - " + .title'`

  # sort first on issue type, then issue id
  issue_list=`echo "$issue_list" | sort  -k4,4 -k2n`

  # Remove enclosing quotes on each line
  issue_list=`echo "$issue_list" | tr -d \"`

  # Replace \ which is left over from above command with "(double quote) and suppress warning
  issue_list=`echo "$issue_list" | tr '\' '"' 2> /dev/null`

  # Adjust the issue links
  issue_list=`echo "$issue_list" | sed -e s/api.github.com.repos/github.com/g`

  echo "$issue_list"
}

while getopts ":r:m:" opt; do
  case $opt in
    r)
      repository=$OPTARG
      ;;
    m)
      milestone=$OPTARG
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

if [ -z "${milestone}" ]; then
    usage
    exit 1
fi

milestone_issues