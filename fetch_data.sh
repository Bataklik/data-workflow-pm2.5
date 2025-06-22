#!/bin/bash

API_PM25_URL="https://bruxellesdata.opendatasoft.com/api/explore/v2.1/catalog/datasets/real-time-air-quality-in-belgium-pm25-fine-particulate-matter/records"
OUTPUT_DIR="raw_data"
LOG_FILE="logs/fetch_data.log"
LIMIT=100

declare -a NETWORKS=("Flanders" "Wallonia" "Brussels")

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "[$TIMESTAMP] Start fetch_data.sh" | tee -a "$LOG_FILE"

for NETWORK in "${NETWORKS[@]}"
do
  NETWORK_LOWER=$(echo "$NETWORK" | tr '[:upper:]' '[:lower:]')
  OUTPUT_FILE="${OUTPUT_DIR}/pm25_${NETWORK_LOWER}_${TIMESTAMP}.json"
  QUERY="?where=network='${NETWORK}'&limit=${LIMIT}"

  echo "[$TIMESTAMP] Download PM2.5 data voor ${NETWORK}" | tee -a "$LOG_FILE"
  curl -s "${API_PM25_URL}${QUERY}" -o "$OUTPUT_FILE"

  if [[ $? -ne 0 ]]; then
      echo "[$TIMESTAMP] FOUT: Download voor ${NETWORK} mislukt" | tee -a "$LOG_FILE"
  else
      echo "[$TIMESTAMP] Download gelukt: $OUTPUT_FILE" | tee -a "$LOG_FILE"
  fi
done