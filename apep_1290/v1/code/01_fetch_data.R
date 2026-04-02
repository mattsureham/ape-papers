# 01_fetch_data.R — Fetch Eurostat quarterly data
# APEP Working Paper apep_1290

source("00_packages.R")

# ---------------------------------------------------------------
# 1. Eurostat: Quarterly government revenue (GOV_10Q_GGNFA)
# ---------------------------------------------------------------

cat("=== Fetching Eurostat quarterly government revenue (bulk) ===\n")

gov_rev_raw <- eurostat::get_eurostat("gov_10q_ggnfa", time_format = "date")
stopifnot("Eurostat revenue data is empty" = nrow(gov_rev_raw) > 0)
cat(sprintf("  Raw revenue data: %d rows\n", nrow(gov_rev_raw)))

# D51REC = Taxes on income (revenue), S13 = General government
# Get both PC_GDP and MIO_EUR
gov_pctgdp <- gov_rev_raw %>%
  filter(na_item == "D51REC", sector == "S13", unit == "PC_GDP", s_adj == "NSA") %>%
  rename(time = TIME_PERIOD, tax_pct_gdp = values) %>%
  select(geo, time, tax_pct_gdp)

gov_levels <- gov_rev_raw %>%
  filter(na_item == "D51REC", sector == "S13", unit == "MIO_EUR", s_adj == "NSA") %>%
  rename(time = TIME_PERIOD, tax_mio_eur = values) %>%
  select(geo, time, tax_mio_eur)

# Also total revenue (TR) for share computation
gov_total <- gov_rev_raw %>%
  filter(na_item == "TR", sector == "S13", unit == "MIO_EUR", s_adj == "NSA") %>%
  rename(time = TIME_PERIOD, total_rev = values) %>%
  select(geo, time, total_rev)

cat(sprintf("  D51REC/PC_GDP: %d rows, %d countries\n",
            nrow(gov_pctgdp), n_distinct(gov_pctgdp$geo)))

# Ireland diagnostics
ie <- gov_pctgdp %>% filter(geo == "IE") %>% arrange(time)
cat(sprintf("  Ireland: %d quarters (%s to %s)\n",
            nrow(ie), min(ie$time), max(ie$time)))
cat(sprintf("  IE tax/GDP range: %.1f%% to %.1f%%\n",
            min(ie$tax_pct_gdp, na.rm=T), max(ie$tax_pct_gdp, na.rm=T)))

ie_lev <- gov_levels %>% filter(geo == "IE") %>% arrange(time)
cat(sprintf("  IE tax levels (EUR mn): min=%.0f, max=%.0f\n",
            min(ie_lev$tax_mio_eur, na.rm=T), max(ie_lev$tax_mio_eur, na.rm=T)))

# ---------------------------------------------------------------
# 2. Eurostat: Quarterly GDP (NAMQ_10_GDP)
# ---------------------------------------------------------------

cat("\n=== Fetching Eurostat quarterly GDP (bulk) ===\n")

gdp_raw <- eurostat::get_eurostat("namq_10_gdp", time_format = "date")
stopifnot("GDP data is empty" = nrow(gdp_raw) > 0)

gdp <- gdp_raw %>%
  filter(na_item == "B1GQ", unit == "CP_MEUR", s_adj == "NSA") %>%
  rename(time = TIME_PERIOD, gdp_meur = values) %>%
  select(geo, time, gdp_meur)

cat(sprintf("  GDP: %d rows, %d countries\n", nrow(gdp), n_distinct(gdp$geo)))

# ---------------------------------------------------------------
# 3. Eurostat: GDP by NACE sector for Ireland (NAMQ_10_A10)
# ---------------------------------------------------------------

cat("\n=== Fetching Eurostat sector GDP ===\n")

sector_raw <- eurostat::get_eurostat("namq_10_a10", time_format = "date")
stopifnot("Sector data is empty" = nrow(sector_raw) > 0)

sector_gdp <- sector_raw %>%
  filter(geo == "IE", na_item == "B1G", unit == "CP_MEUR", s_adj == "NSA") %>%
  rename(time = TIME_PERIOD) %>%
  select(geo, nace_r2, time, values)

cat(sprintf("  Ireland sectors: %d rows, %d sectors\n",
            nrow(sector_gdp), n_distinct(sector_gdp$nace_r2)))
cat("  Sectors:", paste(sort(unique(sector_gdp$nace_r2)), collapse=", "), "\n")

# ---------------------------------------------------------------
# 4. Eurostat: Trade openness & FDI for SCM predictors
#    Use NAMA_10_GDP annual for trade/GDP
# ---------------------------------------------------------------

cat("\n=== Fetching trade openness data (optional) ===\n")

exports <- tryCatch({
  bop_raw <- eurostat::get_eurostat("bop_its6_q", time_format = "date")
  bop_raw %>%
    filter(bop_item == "GS", stk_flow == "CR", partner == "WRL_REST",
           sectpart == "S1", currency == "MIO_EUR", s_adj == "NSA") %>%
    rename(time = TIME_PERIOD, exports = values) %>%
    select(geo, time, exports)
}, error = function(e) {
  cat("  BOP dataset unavailable:", conditionMessage(e), "\n")
  cat("  Will use GDP growth as predictor instead.\n")
  data.frame(geo = character(), time = as.Date(character()), exports = numeric())
})
cat(sprintf("  Exports: %d rows\n", nrow(exports)))

# ---------------------------------------------------------------
# Save
# ---------------------------------------------------------------

saveRDS(gov_pctgdp, "../data/eurostat_tax_pct_gdp.rds")
saveRDS(gov_levels, "../data/eurostat_tax_mio_eur.rds")
saveRDS(gov_total, "../data/eurostat_total_rev.rds")
saveRDS(gdp, "../data/eurostat_gdp.rds")
saveRDS(sector_gdp, "../data/eurostat_sector_gdp.rds")
saveRDS(exports, "../data/eurostat_exports.rds")

cat("\n=== All data fetched and saved ===\n")
