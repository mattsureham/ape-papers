# 02_clean_data.R — Construct analysis panel
source("code/00_packages.R")

# ==============================================================================
# 1. Zurich Steuerfuss Panel
# ==============================================================================
cat("=== Building Zurich Steuerfuss panel ===\n")
zh_stf <- fread("data/zh_steuerfuss_timeseries.csv", encoding = "UTF-8")

# Key columns: YEAR, BFSNR, STF_O_KIRCHE1 (personal), JUR_PERS (corporate)
zh_tax <- zh_stf[, .(
  year = YEAR,
  bfs_nr = BFSNR,
  muni_name = GDE_NAME,
  personal_rate = STF_O_KIRCHE1,
  corporate_rate = JUR_PERS
)]

# Drop 2025-2026 (might be provisional)
zh_tax <- zh_tax[year <= 2024]

# Compute wedge
zh_tax[, wedge := corporate_rate - personal_rate]
zh_tax[, canton := "ZH"]

cat("  ZH tax panel:", nrow(zh_tax), "rows,", uniqueN(zh_tax$bfs_nr), "municipalities\n")
cat("  Years:", paste(range(zh_tax$year), collapse = "-"), "\n")
cat("  Personal rate range:", paste(range(zh_tax$personal_rate, na.rm = TRUE), collapse = "-"), "\n")
cat("  Corporate rate range:", paste(range(zh_tax$corporate_rate, na.rm = TRUE), collapse = "-"), "\n")
cat("  Wedge range:", paste(range(zh_tax$wedge, na.rm = TRUE), collapse = "-"), "\n")

# Year-over-year changes
setorder(zh_tax, bfs_nr, year)
zh_tax[, `:=`(
  d_personal = personal_rate - shift(personal_rate),
  d_corporate = corporate_rate - shift(corporate_rate),
  d_wedge = wedge - shift(wedge)
), by = bfs_nr]

# Flag wedge changes
zh_tax[, wedge_changed := !is.na(d_wedge) & d_wedge != 0]
cat("  Municipality-years with wedge change:", sum(zh_tax$wedge_changed, na.rm = TRUE),
    "out of", sum(!is.na(zh_tax$d_wedge)), "(", round(100 * mean(zh_tax$wedge_changed, na.rm = TRUE), 1), "%)\n")

# ==============================================================================
# 2. Basel-Landschaft Steuerfuss Panel
# ==============================================================================
cat("\n=== Building BL Steuerfuss panel ===\n")
bl_stf <- fread("data/bl_steuerfuss.csv", sep = ";", encoding = "UTF-8")

# Pivot to wide: need personal rate and corporate profit rate per municipality-year
bl_wide <- dcast(bl_stf, jahr + bfs_nummer + gemeinde ~ indikator, value.var = "wert")
setnames(bl_wide, c("jahr", "bfs_nummer", "gemeinde"), c("year", "bfs_nr", "muni_name"))

# Identify personal and corporate rate columns
personal_col <- grep("natürliche.*Personen.*Prozent", names(bl_wide), value = TRUE)
corp_profit_col <- grep("Steuerfuss.*Ertrag.*juristische.*Prozent", names(bl_wide), value = TRUE)

if (length(personal_col) > 0 && length(corp_profit_col) > 0) {
  bl_tax <- bl_wide[, .(
    year, bfs_nr, muni_name,
    personal_rate = get(personal_col[1]),
    corporate_rate = get(corp_profit_col[1])
  )]
} else {
  stop("Could not find personal/corporate rate columns in BL data")
}

bl_tax <- bl_tax[year >= 2012 & year <= 2024]  # Match ZH period
bl_tax[, wedge := corporate_rate - personal_rate]
bl_tax[, canton := "BL"]

setorder(bl_tax, bfs_nr, year)
bl_tax[, `:=`(
  d_personal = personal_rate - shift(personal_rate),
  d_corporate = corporate_rate - shift(corporate_rate),
  d_wedge = wedge - shift(wedge)
), by = bfs_nr]
bl_tax[, wedge_changed := !is.na(d_wedge) & d_wedge != 0]

cat("  BL tax panel:", nrow(bl_tax), "rows,", uniqueN(bl_tax$bfs_nr), "municipalities\n")
cat("  Wedge changes:", sum(bl_tax$wedge_changed, na.rm = TRUE),
    "(", round(100 * mean(bl_tax$wedge_changed, na.rm = TRUE), 1), "%)\n")

# ==============================================================================
# 3. Combined tax panel
# ==============================================================================
tax_panel <- rbind(zh_tax, bl_tax, fill = TRUE)
cat("\n=== Combined tax panel:", nrow(tax_panel), "rows,",
    uniqueN(tax_panel$bfs_nr), "municipalities ===\n")

# ==============================================================================
# 4. ZH Establishments and Employment (outcomes)
# ==============================================================================
cat("\n=== Loading ZH establishment/employment data ===\n")

# Total establishments (filter out BFS_NR=0 which are district/cantonal aggregates)
zh_est <- fread("data/zh_total_establishments.csv", encoding = "UTF-8")
zh_est <- zh_est[BFS_NR > 0, .(bfs_nr = BFS_NR, year = INDIKATOR_JAHR, establishments = INDIKATOR_VALUE)]

# Total employment
zh_emp <- fread("data/zh_total_employment.csv", encoding = "UTF-8")
zh_emp <- zh_emp[BFS_NR > 0, .(bfs_nr = BFS_NR, year = INDIKATOR_JAHR, employment = INDIKATOR_VALUE)]

# Firm size decomposition
zh_micro <- fread("data/zh_micro_firms.csv", encoding = "UTF-8")[BFS_NR > 0, .(bfs_nr = BFS_NR, year = INDIKATOR_JAHR, micro_firms = INDIKATOR_VALUE)]
zh_small <- fread("data/zh_small_firms.csv", encoding = "UTF-8")[BFS_NR > 0, .(bfs_nr = BFS_NR, year = INDIKATOR_JAHR, small_firms = INDIKATOR_VALUE)]

# New firm registrations
zh_new <- fread("data/zh_new_firms.csv", encoding = "UTF-8")[BFS_NR > 0, .(bfs_nr = BFS_NR, year = INDIKATOR_JAHR, new_firms = INDIKATOR_VALUE)]

# Merge enterprise data
zh_firms <- merge(zh_est, zh_emp, by = c("bfs_nr", "year"), all = TRUE)
zh_firms <- merge(zh_firms, zh_micro, by = c("bfs_nr", "year"), all = TRUE)
zh_firms <- merge(zh_firms, zh_small, by = c("bfs_nr", "year"), all = TRUE)
zh_firms <- merge(zh_firms, zh_new, by = c("bfs_nr", "year"), all = TRUE)
cat("  ZH firms panel:", nrow(zh_firms), "rows,", uniqueN(zh_firms$bfs_nr), "munis\n")

# ==============================================================================
# 5. Population data
# ==============================================================================
cat("\n=== Loading population data ===\n")

# ZH population (from ZH statistical office — 1962-2025)
zh_pop <- fread("data/zh_population.csv", encoding = "UTF-8")
zh_pop <- zh_pop[, .(bfs_nr = BFS_NR, year = INDIKATOR_JAHR, population = INDIKATOR_VALUE)]
zh_pop <- zh_pop[year >= 2010 & year <= 2024]

# BL population (from data.bl.ch — endbestand column)
bl_pop <- fread("data/bl_population.csv", sep = ";", encoding = "UTF-8")
# Use gemeinde_nummer as bfs_nr, endbestand as population
# Handle column name variations
nr_col <- grep("gemeinde.*nummer|gemeindenummer", names(bl_pop), value = TRUE, ignore.case = TRUE)
pop_col <- grep("endbestand", names(bl_pop), value = TRUE, ignore.case = TRUE)
if (length(nr_col) > 0 && length(pop_col) > 0) {
  bl_pop_clean <- bl_pop[, .(bfs_nr = get(nr_col[1]), year = jahr, population = get(pop_col[1]))]
  bl_pop_clean <- bl_pop_clean[year >= 2010 & year <= 2024]
} else {
  bl_pop_clean <- data.table(bfs_nr = integer(), year = integer(), population = numeric())
}

all_pop <- rbind(zh_pop, bl_pop_clean)
cat("  Population panel:", nrow(all_pop), "rows\n")

# ==============================================================================
# 6. Steuerkraft (ZH only)
# ==============================================================================
cat("\n=== Loading Steuerkraft ===\n")
zh_sk <- fread("data/zh_steuerkraft.csv", encoding = "UTF-8")
zh_sk <- zh_sk[BFS_NR > 0, .(bfs_nr = BFS_NR, year = INDIKATOR_JAHR, steuerkraft_mio = as.numeric(INDIKATOR_VALUE))]
zh_sk <- zh_sk[year >= 2010 & year <= 2024]
cat("  Steuerkraft panel:", nrow(zh_sk), "rows\n")

# ==============================================================================
# 7. Master panel merge
# ==============================================================================
cat("\n=== Building master panel ===\n")

# Start with tax panel (core)
panel <- copy(tax_panel)

# Merge outcomes
panel <- merge(panel, zh_firms, by = c("bfs_nr", "year"), all.x = TRUE)
panel <- merge(panel, all_pop, by = c("bfs_nr", "year"), all.x = TRUE)
panel <- merge(panel, zh_sk, by = c("bfs_nr", "year"), all.x = TRUE)

# Compute log outcomes (for elasticity interpretation)
panel[, `:=`(
  log_est = log(establishments + 1),
  log_emp = log(employment + 1),
  log_pop = log(population + 1),
  log_sk = log(steuerkraft_mio + 0.001)
)]

# Compute growth rates
setorder(panel, bfs_nr, year)
panel[, `:=`(
  est_growth = (establishments - shift(establishments)) / shift(establishments),
  emp_growth = (employment - shift(employment)) / shift(employment),
  pop_growth = (population - shift(population)) / shift(population)
), by = bfs_nr]

# Drop municipalities with too few observations
obs_per_muni <- panel[!is.na(personal_rate) & !is.na(corporate_rate), .N, by = bfs_nr]
panel <- panel[bfs_nr %in% obs_per_muni[N >= 5]$bfs_nr]

cat("  Master panel:", nrow(panel), "rows,", uniqueN(panel$bfs_nr), "municipalities\n")
cat("  With establishments:", sum(!is.na(panel$establishments)), "\n")
cat("  With population:", sum(!is.na(panel$population)), "\n")
cat("  With Steuerkraft:", sum(!is.na(panel$steuerkraft_mio)), "\n")
cat("  Canton breakdown: ZH =", uniqueN(panel[canton == "ZH"]$bfs_nr),
    "| BL =", uniqueN(panel[canton == "BL"]$bfs_nr), "\n")

# ==============================================================================
# 8. Summary statistics for the wedge
# ==============================================================================
cat("\n=== Wedge Summary Statistics ===\n")
cat("Overall:\n")
print(panel[!is.na(wedge), .(
  mean_wedge = mean(wedge),
  sd_wedge = sd(wedge),
  min_wedge = min(wedge),
  max_wedge = max(wedge),
  mean_personal = mean(personal_rate),
  mean_corporate = mean(corporate_rate),
  n_wedge_changes = sum(wedge_changed, na.rm = TRUE),
  pct_wedge_change = round(100 * mean(wedge_changed, na.rm = TRUE), 1)
)])

cat("\nBy canton:\n")
print(panel[!is.na(wedge), .(
  mean_wedge = round(mean(wedge), 1),
  sd_wedge = round(sd(wedge), 1),
  n_changes = sum(wedge_changed, na.rm = TRUE),
  pct_change = round(100 * mean(wedge_changed, na.rm = TRUE), 1),
  n_munis = uniqueN(bfs_nr)
), by = canton])

# ==============================================================================
# 9. Save
# ==============================================================================
saveRDS(panel, "data/analysis_panel.rds")
cat("\n=== Panel saved to data/analysis_panel.rds ===\n")
