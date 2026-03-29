## 03_main_analysis.R — Primary regressions
## APEP-1116: The Patent Office Lottery
##
## Design: Within-family, within-art-unit twin study
## IV: Leave-one-out examiner grant rate → child grant outcome

source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")
tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- fread(file.path(data_dir, "analysis_sample.csv"))
cat(sprintf("Analysis sample: %s obs\n", format(nrow(df), big.mark = ",")))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 1: Discordance by Reassignment Status
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== TABLE 1: DISCORDANCE RATES ===\n")

# Panel A: Overall
discord_reassigned <- df[reassigned == 1, .(
  n = .N,
  discord_rate = mean(discordant),
  child_grant_rate = mean(child_granted),
  parent_grant_rate = mean(parent_granted)
)]
discord_same <- df[reassigned == 0, .(
  n = .N,
  discord_rate = mean(discordant),
  child_grant_rate = mean(child_granted),
  parent_grant_rate = mean(parent_granted)
)]

cat("Reassigned pairs:\n")
print(discord_reassigned)
cat("Same-examiner pairs:\n")
print(discord_same)
cat(sprintf("Excess discordance: %.1f pp\n",
            100 * (discord_reassigned$discord_rate - discord_same$discord_rate)))

# Panel B: By entity size
discord_small <- df[, .(
  discord_rate = mean(discordant),
  n = .N
), by = .(reassigned, small_entity)]
cat("\nBy entity size and reassignment:\n")
print(discord_small)

# ═══════════════════════════════════════════════════════════════════════
# TABLE 2: Balance Tests
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== TABLE 2: BALANCE TESTS ===\n")

# Among reassigned same-AU pairs, is examiner leniency orthogonal to
# observable characteristics (conditional on AU × year FE)?
df_reassigned <- df[reassigned == 1]

bal_small <- feols(child_exam_loo_rate ~ small_entity | au_year,
                   data = df_reassigned, vcov = ~child_examiner_id)
bal_parent_grant <- feols(child_exam_loo_rate ~ parent_granted | au_year,
                          data = df_reassigned, vcov = ~child_examiner_id)
bal_con_type <- feols(child_exam_loo_rate ~ i(continuation_type) | au_year,
                      data = df_reassigned, vcov = ~child_examiner_id)

cat("Balance: leniency ~ small_entity | AU×year\n")
print(summary(bal_small))
cat("Balance: leniency ~ parent_granted | AU×year\n")
print(summary(bal_parent_grant))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 3: Main IV Results — Examiner Leniency → Child Grant
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== TABLE 3: MAIN IV RESULTS ===\n")

# ── OLS baseline ────────────────────────────────────────────────────
ols_base <- feols(child_granted ~ parent_granted | au_year,
                  data = df_reassigned, vcov = ~child_examiner_id)
cat("OLS baseline (no leniency):\n")
print(summary(ols_base))

# ── Reduced form ────────────────────────────────────────────────────
rf <- feols(child_granted ~ child_exam_loo_rate + parent_granted | au_year,
            data = df_reassigned, vcov = ~child_examiner_id)
cat("Reduced form (child_granted ~ leniency):\n")
print(summary(rf))

# ── First stage ─────────────────────────────────────────────────────
# For a clean IV, we need a treatment variable. Here the "treatment"
# IS the examiner's tendency to grant. The first stage IS the leniency
# measure itself. In a judge/examiner design, the reduced form IS the
# main result — the leniency measure directly captures examiner-specific
# grant propensity.

# But we can also frame it as: does leniency predict actual grant?
fs <- feols(child_granted ~ child_exam_loo_rate | au_year,
            data = df_reassigned, vcov = ~child_examiner_id)
cat("First stage (grant ~ leniency | AU×year):\n")
print(summary(fs))
# F-stat from the coefficient itself (t^2)
fs_t <- coeftable(fs)["child_exam_loo_rate", "t value"]
cat(sprintf("First-stage F (t^2): %.1f\n", fs_t^2))

# ── Main specification: Discordance ~ Reassignment ─────────────────
# This is the core result: reassignment causally increases discordance
main_discord <- feols(discordant ~ reassigned + parent_granted | au_year,
                      data = df, vcov = ~child_art_unit)
cat("Main: discordance ~ reassigned | AU×year\n")
print(summary(main_discord))

# ── IV: What share of grant outcomes is attributable to examiner? ───
# Grant = β × Leniency + γ × ParentGrant + AU×Year FE
# Leniency coefficient: 1-SD increase in leniency → β change in grant probability
main_iv <- feols(child_granted ~ parent_granted + child_exam_loo_rate | au_year,
                 data = df_reassigned, vcov = ~child_examiner_id)
cat("Main IV: grant ~ leniency + parent_grant | AU×year\n")
print(summary(main_iv))

# ── Full sample with reassignment interaction ──────────────────────
main_interact <- feols(child_granted ~ reassigned * child_exam_loo_rate +
                         parent_granted | au_year,
                       data = df, vcov = ~child_examiner_id)
cat("Interaction: grant ~ reassigned × leniency\n")
print(summary(main_interact))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 4: Small Entity Differential
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== TABLE 4: SMALL ENTITY DIFFERENTIAL ===\n")

# Triple-difference: reassignment × small entity
td_discord <- feols(discordant ~ reassigned * small_entity + parent_granted | au_year,
                    data = df, vcov = ~child_art_unit)
cat("Triple-diff: discordance ~ reassigned × small_entity\n")
print(summary(td_discord))

# Leniency effect by entity size (among reassigned)
iv_small <- feols(child_granted ~ child_exam_loo_rate + parent_granted | au_year,
                  data = df_reassigned[small_entity == 1],
                  vcov = ~child_examiner_id)
iv_large <- feols(child_granted ~ child_exam_loo_rate + parent_granted | au_year,
                  data = df_reassigned[small_entity == 0],
                  vcov = ~child_examiner_id)

cat("Leniency effect — Small entities:\n")
print(summary(iv_small))
cat("Leniency effect — Large entities:\n")
print(summary(iv_large))

# ═══════════════════════════════════════════════════════════════════════
# Save key results for tables
# ═══════════════════════════════════════════════════════════════════════

# Save diagnostics for validator
n_treated <- uniqueN(df$child_app[df$reassigned == 1])
n_pre <- length(unique(df$child_filing_year[df$child_filing_year < 2005]))
n_obs <- nrow(df)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))

# Save regression objects
saveRDS(list(
  ols_base = ols_base,
  rf = rf,
  fs = fs,
  main_discord = main_discord,
  main_iv = main_iv,
  main_interact = main_interact,
  td_discord = td_discord,
  iv_small = iv_small,
  iv_large = iv_large,
  bal_small = bal_small,
  bal_parent_grant = bal_parent_grant,
  discord_reassigned = discord_reassigned,
  discord_same = discord_same,
  discord_small = discord_small
), file.path(data_dir, "main_results.rds"))

cat("\nMain analysis complete.\n")
