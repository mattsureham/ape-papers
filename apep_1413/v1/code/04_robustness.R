# 04_robustness.R — Robustness checks for ASAN DiD analysis
# Paper: apep_1413

source("00_packages.R")

data_dir <- "../data"

panel <- read.csv(file.path(data_dir, "analysis_panel.csv"), stringsAsFactors = FALSE)
main_results <- readRDS(file.path(data_dir, "main_results.rds"))

# Balance panel as in main analysis
balanced <- panel %>%
  filter(year >= 2008, year <= 2020, !is.na(new_registrations)) %>%
  group_by(iso3) %>%
  filter(n() == 13) %>%
  ungroup() %>%
  mutate(
    aze = as.integer(iso3 == "AZE"),
    post2013 = as.integer(year >= 2013),
    aze_post = aze * post2013
  )

true_att <- coef(main_results$did_reg_log)["aze_post"]

# ============================================================
# 1. Leave-One-Out DiD
# ============================================================

cat("=== Leave-One-Out: Dropping each donor ===\n")

donors <- setdiff(unique(balanced$iso3), "AZE")

loo_results <- data.frame()
for (drop_country in donors) {
  loo_data <- balanced %>% filter(iso3 != drop_country)
  loo_fit <- fixest::feols(
    log_reg ~ aze_post | iso3 + year,
    data = loo_data, cluster = ~iso3
  )
  loo_results <- rbind(loo_results, data.frame(
    dropped = drop_country,
    att = coef(loo_fit)["aze_post"],
    se = sqrt(diag(vcov(loo_fit)))["aze_post"],
    stringsAsFactors = FALSE
  ))
  cat(sprintf("  Drop %s: ATT = %.4f (SE = %.4f)\n",
              drop_country, coef(loo_fit)["aze_post"],
              sqrt(diag(vcov(loo_fit)))["aze_post"]))
}

cat(sprintf("\nLOO range: [%.4f, %.4f]\n",
            min(loo_results$att), max(loo_results$att)))

# ============================================================
# 2. Placebo-in-Time: Fake treatment in 2010
# ============================================================

cat("\n=== Placebo-in-Time: Treatment in 2010 ===\n")

placebo_time <- balanced %>%
  filter(year <= 2012) %>%
  mutate(placebo_post = as.integer(year >= 2010),
         placebo_tp = aze * placebo_post)

placebo_fit <- fixest::feols(
  log_reg ~ placebo_tp | iso3 + year,
  data = placebo_time, cluster = ~iso3
)
cat("Placebo (2010) result:\n")
print(summary(placebo_fit))

# ============================================================
# 3. Alternative outcome: GDP per capita (placebo)
# ============================================================

cat("\n=== Placebo outcome: GDP per capita ===\n")

gdp_fit <- fixest::feols(
  gdp_pc ~ aze_post | iso3 + year,
  data = balanced, cluster = ~iso3
)
cat("GDP per capita (should be null):\n")
print(summary(gdp_fit))

# ============================================================
# 4. Restricted donor pool: Caucasus + Central Asia only
# ============================================================

cat("\n=== Restricted donor pool ===\n")

restricted <- balanced %>%
  filter(iso3 %in% c("AZE", "GEO", "ARM", "KAZ", "UZB"))

restricted_fit <- fixest::feols(
  log_reg ~ aze_post | iso3 + year,
  data = restricted, cluster = ~iso3
)
cat("Restricted pool (Caucasus + C. Asia):\n")
print(summary(restricted_fit))

# ============================================================
# 5. Alternative treatment year: 2014 (delayed effect)
# ============================================================

cat("\n=== Alternative treatment year: 2014 ===\n")

balanced_2014 <- balanced %>%
  mutate(post2014 = as.integer(year >= 2014),
         aze_post2014 = aze * post2014)

alt_fit <- fixest::feols(
  log_reg ~ aze_post2014 | iso3 + year,
  data = balanced_2014, cluster = ~iso3
)
cat("Treatment in 2014:\n")
print(summary(alt_fit))

# ============================================================
# 6. Unemployment as additional outcome
# ============================================================

cat("\n=== Additional outcome: Unemployment ===\n")

unemp_fit <- fixest::feols(
  unemployment ~ aze_post | iso3 + year,
  data = balanced, cluster = ~iso3
)
cat("Unemployment:\n")
print(summary(unemp_fit))

# ============================================================
# 7. Save results
# ============================================================

robustness <- list(
  loo = loo_results,
  true_att = true_att,
  placebo_time = placebo_fit,
  gdp_placebo = gdp_fit,
  restricted = restricted_fit,
  alt_2014 = alt_fit,
  unemp = unemp_fit,
  space_placebos = data.frame(
    country = names(main_results$placebo_atts),
    att = as.numeric(main_results$placebo_atts),
    stringsAsFactors = FALSE
  ),
  perm_pvalue = main_results$perm_pvalue
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
