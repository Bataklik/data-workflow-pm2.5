#!/bin/bash

INPUT_CSV="processed_data/combined_data_*.csv"
REPORTS_DIR="reports"
mkdir -p "$REPORTS_DIR"

# Pak de meest recente CSV file
CSV_FILE=$(ls -t processed_data/combined_data_*.csv | head -1)

echo "Genereer rapport voor $CSV_FILE"

# Extract PM2.5 en datetime kolommen voor grafiek
cut -d',' -f2,7 "$CSV_FILE" > "${REPORTS_DIR}/pm25_timeseries.csv"

# Gnuplot script maken om PM2.5 tijdreeks te plotten
GNUPLOT_SCRIPT="${REPORTS_DIR}/plot_pm25.gnuplot"
cat > "$GNUPLOT_SCRIPT" << EOF
set datafile separator ","
set xdata time
set timefmt "%Y-%m-%dT%H:%M:%S%:z"
set format x "%H:%M\n%d-%m"
set title "PM2.5 Concentratie Tijdreeks"
set xlabel "Datum Tijd (Brussel)"
set ylabel "PM2.5 (µg/m³)"
set grid
set terminal png size 800,400
set output "${REPORTS_DIR}/pm25_timeseries.png"
plot "${REPORTS_DIR}/pm25_timeseries.csv" using 1:2 with lines title "PM2.5"
EOF

gnuplot "$GNUPLOT_SCRIPT"

echo "Rapport en grafiek gegenereerd in ${REPORTS_DIR}/"