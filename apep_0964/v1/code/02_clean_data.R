# 02_clean_data.R — Variable construction and sample restrictions
source("00_packages.R")

panel <- readRDS("../data/panel.rds")
atad <- readRDS("../data/atad_treatment.rds")

cat("=== Data Cleaning ===\n")
cat(sprintf("Starting rows: %d\n", nrow(panel)))

# ---- 1. Winsorize extreme ratios (top/bottom 1%) ----
winsorize <- function(x, probs = c(0.01, 0.99)) {
  q <- quantile(x, probs, na.rm = TRUE)
  x[x < q[1]] <- q[1]
  x[x > q[2]] <- q[2]
  x
}

panel[!is.na(interest_gos_ratio), interest_gos_w := winsorize(interest_gos_ratio)]
panel[!is.na(net_interest_gos), net_interest_gos_w := winsorize(net_interest_gos)]
panel[!is.na(debt_ratio), debt_ratio_w := winsorize(debt_ratio)]
panel[!is.na(leverage), leverage_w := winsorize(leverage)]

# ---- 2. Create event-time variable ----
# Relative to each country's adoption year
panel[, event_time := year - adoption_year]

# For the main (2019 adopters) analysis, event time relative to 2019
panel[, event_time_2019 := year - 2019]

# ---- 3. Create dose-response treatment ----
# adopted × dose interaction
panel[, treat_dose := adopted * dose]

# For event study: event_time × dose
# Only for 2019 adopters (non-derogation)
panel[, early_adopter := as.integer(derogation == 0)]

# ---- 4. Log transforms for levels ----
panel[debt_securities > 0, log_debt_sec := log(debt_securities)]
panel[loans > 0, log_loans := log(loans)]
panel[equity > 0, log_equity := log(equity)]
panel[interest_paid > 0, log_interest := log(interest_paid)]
panel[gos_ebitda > 0, log_gos := log(gos_ebitda)]

# ---- 5. Pre-treatment means for normalization ----
pre_means <- panel[year < 2019, .(
  pre_mean_interest_gos = mean(interest_gos_ratio, na.rm = TRUE),
  pre_sd_interest_gos = sd(interest_gos_ratio, na.rm = TRUE),
  pre_mean_debt_ratio = mean(debt_ratio, na.rm = TRUE),
  pre_sd_debt_ratio = sd(debt_ratio, na.rm = TRUE),
  pre_mean_leverage = mean(leverage, na.rm = TRUE),
  pre_sd_leverage = sd(leverage, na.rm = TRUE)
), by = geo]

panel <- merge(panel, pre_means, by = "geo", all.x = TRUE)

# ---- 6. Country-group indicators for heterogeneity ----
# High-dose: de_minimis = 0 (IT, LV, SK)
# Medium-dose: de_minimis = 1 (NL, PT, RO, SI, ES)
# Standard: de_minimis = 3 (18 countries)
# Low-dose: de_minimis = 5 (SE)
panel[, dose_group := fcase(
  de_minimis_eur == 0, "nil",
  de_minimis_eur == 1, "1M",
  de_minimis_eur == 3, "3M",
  de_minimis_eur == 5, "5M"
)]

# ---- 7. Check balance ----
cat("\n=== Panel Balance ===\n")
bal <- panel[, .N, by = .(geo, year)]
cat(sprintf("Balanced: %s\n",
            ifelse(all(bal$N == 1) & uniqueN(bal$geo) * uniqueN(bal$year) == nrow(bal),
                   "YES (strongly balanced)", "NO (some gaps)")))

# Country-year counts
cat(sprintf("Countries: %d, Years: %d\n", uniqueN(panel$geo), uniqueN(panel$year)))
cat(sprintf("Obs per country: %d-%d\n", min(bal[, .N, by = geo]$N), max(bal[, .N, by = geo]$N)))

# Treatment summary
cat(sprintf("\n=== Treatment Summary ===\n"))
cat(sprintf("Early adopters (2019): %d countries\n", sum(atad$derogation == 0)))
cat(sprintf("Derogation (2022-2024): %d countries\n", sum(atad$derogation == 1)))
cat(sprintf("Post-treatment obs: %d\n", sum(panel$adopted == 1)))
cat(sprintf("Pre-treatment obs: %d\n", sum(panel$adopted == 0)))

# ---- 8. Save cleaned panel ----
saveRDS(panel, "../data/panel_clean.rds")
cat("\nSaved data/panel_clean.rds\n")
