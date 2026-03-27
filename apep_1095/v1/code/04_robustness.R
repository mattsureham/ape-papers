## 04_robustness.R — Robustness checks and placebos
## apep_1095: Induced seismicity and self-regulation in Texas Permian Basin

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
ring_panel <- readRDS("../data/ring_panel.rds")

# Drop NAs and create explicit treatment variable
panel <- panel %>%
  filter(!is.na(treated)) %>%
  mutate(
    post_treat = as.integer(treated & post),
    treated_int = as.integer(treated)
  )

# ========================================================================
# 1. Magnitude threshold robustness
# ========================================================================
cat("=== Magnitude Threshold Robustness ===\n")

# M2.5+ threshold
m_m25 <- feglm(eq_count_m25 ~ post_treat | grid_id + ym,
                data = panel,
                family = poisson,
                cluster = ~sra_name + ym)
cat("M2.5+ threshold:\n")
summary(m_m25)

# M3.0+ threshold
m_m30 <- feglm(eq_count_m30 ~ post_treat | grid_id + ym,
                data = panel,
                family = poisson,
                cluster = ~sra_name + ym)
cat("\nM3.0+ threshold:\n")
summary(m_m30)

# ========================================================================
# 2. Negative binomial (alternative distribution)
# ========================================================================
cat("\n=== Negative Binomial ===\n")

# Aggregate to SRA-zone × month for tractability
sra_zone_panel <- panel %>%
  group_by(sra_name, ym, month_date) %>%
  summarize(
    eq_count = sum(eq_count),
    treated = first(in_any_sra),
    post = first(post),
    treat_intensity = first(treat_intensity),
    .groups = "drop"
  ) %>%
  mutate(year = year(month_date), month_num = month(month_date))

sra_zone_panel <- sra_zone_panel %>%
  mutate(post_treat = as.integer(treated & post))

m_nb <- MASS::glm.nb(eq_count ~ post_treat + factor(sra_name) + factor(ym),
                       data = sra_zone_panel)
cat("Negative binomial:\n")
cat(sprintf("  post_treat coef = %.4f (SE = %.4f)\n",
            coef(m_nb)["post_treat"],
            sqrt(vcov(m_nb)["post_treat", "post_treat"])))

# ========================================================================
# 3. Placebo test: Pre-treatment (fake treatment in 2019)
# ========================================================================
cat("\n=== Placebo Test: Fake Treatment 2019 ===\n")

panel_pre <- panel %>%
  filter(month_date < as.Date("2021-09-01")) %>%
  mutate(
    fake_post = month_date >= as.Date("2019-06-01"),
    fake_treat = as.integer(treated & fake_post)
  )

m_placebo <- feglm(eq_count ~ fake_treat | grid_id + ym,
                    data = panel_pre,
                    family = poisson,
                    cluster = ~sra_name + ym)
cat("Placebo (fake treatment June 2019):\n")
summary(m_placebo)

# ========================================================================
# 4. Leave-one-SRA-out
# ========================================================================
cat("\n=== Leave-One-Out ===\n")

for (sra in c("Gardendale", "NCR", "Stanton")) {
  m_loo <- feglm(eq_count ~ post_treat | grid_id + ym,
                  data = panel %>% filter(sra_name != sra | !in_any_sra),
                  family = poisson,
                  cluster = ~sra_name + ym)
  cat(sprintf("Excluding %s: coef = %.4f (SE = %.4f)\n",
              sra,
              coef(m_loo)["post_treat"],
              sqrt(vcov(m_loo)["post_treat", "post_treat"])))
}

# ========================================================================
# 5. Randomization Inference (permute SRA designation timing)
# ========================================================================
cat("\n=== Randomization Inference ===\n")

set.seed(42)
n_perms <- 500

# Get the actual treatment effect
actual_coef <- coef(feglm(eq_count ~ post_treat | grid_id + ym,
                           data = panel, family = poisson))["post_treat"]

# Permutation: randomly reassign treatment dates among SRA cells
treat_dates_pool <- panel %>%
  filter(in_any_sra) %>%
  distinct(grid_id, treat_date) %>%
  pull(treat_date)

perm_coefs <- numeric(n_perms)
cat("Running", n_perms, "permutations...\n")

for (i in seq_len(n_perms)) {
  # Shuffle treatment dates among treated grid cells
  perm_panel <- panel
  treated_ids <- unique(panel$grid_id[panel$in_any_sra])
  shuffled_dates <- sample(treat_dates_pool, length(treated_ids), replace = TRUE)
  date_map <- data.frame(grid_id = treated_ids, perm_treat_date = shuffled_dates)

  perm_panel <- perm_panel %>%
    left_join(date_map, by = "grid_id") %>%
    mutate(
      perm_post = !is.na(perm_treat_date) & month_date >= perm_treat_date,
      perm_post_treat = as.integer(treated & perm_post)
    )

  tryCatch({
    m_perm <- feglm(eq_count ~ perm_post_treat | grid_id + ym,
                     data = perm_panel, family = poisson)
    perm_coefs[i] <- coef(m_perm)["perm_post_treat"]
  }, error = function(e) {
    perm_coefs[i] <<- NA
  })

  perm_panel <- perm_panel %>% dplyr::select(-perm_treat_date, -perm_post, -perm_post_treat)

  if (i %% 100 == 0) cat(sprintf("  %d/%d permutations done\n", i, n_perms))
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
ri_pvalue <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("\nRI p-value (two-sided): %.4f\n", ri_pvalue))
cat(sprintf("Actual coefficient: %.4f\n", actual_coef))
cat(sprintf("Permutation distribution: mean=%.4f, sd=%.4f\n",
            mean(perm_coefs), sd(perm_coefs)))

# ========================================================================
# 6. Heterogeneity: By magnitude and depth
# ========================================================================
cat("\n=== Heterogeneity ===\n")

# High vs low baseline seismicity
panel <- panel %>%
  mutate(
    post_treat_high = as.integer(treated & post & high_baseline == 1),
    post_treat_low = as.integer(treated & post & high_baseline == 0)
  )

m_het_baseline <- feglm(
  eq_count ~ post_treat_high + post_treat_low | grid_id + ym,
  data = panel,
  family = poisson,
  cluster = ~sra_name + ym
)
cat("Heterogeneity by baseline seismicity:\n")
summary(m_het_baseline)

# Save robustness results
saveRDS(list(
  m_m25 = m_m25,
  m_m30 = m_m30,
  m_placebo = m_placebo,
  actual_coef = actual_coef,
  perm_coefs = perm_coefs,
  ri_pvalue = ri_pvalue,
  m_het_baseline = m_het_baseline
), "../data/robustness_models.rds")

cat("\nRobustness checks complete.\n")
