#!/bin/bash
#BranchNames File
mv branchnames.properties branchnames_old.properties
mv pr.properties pr_old.properties
echo projectkey "|" repoSlug "|" branchName > branchnames.properties
echo projectkey "|" repoSlug "|" Pullrequest > pr.properties 
touch ObjectArtifactMapping.properties
echo -n > projectkeys.properties
msg_regex="(DE|US|DS|TA)+[[:digit:]]+"
bitbucketKey="OTgzOTI5NzkzMDQwOrJwlCvfwyDJ8QDWy1A5ILUoplte"
rallyKey="_qjZabCw6TUajYHNKzj5pZ587kdzh70RSrjTs9aNkH7M"
#Functions
getProjects()
{
#call project get api
    curl -H "Authorization: Bearer ${bitbucketKey}" http://172.16.8.35:7990/rest/api/1.0/projects?limit=5 >projects.json
#update start and last page 
   cat projects.json | /p/Softwares/jq  '.values[].key' >> projectkeys.properties
   isLastPage=`cat projects.json | /p/Softwares/jq  '.isLastPage'`
   start=`cat projects.json | /p/Softwares/jq  '.nextPageStart'`
#execute only when project count will < 100
while [ "${isLastPage}" != "false" ]
do
    #call end project get api
   curl -H "Authorization: Bearer ${bitbucketKey}" http://172.16.8.35:7990/rest/api/1.0/projects?start=${start}&limit=100 >projects.json
   cat projects.json | /p/Softwares/jq  '.values[].key' >> projectkeys.properties
   isLastPage=`cat projects.json | /p/Softwares/jq  '.isLastPage'`
   start=`cat projects.json | /p/Softwares/jq  '.nextPageStart'`
done
    for project in `cat projectkeys.properties | sed 's/"//g'`
    do 
         projectkey="RC" 
	#projectkey=${project}
       echo -n >  repokeys_${projectkey}.properties
        echo "project key=" ${projectkey}
        #call repos get api for each project key upto limit=100
        curl -H "Authorization: Bearer ${bitbucketKey}" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos >repos_${projectkey}.json
	cat repos_${projectkey}.json | /p/Softwares/jq  '.values[].slug' >> repokeys_${projectkey}.properties
	isLastPage=`cat repos_${projectkey}.json | /p/Softwares/jq  '.isLastPage'`
        start=`cat repos_${projectkey}.json | /p/Softwares/jq  '.nextPageStart'`
#if repos will >100
while [ "${isLastPage}" == "false" ]
do

          curl -H "Authorization: Bearer ${bitbucketKey}" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos?start=${start}&limit=100 >repos_${projectkey}.json
         cat repos_${projectkey}.json | /p/Softwares/jq  '.values[].slug' >> repokeys_${projectkey}.properties
	isLastPage=`cat repos_${projectkey}.json | /p/Softwares/jq  '.isLastPage'`
   	  start=`cat repos_${projectkey}.json | /p/Softwares/jq  '.nextPageStart'`
done
	 #call end repos get api
echo "calling get repos"
        getRepos ${projectkey}
       
    done
}

getRepos()
{
 echo "in get repos"
    projectkey=$1
    for reposlug in `cat  repokeys_${projectkey}.properties | sed 's/"//g'`
    do
	echo "repo name=" ${reposlug}
	echo -n > branchkeys_${projectkey}_${reposlug}.properties
	echo -n > PRkeys_${projectkey}_${reposlug}.properties
        repoSlug=${reposlug}
        #api call to get all branches for repo
        curl -H "Authorization: Bearer ${bitbucketKey}" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos/${repoSlug}/branches?limit=2 >repos_${projectkey}_${repoSlug}.json
        cat repos_${projectkey}_${repoSlug}.json | /p/Softwares/jq  '.values[].displayId' >> branchkeys_${projectkey}_${reposlug}.properties
  	 isLastPage=`cat repos_${projectkey}_${repoSlug}.json | /p/Softwares/jq  '.isLastPage'`
   	start=`cat repos_${projectkey}_${repoSlug}.json | /p/Softwares/jq  '.nextPageStart'`
echo "before while"
while [ "${isLastPage}" == "false" ]
do
	curl -H "Authorization: Bearer ${bitbucketKey}" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos/${repoSlug}/branches?start=${start}&limit=100 >repos_${projectkey}_${repoSlug}.json
        cat repos_${projectkey}_${repoSlug}.json | /p/Softwares/jq  '.values[].displayId' >> branchkeys_${projectkey}_${reposlug}.properties
  	 isLastPage=`cat repos_${projectkey}_${repoSlug}.json | /p/Softwares/jq  '.isLastPage'`
   	start=`cat repos_${projectkey}_${repoSlug}.json | /p/Softwares/jq  '.nextPageStart'`
done
     
  #api call to get all PRs for repo
        
        curl -H "Authorization: Bearer ${bitbucketKey}" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos/${repoSlug}/pull-requests?state=ALL >repos_${projectkey}_${repoSlug}_PR.json
        cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.values[].displayId' >> PRkeys_${projectkey}_${reposlug}.properties
  	cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.values[].description' >> PRkeysDesc_${projectkey}_${reposlug}.properties
  	  isLastPage=`cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.isLastPage'`
   	start=`cat repos_${projectkey}_${repoSlug}.json | /p/Softwares/jq  '.nextPageStart'`
while [ "${isLastPage}" == "false" ]
do
        curl -H "Authorization: Bearer ${bitbucketKey}" http://172.16.8.35:7990/rest/api/1.0/projects/${projectkey}/repos/${repoSlug}/pull-requests?state=ALL&limit=100&start=${start} >repos_${projectkey}_${repoSlug}_PR.json
        cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.values[].title'"|"cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.values[].description' >> PRkeys_${projectkey}_${reposlug}.properties
	cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.values[].description' >> PRkeysDesc_${projectkey}_${reposlug}.properties
  	 isLastPage=`cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.isLastPage'`
   	start=`cat repos_${projectkey}_${repoSlug}.json | /p/Softwares/jq  '.nextPageStart'`
    done
    getPRs  ${projectkey} ${repoSlug}
    getBranches ${projectkey} ${repoSlug}
done 

}
getBranches()
{
    projectkey=$1
    repoSlug=$2
     for branchname in `cat repos_${projectkey}_branch.properties | sed 's/"//g'`
    do
        echo "in get branches branch name="${branchname}
        branchName=${branchname}
        echo ${projectkey}"|"${repoSlug}"|"${branchName} >> branchnames.properties
    done
}

getPRs()
{
echo "get pr fun"
	projectkey=$1
	repoSlug=$2
    for prname in `cat repos_${projectkey}_PR.properties | sed 's/"//g'`
    do
        echo "in get PR PR name="${prname}
        title=${prname}
       #title=`cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.values['"$tp"'].title' | sed 's/"//g'`
	desc=`cat repos_${projectkey}_${repoSlug}_PR.json | /p/Softwares/jq  '.values['"$tp"'].description' | sed 's/"//g'`
        echo ${projectkey}"|"${repoSlug}"|"${title}"|"${desc} >> pr.properties
    done
}
newBranch()
{
    echo "new branch fun"
	sort -o branchnames_sort.properties branchnames.properties
    sort -o branchnames_old_sort.properties branchnames_old.properties
    comm branchnames_sort.properties branchnames_old_sort.properties -3 | grep -E $msg_regex > newbranches.properties
}

newPR()
{
	sort -o pr_sort.properties pr.properties
    sort -o pr_old_sort.properties pr_old.properties
    comm pr_sort.properties pr_old_sort.properties -3 | grep -E $msg_regex > newpr.properties
}

listArtifact()
{
 
    cat newbranches.properties | grep -oE $msg_regex > artifactIds.properties
	cat newpr.properties | grep -oE $msg_regex >> artifactIds.properties
    for artifactId in `cat artifactIds.properties | uniq`
    do
        ##GET API Call to Rally to validate artifact
        ObjectTypePrefix=${artifactId:0:2}
        ObjectType=`cat config_master.json | /p/Softwares/jq  -r '.rally.artifactPrefix."'"${ObjectTypePrefix}"'"'`
        cmd="https://rally1.rallydev.com/slm/webservice/v2.0/${ObjectType}?query=(FormattedID%20%3D%20${artifactId})"
        curl --header "zsessionid:${rallyKey}" -H "Content-Type: application/json" ${cmd} >get.json
        ObjectId=`cat get.json | cut -d"/" -f8 | cut -d"\"" -f1`
	echo ${ObjectId}
        echo ${artifactId}"|"${ObjectId}"|"${ObjectType} >> ObjectArtifactMapping.properties
    done
}

getProjects
newBranch
newPR
listArtifact
cat repos_*.json > AllDetails.json
rm -f repos_*.json
rm -f *sort.properties
rm -f branchkeys_*.json
rm -f branchkeys_*.properties
rm -f repokeys_*.json
rm -f repokeys_*.properties
rm -f PRkeys_*.json
rm -f PRkeys_*.properties
