## 03_main_analysis.R — Main DiD analysis
## APEP apep_1331: The No-Advice Trap

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

cat("=== MAIN ANALYSIS: Contingent Charging Ban DiD ===\n\n")

# ============================================================
# 1. Primary specification: TWFE DiD
# Y_pt = alpha_p + gamma_t + beta*(Treated_p * Post_t) + eps_pt
# ============================================================

# Specification 1: Level (new complaints)
m1_level <- feols(new_complaints ~ did | product_category + time_index,
                  data = panel)

# Specification 2: Log (new complaints)
m1_log <- feols(ln_complaints ~ did | product_category + time_index,
                data = panel)

# Specification 3: Uphold rate (quality of advice indicator)
panel_uphold <- panel %>% filter(!is.na(uphold_rate))
m1_uphold <- feols(uphold_rate ~ did | product_category + time_index,
                   data = panel_uphold)

cat("=== PRIMARY RESULTS ===\n")
cat("\n--- Model 1: Level (New Complaints) ---\n")
summary(m1_level)
cat("\n--- Model 2: Log (New Complaints) ---\n")
summary(m1_log)
cat("\n--- Model 3: Uphold Rate ---\n")
summary(m1_uphold)

# ============================================================
# 2. Permutation inference (randomize which product is "treated")
# With 4 products, there are 4 possible assignments
# ============================================================

cat("\n=== PERMUTATION INFERENCE ===\n")

products <- unique(panel$product_category)
n_products <- length(products)

perm_coefs <- numeric(n_products)
names(perm_coefs) <- products

for (i in seq_along(products)) {
  perm_data <- panel %>%
    mutate(
      perm_treated = as.integer(product_category == products[i]),
      perm_did = perm_treated * post
    )
  perm_model <- feols(new_complaints ~ perm_did | product_category + time_index,
                      data = perm_data)
  perm_coefs[i] <- coef(perm_model)["perm_did"]
}

actual_coef <- coef(m1_level)["did"]
perm_pvalue <- mean(abs(perm_coefs) >= abs(actual_coef))

cat(sprintf("Actual DiD coefficient: %.1f\n", actual_coef))
cat("Permutation coefficients:\n")
for (p in names(perm_coefs)) {
  cat(sprintf("  %s as treated: %.1f\n", p, perm_coefs[p]))
}
cat(sprintf("Permutation p-value (|coef| >= |actual|): %.3f\n", perm_pvalue))

# ============================================================
# 3. Event study: quarterly leads and lags
# ============================================================

cat("\n=== EVENT STUDY ===\n")

# Create event-time variable
# Treatment at time_index = 2020.75 (Q4 cal 2020 = Oct-Dec 2020)
panel <- panel %>%
  mutate(
    event_time = round((time_index - 2020.75) * 4),  # quarters relative to ban
    # Bin extreme leads/lags
    event_time_bin = case_when(
      event_time <= -8 ~ -8L,
      event_time >= 8 ~ 8L,
      TRUE ~ as.integer(event_time)
    )
  )

# Drop one pre-period for normalization (t = -1)
panel_es <- panel %>% filter(event_time_bin != -1)

m_es <- feols(new_complaints ~ i(event_time_bin, treated, ref = -1) |
                product_category + time_index,
              data = panel)

cat("Event study coefficients:\n")
print(summary(m_es))

# Extract event study coefficients for table
es_coefs <- data.frame(
  event_time = as.numeric(gsub(".*::", "", names(coef(m_es)))),
  coef = coef(m_es),
  se = sqrt(diag(vcov(m_es)))
) %>%
  arrange(event_time)

cat("\nEvent study table:\n")
print(es_coefs)

# ============================================================
# 4. Save results for tables
# ============================================================

results <- list(
  m1_level = m1_level,
  m1_log = m1_log,
  m1_uphold = m1_uphold,
  perm_coefs = perm_coefs,
  perm_pvalue = perm_pvalue,
  event_study = m_es,
  es_coefs = es_coefs
)

saveRDS(results, "../data/main_results.rds")

# ============================================================
# 5. Diagnostics for validator
# ============================================================

diag <- list(
  n_treated = 1,  # 1 product category
  n_pre = 21,     # 21 pre-ban quarters
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat(sprintf("N observations: %d\n", nrow(panel)))
cat(sprintf("N products: %d\n", n_products))
cat(sprintf("N quarters: %d\n", length(unique(panel$time_index))))
cat(sprintf("Pre-ban quarters: %d\n", sum(unique(panel$time_index) < 2020.75)))
cat(sprintf("Post-ban quarters: %d\n", sum(unique(panel$time_index) >= 2020.75)))

# Pre-treatment SD of outcome for SDE calculation
pre_sd <- sd(panel$new_complaints[panel$post == 0])
pre_sd_treated <- sd(panel$new_complaints[panel$post == 0 & panel$treated == 1])
cat(sprintf("Pre-treatment SD (all): %.1f\n", pre_sd))
cat(sprintf("Pre-treatment SD (treated): %.1f\n", pre_sd_treated))
cat(sprintf("DiD coefficient: %.1f (SE: %.1f)\n",
            actual_coef, sqrt(diag(vcov(m1_level)))["did"]))
cat(sprintf("SDE (using all SD): %.3f\n", actual_coef / pre_sd))
cat(sprintf("SDE (using treated SD): %.3f\n", actual_coef / pre_sd_treated))

cat("\nMain analysis complete.\n")
