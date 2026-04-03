# 02_clean_data.R — Construct analysis panel
# apep_1343: Private Governance and Bangladesh Apparel Exports After Rana Plaza

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. LOAD AND CLEAN COMTRADE DATA
# ============================================================================
cat("=== Loading Comtrade data ===\n")
ct <- fread(file.path(data_dir, "comtrade_bgd_bilateral.csv"))
cat("Raw rows:", nrow(ct), "\n")

# Remove World aggregate (partnerCode == 0) to avoid double-counting
ct <- ct[partnerCode != 0]
cat("After removing World aggregate:", nrow(ct), "\n")

# ============================================================================
# 2. CLASSIFY DESTINATION COUNTRIES BY ACCORD/ALLIANCE REGIME
# ============================================================================
# UN M49 country codes -> Accord/Alliance classification
# Accord: European countries whose major brands signed the Bangladesh Accord
# (H&M, Inditex, PVH, Primark, C&A, Benetton, Marks & Spencer, etc.)
# Alliance: US and Canada (Walmart, Gap, Target, Kohl's, etc.)
# Control: All other destinations

# Major EU/UK partner codes (M49)
accord_codes <- c(
  40,   # Austria
  56,   # Belgium
  100,  # Bulgaria
  191,  # Croatia
  203,  # Czechia
  208,  # Denmark
  233,  # Estonia
  246,  # Finland
  250,  # France
  276,  # Germany
  300,  # Greece
  348,  # Hungary
  372,  # Ireland
  380,  # Italy
  428,  # Latvia
  440,  # Lithuania
  442,  # Luxembourg
  470,  # Malta
  528,  # Netherlands
  616,  # Poland
  620,  # Portugal
  642,  # Romania
  703,  # Slovakia
  705,  # Slovenia
  724,  # Spain
  752,  # Sweden
  826   # United Kingdom
)

# US + Canada
alliance_codes <- c(
  840,  # United States
  124   # Canada
)

ct[, regime_dest := fifelse(
  partnerCode %in% accord_codes, "Accord",
  fifelse(partnerCode %in% alliance_codes, "Alliance", "Control")
)]

cat("\nDestination classification:\n")
print(ct[, .(n_partners = uniqueN(partnerCode),
             total_value = round(sum(primaryValue, na.rm = TRUE) / 1e9, 2)),
          by = regime_dest])

# ============================================================================
# 3. CLASSIFY PRODUCTS
# ============================================================================
# Treatment products: HS 61 (knitted apparel), HS 62 (woven apparel)
# Control products: HS 03 (fish), HS 52 (cotton), HS 64 (footwear)
ct[, product_type := fifelse(cmdCode %in% c(61, 62), "apparel", "non_apparel")]

cat("\nProduct classification:\n")
print(ct[, .(n_obs = .N,
             total_value_bn = round(sum(primaryValue, na.rm = TRUE) / 1e9, 2)),
          by = product_type])

# ============================================================================
# 4. BUILD ANALYSIS PANEL: regime_dest × product_type × year
# ============================================================================
cat("\n=== Building analysis panel ===\n")

# Aggregate to regime × product × year level
panel <- ct[, .(
  export_value = sum(primaryValue, na.rm = TRUE),
  n_partners = uniqueN(partnerCode),
  n_flows = .N
), by = .(year = period, regime_dest, product_type)]

# Create treatment variables
panel[, `:=`(
  post = as.integer(year >= 2014),  # Rana Plaza: April 2013; Accord inspections start 2014
  log_exports = log(export_value + 1),
  is_apparel = as.integer(product_type == "apparel"),
  is_accord = as.integer(regime_dest == "Accord"),
  is_alliance = as.integer(regime_dest == "Alliance"),
  # Year centered on Rana Plaza
  year_centered = year - 2013
)]

# Create interaction terms for DDD
panel[, `:=`(
  accord_post = is_accord * post,
  alliance_post = is_alliance * post,
  apparel_post = is_apparel * post,
  accord_apparel = is_accord * is_apparel,
  alliance_apparel = is_alliance * is_apparel,
  # Triple interactions
  accord_apparel_post = is_accord * is_apparel * post,
  alliance_apparel_post = is_alliance * is_apparel * post
)]

setorder(panel, year, regime_dest, product_type)
cat("Panel dimensions:", nrow(panel), "rows\n")
cat("Cells per year:", uniqueN(panel[, .(regime_dest, product_type)]), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")

# ============================================================================
# 5. MERGE WORLD BANK MACRO CONTROLS
# ============================================================================
wb <- fread(file.path(data_dir, "wb_bangladesh.csv"))
# Rename columns for clarity
if ("NE.EXP.GNFS.CD" %in% names(wb)) {
  setnames(wb, "NE.EXP.GNFS.CD", "total_exports_usd", skip_absent = TRUE)
}

panel <- merge(panel, wb, by = "year", all.x = TRUE)

# ============================================================================
# 6. COMPUTE EXPORT SHARES AND GROWTH RATES
# ============================================================================
# Export share of each regime-product within total regime exports
panel[, export_share := export_value / sum(export_value), by = .(year, regime_dest)]

# Year-over-year growth rate within regime-product
setorder(panel, regime_dest, product_type, year)
panel[, export_growth := (export_value / shift(export_value, 1)) - 1,
      by = .(regime_dest, product_type)]

# Index (2012 = 100)
panel[, base_value := export_value[year == 2012], by = .(regime_dest, product_type)]
panel[, export_index := 100 * export_value / base_value]

# ============================================================================
# 7. ALSO BUILD PARTNER-LEVEL PANEL (for richer variation)
# ============================================================================
cat("\n=== Building partner-level panel ===\n")

partner_panel <- ct[, .(
  export_value = sum(primaryValue, na.rm = TRUE)
), by = .(year = period, partnerCode, regime_dest, product_type)]

partner_panel[, `:=`(
  post = as.integer(year >= 2014),
  log_exports = log(export_value + 1),
  is_apparel = as.integer(product_type == "apparel"),
  is_accord = as.integer(regime_dest == "Accord"),
  is_alliance = as.integer(regime_dest == "Alliance")
)]

# Triple interaction
partner_panel[, `:=`(
  accord_apparel_post = is_accord * is_apparel * post,
  alliance_apparel_post = is_alliance * is_apparel * post
)]

cat("Partner panel:", nrow(partner_panel), "rows,",
    uniqueN(partner_panel$partnerCode), "partners\n")

# Drop partners with very sparse data (< 3 years observed)
partner_year_count <- partner_panel[, .(n_years = uniqueN(year)), by = partnerCode]
sparse_partners <- partner_year_count[n_years < 3]$partnerCode
partner_panel <- partner_panel[!partnerCode %in% sparse_partners]
cat("After dropping sparse partners:", nrow(partner_panel), "rows,",
    uniqueN(partner_panel$partnerCode), "partners\n")

# ============================================================================
# 8. SAVE
# ============================================================================
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
fwrite(partner_panel, file.path(data_dir, "partner_panel.csv"))

cat("\n=== Panel summary ===\n")
cat("Regime-product panel:", nrow(panel), "obs\n")
cat("Partner panel:", nrow(partner_panel), "obs\n")

# Quick sanity check: apparel exports by regime
cat("\nApparel exports by regime and period (USD millions):\n")
summary_tab <- panel[product_type == "apparel",
                     .(avg_exports_mn = round(mean(export_value) / 1e6, 0)),
                     by = .(regime_dest, period = fifelse(post == 1, "Post", "Pre"))]
print(dcast(summary_tab, regime_dest ~ period, value.var = "avg_exports_mn"))

cat("\n=== Data preparation complete ===\n")
