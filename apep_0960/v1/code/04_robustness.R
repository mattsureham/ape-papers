## 04_robustness.R — Robustness checks for Zambia mining tax DiD
## apep_0960

source("00_packages.R")

df <- readRDS("../data/district_panel.rds")
df$event_time <- df$year - 2019

cat("=== Robustness Checks ===\n\n")

# ── 1. Short post-window (2019 only, pre-reversal) ──────────────────────
cat("--- R1: Short window (2019 only) ---\n")
df_short <- df %>% filter(year <= 2019)
r1 <- feols(asinh_ntl ~ mining_district:post | GID_2 + year,
            data = df_short, vcov = ~GID_2)
cat("Coef:", coef(r1)["mining_district:post"],
    " SE:", se(r1)["mining_district:post"], "\n")

# ── 2. Pre-COVID window (2012-2019) ─────────────────────────────────────
cat("\n--- R2: Pre-COVID window (to 2019) ---\n")
r2 <- feols(asinh_ntl ~ mining_district:post | GID_2 + year,
            data = df_short, vcov = ~GID_2)
cat("Same as R1 (2019 = post): coef =", coef(r2)["mining_district:post"], "\n")

# ── 3. Drop Lusaka (capital city outlier) ────────────────────────────────
cat("\n--- R3: Drop Lusaka Province ---\n")
r3 <- feols(asinh_ntl ~ mining_district:post | GID_2 + year,
            data = df %>% filter(NAME_1 != "Lusaka"), vcov = ~GID_2)
cat("Coef:", coef(r3)["mining_district:post"],
    " SE:", se(r3)["mining_district:post"], "\n")

# ── 4. Sum of lights (not mean) ─────────────────────────────────────────
cat("\n--- R4: Sum of lights ---\n")
df$asinh_ntl_sum <- asinh(df$ntl_sum)
r4 <- feols(asinh_ntl_sum ~ mining_district:post | GID_2 + year,
            data = df, vcov = ~GID_2)
cat("Coef:", coef(r4)["mining_district:post"],
    " SE:", se(r4)["mining_district:post"], "\n")

# ── 5. Placebo test: use 2016 as fake treatment date ─────────────────────
cat("\n--- R5: Placebo (fake treatment at 2016) ---\n")
df_placebo <- df %>% filter(year <= 2018)
df_placebo$post_fake <- as.integer(df_placebo$year >= 2016)
r5 <- feols(asinh_ntl ~ mining_district:post_fake | GID_2 + year,
            data = df_placebo, vcov = ~GID_2)
cat("Placebo coef:", coef(r5)["mining_district:post_fake"],
    " SE:", se(r5)["mining_district:post_fake"], "\n")

# ── 6. Mining province (broader treatment) ───────────────────────────────
cat("\n--- R6: Mining province treatment ---\n")
r6 <- feols(asinh_ntl ~ mining_province:post | GID_2 + year,
            data = df, vcov = ~GID_2)
cat("Coef:", coef(r6)["mining_province:post"],
    " SE:", se(r6)["mining_province:post"], "\n")

# ── 7. District-specific linear trends ───────────────────────────────────
cat("\n--- R7: District-specific linear trends ---\n")
r7 <- feols(asinh_ntl ~ mining_district:post | GID_2[year_c] + year,
            data = df, vcov = ~GID_2)
cat("Coef:", coef(r7)["mining_district:post"],
    " SE:", se(r7)["mining_district:post"], "\n")

# ── 8. NTL at 75th percentile (captures bright areas) ───────────────────
cat("\n--- R8: P75 of nightlights ---\n")
df$asinh_p75 <- asinh(df$ntl_p75)
r8 <- feols(asinh_p75 ~ mining_district:post | GID_2 + year,
            data = df, vcov = ~GID_2)
cat("Coef:", coef(r8)["mining_district:post"],
    " SE:", se(r8)["mining_district:post"], "\n")

# ── 9. Exclude NW Province (only Copperbelt as treated) ──────────────────
cat("\n--- R9: Copperbelt only (drop NW) ---\n")
df_cb <- df %>% filter(NAME_1 != "North-Western")
r9 <- feols(asinh_ntl ~ copperbelt:post | GID_2 + year,
            data = df_cb, vcov = ~GID_2)
cat("Coef:", coef(r9)["copperbelt:post"],
    " SE:", se(r9)["copperbelt:post"], "\n")

# ── 10. Randomization inference ──────────────────────────────────────────
cat("\n--- R10: Randomization Inference ---\n")
set.seed(42)
n_perm <- 1000
true_coef <- as.numeric(coef(feols(asinh_ntl ~ mining_district:post | GID_2 + year,
                                    data = df)))

# Permute treatment assignment across districts
districts <- unique(df$GID_2)
n_treated <- sum(df$mining_district[df$year == 2019])

perm_coefs <- numeric(n_perm)
for (i in 1:n_perm) {
  fake_treated <- sample(districts, n_treated)
  df$fake_mining <- as.integer(df$GID_2 %in% fake_treated)
  m_perm <- feols(asinh_ntl ~ fake_mining:post | GID_2 + year, data = df)
  perm_coefs[i] <- coef(m_perm)["fake_mining:post"]
}

ri_pval <- mean(abs(perm_coefs) >= abs(true_coef))
cat("RI p-value (two-sided):", ri_pval, "\n")
cat("RI 5th/95th percentiles:", quantile(perm_coefs, c(0.025, 0.975)), "\n")

saveRDS(list(perm_coefs = perm_coefs, true_coef = true_coef, ri_pval = ri_pval),
        "../data/ri_result.rds")

# ── Summary table ────────────────────────────────────────────────────────
cat("\n=== Robustness Summary ===\n")
rob_summary <- tibble(
  spec = c("Main", "Short window", "Drop Lusaka", "Sum NTL",
           "Placebo 2016", "Mining province", "District trends",
           "P75 NTL", "Copperbelt only"),
  coef = c(
    coef(feols(asinh_ntl ~ mining_district:post | GID_2 + year, data = df)),
    coef(r1)["mining_district:post"],
    coef(r3)["mining_district:post"],
    coef(r4)["mining_district:post"],
    coef(r5)["mining_district:post_fake"],
    coef(r6)["mining_province:post"],
    coef(r7)["mining_district:post"],
    coef(r8)["mining_district:post"],
    coef(r9)["copperbelt:post"]
  )
)
print(rob_summary)

# Save all robustness models
saveRDS(list(r1=r1, r3=r3, r4=r4, r5=r5, r6=r6, r7=r7, r8=r8, r9=r9,
             ri_pval=ri_pval),
        "../data/robustness_models.rds")

cat("\n=== Robustness complete ===\n")
