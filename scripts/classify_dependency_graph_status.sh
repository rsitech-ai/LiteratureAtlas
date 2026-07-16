#!/bin/bash
set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: $0 REPOSITORY_HTTP_STATUS DEPENDENCY_GRAPH_HTTP_STATUS" >&2
    exit 64
fi

repository_status=$1
graph_status=$2

if [ "$repository_status" != "200" ]; then
    echo "Repository API access failed with HTTP $repository_status; dependency review will not be skipped." >&2
    exit 1
fi

case "$graph_status" in
    200)
        echo "available=true"
        ;;
    404)
        echo "available=false"
        echo "::warning::Dependency graph is unavailable for the accessible repository; lockfile audits remain mandatory." >&2
        ;;
    *)
        echo "Dependency graph API failed with HTTP $graph_status; dependency review will not be skipped." >&2
        exit 1
        ;;
esac
