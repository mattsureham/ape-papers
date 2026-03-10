## =============================================================================
## 03_main_analysis.R — Main regressions
## apep_0571: Voting reform and public safety in Chile
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("Panel:", nrow(panel), "obs,", n_distinct(panel$comuna_clean), "comunas\n")
cat("Years:", paste(sort(unique(panel$year)), collapse=", "), "\n")

## ===========================================================================
## 1. MAIN SPECIFICATION: Continuous-treatment DiD
## ===========================================================================
cat("\n=== MAIN RESULTS ===\n")

# Specification: Y_it = a_i + g_t + beta * (TurnoutDecline_i * Post_t) + e_it
# Treatment: turnout_decline_pct (percentage point decline, 2008→2012)
# Post: year >= 2018 (we exclude 2012, so post means 2018-2024)

# Main result: ln(total crime)
m1 <- feols(ln_total ~ turnout_decline_pct:post | comuna_clean + year,
            data = panel, cluster = ~comuna_clean)

# Police-discretionary crime (treatment group)
m2 <- feols(ln_discretionary ~ turnout_decline_pct:post | comuna_clean + year,
            data = panel, cluster = ~comuna_clean)

# Non-discretionary crime (PLACEBO)
m3 <- feols(ln_nondiscretionary ~ turnout_decline_pct:post | comuna_clean + year,
            data = panel, cluster = ~comuna_clean)

# Crime subtypes
m4_robbery <- feols(ln_robbery ~ turnout_decline_pct:post | comuna_clean + year,
                    data = panel, cluster = ~comuna_clean)
m5_drugs <- feols(ln_drugs ~ turnout_decline_pct:post | comuna_clean + year,
                  data = panel, cluster = ~comuna_clean)
m6_dv <- feols(ln_dv ~ turnout_decline_pct:post | comuna_clean + year,
               data = panel, cluster = ~comuna_clean)
m7_homicide <- feols(ln_homicide ~ turnout_decline_pct:post | comuna_clean + year,
                     data = panel, cluster = ~comuna_clean)
m8_burglary <- feols(ln_burglary ~ turnout_decline_pct:post | comuna_clean + year,
                     data = panel, cluster = ~comuna_clean)

cat("\n--- Main Table ---\n")
etable(m1, m2, m3, m4_robbery, m5_drugs, m6_dv, m7_homicide,
       headers = c("Total", "Discretionary", "Non-discr.", "Robbery",
                    "Drugs", "Dom.Viol.", "Homicide"),
       se.below = TRUE, fitstat = c("n", "r2"))

# Save coefficients for figure/table generation
main_results <- data.frame(
  outcome = c("Total crime", "Discretionary", "Non-discretionary",
              "Robbery", "Drugs", "Domestic violence", "Homicide", "Burglary"),
  beta = c(coef(m1)["turnout_decline_pct:post"],
           coef(m2)["turnout_decline_pct:post"],
           coef(m3)["turnout_decline_pct:post"],
           coef(m4_robbery)["turnout_decline_pct:post"],
           coef(m5_drugs)["turnout_decline_pct:post"],
           coef(m6_dv)["turnout_decline_pct:post"],
           coef(m7_homicide)["turnout_decline_pct:post"],
           coef(m8_burglary)["turnout_decline_pct:post"]),
  se = c(se(m1)["turnout_decline_pct:post"],
         se(m2)["turnout_decline_pct:post"],
         se(m3)["turnout_decline_pct:post"],
         se(m4_robbery)["turnout_decline_pct:post"],
         se(m5_drugs)["turnout_decline_pct:post"],
         se(m6_dv)["turnout_decline_pct:post"],
         se(m7_homicide)["turnout_decline_pct:post"],
         se(m8_burglary)["turnout_decline_pct:post"]),
  type = c("aggregate", "aggregate", "placebo",
           "discretionary", "discretionary", "placebo", "placebo", "discretionary")
)
main_results$ci_lo <- main_results$beta - 1.96 * main_results$se
main_results$ci_hi <- main_results$beta + 1.96 * main_results$se
main_results$pval <- 2 * pnorm(-abs(main_results$beta / main_results$se))
main_results$stars <- ifelse(main_results$pval < 0.01, "***",
                      ifelse(main_results$pval < 0.05, "**",
                      ifelse(main_results$pval < 0.10, "*", "")))

cat("\n--- Coefficient Summary ---\n")
print(main_results %>% mutate(across(where(is.numeric), ~round(., 4))))

## ===========================================================================
## 2. EVENT STUDY
## ===========================================================================
cat("\n=== EVENT STUDY ===\n")

# Create event-time dummies (base year = 2011)
panel <- panel %>%
  mutate(event_year = factor(year, levels = c(2011, 2010, 2018:2024)))

# Total crime
es_total <- feols(ln_total ~ i(year, turnout_decline_pct, ref = 2011) |
                    comuna_clean + year,
                  data = panel, cluster = ~comuna_clean)

# Discretionary crime
es_disc <- feols(ln_discretionary ~ i(year, turnout_decline_pct, ref = 2011) |
                   comuna_clean + year,
                 data = panel, cluster = ~comuna_clean)

# Non-discretionary (placebo)
es_nondisc <- feols(ln_nondiscretionary ~ i(year, turnout_decline_pct, ref = 2011) |
                      comuna_clean + year,
                    data = panel, cluster = ~comuna_clean)

cat("Event study estimates (total crime):\n")
summary(es_total)

# Extract event study coefficients
extract_es <- function(model, outcome_label) {
  cf <- coeftable(model)
  rows <- grepl("turnout_decline_pct", rownames(cf))
  if (sum(rows) == 0) return(NULL)
  df <- data.frame(
    outcome = outcome_label,
    year = as.integer(gsub(".*year::([0-9]+):.*", "\\1", rownames(cf)[rows])),
    beta = cf[rows, "Estimate"],
    se = cf[rows, "Std. Error"],
    stringsAsFactors = FALSE
  )
  df$ci_lo <- df$beta - 1.96 * df$se
  df$ci_hi <- df$beta + 1.96 * df$se
  # Add base year
  df <- bind_rows(df, data.frame(outcome = outcome_label, year = 2011,
                                  beta = 0, se = 0, ci_lo = 0, ci_hi = 0))
  df
}

es_data <- bind_rows(
  extract_es(es_total, "Total crime"),
  extract_es(es_disc, "Discretionary crime"),
  extract_es(es_nondisc, "Non-discretionary (placebo)")
)

## ===========================================================================
## 3. PRE-TREND TEST
## ===========================================================================
cat("\n=== PRE-TREND TEST ===\n")

# Joint F-test on pre-period coefficients
pre_coefs <- coeftable(es_total)
pre_rows <- grepl("year::2010:", rownames(pre_coefs))
if (sum(pre_rows) > 0) {
  pre_f <- wald(es_total, "year::2010")
  cat("  Joint F-test on pre-period (2010):\n")
  cat("    F =", round(pre_f$stat, 3), ", p =", round(pre_f$p, 4), "\n")
}

## ===========================================================================
## 4. HETEROGENEITY: By turnout decline tercile
## ===========================================================================
cat("\n=== HETEROGENEITY ===\n")

# The theory predicts: effects should be strongest in comunas with largest
# decline (= poorer comunas where more voters exited)
panel <- panel %>%
  mutate(high_decline = as.integer(decline_tercile == 3),
         mid_decline = as.integer(decline_tercile == 2))

het_total <- feols(ln_total ~ high_decline:post + mid_decline:post |
                     comuna_clean + year,
                   data = panel, cluster = ~comuna_clean)
cat("Heterogeneity by decline tercile (total crime):\n")
summary(het_total)

# By young vs old turnout gap
panel <- panel %>%
  mutate(young_exit = young_turnout < median(young_turnout, na.rm = TRUE))

het_young <- feols(ln_discretionary ~ turnout_decline_pct:post:young_exit +
                     turnout_decline_pct:post |
                     comuna_clean + year,
                   data = panel, cluster = ~comuna_clean)
cat("\nHeterogeneity by youth exit (discretionary crime):\n")
summary(het_young)

## ===========================================================================
## SAVE ALL RESULTS
## ===========================================================================
fwrite(main_results, file.path(data_dir, "main_results.csv"))
fwrite(es_data, file.path(data_dir, "event_study_data.csv"))

# Save model objects for table generation
saveRDS(list(m1=m1, m2=m2, m3=m3, m4=m4_robbery, m5=m5_drugs,
             m6=m6_dv, m7=m7_homicide, m8=m8_burglary,
             es_total=es_total, es_disc=es_disc, es_nondisc=es_nondisc,
             het_total=het_total, het_young=het_young),
        file.path(data_dir, "models.rds"))

cat("\n=== Main analysis complete ===\n")
