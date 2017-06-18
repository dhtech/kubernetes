#!/bin/bash

set -euo pipefail

# Only look at the integer part of the CSN, should be good enough.
CSN=$(ldapsearch -x -s base -LLL contextCSN -H ldapi:/// \
  | awk '/contextCSN:/ {print $2}' | cut -f 1 -d '.')
INITIAL_CSN=$(</initial-contextCSN | cut -f 1 -d '.')

# If the local contextCSN is greater than or equal to the initial CSN the
# instance is considered to be in sync.
[ "${CSN}" -ge "${INITIAL_CSN}" ]
