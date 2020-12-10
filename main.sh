#!/bin/bash
#BranchNames File
mv branchnames.properties branchnames_old.properties
echo projectkey.repoSlug.branchName > branchnames.properties
#call project get api
curl -H "Authorization: Bearer OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte" http://172.16.8.35:7990/rest/api/1.0/projects?limit=1 >projects.json
#call end project get api

totalProjects=`cat projects.json | /p/jq '.size'`
echo ${totalProjects}
for ((tp = 0 ; tp < ${totalProjects} ; tp++))
do
	projectkey="RC"
  #    projectkey=`cat projects.json | /p/jq '.values['"$tp"'].key' | sed 's/"//g'` 
         echo "project key" ${projectkey}	
	#call repos get api for each project key
        curl -H "Authorization: Bearer OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos >repos_${projectkey}.json
  	totalRepos=`cat repos_${projectkey}.json | /p/jq '.size'`
        echo "repos are" ${totalRepos}
	#call end repos get api
	for ((tr = 0 ; tr < ${totalRepos} ; tr++))
	do
		repoSlug=`cat repos_${projectkey}.json | /p/jq '.values['"$tr"'].slug' | sed 's/"//g'`
		echo "repo slug" ${repoSlug}
		#Function for Branch Name
		#api call to get all branches for repo
	        curl -H "Authorization: Bearer OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos/${repoSlug}/branches >repos_${projectkey}_${repoSlug}.json

		totalBranches=`cat repos_${projectkey}_${repoSlug}.json | /p/jq '.size'`

		for ((tb = 0 ; tb < ${totalBranches} ; tb++))
		do
			branchName=`cat repos_${projectkey}_${repoSlug}.json | /p/jq '.values['"$tb"'].displayId' | sed 's/"//g'`
    			echo ${projectkey}.${repoSlug}.${branchName}
			echo ${projectkey}.${repoSlug}.${branchName} >> branchnames.properties
                        cat branchnames.properties
		done
		#api call end to get all brances for repo
		#Function for Commits
		#Function for Pull Requests
	
	done	
	
done
msg_regex='[A-Z]+[A-Z]+[0-9]+' 
sort -o branchnames_sort.properties branchnames.properties
sort -o branchnames_old_sort.properties branchnames_old.properties
comm branchnames_sort.properties branchnames_old_sort.properties -3 | grep -E $msg_regex > newbranches.properties
totalBranchesToBePushed=`cat newbranches.properties | wc -l`
cat newbranches.properties | grep -oE $msg_regex > artifactIds
cp newbranches.properties newbranches_updated.properties

 for artifacts in `cat artifactIds | uniq`
 do
  echo 
   ##GET API Call to Rally to validate artifact  
   cmd="https://rally1.rallydev.com/slm/webservice/v2.0/defect?query=(FormattedID%20%3D%20${artifacts})"
   echo ${cmd}
   curl --header "zsessionid:_5qkiIFxQaSYES9XL4aMNUFH2EeGMEiemV4EtMH4o" -H "Content-Type: application/json" ${cmd} >get.json
   echo URL ${cmd} 
   ObjectId=`cat get.json | cut -d"/" -f8 | cut -d"\"" -f1`
   echo ${ObjectId}
   sed -i "/${artifacts}/s/^/${ObjectId}./" newbranches_updated.properties
  
done
##POST API Call to Rally
url="http://172.16.8.35:7990/projects/RC/repos/new-repo/browse?at=refs/heads/${branchName}"
artifact="/defect/${ObjectId}"
curl --header "zsessionid:_5qkiIFxQaSYES9XL4aMNUFH2EeGMEiemV4EtMH4o" -H "Content-Type: application/json" -d '{"ConversationPost":{"Artifact":"'"${artifact}"'","Text":"new branch has been created in BitBucket and URL for the same is '"${url}"'"}}' https://rally1.rallydev.com/slm/webservice/v2.0/conversationpost/create >post.json
echo "Printing POST Json" 
		 cat post.json
#new branch has been created in BitBucket and URL for the same is 


