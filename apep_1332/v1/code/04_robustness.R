# ==============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# ==============================================================================

source("00_packages.R")
DATA_DIR <- "../data"

cat("=== Loading data ===\n")
panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
panel <- panel %>%
  filter(has_tmdl_data) %>%
  mutate(
    station_num = as.numeric(factor(station_id)),
    huc8_num = as.numeric(factor(huc8)),
    post = as.numeric(year >= 2010)
  )

results <- readRDS(file.path(DATA_DIR, "main_results.rds"))

cat(sprintf("Panel: %d obs, %d stations\n", nrow(panel), n_distinct(panel$station_id)))


# ---- Robustness 1: Alternative post-period cutoffs ----
cat("\n=== R1: Alternative post-period definitions ===\n")

cutoffs <- c(2008, 2010, 2012)
r1_list <- list()
for (yr in cutoffs) {
  panel_tmp <- panel %>% mutate(post_alt = as.numeric(year >= yr))
  r1_list[[as.character(yr)]] <- feols(
    do_mean ~ tmdl_share:post_alt | station_num + year,
    data = panel_tmp,
    cluster = ~huc8_num
  )
  cat(sprintf("  Post >= %d: coef = %.4f (SE = %.4f)\n", yr,
              coef(r1_list[[as.character(yr)]])["tmdl_share:post_alt"],
              sqrt(vcov(r1_list[[as.character(yr)]])["tmdl_share:post_alt", "tmdl_share:post_alt"])))
}


# ---- Robustness 2: Alternative clustering ----
cat("\n=== R2: Alternative clustering ===\n")

# Station-level clustering
m_station_cl <- feols(do_mean ~ tmdl_share:post | station_num + year,
                      data = panel,
                      cluster = ~station_num)
cat(sprintf("  Station clustering: coef = %.4f (SE = %.4f)\n",
            coef(m_station_cl)["tmdl_share:post"],
            sqrt(vcov(m_station_cl)["tmdl_share:post", "tmdl_share:post"])))

# State clustering (conservative)
panel$state_num <- as.numeric(factor(substr(panel$station_id, 1, 7)))
m_state_cl <- feols(do_mean ~ tmdl_share:post | station_num + year,
                    data = panel,
                    cluster = ~state_num)
cat(sprintf("  State clustering: coef = %.4f (SE = %.4f)\n",
            coef(m_state_cl)["tmdl_share:post"],
            sqrt(vcov(m_state_cl)["tmdl_share:post", "tmdl_share:post"])))


# ---- Robustness 3: Placebo treatment year ----
cat("\n=== R3: Placebo — pre-treatment period only ===\n")

# Use only pre-2010 data and test a fake treatment at 2005
panel_pre <- panel %>%
  filter(year < 2010) %>%
  mutate(placebo_post = as.numeric(year >= 2005))

m_placebo <- feols(do_mean ~ tmdl_share:placebo_post | station_num + year,
                   data = panel_pre,
                   cluster = ~huc8_num)
cat(sprintf("  Placebo (post 2005, pre-period only): coef = %.4f (SE = %.4f, p = %.3f)\n",
            coef(m_placebo)["tmdl_share:placebo_post"],
            sqrt(vcov(m_placebo)["tmdl_share:placebo_post", "tmdl_share:placebo_post"]),
            pvalue(m_placebo)["tmdl_share:placebo_post"]))


# ---- Robustness 4: Exclude extreme DO values ----
cat("\n=== R4: Winsorized DO values ===\n")

winsorize <- function(x, p = 0.01) {
  lo <- quantile(x, p, na.rm = TRUE)
  hi <- quantile(x, 1 - p, na.rm = TRUE)
  pmax(pmin(x, hi), lo)
}

panel_w <- panel %>% mutate(do_mean = winsorize(do_mean, 0.01))
m_winsor <- feols(do_mean ~ tmdl_share:post | station_num + year,
                  data = panel_w,
                  cluster = ~huc8_num)
cat(sprintf("  Winsorized (1%%/99%%): coef = %.4f (SE = %.4f)\n",
            coef(m_winsor)["tmdl_share:post"],
            sqrt(vcov(m_winsor)["tmdl_share:post", "tmdl_share:post"])))


# ---- Robustness 5: Weighted by monitoring frequency ----
cat("\n=== R5: Weighted by monitoring frequency ===\n")

m_weighted <- feols(do_mean ~ tmdl_share:post | station_num + year,
                    data = panel,
                    weights = ~do_n,
                    cluster = ~huc8_num)
cat(sprintf("  Weighted: coef = %.4f (SE = %.4f)\n",
            coef(m_weighted)["tmdl_share:post"],
            sqrt(vcov(m_weighted)["tmdl_share:post", "tmdl_share:post"])))


# ---- Robustness 6: Leave-one-HUC8-out ----
cat("\n=== R6: Leave-one-HUC8-out sensitivity ===\n")

huc8s <- unique(panel$huc8)
loo_coefs <- numeric(length(huc8s))
for (j in seq_along(huc8s)) {
  panel_loo <- panel %>% filter(huc8 != huc8s[j])
  m_loo <- feols(do_mean ~ tmdl_share:post | station_num + year,
                 data = panel_loo,
                 cluster = ~huc8_num)
  loo_coefs[j] <- coef(m_loo)["tmdl_share:post"]
}
cat(sprintf("  LOO range: [%.4f, %.4f], mean = %.4f\n",
            min(loo_coefs), max(loo_coefs), mean(loo_coefs)))


# ---- Save robustness results ----
cat("\n=== Saving robustness results ===\n")

rob_results <- list(
  alt_cutoffs = r1_list,
  alt_cluster_station = m_station_cl,
  alt_cluster_state = m_state_cl,
  placebo = m_placebo,
  winsorized = m_winsor,
  weighted = m_weighted,
  loo_coefs = loo_coefs
)
saveRDS(rob_results, file.path(DATA_DIR, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
