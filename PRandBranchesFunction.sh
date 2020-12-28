#!/bin/bash
#BranchNames File
mv branchnames.properties branchnames_old.properties
mv pr.properties pr_old.properties
echo projectkey "|" repoSlug "|" branchName > branchnames.properties
echo projectkey "|" repoSlug "|" Pullrequest > pr.properties 
touch ObjectArtifactMapping.properties
#msg_regex='[A-Z]+[A-Z]+[0-9]+' 
msg_regex="(DE|US|DS|TA)+[[:digit:]]+"
bitbucketKey="OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte" 
rallyKey="_qjZabCw6TUajYHNKzj5pZ587kdzh70RSrjTs9aNkH7M"
#Functions
getProjects()
{
    bitbucketKey=$1
#call project get api
    curl -H "Authorization: Bearer OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte" http://172.16.8.35:7990/rest/api/1.0/projects?limit=1 >projects.json
#call end project get api
    totalProjects=`cat projects.json | /p/Softwares/jq  '.size'`
    for ((tp = 0 ; tp < ${totalProjects} ; tp++))
    do
	
        projectkey="RC"
        #IMP#projectkey=`cat projects.json | /p/Softwares/jq  '.values['"$tp"'].key' | sed 's/"//g'` 
        #call repos get api for each project key
        curl -H "Authorization: Bearer OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos >repos_${projectkey}.json
        totalRepos=`cat repos_${projectkey}.json | /p/Softwares/jq  '.size'`
        #call end repos get api
	
        getRepos ${totalRepos} ${projectkey}

   
    done
}

getRepos()
{
    totalRepos=$1
    projectkey=$2
    for ((tr = 0 ; tr < ${totalRepos} ; tr++))
    do
        repoSlug=`cat repos_${projectkey}.json | /p/Softwares/jq  '.values['"$tr"'].slug' | sed 's/"//g'`
        #api call to get all branches for repo
        curl -H "Authorization: Bearer OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos/${repoSlug}/branches >repos_${projectkey}_${repoSlug}.json
        totalBranches=`cat repos_${projectkey}_${repoSlug}.json | /p/Softwares/jq  '.size'`
        getBranches ${totalBranches} ${projectkey} ${repoSlug}
        
        #api call to get all PRs for repo
        
        curl -H "Authorization: Bearer OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos/${repoSlug}/pull-requests >repos_${projectkey}_${repoSlug}_PR.json
        totalPRs=`cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.size'`
        getPRs ${totalPRs} ${projectkey} ${repoSlug}
    done  
}

getBranches()
{
    totalBranches=$1
    projectkey=$2
    repoSlug=$3
    for ((tb = 0 ; tb < ${totalBranches} ; tb++))
    do
        branchName=`cat repos_${projectkey}_${repoSlug}.json | /p/Softwares/jq  '.values['"$tb"'].displayId' | sed 's/"//g'`
        echo ${projectkey}"|"${repoSlug}"|"${branchName} >> branchnames.properties
    done
}

newBranch()
{
    sort -o branchnames_sort.properties branchnames.properties
    sort -o branchnames_old_sort.properties branchnames_old.properties
    comm branchnames_sort.properties branchnames_old_sort.properties -3 | grep -E $msg_regex > newbranches.properties
}

getPRs()
{
    totalPRs=$1
	projectkey=$2
	repoSlug=$3
    for ((tp = 0 ; tp < ${totalPRs} ; tp++))
    do
        title=`cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.values['"$tp"'].title' | sed 's/"//g'`
	desc=`cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.values['"$tp"'].description' | sed 's/"//g'`
        echo ${projectkey}"|"${repoSlug}"|"${title}"|"${desc} >> pr.properties
    done
}

newPR()
{
	sort -o pr_sort.properties pr.properties
    sort -o pr_old_sort.properties pr_old.properties
    comm pr_sort.properties pr_old_sort.properties -3 | grep -E $msg_regex > newpr.properties
}


listArtifact()
{
    #rallyKey=${1}
    cat newbranches.properties | grep -oE $msg_regex > artifactIds.properties
	cat newpr.properties | grep -oE $msg_regex >> artifactIds.properties
    for artifactId in `cat artifactIds.properties | uniq`
    do
        ##GET API Call to Rally to validate artifact
        ObjectTypePrefix=${artifactId:0:2}
        ObjectType=`cat config_master.json | /p/Softwares/jq  -r '.rally.artifactPrefix."'"${ObjectTypePrefix}"'"'`
        cmd="https://rally1.rallydev.com/slm/webservice/v2.0/${ObjectType}?query=(FormattedID%20%3D%20${artifactId})"
        curl --header "zsessionid:_qjZabCw6TUajYHNKzj5pZ587kdzh70RSrjTs9aNkH7M" -H "Content-Type: application/json" ${cmd} >get.json
        ObjectId=`cat get.json | cut -d"/" -f8 | cut -d"\"" -f1`
	echo ${ObjectId}
        echo ${artifactId}"|"${ObjectId}"|"${ObjectType} >> ObjectArtifactMapping.properties
    done
}


getCommits()
{
    #bitbucketKey=${1}
    searchDate="2020-12-04"
    for repoDetail in `cat repoDetails.properties`
    do
        projectName=`echo ${repoDetail} | cut -d '|' -f1`
        repoName=`echo ${repoDetail} | cut -d '|' -f2`
        curl -H "Authorization: Bearer ${bitbucketKey}" http://172.16.8.35:7990/rest/api/1.0/projects/${projectName}/repos/${repoName}/commits?since=${searchDate} >commits.json
        #Pushing Details For Commits
    done
}


postCommitsToRally()
{
    echo hi
}

postPRToRally()
{
    ##POST API Call to Rally
    rallyKey=${1}
    while read tp; do
        echo ${tp}
	ArtifactsInAlineAre=`echo ${tp} | grep -oE $msg_regex  | uniq`
	echo "ArtifactsInAlineAre="${ArtifactsInAlineAre}
	for i in ${ArtifactsInAlineAre}
	do
	  echo "1 by 1 artifacts are"${i}
       FormattedId=${i}
        mapping=`grep -s ${FormattedId} ObjectArtifactMapping.properties | uniq`
	 ObjectId=`echo $mapping | cut -d '|' -f2`
        artifactId=`echo ${mapping} | cut -d '|' -f1`
        ObjectType=`echo ${mapping} | cut -d '|' -f3`
        projectName=`echo $tp | cut -d '|' -f1`
	Title=`echo $tp | cut -d '|' -f3`
	Description=`echo $tp | cut -d '|' -f4`
         echo ${projectkey}"|"${repoSlug}"|"${Title}"|"${Description}
         echo ${projectkey}"|"${repoSlug}"|"${Title}"|"${Description} >> pullrequests.properties
	echo "object,desc,title to be put is" ${ObjectId} ${Description} ${Title}
	url="http://172.16.8.35:7990/projects/${projectkey}/repos/${repoSlug}/pull-requests"
	echo url ${url}
	artifact="/${ObjectType}/${ObjectId}"
	curl --header "zsessionid:_5qkiIFxQaSYES9XL4aMNUFH2EeGMEiemV4EtMH4o" -H "Content-Type: application/json" -d '{"PullRequest":{"Description":"'"${Description}"'","Name":"'"${Title}"'","Artifact":"'"${artifact}"'","ExternalID":"123","ExternalFormattedId":"12345","Url":"'"${url}"'"}}' https://rally1.rallydev.com/slm/webservice/v2.0/pullrequest/create
	echo "Details of new PR has been updated on Rally" 
	done
    done < newpr.properties
}

postBranchToRally()
{
    ##POST API Call to Rally
    #rallyKey=${1}
  
        while read tn; do
        echo ${tn}
	ArtifactsInAlineAre=`echo ${tn} | grep -oE $msg_regex  | uniq`
	echo "ArtifactsInAlineAre="${ArtifactsInAlineAre}
	for i in ${ArtifactsInAlineAre}
	do
	  echo "1 by 1 artifacts are"${i}
       FormattedId=${i}
        mapping=`grep -s ${ObjectId} ObjectArtifactMapping.properties | uniq`
	echo ${mapping}
        artifactId=`echo ${mapping} | cut -d '|' -f1`
        ObjectType=`echo ${mapping} | cut -d '|' -f3`
        projectName=`echo $tn | cut -d '|' -f1`
        repoName=`echo $tn | cut -d '|' -f2`
        newBranchName=`echo $tn | cut -d '|' -f3`
        url="http://172.16.8.35:7990/projects/${projectName}/repos/${repoName}/browse?at=refs/heads/${newBranchName}"
        echo url ${url}
        artifact="/${ObjectType}/${ObjectId}"
        echo  Artifact $artifact
        curl --header "zsessionid:_qjZabCw6TUajYHNKzj5pZ587kdzh70RSrjTs9aNkH7M" -H "Content-Type: application/json" -d '{"ConversationPost":{"Artifact":"'"${artifact}"'","Text":"New branch has been created in BitBucket and URL for the same is <a class=\"cke-link-popover-active\" href=\"'"${url}"'\">'"${newBranchName}"'</a>\n"}}' https://rally1.rallydev.com/slm/webservice/v2.0/conversationpost/create >post.json
        echo "Details of New branches has been updated on Rally" 
    done
done <  newbranches.properties
   
}

getProjects 
newBranch
newPR
listArtifact
postBranchToRally 
postPRToRally

cat repos_*.json > AllDetails.json
rm -f repos_*.json
rm -f *sort.properties
