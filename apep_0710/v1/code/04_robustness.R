# 04_robustness.R — Robustness checks and validity tests
# apep_0710: Ukraine ProZorro Procurement Thresholds

source("00_packages.R")

df <- readRDS("../data/prozorro_clean.rds")
load("../data/models.RData")

bw <- 100000
df_bw <- df %>% filter(abs(running) <= bw)

cat("\n=== ROBUSTNESS CHECKS ===\n")

# ══════════════════════════════════════════════════════════════════
# 1. McCrary Density Test
# ══════════════════════════════════════════════════════════════════

cat("\n--- McCrary Density Test ---\n")
cat("Pre-war:\n")
df_pre <- df %>% filter(post == 0)
dens_pre <- rddensity(X = df_pre$running, c = 0)
summary(dens_pre)

cat("Post-war:\n")
df_post <- df %>% filter(post == 1)
dens_post <- rddensity(X = df_post$running, c = 0)
summary(dens_post)

# ══════════════════════════════════════════════════════════════════
# 2. Bandwidth Sensitivity
# ══════════════════════════════════════════════════════════════════

cat("\n--- Bandwidth Sensitivity ---\n")

bandwidths <- c(50000, 75000, 100000, 125000, 150000)
bw_results <- list()

for (h in bandwidths) {
  df_h <- df %>% filter(abs(running) <= h, !is.na(savings_pct))
  if (nrow(df_h) > 100) {
    mod <- feols(
      savings_pct ~ above * post + running + running:above |
        region_en + year,
      data = df_h,
      vcov = ~region_en
    )
    bw_results[[as.character(h)]] <- list(
      bw = h,
      coef = coef(mod)["above:post"],
      se = se(mod)["above:post"],
      n = nrow(df_h)
    )
    cat(sprintf("  BW ±%dK: β = %.2f (SE = %.2f), N = %d\n",
                h / 1000, coef(mod)["above:post"], se(mod)["above:post"], nrow(df_h)))
  }
}

# ══════════════════════════════════════════════════════════════════
# 3. Placebo Cutoffs
# ══════════════════════════════════════════════════════════════════

cat("\n--- Placebo Cutoffs ---\n")

placebo_cutoffs <- c(100000, 150000, 250000, 300000, 350000)
for (pc in placebo_cutoffs) {
  df_p <- df_pre %>%
    mutate(running_p = value_uah - pc, above_p = as.integer(value_uah > pc)) %>%
    filter(abs(running_p) <= bw, !is.na(savings_pct))

  if (nrow(df_p) > 50) {
    rd_p <- tryCatch(
      rdrobust(y = df_p$savings_pct, x = df_p$running_p, c = 0),
      error = function(e) NULL
    )
    if (!is.null(rd_p)) {
      cat(sprintf("  Cutoff %dK: τ = %.2f (p = %.3f), N_eff = %d\n",
                  pc / 1000, rd_p$coef[1], rd_p$pv[3], rd_p$N_h[1] + rd_p$N_h[2]))
    }
  }
}

# ══════════════════════════════════════════════════════════════════
# 4. Placebo Outcomes: Western Oblasts Only (remote from conflict)
# ══════════════════════════════════════════════════════════════════

cat("\n--- Placebo: Western Oblasts ---\n")
western <- c("Lviv", "Ivano-Frankivsk", "Zakarpattia", "Ternopil", "Volyn")
df_west <- df_bw %>%
  filter(region_en %in% western, !is.na(savings_pct))

if (nrow(df_west) > 50) {
  west_did <- feols(
    savings_pct ~ above * post + running + running:above,
    data = df_west,
    vcov = "hetero"
  )
  cat("Western oblasts diff-in-disc:\n")
  summary(west_did)
} else {
  cat("Insufficient western oblast data.\n")
}

# ══════════════════════════════════════════════════════════════════
# 5. Alternative Functional Forms
# ══════════════════════════════════════════════════════════════════

cat("\n--- Alternative Specifications ---\n")

df_bw_sav <- df_bw %>% filter(!is.na(savings_pct))

if (nrow(df_bw_sav) > 100) {
  # Quadratic in running variable
  quad_spec <- feols(
    savings_pct ~ above * post + running + I(running^2) +
      running:above + I(running^2):above |
      region_en + year,
    data = df_bw_sav,
    vcov = ~region_en
  )
  cat("Quadratic specification:\n")
  cat(sprintf("  above:post = %.2f (SE = %.2f)\n",
              coef(quad_spec)["above:post"], se(quad_spec)["above:post"]))

  # No fixed effects
  no_fe <- feols(
    savings_pct ~ above * post + running + running:above,
    data = df_bw_sav,
    vcov = "hetero"
  )
  cat("No fixed effects:\n")
  cat(sprintf("  above:post = %.2f (SE = %.2f)\n",
              coef(no_fe)["above:post"], se(no_fe)["above:post"]))
}

# ══════════════════════════════════════════════════════════════════
# 6. Summary Statistics Table
# ══════════════════════════════════════════════════════════════════

cat("\n--- Summary Statistics ---\n")

summ <- df %>%
  group_by(period = ifelse(post == 0, "Pre-war", "Post-war")) %>%
  summarise(
    N = n(),
    Mean_Value = mean(value_uah, na.rm = TRUE),
    SD_Value = sd(value_uah, na.rm = TRUE),
    Mean_Savings = mean(savings_pct, na.rm = TRUE),
    SD_Savings = sd(savings_pct, na.rm = TRUE),
    Mean_Bids = mean(n_bids, na.rm = TRUE),
    Pct_Competitive = mean(is_competitive, na.rm = TRUE) * 100,
    Pct_Frontline = mean(frontline, na.rm = TRUE) * 100,
    N_Oblasts = n_distinct(region_en),
    .groups = "drop"
  )

print(summ)

# By above/below threshold
summ2 <- df %>%
  group_by(
    Period = ifelse(post == 0, "Pre-war", "Post-war"),
    Threshold = ifelse(above == 1, "Above 200K", "Below 200K")
  ) %>%
  summarise(
    N = n(),
    Mean_Savings = mean(savings_pct, na.rm = TRUE),
    Mean_Bids = mean(n_bids, na.rm = TRUE),
    Pct_Competitive = mean(is_competitive, na.rm = TRUE) * 100,
    .groups = "drop"
  )

print(summ2)

cat("\nRobustness checks complete.\n")

# Save bandwidth sensitivity results
saveRDS(bw_results, "../data/bw_sensitivity.rds")
