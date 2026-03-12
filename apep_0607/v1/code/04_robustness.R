# 04_robustness.R — Robustness checks and placebo tests
# APEP Working Paper apep_0607

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
panel <- panel %>%
  mutate(event_time = year - 2012)

cat("Panel loaded:", nrow(panel), "obs\n")

# ============================================================
# 1. Placebo Test: Fake treatment in 2009
# ============================================================
cat("\n=== Placebo Test: Fake Treatment in 2009 ===\n")

panel_pre <- panel %>% filter(year <= 2011)
panel_pre <- panel_pre %>%
  mutate(
    fake_post = as.integer(year >= 2009),
    fake_treatment = farming_share_2008 * fake_post
  )

placebo_soy <- feols(log_soy_area ~ fake_treatment | muni_code_6 + state_year,
                     data = panel_pre, cluster = ~muni_code_6)
placebo_cattle <- feols(log_cattle ~ fake_treatment | muni_code_6 + state_year,
                        data = panel_pre, cluster = ~muni_code_6)

cat("Placebo (soy)    — coef:", round(coef(placebo_soy), 4),
    "SE:", round(se(placebo_soy), 4),
    "p:", round(pvalue(placebo_soy), 4), "\n")
cat("Placebo (cattle) — coef:", round(coef(placebo_cattle), 4),
    "SE:", round(se(placebo_cattle), 4),
    "p:", round(pvalue(placebo_cattle), 4), "\n")

saveRDS(placebo_soy, "../data/placebo_soy.rds")
saveRDS(placebo_cattle, "../data/placebo_cattle.rds")

# ============================================================
# 2. Year FE instead of State×Year FE
# ============================================================
cat("\n=== Robustness: Year FE only ===\n")

r_yearfe_soy <- feols(log_soy_area ~ treatment_x_post | muni_code_6 + year,
                      data = panel, cluster = ~muni_code_6)
r_yearfe_cattle <- feols(log_cattle ~ treatment_x_post | muni_code_6 + year,
                         data = panel, cluster = ~muni_code_6)

cat("Year FE (soy)    — coef:", round(coef(r_yearfe_soy), 4),
    "SE:", round(se(r_yearfe_soy), 4), "\n")
cat("Year FE (cattle) — coef:", round(coef(r_yearfe_cattle), 4),
    "SE:", round(se(r_yearfe_cattle), 4), "\n")

# ============================================================
# 3. Trimming extreme treatment values
# ============================================================
cat("\n=== Robustness: Trimmed Sample (1st-99th percentile) ===\n")

q01 <- quantile(panel$farming_share_2008, 0.01, na.rm = TRUE)
q99 <- quantile(panel$farming_share_2008, 0.99, na.rm = TRUE)

panel_trim <- panel %>%
  filter(farming_share_2008 >= q01, farming_share_2008 <= q99)

r_trim_soy <- feols(log_soy_area ~ treatment_x_post | muni_code_6 + state_year,
                    data = panel_trim, cluster = ~muni_code_6)
r_trim_cattle <- feols(log_cattle ~ treatment_x_post | muni_code_6 + state_year,
                       data = panel_trim, cluster = ~muni_code_6)

cat("Trimmed (soy)    — coef:", round(coef(r_trim_soy), 4),
    "SE:", round(se(r_trim_soy), 4), "\n")
cat("Trimmed (cattle) — coef:", round(coef(r_trim_cattle), 4),
    "SE:", round(se(r_trim_cattle), 4), "\n")

# ============================================================
# 4. Asinh transformation (handles zeros better)
# ============================================================
cat("\n=== Robustness: Asinh Transformation ===\n")

panel <- panel %>%
  mutate(
    asinh_soy_area = asinh(soy_area_ha),
    asinh_cattle = asinh(cattle_head)
  )

r_asinh_soy <- feols(asinh_soy_area ~ treatment_x_post | muni_code_6 + state_year,
                     data = panel, cluster = ~muni_code_6)
r_asinh_cattle <- feols(asinh_cattle ~ treatment_x_post | muni_code_6 + state_year,
                        data = panel, cluster = ~muni_code_6)

cat("Asinh (soy)    — coef:", round(coef(r_asinh_soy), 4),
    "SE:", round(se(r_asinh_soy), 4), "\n")
cat("Asinh (cattle) — coef:", round(coef(r_asinh_cattle), 4),
    "SE:", round(se(r_asinh_cattle), 4), "\n")

# ============================================================
# 5. Excluding Amazon biome (different legal reserve: 80%)
# ============================================================
cat("\n=== Robustness: Excluding Amazon ===\n")

if ("biome" %in% names(panel)) {
  panel_noamz <- panel %>%
    filter(!grepl("amaz", biome, ignore.case = TRUE))

  if (nrow(panel_noamz) > 100) {
    r_noamz_soy <- feols(log_soy_area ~ treatment_x_post | muni_code_6 + state_year,
                         data = panel_noamz, cluster = ~muni_code_6)
    r_noamz_cattle <- feols(log_cattle ~ treatment_x_post | muni_code_6 + state_year,
                            data = panel_noamz, cluster = ~muni_code_6)

    cat("No Amazon (soy)    — coef:", round(coef(r_noamz_soy), 4),
        "SE:", round(se(r_noamz_soy), 4), "\n")
    cat("No Amazon (cattle) — coef:", round(coef(r_noamz_cattle), 4),
        "SE:", round(se(r_noamz_cattle), 4), "\n")

    saveRDS(r_noamz_soy, "../data/r_noamz_soy.rds")
    saveRDS(r_noamz_cattle, "../data/r_noamz_cattle.rds")
  }
}

# ============================================================
# 6. Moral Hazard: Post-2012 deforestation ~ treatment
# ============================================================
cat("\n=== Moral Hazard Test ===\n")

defor <- readRDS("../data/defor_outcome.rds")
treatment <- readRDS("../data/treatment_data.rds")

# Both use geocode (7-digit IBGE code)
defor_analysis <- treatment %>%
  left_join(defor %>% select(geocode, post_2012_defor_share),
            by = "geocode") %>%
  filter(!is.na(post_2012_defor_share), !is.na(farming_share_2008))

# Cross-sectional regression: does pre-2008 amnesty exposure predict post-2012 deforestation?
moral_hazard <- lm(post_2012_defor_share ~ farming_share_2008 + factor(state_code),
                   data = defor_analysis)

cat("Moral hazard regression:\n")
cat("  Coef on farming_share_2008:", round(coef(moral_hazard)["farming_share_2008"], 6), "\n")
cat("  SE:", round(sqrt(diag(vcov(moral_hazard)))["farming_share_2008"], 6), "\n")
cat("  N:", nrow(defor_analysis), "\n")

saveRDS(moral_hazard, "../data/moral_hazard.rds")

# Also test with forest_loss as treatment
if ("forest_loss_share" %in% names(defor_analysis)) {
  mh2 <- lm(post_2012_defor_share ~ forest_loss_share + factor(state_code),
             data = defor_analysis)
  cat("\nMoral hazard (forest loss treatment):\n")
  cat("  Coef:", round(coef(mh2)["forest_loss_share"], 6),
      "SE:", round(sqrt(diag(vcov(mh2)))["forest_loss_share"], 6), "\n")
  saveRDS(mh2, "../data/moral_hazard_2.rds")
}

# Save robustness models
saveRDS(r_yearfe_soy, "../data/r_yearfe_soy.rds")
saveRDS(r_yearfe_cattle, "../data/r_yearfe_cattle.rds")
saveRDS(r_trim_soy, "../data/r_trim_soy.rds")
saveRDS(r_trim_cattle, "../data/r_trim_cattle.rds")
saveRDS(r_asinh_soy, "../data/r_asinh_soy.rds")
saveRDS(r_asinh_cattle, "../data/r_asinh_cattle.rds")

cat("\n=== Robustness Checks Complete ===\n")
