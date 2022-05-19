#!/bin/bash
set -e

for file in /sql/*; do
    psql -U covid19_user -d covid19 -f "$file"
done
