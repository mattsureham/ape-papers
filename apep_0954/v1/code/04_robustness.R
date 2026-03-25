## 04_robustness.R — Robustness checks and event study
## apep_0954: Beirut Port Explosion and Food Prices

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

dt <- fread(file.path(data_dir, "panel_main.csv"))
dt[, ym := as.Date(ym)]

# ---- 1. Panel Balance Check ----
cat("=== PANEL BALANCE ===\n")
bal <- dt[, .(n_months = uniqueN(ym)), by = .(market, commodity)]
cat(sprintf("Market-commodity pairs: %d\n", nrow(bal)))
cat(sprintf("Mean months per pair: %.1f (of 36 possible)\n", mean(bal$n_months)))

# How many commodities appear both pre and post?
pre_commod <- unique(dt[post == 0, commodity])
post_commod <- unique(dt[post == 1, commodity])
both_commod <- intersect(pre_commod, post_commod)
cat(sprintf("Commodities pre only: %d, post only: %d, both: %d\n",
            length(setdiff(pre_commod, post_commod)),
            length(setdiff(post_commod, pre_commod)),
            length(both_commod)))

# Create balanced sub-panel: commodities observed both pre and post
dt_bal <- dt[commodity %in% both_commod]
cat(sprintf("\nBalanced commodity panel: %d obs (from %d)\n", nrow(dt_bal), nrow(dt)))
cat(sprintf("Commodities in balanced panel: %d\n", length(both_commod)))

# ---- 2. Re-run main specs on balanced panel ----
cat("\n=== BALANCED PANEL DiD ===\n")

dt_bal[, mc_fe := paste0(market, "_", commodity)]
dt_bal[, ct_fe := paste0(commodity, "_", as.character(ym))]
dt_bal[, mt_fe := paste0(market, "_", as.character(ym))]
dt_bal[, bp_post := beirut_proximity * post]

# DiD: all commodities (balanced)
m1b <- feols(log_price ~ bp_post | mc_fe + ct_fe,
             data = dt_bal, cluster = ~market)
cat("Balanced panel - All commodities:\n")
summary(m1b)

# DiD: imported only (balanced)
m2b <- feols(log_price ~ bp_post | mc_fe + ct_fe,
             data = dt_bal[imported == 1], cluster = ~market)
cat("\nBalanced panel - Imported:\n")
summary(m2b)

# DiD: local only (balanced, placebo)
m3b <- feols(log_price ~ bp_post | mc_fe + ct_fe,
             data = dt_bal[local == 1], cluster = ~market)
cat("\nBalanced panel - Local (placebo):\n")
summary(m3b)

# Triple-diff on balanced panel
dt_bal_td <- dt_bal[commodity_type != "ambiguous"]
dt_bal_td[, bp_imp_post := beirut_proximity * imported * post]

m5b <- feols(log_price ~ bp_imp_post |
               mc_fe + mt_fe + ct_fe,
             data = dt_bal_td, cluster = ~market)
cat("\nBalanced panel - Triple-diff (fully saturated):\n")
summary(m5b)

# ---- 3. Event Study (Balanced Panel) ----
cat("\n=== EVENT STUDY ===\n")

# Create proper monthly event time
explosion_month <- as.Date("2020-08-01")
dt_bal[, event_month := as.integer(round(difftime(ym, explosion_month, units = "days") / 30.44))]

# Check range
cat(sprintf("Event time range: %d to %d\n", min(dt_bal$event_month), max(dt_bal$event_month)))
cat(sprintf("Available event times: %s\n", paste(sort(unique(dt_bal$event_month)), collapse = ", ")))

# Bin at -12 and +12
dt_bal[event_month < -12, event_month := -12]
dt_bal[event_month > 16, event_month := 16]

# Reference period: -1 (July 2020)
# Event study for imported commodities
m_es_imp <- feols(log_price ~ i(event_month, beirut_proximity, ref = -1) | mc_fe + ct_fe,
                  data = dt_bal[imported == 1], cluster = ~market)

# Event study for local commodities
m_es_loc <- feols(log_price ~ i(event_month, beirut_proximity, ref = -1) | mc_fe + ct_fe,
                  data = dt_bal[local == 1], cluster = ~market)

cat("\nEvent study coefficients (imported):\n")
es_coefs <- coeftable(m_es_imp)
print(es_coefs[1:min(nrow(es_coefs), 30), ])

# ---- 4. Excluding Beirut Market ----
cat("\n=== EXCLUDING BEIRUT MARKET ===\n")

m_no_beirut <- feols(log_price ~ bp_post | mc_fe + ct_fe,
                     data = dt_bal[market != "Beirut" & imported == 1],
                     cluster = ~market)
cat("Imported, excluding Beirut market:\n")
summary(m_no_beirut)

# ---- 5. Short post-window (Aug-Dec 2020 only) ----
cat("\n=== SHORT POST WINDOW (Aug-Dec 2020) ===\n")

dt_short <- dt_bal[ym <= "2020-12-31"]
dt_short[, bp_post_s := beirut_proximity * post]

m_short <- feols(log_price ~ bp_post_s | mc_fe + ct_fe,
                 data = dt_short[imported == 1], cluster = ~market)
cat("Imported, short post window:\n")
summary(m_short)

# ---- 6. USD Prices (robustness) ----
cat("\n=== USD PRICES ===\n")

if ("log_price_usd" %in% names(dt_bal)) {
  dt_bal_usd <- dt_bal[!is.na(log_price_usd)]
  if (nrow(dt_bal_usd) > 100) {
    m_usd <- feols(log_price_usd ~ bp_post | mc_fe + ct_fe,
                   data = dt_bal_usd[imported == 1], cluster = ~market)
    cat("USD prices, imported:\n")
    summary(m_usd)
  } else {
    cat("Insufficient USD price observations.\n")
  }
} else {
  cat("No USD price variable available.\n")
}

# ---- 7. Fuel vs Food Decomposition ----
cat("\n=== FUEL vs FOOD ===\n")

dt_bal[, is_fuel := as.integer(grepl("fuel|diesel|gasoline|petrol|gas", commodity, ignore.case = TRUE))]
cat(sprintf("Fuel obs: %d, Food obs: %d\n",
            sum(dt_bal$is_fuel), sum(!dt_bal$is_fuel)))

if (sum(dt_bal$is_fuel) > 50) {
  m_fuel <- feols(log_price ~ bp_post | mc_fe + ct_fe,
                  data = dt_bal[is_fuel == 1], cluster = ~market)
  cat("Fuel commodities:\n")
  summary(m_fuel)

  m_food <- feols(log_price ~ bp_post | mc_fe + ct_fe,
                  data = dt_bal[is_fuel == 0 & imported == 1], cluster = ~market)
  cat("\nImported food (non-fuel):\n")
  summary(m_food)
}

# ---- 8. Save all robustness models ----
save(m1b, m2b, m3b, m5b, m_es_imp, m_es_loc, m_no_beirut, m_short,
     file = file.path(data_dir, "models_robustness.RData"))

# Update diagnostics
load(file.path(data_dir, "diagnostics.json") |> dirname() |> file.path("diagnostics.json") |>
       (\(x) { fromJSON(x) })() |> (\(x) NULL)())

diag <- fromJSON(file.path(data_dir, "diagnostics.json"))
diag$balanced_n_obs <- nrow(dt_bal)
diag$balanced_n_commodities <- length(both_commod)
diag$balanced_imported_beta <- coef(m2b)["bp_post"]
diag$balanced_imported_se <- se(m2b)["bp_post"]
diag$balanced_triple_beta <- coef(m5b)["bp_imp_post"]
diag$balanced_triple_se <- se(m5b)["bp_imp_post"]

write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("\nRobustness complete. Models saved.\n")
