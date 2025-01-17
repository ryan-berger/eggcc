#!/bin/bash

set -e

# do cleanup on exit. if debugging, comment out line 9
cleanup() {
  rm -r ./tmp/
}
trap cleanup EXIT

# TODO: take in file glob as command line argument
PROFILES=tests/small/add.bril

# create temporary directory structure necessary for bench runs
mkdir -p ./tmp/bench
mkdir ./tmp/hyperfine

# bench will benchmark a single bril file, outputting its contents to ./tmp/bench/<profile_name>.json
bench() {
    profile=$1

    # strip the file path down to just the file name
    # TODO: profile name is not unique, generate a unique output path (it will be aggregated anyway)
    profile_name=$(basename -- $profile)

    # run eggcc, interp the program and put the data out to $out
    out="./tmp/bench/${profile_name}.json"

    cargo run --release $profile --interp --profile-out "$out"

    # $out now contains a key value of total_dyn_inst: value, so use read to get the key/value
    # TODO: this is kind of a yaml sort of format so maybe yq would be good in the future
    read KEY VAL <<< $(cat $out)

    # export hyperfine out to tmp file
    hyperfine_out="./tmp/hyperfine/${profile_name}.json"
    hyperfine --warmup 2 --export-json "$hyperfine_out" "cargo run --release $profile --interp"

    # overwwrite outfile with json version of profile data, annotate with profile name.
    # we also combine both instruction count and hyperfine json output into a single object
    # to make things super easy
    printf '{"%s": {"%s": "%s", "hyperfine": %s}}' \
      $profile $KEY $VAL \
      "$(cat "./tmp/hyperfine/${profile_name}.json")" > $out
}

for p in $PROFILES
do
  bench $p
done

# aggregate all profile data into a single JSON array
jq -s '.' ./tmp/bench/*.json > nightly/data/profile.json
