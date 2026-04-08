## 03_main_analysis.R
## apep_1428: Does Financial Parity Follow Legal Parity?
## Main DDD analysis: female × post × income_source

source("code/00_packages.R")
# Explicitly use fixest functions to avoid scales::pvalue conflict
pvalue <- fixest::pvalue
se <- fixest::se

df_mayor_long <- readRDS("data/df_mayor_long.rds")
df_long <- readRDS("data/df_long.rds")
df <- readRDS("data/df_clean.rds")

## ── Model 1: DDD — female × post × party_source (mayors only) ─────────────
# Primary specification: within-candidate triple difference
# β7(female × post × is_party_source) is the DDD estimate
# Interpretation: did parity mandate specifically narrow the party-transfer gender gap
# relative to the sympathizer/self-finance gender gap?

# Restrict to party_transfer vs sympathizer (main DDD)
df_ddd <- df_mayor_long %>%
  filter(income_source %in% c("party_transfer", "sympathizer"))

cat("DDD sample (mayor × party/sympathizer):", nrow(df_ddd), "obs\n")

# DDD specification with party × state FE
m1_ddd <- feols(
  log_amount ~ female * post * is_party_source | party_state,
  data = df_ddd,
  cluster = ~ state
)

cat("\n== Model 1: DDD (female × post × party_source) ==\n")
print(summary(m1_ddd))

## ── Model 2: DDD with self-financing as alternative placebo ────────────────
df_ddd2 <- df_mayor_long %>%
  filter(income_source %in% c("party_transfer", "self_finance"))

m2_ddd_selffinance <- feols(
  log_amount ~ female * post * is_party_source | party_state,
  data = df_ddd2,
  cluster = ~ state
)

cat("\n== Model 2: DDD with self-finance placebo ==\n")
print(summary(m2_ddd_selffinance))

## ── Model 3: Simple female × post DiD (party transfers only) ───────────────
df_party_only <- df_mayor_long %>%
  filter(income_source == "party_transfer")

m3_did <- feols(
  log_amount ~ female * post | party_state,
  data = df_party_only,
  cluster = ~ state
)

cat("\n== Model 3: Simple DiD (party transfers only) ==\n")
print(summary(m3_did))

## ── Model 4: Sympathizer placebo ───────────────────────────────────────────
df_simpatiz_only <- df_mayor_long %>%
  filter(income_source == "sympathizer")

m4_placebo <- feols(
  log_amount ~ female * post | party_state,
  data = df_simpatiz_only,
  cluster = ~ state
)

cat("\n== Model 4: Sympathizer placebo ==\n")
print(summary(m4_placebo))

## ── Model 5: All offices (office-type robustness) ──────────────────────────
df_all_party <- df_long %>%
  filter(income_source == "party_transfer",
         office_type %in% c("MAYOR", "LEGISLATOR"))

m5_all_offices <- feols(
  log_amount ~ female * post * is_mayor | party_state + office_type,
  data = df_all_party,
  cluster = ~ state
)

cat("\n== Model 5: All offices DDD (female × post × is_mayor) ==\n")
print(summary(m5_all_offices))

## ── Extract key estimates for paper ────────────────────────────────────────
key_estimates <- list(
  ddd_main = coef(m1_ddd)["female:post:is_party_source"],
  ddd_se   = se(m1_ddd)["female:post:is_party_source"],
  ddd_p    = pvalue(m1_ddd)["female:post:is_party_source"],
  did_party = coef(m3_did)["female:post"],
  did_party_se = se(m3_did)["female:post"],
  did_party_p  = pvalue(m3_did)["female:post"],
  placebo_simpatiz = coef(m4_placebo)["female:post"],
  placebo_se = se(m4_placebo)["female:post"],
  placebo_p  = pvalue(m4_placebo)["female:post"]
)

cat("\n=== KEY ESTIMATES ===\n")
cat(sprintf("DDD estimate (main): β7 = %.3f (SE=%.3f, p=%.3f)\n",
            key_estimates$ddd_main, key_estimates$ddd_se, key_estimates$ddd_p))
cat(sprintf("DiD party transfers: β = %.3f (SE=%.3f, p=%.3f)\n",
            key_estimates$did_party, key_estimates$did_party_se, key_estimates$did_party_p))
cat(sprintf("Placebo sympathizer: β = %.3f (SE=%.3f, p=%.3f)\n",
            key_estimates$placebo_simpatiz, key_estimates$placebo_se, key_estimates$placebo_p))

## ── Write diagnostics.json ─────────────────────────────────────────────────
n_female <- sum(df$female == 1 & df$office_type == "MAYOR")
n_obs_ddd <- nrow(df_ddd)

diagnostics <- list(
  n_treated = n_female,   # female mayoral candidates
  n_obs     = n_obs_ddd,  # observations in main DDD
  method    = "DDD"       # triple difference; n_pre not applicable
)

jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics written:\n")
cat(jsonlite::toJSON(diagnostics, pretty = TRUE, auto_unbox = TRUE), "\n")

## ── Save model objects ─────────────────────────────────────────────────────
saveRDS(list(m1=m1_ddd, m2=m2_ddd_selffinance, m3=m3_did,
             m4=m4_placebo, m5=m5_all_offices,
             key=key_estimates), "data/models.rds")

cat("\nMain analysis complete.\n")
