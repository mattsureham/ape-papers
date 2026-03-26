## 04_robustness.R — Robustness checks and placebo tests
## APEP-1033: Pouring Risk — Raw Milk Legalization and Foodborne Illness

source("00_packages.R")

cat("=== Robustness Checks ===\n")

panel    <- read_csv("../data/panel.csv", show_col_types = FALSE)
panel_cs <- read_csv("../data/panel_cs.csv", show_col_types = FALSE)

## ---- 1. Placebo: Pasteurized dairy outbreaks ----
cat("\n--- Placebo: Pasteurized Dairy Outbreaks ---\n")
m_placebo_past <- fepois(outbreaks_past ~ legal | state_abbr + year,
                         data = panel, cluster = ~state_abbr)
cat("Pasteurized dairy (should be null):\n")
summary(m_placebo_past)

## ---- 2. Placebo: Non-dairy foodborne outbreaks ----
cat("\n--- Placebo: Non-Dairy Foodborne Outbreaks ---\n")
m_placebo_nondairy <- fepois(outbreaks_nondairy ~ legal | state_abbr + year,
                             data = panel, cluster = ~state_abbr)
cat("Non-dairy foodborne (should be null):\n")
summary(m_placebo_nondairy)

## ---- 3. OLS on log(1+Y) ----
cat("\n--- OLS: log(1 + outbreaks) ---\n")
panel <- panel %>% mutate(log_outbreaks = log1p(outbreaks_unpast))

m_log <- feols(log_outbreaks ~ legal | state_abbr + year,
               data = panel, cluster = ~state_abbr)
cat("OLS log(1+Y):\n")
summary(m_log)

## ---- 4. OLS on asinh(outbreaks) ----
cat("\n--- OLS: asinh(outbreaks) ---\n")
panel <- panel %>% mutate(asinh_outbreaks = asinh(outbreaks_unpast))

m_asinh <- feols(asinh_outbreaks ~ legal | state_abbr + year,
                 data = panel, cluster = ~state_abbr)
cat("OLS asinh(Y):\n")
summary(m_asinh)

## ---- 5. Wild Cluster Bootstrap (main Poisson specification) ----
cat("\n--- Wild Cluster Bootstrap ---\n")

## WCB requires OLS — apply to extensive margin
panel_cs <- panel_cs %>%
  mutate(any_outbreak = as.integer(outbreaks_unpast > 0))

m_ols_for_wcb <- feols(any_outbreak ~ post | state_abbr + year,
                       data = panel_cs, cluster = ~state_abbr)

wcb_result <- tryCatch({
  boottest(m_ols_for_wcb,
           param    = "post",
           B        = 9999,
           clustid  = "state_abbr",
           type     = "rademacher")
}, error = function(e) {
  cat("WCB error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(wcb_result)) {
  cat("Wild Cluster Bootstrap p-value:", wcb_result$p_val, "\n")
  cat("WCB 95% CI:", wcb_result$conf_int, "\n")
}

## ---- 6. Leave-one-state-out jackknife ----
cat("\n--- Leave-One-State-Out ---\n")

treated_states <- unique(panel_cs$state_abbr[panel_cs$first_treat_cs > 0 &
                                               !is.na(panel_cs$first_treat_cs)])

jackknife_results <- map_dfr(treated_states, function(drop_st) {
  sub <- panel_cs %>% filter(state_abbr != drop_st)
  m <- tryCatch({
    fepois(outbreaks_unpast ~ post | state_abbr + year,
           data = sub, cluster = ~state_abbr)
  }, error = function(e) NULL)

  if (!is.null(m)) {
    tibble(dropped = drop_st,
           coef = coef(m)["post"],
           se   = se(m)["post"])
  }
})

if (nrow(jackknife_results) > 0) {
  cat("Jackknife results (dropping one treated state at a time):\n")
  print(jackknife_results, n = 20)
  cat("Range of coefficients:", range(jackknife_results$coef), "\n")
  cat("Mean:", mean(jackknife_results$coef), "\n")
}

## ---- 7. Restrict treatment to states with retail/farm-gate legalization ----
cat("\n--- Restricted Treatment: Farm-gate+ only (exclude herdshare-only) ---\n")

treatment <- read_csv("../data/treatment_coding.csv", show_col_types = FALSE)
fg_states <- treatment %>%
  filter(category %in% c("R", "F") & is.finite(first_legal_year) & first_legal_year > 0) %>%
  pull(state_abbr)

cat("Farm-gate+ newly-treated states:", paste(fg_states, collapse = ", "), "\n")

panel_fg <- panel_cs %>%
  filter(first_treat_cs == 0 | state_abbr %in% fg_states)

m_fg <- tryCatch({
  fepois(outbreaks_unpast ~ post | state_abbr + year,
         data = panel_fg, cluster = ~state_abbr)
}, error = function(e) {
  cat("Farm-gate restriction failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(m_fg)) {
  cat("Farm-gate+ only:\n")
  summary(m_fg)
}

## ---- Save robustness results ----
rob_results <- list(
  placebo_pasteurized = m_placebo_past,
  placebo_nondairy    = m_placebo_nondairy,
  ols_log             = m_log,
  ols_asinh           = m_asinh,
  wcb                 = wcb_result,
  jackknife           = jackknife_results,
  farmgate_only       = m_fg
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
