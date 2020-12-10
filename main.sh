#BranchNames File
mv branchnames.properties branchnames_old.properties
echo projectkey}.repoSlug.branchName > branchnames.properties
#call project get api
#API

#call end project get api

totalProjects=`cat projects.json | jq '.size'`
for ((tp = 0 ; tp <= ${totalProjects} ; tp++))
do
	projectkey = `cat projects.json | jq '.values[${tp}].key`
	
	#call repos get api for each project key
	#API
	
	totalRepos=`cat repos_${projectkey}.json | jq '.size'`
	#call end repos get api
	for ((tr = 0 ; tr <= ${totalRepos} ; tr++))
	do
		repoSlug = `cat repos_${projectkey}.json | jq '.values[${tr}].slug`
		
		#Function for Branch Name
		#api call to get all brances for repo
		#API
		totalBranches=`cat repos_${projectkey}_${repoSlug}.json | jq '.size'`
		for ((tb = 0 ; tb <= ${totalBranches} ; tb++))
		do
			branchName = `cat repos_${projectkey}_${repoSlug}.json | jq '.values[${tb}].displayId`
			echo ${projectkey}.${repoSlug}.${branchName} >> branchnames.properties
		done
		#api call end to get all brances for repo
		#Function for Commits
		#Function for Pull Requests
	
	done	
	
done

msg_regex='[A-Z]+[A-Z]+[0-9]+'
comm branchnames.properties branchnames_old.properties -3 | grep -E $msg_regex > newbranches.properties
totalBranchesToBePushed = `cat newbranches.properties | wc -l`
artifactIds=`cat newbranches.properties | grep -oE $msg_regex`
for artifacts in `cat artifactIds | uniq`
do
	##GET API Call to Rally to validate artifact
	##In Progress
done





##POST API Call to Rally
#new branch has been created in BitBucket and URL for the same is 
