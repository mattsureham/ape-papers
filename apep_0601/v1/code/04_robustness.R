## 04_robustness.R — Robustness checks and placebo tests
## APEP-0601: PDUFA Deadline Bunching and Drug Safety

source("code/00_packages.R")

cat("=== Loading data ===\n")
df <- readRDS("data/clean_analysis.rds")
df_full <- readRDS("data/clean_full.rds")
results <- readRDS("data/main_results.rds")

# ============================================================
# 1. Covariate Balance at Cutoff
# ============================================================
cat("=== 1. Covariate Balance at c=300 ===\n")

df_rdd <- df %>% filter(review_days >= 200, review_days <= 500)

covariates <- c("is_orphan", "is_accelerated", "is_fast_track", "years_on_market")
balance_results <- list()

for (cov in covariates) {
  if (cov %in% names(df_rdd)) {
    rd_cov <- tryCatch({
      rdrobust(y = as.numeric(df_rdd[[cov]]), x = df_rdd$rv, c = 0,
               kernel = "triangular", p = 1)
    }, error = function(e) NULL)

    if (!is.null(rd_cov)) {
      balance_results[[cov]] <- list(
        coef = rd_cov$coef[1],
        se = rd_cov$se[3],
        pv = rd_cov$pv[3]
      )
      cat(sprintf("  %s: coef=%.3f, SE=%.3f, p=%.3f\n",
                  cov, rd_cov$coef[1], rd_cov$se[3], rd_cov$pv[3]))
    }
  }
}

# Therapeutic class balance
cat("\nTherapeutic class by bunching status:\n")
df_rdd %>%
  mutate(bunched = review_days >= 295 & review_days < 310) %>%
  count(bunched, therapeutic_class) %>%
  pivot_wider(names_from = bunched, values_from = n, values_fill = 0) %>%
  print()

# ============================================================
# 2. Placebo Cutoffs
# ============================================================
cat("\n=== 2. Placebo Cutoffs ===\n")

placebo_cutoffs <- c(200, 250, 350, 400, 450)
placebo_results <- list()

for (pc in placebo_cutoffs) {
  pc_rv <- df_rdd$review_days - pc
  rd_placebo <- tryCatch({
    rdrobust(y = df_rdd$log_serious_ae, x = pc_rv, c = 0,
             kernel = "triangular", p = 1)
  }, error = function(e) NULL)

  if (!is.null(rd_placebo)) {
    placebo_results[[as.character(pc)]] <- list(
      cutoff = pc,
      coef = rd_placebo$coef[1],
      se = rd_placebo$se[3],
      pv = rd_placebo$pv[3]
    )
    cat(sprintf("  Cutoff=%d: coef=%.3f, SE=%.3f, p=%.3f\n",
                pc, rd_placebo$coef[1], rd_placebo$se[3], rd_placebo$pv[3]))
  }
}

# ============================================================
# 3. Bandwidth Sensitivity
# ============================================================
cat("\n=== 3. Bandwidth Sensitivity ===\n")

bandwidths <- c(30, 50, 75, 100, 150, 200)
bw_results <- list()

for (bw in bandwidths) {
  df_bw <- df %>%
    filter(review_days >= (300 - bw), review_days <= (300 + bw))

  if (nrow(df_bw) >= 20) {
    rd_bw <- tryCatch({
      rdrobust(y = df_bw$log_serious_ae, x = df_bw$rv, c = 0,
               kernel = "triangular", p = 1, h = bw)
    }, error = function(e) NULL)

    if (!is.null(rd_bw)) {
      bw_results[[as.character(bw)]] <- list(
        bandwidth = bw,
        coef = rd_bw$coef[1],
        se = rd_bw$se[3],
        pv = rd_bw$pv[3],
        n_left = rd_bw$N_h[1],
        n_right = rd_bw$N_h[2]
      )
      cat(sprintf("  h=%d: coef=%.3f, SE=%.3f, p=%.3f, N=%d+%d\n",
                  bw, rd_bw$coef[1], rd_bw$se[3], rd_bw$pv[3],
                  rd_bw$N_h[1], rd_bw$N_h[2]))
    }
  }
}

# ============================================================
# 4. Alternative Polynomial Orders
# ============================================================
cat("\n=== 4. Polynomial Order Sensitivity ===\n")

poly_results <- list()
for (p_order in 1:3) {
  rd_poly <- tryCatch({
    rdrobust(y = df_rdd$log_serious_ae, x = df_rdd$rv, c = 0,
             kernel = "triangular", p = p_order)
  }, error = function(e) NULL)

  if (!is.null(rd_poly)) {
    poly_results[[as.character(p_order)]] <- list(
      order = p_order,
      coef = rd_poly$coef[1],
      se = rd_poly$se[3],
      pv = rd_poly$pv[3]
    )
    cat(sprintf("  p=%d: coef=%.3f, SE=%.3f, p=%.3f\n",
                p_order, rd_poly$coef[1], rd_poly$se[3], rd_poly$pv[3]))
  }
}

# ============================================================
# 5. Priority Review Placebo (180-day deadline)
# ============================================================
cat("\n=== 5. Priority Review Placebo (c=180) ===\n")

# Need to reload raw NME data for priority review drugs
nme_raw <- readRDS("data/nme_raw.rds")
ae_cache <- readRDS("data/faers_pdufa_cache.rds")

df_priority <- nme_raw %>%
  mutate(
    receipt_date = as.Date(FDA.Receipt.Date, format = "%m/%d/%Y"),
    approval_date = as.Date(FDA.Approval.Date, format = "%m/%d/%Y"),
    review_days = as.numeric(approval_date - receipt_date),
    approval_year = as.integer(Approval.Year),
    nda_number = as.character(Application.Number.1.)
  ) %>%
  filter(grepl("^Priority", Review.Designation), approval_year >= 1993,
         !is.na(review_days)) %>%
  left_join(ae_cache, by = "nda_number") %>%
  filter(!is.na(total_ae)) %>%
  mutate(
    log_serious_ae = log1p(serious_ae),
    rv_180 = review_days - 180
  )

cat("Priority review drugs:", nrow(df_priority), "\n")
if (nrow(df_priority) >= 20) {
  rd_priority <- tryCatch({
    rdrobust(y = df_priority$log_serious_ae, x = df_priority$rv_180, c = 0,
             kernel = "triangular", p = 1)
  }, error = function(e) {
    cat("rdrobust failed for priority review:", e$message, "\n")
    NULL
  })

  if (!is.null(rd_priority)) {
    cat("  RD at 180-day priority deadline:\n")
    cat("  Coef:", round(rd_priority$coef[1], 3), "\n")
    cat("  Robust SE:", round(rd_priority$se[3], 3), "\n")
    cat("  P-value:", round(rd_priority$pv[3], 4), "\n")
  }
}

# ============================================================
# 6. Negative Binomial for Count Outcomes
# ============================================================
cat("\n=== 6. Negative Binomial Count Models ===\n")

df_nb <- df %>%
  filter(review_days >= 250, review_days <= 400) %>%
  mutate(bunched = review_days >= 295 & review_days < 310)

nb1 <- tryCatch({
  MASS::glm.nb(serious_ae ~ bunched + factor(therapeutic_class) +
                 approval_year + offset(log(years_on_market)),
               data = df_nb %>% filter(serious_ae >= 0, years_on_market > 0))
}, error = function(e) {
  cat("NB model failed:", e$message, "\n")
  NULL
})

if (!is.null(nb1)) {
  cat("NB model: serious AEs ~ bunched + controls + offset(log(years_on_market))\n")
  cat("  Bunched IRR:", round(exp(coef(nb1)["bunchedTRUE"]), 3), "\n")
  cat("  Bunched coef:", round(coef(nb1)["bunchedTRUE"], 3), "\n")
  cat("  SE:", round(summary(nb1)$coefficients["bunchedTRUE", "Std. Error"], 3), "\n")
  cat("  P-value:", round(summary(nb1)$coefficients["bunchedTRUE", "Pr(>|z|)"], 4), "\n")
}

nb2 <- tryCatch({
  MASS::glm.nb(death_ae ~ bunched + factor(therapeutic_class) +
                 approval_year + offset(log(years_on_market)),
               data = df_nb %>% filter(death_ae >= 0, years_on_market > 0))
}, error = function(e) NULL)

if (!is.null(nb2)) {
  cat("\nNB model: death AEs ~ bunched:\n")
  cat("  Bunched IRR:", round(exp(coef(nb2)["bunchedTRUE"]), 3), "\n")
  cat("  Bunched coef:", round(coef(nb2)["bunchedTRUE"], 3), "\n")
  cat("  SE:", round(summary(nb2)$coefficients["bunchedTRUE", "Std. Error"], 3), "\n")
  cat("  P-value:", round(summary(nb2)$coefficients["bunchedTRUE", "Pr(>|z|)"], 4), "\n")
}

# ============================================================
# Save all robustness results
# ============================================================
robustness <- list(
  balance = balance_results,
  placebo_cutoffs = placebo_results,
  bandwidth_sensitivity = bw_results,
  polynomial = poly_results,
  priority_placebo = if (exists("rd_priority") && !is.null(rd_priority)) {
    list(coef = rd_priority$coef[1], se = rd_priority$se[3], pv = rd_priority$pv[3])
  } else NULL,
  nb_serious = if (!is.null(nb1)) {
    list(irr = exp(coef(nb1)["bunchedTRUE"]),
         coef = coef(nb1)["bunchedTRUE"],
         se = summary(nb1)$coefficients["bunchedTRUE", "Std. Error"],
         pv = summary(nb1)$coefficients["bunchedTRUE", "Pr(>|z|)"])
  } else NULL,
  nb_death = if (!is.null(nb2)) {
    list(irr = exp(coef(nb2)["bunchedTRUE"]),
         coef = coef(nb2)["bunchedTRUE"],
         se = summary(nb2)$coefficients["bunchedTRUE", "Std. Error"],
         pv = summary(nb2)$coefficients["bunchedTRUE", "Pr(>|z|)"])
  } else NULL
)

saveRDS(robustness, "data/robustness_results.rds")
cat("\n=== Robustness analysis complete ===\n")
