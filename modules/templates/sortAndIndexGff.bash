#!/usr/bin/env bash

set -euo pipefail

sort -k1,1 -k4,4n ${gff} > ${uniqueId}.sorted.gff
cp ${uniqueId}.sorted.gff ${uniqueId}_sorted.gff.bkup
bgzip ${uniqueId}.sorted.gff
mv ${uniqueId}_sorted.gff.bkup ${uniqueId}.sorted.gff
tabix -p gff ${uniqueId}.sorted.gff.gz
