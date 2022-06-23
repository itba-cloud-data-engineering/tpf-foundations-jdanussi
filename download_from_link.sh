#!/bin/bash

download_from_link() {
 local download_link=$1; shift || return 1
 local temporary_dir

 temporary_dir=$(mktemp -d) \
 && export ec=18; while [ $ec -eq 18 ]; do curl -LO -C - "${download_link:-}"; export ec=$?; done \
 && unzip -d "$temporary_dir" \*.zip \
 && rm -rf *.zip \
 && mv "$temporary_dir"/* ${1:-"$PWD/etl/data"} \
 && rm -rf $temporary_dir
}