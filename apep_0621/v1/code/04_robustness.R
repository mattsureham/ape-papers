# =============================================================================
# 04_robustness.R — Robustness checks and placebos
# APEP Working Paper apep_0621
# =============================================================================

source("00_packages.R")

panel_short <- readRDS("../data/panel_short_clean.rds")
state_changes <- readRDS("../data/state_changes.rds")
state_long <- readRDS("../data/state_long_clean.rds")
state_long_bysex <- readRDS("../data/state_long_bysex.rds")
state_long_byrace <- readRDS("../data/state_long_byrace.rds")
state_short_bysex <- readRDS("../data/state_short_bysex.rds")
placebo_old <- readRDS("../data/placebo_old.rds")
mp_dates <- readRDS("../data/mp_adoption_dates.rds")

southern_fips <- c(1, 5, 12, 13, 21, 22, 24, 28, 37, 40, 45, 47, 48, 51, 54)

# =============================================================================
# 1. Pre-treatment balance: 1910 covariates by adoption timing
# =============================================================================
cat("=== Pre-treatment balance ===\n")

balance <- state_changes[, c("statefip", "state_name", "mp_year",
                              "child_labor_1910", "school_attend_1910",
                              "share_male", "share_white", "n_children")]
balance$adoption_group <- cut(balance$mp_year,
                               breaks = c(-Inf, 0.5, 1914, 1918, 1920, Inf),
                               labels = c("Never", "Early", "Middle", "Late", "Post-1920"))

cat("Pre-treatment balance by adoption group:\n")
balance_summ <- aggregate(
  cbind(child_labor_1910, school_attend_1910, share_white) ~ adoption_group,
  data = balance,
  FUN = function(x) round(mean(x), 4)
)
print(balance_summ)

# F-test: do 1910 covariates predict adoption timing?
balance_test <- lm(I(mp_year > 0 & mp_year <= 1919) ~
                     child_labor_1910 + school_attend_1910 + share_white,
                   data = state_changes)
cat("\nF-test for selection into treatment:\n")
print(summary(balance_test))

saveRDS(balance_summ, "../data/balance_table.rds")

# =============================================================================
# 2. Placebo: Children too old to benefit (age 15-18 in 1910 → 1920)
# =============================================================================
cat("\n=== Placebo: older children ===\n")

placebo_old <- merge(placebo_old, mp_dates[, c("statefip", "mp_year")],
                      by = "statefip", all.x = TRUE)
placebo_old$mp_year[is.na(placebo_old$mp_year)] <- 0
placebo_old$treated_by_1920 <- as.integer(placebo_old$mp_year > 0 & placebo_old$mp_year <= 1919)

# Reshape to panel
placebo_panel <- rbind(
  data.frame(statefip = placebo_old$statefip, year = 1910,
             child_labor = placebo_old$child_labor_1910,
             n_children = placebo_old$n_children,
             treated_by_1920 = placebo_old$treated_by_1920,
             post = 0),
  data.frame(statefip = placebo_old$statefip, year = 1920,
             child_labor = placebo_old$child_labor_1920,
             n_children = placebo_old$n_children,
             treated_by_1920 = placebo_old$treated_by_1920,
             post = 1)
)

placebo_did <- feols(
  child_labor ~ treated_by_1920:post | statefip + year,
  data = placebo_panel,
  weights = ~n_children,
  cluster = ~statefip
)
cat("Placebo DiD — Older children (age 15-18 in 1910):\n")
summary(placebo_did)

# =============================================================================
# 3. Heterogeneity by sex (long-run)
# =============================================================================
cat("\n=== Heterogeneity by sex ===\n")

state_long_bysex <- merge(state_long_bysex,
                           mp_dates[, c("statefip", "mp_year")],
                           by = "statefip", all.x = TRUE)
state_long_bysex$mp_year[is.na(state_long_bysex$mp_year)] <- 0
state_long_bysex$mp_exposure <- ifelse(state_long_bysex$mp_year > 0,
                                        pmax(0, 1920 - state_long_bysex$mp_year), 0)
state_long_bysex$treated <- as.integer(state_long_bysex$mp_year > 0 &
                                        state_long_bysex$mp_year <= 1919)

# Males
sei_male <- feols(
  mean_sei_1940 ~ mp_exposure,
  data = state_long_bysex[state_long_bysex$sex == 1, ],
  weights = ~n_children,
  cluster = ~statefip
)
cat("SEI — Males:\n")
summary(sei_male)

# Females
sei_female <- feols(
  mean_sei_1940 ~ mp_exposure,
  data = state_long_bysex[state_long_bysex$sex == 2, ],
  weights = ~n_children,
  cluster = ~statefip
)
cat("\nSEI — Females:\n")
summary(sei_female)

# Short-run child labor by sex
state_short_bysex <- merge(state_short_bysex,
                            mp_dates[, c("statefip", "mp_year")],
                            by = "statefip", all.x = TRUE)
state_short_bysex$mp_year[is.na(state_short_bysex$mp_year)] <- 0
state_short_bysex$treated_by_1920 <- as.integer(state_short_bysex$mp_year > 0 &
                                                  state_short_bysex$mp_year <= 1919)

short_bysex_panel <- rbind(
  data.frame(statefip = state_short_bysex$statefip,
             sex = state_short_bysex$sex,
             year = 1910,
             child_labor = state_short_bysex$child_labor_1910,
             school_attend = state_short_bysex$school_attend_1910,
             n_children = state_short_bysex$n_children,
             treated_by_1920 = state_short_bysex$treated_by_1920,
             post = 0),
  data.frame(statefip = state_short_bysex$statefip,
             sex = state_short_bysex$sex,
             year = 1920,
             child_labor = state_short_bysex$child_labor_1920,
             school_attend = state_short_bysex$school_attend_1920,
             n_children = state_short_bysex$n_children,
             treated_by_1920 = state_short_bysex$treated_by_1920,
             post = 1)
)

did_cl_boys <- feols(
  child_labor ~ treated_by_1920:post | statefip + year,
  data = short_bysex_panel[short_bysex_panel$sex == 1, ],
  weights = ~n_children,
  cluster = ~statefip
)
cat("\nDiD Child Labor — Boys:\n")
summary(did_cl_boys)

did_cl_girls <- feols(
  child_labor ~ treated_by_1920:post | statefip + year,
  data = short_bysex_panel[short_bysex_panel$sex == 2, ],
  weights = ~n_children,
  cluster = ~statefip
)
cat("\nDiD Child Labor — Girls:\n")
summary(did_cl_girls)

# =============================================================================
# 4. Heterogeneity by race (long-run)
# =============================================================================
cat("\n=== Heterogeneity by race ===\n")

state_long_byrace <- merge(state_long_byrace,
                             mp_dates[, c("statefip", "mp_year")],
                             by = "statefip", all.x = TRUE)
state_long_byrace$mp_year[is.na(state_long_byrace$mp_year)] <- 0
state_long_byrace$mp_exposure <- ifelse(state_long_byrace$mp_year > 0,
                                         pmax(0, 1920 - state_long_byrace$mp_year), 0)

sei_white <- feols(
  mean_sei_1940 ~ mp_exposure,
  data = state_long_byrace[state_long_byrace$race_group == "white", ],
  weights = ~n_children,
  cluster = ~statefip
)
cat("SEI — White children:\n")
summary(sei_white)

sei_nonwhite <- feols(
  mean_sei_1940 ~ mp_exposure,
  data = state_long_byrace[state_long_byrace$race_group == "nonwhite", ],
  weights = ~n_children,
  cluster = ~statefip
)
cat("\nSEI — Nonwhite children:\n")
summary(sei_nonwhite)

# =============================================================================
# 5. Unweighted regressions
# =============================================================================
cat("\n=== Unweighted specifications ===\n")

did_cl_unweighted <- feols(
  child_labor ~ treated_by_1920:post | statefip + year,
  data = panel_short,
  cluster = ~statefip
)
cat("DiD Child Labor (unweighted):\n")
summary(did_cl_unweighted)

ols_sei_unweighted <- feols(
  mean_sei_1940 ~ mp_exposure,
  data = state_long,
  cluster = ~statefip
)
cat("\nOLS SEI (unweighted, continuous):\n")
summary(ols_sei_unweighted)

# =============================================================================
# 6. Dose-response: Non-parametric by exposure bins
# =============================================================================
cat("\n=== Dose-response by exposure bins ===\n")

state_long$exposure_bin <- cut(state_long$mp_exposure,
                                breaks = c(-0.5, 0.5, 3.5, 5.5, 7.5, 10),
                                labels = c("0", "1-3", "4-5", "6-7", "8-9"))
dose_response <- aggregate(
  cbind(mean_sei_1940, n_children) ~ exposure_bin,
  data = state_long,
  FUN = mean
)
cat("Mean SEI by exposure bin:\n")
print(dose_response)

# =============================================================================
# Save robustness results
# =============================================================================
robust_results <- list(
  placebo_did = placebo_did,
  sei_male = sei_male,
  sei_female = sei_female,
  did_cl_boys = did_cl_boys,
  did_cl_girls = did_cl_girls,
  sei_white = sei_white,
  sei_nonwhite = sei_nonwhite,
  did_cl_unweighted = did_cl_unweighted,
  ols_sei_unweighted = ols_sei_unweighted,
  balance_test = balance_test,
  balance_summ = balance_summ
)

saveRDS(robust_results, "../data/robust_results.rds")

cat("\n=== Robustness analysis complete ===\n")
