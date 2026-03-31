## 04_robustness.R — Robustness checks for apep_1228
## GIPP waterbed effect in UK insurance

source("00_packages.R")

data_dir <- "../data"
boe_panel <- readRDS(file.path(data_dir, "boe_panel.rds"))
firms_panel <- readRDS(file.path(data_dir, "firms_panel.rds"))

## Reconstruct analysis variables
boe_panel <- boe_panel %>%
  mutate(
    rel_q = (year - 2022) * 4 + q - 1,
    line_id = as.factor(line),
    quarter_id = as.factor(quarter),
    is_motor = as.integer(line %in% c("Motor liability", "Motor other")),
    is_property = as.integer(line == "Property"),
    motor_post = is_motor * post,
    property_post = is_property * post
  )

## ============================================================
## 1. Placebo Treatment Date: 2020Q1 (pre-COVID, pre-GIPP)
## ============================================================
cat("=== PLACEBO: Treatment at 2020Q1 ===\n")
boe_pre <- boe_panel %>%
  filter(time < 2022.0) %>%
  mutate(
    placebo_post = as.integer(time >= 2020.0),
    placebo_treat = gipp_target * placebo_post,
    motor_placebo = is_motor * placebo_post,
    property_placebo = is_property * placebo_post
  )

m_placebo1 <- feols(log_nwp ~ placebo_treat | line_id + quarter_id,
                    data = boe_pre, cluster = ~line_id)
cat("Placebo NWP:\n")
print(summary(m_placebo1))

m_placebo2 <- feols(loss_ratio ~ placebo_treat | line_id + quarter_id,
                    data = boe_pre, cluster = ~line_id)
cat("\nPlacebo Loss Ratio:\n")
print(summary(m_placebo2))

## Separate motor/property placebo
m_placebo3 <- feols(log_nwp ~ motor_placebo + property_placebo | line_id + quarter_id,
                    data = boe_pre, cluster = ~line_id)
cat("\nPlacebo Motor/Property NWP:\n")
print(summary(m_placebo3))

## ============================================================
## 2. Drop COVID quarters (2020Q1-2021Q2)
## ============================================================
cat("\n=== ROBUSTNESS: Drop COVID quarters ===\n")
boe_no_covid <- boe_panel %>%
  filter(!(time >= 2020.0 & time < 2021.5))

m_nc1 <- feols(log_nwp ~ motor_post + property_post | line_id + quarter_id,
               data = boe_no_covid, cluster = ~line_id)
cat("No-COVID NWP:\n")
print(summary(m_nc1))

m_nc2 <- feols(loss_ratio ~ motor_post + property_post | line_id + quarter_id,
               data = boe_no_covid, cluster = ~line_id)
cat("\nNo-COVID Loss Ratio:\n")
print(summary(m_nc2))

## ============================================================
## 3. Alternative control group: drop Medical & Income Protection
##    (may be affected by COVID claims differently)
## ============================================================
cat("\n=== ROBUSTNESS: Restricted control group ===\n")
boe_restricted <- boe_panel %>%
  filter(!(line %in% c("Medical expense", "Income protection")))

m_rc1 <- feols(log_nwp ~ motor_post + property_post | line_id + quarter_id,
               data = boe_restricted, cluster = ~line_id)
cat("Restricted controls NWP:\n")
print(summary(m_rc1))

m_rc2 <- feols(loss_ratio ~ motor_post + property_post | line_id + quarter_id,
               data = boe_restricted, cluster = ~line_id)
cat("\nRestricted controls Loss Ratio:\n")
print(summary(m_rc2))

## ============================================================
## 4. Levels instead of logs (NWP in billions)
## ============================================================
cat("\n=== ROBUSTNESS: NWP in levels (billions) ===\n")
boe_panel$nwp_bn <- boe_panel$nwp / 1e9

m_lev <- feols(nwp_bn ~ motor_post + property_post | line_id + quarter_id,
               data = boe_panel, cluster = ~line_id)
cat("Levels NWP (GBP bn):\n")
print(summary(m_lev))

## ============================================================
## 5. Pre-trend test: joint F-test on pre-period event study coefficients
## ============================================================
cat("\n=== PRE-TREND TEST ===\n")
m_event_nwp <- feols(log_nwp ~ i(rel_q, gipp_target, ref = -1) | line_id + quarter_id,
                     data = boe_panel, cluster = ~line_id)

## Test joint significance of all pre-period coefficients
pre_coefs <- grep("rel_q::-[0-9]", names(coef(m_event_nwp)), value = TRUE)
cat("Pre-period coefficients (", length(pre_coefs), "coefs):\n")
pre_vals <- coef(m_event_nwp)[pre_coefs]
cat("Range:", round(range(pre_vals), 4), "\n")
cat("Mean:", round(mean(pre_vals), 4), "\n")

wald_result <- tryCatch(
  wald(m_event_nwp, pre_coefs),
  error = function(e) {
    cat("Wald test error:", e$message, "\n")
    NULL
  }
)
if (!is.null(wald_result)) {
  cat("Wald test for joint pre-trend significance:\n")
  print(wald_result)
}

## ============================================================
## 6. Firm-level: placebo outcome (claims acceptance for low-GIPP products)
## ============================================================
cat("\n=== FIRM PLACEBO: Low-GIPP products ===\n")
## For firm-level, compare high vs low GIPP products (not post dummy, which is collinear)
firms_both <- firms_panel %>%
  filter(gipp_exposure %in% c("high", "low"))

m_firm_placebo <- feols(claims_freq_mid ~ treat_post | product_category + year,
                        data = firms_both, cluster = ~firm_name)
cat("High vs Low GIPP products claims frequency:\n")
print(summary(m_firm_placebo))

## ============================================================
## 7. Save all robustness models
## ============================================================
robustness_models <- list(
  placebo_nwp = m_placebo1,
  placebo_lr = m_placebo2,
  placebo_motor_prop = m_placebo3,
  no_covid_nwp = m_nc1,
  no_covid_lr = m_nc2,
  restricted_nwp = m_rc1,
  restricted_lr = m_rc2,
  levels_nwp = m_lev,
  event_nwp = m_event_nwp
)
saveRDS(robustness_models, file.path(data_dir, "robustness_models.rds"))

cat("\nRobustness checks complete.\n")
