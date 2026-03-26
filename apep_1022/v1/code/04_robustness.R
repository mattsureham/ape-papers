## 04_robustness.R — Robustness checks
## apep_1022: Affirmative action bans and minority enrollment cascades

source("00_packages.R")

cat("=== Robustness Checks ===\n")

results <- readRDS("../data/main_results.rds")
df <- results$analysis_sample

## -------------------------------------------------------------------
## 1. Not-yet-treated control group (instead of never-treated)
## -------------------------------------------------------------------
cat("\n--- Alternative control: not-yet-treated ---\n")

cs_nyt <- att_gt(
  yname = "share_minority",
  tname = "year",
  idname = "unitid",
  gname = "first_treat",
  data = df,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)

agg_nyt <- aggte(cs_nyt, type = "simple")
cat(sprintf("ATT (not-yet-treated control): %.4f (SE: %.4f)\n",
            agg_nyt$overall.att, agg_nyt$overall.se))

## -------------------------------------------------------------------
## 2. Cohort-specific effects
## -------------------------------------------------------------------
cat("\n--- Cohort-specific effects ---\n")

agg_group <- aggte(results$cs_minority, type = "group")
cat("Group-specific ATTs:\n")
for (i in seq_along(agg_group$egt)) {
  cat(sprintf("  Cohort %d: ATT = %.4f (SE: %.4f)\n",
              agg_group$egt[i], agg_group$att.egt[i], agg_group$se.egt[i]))
}

## -------------------------------------------------------------------
## 3. Enrollment LEVELS (not shares) — test displacement vs loss
## -------------------------------------------------------------------
cat("\n--- Enrollment levels (not shares) ---\n")

# Log enrollment of minority students
df <- df %>% mutate(
  log_black = log(enroll_black + 1),
  log_hisp = log(enroll_hisp + 1),
  log_minority = log(enroll_black + enroll_hisp + 1),
  log_total = log(enroll_total)
)

cs_level <- att_gt(
  yname = "log_minority",
  tname = "year",
  idname = "unitid",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)

agg_level <- aggte(cs_level, type = "simple")
cat(sprintf("ATT (log minority enrollment): %.4f (SE: %.4f, p: %.4f)\n",
            agg_level$overall.att, agg_level$overall.se,
            2 * pnorm(-abs(agg_level$overall.att / agg_level$overall.se))))

# Total enrollment (test whether bans reduce total enrollment)
cs_total <- att_gt(
  yname = "log_total",
  tname = "year",
  idname = "unitid",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)

agg_total <- aggte(cs_total, type = "simple")
cat(sprintf("ATT (log total enrollment): %.4f (SE: %.4f, p: %.4f)\n",
            agg_total$overall.att, agg_total$overall.se,
            2 * pnorm(-abs(agg_total$overall.att / agg_total$overall.se))))

## -------------------------------------------------------------------
## 4. Drop one state at a time (leave-one-out)
## -------------------------------------------------------------------
cat("\n--- Leave-one-out (drop one treatment state) ---\n")

ban_states <- c("MI", "NE", "AZ", "NH", "OK", "ID")
loo_results <- list()

for (st in ban_states) {
  df_loo <- df %>% filter(stabbr != st)
  tryCatch({
    cs_loo <- att_gt(
      yname = "share_minority",
      tname = "year",
      idname = "unitid",
      gname = "first_treat",
      data = df_loo,
      control_group = "nevertreated",
      est_method = "dr",
      bstrap = TRUE,
      biters = 500
    )
    agg_loo <- aggte(cs_loo, type = "simple")
    loo_results[[st]] <- list(
      dropped = st,
      att = agg_loo$overall.att,
      se = agg_loo$overall.se
    )
    cat(sprintf("  Drop %s: ATT = %.4f (SE: %.4f)\n", st,
                agg_loo$overall.att, agg_loo$overall.se))
  }, error = function(e) {
    cat(sprintf("  Drop %s: error: %s\n", st, e$message))
  })
}

## -------------------------------------------------------------------
## 5. Sun-Abraham estimator (alternative heterogeneity-robust)
## -------------------------------------------------------------------
cat("\n--- Sun-Abraham (fixest::sunab) ---\n")

df_sa <- df %>% filter(first_treat > 0 | first_treat == 0)
# For sunab, need treatment year variable where untreated = large number
df_sa <- df_sa %>%
  mutate(first_treat_sa = ifelse(first_treat == 0, 10000, first_treat))

sa_black <- feols(share_black ~ sunab(first_treat_sa, year) | unitid + year,
                  data = df_sa, cluster = ~stabbr)
sa_hisp <- feols(share_hisp ~ sunab(first_treat_sa, year) | unitid + year,
                 data = df_sa, cluster = ~stabbr)
sa_minority <- feols(share_minority ~ sunab(first_treat_sa, year) | unitid + year,
                     data = df_sa, cluster = ~stabbr)

cat(sprintf("Sun-Abraham ATT Black: %.4f (SE: %.4f)\n",
            summary(sa_black, agg = "att")$coeftable[1, 1],
            summary(sa_black, agg = "att")$coeftable[1, 2]))
cat(sprintf("Sun-Abraham ATT Hispanic: %.4f (SE: %.4f)\n",
            summary(sa_hisp, agg = "att")$coeftable[1, 1],
            summary(sa_hisp, agg = "att")$coeftable[1, 2]))
cat(sprintf("Sun-Abraham ATT Minority: %.4f (SE: %.4f)\n",
            summary(sa_minority, agg = "att")$coeftable[1, 1],
            summary(sa_minority, agg = "att")$coeftable[1, 2]))

## -------------------------------------------------------------------
## 6. Save robustness results
## -------------------------------------------------------------------
# Extract SA coefficients before saving (model objects don't serialize well)
sa_coefs <- list(
  black = list(att = summary(sa_black, agg = "att")$coeftable[1, 1],
               se = summary(sa_black, agg = "att")$coeftable[1, 2],
               pval = summary(sa_black, agg = "att")$coeftable[1, 4]),
  hisp = list(att = summary(sa_hisp, agg = "att")$coeftable[1, 1],
              se = summary(sa_hisp, agg = "att")$coeftable[1, 2],
              pval = summary(sa_hisp, agg = "att")$coeftable[1, 4]),
  minority = list(att = summary(sa_minority, agg = "att")$coeftable[1, 1],
                  se = summary(sa_minority, agg = "att")$coeftable[1, 2],
                  pval = summary(sa_minority, agg = "att")$coeftable[1, 4])
)

robust <- list(
  nyt = agg_nyt,
  cohort = agg_group,
  level_minority = agg_level,
  level_total = agg_total,
  loo = loo_results,
  sa_coefs = sa_coefs,
  cs_level = cs_level,
  cs_total = cs_total
)

saveRDS(robust, "../data/robustness_results.rds")
cat("\n=== Robustness complete ===\n")
