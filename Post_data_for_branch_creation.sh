curl --header "zsessionid:_5qkiIFxQaSYES9XL4aMNUFH2EeGMEiemV4EtMH4o" -H "Content-Type: application/json"  -d  '{"Connection":{"Description":"Created branch in bitbucket","Name":"testing"}}' https://rally1.rallydev.com/slm/webservice/v2.0/Connection/create?workspace=workspace/10703513144 >post.json
echo "Printing POST Json"
