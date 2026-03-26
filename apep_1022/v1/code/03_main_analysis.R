## 03_main_analysis.R — Callaway-Sant'Anna staggered DiD
## apep_1022: Affirmative action bans and minority enrollment cascades

source("00_packages.R")

cat("=== Main Analysis: Staggered DiD ===\n")

panel <- readRDS("../data/analysis_panel.rds")

## -------------------------------------------------------------------
## 1. Restrict to analysis sample
##    Exclude early-ban states (CA/WA/FL) — no pre-treatment data
##    Keep MI, NE, AZ, NH, OK, ID (6 treatment cohorts) + never-treated
## -------------------------------------------------------------------
cat("Building analysis sample...\n")

df <- panel %>%
  filter(!(stabbr %in% c("CA", "WA", "FL"))) %>%
  filter(year >= 2002, year <= 2022) %>%
  # Remove institutions with missing enrollment
  filter(!is.na(share_black), !is.na(enroll_total), enroll_total > 0)

cat(sprintf("Analysis sample: %d inst-years, %d institutions\n",
            nrow(df), n_distinct(df$unitid)))
cat(sprintf("Treated states: %s\n",
            paste(sort(unique(df$stabbr[df$first_treat > 0])), collapse = ", ")))
cat(sprintf("Treatment cohorts: %s\n",
            paste(sort(unique(df$first_treat[df$first_treat > 0])), collapse = ", ")))
cat(sprintf("Never-treated: %d institutions in %d states\n",
            n_distinct(df$unitid[df$first_treat == 0]),
            n_distinct(df$stabbr[df$first_treat == 0])))

## -------------------------------------------------------------------
## 2. Callaway-Sant'Anna: Black enrollment share
## -------------------------------------------------------------------
cat("\n--- CS DiD: Black enrollment share ---\n")

cs_black <- att_gt(
  yname = "share_black",
  tname = "year",
  idname = "unitid",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  est_method = "dr",        # doubly-robust
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("Group-time ATTs computed.\n")

# Simple aggregate ATT
agg_black <- aggte(cs_black, type = "simple")
cat(sprintf("Overall ATT (Black share): %.4f (SE: %.4f, p: %.4f)\n",
            agg_black$overall.att, agg_black$overall.se,
            2 * pnorm(-abs(agg_black$overall.att / agg_black$overall.se))))

# Dynamic (event study) aggregation
es_black <- aggte(cs_black, type = "dynamic", min_e = -6, max_e = 10)
cat("Event study computed.\n")

## -------------------------------------------------------------------
## 3. Callaway-Sant'Anna: Hispanic enrollment share
## -------------------------------------------------------------------
cat("\n--- CS DiD: Hispanic enrollment share ---\n")

cs_hisp <- att_gt(
  yname = "share_hisp",
  tname = "year",
  idname = "unitid",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_hisp <- aggte(cs_hisp, type = "simple")
cat(sprintf("Overall ATT (Hispanic share): %.4f (SE: %.4f, p: %.4f)\n",
            agg_hisp$overall.att, agg_hisp$overall.se,
            2 * pnorm(-abs(agg_hisp$overall.att / agg_hisp$overall.se))))

es_hisp <- aggte(cs_hisp, type = "dynamic", min_e = -6, max_e = 10)

## -------------------------------------------------------------------
## 4. Callaway-Sant'Anna: Combined minority share (Black + Hispanic)
## -------------------------------------------------------------------
cat("\n--- CS DiD: Combined minority share ---\n")

cs_minority <- att_gt(
  yname = "share_minority",
  tname = "year",
  idname = "unitid",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_minority <- aggte(cs_minority, type = "simple")
cat(sprintf("Overall ATT (minority share): %.4f (SE: %.4f, p: %.4f)\n",
            agg_minority$overall.att, agg_minority$overall.se,
            2 * pnorm(-abs(agg_minority$overall.att / agg_minority$overall.se))))

es_minority <- aggte(cs_minority, type = "dynamic", min_e = -6, max_e = 10)

## -------------------------------------------------------------------
## 5. TWFE comparison (for "settling the dispute")
## -------------------------------------------------------------------
cat("\n--- TWFE comparison ---\n")

twfe_black <- feols(share_black ~ post | unitid + year, data = df, cluster = ~stabbr)
twfe_hisp <- feols(share_hisp ~ post | unitid + year, data = df, cluster = ~stabbr)
twfe_minority <- feols(share_minority ~ post | unitid + year, data = df, cluster = ~stabbr)

cat(sprintf("TWFE Black: %.4f (SE: %.4f)\n", coef(twfe_black), se(twfe_black)))
cat(sprintf("TWFE Hispanic: %.4f (SE: %.4f)\n", coef(twfe_hisp), se(twfe_hisp)))
cat(sprintf("TWFE Minority: %.4f (SE: %.4f)\n", coef(twfe_minority), se(twfe_minority)))

cat(sprintf("\nCS vs TWFE (Black): CS = %.4f, TWFE = %.4f, Ratio = %.2f\n",
            agg_black$overall.att, coef(twfe_black),
            agg_black$overall.att / coef(twfe_black)))

## -------------------------------------------------------------------
## 6. Cascade analysis: effects by institution size
##    Large institutions (flagships/research universities) vs small
## -------------------------------------------------------------------
cat("\n--- Cascade analysis by institution size ---\n")

cascade_results <- list()
size_labels <- c("Small", "Medium", "Large")

for (q in 1:3) {
  df_q <- df %>% filter(size_q == q)
  n_inst <- n_distinct(df_q$unitid)
  n_treated <- n_distinct(df_q$unitid[df_q$first_treat > 0])

  if (n_treated < 3 || n_inst < 10) {
    cat(sprintf("  %s (Q%d): too few units (n_inst=%d, n_treated=%d), skipping\n",
                size_labels[q], q, n_inst, n_treated))
    next
  }

  tryCatch({
    cs_q <- att_gt(
      yname = "share_minority",
      tname = "year",
      idname = "unitid",
      gname = "first_treat",
      data = df_q,
      control_group = "nevertreated",
      est_method = "dr",
      bstrap = TRUE,
      biters = 500
    )
    agg_q <- aggte(cs_q, type = "simple")
    cascade_results[[as.character(q)]] <- list(
      size_label = size_labels[q],
      att = agg_q$overall.att,
      se = agg_q$overall.se,
      n_inst = n_inst,
      n_treated = n_treated
    )
    cat(sprintf("  %s (Q%d): ATT = %.4f (SE: %.4f), n_inst=%d, n_treated=%d\n",
                size_labels[q], q, agg_q$overall.att, agg_q$overall.se, n_inst, n_treated))
  }, error = function(e) {
    cat(sprintf("  %s (Q%d): error: %s\n", size_labels[q], q, e$message))
  })
}

## -------------------------------------------------------------------
## 7. White enrollment share (placebo)
## -------------------------------------------------------------------
cat("\n--- Placebo: White enrollment share ---\n")

cs_white <- att_gt(
  yname = "share_white",
  tname = "year",
  idname = "unitid",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)

agg_white <- aggte(cs_white, type = "simple")
cat(sprintf("Overall ATT (White share): %.4f (SE: %.4f, p: %.4f)\n",
            agg_white$overall.att, agg_white$overall.se,
            2 * pnorm(-abs(agg_white$overall.att / agg_white$overall.se))))

## -------------------------------------------------------------------
## 8. Save results
## -------------------------------------------------------------------
results <- list(
  cs_black = cs_black,
  cs_hisp = cs_hisp,
  cs_minority = cs_minority,
  cs_white = cs_white,
  es_black = es_black,
  es_hisp = es_hisp,
  es_minority = es_minority,
  agg_black = agg_black,
  agg_hisp = agg_hisp,
  agg_minority = agg_minority,
  agg_white = agg_white,
  twfe_black = twfe_black,
  twfe_hisp = twfe_hisp,
  twfe_minority = twfe_minority,
  cascade_results = cascade_results,
  analysis_sample = df
)

saveRDS(results, "../data/main_results.rds")

## Write diagnostics.json for validator
jsonlite::write_json(
  list(
    n_treated = n_distinct(df$unitid[df$first_treat > 0]),
    n_pre = length(unique(df$year[df$year < 2007])),  # earliest treatment
    n_obs = nrow(df)
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

cat("\n=== Main analysis complete ===\n")
