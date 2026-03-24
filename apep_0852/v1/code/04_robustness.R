## 04_robustness.R — Robustness checks and heterogeneity analysis
## Placebos, jackknife, heterogeneity by income

library(data.table)
library(fixest)
library(jsonlite)

# Set working directory to paper root (parent of code/)
paper_dir <- tryCatch(
  normalizePath(file.path(dirname(sys.frame(1)$ofile), ".."), mustWork = FALSE),
  error = function(e) normalizePath(file.path(getwd(), ".."), mustWork = FALSE)
)
if (dir.exists(paper_dir)) setwd(paper_dir)
datadir <- "data"

cat("=== Robustness Checks ===\n")

df <- fread(file.path(datadir, "analysis_data.csv"))

# Reconstruct interactions
df[, treat_x_post := treat_state * post]
df[, school_x_post := has_school_age * post]
df[, treat_x_school := treat_state * has_school_age]
df[, treat_x_school_x_post := treat_state * has_school_age * post]
df[, state_school := paste(GESTFIPS, has_school_age, sep = "_")]

# ── 1. PLACEBO: Young children only (0-4) ───────────────────────
cat("\n--- Placebo: Young-child-only households (not in school) ---\n")

# Households with only young children (0-4) shouldn't benefit from school meals
df[, has_young_only := as.integer(young_only == 1)]
df[, treat_x_young_x_post := treat_state * has_young_only * post]
df[, young_x_post := has_young_only * post]
df[, treat_x_young := treat_state * has_young_only]

# Restrict to HH with young-only or no children (exclude school-age to avoid contamination)
placebo_df <- df[has_school_age == 0]

m_placebo <- feols(food_insecure ~ treat_x_young_x_post + treat_x_post +
                     young_x_post + treat_x_young |
                     GESTFIPS + year,
                   data = placebo_df, weights = ~wt, cluster = ~GESTFIPS)
cat("Placebo (young children 0-4 vs no children):\n")
print(summary(m_placebo))

# ── 2. LEAVE-ONE-STATE-OUT JACKKNIFE ─────────────────────────────
cat("\n--- Leave-one-state-out jackknife ---\n")

treated_states <- unique(df[treat_state == 1]$GESTFIPS)
jack_coefs <- numeric(length(treated_states))
names(jack_coefs) <- treated_states

for (i in seq_along(treated_states)) {
  s <- treated_states[i]
  m_jack <- feols(food_insecure ~ treat_x_school_x_post + treat_x_post +
                    school_x_post + treat_x_school |
                    GESTFIPS + year,
                  data = df[GESTFIPS != s], weights = ~wt, cluster = ~GESTFIPS)
  jack_coefs[i] <- coef(m_jack)["treat_x_school_x_post"]
}

cat("Jackknife estimates (leave-one-treated-state-out):\n")
state_names <- c("6" = "CA", "23" = "ME", "8" = "CO", "26" = "MI",
                 "27" = "MN", "50" = "VT")
for (i in seq_along(jack_coefs)) {
  s <- names(jack_coefs)[i]
  sn <- ifelse(s %in% names(state_names), state_names[s], s)
  cat(sprintf("  Drop %s: %.4f\n", sn, jack_coefs[i]))
}
cat(sprintf("  Range: [%.4f, %.4f]\n", min(jack_coefs), max(jack_coefs)))

# ── 3. HETEROGENEITY BY INCOME ───────────────────────────────────
cat("\n--- Heterogeneity: Low-income vs higher-income ---\n")

# HRPOOR = 1 if income below 185% poverty
m_lowinc <- feols(food_insecure ~ treat_x_school_x_post + treat_x_post +
                    school_x_post + treat_x_school |
                    GESTFIPS + year,
                  data = df[low_income == 1], weights = ~wt, cluster = ~GESTFIPS)

m_highinc <- feols(food_insecure ~ treat_x_school_x_post + treat_x_post +
                     school_x_post + treat_x_school |
                     GESTFIPS + year,
                   data = df[low_income == 0], weights = ~wt, cluster = ~GESTFIPS)

cat("Low-income (<185% FPL):\n")
cat(sprintf("  DDD coef: %.4f (SE: %.4f)\n",
            coef(m_lowinc)["treat_x_school_x_post"],
            se(m_lowinc)["treat_x_school_x_post"]))
cat("Higher-income (≥185% FPL):\n")
cat(sprintf("  DDD coef: %.4f (SE: %.4f)\n",
            coef(m_highinc)["treat_x_school_x_post"],
            se(m_highinc)["treat_x_school_x_post"]))

# ── 4. HETEROGENEITY BY SINGLE PARENT ───────────────────────────
cat("\n--- Heterogeneity: Single-parent vs two-parent ---\n")

m_single <- feols(food_insecure ~ treat_x_school_x_post + treat_x_post +
                    school_x_post + treat_x_school |
                    GESTFIPS + year,
                  data = df[single_parent == 1], weights = ~wt, cluster = ~GESTFIPS)

m_twopar <- feols(food_insecure ~ treat_x_school_x_post + treat_x_post +
                    school_x_post + treat_x_school |
                    GESTFIPS + year,
                  data = df[single_parent == 0], weights = ~wt, cluster = ~GESTFIPS)

cat("Single-parent:\n")
cat(sprintf("  DDD coef: %.4f (SE: %.4f)\n",
            coef(m_single)["treat_x_school_x_post"],
            se(m_single)["treat_x_school_x_post"]))
cat("Two-parent/other:\n")
cat(sprintf("  DDD coef: %.4f (SE: %.4f)\n",
            coef(m_twopar)["treat_x_school_x_post"],
            se(m_twopar)["treat_x_school_x_post"]))

# ── 5. COHORT-SPECIFIC EFFECTS ───────────────────────────────────
cat("\n--- Cohort-specific effects ---\n")

# Cohort 1 only (CA, ME — treated from 2022)
df_c1 <- df[first_treat %in% c(0, 2022)]
df_c1[, post_c1 := as.integer(year >= 2022 & first_treat == 2022)]
df_c1[, ddd_c1 := post_c1 * has_school_age]

m_c1 <- feols(food_insecure ~ ddd_c1 + post_c1 +
                school_x_post + treat_x_school |
                GESTFIPS + year,
              data = df_c1, weights = ~wt, cluster = ~GESTFIPS)

cat(sprintf("Cohort 1 (CA/ME, 2022): DDD = %.4f (SE: %.4f)\n",
            coef(m_c1)["ddd_c1"], se(m_c1)["ddd_c1"]))

# Cohort 2 only (CO, MI, MN, VT — treated from 2023)
df_c2 <- df[first_treat %in% c(0, 2023) & year %in% c(2019, 2021, 2023)]
df_c2[, post_c2 := as.integer(year >= 2023 & first_treat == 2023)]
df_c2[, ddd_c2 := post_c2 * has_school_age]
df_c2[, school_x_post_c2 := has_school_age * as.integer(year >= 2023)]

m_c2 <- feols(food_insecure ~ ddd_c2 + post_c2 +
                school_x_post_c2 + treat_x_school |
                GESTFIPS + year,
              data = df_c2, weights = ~wt, cluster = ~GESTFIPS)

cat(sprintf("Cohort 2 (CO/MI/MN/VT, 2023): DDD = %.4f (SE: %.4f)\n",
            coef(m_c2)["ddd_c2"], se(m_c2)["ddd_c2"]))

# ── 6. BINARY OUTCOME: LOGIT ────────────────────────────────────
cat("\n--- Logit specification ---\n")

m_logit <- feglm(food_insecure ~ treat_x_school_x_post + treat_x_post +
                   school_x_post + treat_x_school +
                   age_ref + female_ref + hhsize |
                   GESTFIPS + year,
                 data = df, weights = ~wt, cluster = ~GESTFIPS,
                 family = binomial(link = "logit"))

cat("Logit DDD (food insecurity):\n")
cat(sprintf("  Log-odds coef: %.4f (SE: %.4f)\n",
            coef(m_logit)["treat_x_school_x_post"],
            se(m_logit)["treat_x_school_x_post"]))
# Average marginal effect approximation
logit_me <- coef(m_logit)["treat_x_school_x_post"] *
  mean(df$food_insecure) * (1 - mean(df$food_insecure))
cat(sprintf("  Approx marginal effect: %.4f\n", logit_me))

# ── Save robustness results ──────────────────────────────────────
rob_results <- list(
  placebo = list(
    coef = coef(m_placebo)["treat_x_young_x_post"],
    se = se(m_placebo)["treat_x_young_x_post"]
  ),
  jackknife = jack_coefs,
  hetero_income = list(
    low = list(coef = coef(m_lowinc)["treat_x_school_x_post"],
               se = se(m_lowinc)["treat_x_school_x_post"]),
    high = list(coef = coef(m_highinc)["treat_x_school_x_post"],
                se = se(m_highinc)["treat_x_school_x_post"])
  ),
  hetero_single = list(
    single = list(coef = coef(m_single)["treat_x_school_x_post"],
                  se = se(m_single)["treat_x_school_x_post"]),
    twopar = list(coef = coef(m_twopar)["treat_x_school_x_post"],
                  se = se(m_twopar)["treat_x_school_x_post"])
  ),
  cohort1 = list(coef = coef(m_c1)["ddd_c1"], se = se(m_c1)["ddd_c1"]),
  cohort2 = list(coef = coef(m_c2)["ddd_c2"], se = se(m_c2)["ddd_c2"]),
  logit_coef = coef(m_logit)["treat_x_school_x_post"],
  logit_me = logit_me
)
saveRDS(rob_results, file.path(datadir, "robustness_results.rds"))

# Save model objects for tables
rob_models <- list(
  m_placebo = m_placebo,
  m_lowinc = m_lowinc, m_highinc = m_highinc,
  m_single = m_single, m_twopar = m_twopar,
  m_c1 = m_c1, m_c2 = m_c2, m_logit = m_logit
)
saveRDS(rob_models, file.path(datadir, "robustness_models.rds"))

cat("\n=== Robustness checks complete ===\n")
