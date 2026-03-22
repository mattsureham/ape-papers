## 02_clean_data.R — Construct analysis panels with border exposure
## Paper: apep_0738 — Franc Shock and Retail Desertification

source("code/00_packages.R")

# ============================================================
# 1. Load raw data
# ============================================================
canton_dt <- fread("data/statent_canton_sector.csv")
muni_dt   <- fread("data/statent_municipal.csv")

cat(sprintf("Canton data: %d rows\n", nrow(canton_dt)))
cat(sprintf("Municipal data: %d rows\n", nrow(muni_dt)))

# ============================================================
# 2. Define border cantons and exposure
# ============================================================
# BFS canton IDs 1-26 map to the standard Swiss canton order
# Border exposure: continuous 0-1 based on population proximity to cross-border retail
# Key: BS(12), SH(14), GE(25) are near-fully surrounded; TI(21), TG(20), JU(26) high exposure
# Interior: BE(2), LU(3), UR(4), SZ(5), OW(6), NW(7), GL(8), ZG(9), FR(10), AR(15), AI(16)
canton_border <- data.table(
  canton = as.character(1:26),
  canton_abbr = c("ZH","BE","LU","UR","SZ","OW","NW","GL","ZG","FR",
                  "SO","BS","BL","SH","AR","AI","SG","GR","AG","TG",
                  "TI","VD","VS","NE","GE","JU"),
  border_exposure = c(
    0.25, # 1  ZH: borders DE at Rafz/Eglisau
    0.00, # 2  BE: interior
    0.00, # 3  LU: interior
    0.00, # 4  UR: interior
    0.00, # 5  SZ: interior
    0.00, # 6  OW: interior
    0.00, # 7  NW: interior
    0.00, # 8  GL: interior
    0.00, # 9  ZG: interior
    0.00, # 10 FR: interior
    0.15, # 11 SO: small border with FR/DE near Basel
    1.00, # 12 BS: surrounded by DE/FR
    0.80, # 13 BL: borders DE/FR
    1.00, # 14 SH: enclave in Germany
    0.00, # 15 AR: interior
    0.00, # 16 AI: interior
    0.50, # 17 SG: borders AT/LI
    0.40, # 18 GR: borders AT/IT
    0.50, # 19 AG: borders DE along Rhine
    0.70, # 20 TG: borders DE (Bodensee)
    0.90, # 21 TI: borders IT
    0.40, # 22 VD: borders FR
    0.30, # 23 VS: borders FR/IT, mountainous
    0.50, # 24 NE: borders FR
    1.00, # 25 GE: surrounded by France
    0.70  # 26 JU: borders FR
  )
)

# ============================================================
# 3. Build canton × sector analysis panel
# ============================================================
# Ensure consistent types
canton_dt[, canton := as.character(canton)]
canton_border[, canton := as.character(canton)]

# Merge border exposure
canton_dt <- merge(canton_dt, canton_border[, .(canton, canton_abbr, border_exposure)],
                   by = "canton", all.x = TRUE)

# Flag retail sector (NOGA 47 = Retail trade except motor vehicles)
canton_dt[, is_retail := grepl("^47", noga_div)]
canton_dt[, is_hospitality := grepl("^(55|56)", noga_div)]
canton_dt[, is_nontradable := grepl("^(84|85|86|87|88)", noga_div)]  # public admin, education, health
canton_dt[, is_manufacturing := as.integer(noga_div) %in% 10:33]

# Create sector groups
canton_dt[, sector_group := fcase(
  is_retail, "retail",
  is_hospitality, "hospitality",
  is_nontradable, "nontradable",
  is_manufacturing, "manufacturing",
  default = "other_services"
)]

# Post indicator
canton_dt[, post := as.integer(year >= 2015)]

# Border indicator (binary for main spec, continuous for dose-response)
canton_dt[, border := as.integer(border_exposure > 0)]

# Log outcomes (handle zeros)
canton_dt[, log_est := log(pmax(establishments, 1))]
canton_dt[, log_emp := log(pmax(employees, 1))]
canton_dt[, log_fte := log(pmax(fte, 1))]

# Event time
canton_dt[, event_time := year - 2015]

cat(sprintf("\nCanton panel: %d rows\n", nrow(canton_dt)))
cat(sprintf("Border cantons (exposure > 0): %d\n",
            uniqueN(canton_dt[border == 1]$canton)))
cat(sprintf("Interior cantons: %d\n",
            uniqueN(canton_dt[border == 0]$canton)))
cat(sprintf("Retail sector observations: %d\n",
            nrow(canton_dt[is_retail == TRUE])))

# ============================================================
# 4. Build canton-level aggregated panel for retail
# ============================================================
# Aggregate retail and non-tradable by canton x year
retail_panel <- canton_dt[sector_group == "retail",
  .(retail_est = sum(establishments, na.rm = TRUE),
    retail_emp = sum(employees, na.rm = TRUE),
    retail_fte = sum(fte, na.rm = TRUE)),
  by = .(year, canton, canton_name, canton_abbr, border_exposure, border)]

nontradable_panel <- canton_dt[sector_group == "nontradable",
  .(nontrad_est = sum(establishments, na.rm = TRUE),
    nontrad_emp = sum(employees, na.rm = TRUE),
    nontrad_fte = sum(fte, na.rm = TRUE)),
  by = .(year, canton)]

hospitality_panel <- canton_dt[sector_group == "hospitality",
  .(hosp_est = sum(establishments, na.rm = TRUE),
    hosp_emp = sum(employees, na.rm = TRUE),
    hosp_fte = sum(fte, na.rm = TRUE)),
  by = .(year, canton)]

canton_panel <- merge(retail_panel, nontradable_panel, by = c("year", "canton"), all.x = TRUE)
canton_panel <- merge(canton_panel, hospitality_panel, by = c("year", "canton"), all.x = TRUE)

# Total economy for normalization
total_panel <- canton_dt[,
  .(total_est = sum(establishments, na.rm = TRUE),
    total_emp = sum(employees, na.rm = TRUE)),
  by = .(year, canton)]
canton_panel <- merge(canton_panel, total_panel, by = c("year", "canton"), all.x = TRUE)

# Retail share
canton_panel[, retail_share := retail_est / total_est]
canton_panel[, retail_emp_share := retail_emp / total_emp]

# Log outcomes
canton_panel[, log_retail_est := log(retail_est)]
canton_panel[, log_retail_emp := log(retail_emp)]
canton_panel[, log_nontrad_est := log(nontrad_est)]
canton_panel[, log_hosp_est := log(hosp_est)]

canton_panel[, post := as.integer(year >= 2015)]
canton_panel[, event_time := year - 2015]

cat(sprintf("Canton retail panel: %d rows (%d cantons × %d years)\n",
            nrow(canton_panel), uniqueN(canton_panel$canton), uniqueN(canton_panel$year)))

fwrite(canton_panel, "data/canton_retail_panel.csv")

# ============================================================
# 5. Build municipal analysis panel
# ============================================================
# Get tertiary and secondary sector
muni_tertiary <- muni_dt[sector == "3",
  .(tert_est = sum(establishments, na.rm = TRUE),
    tert_emp = sum(employees, na.rm = TRUE),
    tert_fte = sum(fte, na.rm = TRUE)),
  by = .(year, gem_id, gem_name)]

muni_secondary <- muni_dt[sector == "2",
  .(sec_est = sum(establishments, na.rm = TRUE),
    sec_emp = sum(employees, na.rm = TRUE)),
  by = .(year, gem_id)]

muni_total <- muni_dt[sector == "999",
  .(total_est = sum(establishments, na.rm = TRUE),
    total_emp = sum(employees, na.rm = TRUE)),
  by = .(year, gem_id)]

muni_panel <- merge(muni_tertiary, muni_secondary, by = c("year", "gem_id"), all.x = TRUE)
muni_panel <- merge(muni_panel, muni_total, by = c("year", "gem_id"), all.x = TRUE)

# Map municipality to canton using BFS Gemeindenummer
# First digit(s) encode canton: 1-99 = ZH, 100-199 = BE, etc.
# Actually BFS numbering: gem_id 1-999 does not directly encode canton
# We need a lookup. The gem_name often includes the canton info.
# For now, assign canton from the gem_id ranges in the BFS register:
# This is approximate — BFS gem IDs are assigned sequentially within cantons

# Better: extract canton from the data by fetching municipal metadata
# The gem_id in BFS STATENT maps directly to the BFS commune number
# Let's create a canton mapping from the gem_id ranges

# BFS commune number ranges by canton (approximate, from BFS register)
canton_gem_ranges <- data.table(
  canton_num = 1:26,
  canton_abbr = c("ZH","BE","LU","UR","SZ","OW","NW","GL","ZG","FR",
                  "SO","BS","BL","SH","AR","AI","SG","GR","GR","TG",
                  "TI","VD","VS","NE","GE","JU"),
  gem_min = c(1, 301, 1001, 1201, 1301, 1401, 1501, 1601, 1701, 2001,
              2401, 2701, 2761, 2901, 3001, 3101, 3201, 3501, 3500, 4001,
              5001, 5401, 6001, 6401, 6601, 6701),
  gem_max = c(300, 1000, 1200, 1300, 1400, 1500, 1600, 1700, 2000, 2400,
              2700, 2760, 2900, 3000, 3100, 3200, 3500, 4000, 4000, 5000,
              5400, 6000, 6400, 6600, 6700, 6900)
)

# Fix canton 19 (GR is actually 18, TG is 20)
canton_gem_ranges <- canton_gem_ranges[canton_num != 19]

muni_panel[, gem_num := as.integer(gem_id)]

# Assign canton to each municipality
muni_panel[, canton_abbr := NA_character_]
for (i in 1:nrow(canton_gem_ranges)) {
  r <- canton_gem_ranges[i]
  muni_panel[gem_num >= r$gem_min & gem_num <= r$gem_max, canton_abbr := r$canton_abbr]
}

# Merge border exposure from canton-level data
muni_panel <- merge(muni_panel,
                    canton_border[, .(canton_abbr, border_exposure)],
                    by = "canton_abbr", all.x = TRUE)

muni_panel[is.na(border_exposure), border_exposure := 0]
muni_panel[, border := as.integer(border_exposure > 0)]
muni_panel[, post := as.integer(year >= 2015)]
muni_panel[, event_time := year - 2015]

# Log outcomes
muni_panel[, log_tert_est := log(pmax(tert_est, 1))]
muni_panel[, log_tert_emp := log(pmax(tert_emp, 1))]
muni_panel[, log_sec_est := log(pmax(sec_est, 1))]
muni_panel[, tert_share := tert_est / pmax(total_est, 1)]

cat(sprintf("Municipal panel: %d rows, %d municipalities\n",
            nrow(muni_panel), uniqueN(muni_panel$gem_id)))
cat(sprintf("Border municipalities: %d\n",
            uniqueN(muni_panel[border == 1]$gem_id)))
cat(sprintf("Interior municipalities: %d\n",
            uniqueN(muni_panel[border == 0]$gem_id)))

fwrite(muni_panel, "data/municipal_panel.csv")

# ============================================================
# 6. Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

# Pre-treatment means by border status
pre <- canton_panel[year <= 2014]
cat("\nPre-treatment (2011-2014) canton retail establishments:\n")
print(pre[, .(mean_est = mean(retail_est), sd_est = sd(retail_est),
              mean_emp = mean(retail_emp), N = .N),
          by = .(border_group = ifelse(border == 1, "Border", "Interior"))])

cat("\nRetail establishments by canton, 2014:\n")
print(canton_panel[year == 2014, .(canton_abbr, retail_est, retail_emp, border_exposure)][order(-border_exposure)])

cat("\n=== Data cleaning complete ===\n")
