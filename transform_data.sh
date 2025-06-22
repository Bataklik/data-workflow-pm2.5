#!/bin/bash

INPUT_DIR="raw_data"
OUTPUT_DIR="processed_data"
LOG_FILE="logs/transform_data.log"
OUTPUT_FILE="combined_data"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_PATH="${OUTPUT_DIR}/${OUTPUT_FILE}_${TIMESTAMP}.csv"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$TIMESTAMP] Start transform_data.sh" | tee -a "$LOG_FILE"

# Header CSV schrijven
echo "timestamp,local_timestamp,lat,lon,ab_name,network,pm25_value,temperature_2m,apparent_temperature,relativehumidity_2m,windspeed_10m" > "$OUTPUT_PATH"

for FILE in "${INPUT_DIR}"/pm25_*.json; do
  echo "[$TIMESTAMP] Verwerk $FILE" | tee -a "$LOG_FILE"

  jq -c '.results[]' "$FILE" | while read -r RECORD; do
    LAT=$(echo "$RECORD" | jq '.geo_point.lat')
    LON=$(echo "$RECORD" | jq '.geo_point.lon')
    TS_PM25=$(echo "$RECORD" | jq -r '.timestamp')

    START=$(echo "$TS_PM25" | cut -c1-13):00:00
    END=$(date -u -d "${START} +1 hour" +"%Y-%m-%dT%H:00:00")

    WEATHER_JSON=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&hourly=temperature_2m,apparent_temperature,relativehumidity_2m,windspeed_10m&start=${START}&end=${END}&timezone=UTC")

    if [[ $(echo "$WEATHER_JSON" | jq '.hourly.temperature_2m | length') -gt 0 ]]; then
      TEMP=$(echo "$WEATHER_JSON" | jq '.hourly.temperature_2m[0]')
      APP_TEMP=$(echo "$WEATHER_JSON" | jq '.hourly.apparent_temperature[0]')
      HUM=$(echo "$WEATHER_JSON" | jq '.hourly.relativehumidity_2m[0]')
      WIND=$(echo "$WEATHER_JSON" | jq '.hourly.windspeed_10m[0]')
    else
      TEMP=null
      APP_TEMP=null
      HUM=null
      WIND=null
    fi

    datetime=$(TZ=Europe/Brussels date -d "$TS_PM25" +"%Y-%m-%dT%H:%M:%S%:z")

    printf '%s,"%s",%f,%f,"%s","%s",%s,%s,%s,%s,%s\n' \
      "$TS_PM25" \
      "$datetime" \
      "$LAT" \
      "$LON" \
      "$(echo "$RECORD" | jq -r '.ab_name')" \
      "$(echo "$RECORD" | jq -r '.network')" \
      "$(echo "$RECORD" | jq '.value')" \
      "$TEMP" \
      "$APP_TEMP" \
      "$HUM" \
      "$WIND" >> "$OUTPUT_PATH"
  done
done

echo "[$TIMESTAMP] Transform en CSV klaar: $OUTPUT_PATH" | tee -a "$LOG_FILE"
