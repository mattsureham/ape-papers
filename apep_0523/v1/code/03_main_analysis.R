## 03_main_analysis.R — Primary regressions
## TLV Vacancy Tax Expansion — apep_0523

source("00_packages.R")

data_dir <- "../data"

# ===========================================================================
# 1. Load data
# ===========================================================================
cat("=== Loading analysis data ===\n")
main <- fread(file.path(data_dir, "main_sample.csv"))
cat(sprintf("Main sample: %s rows, %s communes\n",
            format(nrow(main), big.mark = ","), uniqueN(main$codgeo)))

# ===========================================================================
# 2. Primary DiD: Transaction Volume
# ===========================================================================
cat("\n=== Primary DiD: Transaction Volume ===\n")

# Model 1: Basic TWFE
m1_vol <- feols(log_n_trans ~ treat_post | codgeo + quarter,
                data = main, cluster = ~codgeo)
cat("Model 1 (TWFE, volume):\n")
summary(m1_vol)

# Model 2: With department x quarter FE
main[, dep := substr(codgeo, 1, 2)]
m2_vol <- feols(log_n_trans ~ treat_post | codgeo + dep^quarter,
                data = main, cluster = ~codgeo)
cat("\nModel 2 (Dep x Quarter FE, volume):\n")
summary(m2_vol)

# ===========================================================================
# 3. Primary DiD: Prices
# ===========================================================================
cat("\n=== Primary DiD: Prices ===\n")

# Only communes with non-missing prices
price_sample <- main[!is.na(log_prix_m2)]

m1_price <- feols(log_prix_m2 ~ treat_post | codgeo + quarter,
                  data = price_sample, cluster = ~codgeo)
cat("Model 1 (TWFE, price/m2):\n")
summary(m1_price)

m2_price <- feols(log_prix_m2 ~ treat_post | codgeo + dep^quarter,
                  data = price_sample, cluster = ~codgeo)
cat("\nModel 2 (Dep x Quarter FE, price/m2):\n")
summary(m2_price)

# Median total price
m1_totprice <- feols(log_med_price ~ treat_post | codgeo + quarter,
                     data = main[!is.na(log_med_price)], cluster = ~codgeo)
cat("\nModel 1 (TWFE, total price):\n")
summary(m1_totprice)

# Helper function for event study coefficient extraction
extract_es_coefs <- function(mod, outcome_label) {
  nms <- names(coef(mod))
  rt <- as.numeric(gsub(".*::(-?[0-9]+):.*", "\\1", nms))
  data.table(
    rel_time = rt,
    estimate = coef(mod),
    se = se(mod),
    ci_lower = coef(mod) - 1.96 * se(mod),
    ci_upper = coef(mod) + 1.96 * se(mod),
    outcome = outcome_label
  )
}

# ===========================================================================
# 4. Event Study
# ===========================================================================
cat("\n=== Event Study ===\n")

# Create relative time factor (bin endpoints)
main[, rel_time_binned := pmax(pmin(rel_time, 6), -8)]
main[, rel_time_f := factor(rel_time_binned)]
# Drop period -1 as reference
main[, rel_time_f := relevel(rel_time_f, ref = as.character(-1))]

# Event study: volume
es_vol <- feols(log_n_trans ~ i(rel_time_binned, treated, ref = -1) | codgeo + quarter,
                data = main, cluster = ~codgeo)
cat("Event study (volume):\n")
summary(es_vol)

# Event study: prices
es_price <- feols(log_prix_m2 ~ i(rel_time_binned, treated, ref = -1) | codgeo + quarter,
                  data = price_sample[, rel_time_binned := pmax(pmin(rel_time, 6), -8)],
                  cluster = ~codgeo)
cat("\nEvent study (price/m2):\n")
summary(es_price)

# ===========================================================================
# 5. Composition effects
# ===========================================================================
cat("\n=== Composition Effects ===\n")

# Apartment share
m_apt <- feols(pct_apartment ~ treat_post | codgeo + quarter,
               data = main[!is.na(pct_apartment)], cluster = ~codgeo)
cat("Composition: apartment share\n")
summary(m_apt)

# Mean surface
m_surf <- feols(mean_surface ~ treat_post | codgeo + quarter,
                data = main[!is.na(mean_surface)], cluster = ~codgeo)
cat("\nComposition: mean surface\n")
summary(m_surf)

# Mean rooms
m_rooms <- feols(mean_rooms ~ treat_post | codgeo + quarter,
                 data = main[!is.na(mean_rooms)], cluster = ~codgeo)
cat("\nComposition: mean rooms\n")
summary(m_rooms)

# ===========================================================================
# 5b. DDD: Newly treated vs. Always treated (better control)
# ===========================================================================
cat("\n=== DDD: Newly treated vs. Always treated ===\n")

ddd_data <- fread(file.path(data_dir, "balanced_panel.csv"))
ddd_data <- ddd_data[group %in% c("newly_treated_2023", "always_treated")]
ddd_data[, newly := as.integer(group == "newly_treated_2023")]
ddd_data[, post_ddd := as.integer(year_q >= 2024)]
ddd_data[, ddd_treat := newly * post_ddd]

m_ddd_vol <- feols(log_n_trans ~ ddd_treat | codgeo + quarter,
                   data = ddd_data, cluster = ~codgeo)
cat("DDD Volume (newly vs. always treated):\n")
summary(m_ddd_vol)

m_ddd_price <- feols(log_prix_m2 ~ ddd_treat | codgeo + quarter,
                     data = ddd_data[!is.na(log_prix_m2)], cluster = ~codgeo)
cat("\nDDD Price/m2 (newly vs. always treated):\n")
summary(m_ddd_price)

# DDD event study
ddd_data[, rel_time_binned := pmax(pmin(rel_time, 6), -8)]
es_ddd_vol <- feols(log_n_trans ~ i(rel_time_binned, newly, ref = -1) | codgeo + quarter,
                    data = ddd_data, cluster = ~codgeo)
cat("\nDDD Event Study (volume):\n")
summary(es_ddd_vol)

# Export DDD event study coefficients
es_ddd_coef <- extract_es_coefs(es_ddd_vol, "DDD_log_transactions")
fwrite(es_ddd_coef, file.path(data_dir, "ddd_event_study_coefs.csv"))

# Save DDD summary
ddd_summary <- data.table(
  model = c("DDD Volume", "DDD Price/m2"),
  coef = c(coef(m_ddd_vol)["ddd_treat"], coef(m_ddd_price)["ddd_treat"]),
  se = c(se(m_ddd_vol)["ddd_treat"], se(m_ddd_price)["ddd_treat"]),
  n_obs = c(nobs(m_ddd_vol), nobs(m_ddd_price))
)
ddd_summary[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(ddd_summary, file.path(data_dir, "ddd_summary.csv"))
cat("\nDDD Summary:\n")
print(ddd_summary)

# ===========================================================================
# 6. Save results
# ===========================================================================
cat("\n=== Saving results ===\n")

results <- list(
  m1_vol = m1_vol,
  m2_vol = m2_vol,
  m1_price = m1_price,
  m2_price = m2_price,
  m1_totprice = m1_totprice,
  es_vol = es_vol,
  es_price = es_price,
  m_apt = m_apt,
  m_surf = m_surf,
  m_rooms = m_rooms,
  m_ddd_vol = m_ddd_vol,
  m_ddd_price = m_ddd_price,
  es_ddd_vol = es_ddd_vol
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# Export coefficients as CSV for figures
es_vol_coef <- extract_es_coefs(es_vol, "log_transactions")
es_price_coef <- extract_es_coefs(es_price, "log_price_m2")

fwrite(rbind(es_vol_coef, es_price_coef), file.path(data_dir, "event_study_coefs.csv"))

# Summary table
did_summary <- data.table(
  model = c("Volume (TWFE)", "Volume (Dep x Qtr)", "Price/m2 (TWFE)", "Price/m2 (Dep x Qtr)",
            "Total Price (TWFE)", "Apt Share", "Surface", "Rooms"),
  coef = c(coef(m1_vol)["treat_post"], coef(m2_vol)["treat_post"],
           coef(m1_price)["treat_post"], coef(m2_price)["treat_post"],
           coef(m1_totprice)["treat_post"],
           coef(m_apt)["treat_post"], coef(m_surf)["treat_post"], coef(m_rooms)["treat_post"]),
  se = c(se(m1_vol)["treat_post"], se(m2_vol)["treat_post"],
         se(m1_price)["treat_post"], se(m2_price)["treat_post"],
         se(m1_totprice)["treat_post"],
         se(m_apt)["treat_post"], se(m_surf)["treat_post"], se(m_rooms)["treat_post"]),
  n_obs = c(nobs(m1_vol), nobs(m2_vol), nobs(m1_price), nobs(m2_price),
            nobs(m1_totprice), nobs(m_apt), nobs(m_surf), nobs(m_rooms)),
  n_communes = c(length(unique(main$codgeo)), length(unique(main$codgeo)),
                 length(unique(price_sample$codgeo)), length(unique(price_sample$codgeo)),
                 length(unique(main[!is.na(log_med_price)]$codgeo)),
                 length(unique(main[!is.na(pct_apartment)]$codgeo)),
                 length(unique(main[!is.na(mean_surface)]$codgeo)),
                 length(unique(main[!is.na(mean_rooms)]$codgeo)))
)
did_summary[, pval := 2 * pnorm(-abs(coef / se))]
did_summary[, stars := fcase(
  pval < 0.01, "***",
  pval < 0.05, "**",
  pval < 0.10, "*",
  default = ""
)]

fwrite(did_summary, file.path(data_dir, "did_summary.csv"))
cat("DID Summary:\n")
print(did_summary)

cat("\nDone.\n")
