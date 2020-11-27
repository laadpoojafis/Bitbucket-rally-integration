	#!/bin/bash
	echo "Hi"
	msg_regex='[A-Z]+[0-9]+'
	tenant_name=`cat config_master.json | jq  -r .rally.tenant_name`
	
                repo_name=""
    		branch_name=`git branch | grep \* | cut -d ' ' -f2`
		commit_msg=`git log -1 | grep -Es $msg_regex`
		timestamp=`git log -1  --format="%ai" | sed 's/ /T/' | sed 's/ //'`
		echo ${timestamp}
		commit_id=`git rev-parse HEAD`
		build_url=`echo ${BUILD_URL}`
		echo ${BUILD_URL} 
		uri="https://bitbucket.org/Pooja-Laad/selenium-testing-task/commits/${commit_id}"
		name="<hyperlink to uri>"
	if [ $? -eq 0 ]
	then
		echo "Regex Match"
		 for ids in `git log -1 | grep -oE $msg_regex`
		 do
		        echo $ids 

	                ids1=${ids:0:2}
			echo "First 2 char are ${ids1}"
                  
                    for artefact in `cat config_master.json | jq  -r '.rally.artifactPrefix."'"${ids1}"'"'`
		do
		echo "Inside nested for loop ${artefact}"		   
	           cmd="https://rally1.rallydev.com/slm/webservice/v2.0/${artefact}?query=(FormattedID%20%3D%20${ids})"
		

		echo URL ${cmd} 
		curl --header "zsessionid:_5qkiIFxQaSYES9XL4aMNUFH2EeGMEiemV4EtMH4o" -H "Content-Type: application/json" ${cmd} >get.json
		
		
		cat get.json

		ObjectID=`cat get.json | jq '.QueryResult.Results[0]._ref' | grep -oE '[0-9][0-9][0-9]*'`
		echo ObjectID ${ObjectID}
		artifact="/${artefact}/${ObjectID}"

			echo ${artifact}
		curl --header "zsessionid:_5qkiIFxQaSYES9XL4aMNUFH2EeGMEiemV4EtMH4o" -H "Content-Type: application/json" -d '{"Changeset":{"Revision":"1","Uri":"'"${uri}"'","CommitTimestamp":"'"${timestamp}"'","Message":"'"${commit_msg}"'","Author":"/user/411667913296","SCMRepository":"/scmrepository/424317194036","Branch":"'"${branch_name}"'","Builds":{"Builds":"'"${build_url}"'"},"Artifacts":{"Artifact":"'"${artifact}"'"}}}' https://rally1.rallydev.com/slm/webservice/v2.0/changeset/create?workspace=workspace/10703513144 >post.json
		 echo "Printing POST Json" 
		 cat post.json
		 done
		done
	else
		echo "Commit doesn't contain Rally Artifact ID"
	fi
