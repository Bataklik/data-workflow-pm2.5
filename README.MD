# Luchtkwaliteits Data Workflow

Dit project bevat een geautomatiseerde workflow voor het verzamelen, transformeren, analyseren en rapporteren van luchtkwaliteitsdata (PM2.5). De scripts zijn geschreven in Bash en Python en maken het eenvoudig om ruwe API-data om te zetten in bruikbare rapporten.

## 📂 Projectstructuur

``` XML
data-workflow/
├── raw_data/           # ruwe JSON-bestanden, read-only
├── processed/          # samengevoegde CSV-bestanden
├── reports/            # rapporten + grafieken
├── logs/               # logbestanden van scripts
├── fetch_data.sh       # download script
├── transform_data.sh   # JSON -> CSV script
├── analyze_data.py     # analyse en grafieken
├── generate_report.sh  # rapportgeneratie
└── run_workflow.sh     # overkoepelend script
```

## ⚙️ Scripts

### `fetch_data.sh`

- Downloadt JSON-data van de API.
- Slaat bestanden op met een timestamp in `raw_data/`.
- Logt acties naar `logs/fetch_data.log`.

### `transform_data.sh`

- Combineert alle JSON-bestanden tot een CSV.
- Extract met `jq` de relevante velden (timestamp, device_id, locatie, PM2.5).

### `analyze_data.py`

- Analyseert het CSV-bestand met `pandas`.
- Genereert een tijdreeksplot (PNG).
- Berekent gemiddelde, max en min waarden van PM2.5.

### `generate_report.sh`

- Genereert een Markdown-rapport met grafieken en statistieken.
- Converteert naar HTML of PDF met `pandoc`.

### `run_workflow.sh`

- Voert de volledige pipeline automatisch uit:

```txt
1️⃣ Fetch → 2️⃣ Transform → 3️⃣ Analyze → 4️⃣ Report
```

## 🔧 Benodigdheden

- `bash`, `jq`, `curl` of `wget`
- `python3`, `pandas`, `matplotlib`
- `pandoc` (voor rapporten in HTML/PDF)

Installeer Python packages:

```bash
pip install pandas matplotlib
```

🚀 Gebruik

Alle stappen uitvoeren:

```bash
./run_workflow.sh
```

Of handmatig:

```bash
./fetch_data.sh
./transform_data.sh
python3 analyze_data.py
./generate_report.sh
```

📈 Output

- JSON-bestanden in raw_data/
- CSV-bestanden in processed/
- Grafieken (PNG) en rapporten (HTML/PDF) in reports/
