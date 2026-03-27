# 04_robustness.R — Robustness checks
# apep_1071: Golden Visa and Existing-New Dwelling Price Divergence

source("00_packages.R")

hpi <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
gap_data <- read_csv("../data/gap_data.csv", show_col_types = FALSE)
results <- readRDS("../data/main_results.rds")

treatment_start <- as.Date("2012-10-01")
suspension_start <- as.Date("2023-01-01")

gap_pre <- gap_data %>% filter(time <= as.Date("2019-12-31"))

# ── 1. LEAVE-ONE-OUT: Drop each comparator country ───────────────
cat("=== LEAVE-ONE-OUT ===\n")

all_countries <- unique(gap_pre$country)
comparators <- setdiff(all_countries, "PT")

loo_results <- data.frame(
  dropped = character(),
  beta = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (drop_country in comparators) {
  gap_loo <- gap_pre %>% filter(country != drop_country)
  m_loo <- feols(gap ~ portugal:post | country + quarter_id,
                 data = gap_loo,
                 cluster = ~country)
  loo_results <- rbind(loo_results, data.frame(
    dropped = drop_country,
    beta = coef(m_loo)["portugal:post"],
    se = se(m_loo)["portugal:post"]
  ))
}

loo_results <- loo_results %>% arrange(beta)
cat("LOO range: [", round(min(loo_results$beta), 2), ",",
    round(max(loo_results$beta), 2), "]\n")
cat("Top 5 most influential:\n")
loo_sorted <- loo_results %>%
  mutate(influence = abs(beta - results$dd_beta)) %>%
  arrange(desc(influence))
print(head(loo_sorted, 5))

# ── 2. PLACEBO TREATMENT DATES ───────────────────────────────────
cat("\n=== PLACEBO TREATMENT DATES ===\n")

placebo_dates_str <- c("2008-01-01", "2009-01-01", "2010-01-01", "2011-01-01")
placebo_dates <- as.Date(placebo_dates_str)
placebo_results <- data.frame(
  placebo_date = character(),
  beta = numeric(),
  se = numeric(),
  p = numeric(),
  stringsAsFactors = FALSE
)

gap_pre_only <- gap_data %>% filter(time < treatment_start)

for (i in seq_along(placebo_dates)) {
  pdate <- placebo_dates[i]
  pdate_label <- placebo_dates_str[i]

  # Only use countries that have data spanning the placebo date
  countries_with_span <- gap_pre_only %>%
    group_by(country) %>%
    filter(min(time) < pdate, max(time) >= pdate) %>%
    ungroup()

  if (nrow(countries_with_span) == 0 || n_distinct(countries_with_span$country) < 3) {
    cat(sprintf("  Placebo %s: skipped (insufficient country coverage)\n", pdate_label))
    next
  }

  gap_plac <- countries_with_span %>%
    mutate(post_placebo = as.integer(time >= pdate))

  m_plac <- tryCatch({
    feols(gap ~ portugal:post_placebo | country + quarter_id,
          data = gap_plac, cluster = ~country)
  }, error = function(e) NULL)

  if (!is.null(m_plac)) {
    placebo_results <- rbind(placebo_results, data.frame(
      placebo_date = pdate_label,
      beta = coef(m_plac)["portugal:post_placebo"],
      se = se(m_plac)["portugal:post_placebo"],
      p = pvalue(m_plac)["portugal:post_placebo"]
    ))
    cat(sprintf("  Placebo %s: β = %.2f (SE = %.2f, p = %.3f)\n",
                pdate_label, coef(m_plac)["portugal:post_placebo"],
                se(m_plac)["portugal:post_placebo"],
                pvalue(m_plac)["portugal:post_placebo"]))
  } else {
    cat(sprintf("  Placebo %s: estimation failed (collinearity)\n", pdate_label))
  }
}

# ── 3. FULL SAMPLE (including COVID period) ──────────────────────
cat("\n=== FULL SAMPLE ===\n")

m_full <- feols(gap ~ portugal:post | country + quarter_id,
                data = gap_data,
                cluster = ~country)
cat(sprintf("  Full sample: β = %.2f (SE = %.2f, p = %.4f)\n",
            coef(m_full)["portugal:post"], se(m_full)["portugal:post"],
            pvalue(m_full)["portugal:post"]))

# ── 4. 2023 SUSPENSION REVERSAL ─────────────────────────────────
cat("\n=== 2023 SUSPENSION REVERSAL ===\n")

gap_full_rev <- gap_data %>%
  mutate(portugal_post_susp = portugal * post_suspension)

m_reversal <- feols(gap ~ portugal:post + portugal_post_susp | country + quarter_id,
                    data = gap_full_rev,
                    cluster = ~country)

reversal_beta <- coef(m_reversal)["portugal_post_susp"]
reversal_se <- se(m_reversal)["portugal_post_susp"]
main_with_rev <- coef(m_reversal)["portugal:post"]

cat(sprintf("  Golden Visa effect: β = %.2f (SE = %.2f)\n",
            main_with_rev, se(m_reversal)["portugal:post"]))
cat(sprintf("  Suspension attenuation: β = %.2f (SE = %.2f)\n",
            reversal_beta, reversal_se))

# ── 5. RESTRICT TO SOUTHERN EUROPE ───────────────────────────────
cat("\n=== SOUTHERN EUROPE ONLY ===\n")

southern <- c("PT", "ES", "IT", "HR", "SI", "BG", "RO")
gap_south <- gap_pre %>% filter(country %in% southern)

m_south <- feols(gap ~ portugal:post | country + quarter_id,
                 data = gap_south,
                 cluster = ~country)
cat(sprintf("  Southern Europe: β = %.2f (SE = %.2f, p = %.4f)\n",
            coef(m_south)["portugal:post"], se(m_south)["portugal:post"],
            pvalue(m_south)["portugal:post"]))

# RI for Southern Europe
south_countries <- unique(gap_south$country)
ri_south <- numeric(length(south_countries))
for (i in seq_along(south_countries)) {
  gap_perm <- gap_south %>%
    mutate(portugal_perm = as.integer(country == south_countries[i]))
  m_perm <- feols(gap ~ portugal_perm:post | country + quarter_id,
                  data = gap_perm,
                  cluster = ~country)
  ri_south[i] <- coef(m_perm)["portugal_perm:post"]
}
obs_south <- coef(m_south)["portugal:post"]
ri_p_south <- mean(ri_south >= obs_south)
cat("  RI p-value (one-sided, Southern):", ri_p_south,
    "(rank", sum(ri_south >= obs_south), "of", length(south_countries), ")\n")

# ── 6. EXCLUDE COUNTRIES WITH OWN GOLDEN VISAS (post-2013) ──────
cat("\n=== EXCLUDE LATE GOLDEN VISA COUNTRIES ===\n")

# Spain introduced golden visa in Sept 2013, Ireland had IIP from 2012
late_gv <- c("ES", "IE", "HU")
gap_no_gv <- gap_pre %>% filter(!(country %in% late_gv))

m_no_gv <- feols(gap ~ portugal:post | country + quarter_id,
                 data = gap_no_gv,
                 cluster = ~country)
cat(sprintf("  Excl. ES/IE/HU: β = %.2f (SE = %.2f, p = %.4f)\n",
            coef(m_no_gv)["portugal:post"], se(m_no_gv)["portugal:post"],
            pvalue(m_no_gv)["portugal:post"]))

# ── 7. SAVE ──────────────────────────────────────────────────────
robustness <- list(
  loo = loo_results,
  placebos = placebo_results,
  full_sample_beta = coef(m_full)["portugal:post"],
  full_sample_se = se(m_full)["portugal:post"],
  full_sample_p = pvalue(m_full)["portugal:post"],
  reversal_beta = reversal_beta,
  reversal_se = reversal_se,
  main_with_reversal = main_with_rev,
  southern_beta = coef(m_south)["portugal:post"],
  southern_se = se(m_south)["portugal:post"],
  ri_p_south = ri_p_south,
  no_gv_beta = coef(m_no_gv)["portugal:post"],
  no_gv_se = se(m_no_gv)["portugal:post"]
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("\nRobustness checks complete.\n")
