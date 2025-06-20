#!/bin/bash

# === CONFIGURATIE ===
API_PM25_URL="https://bruxellesdata.opendatasoft.com/api/explore/v2.1/catalog/datasets/real-time-air-quality-in-belgium-pm25-fine-particulate-matter/records"
OUTPUT_DIR="raw_data"
COMBINED_FILE="combined_data"
LOG_FILE="logs/fetch_and_combine.log"
LIMIT=100

declare -a NETWORKS=("Flanders" "Wallonia" "Brussels")

# === MAPPEN MAKEN ===
mkdir -p $OUTPUT_DIR
mkdir -p $(dirname $LOG_FILE)

# === TIMESTAMP ===
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "[$TIMESTAMP] Start fetch_and_combine.sh" | tee -a $LOG_FILE

> ${OUTPUT_DIR}/${COMBINED_FILE}_${TIMESTAMP}.json
echo "[" >> ${OUTPUT_DIR}/${COMBINED_FILE}_${TIMESTAMP}.json

FIRST_RECORD=true

# === LOOP OVER NETWERKEN ===
for NETWORK in "${NETWORKS[@]}"
do
  NETWORK_LOWER=$(echo "$NETWORK" | tr '[:upper:]' '[:lower:]')
  OUTPUT_FILE="${OUTPUT_DIR}/pm25_${NETWORK_LOWER}_${TIMESTAMP}.json"
  QUERY="?where=network='${NETWORK}'&limit=${LIMIT}"

  echo "[$TIMESTAMP] Download PM2.5 data voor ${NETWORK}" | tee -a $LOG_FILE
  curl -s "${API_PM25_URL}${QUERY}" -o $OUTPUT_FILE

  if [[ $? -ne 0 ]]; then
      echo "[$TIMESTAMP] FOUT: Download voor ${NETWORK} mislukt" | tee -a $LOG_FILE
      continue
  fi

  echo "[$TIMESTAMP] Verwerk PM2.5 data voor ${NETWORK}" | tee -a $LOG_FILE

  jq -c '.results[]' "$OUTPUT_FILE" | while read -r RECORD; do
    LAT=$(echo "$RECORD" | jq '.geo_point.lat')
    LON=$(echo "$RECORD" | jq '.geo_point.lon')
    TS_PM25=$(echo "$RECORD" | jq -r '.timestamp')

    START=$(echo "$TS_PM25" | cut -c1-13):00:00
    END=$(date -u -d "${START} +1 hour" +"%Y-%m-%dT%H:00:00")

    # Weerdata ophalen
    WEATHER_JSON=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&hourly=temperature_2m,relativehumidity_2m,windspeed_10m&start=${START}&end=${END}&timezone=UTC")

    # Check of data aanwezig is
    if [[ $(echo "$WEATHER_JSON" | jq '.hourly.temperature_2m | length') -gt 0 ]]; then
      TEMP=$(echo "$WEATHER_JSON" | jq '.hourly.temperature_2m[0]')
      HUM=$(echo "$WEATHER_JSON" | jq '.hourly.relativehumidity_2m[0]')
      WIND=$(echo "$WEATHER_JSON" | jq '.hourly.windspeed_10m[0]')
    else
      TEMP=null
      HUM=null
      WIND=null
    fi

    # Combineer
    COMBINED_JSON=$(jq -n \
      --arg ts "$TS_PM25" \
      --argjson lat "$LAT" \
      --argjson lon "$LON" \
      --arg ab_name "$(echo "$RECORD" | jq -r '.ab_name')" \
      --arg network "$(echo "$RECORD" | jq -r '.network')" \
      --argjson pm25_value "$(echo "$RECORD" | jq '.value')" \
      --argjson temp "$TEMP" \
      --argjson hum "$HUM" \
      --argjson wind "$WIND" \
      '{
        timestamp: $ts,
        location: {
          lat: $lat,
          lon: $lon,
          ab_name: $ab_name,
          network: $network
        },
        pm25_value: $pm25_value,
        weather: {
          temperature_2m: $temp,
          relativehumidity_2m: $hum,
          windspeed_10m: $wind
        }
      }')

    # JSON netjes toevoegen met komma's tussen records
    if $FIRST_RECORD; then
      echo "$COMBINED_JSON" >> ${OUTPUT_DIR}/${COMBINED_FILE}_${TIMESTAMP}.json
      FIRST_RECORD=false
    else
      echo "," >> ${OUTPUT_DIR}/${COMBINED_FILE}_${TIMESTAMP}.json
      echo "$COMBINED_JSON" >> ${OUTPUT_DIR}/${COMBINED_FILE}_${TIMESTAMP}.json
    fi
  done
done

echo "]" >> ${OUTPUT_DIR}/${COMBINED_FILE}_${TIMESTAMP}.json
echo "[$TIMESTAMP] Combinatie voltooid: ${OUTPUT_DIR}/${COMBINED_FILE}_${TIMESTAMP}.json" | tee -a $LOG_FILE
