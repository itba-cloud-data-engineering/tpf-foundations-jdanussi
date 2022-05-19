#!/bin/bash

download_from_link() {
 local download_link=$1; shift || return 1
 local temporary_dir

 temporary_dir=$(mktemp -d) \
 && curl -LO "${download_link:-}" \
 && unzip -d "$temporary_dir" \*.zip \
 && rm -rf *.zip \
 && mv "$temporary_dir"/* ${1:-"$PWD/etl/data"} \
 && rm -rf $temporary_dir
}