## 01_fetch_data.R — Fetch RTB/ESRI Rent Index from CSO PxStat
## apep_0806: Ireland Rent Pressure Zones
##
## Data: CSO PxStat table RIQ02 — RTB/ESRI Quarterly Rent Index
## 26 counties, 72 quarters (2007Q4–2025Q3), standardised average monthly rent

source("00_packages.R")

# ── 1. Download RIQ02 via JSON-stat API and parse in Python ───────────────
cat("Fetching RIQ02 from CSO PxStat...\n")

# Use system Python to parse JSON-stat (rjstat has issues with this dataset)
py_script <- '
import json, sys, csv, urllib.request

url = "https://ws.cso.ie/public/api.restful/PxStat.Data.Cube_API.ReadDataset/RIQ02/JSON-stat/2.0/en/"
with urllib.request.urlopen(url, timeout=120) as resp:
    data = json.loads(resp.read().decode())

dims = data["id"]
dim_sizes = data["size"]
dim_labels = {}
dim_indices = {}
for d in dims:
    dd = data["dimension"][d]
    idx_raw = dd["category"]["index"]
    if isinstance(idx_raw, dict):
        idx = sorted(idx_raw.keys(), key=lambda x: idx_raw[x])
    else:
        idx = idx_raw
    dim_labels[d] = dd["category"]["label"]
    dim_indices[d] = idx

values = data["value"]

bed_idx = dim_indices["C02970V03592"]
prop_idx = dim_indices["C02969V03591"]
loc_idx = dim_indices["C03004V03625"]
time_idx = dim_indices["TLIST(Q1)"]

all_bed_key = [k for k, v in dim_labels["C02970V03592"].items() if "All bed" in v][0]
all_prop_key = [k for k, v in dim_labels["C02969V03591"].items() if "All prop" in v][0]
all_bed_pos = bed_idx.index(all_bed_key)
all_prop_pos = prop_idx.index(all_prop_key)

n_time, n_bed, n_prop, n_loc = dim_sizes[1], dim_sizes[2], dim_sizes[3], dim_sizes[4]

irish_counties = [
    "Carlow", "Cavan", "Clare", "Cork", "Donegal", "Dublin",
    "Galway", "Kerry", "Kildare", "Kilkenny", "Laois", "Leitrim",
    "Limerick", "Longford", "Louth", "Mayo", "Meath", "Monaghan",
    "Offaly", "Roscommon", "Sligo", "Tipperary", "Waterford",
    "Westmeath", "Wexford", "Wicklow"
]

county_locs = {k: v for k, v in dim_labels["C03004V03625"].items() if v in irish_counties}

with open(sys.argv[1], "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["county", "quarter", "rent_eur"])
    for t_pos, t_key in enumerate(time_idx):
        t_label = dim_labels["TLIST(Q1)"][t_key]
        for loc_key, loc_label in county_locs.items():
            l_pos = loc_idx.index(loc_key)
            flat_idx = t_pos * (n_bed * n_prop * n_loc) + all_bed_pos * (n_prop * n_loc) + all_prop_pos * n_loc + l_pos
            val = values.get(str(flat_idx)) if isinstance(values, dict) else (values[flat_idx] if flat_idx < len(values) else None)
            if val is not None:
                w.writerow([loc_label, t_label, val])
'

out_csv <- "../data/rent_county.csv"
writeLines(py_script, "../data/_fetch_riq02.py")
exit_code <- system2("python3", args = c("../data/_fetch_riq02.py", out_csv),
                     stdout = TRUE, stderr = TRUE)
cat(exit_code, sep = "\n")

stopifnot(file.exists(out_csv))
rent_raw <- read.csv(out_csv, stringsAsFactors = FALSE)
cat("Downloaded", nrow(rent_raw), "rows for", length(unique(rent_raw$county)), "counties.\n")
stopifnot(nrow(rent_raw) > 1000)  # Expect 26 × 72 = 1872

# ── 2. Parse and clean ───────────────────────────────────────────────────
rent <- rent_raw %>%
  mutate(
    year = as.integer(sub("(\\d{4}).*", "\\1", quarter)),
    qtr  = as.integer(sub(".*Q(\\d)", "\\1", quarter)),
    yq   = paste0(year, "Q", qtr),
    time_id = year * 4L + qtr,
    log_rent = log(rent_eur)
  )

cat("Time range:", min(rent$yq), "to", max(rent$yq), "\n")
cat("Counties:", length(unique(rent$county)), "\n")

# ── 3. RPZ treatment timing ──────────────────────────────────────────────
# First LEA designated as RPZ per county
# Sources: SI 625/2016, SI 17/2017, SI 246/2017, SI 407/2017,
#          SI 21/2018, SI 6/2019, Residential Tenancies (No.2) Act 2021

rpz_dates <- tribble(
  ~county,       ~rpz_date,
  "Dublin",      "2016-12-24",  # SI 625/2016: all 4 Dublin LAs
  "Cork",        "2016-12-24",  # SI 625/2016: Cork City
  "Galway",      "2017-01-26",  # SI 17/2017: Galway City
  "Kildare",     "2017-01-26",  # SI 17/2017: Maynooth LEA
  "Louth",       "2017-09-26",  # SI 407/2017: Drogheda
  "Wicklow",     "2017-09-26",  # SI 407/2017: Greystones
  "Meath",       "2017-09-26",  # SI 407/2017: Ashbourne-Ratoath
  "Limerick",    "2018-01-17",  # SI 21/2018: Limerick City
  "Waterford",   "2019-01-03",  # SI 6/2019: Waterford City
  "Kilkenny",    "2019-01-03",  # SI 6/2019
  "Carlow",      "2019-01-03",  # SI 6/2019
  "Westmeath",   "2019-01-03",  # SI 6/2019: Athlone
  # Remaining counties: national RPZ from Residential Tenancies (No.2) Act 2021
  "Cavan",       "2021-08-01",
  "Clare",       "2021-08-01",
  "Donegal",     "2021-08-01",
  "Kerry",       "2021-08-01",
  "Laois",       "2021-08-01",
  "Leitrim",     "2021-08-01",
  "Longford",    "2021-08-01",
  "Mayo",        "2021-08-01",
  "Monaghan",    "2021-08-01",
  "Offaly",      "2021-08-01",
  "Roscommon",   "2021-08-01",
  "Sligo",       "2021-08-01",
  "Tipperary",   "2021-08-01",
  "Wexford",     "2021-08-01"
)

rpz_dates <- rpz_dates %>%
  mutate(
    rpz_date    = as.Date(rpz_date),
    rpz_year    = year(rpz_date),
    rpz_qtr     = quarter(rpz_date),
    rpz_yq      = paste0(rpz_year, "Q", rpz_qtr),
    first_treat = rpz_year * 4L + rpz_qtr
  )

cat("\nTreatment cohorts:\n")
print(rpz_dates %>% count(rpz_yq) %>% arrange(rpz_yq))

# ── 4. Merge and create panel ────────────────────────────────────────────
panel <- rent %>%
  left_join(rpz_dates %>% select(county, first_treat, rpz_yq), by = "county") %>%
  mutate(
    county_id = as.integer(factor(county)),
    post_rpz  = as.integer(time_id >= first_treat),
    # Relative time (event time)
    rel_time  = time_id - first_treat
  )

stopifnot(all(!is.na(panel$first_treat)))

# Restrict to 2012Q1+ (pre-crisis recovery distorts earlier data)
panel <- panel %>% filter(year >= 2012)

cat("\nFinal panel:\n")
cat("  Obs:", nrow(panel), "\n")
cat("  Counties:", n_distinct(panel$county), "\n")
cat("  Quarters:", n_distinct(panel$yq), "\n")
cat("  Time range:", min(panel$yq), "to", max(panel$yq), "\n")
cat("  Cohort sizes:\n")
print(panel %>% distinct(county, rpz_yq) %>% count(rpz_yq))

# ── 5. Save ──────────────────────────────────────────────────────────────
saveRDS(panel, "../data/rent_panel.rds")
write.csv(panel, "../data/rent_panel.csv", row.names = FALSE)
saveRDS(rpz_dates, "../data/rpz_dates.rds")

cat("\n✓ Panel saved: data/rent_panel.rds\n")
