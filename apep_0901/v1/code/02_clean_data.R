## 02_clean_data.R — Construct municipality-year panel

source("00_packages.R")

data_dir <- "../data"

# ── 1. Load raw data ────────────────────────────────────────────────────────
stf <- fread(file.path(data_dir, "steuerfuss_timeseries.csv"))
jr  <- fread(file.path(data_dir, "jahresrechnungen_fixed.csv"))
pop <- fread(file.path(data_dir, "population_zh.csv"))
statent <- fread(file.path(data_dir, "statent_zh.csv"))

# ── 2. Clean Steuerfuss ─────────────────────────────────────────────────────
stf_clean <- stf[, .(
  bfsnr     = BFSNR,
  year      = YEAR,
  gde_name  = GDE_NAME,
  stf_nat   = as.numeric(STF_O_KIRCHE1),  # Natural person multiplier (excl. church)
  stf_corp  = as.numeric(JUR_PERS)         # Corporate multiplier
)]
# Drop rows with missing corporate rate
stf_clean <- stf_clean[!is.na(stf_corp) & !is.na(stf_nat)]
cat(sprintf("Steuerfuss panel: %d obs, %d municipalities, %d-%d\n",
            nrow(stf_clean), uniqueN(stf_clean$bfsnr),
            min(stf_clean$year), max(stf_clean$year)))

# ── 3. Clean Jahresrechnungen ───────────────────────────────────────────────
# Build crosswalk from Jahresrechnungen entity names to BFS numbers
# Entity names are like "Politische Gemeinde Adliswil"
jr_names <- unique(jr$KOERPERSCHAFT_NAME)
stf_names <- unique(stf_clean[, .(bfsnr, gde_name)])

# Clean entity names: remove "Politische Gemeinde " prefix
jr[, gde_clean := gsub("^Politische Gemeinde\\s+", "", KOERPERSCHAFT_NAME)]

# Merge with steuerfuss names to get BFS number
name_xwalk <- merge(
  unique(jr[, .(gde_clean)]),
  stf_names[, .(bfsnr, gde_name)],
  by.x = "gde_clean", by.y = "gde_name",
  all.x = TRUE
)

# Check match rate
matched <- sum(!is.na(name_xwalk$bfsnr))
cat(sprintf("Name crosswalk: %d/%d matched (%0.1f%%)\n",
            matched, nrow(name_xwalk), 100 * matched / nrow(name_xwalk)))

# Deduplicate crosswalk (keep first match per name)
name_xwalk <- name_xwalk[!is.na(bfsnr)]
name_xwalk <- name_xwalk[!duplicated(gde_clean)]

# Apply crosswalk
jr <- merge(jr, name_xwalk, by = "gde_clean", all.x = TRUE)
jr <- jr[!is.na(bfsnr)]  # Keep only matched municipalities

# Ensure JAHR is integer
jr[, JAHR := as.integer(JAHR)]
jr <- jr[!is.na(JAHR)]

# Focus on Erfolgsrechnung (income statement) for spending
jr_er <- jr[SET_NAME == "Erfolgsrechnung"]

# Extract key spending categories from indicator names
# Key functional categories (by indicator ID patterns):
# We need to identify spending on: education, social welfare, infrastructure, total
key_indicators <- jr_er[, .(
  indikator_id   = INDIKATOR_ID,
  indikator_name = INDIKATOR_NAME,
  n_obs          = .N
), by = .(INDIKATOR_ID, INDIKATOR_NAME)][order(INDIKATOR_ID)]

# Identify spending indicators by searching names
# "Aufwand" = expenditure, "Ertrag" = revenue
# Look for functional categories
cat("\nSearching for key spending indicators...\n")
spending_patterns <- c(
  "total_exp"    = "^\\[1\\d{2}\\].*30.*Personalaufwand|^\\[100\\]",
  "education"    = "[Bb]ildung|[Ss]chule|[Ee]ducation",
  "social"       = "[Ss]ozial|[Ff]ürsorge|[Ss]ozialhilfe",
  "infrastructure" = "[Vv]erkehr|[Ss]trassen|[Oo]ffentlicher Verkehr|[Uu]mwelt",
  "tax_revenue"  = "[Ss]teuer.*\\[Fr\\.\\]|[Gg]emeindesteuern",
  "total_revenue"= "^\\[1[12]\\d\\].*Ertrag|Gesamtertrag"
)

# Print available indicators for inspection
cat("\nSample indicators:\n")
print(head(key_indicators[order(-n_obs)], 30))

# Select relevant indicators based on INDIKATOR_ID
# From the smoke test, key IDs include:
# Total expenditure, tax revenue, functional spending categories
# We'll use a broad approach: pivot on INDIKATOR_ID for major categories
# Focus on level-2 functional headings

# Extract spending by functional category
# Typical HRM2 structure: INDIKATOR_ID encodes the account hierarchy
# Let's extract the functional spending indicators
jr_spending <- jr_er[, .(
  bfsnr = bfsnr,
  year  = JAHR,
  indikator_id   = INDIKATOR_ID,
  indikator_name = INDIKATOR_NAME,
  value = as.numeric(VALUE)
)]

# Save all indicators for flexible analysis
fwrite(jr_spending, file.path(data_dir, "spending_panel.csv"))

# ── 4. Construct main panel ─────────────────────────────────────────────────
# Merge steuerfuss + population
panel <- merge(stf_clean, pop, by = c("bfsnr", "year"), all.x = TRUE)

# Merge STATENT
panel <- merge(panel, statent, by = c("bfsnr", "year"), all.x = TRUE)

# Compute within-municipality Steuerfuss changes
setorder(panel, bfsnr, year)
panel[, `:=`(
  stf_corp_lag  = shift(stf_corp, 1),
  stf_nat_lag   = shift(stf_nat, 1),
  stf_corp_chg  = stf_corp - shift(stf_corp, 1),
  pop_growth    = (population - shift(population, 1)) / shift(population, 1)
), by = bfsnr]

# Flag large cuts (≥5pp)
panel[, large_cut := as.integer(!is.na(stf_corp_chg) & stf_corp_chg <= -5)]

# Compute log transformations for establishments
panel[, log_estab := log(establishments + 1)]
panel[, log_emp   := log(employees + 1)]

cat(sprintf("\nMain panel: %d obs, %d municipalities, %d-%d\n",
            nrow(panel), uniqueN(panel$bfsnr),
            min(panel$year), max(panel$year)))

# ── 5. Summary statistics ───────────────────────────────────────────────────
cat("\n=== STEUERFUSS VARIATION ===\n")
cat(sprintf("Corporate rate: mean=%.1f, sd=%.1f, min=%.0f, max=%.0f\n",
            mean(panel$stf_corp, na.rm = TRUE),
            sd(panel$stf_corp, na.rm = TRUE),
            min(panel$stf_corp, na.rm = TRUE),
            max(panel$stf_corp, na.rm = TRUE)))

chg <- panel[!is.na(stf_corp_chg) & stf_corp_chg != 0]
cat(sprintf("Non-zero changes: %d obs (%.1f%% of panel)\n",
            nrow(chg), 100 * nrow(chg) / nrow(panel[!is.na(stf_corp_chg)])))
cat(sprintf("  Mean change: %.2f pp, sd=%.2f\n",
            mean(chg$stf_corp_chg), sd(chg$stf_corp_chg)))
cat(sprintf("  Cuts: %d, Increases: %d\n",
            sum(chg$stf_corp_chg < 0), sum(chg$stf_corp_chg > 0)))
cat(sprintf("  Large cuts (≥5pp): %d\n", sum(panel$large_cut == 1, na.rm = TRUE)))

# Save panel
fwrite(panel, file.path(data_dir, "panel.csv"))
cat("\nPanel saved to data/panel.csv\n")
