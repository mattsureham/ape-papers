# 04_robustness.R — Robustness checks
# APEP paper apep_0784: OSHA Heat NEP

source("00_packages.R")

data_dir <- "../data/"
df <- fread(file.path(data_dir, "analysis_panel.csv"))

# Recreate standardized temperature
df[, temp_std := (avg_summer_temp - mean(avg_summer_temp, na.rm = TRUE)) /
     sd(avg_summer_temp, na.rm = TRUE)]
df[, did_temp := high_heat * post * temp_std]
df[, event_time := year - 2022]

cat("=== Robustness Checks ===\n\n")

# ============================================================
# 1. Restricted sample: 2019-2023 (shorter pre-treatment window)
# ============================================================
cat("--- R1: Restricted to 2019-2023 ---\n")

df_short <- df[year >= 2019]

r1_did <- feols(trc_rate ~ did | naics2 + state^year, data = df_short, cluster = ~state)
r1_triple <- feols(trc_rate ~ did + triple_did | naics2^state + state^year,
                   data = df_short, cluster = ~state)

cat(sprintf("  Simple DiD:  β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r1_did)["did"], se(r1_did)["did"], pvalue(r1_did)["did"]))
cat(sprintf("  Triple DiD:  β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r1_triple)["triple_did"], se(r1_triple)["triple_did"], pvalue(r1_triple)["triple_did"]))

# ============================================================
# 2. Excluding COVID years (2020-2021)
# ============================================================
cat("\n--- R2: Excluding 2020-2021 ---\n")

df_nocovid <- df[!(year %in% c(2020, 2021))]
df_nocovid[, post_nocovid := as.integer(year >= 2022)]
df_nocovid[, did_nocovid := high_heat * post_nocovid]
df_nocovid[, triple_nocovid := high_heat * post_nocovid * hot_state]

r2_did <- feols(trc_rate ~ did_nocovid | naics2 + state^year, data = df_nocovid, cluster = ~state)
r2_triple <- feols(trc_rate ~ did_nocovid + triple_nocovid | naics2^state + state^year,
                   data = df_nocovid, cluster = ~state)

cat(sprintf("  Simple DiD:  β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r2_did)["did_nocovid"], se(r2_did)["did_nocovid"], pvalue(r2_did)["did_nocovid"]))
cat(sprintf("  Triple DiD:  β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r2_triple)["triple_nocovid"], se(r2_triple)["triple_nocovid"],
            pvalue(r2_triple)["triple_nocovid"]))

# ============================================================
# 3. Federal OSHA states only (NEP directly applies)
# ============================================================
cat("\n--- R3: Federal OSHA States Only ---\n")

# State-plan states (have their own OSHA programs — may or may not adopt NEP):
# AK, AZ, CA, HI, IN, IA, KY, MD, MI, MN, NV, NM, NC, OR, SC, TN, UT, VA, VT, WA, WY
# Plus territories (PR, VI, GU)
state_plan <- c("AK","AZ","CA","HI","IN","IA","KY","MD","MI","MN",
                "NV","NM","NC","OR","SC","TN","UT","VA","VT","WA","WY")

df_federal <- df[!(state %in% state_plan)]

r3_did <- feols(trc_rate ~ did | naics2 + state^year, data = df_federal, cluster = ~state)
r3_triple <- feols(trc_rate ~ did + triple_did | naics2^state + state^year,
                   data = df_federal, cluster = ~state)

cat(sprintf("  Federal OSHA states: %d\n", uniqueN(df_federal$state)))
cat(sprintf("  Simple DiD:  β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r3_did)["did"], se(r3_did)["did"], pvalue(r3_did)["did"]))
cat(sprintf("  Triple DiD:  β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r3_triple)["triple_did"], se(r3_triple)["triple_did"],
            pvalue(r3_triple)["triple_did"]))

# ============================================================
# 4. Placebo test: State-plan states (NEP should NOT apply)
# ============================================================
cat("\n--- R4: State-Plan States (Placebo) ---\n")

df_stateplan <- df[state %in% state_plan]

r4_did <- feols(trc_rate ~ did | naics2 + state^year, data = df_stateplan, cluster = ~state)

cat(sprintf("  State-plan states: %d\n", uniqueN(df_stateplan$state)))
cat(sprintf("  Placebo DiD: β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r4_did)["did"], se(r4_did)["did"], pvalue(r4_did)["did"]))

# ============================================================
# 5. Heat terciles instead of median split
# ============================================================
cat("\n--- R5: Heat Terciles ---\n")

temp_terciles <- quantile(unique(df$avg_summer_temp), probs = c(1/3, 2/3), na.rm = TRUE)
df[, heat_tercile := cut(avg_summer_temp,
                          breaks = c(-Inf, temp_terciles[1], temp_terciles[2], Inf),
                          labels = c("Cool", "Moderate", "Hot"))]

df[, did_hot := high_heat * post * as.integer(heat_tercile == "Hot")]
df[, did_mod := high_heat * post * as.integer(heat_tercile == "Moderate")]

r5 <- feols(trc_rate ~ did + did_hot + did_mod | naics2^state + state^year,
            data = df, cluster = ~state)

cat(sprintf("  Base DiD:        β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r5)["did"], se(r5)["did"], pvalue(r5)["did"]))
cat(sprintf("  Hot tercile:     β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r5)["did_hot"], se(r5)["did_hot"], pvalue(r5)["did_hot"]))
cat(sprintf("  Moderate tercile: β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r5)["did_mod"], se(r5)["did_mod"], pvalue(r5)["did_mod"]))

# ============================================================
# 6. Alternative outcome: Death rate
# ============================================================
cat("\n--- R6: Death Rate ---\n")

df[, death_rate := (total_deaths / hours) * 200000]
df[death_rate > quantile(death_rate, 0.99, na.rm = TRUE), death_rate := quantile(death_rate, 0.99, na.rm = TRUE)]

r6 <- feols(death_rate ~ did | naics2 + state^year, data = df, cluster = ~state)

cat(sprintf("  Death rate DiD: β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(r6)["did"], se(r6)["did"], pvalue(r6)["did"]))

# ============================================================
# 7. Size-restricted sample (establishments with 250+ employees)
# ============================================================
cat("\n--- R7: Large Establishments Only (250+) ---\n")

df_large <- df[employees >= 250]

r7_did <- feols(trc_rate ~ did | naics2 + state^year, data = df_large, cluster = ~state)
r7_triple <- feols(trc_rate ~ did + triple_did | naics2^state + state^year,
                   data = df_large, cluster = ~state)

cat(sprintf("  N (large estab): %d\n", nrow(df_large)))
cat(sprintf("  Simple DiD:  β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r7_did)["did"], se(r7_did)["did"], pvalue(r7_did)["did"]))
cat(sprintf("  Triple DiD:  β = %.3f (SE = %.3f, p = %.3f)\n",
            coef(r7_triple)["triple_did"], se(r7_triple)["triple_did"],
            pvalue(r7_triple)["triple_did"]))

# ============================================================
# Save robustness models
# ============================================================
save(r1_did, r1_triple, r2_did, r2_triple, r3_did, r3_triple,
     r4_did, r5, r6, r7_did, r7_triple,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\n=== Robustness checks complete ===\n")
