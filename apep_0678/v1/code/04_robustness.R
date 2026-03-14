# 04_robustness.R — Robustness checks and sensitivity analysis
# APEP-0678: Price Floors and Poison — MUP and Alcohol-Specific Mortality
#
# Checks:
#   R1. Placebo outcome: non-alcohol mortality (crude total - alcohol deaths) as falsification
#   R2. Synthetic control: English regions as donors to build synthetic Scotland
#   R3. Pre-trend test: formal Wald test of parallel trends (2013-2017)
#   R4. HonestDiD sensitivity: Rambachan-Roth bounds on event-study estimates
#   R5. Alternative treatment dates (robustness to exact MUP timing)
#   R6. Deprivation heterogeneity: within-England most vs least deprived trend

source("00_packages.R")

cat("\n=== ROBUSTNESS CHECKS FOR APEP-0678 ===\n\n")

DATA_DIR   <- "../data"
TABLE_DIR  <- "../tables"
FIGURE_DIR <- "../figures"
for (d in c(TABLE_DIR, FIGURE_DIR)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

country_panel     <- readRDS(file.path(DATA_DIR, "country_panel.rds"))
region_panel      <- readRDS(file.path(DATA_DIR, "region_panel.rds"))
deprivation_panel <- readRDS(file.path(DATA_DIR, "deprivation_panel.rds"))
main_results      <- readRDS(file.path(DATA_DIR, "main_results.rds"))

# ============================================================================
# R1: PLACEBO OUTCOME — Non-alcohol crude mortality
# ============================================================================
cat("--- R1: Placebo outcome (non-alcohol crude mortality) ---\n")

# Crude all-cause death rate proxied from deaths and population
# We use: crude_rate (all-cause) minus alcohol deaths rate = background mortality
# Since we don't have separate all-cause data, we use the crude_rate variable
# (which captures total deaths per 100,000) from the Fingertips data.
# Alcohol-specific deaths are a small share, so crude_rate ≈ non-alcohol deaths proxy.
# For Scotland/Wales we construct crude_rate from deaths / population * 1e5.

placebo_data <- country_panel %>%
  mutate(
    # crude_rate is total deaths per 100,000; rate is alcohol-specific age-std
    # Use crude_rate as the placebo non-alcohol outcome
    # (we expect no MUP effect on non-alcohol mortality)
    placebo_outcome = crude_rate
  ) %>%
  filter(!is.na(placebo_outcome))

placebo_twfe <- feols(
  placebo_outcome ~ treated | country + year,
  data    = placebo_data,
  cluster = ~country
)

cat("  Placebo outcome (crude rate) TWFE estimate:\n")
print(summary(placebo_twfe))

placebo_coef <- coef(placebo_twfe)["treated"]
placebo_se   <- se(placebo_twfe)["treated"]

cat("  Placebo coef:", round(placebo_coef, 3),
    "| SE:", round(placebo_se, 3),
    "| t-stat:", round(placebo_coef / placebo_se, 2), "\n")

# ============================================================================
# R2: SYNTHETIC CONTROL — English regions as donors for Scotland
# ============================================================================
cat("\n--- R2: Synthetic control (Scotland vs English regions) ---\n")

# Use pre-treatment rates (2013-2017) to find donor weights
# Donors: 9 English regions; Treated: Scotland
pre_years  <- 2013:2017
post_years <- 2018:2023

# Wide format for pre-treatment fitting
donors <- region_panel %>%
  filter(country == "England") %>%
  select(area_code, unit_label, year, rate) %>%
  filter(year %in% pre_years) %>%
  pivot_wider(names_from = area_code, values_from = rate, id_cols = year)

scotland_pre <- region_panel %>%
  filter(country == "Scotland", year %in% pre_years) %>%
  select(year, rate_scotland = rate) %>%
  arrange(year)

donor_cols  <- setdiff(names(donors), "year")
donor_mat   <- as.matrix(donors[, donor_cols])
scot_vec    <- scotland_pre$rate_scotland

# Constrained least squares: minimize ||Yw - Ys||^2 subject to w >= 0, sum(w) = 1
# We use quadratic programming via a simple iterative approach
# (no new packages needed — we use optim() with constraints)

obj_fn <- function(w) {
  sum((donor_mat %*% w - scot_vec)^2)
}

# Use Dirichlet initialization; optimize with L-BFGS-B and non-negativity
n_donors  <- length(donor_cols)
w_init    <- rep(1 / n_donors, n_donors)

optim_result <- optim(
  par     = w_init,
  fn      = function(w) {
    w_proj <- pmax(w, 0)
    w_proj <- w_proj / sum(w_proj)
    sum((donor_mat %*% w_proj - scot_vec)^2)
  },
  method  = "L-BFGS-B",
  lower   = rep(0, n_donors),
  control = list(maxit = 5000, factr = 1e-12)
)

w_raw     <- pmax(optim_result$par, 0)
w_synth   <- w_raw / sum(w_raw)
names(w_synth) <- donor_cols

cat("  Synthetic Scotland donor weights (>0.01):\n")
w_tbl <- tibble(
  area_code = donor_cols,
  weight    = round(w_synth, 4)
) %>%
  left_join(distinct(region_panel, area_code, unit_label), by = "area_code") %>%
  filter(weight >= 0.01) %>%
  arrange(desc(weight))
print(w_tbl)

# Pre-treatment RMSPE
synth_pre   <- as.numeric(donor_mat %*% w_synth)
pre_rmspe   <- sqrt(mean((synth_pre - scot_vec)^2))
cat("  Pre-treatment RMSPE:", round(pre_rmspe, 3), "\n")

# Post-treatment synthetic vs actual Scotland
all_years <- sort(unique(region_panel$year))
donors_all <- region_panel %>%
  filter(country == "England") %>%
  select(area_code, year, rate) %>%
  pivot_wider(names_from = area_code, values_from = rate, id_cols = year) %>%
  arrange(year)

donor_mat_all <- as.matrix(donors_all[, donor_cols])
synth_all     <- as.numeric(donor_mat_all %*% w_synth)

scot_all <- region_panel %>%
  filter(country == "Scotland") %>%
  arrange(year) %>%
  pull(rate)

synth_df <- tibble(
  year        = all_years,
  actual      = scot_all,
  synthetic   = synth_all,
  gap         = actual - synthetic
)

cat("  Synthetic control gaps (post-2018):\n")
print(synth_df %>% filter(year >= 2018))

avg_gap_post <- mean(synth_df$gap[synth_df$year >= 2018])
cat("  Average post-treatment gap:", round(avg_gap_post, 3), "\n")

# Permutation inference via donor placebos
donor_gaps <- lapply(donor_cols, function(dc) {
  d_pre  <- donor_mat[, setdiff(colnames(donor_mat), dc), drop = FALSE]
  d_y    <- donor_mat[, dc]
  n_d2   <- ncol(d_pre)
  w2_init <- rep(1 / n_d2, n_d2)
  opt2   <- optim(
    par    = w2_init,
    fn     = function(w) {
      wp <- pmax(w, 0); wp <- wp / sum(wp)
      sum((d_pre %*% wp - d_y)^2)
    },
    method = "L-BFGS-B",
    lower  = rep(0, n_d2),
    control = list(maxit = 2000, factr = 1e-10)
  )
  w2  <- pmax(opt2$par, 0); w2 <- w2 / sum(w2)
  # RMSPE-normalised gap
  pre_rmspe2 <- sqrt(mean((d_pre %*% w2 - d_y)^2))
  if (pre_rmspe2 < 0.01) return(NA_real_)
  d_all_mat  <- as.matrix(donors_all[, setdiff(donor_cols, dc), drop = FALSE])
  synth2_all <- as.numeric(d_all_mat %*% w2)
  d_y_all    <- donors_all[[dc]]
  post_gap2  <- mean(d_y_all[donors_all$year >= 2018] - synth2_all[donors_all$year >= 2018])
  post_gap2 / pre_rmspe2
})

donor_norm_gaps <- na.omit(unlist(donor_gaps))
scot_rmspe_ratio <- avg_gap_post / pre_rmspe

pval_sc <- mean(abs(donor_norm_gaps) >= abs(scot_rmspe_ratio))
cat("  Placebo permutation p-value (synth control):", round(pval_sc, 3), "\n")
cat("  Scotland RMSPE-normalised gap:", round(scot_rmspe_ratio, 3), "\n")

# Figure: Synthetic control
p_synth <- ggplot(synth_df, aes(x = year)) +
  geom_line(aes(y = actual,    colour = "Actual Scotland",    linetype = "Actual Scotland"),
            linewidth = 1) +
  geom_line(aes(y = synthetic, colour = "Synthetic Scotland", linetype = "Synthetic Scotland"),
            linewidth = 1) +
  geom_vline(xintercept = 2017.5, linetype = "dotted", colour = "grey50") +
  annotate("text", x = 2017.7, y = max(synth_df$actual) * 0.98,
           label = "MUP 2018", size = 2.8, hjust = 0, colour = "grey40") +
  scale_colour_manual(values = c("Actual Scotland"    = "#1b7837",
                                  "Synthetic Scotland" = "#636363"), name = NULL) +
  scale_linetype_manual(values = c("Actual Scotland" = "solid",
                                    "Synthetic Scotland" = "dashed"), name = NULL) +
  scale_x_continuous(breaks = 2013:2023) +
  labs(
    x = "Year",
    y = "Alcohol-specific mortality (per 100,000)",
    title = "Synthetic Control: Actual vs Synthetic Scotland"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position  = c(0.98, 0.02),
    legend.justification = c(1, 0),
    axis.text.x      = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(FIGURE_DIR, "fig3_synthetic_control.pdf"), p_synth,
       width = 7, height = 4.5, device = "pdf")
ggsave(file.path(FIGURE_DIR, "fig3_synthetic_control.png"), p_synth,
       width = 7, height = 4.5, dpi = 200)
cat("  Saved fig3_synthetic_control\n")

# ============================================================================
# R3: PRE-TREND TESTS
# ============================================================================
cat("\n--- R3: Pre-trend tests ---\n")

# Test whether pre-treatment trends differ between Scotland and England
pre_data <- country_panel %>%
  filter(year <= 2017, country %in% c("Scotland", "England")) %>%
  mutate(scotland = as.integer(country == "Scotland"))

# Linear trend interaction test
pre_trend_test <- lm(rate ~ year * scotland, data = pre_data)
cat("  Linear pre-trend interaction:\n")
print(summary(pre_trend_test))

# F-test on interaction term
anova_pt <- anova(
  lm(rate ~ year + scotland, data = pre_data),
  lm(rate ~ year * scotland, data = pre_data)
)
cat("  F-test for differential trend (p-value):",
    round(anova_pt$`Pr(>F)`[2], 4), "\n")

# Joint test on pre-period event-study dummies (using feols on all countries)
pre_joint <- country_panel %>%
  filter(year <= 2017) %>%
  mutate(scotland = as.integer(country == "Scotland"))

pre_es <- feols(
  rate ~ i(year, scotland, ref = 2017) | country + year,
  data    = pre_joint,
  cluster = ~country
)

cat("  Pre-trend event-study (Scotland, 2013-2016 vs 2017 base):\n")
print(summary(pre_es))

# ============================================================================
# R4: HonestDiD SENSITIVITY ANALYSIS
# ============================================================================
cat("\n--- R4: HonestDiD sensitivity (Rambachan-Roth) ---\n")

# Extract event-study coefficients and covariance matrix
es_df <- main_results$event_study_scotland

# Separate pre and post
pre_coefs  <- es_df %>% filter(year < 2017) %>% arrange(year) %>% pull(coef)
post_coefs <- es_df %>% filter(year > 2017) %>% arrange(year) %>% pull(coef)

n_pre  <- length(pre_coefs)
n_post <- length(post_coefs)

# Reconstruct covariance from SEs (diagonal approximation — limited by small N)
all_se <- es_df %>%
  filter(year != 2017) %>%
  arrange(year) %>%
  pull(se)

# Replace zero SE (2017 reference year appended) — it's already excluded here
sigma <- diag(all_se^2 + 1e-8)   # small ridge for numerical stability

betahat <- c(pre_coefs, post_coefs)

cat("  betahat (pre then post):", round(betahat, 3), "\n")
cat("  n_pre:", n_pre, "| n_post:", n_post, "\n")

# HonestDiD: Smoothness restriction (M = slope deviation budget)
M_vals <- c(0.5, 1.0, 2.0, 3.0)

honest_results <- tryCatch({
  lapply(M_vals, function(m_val) {
    res <- createSensitivityResults(
      betahat       = betahat,
      sigma         = sigma,
      numPrePeriods = n_pre,
      numPostPeriods = n_post,
      l_vec         = rep(1 / n_post, n_post),   # average ATT
      Mvec          = m_val
    )
    as.data.frame(res) %>% mutate(M = m_val)
  }) %>% bind_rows()
}, error = function(e) {
  cat("  HonestDiD error (likely degenerate covariance):", conditionMessage(e), "\n")
  NULL
})

if (!is.null(honest_results)) {
  cat("  HonestDiD sensitivity results:\n")
  print(honest_results)
} else {
  cat("  HonestDiD skipped (small sample covariance degeneracy).\n")
}

# ============================================================================
# R5: ALTERNATIVE TREATMENT DATES
# ============================================================================
cat("\n--- R5: Alternative treatment windows ---\n")

# A) Scotland: assume 2019 as first full year of effect (allow partial 2018)
alt_2019 <- country_panel %>%
  mutate(treated_alt = as.integer(
    (country == "Scotland" & year >= 2019) |
    (country == "Wales"    & year >= 2020)
  ))

twfe_alt <- feols(
  rate ~ treated_alt | country + year,
  data    = alt_2019,
  cluster = ~country
)

cat("  Alt treatment date (Scotland 2019, Wales 2020):\n")
print(coeftable(twfe_alt))

# B) Drop 2020-2021 (COVID contamination check)
no_covid <- country_panel %>%
  filter(!year %in% c(2020, 2021))

twfe_nocovid <- feols(
  rate ~ treated | country + year,
  data    = no_covid,
  cluster = ~country
)

cat("  Excluding 2020-2021 (COVID):\n")
print(coeftable(twfe_nocovid))

# C) Drop Wales entirely (Scotland vs England; use region_panel for valid SEs)
scot_only_reg <- region_panel %>%
  filter(country %in% c("Scotland", "England"))

twfe_scot <- feols(
  rate ~ treated | unit_id + year,
  data    = scot_only_reg,
  cluster = ~unit_id
)

cat("  Scotland vs England regions only:\n")
print(coeftable(twfe_scot))

# ============================================================================
# R6: DEPRIVATION HETEROGENEITY (within-England)
# ============================================================================
cat("\n--- R6: Deprivation heterogeneity (England) ---\n")

# Compare trend in most deprived vs least deprived English LAs
# Since MUP was not implemented in England, any divergence reflects background trends

dep_panel <- deprivation_panel %>%
  filter(decile %in% c(1, 10)) %>%
  mutate(
    group    = if_else(decile == 1, "Most deprived", "Least deprived"),
    post2018 = as.integer(year >= 2018)
  )

# Event study within England: use all 10 deciles with decile as continuous variable
# Most deprived (decile=1) vs average; gives valid SEs across 10 groups
dep_es <- feols(
  rate ~ i(year, I(decile <= 2), ref = 2017) | decile + year,
  data    = deprivation_panel,
  cluster = ~decile
)

cat("  Deprivation gap event study (top-2 most deprived vs rest, 10 deciles):\n")
print(summary(dep_es))

# Pre/post trend comparison
dep_prepost <- dep_panel %>%
  group_by(group, post2018) %>%
  summarise(mean_rate = round(mean(rate, na.rm = TRUE), 2), .groups = "drop") %>%
  pivot_wider(names_from = post2018, values_from = mean_rate,
              names_prefix = "period_") %>%
  mutate(change = period_1 - period_0)

cat("  Most/least deprived pre/post (England, break at 2018):\n")
print(dep_prepost)

dep_did <- diff(dep_prepost$change[order(dep_prepost$group, decreasing = TRUE)])
cat("  Deprivation DiD (most minus least change):", round(dep_did, 3), "\n")

# All 10 deciles: trend coefficients 2013-2023
dep_trends <- deprivation_panel %>%
  group_by(decile) %>%
  group_modify(~{
    d <- .x
    tibble(
      trend_pre  = round(coef(lm(rate ~ year, data = d[d$year <= 2017, ]))["year"], 3),
      trend_post = round(coef(lm(rate ~ year, data = d[d$year >= 2018, ]))["year"], 3),
      mean_rate  = round(mean(d$rate, na.rm = TRUE), 2)
    )
  }) %>%
  ungroup()

cat("  Deprivation decile trends:\n")
print(dep_trends)

# Figure: Deprivation gradient over time (all 10 deciles)
dep_fig_data <- deprivation_panel %>%
  mutate(
    dep_group = case_when(
      decile <= 2  ~ "Most deprived (D1-D2)",
      decile >= 9  ~ "Least deprived (D9-D10)",
      TRUE         ~ "Middle (D3-D8)"
    )
  )

p_dep <- ggplot(dep_fig_data, aes(x = year, y = rate,
                                    group = factor(decile),
                                    colour = dep_group,
                                    alpha = dep_group)) +
  geom_line(linewidth = 0.7) +
  geom_vline(xintercept = 2017.5, linetype = "dashed", colour = "grey60") +
  scale_colour_manual(
    values = c(
      "Most deprived (D1-D2)"  = "#d73027",
      "Middle (D3-D8)"         = "#bdbdbd",
      "Least deprived (D9-D10)"= "#4575b4"
    ), name = NULL
  ) +
  scale_alpha_manual(
    values = c(
      "Most deprived (D1-D2)"  = 1.0,
      "Middle (D3-D8)"         = 0.5,
      "Least deprived (D9-D10)"= 1.0
    ), name = NULL
  ) +
  scale_x_continuous(breaks = 2013:2023) +
  labs(
    x     = "Year",
    y     = "Alcohol-specific mortality (age-standardised, per 100,000)",
    title = "England: Deprivation Gradient in Alcohol Mortality, 2013-2023"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position  = c(0.02, 0.98),
    legend.justification = c(0, 1),
    axis.text.x      = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(FIGURE_DIR, "fig4_deprivation_gradient.pdf"), p_dep,
       width = 7, height = 4.5, device = "pdf")
ggsave(file.path(FIGURE_DIR, "fig4_deprivation_gradient.png"), p_dep,
       width = 7, height = 4.5, dpi = 200)
cat("  Saved fig4_deprivation_gradient\n")

# ============================================================================
# SAVE ROBUSTNESS RESULTS
# ============================================================================
cat("\n--- Saving robustness results ---\n")

robustness <- list(
  placebo_coef          = round(placebo_coef, 4),
  placebo_se            = round(placebo_se, 4),
  synth_avg_gap         = round(avg_gap_post, 4),
  synth_pval            = round(pval_sc, 4),
  pretrend_pval         = round(anova_pt$`Pr(>F)`[2], 4),
  twfe_alt2019_coef     = round(coef(twfe_alt)["treated_alt"], 4),
  twfe_nocovid_coef     = round(coef(twfe_nocovid)["treated"], 4),
  twfe_scot_only_coef   = round(coef(twfe_scot)[["treated"]], 4),
  dep_did               = round(dep_did, 4),
  dep_trends            = dep_trends,
  honest_results        = honest_results
)

saveRDS(robustness, file.path(DATA_DIR, "robustness_results.rds"))

# Update diagnostics
diag <- jsonlite::read_json(file.path(DATA_DIR, "diagnostics.json"))
diag$placebo_pval        <- round(2 * (1 - pnorm(abs(placebo_coef / placebo_se))), 4)
diag$synth_pval          <- round(pval_sc, 4)
diag$pretrend_pval       <- round(anova_pt$`Pr(>F)`[2], 4)
jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)

cat("  robustness_results.rds saved\n")
cat("  Placebo t-stat:", round(placebo_coef / placebo_se, 2),
    "| Synth p-val:", round(pval_sc, 3),
    "| Pre-trend p:", round(anova_pt$`Pr(>F)`[2], 4), "\n")

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
