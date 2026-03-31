# 02_clean_data.R — Clean and merge STATENT + Steuerfuss + Population
source("code/00_packages.R")

cat("=== Cleaning data ===\n")

# ============================================================
# 1. STATENT: Pivot to municipality-year panel
# ============================================================
cat("--- 1. Processing STATENT ---\n")
statent_raw <- fread("data/statent_total_raw.csv")

# Extract BFS number from "261 Zürich" format
statent_raw[, bfsnr := as.integer(str_extract(Gemeinde, "^\\d+"))]

# Pivot: one row per municipality-year with columns for establishments & employees
statent_raw[, year := as.integer(Jahr)]
estab <- statent_raw[Beobachtungseinheit == "Arbeitsstätten",
                     .(bfsnr, year, establishments = value)]
emp <- statent_raw[Beobachtungseinheit == "Beschäftigte",
                   .(bfsnr, year, employment = value)]

panel <- merge(estab, emp, by = c("bfsnr", "year"), all = TRUE)
panel[, emp_per_estab := employment / establishments]

cat(sprintf("STATENT panel: %d rows, %d municipalities, %d years\n",
            nrow(panel), uniqueN(panel$bfsnr), uniqueN(panel$year)))

# ============================================================
# 2. Sectoral STATENT: Secondary vs Tertiary
# ============================================================
cat("--- 2. Processing sectoral STATENT ---\n")
sectors_raw <- fread("data/statent_sectors_raw.csv")
sectors_raw[, bfsnr := as.integer(str_extract(Gemeinde, "^\\d+"))]
sectors_raw[, year := as.integer(Jahr)]
sectors_raw[, sector := fcase(
  grepl("Sekundär", Wirtschaftssektor), "secondary",
  grepl("Tertiär", Wirtschaftssektor), "tertiary",
  default = "other"
)]

# Pivot by sector and unit
sec_estab <- sectors_raw[Beobachtungseinheit == "Arbeitsstätten" & sector == "secondary",
                         .(bfsnr, year, estab_sec = value)]
sec_emp <- sectors_raw[Beobachtungseinheit == "Beschäftigte" & sector == "secondary",
                       .(bfsnr, year, emp_sec = value)]
ter_estab <- sectors_raw[Beobachtungseinheit == "Arbeitsstätten" & sector == "tertiary",
                         .(bfsnr, year, estab_ter = value)]
ter_emp <- sectors_raw[Beobachtungseinheit == "Beschäftigte" & sector == "tertiary",
                       .(bfsnr, year, emp_ter = value)]

sector_panel <- Reduce(function(a, b) merge(a, b, by = c("bfsnr", "year"), all = TRUE),
                       list(sec_estab, sec_emp, ter_estab, ter_emp))
sector_panel[, emp_per_estab_sec := emp_sec / estab_sec]
sector_panel[, emp_per_estab_ter := emp_ter / estab_ter]
sector_panel[, tertiary_share := estab_ter / (estab_sec + estab_ter)]

panel <- merge(panel, sector_panel, by = c("bfsnr", "year"), all.x = TRUE)

# ============================================================
# 3. Steuerfuss: Harmonize ZH + BL
# ============================================================
cat("--- 3. Processing Steuerfuss ---\n")

# ZH: JUR_PERS is the corporate tax multiplier (percentage)
zh_stf <- fread("data/zh_steuerfuss.csv")
zh_corp <- zh_stf[, .(bfsnr = BFSNR, year = YEAR, steuerfuss = JUR_PERS)]
zh_corp <- zh_corp[!is.na(steuerfuss) & year >= 2011 & year <= 2023]
zh_corp[, canton := "ZH"]
cat(sprintf("  ZH: %d municipality-years\n", nrow(zh_corp)))

# BL: filter to corporate tax multiplier indicator
bl_stf <- fread("data/bl_steuerfuss.csv", sep = ";")
# Check column names
cat(sprintf("  BL columns: %s\n", paste(names(bl_stf), collapse = ", ")))

# BL typically has an "indikator" column — filter to corporate/juristic persons
bl_corp_indicators <- bl_stf[grepl("[Jj]urist|[Kk]örper|[Ff]irm|[Gg]ewinn|JUR", indikator, ignore.case = TRUE)]
if (nrow(bl_corp_indicators) == 0) {
  cat("  BL: No corporate indicator found. Checking unique indicators:\n")
  cat(paste("   ", head(unique(bl_stf$indikator), 20), collapse = "\n"))
  cat("\n")
  # Try using the generic Steuerfuss if no corporate-specific one
  bl_corp_indicators <- bl_stf[grepl("[Ss]teuer", indikator, ignore.case = TRUE)]
}

if (nrow(bl_corp_indicators) > 0) {
  cat(sprintf("  BL indicator used: %s\n", bl_corp_indicators[1, indikator]))
  bl_corp <- bl_corp_indicators[, .(bfsnr = bfs_nummer, year = jahr,
                                     steuerfuss = as.numeric(wert))]
  bl_corp <- bl_corp[!is.na(steuerfuss) & year >= 2011 & year <= 2023]
  bl_corp[, canton := "BL"]
  cat(sprintf("  BL: %d municipality-years\n", nrow(bl_corp)))
} else {
  bl_corp <- data.table(bfsnr = integer(), year = integer(),
                        steuerfuss = numeric(), canton = character())
  cat("  BL: No usable corporate tax data found\n")
}

# Combine Steuerfuss
steuerfuss <- rbind(zh_corp, bl_corp)

# Compute Steuerfuss changes
steuerfuss <- steuerfuss[order(bfsnr, year)]
steuerfuss[, stf_lag := shift(steuerfuss, 1), by = bfsnr]
steuerfuss[, stf_change := steuerfuss - stf_lag]
steuerfuss[, stf_cut := as.integer(!is.na(stf_change) & stf_change <= -5)]
steuerfuss[, stf_large_cut := as.integer(!is.na(stf_change) & stf_change <= -10)]

# First large cut per municipality (for event study)
first_cuts <- steuerfuss[stf_cut == 1, .(first_cut_year = min(year)), by = bfsnr]
steuerfuss <- merge(steuerfuss, first_cuts, by = "bfsnr", all.x = TRUE)
steuerfuss[, ever_cut := as.integer(!is.na(first_cut_year))]
steuerfuss[, event_time := year - first_cut_year]

cat(sprintf("  Total municipalities with Steuerfuss: %d\n", uniqueN(steuerfuss$bfsnr)))
cat(sprintf("  Municipalities with >=5pp cut: %d\n", sum(!is.na(first_cuts$first_cut_year))))

# ============================================================
# 4. Population
# ============================================================
cat("--- 4. Processing population ---\n")
pop_raw <- fread("data/population_raw.csv")

# Find the geo column (contains BFS numbers in label)
geo_col <- names(pop_raw)[grepl("Gemeinde|Kanton|Bezirk", names(pop_raw))]
if (length(geo_col) == 0) geo_col <- names(pop_raw)[2]
cat(sprintf("  Population geo column: %s\n", geo_col[1]))

pop_raw[, bfsnr := as.integer(str_extract(get(geo_col[1]), "\\d+"))]
pop_raw[, year := as.integer(Jahr)]
pop <- pop_raw[!is.na(bfsnr) & !is.na(value), .(bfsnr, year, population = value)]
pop <- pop[population > 0]

cat(sprintf("  Population: %d municipality-years\n", nrow(pop)))

# ============================================================
# 5. Merge everything
# ============================================================
cat("--- 5. Merging ---\n")

# Merge STATENT + Steuerfuss
df <- merge(panel, steuerfuss[, .(bfsnr, year, steuerfuss, stf_change, stf_cut,
                                   stf_large_cut, first_cut_year, ever_cut, event_time,
                                   canton)],
            by = c("bfsnr", "year"), all.x = TRUE)

# Merge population
df <- merge(df, pop, by = c("bfsnr", "year"), all.x = TRUE)

# Restrict to municipalities WITH Steuerfuss data (ZH + BL for now)
df <- df[!is.na(steuerfuss)]

# Log transforms
df[, log_emp_per_estab := log(emp_per_estab)]
df[, log_establishments := log(establishments)]
df[, log_employment := log(employment)]
df[, log_estab_ter := log(estab_ter)]
df[, log_emp_ter := log(emp_ter)]
df[, log_emp_per_estab_ter := log(emp_per_estab_ter)]

# Summary stats
cat(sprintf("\nFinal panel:\n"))
cat(sprintf("  Observations: %d\n", nrow(df)))
cat(sprintf("  Municipalities: %d\n", uniqueN(df$bfsnr)))
cat(sprintf("  Years: %s to %s\n", min(df$year), max(df$year)))
cat(sprintf("  Ever-cut municipalities: %d\n", sum(df[, .(ec = max(ever_cut, na.rm = TRUE)), by = bfsnr]$ec, na.rm = TRUE)))
cat(sprintf("  Mean Steuerfuss: %.1f%%\n", mean(df$steuerfuss, na.rm = TRUE)))
cat(sprintf("  Mean emp/estab: %.2f\n", mean(df$emp_per_estab, na.rm = TRUE)))
cat(sprintf("  Mean emp/estab (tertiary): %.2f\n", mean(df$emp_per_estab_ter, na.rm = TRUE)))

fwrite(df, "data/analysis_panel.csv")
cat("\nSaved: data/analysis_panel.csv\n")
