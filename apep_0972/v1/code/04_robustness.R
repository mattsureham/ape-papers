# 04_robustness.R — Robustness checks and heterogeneity
# apep_0972: Craft brewery self-distribution deregulation

source("00_packages.R")

state_panel <- readRDS("../data/state_panel.rds")
county_entry <- readRDS("../data/county_entry.rds")
state_edu <- readRDS("../data/state_edu.rds")

sp312 <- state_panel %>% filter(industry == "312")

# ══════════════════════════════════════════════════════════════════════
# 1. PLACEBO: Apply treatment to NAICS 311 (Food Manufacturing)
# ══════════════════════════════════════════════════════════════════════
cat("=== Placebo: NAICS 311 ===\n")
sp311 <- state_panel %>% filter(industry == "311")

placebo_311 <- feols(log_emp ~ treated | statefips + time_id,
                     data = sp311, cluster = ~statefips)
summary(placebo_311)

# ══════════════════════════════════════════════════════════════════════
# 2. PRE-TREATMENT FALSIFICATION: Assign treatment 4 quarters early
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Pre-treatment falsification (4Q early) ===\n")
sp312_falsif <- sp312 %>%
  mutate(
    treat_yq_early = if_else(treat_yq > 0, treat_yq - 4L, 0L),
    treated_early = if_else(treat_yq_early > 0 & yq >= treat_yq_early, 1L, 0L)
  )

falsif_4q <- feols(log_emp ~ treated_early | statefips + time_id,
                   data = sp312_falsif, cluster = ~statefips)
summary(falsif_4q)

# ══════════════════════════════════════════════════════════════════════
# 3. EDUCATION HETEROGENEITY: by worker education level
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Education Heterogeneity ===\n")

# E1 = Less than HS, E2 = HS/GED, E3 = Some college, E4 = BA+
for (ed in c("E1", "E2", "E3", "E4")) {
  ed_data <- state_edu %>% filter(education == ed)
  if (nrow(ed_data) < 100) {
    cat(sprintf("  %s: too few observations (%d), skipping\n", ed, nrow(ed_data)))
    next
  }
  ed_model <- feols(log_emp ~ treated | statefips + time_id,
                    data = ed_data, cluster = ~statefips)
  cat(sprintf("  %s: coef=%.4f, SE=%.4f, p=%.4f (N=%d)\n",
              ed, coef(ed_model)["treated"], se(ed_model)["treated"],
              pvalue(ed_model)["treated"], nrow(ed_data)))
}

# ══════════════════════════════════════════════════════════════════════
# 4. ALTERNATIVE OUTCOME: Levels instead of logs
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Level specification ===\n")
m_level <- feols(Emp ~ treated | statefips + time_id,
                 data = sp312, cluster = ~statefips)
summary(m_level)

# ══════════════════════════════════════════════════════════════════════
# 5. RESTRICT TO 2005-2019 (avoid early data sparseness + COVID)
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Restricted sample: 2005-2019 ===\n")
sp312_r <- sp312 %>% filter(year >= 2005, year <= 2019)
m_restricted <- feols(log_emp ~ treated | statefips + time_id,
                      data = sp312_r, cluster = ~statefips)
summary(m_restricted)

# ══════════════════════════════════════════════════════════════════════
# 6. WILD CLUSTER BOOTSTRAP (few clusters check)
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Wild Cluster Bootstrap p-values ===\n")
# fixest has built-in wild cluster bootstrap
m_boot <- feols(log_emp ~ treated | statefips + time_id,
                data = sp312, cluster = ~statefips)
boot_pval <- tryCatch({
  # Use fixest's bootstrap
  b <- boot(m_boot, type = "wild", reps = 999, cluster = ~statefips)
  b
}, error = function(e) {
  cat("  Bootstrap error:", conditionMessage(e), "\n")
  NULL
})

# ══════════════════════════════════════════════════════════════════════
# 7. LEAVE-ONE-STATE-OUT
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Leave-one-state-out ===\n")
treated_states <- unique(sp312$statefips[sp312$treat_yq > 0])
loo_coefs <- sapply(treated_states, function(s) {
  d <- sp312 %>% filter(statefips != s)
  m <- feols(log_emp ~ treated | statefips + time_id, data = d, cluster = ~statefips)
  coef(m)["treated"]
})
names(loo_coefs) <- treated_states
cat(sprintf("  LOO range: [%.4f, %.4f]\n", min(loo_coefs), max(loo_coefs)))
cat(sprintf("  LOO mean: %.4f (full sample: %.4f)\n",
            mean(loo_coefs), coef(m_boot)["treated"]))

# ══════════════════════════════════════════════════════════════════════
# 8. MDE CALCULATION
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Minimum Detectable Effect ===\n")
# MDE at 80% power = 2.8 * SE
se_main <- se(m_boot)["treated"]
mde <- 2.8 * se_main
sd_y <- sd(sp312$log_emp)
mde_sde <- mde / sd_y
cat(sprintf("  SE(treated): %.4f\n", se_main))
cat(sprintf("  MDE (80%% power): %.4f log points\n", mde))
cat(sprintf("  MDE as %% of mean: %.1f%%\n", 100 * (exp(mde) - 1)))
cat(sprintf("  MDE as SDE: %.4f\n", mde_sde))

# Save robustness results
saveRDS(list(
  placebo_311 = placebo_311,
  falsif_4q = falsif_4q,
  m_level = m_level,
  m_restricted = m_restricted,
  loo_coefs = loo_coefs,
  mde = mde,
  mde_sde = mde_sde,
  sd_y = sd_y
), "../data/robustness_models.rds")

cat("\nRobustness checks complete.\n")
