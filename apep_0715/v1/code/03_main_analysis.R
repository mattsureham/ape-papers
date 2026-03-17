## 03_main_analysis.R — Main regressions for FOBT stake reduction paper
## apep_0715

source("00_packages.R")
setwd(file.path(dirname(getwd())))

cat("=== Main Analysis ===\n")

# Load data
panel_ggy <- readRDS("data/panel_ggy.rds")
panel_premises <- readRDS("data/panel_premises.rds")
ggy_overview <- readRDS("data/ggy_overview.rds")
premises <- readRDS("data/premises_national.rds")
machines_betting <- readRDS("data/machines_betting.rds")
betting_detail <- readRDS("data/betting_detail.rds")

# ─────────────────────────────────────────────────────────────
# 1. Restrict sample to pre-COVID window
# ─────────────────────────────────────────────────────────────
# Treatment: FOBT stake cut April 2019
# FY2020 (Apr 2019-Mar 2020) = first treated year (11 months pre-COVID + 1 month COVID)
# FY2021 (Apr 2020-Mar 2021) = COVID-contaminated
# Baseline: Use pre-COVID sample ending FY2020 for main results
# Extended: Include post-COVID years for long-run effects

panel_ggy_main <- panel_ggy %>%
  filter(fy_end >= 2009, fy_end <= 2023) %>%
  mutate(
    log_ggy = log(ggy),
    post_2020 = as.integer(fy_end >= 2020),
    treat_post = treated * post_2020,
    # For event study
    event_time = fy_end - 2020  # 0 = first treated year
  )

# Exclude COVID year for robustness
panel_ggy_nocovid <- panel_ggy_main %>%
  filter(fy_end != 2021)  # FY ending Mar 2021 = COVID lockdown year

cat("Main panel:", nrow(panel_ggy_main), "obs\n")
cat("  Sectors:", paste(unique(panel_ggy_main$sector_clean), collapse = ", "), "\n")
cat("  Years:", min(panel_ggy_main$fy_end), "-", max(panel_ggy_main$fy_end), "\n")

# ─────────────────────────────────────────────────────────────
# 2. Sector DiD: GGY
# ─────────────────────────────────────────────────────────────
# Log GGY regression: sector + year FE, betting × post interaction
# Since we only have 4 sectors, we use robust SEs (not clustered)

# Main specification
did_ggy <- fixest::feols(log_ggy ~ treat_post | sector + fy_end,
                          data = panel_ggy_main,
                          vcov = "hetero")

cat("\n=== GGY DiD (log) ===\n")
summary(did_ggy)

# Pre-COVID only (through FY2020)
panel_ggy_precovid <- panel_ggy_main %>% filter(fy_end <= 2020)
did_ggy_precovid <- fixest::feols(log_ggy ~ treat_post | sector + fy_end,
                                   data = panel_ggy_precovid,
                                   vcov = "hetero")
cat("\n=== GGY DiD (pre-COVID only) ===\n")
summary(did_ggy_precovid)

# Excluding COVID year
did_ggy_nocovid <- fixest::feols(log_ggy ~ treat_post | sector + fy_end,
                                  data = panel_ggy_nocovid,
                                  vcov = "hetero")
cat("\n=== GGY DiD (excl COVID) ===\n")
summary(did_ggy_nocovid)

# ─────────────────────────────────────────────────────────────
# 3. Event Study: Year-by-year betting × year interactions
# ─────────────────────────────────────────────────────────────
# Relative to event time -1 (FY2019 = last pre-treatment year)
panel_ggy_es <- panel_ggy_main %>%
  filter(event_time >= -7, event_time <= 3) %>%  # Window: -7 to +3
  mutate(event_time_f = factor(event_time))

# Drop reference period (event_time = -1)
did_es <- fixest::feols(log_ggy ~ i(event_time_f, treated, ref = "-1") | sector + fy_end,
                         data = panel_ggy_es,
                         vcov = "hetero")
cat("\n=== Event Study ===\n")
summary(did_es)

# Extract event study coefficients
es_coefs <- broom::tidy(did_es, conf.int = TRUE) %>%
  filter(grepl("event_time", term)) %>%
  mutate(
    event_time = as.integer(gsub("event_time_f::(-?\\d+):treated", "\\1", term))
  )
cat("\nEvent study coefficients:\n")
print(es_coefs[, c("event_time", "estimate", "std.error", "p.value")])

# Save for tables
saveRDS(es_coefs, "data/es_coefs.rds")

# ─────────────────────────────────────────────────────────────
# 4. Premises DiD
# ─────────────────────────────────────────────────────────────
panel_prem_main <- panel_premises %>%
  filter(fy_end >= 2009, fy_end <= 2024) %>%
  mutate(
    log_prem = log(premises_count + 1),
    post_2020 = as.integer(fy_end >= 2020),
    treat_post = treated * post_2020
  )

# Use Betting, Casino, Bingo as sectors (drop AGC and FEC to match GGY sectors)
panel_prem_3s <- panel_prem_main %>%
  filter(sector_clean %in% c("Betting", "Casino", "Bingo"))

did_prem <- fixest::feols(log_prem ~ treat_post | sector + fy_end,
                           data = panel_prem_3s,
                           vcov = "hetero")
cat("\n=== Premises DiD (log) ===\n")
summary(did_prem)

# ─────────────────────────────────────────────────────────────
# 5. Simple before-after DiD arithmetic
# ─────────────────────────────────────────────────────────────
cat("\n=== Simple DiD Arithmetic ===\n")

# GGY before (avg 2016-2019) and after (2020)
pre_avg <- panel_ggy_main %>%
  filter(fy_end >= 2016, fy_end <= 2019) %>%
  group_by(sector_clean, treated) %>%
  summarise(pre_ggy = mean(ggy), .groups = "drop")

post_avg <- panel_ggy_main %>%
  filter(fy_end == 2020) %>%
  select(sector_clean, treated, post_ggy = ggy)

did_arith <- left_join(pre_avg, post_avg, by = c("sector_clean", "treated")) %>%
  mutate(
    change = post_ggy - pre_ggy,
    pct_change = (post_ggy - pre_ggy) / pre_ggy * 100
  )
cat("Pre-period avg (2016-2019) vs Post (2020):\n")
print(did_arith)

# DiD estimate
betting_change <- did_arith$pct_change[did_arith$sector_clean == "Betting"]
control_change <- mean(did_arith$pct_change[did_arith$treated == 0])
cat("\nBetting GGY change:", round(betting_change, 1), "%\n")
cat("Control sectors avg GGY change:", round(control_change, 1), "%\n")
cat("DiD (pp difference):", round(betting_change - control_change, 1), "pp\n")

# ─────────────────────────────────────────────────────────────
# 6. Machine Channel Decomposition
# ─────────────────────────────────────────────────────────────
cat("\n=== Machine Channel ===\n")

# Remove duplicate rows (2021 appears twice in some datasets)
machines_clean <- machines_betting %>%
  distinct(fy_end, .keep_all = TRUE)

# B2 machine collapse
cat("B2 machines:\n")
cat("  Pre-reform (Mar 2019):", machines_clean$b2_machines[machines_clean$fy_end == 2019], "\n")
cat("  Post-reform (Mar 2020):", machines_clean$b2_machines[machines_clean$fy_end == 2020], "\n")
cat("  Change:", round((machines_clean$b2_machines[machines_clean$fy_end == 2020] /
                         machines_clean$b2_machines[machines_clean$fy_end == 2019] - 1) * 100, 1), "%\n")

# Machine GGY
cat("\nMachine GGY in betting premises:\n")
cat("  Pre-reform:", round(machines_clean$total_machine_ggy[machines_clean$fy_end == 2019]), "£M\n")
cat("  Post-reform:", round(machines_clean$total_machine_ggy[machines_clean$fy_end == 2020]), "£M\n")
cat("  Change:", round((machines_clean$total_machine_ggy[machines_clean$fy_end == 2020] /
                         machines_clean$total_machine_ggy[machines_clean$fy_end == 2019] - 1) * 100, 1), "%\n")

# OTC vs Machine decomposition
betting_clean <- betting_detail %>% distinct(fy_end, .keep_all = TRUE)
cat("\nBetting GGY decomposition:\n")
cat("  OTC GGY pre:", round(betting_clean$otc_ggy[betting_clean$fy_end == 2019]), "£M\n")
cat("  OTC GGY post:", round(betting_clean$otc_ggy[betting_clean$fy_end == 2020]), "£M\n")
cat("  OTC change:", round((betting_clean$otc_ggy[betting_clean$fy_end == 2020] /
                            betting_clean$otc_ggy[betting_clean$fy_end == 2019] - 1) * 100, 1), "%\n")
cat("  Machine GGY pre:", round(betting_clean$machine_ggy[betting_clean$fy_end == 2019]), "£M\n")
cat("  Machine GGY post:", round(betting_clean$machine_ggy[betting_clean$fy_end == 2020]), "£M\n")
cat("  Machine change:", round((betting_clean$machine_ggy[betting_clean$fy_end == 2020] /
                                betting_clean$machine_ggy[betting_clean$fy_end == 2019] - 1) * 100, 1), "%\n")

# ─────────────────────────────────────────────────────────────
# 7. Substitution: Remote vs Non-Remote Betting
# ─────────────────────────────────────────────────────────────
cat("\n=== Substitution Analysis ===\n")

# Use GGY overview which has annual remote betting GGY
subst <- ggy_overview %>%
  select(fy_end, betting_nr, betting_r) %>%
  mutate(
    total_betting = betting_nr + betting_r,
    remote_share = betting_r / total_betting * 100
  )
cat("Betting GGY by channel:\n")
print(subst)

# Pre vs post comparison
pre_total <- mean(subst$total_betting[subst$fy_end >= 2016 & subst$fy_end <= 2019])
post_total <- subst$total_betting[subst$fy_end == 2020]
cat("\nTotal betting GGY (NR + Remote):\n")
cat("  Pre avg (2016-2019):", round(pre_total), "£M\n")
cat("  Post (2020):", round(post_total), "£M\n")
cat("  Change:", round((post_total / pre_total - 1) * 100, 1), "%\n")

pre_remote <- mean(subst$betting_r[subst$fy_end >= 2016 & subst$fy_end <= 2019])
post_remote <- subst$betting_r[subst$fy_end == 2020]
cat("\nRemote betting GGY:\n")
cat("  Pre avg (2016-2019):", round(pre_remote), "£M\n")
cat("  Post (2020):", round(post_remote), "£M\n")
cat("  Change:", round((post_remote / pre_remote - 1) * 100, 1), "%\n")

# ─────────────────────────────────────────────────────────────
# 8. Write diagnostics for validation
# ─────────────────────────────────────────────────────────────
diagnostics <- list(
  n_treated = 1,  # 1 treated sector (betting)
  n_pre = 11,     # FY2009-2019 pre-treatment
  n_obs = nrow(panel_ggy_main),
  n_sectors = length(unique(panel_ggy_main$sector_clean)),
  n_years = length(unique(panel_ggy_main$fy_end)),
  pre_years = paste(sort(unique(panel_ggy_main$fy_end[panel_ggy_main$post_2020 == 0])), collapse = ","),
  post_years = paste(sort(unique(panel_ggy_main$fy_end[panel_ggy_main$post_2020 == 1])), collapse = ",")
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

# Save key model objects
saveRDS(did_ggy, "data/did_ggy.rds")
saveRDS(did_ggy_precovid, "data/did_ggy_precovid.rds")
saveRDS(did_ggy_nocovid, "data/did_ggy_nocovid.rds")
saveRDS(did_es, "data/did_es.rds")
saveRDS(did_prem, "data/did_prem.rds")
saveRDS(did_arith, "data/did_arith.rds")
saveRDS(subst, "data/substitution.rds")

cat("\n=== Main analysis complete ===\n")
