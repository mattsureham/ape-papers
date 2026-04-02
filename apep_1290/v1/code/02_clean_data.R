# 02_clean_data.R — Construct analysis panel
# APEP Working Paper apep_1290

source("00_packages.R")

# ---------------------------------------------------------------
# Load raw data
# ---------------------------------------------------------------

tax_pct <- readRDS("../data/eurostat_tax_pct_gdp.rds")
tax_lev <- readRDS("../data/eurostat_tax_mio_eur.rds")
total_rev <- readRDS("../data/eurostat_total_rev.rds")
gdp_dat <- readRDS("../data/eurostat_gdp.rds")
sector_gdp <- readRDS("../data/eurostat_sector_gdp.rds")

# ---------------------------------------------------------------
# 1. Build country-quarter panel
# ---------------------------------------------------------------

# EU member states (current + recent, excluding aggregates)
eu_geos <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
             "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
             "NL", "PL", "PT", "RO", "SE", "SI", "SK")

# Add year-quarter identifier
add_yq <- function(df) {
  df %>%
    mutate(
      year = lubridate::year(time),
      quarter = lubridate::quarter(time),
      yq = zoo::as.yearqtr(time)
    )
}

tax_pct <- tax_pct %>% filter(geo %in% eu_geos) %>% add_yq()
tax_lev <- tax_lev %>% filter(geo %in% eu_geos) %>% add_yq()
gdp_dat <- gdp_dat %>% filter(geo %in% eu_geos) %>% add_yq()
total_rev <- total_rev %>% filter(geo %in% eu_geos) %>% add_yq()

# Merge into panel
panel <- tax_pct %>%
  left_join(tax_lev, by = c("geo", "time", "year", "quarter", "yq")) %>%
  left_join(gdp_dat, by = c("geo", "time", "year", "quarter", "yq")) %>%
  left_join(total_rev, by = c("geo", "time", "year", "quarter", "yq")) %>%
  arrange(geo, time)

# Compute additional variables
panel <- panel %>%
  mutate(
    tax_share_rev = tax_mio_eur / total_rev * 100,  # Income tax as % of total revenue
    log_tax = log(tax_mio_eur + 1),
    log_gdp = log(gdp_meur + 1)
  )

cat(sprintf("Panel: %d rows, %d countries, %d quarters\n",
            nrow(panel), n_distinct(panel$geo), n_distinct(panel$yq)))

# ---------------------------------------------------------------
# 2. Define treatment and event windows
# ---------------------------------------------------------------

# Event dates (start of quarter containing the event)
event1 <- as.Date("2016-07-01")  # EC ruling Aug 30, 2016 → 2016-Q3
event2 <- as.Date("2020-07-01")  # GC annulment Jul 15, 2020 → 2020-Q3
event3 <- as.Date("2024-07-01")  # CJEU reinstatement Sep 10, 2024 → 2024-Q3

panel <- panel %>%
  mutate(
    treated = as.integer(geo == "IE"),
    post1 = as.integer(time >= event1),
    post2 = as.integer(time >= event2),
    post3 = as.integer(time >= event3),
    # Combined treatment indicators
    treated_post1 = treated * post1,
    treated_post2 = treated * post2,
    treated_post3 = treated * post3,
    # Event time relative to first event (2016-Q3)
    event_time = as.numeric(yq - zoo::as.yearqtr(event1)) * 4  # in quarters
  )

# ---------------------------------------------------------------
# 3. Check data coverage for SCM
# ---------------------------------------------------------------

# Need consistent pre-period across countries
pre_period <- panel %>% filter(time < event1)
coverage <- pre_period %>%
  group_by(geo) %>%
  summarise(
    n_quarters = sum(!is.na(tax_pct_gdp)),
    first_q = min(yq[!is.na(tax_pct_gdp)]),
    last_q = max(yq[!is.na(tax_pct_gdp)]),
    .groups = "drop"
  ) %>%
  arrange(desc(n_quarters))

cat("\n=== Pre-period coverage (before 2016-Q3) ===\n")
print(coverage, n = 30)

# Keep countries with at least 40 quarters of pre-period data (10 years)
good_geos <- coverage %>% filter(n_quarters >= 40) %>% pull(geo)
cat(sprintf("\nCountries with 40+ pre-period quarters: %d\n", length(good_geos)))
cat("  ", paste(good_geos, collapse = ", "), "\n")

# Filter panel to good-coverage countries
panel_clean <- panel %>% filter(geo %in% good_geos)

# ---------------------------------------------------------------
# 4. Construct SCM-compatible dataset
# ---------------------------------------------------------------

# Common time window: max of first available across countries, to 2025-Q3
common_start <- max(coverage$first_q[coverage$geo %in% good_geos])
common_end <- zoo::as.yearqtr("2025 Q3")

panel_scm <- panel_clean %>%
  filter(yq >= common_start, yq <= common_end) %>%
  filter(!is.na(tax_pct_gdp))

# Numeric IDs for Synth package
geo_ids <- data.frame(
  geo = sort(unique(panel_scm$geo)),
  geo_id = seq_along(sort(unique(panel_scm$geo)))
)
panel_scm <- panel_scm %>% left_join(geo_ids, by = "geo")

# Numeric time index
time_ids <- data.frame(
  yq = sort(unique(panel_scm$yq)),
  time_id = seq_along(sort(unique(panel_scm$yq)))
)
panel_scm <- panel_scm %>% left_join(time_ids, by = "yq")

# Treatment period starts at event1
treat_start <- time_ids$time_id[time_ids$yq == zoo::as.yearqtr(event1)]
ireland_id <- geo_ids$geo_id[geo_ids$geo == "IE"]

cat(sprintf("\nSCM panel: %d rows, %d countries, %d quarters\n",
            nrow(panel_scm), n_distinct(panel_scm$geo), n_distinct(panel_scm$yq)))
cat(sprintf("  Common window: %s to %s\n", common_start, common_end))
cat(sprintf("  Treatment starts: period %d (= %s)\n", treat_start, "2016 Q3"))
cat(sprintf("  Ireland ID: %d\n", ireland_id))

# ---------------------------------------------------------------
# 5. Ireland sector panel (for mechanism test)
# ---------------------------------------------------------------

sector_panel <- sector_gdp %>%
  add_yq() %>%
  filter(nace_r2 %in% c("J", "C", "K", "G-I", "M_N")) %>%
  mutate(
    post1 = as.integer(time >= event1),
    sector_label = case_when(
      nace_r2 == "J" ~ "Info & Comms (Apple)",
      nace_r2 == "C" ~ "Manufacturing",
      nace_r2 == "K" ~ "Finance & Insurance",
      nace_r2 == "G-I" ~ "Trade, Transport, Hospitality",
      nace_r2 == "M_N" ~ "Professional & Admin",
      TRUE ~ nace_r2
    )
  )

cat(sprintf("\nSector panel (IE): %d rows, %d sectors\n",
            nrow(sector_panel), n_distinct(sector_panel$nace_r2)))

# ---------------------------------------------------------------
# Save
# ---------------------------------------------------------------

saveRDS(panel_scm, "../data/panel_scm.rds")
saveRDS(panel_clean, "../data/panel_clean.rds")
saveRDS(sector_panel, "../data/sector_panel.rds")
saveRDS(geo_ids, "../data/geo_ids.rds")
saveRDS(time_ids, "../data/time_ids.rds")

# Save key parameters
params <- list(
  event1 = event1, event2 = event2, event3 = event3,
  treat_start = treat_start, ireland_id = ireland_id,
  common_start = as.character(common_start),
  common_end = as.character(common_end),
  good_geos = good_geos
)
saveRDS(params, "../data/params.rds")

cat("\n=== Panel construction complete ===\n")
