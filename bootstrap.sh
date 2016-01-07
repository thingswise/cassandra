#!/dumb-init /bin/bash

set -x

skydns_key=${CASSANDRA_SKYDNS:-/local/skydns/cassandra}
local_address=${LOCAL_ADDRESS:-NOADDR}


hosts=()

while read idx _ value
do 
  v1=$(echo $value|sed 's/.*"host"\s*:\s*"\([^"]*\)".*/\1/')
  if [ $v1 != $local_address ]; then
    hosts+=($v1)
  fi
done < <(curl http://172.17.42.1:4001/v2/keys/skydns${skydns_key}?consistent=true 2>/dev/null | \
  /JSON.sh | \
  egrep '\["node","nodes",([^,]*),"(value)"\]' | \
  sed 's/\["node","nodes",\([^,]*\),"\(key\|value\)"\]\t"\(.*\)"/\1 \2 \3/')

hosts_str=$(IFS=","; echo "${hosts[*]}")
declare -p hosts_str
    
echo "Starting cassandra with seeds: ${hosts_str}"    
    
CASSANDRA_SEEDS="${hosts_str}" 
exec /docker-entrypoint.sh $*
