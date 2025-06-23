import pandas as pd
import matplotlib.pyplot as plt
import sys

# CSV pad als argument, bv: python analyze_data.py processed_data/combined_data_20250620_123456.csv
csv_file = sys.argv[1]

# Lees CSV
df = pd.read_csv(csv_file, parse_dates=['timestamp', 'datetime'])

# Statistieken PM2.5
mean_pm25 = df['pm25_value'].mean()
max_pm25 = df['pm25_value'].max()
min_pm25 = df['pm25_value'].min()

print(f"PM2.5 gemiddeld: {mean_pm25:.2f}")
print(f"PM2.5 max: {max_pm25:.2f}")
print(f"PM2.5 min: {min_pm25:.2f}")

# Tijdreeksplot PM2.5 (per timestamp, evt. gemiddeld over alle locaties)
ts_avg = df.groupby('timestamp')['pm25_value'].mean()

plt.figure(figsize=(10,5))
ts_avg.plot()
plt.title('Gemiddelde PM2.5 over tijd')
plt.xlabel('Tijd (UTC)')
plt.ylabel('PM2.5 (µg/m³)')
plt.grid(True)
plt.tight_layout()

# Opslaan plot als PNG (zelfde map als CSV, zelfde timestamp)
png_file = csv_file.replace('.csv', '_pm25_timeseries.png')
plt.savefig(png_file)
print(f"Tijdreeksplot opgeslagen in {png_file}")