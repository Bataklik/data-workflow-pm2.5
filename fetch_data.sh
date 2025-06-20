#!/bin/bash

# === CONFIGURATIE ===
API_URL="https://bruxellesdata.opendatasoft.com/api/explore/v2.1/catalog/datasets/real-time-air-quality-in-belgium-pm25-fine-particulate-matter/records"
OUTPUT_DIR="raw_data"
LOG_FILE="logs/fetch_data.log"
LIMIT=100  # haal voldoende records op

# === NETWERKEN ===
declare -a NETWORKS=("Flanders" "Wallonia" "Brussels")

# === MAPPEN MAKEN ===
mkdir -p $OUTPUT_DIR
mkdir -p $(dirname $LOG_FILE)

# === TIMESTAMP ===
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# === LOOP OVER NETWERKEN ===
for NETWORK in "${NETWORKS[@]}"
do
  NETWORK_LOWER=$(echo "$NETWORK" | tr '[:upper:]' '[:lower:]')
  OUTPUT_FILE="${OUTPUT_DIR}/pm25_${NETWORK_LOWER}_${TIMESTAMP}.json"
  QUERY="?where=network='${NETWORK}'&limit=${LIMIT}"

  echo "[$TIMESTAMP] Download PM2.5 data voor ${NETWORK}" | tee -a $LOG_FILE
  curl -s "${API_URL}${QUERY}" -o $OUTPUT_FILE

  if [[ $? -eq 0 ]]; then
      echo "[$TIMESTAMP] Data voor ${NETWORK} opgeslagen in ${OUTPUT_FILE}" | tee -a $LOG_FILE
  else
      echo "[$TIMESTAMP] FOUT: Download voor ${NETWORK} mislukt" | tee -a $LOG_FILE
  fi
done
