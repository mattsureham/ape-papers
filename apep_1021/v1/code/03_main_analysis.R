# 03_main_analysis.R — Main regressions
# apep_1021: Latvia AML Shell-Company Ban

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

# ============================================================
# 1. Difference-in-Differences: Dissolution Rate
# ============================================================

# Create interaction terms
panel[, shell_x_riga := as.numeric(shell_likely) * as.numeric(riga)]
panel[, shell_x_post := as.numeric(shell_likely) * as.numeric(post)]
panel[, riga_x_post := as.numeric(riga) * as.numeric(post)]
panel[, triple := as.numeric(shell_likely) * as.numeric(riga) * as.numeric(post)]

# Group fixed effects
panel[, group_id := paste0(as.numeric(shell_likely), "_", as.numeric(riga))]

# --- Model 1: Simple DiD on treated group (SIA/Riga vs all others) ---
m1_diss <- feols(dissolution_rate ~ treated * post | group_id + ym,
                 data = panel, vcov = "hetero")

# --- Model 2: Triple-DiD (Shell x Riga x Post) ---
m2_diss <- feols(dissolution_rate ~ shell_likely:post + riga:post + triple | group_id + ym,
                 data = panel, vcov = "hetero")

# --- Model 3: Registration rate ---
m1_reg <- feols(registration_rate ~ treated * post | group_id + ym,
                data = panel, vcov = "hetero")

m2_reg <- feols(registration_rate ~ shell_likely:post + riga:post + triple | group_id + ym,
                data = panel, vcov = "hetero")

cat("=== DISSOLUTION RATE ===\n")
cat("\nModel 1: DiD (treated = SIA/Riga)\n")
summary(m1_diss)

cat("\nModel 2: Triple-DiD (Shell x Riga x Post)\n")
summary(m2_diss)

cat("\n=== REGISTRATION RATE ===\n")
cat("\nModel 1: DiD (treated = SIA/Riga)\n")
summary(m1_reg)

cat("\nModel 2: Triple-DiD (Shell x Riga x Post)\n")
summary(m2_reg)

# ============================================================
# 2. Event Study
# ============================================================

# Create event study indicators for treated group
# Omit t = -1 (January 2018)
panel[, rel_month_f := factor(rel_month)]
panel[, rel_month_f := relevel(rel_month_f, ref = "-1")]

# Event study: dissolution rate
es_diss <- feols(dissolution_rate ~ i(rel_month, treated, ref = -1) | group_id + ym,
                 data = panel, vcov = "hetero")

cat("\n=== EVENT STUDY: Dissolution Rate ===\n")
summary(es_diss)

# Event study: registration rate
es_reg <- feols(registration_rate ~ i(rel_month, treated, ref = -1) | group_id + ym,
                data = panel, vcov = "hetero")

cat("\n=== EVENT STUDY: Registration Rate ===\n")
summary(es_reg)

# ============================================================
# 3. Stock of active firms (level effect)
# ============================================================

# Log active firms
panel[, log_active := log(active_firms)]

m_active <- feols(log_active ~ treated * post | group_id + ym,
                  data = panel, vcov = "hetero")

cat("\n=== LOG ACTIVE FIRMS ===\n")
summary(m_active)

# Event study on log active firms
es_active <- feols(log_active ~ i(rel_month, treated, ref = -1) | group_id + ym,
                   data = panel, vcov = "hetero")

# ============================================================
# 4. Save results and diagnostics
# ============================================================

# Extract event study coefficients for tables
es_coefs_diss <- as.data.table(coeftable(es_diss))
es_coefs_diss[, variable := rownames(coeftable(es_diss))]

es_coefs_reg <- as.data.table(coeftable(es_reg))
es_coefs_reg[, variable := rownames(coeftable(es_reg))]

es_coefs_active <- as.data.table(coeftable(es_active))
es_coefs_active[, variable := rownames(coeftable(es_active))]

# Save model objects
save(m1_diss, m2_diss, m1_reg, m2_reg, m_active,
     es_diss, es_reg, es_active,
     file = "../data/main_models.RData")

# Diagnostics for validator
diag <- list(
  n_treated = 2L,  # 2 treated groups (SIA+Riga in pre and post)
  n_pre = as.integer(sum(panel$ym < as.Date("2018-02-01")) / 4),  # 37 pre-months x 4 groups
  n_obs = nrow(panel),
  n_active_firms_pre_treated = round(mean(panel[shell_likely == TRUE & riga == TRUE & !post, active_firms])),
  n_active_firms_pre_control = round(mean(panel[!(shell_likely & riga) & !post, active_firms])),
  treatment_date = "2018-02-01",
  outcome = "dissolution_rate_per_1000"
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\nModels saved to data/main_models.RData\n")
cat("Diagnostics saved to data/diagnostics.json\n")

# Print key results for verification
cat("\n=== KEY RESULTS ===\n")
cat(sprintf("DiD dissolution rate: %.2f (SE: %.2f, p: %.4f)\n",
            coef(m1_diss)["treatedTRUE:postTRUE"],
            se(m1_diss)["treatedTRUE:postTRUE"],
            pvalue(m1_diss)["treatedTRUE:postTRUE"]))
cat(sprintf("Triple-DiD dissolution rate: %.2f (SE: %.2f, p: %.4f)\n",
            coef(m2_diss)["triple"],
            se(m2_diss)["triple"],
            pvalue(m2_diss)["triple"]))
cat(sprintf("DiD registration rate: %.2f (SE: %.2f, p: %.4f)\n",
            coef(m1_reg)["treatedTRUE:postTRUE"],
            se(m1_reg)["treatedTRUE:postTRUE"],
            pvalue(m1_reg)["treatedTRUE:postTRUE"]))
cat(sprintf("Log active firms: %.3f (SE: %.3f, p: %.4f)\n",
            coef(m_active)["treatedTRUE:postTRUE"],
            se(m_active)["treatedTRUE:postTRUE"],
            pvalue(m_active)["treatedTRUE:postTRUE"]))
