# 04_robustness.R — Robustness checks and mechanism tests
# apep_0900: CBAM product-scope loophole

source("00_packages.R")

load("../data/main_results.RData")

# ========================================================
# TABLE 3: Robustness checks
# ========================================================

cat("=== ROBUSTNESS CHECKS ===\n\n")

# --- R1: Iron/steel only (drop aluminum) ---
hs4_fe <- panel_hs4[material == "iron_steel"]
hs4_fe[, hs4_partner := interaction(factor(hs4), factor(partner_code))]
hs4_fe[, hs4_year := interaction(factor(hs4), factor(year))]
hs4_fe[, partner_year := interaction(factor(partner_code), factor(year))]

r1 <- feols(log_value ~ covered:high_carbon:post + covered:post + high_carbon:post |
              hs4_partner + hs4_year + partner_year,
            data = hs4_fe, cluster = ~hs4_partner)
cat("R1 (Iron/steel only):\n")
print(summary(r1))

# --- R2: Broader post definition (2023+, capturing anticipation) ---
r2 <- feols(log_value ~ covered:high_carbon:post_broad + covered:post_broad + high_carbon:post_broad |
              hs4_partner + hs4_year + partner_year,
            data = panel_hs4[, `:=`(hs4_partner = interaction(factor(hs4), factor(partner_code)),
                                     hs4_year = interaction(factor(hs4), factor(year)),
                                     partner_year = interaction(factor(partner_code), factor(year)))],
            cluster = ~hs4_partner)
cat("\nR2 (Post = 2023+):\n")
print(summary(r2))

# --- R3: Drop Russia/Ukraine (sanctions confound) ---
hs4_nosanc <- panel_hs4[!partner_code %in% c("643", "804")]
hs4_nosanc[, hs4_partner := interaction(factor(hs4), factor(partner_code))]
hs4_nosanc[, hs4_year := interaction(factor(hs4), factor(year))]
hs4_nosanc[, partner_year := interaction(factor(partner_code), factor(year))]

r3 <- feols(log_value ~ covered:high_carbon:post + covered:post + high_carbon:post |
              hs4_partner + hs4_year + partner_year,
            data = hs4_nosanc, cluster = ~hs4_partner)
cat("\nR3 (Drop Russia + Ukraine):\n")
print(summary(r3))

# --- R4: Unit value (log price per kg) ---
panel_hs4[, unit_value := value_usd / qty_kg]
panel_hs4[, log_uv := log(unit_value + 1)]
panel_hs4[, hs4_partner2 := interaction(factor(hs4), factor(partner_code))]
panel_hs4[, hs4_year2 := interaction(factor(hs4), factor(year))]
panel_hs4[, partner_year2 := interaction(factor(partner_code), factor(year))]

r4 <- feols(log_uv ~ covered:high_carbon:post + covered:post + high_carbon:post |
              hs4_partner2 + hs4_year2 + partner_year2,
            data = panel_hs4[is.finite(log_uv)], cluster = ~hs4_partner2)
cat("\nR4 (Unit value):\n")
print(summary(r4))

# --- R5: Leave-one-partner-out ---
cat("\n=== LEAVE-ONE-PARTNER-OUT ===\n")
partners <- unique(panel_hs4$partner_code)
loo_results <- data.table()
for (p in partners) {
  loo_data <- panel_hs4[partner_code != p]
  loo_data[, hs4_partner_loo := interaction(factor(hs4), factor(partner_code))]
  loo_data[, hs4_year_loo := interaction(factor(hs4), factor(year))]
  loo_data[, partner_year_loo := interaction(factor(partner_code), factor(year))]
  loo_m <- feols(log_value ~ covered:high_carbon:post + covered:post + high_carbon:post |
                   hs4_partner_loo + hs4_year_loo + partner_year_loo,
                 data = loo_data, cluster = ~hs4_partner_loo)
  pname <- unique(panel_hs4[partner_code == p]$partner_name)[1]
  loo_results <- rbind(loo_results, data.table(
    dropped = pname,
    coef = coef(loo_m)["covered:high_carbon:post"],
    se = se(loo_m)["covered:high_carbon:post"]
  ))
}
print(loo_results)

# ========================================================
# MECHANISM: Relative shift within iron/steel chain
# ========================================================

cat("\n=== MECHANISM: HS72 vs HS73 raw means ===\n")
mech <- panel[material == "iron_steel",
              .(total_value_B = sum(value_usd) / 1e9),
              by = .(covered, high_carbon, year)][order(covered, high_carbon, year)]
print(mech)

# Compute share: HS73/(HS72+HS73) by partner type and year
shares <- panel[material == "iron_steel",
                .(total = sum(value_usd)),
                by = .(covered, high_carbon, year)]
shares_wide <- dcast(shares, high_carbon + year ~ covered, value.var = "total")
setnames(shares_wide, c("0", "1"), c("exempt", "covered"))
shares_wide[, downstream_share := exempt / (exempt + covered)]
cat("\nDownstream share (HS73 / (HS72+HS73)):\n")
print(shares_wide[order(high_carbon, year)])

# ========================================================
# POWER ANALYSIS: Minimum detectable effect
# ========================================================

cat("\n=== POWER ANALYSIS ===\n")
# From main HS4 specification (Model 4)
se_ddd <- se(m4)["covered:high_carbon:post"]
# MDE at 80% power, 5% significance: β_MDE = (1.96 + 0.84) × SE
mde <- 2.8 * se_ddd
cat(sprintf("SE of DDD: %.3f\n", se_ddd))
cat(sprintf("MDE (80%% power, 5%% sig): %.3f log points (%.1f%%)\n",
            mde, (exp(mde) - 1) * 100))
cat(sprintf("We can rule out effects larger than %.1f%% in either direction\n",
            (exp(mde) - 1) * 100))

# --- Save robustness results ---
save(r1, r2, r3, r4, loo_results, shares_wide, mde, se_ddd,
     file = "../data/robustness_results.RData")

cat("\n=== Robustness complete ===\n")
