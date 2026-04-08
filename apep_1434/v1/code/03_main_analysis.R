##############################################################################
# 03_main_analysis.R — Reduced form and IV regressions
# apep_1434: When Scandals Go Dark
##############################################################################

source("00_packages.R")

panel <- readRDS("data/analysis_panel.rds")

cat("=== Main Analysis ===\n")
cat("Panel:", nrow(panel), "obs,", n_distinct(panel$agency_code), "agencies,",
    n_distinct(panel$ym), "months\n\n")

###########################################################################
# 1. Reduced form: mega-events → hearings
###########################################################################
cat("--- Reduced Form ---\n")

# RF1: agency + quarter FE
rf1 <- feols(
  n_hearings ~ mega | agency_code + quarter,
  data = panel, cluster = ~agency_code
)

# RF2: agency + year + quarter FE
rf2 <- feols(
  n_hearings ~ mega | agency_code + year + quarter,
  data = panel, cluster = ~agency_code
)

# RF3: agency × year FE (most demanding)
rf3 <- feols(
  n_hearings ~ mega | agency_code^year + quarter,
  data = panel, cluster = ~agency_code
)

# RF4: extensive margin
rf4 <- feols(
  any_hearing ~ mega | agency_code + year + quarter,
  data = panel, cluster = ~agency_code
)

# RF5: IHS outcome
rf5 <- feols(
  ihs_hearings ~ mega | agency_code + year + quarter,
  data = panel, cluster = ~agency_code
)

cat("Reduced form results:\n")
etable(rf1, rf2, rf3, rf4, rf5,
       headers = c("Quarter FE", "Year+Q FE", "Agency×Year", "Extensive", "IHS"))

###########################################################################
# 2. OLS: Scandal interest → hearings
###########################################################################
cat("\n--- OLS ---\n")

ols1 <- feols(
  n_hearings ~ ihs_scandal | agency_code + year + quarter,
  data = panel, cluster = ~agency_code
)

ols2 <- feols(
  n_hearings ~ ihs_scandal + lag1_hearings | agency_code + year + quarter,
  data = panel, cluster = ~agency_code
)

etable(ols1, ols2)

###########################################################################
# 3. First stage: Competing events → scandal interest
###########################################################################
cat("\n--- First Stage ---\n")

fs1 <- feols(
  ihs_scandal ~ mega | agency_code + year + quarter,
  data = panel, cluster = ~agency_code
)

fs2 <- feols(
  ihs_scandal ~ ihs_competing | agency_code + year + quarter,
  data = panel, cluster = ~agency_code
)

fs3 <- feols(
  scandal_interest ~ competing_interest | agency_code + year + quarter,
  data = panel, cluster = ~agency_code
)

cat("First stage:\n")
etable(fs1, fs2, fs3)

###########################################################################
# 4. IV: Competing events → scandal interest → hearings
###########################################################################
cat("\n--- IV ---\n")

# IV with binary instrument
iv1 <- feols(
  n_hearings ~ 1 | agency_code + year + quarter |
    ihs_scandal ~ mega,
  data = panel, cluster = ~agency_code
)

# IV with continuous instrument
iv2 <- feols(
  n_hearings ~ 1 | agency_code + year + quarter |
    ihs_scandal ~ ihs_competing,
  data = panel, cluster = ~agency_code
)

# IV with lag control
iv3 <- feols(
  n_hearings ~ lag1_hearings | agency_code + year + quarter |
    ihs_scandal ~ mega,
  data = panel, cluster = ~agency_code
)

# IV extensive margin
iv4 <- feols(
  any_hearing ~ 1 | agency_code + year + quarter |
    ihs_scandal ~ mega,
  data = panel, cluster = ~agency_code
)

cat("IV results:\n")
etable(iv1, iv2, iv3, iv4)

###########################################################################
# 5. Event study around specific scandals
###########################################################################
cat("\n--- Event Studies ---\n")

scandal_panel <- panel |>
  filter(in_scandal_window, abs(months_to_scandal) <= 6)

if (nrow(scandal_panel) > 50) {
  # Interaction: do mega-events during scandal windows matter more?
  scandal_panel <- scandal_panel |>
    mutate(
      post = as.integer(months_to_scandal >= 0),
      mega_x_post = mega * post
    )

  es2 <- feols(
    n_hearings ~ post + mega + mega_x_post | agency_code,
    data = scandal_panel, cluster = ~agency_code
  )

  cat("Event study N:", nrow(scandal_panel), "\n")
  etable(es2)
}

###########################################################################
# 6. Save
###########################################################################

diagnostics <- list(
  n_treated = n_distinct(panel$agency_code),
  n_pre = length(unique(panel$ym[panel$year < 2014])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

save(rf1, rf2, rf3, rf4, rf5, ols1, ols2,
     fs1, fs2, fs3, iv1, iv2, iv3, iv4,
     file = "data/main_results.RData")

if (exists("es2")) save(es2, file = "data/event_study_results.RData")

cat("\n=== Main analysis complete ===\n")
cat("Diagnostics:", toJSON(diagnostics, auto_unbox = TRUE), "\n")
