# =============================================================================
# 04_robustness.R — Placebo tests, NC repeal, heterogeneity
# apep_1094: Film Tax Credits and Racial Employment Gains
# =============================================================================

source("00_packages.R")

panel_all   <- readRDS("../data/panel_all.rds")
panel_black <- readRDS("../data/panel_black.rds")
panel_722   <- readRDS("../data/panel_722.rds")
results     <- readRDS("../data/results.rds")

# =============================================================================
# 1. Placebo: NAICS 722 (Food Services) — should show no effect
# =============================================================================
cat("Running placebo test: NAICS 722 (Food Services)...\n")

# Need treatment info for 722 panel
film_credits <- readRDS("../data/film_credits.rds")
# panel_722 already has treatment info and state_id from 02_clean_data.R
panel_722_all <- panel_722 %>%
  filter(race == "A0")

placebo_722 <- att_gt(
  yname  = "log_emp",
  tname  = "period",
  idname = "state_id",
  gname  = "first_treat",
  data   = panel_722_all %>% filter(first_treat >= 0),
  control_group = "nevertreated",
  allow_unbalanced_panel = TRUE,
  base_period = "universal"
)
agg_722 <- aggte(placebo_722, type = "simple", na.rm = TRUE)
cat(sprintf("  Placebo ATT (NAICS 722): %.4f (SE: %.4f)\n",
            agg_722$overall.att, agg_722$overall.se))

# =============================================================================
# 2. North Carolina repeal event study (2014 removal)
# =============================================================================
cat("Running NC repeal analysis...\n")

# Before/after NC credit repeal in 2014
# Use GA as treated (kept credit) vs NC (repealed)
nc_ga <- panel_all %>%
  filter(state_abbr %in% c("NC", "GA")) %>%
  mutate(
    repeal_post = year >= 2014,
    is_nc = state_abbr == "NC"
  )

# Simple DiD: NC lost employment relative to GA after 2014
# With only 2 states, use period FE only (state FE absorbs is_nc)
nc_repeal <- feols(log_emp ~ is_nc + repeal_post + is_nc:repeal_post | period,
                   data = nc_ga, cluster = ~state_abbr)
cat("  NC repeal DiD (NC vs GA):\n")
print(summary(nc_repeal))

# =============================================================================
# 3. Heterogeneity: High vs Low pre-treatment Black employment share
# =============================================================================
cat("Running heterogeneity by pre-treatment Black share...\n")

black_share_pre <- readRDS("../data/black_share_pre.rds")

# Split sample
high_black_states <- black_share_pre$state_abbr[black_share_pre$high_black]
low_black_states  <- black_share_pre$state_abbr[!black_share_pre$high_black]

# Run CS-DiD on each subsample (using Black employment, race A2)
# Include never-treated in both samples for controls
never_treated_states <- panel_black$state_abbr[panel_black$first_treat == 0]
high_sample <- c(high_black_states, unique(never_treated_states))
low_sample  <- c(low_black_states, unique(never_treated_states))

cs_high <- att_gt(
  yname  = "log_emp",
  tname  = "period",
  idname = "state_id",
  gname  = "first_treat",
  data   = panel_black %>%
    filter(first_treat >= 0, state_abbr %in% high_sample),
  control_group = "nevertreated",
  allow_unbalanced_panel = TRUE,
  base_period = "universal"
)
agg_high <- aggte(cs_high, type = "simple", na.rm = TRUE)

cs_low <- att_gt(
  yname  = "log_emp",
  tname  = "period",
  idname = "state_id",
  gname  = "first_treat",
  data   = panel_black %>%
    filter(first_treat >= 0, state_abbr %in% low_sample),
  control_group = "nevertreated",
  allow_unbalanced_panel = TRUE,
  base_period = "universal"
)
agg_low <- aggte(cs_low, type = "simple", na.rm = TRUE)

cat(sprintf("  High Black share ATT: %.4f (SE: %.4f)\n",
            agg_high$overall.att, agg_high$overall.se))
cat(sprintf("  Low Black share ATT: %.4f (SE: %.4f)\n",
            agg_low$overall.att, agg_low$overall.se))

# =============================================================================
# 4. Randomization inference (permute treatment assignment)
# =============================================================================
cat("Running randomization inference for main result...\n")

# Observed TWFE coefficient
twfe_obs <- feols(log_emp ~ post | state_abbr + period,
                  data = panel_all, cluster = ~state_abbr)
obs_coef <- coef(twfe_obs)["postTRUE"]

# Permutation test: randomly reassign treatment assignment across states
set.seed(42)
n_perms <- 999
perm_coefs <- numeric(n_perms)

# Get unique state-level treatment assignments
state_treat <- panel_all %>%
  distinct(state_id, first_treat) %>%
  arrange(state_id)

for (i in 1:n_perms) {
  # Shuffle first_treat across states
  shuffled <- sample(state_treat$first_treat)
  perm_map <- data.frame(state_id = state_treat$state_id, perm_ft = shuffled)

  perm_df <- panel_all %>%
    left_join(perm_map, by = "state_id") %>%
    mutate(perm_post = perm_ft > 0 & period >= perm_ft)

  perm_fit <- feols(log_emp ~ perm_post | state_id + period,
                    data = perm_df, cluster = ~state_id)
  perm_coefs[i] <- coef(perm_fit)["perm_postTRUE"]
}

ri_pval <- mean(abs(perm_coefs) >= abs(obs_coef))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_pval))
cat(sprintf("  Observed coef: %.4f, RI 95th percentile: %.4f\n",
            obs_coef, quantile(abs(perm_coefs), 0.95)))

# =============================================================================
# Save robustness results
# =============================================================================
robustness <- list(
  placebo_722 = list(att = agg_722$overall.att, se = agg_722$overall.se),
  nc_repeal = nc_repeal,
  het_high_black = list(att = agg_high$overall.att, se = agg_high$overall.se),
  het_low_black = list(att = agg_low$overall.att, se = agg_low$overall.se),
  ri_pval = ri_pval,
  ri_obs_coef = obs_coef
)

saveRDS(robustness, "../data/robustness.rds")
cat("\nRobustness checks saved.\n")
