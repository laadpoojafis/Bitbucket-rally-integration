#!/bin/bash
#Pullrequest Files
mv pullrequests.properties pullrequests_old.properties
echo projectkey.repoSlug.title.description > pullrequests.properties
#call project get api
curl -H "Authorization: Bearer OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte" http://172.16.8.35:7990/rest/api/1.0/projects?limit=1 >projects.json
#call end project get api
totalProjects=`cat projects.json | /p/jq  '.size'`
echo ${totalProjects}
for ((tp = 0 ; tp < ${totalProjects} ; tp++))
do
	projectkey="RC"
  #    projectkey=`cat projects.json | /p/jq  '.values['"$tp"'].key' | sed 's/"//g'` 
        echo "project key" ${projectkey}	
	#call repos get api for each project key
        curl -H "Authorization: Bearer OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos >repos_${projectkey}.json
  	totalRepos=`cat repos_${projectkey}.json | /p/jq  '.size'`
        echo "repos are" ${totalRepos}   
        for ((tr = 0 ; tr < ${totalRepos} ; tr++))
	do
		repoSlug=`cat repos_${projectkey}.json | /p/jq  '.values['"$tr"'].slug' | sed 's/"//g'`
		echo "repo slug" ${repoSlug}
		#Function for Branch Name
		#api call to get all PR for repo
	        curl -H "Authorization: Bearer OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos/${repoSlug}/pull-requests >repos_${projectkey}_${repoSlug}.json
	        PR=`cat repos_${projectkey}_${repoSlug}.json | /p/jq  '.size'`
		for ((tb = 0 ; tb < ${PR} ; tb++))
		do
		Title=`cat repos_${projectkey}_${repoSlug}.json | /p/jq '.values['"${tb}"'].title' | sed 's/"//g'`
		Description=`cat repos_${projectkey}_${repoSlug}.json | /p/jq '.values['"${tb}"'].description' | sed 's/"//g'`
	           echo ${projectkey}.${repoSlug}.${Title}.${Description}
		   echo ${projectkey}.${repoSlug}.${Title}.${Description} >> pullrequests.properties
 	         done
	done			
done
msg_regex='[A-Z]+[A-Z]+[0-9]+' 
sort -o pullrequests_sort.properties pullrequests.properties
sort -o pullrequests_old_sort.properties pullrequests_old.properties
comm pullrequests_sort.properties pullrequests_old_sort.properties -3 | grep -E $msg_regex > newpullrequests.properties

##POST API Call to Rally
		while read tn; do
		  echo "line from newPR file" $tn
		ArtifactsInAlineAre=`echo $tn | grep  -oE $msg_regex | uniq`
		echo "ArtifactsInAlineAre="${ArtifactsInAlineAre}
		for i in $ArtifactsInAlineAre
		do
		  echo "1 by 1 artifacts are"${i}
                cmd="https://rally1.rallydev.com/slm/webservice/v2.0/defect?query=(FormattedID%20%3D%20${i})"
   		echo ${cmd}
		 curl --header "zsessionid:_qjZabCw6TUajYHNKzj5pZ587kdzh70RSrjTs9aNkH7M" -H "Content-Type: application/json" ${cmd} >get.json
		 echo URL ${cmd} 
   		ObjectId=`cat get.json | cut -d"/" -f8 | cut -d"\"" -f1`
		echo "object Id "${ObjectId} ${artifacts}
Description=`echo $tn | cut -d '.' -f4`
Title=`echo $tn | cut -d '.' -f3`
echo "object,desc,title to be put is" ${ObjectId} ${Description} ${Title}
url="http://172.16.8.35:7990/projects/${projectkey}/repos/${repoSlug}/pull-requests"
echo url ${url}
artifact="/defect/${ObjectId}"
curl --header "zsessionid:_5qkiIFxQaSYES9XL4aMNUFH2EeGMEiemV4EtMH4o" -H "Content-Type: application/json" -d '{"PullRequest":{"Description":"'"${Description}"'","Name":"'"${Title}"'","Artifact":"'"${artifact}"'","ExternalID":"123","ExternalFormattedId":"12345","Url":"'"${url}"'"}}' https://rally1.rallydev.com/slm/webservice/v2.0/pullrequest/create
cat post.json
done
 done <newpullrequests.properties


