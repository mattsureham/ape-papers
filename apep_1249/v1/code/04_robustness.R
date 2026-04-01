## 04_robustness.R — Robustness checks and placebo tests

source("00_packages.R")

panel <- fread("../data/panel_clean.csv")
elec <- panel[industry == "electricity"]

cat("=== Robustness Checks ===\n\n")

# ---------------------------------------------------------------
# 1. PLACEBO OUTCOMES: non-electricity industries
# If the carbon tax operates through electricity generation costs,
# we should see effects in electricity but NOT in mining, manufacturing,
# or construction (which are not directly taxed via electricity generation)
# ---------------------------------------------------------------
cat("--- Placebo 1: Mining employment ---\n")
mining <- panel[industry == "mining"]
p_mining <- feols(log_emp ~ coal_x_tax + coal_x_post | state + yq,
                  data = mining, cluster = ~state)
summary(p_mining)

cat("\n--- Placebo 2: Manufacturing employment ---\n")
manuf <- panel[industry == "manufacturing"]
p_manuf <- feols(log_emp ~ coal_x_tax + coal_x_post | state + yq,
                 data = manuf, cluster = ~state)
summary(p_manuf)

cat("\n--- Placebo 3: Construction employment ---\n")
constr <- panel[industry == "construction"]
p_constr <- feols(log_emp ~ coal_x_tax + coal_x_post | state + yq,
                  data = constr, cluster = ~state)
summary(p_constr)

# ---------------------------------------------------------------
# 2. STATE-SPECIFIC LINEAR TRENDS
# ---------------------------------------------------------------
cat("\n--- Robustness: State-specific linear trends ---\n")
elec[, trend := yq - 2005]
r_trend <- feols(log_emp ~ coal_x_tax + coal_x_post | state + yq + state[trend],
                 data = elec, cluster = ~state)
summary(r_trend)

# ---------------------------------------------------------------
# 3. EXCLUDE SMALL STATES (ACT, NT — tiny electricity sectors)
# ---------------------------------------------------------------
cat("\n--- Robustness: Exclude ACT and NT ---\n")
elec_big <- elec[!state %in% c("ACT", "NT")]
r_big <- feols(log_emp ~ coal_x_tax + coal_x_post | state + yq,
               data = elec_big, cluster = ~state)
summary(r_big)

# ---------------------------------------------------------------
# 4. ALTERNATIVE TREATMENT WINDOWS
# Exclude transition quarters (Q3 2012 and Q3 2014)
# ---------------------------------------------------------------
cat("\n--- Robustness: Exclude transition quarters ---\n")
elec_notrans <- elec[!(yq %in% c(2012.5, 2014.5))]
r_notrans <- feols(log_emp ~ coal_x_tax + coal_x_post | state + yq,
                   data = elec_notrans, cluster = ~state)
summary(r_notrans)

# ---------------------------------------------------------------
# 5. LEVELS INSTEAD OF LOGS
# ---------------------------------------------------------------
cat("\n--- Robustness: Employment in levels ---\n")
r_levels <- feols(employment ~ coal_x_tax + coal_x_post | state + yq,
                  data = elec, cluster = ~state)
summary(r_levels)

# ---------------------------------------------------------------
# 6. TRIPLE DIFFERENCE: Electricity vs Manufacturing × Coal Share × Period
# Leverages within-state variation across industries
# ---------------------------------------------------------------
cat("\n--- Triple Difference: Electricity vs Manufacturing ---\n")
elec_manuf <- panel[industry %in% c("electricity", "manufacturing")]
elec_manuf[, is_elec := as.integer(industry == "electricity")]
elec_manuf[, elec_coal_tax := is_elec * coal_share * tax_period]
elec_manuf[, elec_coal_post := is_elec * coal_share * post_repeal]
# Also need two-way interactions
elec_manuf[, elec_tax := is_elec * tax_period]
elec_manuf[, elec_post := is_elec * post_repeal]
elec_manuf[, coal_tax := coal_share * tax_period]
elec_manuf[, coal_post := coal_share * post_repeal]

ddd <- feols(log_emp ~ elec_coal_tax + elec_coal_post +
               elec_tax + elec_post + coal_tax + coal_post |
               state_ind + yq,
             data = elec_manuf, cluster = ~state)
summary(ddd)

# ---------------------------------------------------------------
# 7. RANDOMIZATION INFERENCE
# Permute coal shares across states, re-estimate, compute p-value
# ---------------------------------------------------------------
cat("\n--- Randomization Inference (500 permutations) ---\n")
set.seed(42)
n_perm <- 500
beta_tax_obs <- coef(m1_base <- feols(log_emp ~ coal_x_tax + coal_x_post | state + yq,
                                       data = elec))["coal_x_tax"]
beta_post_obs <- coef(m1_base)["coal_x_post"]

states_unique <- unique(elec$state)
perm_tax <- numeric(n_perm)
perm_post <- numeric(n_perm)

for (i in 1:n_perm) {
  # Permute coal shares across states
  perm_map <- data.table(
    state = states_unique,
    coal_share_perm = sample(unique(elec[match(states_unique, state)]$coal_share))
  )
  elec_perm <- merge(elec, perm_map, by = "state")
  elec_perm[, coal_x_tax_p := coal_share_perm * tax_period]
  elec_perm[, coal_x_post_p := coal_share_perm * post_repeal]

  m_perm <- feols(log_emp ~ coal_x_tax_p + coal_x_post_p | state + yq,
                  data = elec_perm)
  perm_tax[i] <- coef(m_perm)["coal_x_tax_p"]
  perm_post[i] <- coef(m_perm)["coal_x_post_p"]
}

ri_pval_tax <- mean(abs(perm_tax) >= abs(beta_tax_obs))
ri_pval_post <- mean(abs(perm_post) >= abs(beta_post_obs))
cat("RI p-value (tax effect):", ri_pval_tax, "\n")
cat("RI p-value (post-repeal):", ri_pval_post, "\n")

# ---------------------------------------------------------------
# Save all robustness models
# ---------------------------------------------------------------
rob_models <- list(
  placebo_mining = p_mining,
  placebo_manuf = p_manuf,
  placebo_constr = p_constr,
  state_trends = r_trend,
  exclude_small = r_big,
  exclude_transition = r_notrans,
  levels = r_levels,
  ddd = ddd
)
saveRDS(rob_models, "../data/robustness_models.rds")

# Save RI results
ri_results <- list(
  beta_tax_obs = beta_tax_obs,
  beta_post_obs = beta_post_obs,
  ri_pval_tax = ri_pval_tax,
  ri_pval_post = ri_pval_post,
  n_permutations = n_perm
)
jsonlite::write_json(ri_results, "../data/ri_results.json", auto_unbox = TRUE)

cat("\n=== Robustness checks complete ===\n")
