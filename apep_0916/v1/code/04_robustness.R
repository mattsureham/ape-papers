# =============================================================================
# 04_robustness.R — Robustness checks
# Paper: When the Banks Broke (apep_0916)
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_clean.rds")
cat("Loaded:", nrow(df), "observations\n")

# ─────────────────────────────────────────────────────────────────────────────
# R1: Broader unit banking definition (includes limited branching states)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== R1: Broader Unit Banking Definition ===\n")

r1 <- feols(delta_occscore_20_40 ~ unit_banking_broad * ag_share + age_1920 + age_sq +
              white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
              region,
            data = df, vcov = ~statefip_1920)
cat("Broad UB × Ag:", round(coef(r1)["unit_banking_broad:ag_share"], 4),
    "se:", round(se(r1)["unit_banking_broad:ag_share"], 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# R2: SEI instead of OccScore
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== R2: SEI as Outcome ===\n")

r2 <- feols(delta_sei_20_40 ~ unit_banking * ag_share + age_1920 + age_sq +
              white + foreign_born + married_1920 + farmer_1920 + sei_1920 |
              region,
            data = df, vcov = ~statefip_1920)
cat("SEI (UB × Ag):", round(coef(r2)["unit_banking:ag_share"], 4),
    "se:", round(se(r2)["unit_banking:ag_share"], 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# R3: Exclude border states (states adjacent to unit banking boundaries)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== R3: Exclude Border States ===\n")
# Drop states that are borderline in classification
border_states <- c(18, 21, 5, 13, 26, 39, 46, 55)  # IN, KY, AR, GA, MI, OH, SD, WI
df_noborder <- df[!statefip_1920 %in% border_states]
r3 <- feols(delta_occscore_20_40 ~ unit_banking * ag_share + age_1920 + age_sq +
              white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
              region,
            data = df_noborder, vcov = ~statefip_1920)
cat("No borders (UB × Ag):", round(coef(r3)["unit_banking:ag_share"], 4),
    "se:", round(se(r3)["unit_banking:ag_share"], 4), "\n")
rm(df_noborder); gc()

# ─────────────────────────────────────────────────────────────────────────────
# R4: Restrict to stayers (non-movers 1920-1940)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== R4: Stayers Only ===\n")
df_stay <- df[mover_20_40 == 0]
r4 <- feols(delta_occscore_20_40 ~ unit_banking * ag_share + age_1920 + age_sq +
              white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
              region,
            data = df_stay, vcov = ~statefip_1920)
cat("Stayers (UB × Ag):", round(coef(r4)["unit_banking:ag_share"], 4),
    "se:", round(se(r4)["unit_banking:ag_share"], 4), "\n")
rm(df_stay); gc()

# ─────────────────────────────────────────────────────────────────────────────
# R5: White men only (race homogeneous sample)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== R5: White Men Only ===\n")
df_white <- df[white == 1]
r5 <- feols(delta_occscore_20_40 ~ unit_banking * ag_share + age_1920 + age_sq +
              foreign_born + married_1920 + farmer_1920 + occscore_1920 |
              region,
            data = df_white, vcov = ~statefip_1920)
cat("White men (UB × Ag):", round(coef(r5)["unit_banking:ag_share"], 4),
    "se:", round(se(r5)["unit_banking:ag_share"], 4), "\n")
rm(df_white); gc()

# ─────────────────────────────────────────────────────────────────────────────
# R6: Leave-one-out (drop largest unit banking state — Illinois)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== R6: Leave-One-Out (drop Illinois) ===\n")
df_noIL <- df[statefip_1920 != 17]
r6 <- feols(delta_occscore_20_40 ~ unit_banking * ag_share + age_1920 + age_sq +
              white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
              region,
            data = df_noIL, vcov = ~statefip_1920)
cat("No IL (UB × Ag):", round(coef(r6)["unit_banking:ag_share"], 4),
    "se:", round(se(r6)["unit_banking:ag_share"], 4), "\n")
rm(df_noIL); gc()

# ─────────────────────────────────────────────────────────────────────────────
# R7: Placebo — 1920→1930 change (pre-crisis decade)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== R7: Placebo (1920-1930, Roaring Twenties) ===\n")
df_slim <- df[, .(delta_occscore_20_30, unit_banking, ag_share, age_1920, age_sq,
                   white, foreign_born, married_1920, farmer_1920, occscore_1920,
                   region, statefip_1920)]
r7 <- feols(delta_occscore_20_30 ~ unit_banking * ag_share + age_1920 + age_sq +
              white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
              region,
            data = df_slim, vcov = ~statefip_1920)
cat("Placebo 1920-1930 (UB × Ag):", round(coef(r7)["unit_banking:ag_share"], 4),
    "se:", round(se(r7)["unit_banking:ag_share"], 4), "\n")
rm(df_slim); gc()

# ─────────────────────────────────────────────────────────────────────────────
# Save robustness models
# ─────────────────────────────────────────────────────────────────────────────
rob_models <- list(
  r1_broad = r1, r2_sei = r2, r3_noborder = r3,
  r4_stayers = r4, r5_white = r5, r6_noIL = r6, r7_placebo = r7
)
saveRDS(rob_models, "../data/robustness_models.rds")
cat("\nRobustness checks complete. Models saved.\n")
