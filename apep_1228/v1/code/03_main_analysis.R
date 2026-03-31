## 03_main_analysis.R — Main DiD analysis for apep_1228
## GIPP waterbed effect in UK insurance

source("00_packages.R")

data_dir <- "../data"
boe_panel <- readRDS(file.path(data_dir, "boe_panel.rds"))
firms_panel <- readRDS(file.path(data_dir, "firms_panel.rds"))

## ============================================================
## 1. BoE Line-of-Business DiD: Log NWP
## ============================================================

## Create relative time variable (quarters relative to 2022Q1)
boe_panel <- boe_panel %>%
  mutate(
    rel_q = (year - 2022) * 4 + q - 1,  # 0 = 2022Q1
    line_id = as.factor(line),
    quarter_id = as.factor(quarter)
  )

cat("=== MAIN SPECIFICATION: DiD on Log(NWP) ===\n\n")

## Column (1): Basic DiD
m1 <- feols(log_nwp ~ treat_post | line_id + quarter_id,
            data = boe_panel, cluster = ~line_id)
cat("Model 1 — Basic DiD:\n")
print(summary(m1))

## Column (2): Include line-specific linear trends
boe_panel$line_num <- as.numeric(boe_panel$line_id)
m2 <- feols(log_nwp ~ treat_post | line_id + quarter_id + line_id[time],
            data = boe_panel, cluster = ~line_id)
cat("\nModel 2 — Line-specific trends:\n")
print(summary(m2))

## Column (3): DiD on Loss Ratio (captures waterbed through composition)
m3 <- feols(loss_ratio ~ treat_post | line_id + quarter_id,
            data = boe_panel, cluster = ~line_id)
cat("\nModel 3 — Loss Ratio DiD:\n")
print(summary(m3))

## Column (4): Loss Ratio with line-specific trends
m4 <- feols(loss_ratio ~ treat_post | line_id + quarter_id + line_id[time],
            data = boe_panel, cluster = ~line_id)
cat("\nModel 4 — Loss Ratio with trends:\n")
print(summary(m4))

## ============================================================
## 2. Event Study — Dynamic Treatment Effects
## ============================================================

## Create event time dummies (relative to 2022Q1)
## Bin endpoints: ≤ -8 and ≥ 8
boe_panel <- boe_panel %>%
  mutate(
    rel_q_binned = pmax(pmin(rel_q, 12), -16),
    event_time = factor(rel_q_binned)
  )

## Drop -1 as reference period
m_event_nwp <- feols(log_nwp ~ i(rel_q_binned, gipp_target, ref = -1) | line_id + quarter_id,
                     data = boe_panel, cluster = ~line_id)
cat("\n=== Event Study: Log(NWP) ===\n")
print(summary(m_event_nwp))

m_event_lr <- feols(loss_ratio ~ i(rel_q_binned, gipp_target, ref = -1) | line_id + quarter_id,
                    data = boe_panel, cluster = ~line_id)
cat("\n=== Event Study: Loss Ratio ===\n")
print(summary(m_event_lr))

## ============================================================
## 3. Separate Motor vs Property Effects
## ============================================================

boe_panel <- boe_panel %>%
  mutate(
    is_motor = as.integer(line %in% c("Motor liability", "Motor other")),
    is_property = as.integer(line == "Property"),
    motor_post = is_motor * post,
    property_post = is_property * post
  )

m5 <- feols(log_nwp ~ motor_post + property_post | line_id + quarter_id,
            data = boe_panel, cluster = ~line_id)
cat("\n=== Separate Motor vs Property Effects on Log(NWP) ===\n")
print(summary(m5))

m6 <- feols(loss_ratio ~ motor_post + property_post | line_id + quarter_id,
            data = boe_panel, cluster = ~line_id)
cat("\n=== Separate Motor vs Property Effects on Loss Ratio ===\n")
print(summary(m6))

## ============================================================
## 4. FCA Firm-Level Analysis
## ============================================================

cat("\n=== FCA FIRM-LEVEL ANALYSIS ===\n\n")

## Firm-level DiD using claims frequency midpoint
m_firm1 <- feols(claims_freq_mid ~ treat_post | firm_name + year,
                 data = firms_panel, cluster = ~firm_name)
cat("Firm Model 1 — Claims frequency DiD:\n")
print(summary(m_firm1))

## Claims acceptance rate
m_firm2 <- feols(claims_accept_mid ~ treat_post | firm_name + year,
                 data = firms_panel, cluster = ~firm_name)
cat("\nFirm Model 2 — Claims acceptance rate DiD:\n")
print(summary(m_firm2))

## Claims complaints
m_firm3 <- feols(claims_complaints_mid ~ treat_post | firm_name + year,
                 data = firms_panel, cluster = ~firm_name)
cat("\nFirm Model 3 — Claims complaints DiD:\n")
print(summary(m_firm3))

## ============================================================
## 5. Save results and write diagnostics
## ============================================================

## Key estimates for the paper
results <- list(
  boe_did_nwp = list(
    coef = coef(m1)["treat_post"],
    se = sqrt(diag(vcov(m1, type = "cluster")))["treat_post"],
    n = nobs(m1)
  ),
  boe_did_nwp_trends = list(
    coef = coef(m2)["treat_post"],
    se = sqrt(diag(vcov(m2, type = "cluster")))["treat_post"],
    n = nobs(m2)
  ),
  boe_did_lr = list(
    coef = coef(m3)["treat_post"],
    se = sqrt(diag(vcov(m3, type = "cluster")))["treat_post"],
    n = nobs(m3)
  ),
  boe_did_lr_trends = list(
    coef = coef(m4)["treat_post"],
    se = sqrt(diag(vcov(m4, type = "cluster")))["treat_post"],
    n = nobs(m4)
  ),
  motor_nwp = list(
    coef = coef(m5)["motor_post"],
    se = sqrt(diag(vcov(m5, type = "cluster")))["motor_post"]
  ),
  property_nwp = list(
    coef = coef(m5)["property_post"],
    se = sqrt(diag(vcov(m5, type = "cluster")))["property_post"]
  )
)

saveRDS(results, file.path(data_dir, "main_results.rds"))
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6,
             m_event_nwp = m_event_nwp, m_event_lr = m_event_lr,
             m_firm1 = m_firm1, m_firm2 = m_firm2, m_firm3 = m_firm3),
        file.path(data_dir, "all_models.rds"))

## Diagnostics for validator
n_treated_lines <- length(unique(boe_panel$line[boe_panel$gipp_target == 1]))
n_pre <- length(unique(boe_panel$quarter[boe_panel$post == 0]))
n_obs <- nrow(boe_panel)
jsonlite::write_json(
  list(n_treated = n_treated_lines * n_pre,  # treated unit-quarters pre-treatment
       n_pre = n_pre,
       n_obs = n_obs),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE
)

cat("\n=== DIAGNOSTICS ===\n")
cat("Treated lines:", n_treated_lines, "\n")
cat("Pre-treatment quarters:", n_pre, "\n")
cat("Total observations:", n_obs, "\n")
cat("\nResults saved.\n")
