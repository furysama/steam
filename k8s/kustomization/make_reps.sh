#!/bin/bash

replicas=1

NUM_NODES=2

while getopts ":r:n:" flag
do
	case "${flag}" in
		r ) if [ "$OPTARG" -eq "$OPTARG" ] 2>/dev/null; then replicas=${OPTARG}; fi ;;
		n ) if [ "$OPTARG" -eq "$OPTARG" ] 2>/dev/null; then NUM_NODES=${OPTARG}; fi ;;
		\?) echo "Usage: $0 [-r] [-n]"; exit -1;;
	esac
done

echo "Replicas: $replicas"

cp templates/base_kustomization.template kustomization.yaml
# use a c-style loop to force replicas to be treated as integer
for (( i = 0 ; i <= $( expr $replicas - 1 ) ; i++)); do
	if [ $i -eq 0 ]; then
		SERIES="base"
	else
		SERIES="series-$i"
	fi
	if [[ ! -d $SERIES ]]; then
		mkdir $SERIES
	fi
	
	SERVER_PORT=$(expr 31337 + $i \* 2)
	QUERY_PORT=$(expr 31338 + $i \* 2)

	echo "Creating $SERIES with server port $SERVER_PORT and query port $QUERY_PORT"
	envsubst < templates/stateful_set.template > $SERIES/stateful_set.yaml
	envsubst < templates/series.template > $SERIES/series.yaml
	envsubst < templates/service.template > $SERIES/service.yaml
	cp templates/kustomization.template $SERIES/kustomization.yaml
	echo "- $SERIES" >> kustomization.yaml
done

set -e
kustomize build . > dry_run
kubectl apply -f dry_run --dry-run=client
mv dry_run deploy.yaml
exit 0
