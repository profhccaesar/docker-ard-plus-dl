#!/bin/bash
#
# Startskript für den Docker-Container - wird automatisch ausgeführt
#

cd "${HOME}/output"
ard-plus-dl.sh "$@"
rc=$?

# cleanup
rm -f ard-plus-token content-result.txt 2>/dev/null

exit ${rc}

