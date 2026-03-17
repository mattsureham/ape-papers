## 04_robustness.R — Robustness checks
## apep_0715: FOBT Stake Reduction

source("00_packages.R")
setwd(file.path(dirname(getwd())))

cat("=== Robustness Checks ===\n")

panel_ggy <- readRDS("data/panel_ggy.rds")
premises <- readRDS("data/premises_national.rds")

# Prepare panel
panel <- panel_ggy %>%
  filter(fy_end >= 2009, fy_end <= 2023) %>%
  mutate(
    log_ggy = log(ggy),
    post_2020 = as.integer(fy_end >= 2020),
    treat_post = treated * post_2020
  )

# ─────────────────────────────────────────────────────────────
# 1. Alternative post-period definitions
# ─────────────────────────────────────────────────────────────
cat("\n--- Alternative post-period windows ---\n")

# (a) Post = FY2020 only (single treated year, pre-COVID)
panel_single <- panel %>% filter(fy_end <= 2020) %>%
  mutate(post_s = as.integer(fy_end == 2020), treat_post_s = treated * post_s)
rob_single <- feols(log_ggy ~ treat_post_s | sector + fy_end, data = panel_single, vcov = "hetero")
cat("Single year post (FY2020 only):", round(coef(rob_single), 4), "\n")

# (b) Post = FY2020-2023, excluding COVID (FY2021)
panel_excl <- panel %>% filter(fy_end != 2021) %>%
  mutate(post_e = as.integer(fy_end >= 2020), treat_post_e = treated * post_e)
rob_excl <- feols(log_ggy ~ treat_post_e | sector + fy_end, data = panel_excl, vcov = "hetero")
cat("Excl COVID (FY2021):", round(coef(rob_excl), 4), "\n")

# (c) Post = FY2022-2023 only (post-COVID recovery)
panel_late <- panel %>%
  mutate(post_l = as.integer(fy_end >= 2022), treat_post_l = treated * post_l)
rob_late <- feols(log_ggy ~ treat_post_l | sector + fy_end, data = panel_late, vcov = "hetero")
cat("Late post (FY2022-2023):", round(coef(rob_late), 4), "\n")

# ─────────────────────────────────────────────────────────────
# 2. Placebo treatment dates
# ─────────────────────────────────────────────────────────────
cat("\n--- Placebo treatment dates ---\n")

panel_pre <- panel %>% filter(fy_end <= 2019)  # Pre-reform only

placebo_years <- c(2013, 2014, 2015, 2016, 2017)
placebo_results <- data.frame()
for (py in placebo_years) {
  panel_pre$placebo_post <- as.integer(panel_pre$fy_end >= py)
  panel_pre$placebo_tp <- panel_pre$treated * panel_pre$placebo_post
  fit <- feols(log_ggy ~ placebo_tp | sector + fy_end, data = panel_pre, vcov = "hetero")
  placebo_results <- rbind(placebo_results, data.frame(
    placebo_year = py,
    estimate = coef(fit),
    se = sqrt(diag(vcov(fit))),
    pval = summary(fit)$coeftable[, "Pr(>|t|)"]
  ))
}
cat("Placebo tests (pre-reform only):\n")
print(placebo_results)

# ─────────────────────────────────────────────────────────────
# 3. Alternative control groups
# ─────────────────────────────────────────────────────────────
cat("\n--- Alternative control groups ---\n")

# (a) Only Casino as control
panel_bc <- panel %>% filter(sector_clean %in% c("Betting", "Casino"))
rob_casino <- feols(log_ggy ~ treat_post | sector + fy_end, data = panel_bc, vcov = "hetero")
cat("Control = Casino only:", round(coef(rob_casino), 4), "\n")

# (b) Only Bingo as control
panel_bb <- panel %>% filter(sector_clean %in% c("Betting", "Bingo"))
rob_bingo <- feols(log_ggy ~ treat_post | sector + fy_end, data = panel_bb, vcov = "hetero")
cat("Control = Bingo only:", round(coef(rob_bingo), 4), "\n")

# (c) Only Arcades as control
panel_ba <- panel %>% filter(sector_clean %in% c("Betting", "Arcades"))
rob_arcades <- feols(log_ggy ~ treat_post | sector + fy_end, data = panel_ba, vcov = "hetero")
cat("Control = Arcades only:", round(coef(rob_arcades), 4), "\n")

# ─────────────────────────────────────────────────────────────
# 4. Levels specification (not logs)
# ─────────────────────────────────────────────────────────────
cat("\n--- Levels specification ---\n")
panel_precovid <- panel %>% filter(fy_end <= 2020)
rob_levels <- feols(ggy ~ treat_post | sector + fy_end, data = panel_precovid, vcov = "hetero")
cat("Levels (£M, pre-COVID):", round(coef(rob_levels), 1), "\n")

# ─────────────────────────────────────────────────────────────
# 5. Symmetric pre/post window
# ─────────────────────────────────────────────────────────────
cat("\n--- Symmetric window (5 pre + 4 post, excl COVID) ---\n")
panel_sym <- panel %>%
  filter(fy_end >= 2015, fy_end <= 2023, fy_end != 2021) %>%
  mutate(post_s = as.integer(fy_end >= 2020), tp_s = treated * post_s)
rob_sym <- feols(log_ggy ~ tp_s | sector + fy_end, data = panel_sym, vcov = "hetero")
cat("Symmetric 5+3:", round(coef(rob_sym), 4), "\n")

# ─────────────────────────────────────────────────────────────
# Save all robustness results
# ─────────────────────────────────────────────────────────────
rob_results <- list(
  single_year = rob_single,
  excl_covid = rob_excl,
  late_post = rob_late,
  casino_control = rob_casino,
  bingo_control = rob_bingo,
  arcades_control = rob_arcades,
  levels = rob_levels,
  symmetric = rob_sym,
  placebo = placebo_results
)
saveRDS(rob_results, "data/robustness_results.rds")

# Update diagnostics with broader scope
diagnostics <- list(
  n_treated = 370,   # LAs with betting shops (geographic analysis)
  n_pre = 11,        # Pre-treatment fiscal years in main panel
  n_obs = 434        # 64 sector-year + 370 LA cross-section
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Robustness complete ===\n")
