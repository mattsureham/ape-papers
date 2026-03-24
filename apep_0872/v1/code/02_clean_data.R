## 02_clean_data.R — Clean and construct analysis panel
## apep_0872: Hungary bank levy and credit supply

source("00_packages.R")

# ============================================================
# 1. ECB BSI data — select the right aggregate series
# ============================================================
bsi <- readRDS("../data/bsi_nfc_loans.rds")

cat("Raw BSI data structure:\n")
cat(sprintf("  Rows: %d\n", nrow(bsi)))
cat(sprintf("  Countries: %s\n", paste(unique(bsi$country), collapse = ", ")))
cat(sprintf("  Date range: %s to %s\n", min(bsi$date), max(bsi$date)))

# The broad query returns multiple BSI item types. We need to identify
# the total outstanding NFC loans series for each country.
# Check which series identifiers are in the data
if ("BS_ITEM" %in% names(bsi)) {
  cat("\nBS_ITEM values:\n")
  print(table(bsi$BS_ITEM))
} else if ("KEY" %in% names(bsi)) {
  # Parse the KEY field to identify the series
  cat("\nParsing KEY field to identify series...\n")
  # Extract BS_ITEM from the ECB key (position 5 in dot-separated)
  bsi$bs_item <- sapply(strsplit(bsi$KEY, "\\."), function(x) if (length(x) >= 5) x[5] else NA)
  bsi$maturity <- sapply(strsplit(bsi$KEY, "\\."), function(x) if (length(x) >= 9) x[9] else NA)
  cat("BS_ITEM values:\n")
  print(table(bsi$bs_item))
  cat("\nMaturity values:\n")
  print(table(bsi$maturity))
}

# We want A20 (total loans) or A2A (loans), with 0000 (all maturities)
# Filter to the broadest aggregate
if ("bs_item" %in% names(bsi)) {
  # Prefer A20 (total loans outstanding)
  target_items <- c("A20", "A2A", "A2B", "A2C", "A2Z")
  avail <- intersect(target_items, unique(bsi$bs_item))

  if (length(avail) > 0) {
    chosen_item <- avail[1]
    cat(sprintf("\nUsing BS_ITEM = %s\n", chosen_item))
    bsi_filt <- bsi[bsi$bs_item == chosen_item, ]

    # Also filter to 0000 (all maturities) if available
    if ("maturity" %in% names(bsi_filt)) {
      if ("0000" %in% unique(bsi_filt$maturity)) {
        bsi_filt <- bsi_filt[bsi_filt$maturity == "0000", ]
        cat("Filtered to all maturities (0000)\n")
      }
    }
  } else {
    cat("\nNo standard BS_ITEM found. Using first available series per country.\n")
    # Take the series with the most observations per country
    bsi_filt <- bsi %>%
      group_by(country, bs_item) %>%
      summarise(n = n(), .groups = "drop") %>%
      group_by(country) %>%
      slice_max(n, n = 1) %>%
      ungroup()

    chosen_keys <- bsi_filt %>% select(country, bs_item)
    bsi_filt <- bsi %>% inner_join(chosen_keys, by = c("country", "bs_item"))
  }
} else {
  # If no KEY field, the data should already be the right series
  bsi_filt <- bsi
}

# Select core columns
bsi_clean <- data.frame(
  country = bsi_filt$country,
  date = bsi_filt$date,
  nfc_loans_eur = bsi_filt$nfc_loans,  # in EUR millions
  stringsAsFactors = FALSE
)

# Remove duplicates (keep first if multiple series per country-month)
bsi_clean <- bsi_clean %>%
  group_by(country, date) %>%
  summarise(nfc_loans_eur = first(nfc_loans_eur), .groups = "drop") %>%
  as.data.frame()

cat(sprintf("\nCleaned BSI: %d obs\n", nrow(bsi_clean)))
for (cc in unique(bsi_clean$country)) {
  sub <- bsi_clean[bsi_clean$country == cc, ]
  cat(sprintf("  %s: %d months, %s to %s, range: %.0f-%.0f EUR mn\n",
              cc, nrow(sub), min(sub$date), max(sub$date),
              min(sub$nfc_loans_eur, na.rm = TRUE),
              max(sub$nfc_loans_eur, na.rm = TRUE)))
}

# ============================================================
# 2. Restrict to common sample period
# ============================================================
# Find the latest start and earliest end across all countries
panel_start <- max(tapply(bsi_clean$date, bsi_clean$country, min))
panel_end <- min(tapply(bsi_clean$date, bsi_clean$country, max))
cat(sprintf("\nCommon sample: %s to %s\n", panel_start, panel_end))

bsi_panel <- bsi_clean %>%
  filter(date >= panel_start & date <= panel_end)

cat(sprintf("Panel after trimming: %d obs\n", nrow(bsi_panel)))

# Ensure balanced panel
country_counts <- bsi_panel %>% group_by(country) %>% summarise(n = n())
cat("Months per country after trimming:\n")
print(country_counts)

# ============================================================
# 3. Construct analysis variables
# ============================================================
bsi_panel <- bsi_panel %>%
  arrange(country, date) %>%
  group_by(country) %>%
  mutate(
    # Log NFC loans
    log_nfc_loans = log(nfc_loans_eur),
    # Year-month identifiers
    year = year(date),
    month = month(date),
    ym = as.numeric(date),  # numeric for fixed effects
    # Treatment indicators
    hungary = as.integer(country == "HU"),
    # Treatment date: September 2010
    post = as.integer(date >= as.Date("2010-09-01")),
    # Interaction
    treat = hungary * post,
    # Event time (months relative to September 2010)
    event_time = as.integer(round(difftime(date, as.Date("2010-09-01"), units = "days") / 30.44)),
    # Index month (normalize loans to 100 at treatment date)
    nfc_base = nfc_loans_eur[which.min(abs(date - as.Date("2010-09-01")))],
    nfc_index = 100 * nfc_loans_eur / nfc_base,
    # FGS period indicator (2013 onward)
    fgs_period = as.integer(date >= as.Date("2013-06-01")),
    # Levy halved period (2016 onward)
    halved_period = as.integer(date >= as.Date("2016-01-01"))
  ) %>%
  ungroup()

# ============================================================
# 4. World Bank annual panel
# ============================================================
wb <- readRDS("../data/wb_credit_gdp.rds")

wb_panel <- wb %>%
  filter(year >= 2003 & year <= 2020) %>%
  mutate(
    hungary = as.integer(country == "HU"),
    post = as.integer(year >= 2011),  # Annual: first full year is 2011
    treat = hungary * post
  )

cat(sprintf("\nWorld Bank panel: %d obs, %d countries, %d-%d\n",
            nrow(wb_panel), length(unique(wb_panel$country)),
            min(wb_panel$year), max(wb_panel$year)))

# ============================================================
# 5. Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

# Pre-treatment period (2005-2010:08)
pre <- bsi_panel %>% filter(date < as.Date("2010-09-01") & date >= as.Date("2005-01-01"))
post_dat <- bsi_panel %>% filter(date >= as.Date("2010-09-01"))

cat("\nPre-treatment NFC loans (EUR millions):\n")
pre %>%
  group_by(country) %>%
  summarise(
    mean = mean(nfc_loans_eur),
    sd = sd(nfc_loans_eur),
    min = min(nfc_loans_eur),
    max = max(nfc_loans_eur),
    n = n()
  ) %>%
  print()

cat("\nPost-treatment NFC loans (EUR millions):\n")
post_dat %>%
  group_by(country) %>%
  summarise(
    mean = mean(nfc_loans_eur),
    sd = sd(nfc_loans_eur),
    min = min(nfc_loans_eur),
    max = max(nfc_loans_eur),
    n = n()
  ) %>%
  print()

# World Bank pre/post
cat("\nCredit to private sector (% GDP):\n")
wb_panel %>%
  mutate(period = ifelse(year < 2011, "Pre", "Post")) %>%
  group_by(country, period) %>%
  summarise(mean_credit_gdp = mean(credit_gdp, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = period, values_from = mean_credit_gdp) %>%
  print()

# ============================================================
# 6. Save analysis-ready panels
# ============================================================
saveRDS(bsi_panel, "../data/bsi_panel.rds")
saveRDS(wb_panel, "../data/wb_panel.rds")

# Also save summary stats for tables
sumstats <- bsi_panel %>%
  filter(date >= as.Date("2005-01-01")) %>%
  group_by(country) %>%
  summarise(
    mean_loans = mean(nfc_loans_eur),
    sd_loans = sd(nfc_loans_eur),
    min_loans = min(nfc_loans_eur),
    max_loans = max(nfc_loans_eur),
    mean_log = mean(log_nfc_loans),
    sd_log = sd(log_nfc_loans),
    n_months = n(),
    .groups = "drop"
  )
saveRDS(sumstats, "../data/sumstats.rds")

cat("\nAnalysis panels saved.\n")
cat("DONE: 02_clean_data.R\n")
