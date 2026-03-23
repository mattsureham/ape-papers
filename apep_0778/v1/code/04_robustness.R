## =============================================================================
## 04_robustness.R — Robustness checks
## apep_0778
## =============================================================================

source("00_packages.R")

cat("=== Loading data ===\n")
df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

## ---- R1: Not-yet-treated control group ----
cat("\n=== R1: Not-yet-treated controls ===\n")

cs_nyt <- att_gt(
  yname = "snap_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = df,
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "varying"
)
agg_nyt <- aggte(cs_nyt, type = "simple")
cat(sprintf("  NYT ATT: %.4f (SE: %.4f)\n", agg_nyt$overall.att, agg_nyt$overall.se))

## ---- R2: Exclude early adopters (pre-2005, always-treated in ACS) ----
cat("\n=== R2: Restrict to 2006+ cohorts only ===\n")

df_late <- df %>% filter(first_treat == 0 | first_treat >= 2006)
cs_late <- att_gt(
  yname = "snap_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = df_late,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "varying"
)
agg_late <- aggte(cs_late, type = "simple")
cat(sprintf("  Late adopters ATT: %.4f (SE: %.4f)\n",
            agg_late$overall.att, agg_late$overall.se))

## ---- R3: Anticipation (1 year) ----
cat("\n=== R3: 1-year anticipation ===\n")

cs_antic <- att_gt(
  yname = "snap_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  anticipation = 1,
  est_method = "dr",
  base_period = "varying"
)
agg_antic <- aggte(cs_antic, type = "simple")
cat(sprintf("  Anticipation ATT: %.4f (SE: %.4f)\n",
            agg_antic$overall.att, agg_antic$overall.se))

## ---- R4: Randomization inference ----
cat("\n=== R4: Randomization inference ===\n")

twfe_est <- coef(results$twfe_rate)["post"]
set.seed(42)
n_perms <- 999
perm_ests <- numeric(n_perms)

state_ids <- unique(df$state_abbr)
treated_ids <- unique(df$state_abbr[df$treated == 1])
n_treat <- length(treated_ids)

for (p in 1:n_perms) {
  fake_treated <- sample(state_ids, n_treat)
  df_perm <- df %>%
    mutate(post_perm = ifelse(state_abbr %in% fake_treated, post, 0))
  fit_perm <- tryCatch(
    feols(snap_rate ~ post_perm | state_id + year, data = df_perm, cluster = ~state_abbr),
    error = function(e) NULL
  )
  if (!is.null(fit_perm)) perm_ests[p] <- coef(fit_perm)["post_perm"]
  else perm_ests[p] <- NA
}

perm_ests <- perm_ests[!is.na(perm_ests)]
ri_p <- mean(abs(perm_ests) >= abs(twfe_est))
cat(sprintf("  RI p-value: %.4f\n", ri_p))

## ---- R5: Excluding Great Recession window ----
cat("\n=== R5: Excluding 2008-2010 ===\n")

df_no_gr <- df %>% filter(year < 2008 | year > 2010)
if (n_distinct(df_no_gr$first_treat[df_no_gr$first_treat > 0]) >= 2) {
  cs_no_gr <- tryCatch({
    att_gt(
      yname = "snap_rate", tname = "year", idname = "state_id",
      gname = "first_treat", data = df_no_gr,
      control_group = "nevertreated", anticipation = 0,
      est_method = "dr", base_period = "varying"
    )
  }, error = function(e) { cat(sprintf("  Error: %s\n", e$message)); NULL })

  if (!is.null(cs_no_gr)) {
    agg_no_gr <- aggte(cs_no_gr, type = "simple")
    cat(sprintf("  Excl. 2008-2010 ATT: %.4f (SE: %.4f)\n",
                agg_no_gr$overall.att, agg_no_gr$overall.se))
  } else {
    agg_no_gr <- list(overall.att = NA, overall.se = NA)
  }
} else {
  agg_no_gr <- list(overall.att = NA, overall.se = NA)
  cat("  Too few cohorts.\n")
}

## ---- Save ----
cat("\n=== Saving robustness results ===\n")

robustness <- list(
  nyt = list(att = agg_nyt$overall.att, se = agg_nyt$overall.se),
  late_only = list(att = agg_late$overall.att, se = agg_late$overall.se),
  anticipation = list(att = agg_antic$overall.att, se = agg_antic$overall.se),
  ri_p = ri_p,
  no_gr = list(att = agg_no_gr$overall.att, se = agg_no_gr$overall.se)
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("  Saved: robustness_results.rds\n")
cat("  DONE.\n")
