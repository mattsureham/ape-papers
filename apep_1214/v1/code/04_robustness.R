## 04_robustness.R — Robustness checks
## apep_1214: MCMV Housing and School Quality

source("00_packages.R")

data_dir <- "../data"

# Load data
panel <- fread(file.path(data_dir, "panel_public.csv"))
results <- readRDS(file.path(data_dir, "results.rds"))

ideb_waves <- c(2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019, 2021, 2023)
ai <- panel[stage == "anos_iniciais"]
ai[, g := 0L]
ai[first_year > 0, g := {
  wave_idx <- findInterval(first_year, ideb_waves)
  ifelse(first_year %in% ideb_waves,
         first_year,
         ideb_waves[pmin(wave_idx + 1, length(ideb_waves))])
}]

# ============================================================
# Robustness 1: Stacked DiD
# ============================================================
cat("=== Robustness 1: Stacked DiD ===\n")

# Create stacked dataset: for each cohort g, keep never-treated + cohort g
# Window: 2 pre-periods, 4 post-periods
build_stack <- function(dt, cohorts) {
  stacked <- list()
  for (gg in cohorts) {
    cohort_data <- dt[g == gg | g == 0]
    # Keep windows around treatment
    wave_idx <- which(ideb_waves == gg)
    if (length(wave_idx) == 0) next
    pre_start <- max(1, wave_idx - 2)
    post_end <- min(length(ideb_waves), wave_idx + 4)
    keep_waves <- ideb_waves[pre_start:post_end]
    sub <- cohort_data[year %in% keep_waves]
    sub[, stack_id := gg]
    sub[, rel_time := year - gg]
    stacked[[length(stacked) + 1]] <- sub
  }
  rbindlist(stacked)
}

cohorts <- sort(unique(ai[g > 0]$g))
stacked <- build_stack(ai, cohorts)
stacked[, unit_stack := paste(mun_id, stack_id, sep = "_")]

stacked[, stack_factor := as.factor(stack_id)]
stacked[, year_stack := interaction(year, stack_factor)]
stacked_reg <- feols(ideb_score ~ treated | unit_stack + year_stack,
                     data = stacked, cluster = ~mun_id)
cat("Stacked DiD result:\n")
print(summary(stacked_reg))

# ============================================================
# Robustness 2: Not-yet-treated as control
# ============================================================
cat("\n=== Robustness 2: Not-yet-treated control group ===\n")

cs_nyt <- att_gt(
  yname = "ideb_score",
  tname = "year",
  idname = "mun_id",
  gname = "g",
  data = as.data.frame(ai),
  control_group = "notyettreated",
  est_method = "dr",
  base_period = "universal"
)

cs_nyt_agg <- aggte(cs_nyt, type = "simple")
cat("CS ATT (not-yet-treated control):\n")
print(summary(cs_nyt_agg))

# ============================================================
# Robustness 3: Including all MCMV modalities (not just FAR)
# ============================================================
cat("\n=== Robustness 3: All MCMV modalities ===\n")

mcmv_all <- fread(file.path(data_dir, "view_dados_abertos_ogu_202603201556.csv"),
                  sep = ";", encoding = "Latin-1")
mcmv_all[, contract_year := year(as.Date(dt_assinatura, format = "%d/%m/%Y"))]
mcmv_all[, mun_id := cod_ibge]

# First treatment year for ANY MCMV modality
first_any <- mcmv_all[!is.na(contract_year),
                       .(first_year_any = min(contract_year)),
                       by = mun_id]

ai_all <- merge(panel[stage == "anos_iniciais"], first_any, by = "mun_id", all.x = TRUE)
ai_all[, treated_any := fifelse(!is.na(first_year_any) & year >= first_year_any, 1L, 0L)]

twfe_all <- feols(ideb_score ~ treated_any | mun_id + year,
                  data = ai_all, cluster = ~mun_id)
cat("TWFE with all MCMV modalities:\n")
print(summary(twfe_all))

# ============================================================
# Robustness 4: Leave-one-state-out (jackknife)
# ============================================================
cat("\n=== Robustness 4: Leave-one-state-out ===\n")

# Get state for each municipality
ideb_raw <- fread(file.path(data_dir, "ideb_municipality.csv"))
mun_state <- unique(ideb_raw[, .(mun_id = as.integer(substr(as.character(municipality_id), 1, 6)),
                                  state)])

ai_s <- merge(ai, mun_state, by = "mun_id", all.x = TRUE)
states <- unique(ai_s[!is.na(state)]$state)

loo_results <- data.table(
  state_dropped = character(),
  att = numeric(),
  se = numeric()
)

for (s in states) {
  sub <- ai_s[state != s]
  if (uniqueN(sub[g > 0]$mun_id) < 20) next
  tryCatch({
    cs_loo <- att_gt(
      yname = "ideb_score", tname = "year", idname = "mun_id", gname = "g",
      data = as.data.frame(sub), control_group = "nevertreated",
      est_method = "dr", base_period = "universal"
    )
    agg_loo <- aggte(cs_loo, type = "simple")
    loo_results <- rbind(loo_results, data.table(
      state_dropped = s, att = agg_loo$overall.att, se = agg_loo$overall.se))
  }, error = function(e) NULL)
}

cat(sprintf("Leave-one-state-out: %d states\n", nrow(loo_results)))
cat(sprintf("ATT range: [%.4f, %.4f]\n",
            min(loo_results$att), max(loo_results$att)))
cat(sprintf("Mean ATT: %.4f\n", mean(loo_results$att)))

# ============================================================
# Robustness 5: Excluding 2021 (COVID year)
# ============================================================
cat("\n=== Robustness 5: Excluding 2021 (COVID) ===\n")

ai_nocovid <- ai[year != 2021]
cs_nocovid <- att_gt(
  yname = "ideb_score", tname = "year", idname = "mun_id", gname = "g",
  data = as.data.frame(ai_nocovid), control_group = "nevertreated",
  est_method = "dr", base_period = "universal"
)
cs_nocovid_agg <- aggte(cs_nocovid, type = "simple")
cat("CS ATT excluding 2021:\n")
print(summary(cs_nocovid_agg))

# ============================================================
# Save robustness results
# ============================================================
cat("\n=== Saving robustness results ===\n")

rob_results <- list(
  stacked = stacked_reg,
  cs_nyt = cs_nyt_agg,
  twfe_all = twfe_all,
  loo = loo_results,
  cs_nocovid = cs_nocovid_agg
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness summary:\n")
cat(sprintf("  Main CS ATT:             %.4f (SE: %.4f)\n",
            results$cs_agg_ai$overall.att, results$cs_agg_ai$overall.se))
cat(sprintf("  Stacked DiD:             %.4f (SE: %.4f)\n",
            coef(stacked_reg)["treated"], se(stacked_reg)["treated"]))
cat(sprintf("  Not-yet-treated:         %.4f (SE: %.4f)\n",
            cs_nyt_agg$overall.att, cs_nyt_agg$overall.se))
cat(sprintf("  All MCMV modalities:     %.4f (SE: %.4f)\n",
            coef(twfe_all)["treated_any"], se(twfe_all)["treated_any"]))
cat(sprintf("  LOO mean ATT:            %.4f\n", mean(loo_results$att)))
cat(sprintf("  Excluding 2021 (COVID):  %.4f (SE: %.4f)\n",
            cs_nocovid_agg$overall.att, cs_nocovid_agg$overall.se))

cat("\nRobustness checks complete.\n")
