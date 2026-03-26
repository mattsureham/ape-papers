## 03_main_analysis.R — Main DiD regressions
## apep_0986: Forced EPCI Mergers and RN Voting

source("00_packages.R")
data_dir <- "../data"

## ============================================================================
## 1. Load data
## ============================================================================
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

## Drop observations with missing treatment
panel <- panel[!is.na(treated)]
cat(sprintf("Panel: %d obs, %d communes, %d elections\n",
            nrow(panel), uniqueN(panel$code_commune), uniqueN(panel$year)))

## ============================================================================
## 2. Main specification: Binary DiD with commune and election FE
## ============================================================================
cat("\n=== Specification 1: Binary DiD ===\n")

## Y_{c,t} = alpha_c + gamma_t + beta * (Treated_c x Post_t) + epsilon_{c,t}
## Clustered at département level

m1 <- feols(fn_share ~ treat_post | code_commune + year,
            data = panel, cluster = ~dep)
cat("Binary DiD (no controls):\n")
summary(m1)

## With département × year FE (absorbs regional trends)
m2 <- feols(fn_share ~ treat_post | code_commune + dep^year,
            data = panel, cluster = ~dep)
cat("\nBinary DiD (dep x year FE):\n")
summary(m2)

## ============================================================================
## 3. Continuous treatment intensity
## ============================================================================
cat("\n=== Specification 2: Continuous DiD (merger intensity) ===\n")

## Treatment intensity = log(EPCI_pop_2017 / EPCI_pop_2016) × Post
m3 <- feols(fn_share ~ intensity_post | code_commune + year,
            data = panel, cluster = ~dep)
cat("Continuous DiD (no controls):\n")
summary(m3)

m4 <- feols(fn_share ~ intensity_post | code_commune + dep^year,
            data = panel, cluster = ~dep)
cat("\nContinuous DiD (dep x year FE):\n")
summary(m4)

## ============================================================================
## 4. Event study — pre-trends test
## ============================================================================
cat("\n=== Event study ===\n")

## Create election-specific indicators
panel[, year_f := factor(year)]
panel[, event_2007 := as.integer(year == 2007) * treated]
panel[, event_2012 := as.integer(year == 2012) * treated]
panel[, event_2017 := as.integer(year == 2017) * treated]
panel[, event_2022 := as.integer(year == 2022) * treated]

## Event study: omit 2012 as reference period (last pre-treatment)
m_event <- feols(fn_share ~ event_2007 + event_2017 + event_2022 |
                   code_commune + year,
                 data = panel, cluster = ~dep)
cat("Event study (ref = 2012):\n")
summary(m_event)

## ============================================================================
## 5. Secondary outcomes
## ============================================================================
cat("\n=== Secondary outcomes ===\n")

## Turnout
panel[, turnout := exprimes / inscrits * 100]
m_turnout <- feols(turnout ~ treat_post | code_commune + year,
                   data = panel, cluster = ~dep)
cat("Turnout:\n")
summary(m_turnout)

## ============================================================================
## 6. Callaway-Sant'Anna estimator (binary treatment)
## ============================================================================
cat("\n=== Callaway-Sant'Anna ===\n")

## For CS-DiD, treatment timing is the same for all treated (2017)
## So all treated units have the same group (g = 2017)
## This collapses to a standard 2x2 DiD but provides proper inference

## Prepare data for `did` package
cs_data <- panel[, .(
  id = as.numeric(factor(code_commune)),
  time = year,
  treated_first = fifelse(treated == 1, 2017L, 0L),
  fn_share = fn_share
)]

## Run Callaway-Sant'Anna
cs_out <- tryCatch({
  att_gt(
    yname = "fn_share",
    tname = "time",
    idname = "id",
    gname = "treated_first",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    bstrap = TRUE,
    cband = TRUE
  )
}, error = function(e) {
  cat("CS-DiD error:", e$message, "\n")
  NULL
})

if (!is.null(cs_out)) {
  cat("Callaway-Sant'Anna results:\n")
  print(summary(cs_out))

  ## Aggregate to overall ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nOverall ATT:\n")
  print(summary(cs_agg))
}

## ============================================================================
## 7. Save diagnostics
## ============================================================================
diag <- list(
  n_treated = uniqueN(panel[treated == 1, code_commune]),
  n_pre = length(unique(panel[post == 0, year])),
  n_obs = nrow(panel),
  n_control = uniqueN(panel[treated == 0, code_commune]),
  n_clusters = uniqueN(panel$dep),
  mean_fn_pre_treated = mean(panel[treated == 1 & post == 0, fn_share]),
  mean_fn_pre_control = mean(panel[treated == 0 & post == 0, fn_share]),
  sd_fn_pre = sd(panel[post == 0, fn_share])
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved.\n")

## ============================================================================
## 8. Save model objects for table generation
## ============================================================================
save(m1, m2, m3, m4, m_event, m_turnout, cs_out,
     file = file.path(data_dir, "model_objects.RData"))
cat("Model objects saved.\n")
