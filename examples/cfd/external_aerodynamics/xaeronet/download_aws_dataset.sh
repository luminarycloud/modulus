#!/bin/bash

# Usage: ./script.sh -d <local_directory> [-s]
# Use -s flag to skip downloading volume files (.vtu)
SKIP_VOLUME=false
while getopts "d:s" opt; do
    case $opt in
        d) LOCAL_DIR="$OPTARG";;
        s) SKIP_VOLUME=true;;
        \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
    esac
done

if [ -z "$LOCAL_DIR" ]; then
    echo "Error: Local directory (-d) must be specified"
    echo "Usage: $0 -d <local_directory> [-s]"
    echo "  -d: Specify local directory for downloads"
    echo "  -s: Skip downloading volume files (optional)"
    exit 1
fi

S3_BUCKET="caemldatasets"
S3_PREFIX="drivaer/dataset"

mkdir -p "$LOCAL_DIR"

download_run_files() {
    local i=$1
    RUN_DIR="run_$i"
    RUN_LOCAL_DIR="$LOCAL_DIR/$RUN_DIR"
    mkdir -p "$RUN_LOCAL_DIR"

    # Download volume file if not skipped
    if [ "$SKIP_VOLUME" = false ]; then
        if [ ! -f "$RUN_LOCAL_DIR/volume_$i.vtu" ]; then
            aws s3 cp --no-sign-request "s3://$S3_BUCKET/$S3_PREFIX/$RUN_DIR/volume_$i.vtu" "$RUN_LOCAL_DIR/" &
       fi
    fi

    # Download STL and VTP files
    if [ ! -f "$RUN_LOCAL_DIR/drivaer_$i.stl" ]; then
        aws s3 cp --no-sign-request "s3://$S3_BUCKET/$S3_PREFIX/$RUN_DIR/drivaer_$i.stl" "$RUN_LOCAL_DIR/" &
    fi

    if [ ! -f "$RUN_LOCAL_DIR/boundary_$i.vtp" ]; then
        aws s3 cp --no-sign-request "s3://$S3_BUCKET/$S3_PREFIX/$RUN_DIR/boundary_$i.vtp" "$RUN_LOCAL_DIR/" &
    fi

    # Download CSV files
    for csv in "force_mom_$i.csv" "force_mom_constref_$i.csv" "geo_parameters_$i.csv" "geo_ref_$i.csv"; do
        if [ ! -f "$RUN_LOCAL_DIR/$csv" ]; then
            aws s3 cp --no-sign-request "s3://$S3_BUCKET/$S3_PREFIX/$RUN_DIR/$csv" "$RUN_LOCAL_DIR/" &
        fi
    done
    
    wait
}

for i in $(seq 1 500); do
    download_run_files "$i" &
    if (( $(jobs -r | wc -l) >= 8 )); then
        wait -n
    fi
done

wait 
