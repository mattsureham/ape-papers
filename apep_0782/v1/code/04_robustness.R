## 04_robustness.R — Robustness checks
## APEP paper apep_0782: MSHA 2007 Penalty Reform

library(data.table)
library(fixest)

cat("=== 04_robustness.R: Robustness checks ===\n")

data_dir <- here::here("output", "apep_0782", "v1", "data")
panel <- readRDS(file.path(data_dir, "panel.rds"))
panel <- panel[!is.na(treat_intensity) & !is.na(injury_rate)]

## ===========================================================================
## 1. Alternative clustering: State level
## ===========================================================================
cat("\n--- Robustness 1: State-level clustering ---\n")

r1 <- feols(injury_rate ~ treat_intensity:post | MINE_ID + yq,
            data = panel, cluster = ~state)
cat(sprintf("State clustering: coef=%.4f, se=%.4f, p=%.4f\n",
            coef(r1)["treat_intensity:post"],
            se(r1)["treat_intensity:post"],
            fixest::pvalue(r1)["treat_intensity:post"]))

## ===========================================================================
## 2. Placebo reform in 2004 (using 2002-2006 data only)
## ===========================================================================
cat("\n--- Robustness 2: Placebo reform (2004) ---\n")

# Load full raw data for extended panel
violations <- readRDS(file.path(data_dir, "violations_raw.rds"))
violations[, MINE_ID := gsub('"', '', MINE_ID)]
violations[, SIG_SUB := gsub('"', '', SIG_SUB)]

accidents <- readRDS(file.path(data_dir, "accidents_raw.rds"))
accidents[, MINE_ID := gsub('"', '', MINE_ID)]
accidents[, DEGREE_INJURY_CD := gsub('"', '', DEGREE_INJURY_CD)]

mines <- readRDS(file.path(data_dir, "mines_raw.rds"))
mines[, MINE_ID := gsub('"', '', MINE_ID)]
mines[, STATE := gsub('"', '', STATE)]

# Pre-reform treatment: 2002-2003 S&S violations
viol_pre02 <- violations[CAL_YR >= 2002 & CAL_YR <= 2003 & SIG_SUB == "Y"]
treat_02 <- viol_pre02[, .(
  mean_pen_ss = mean(PROPOSED_PENALTY, na.rm = TRUE)
), by = MINE_ID]
treat_02[, treat_intensity_placebo := mean_pen_ss / 100]
treat_02 <- treat_02[!is.na(treat_intensity_placebo)]

# Construct placebo panel: 2002-2006, placebo reform at 2004Q1
acc_placebo <- accidents[CAL_YR >= 2002 & CAL_YR <= 2006]
acc_placebo[, is_injury := DEGREE_INJURY_CD %in% c("01", "02", "03", "04", "05", "06")]

inj_placebo <- acc_placebo[, .(
  n_injuries = sum(is_injury)
), by = .(MINE_ID, CAL_YR, CAL_QTR)]

# Get mine employees
mine_emp <- mines[, .(MINE_ID, n_employees = as.numeric(NO_EMPLOYEES),
                       state = gsub('"', '', STATE))]
mine_emp <- mine_emp[!is.na(n_employees) & n_employees > 0]

placebo_mines <- merge(treat_02, mine_emp, by = "MINE_ID")

placebo_panel <- CJ(MINE_ID = placebo_mines$MINE_ID,
                     CAL_YR = 2002:2006,
                     CAL_QTR = 1:4)
placebo_panel <- merge(placebo_panel, inj_placebo,
                       by = c("MINE_ID", "CAL_YR", "CAL_QTR"), all.x = TRUE)
placebo_panel[is.na(n_injuries), n_injuries := 0L]
placebo_panel <- merge(placebo_panel, placebo_mines, by = "MINE_ID")
placebo_panel[, injury_rate := (n_injuries / n_employees) * 100]
placebo_panel[, post_placebo := as.integer(CAL_YR >= 2004)]
placebo_panel[, yq := sprintf("%dQ%d", CAL_YR, CAL_QTR)]

r2 <- feols(injury_rate ~ treat_intensity_placebo:post_placebo | MINE_ID + yq,
            data = placebo_panel, cluster = ~MINE_ID)
cat(sprintf("Placebo 2004: coef=%.4f, se=%.4f, p=%.4f\n",
            coef(r2)["treat_intensity_placebo:post_placebo"],
            se(r2)["treat_intensity_placebo:post_placebo"],
            fixest::pvalue(r2)["treat_intensity_placebo:post_placebo"]))

## ===========================================================================
## 3. Excluding transition quarters (2007Q1-Q2)
## ===========================================================================
cat("\n--- Robustness 3: Excluding transition quarters ---\n")

panel_notrans <- panel[!(CAL_YR == 2007 & CAL_QTR <= 2)]
# Redefine post for remaining obs (2007Q3+ is post)
panel_notrans[, post_notrans := as.integer(CAL_YR > 2007 | (CAL_YR == 2007 & CAL_QTR >= 3))]

r3 <- feols(injury_rate ~ treat_intensity:post_notrans | MINE_ID + yq,
            data = panel_notrans, cluster = ~MINE_ID)
cat(sprintf("Excl transition: coef=%.4f, se=%.4f, p=%.4f\n",
            coef(r3)["treat_intensity:post_notrans"],
            se(r3)["treat_intensity:post_notrans"],
            fixest::pvalue(r3)["treat_intensity:post_notrans"]))

## ===========================================================================
## 4. S&S vs Non-S&S treatment intensity separately
## ===========================================================================
cat("\n--- Robustness 4: S&S count treatment (intensive margin) ---\n")

# Use count of S&S violations in pre-period as alternative treatment
panel[, treat_count := n_ss_pre]
panel[, treat_count_z := (treat_count - mean(treat_count)) / sd(treat_count)]

r4 <- feols(injury_rate ~ treat_count:post | MINE_ID + yq,
            data = panel, cluster = ~MINE_ID)
cat(sprintf("S&S count treat: coef=%.6f, se=%.6f, p=%.4f\n",
            coef(r4)["treat_count:post"],
            se(r4)["treat_count:post"],
            fixest::pvalue(r4)["treat_count:post"]))

## ===========================================================================
## 5. Coal vs Metal/Non-Metal mines
## ===========================================================================
cat("\n--- Robustness 5: Heterogeneity by mine type ---\n")

panel[, coal_metal := gsub('"', '', coal_metal)]
r5_coal <- feols(injury_rate ~ treat_intensity:post | MINE_ID + yq,
                 data = panel[coal_metal == "C"], cluster = ~MINE_ID)
r5_metal <- feols(injury_rate ~ treat_intensity:post | MINE_ID + yq,
                  data = panel[coal_metal == "M"], cluster = ~MINE_ID)

cat(sprintf("Coal mines:  coef=%.4f, se=%.4f, p=%.4f (N=%d)\n",
            coef(r5_coal)["treat_intensity:post"],
            se(r5_coal)["treat_intensity:post"],
            fixest::pvalue(r5_coal)["treat_intensity:post"],
            r5_coal$nobs))
cat(sprintf("Metal mines: coef=%.4f, se=%.4f, p=%.4f (N=%d)\n",
            coef(r5_metal)["treat_intensity:post"],
            se(r5_metal)["treat_intensity:post"],
            fixest::pvalue(r5_metal)["treat_intensity:post"],
            r5_metal$nobs))

## ===========================================================================
## 6. Winsorized outcome
## ===========================================================================
cat("\n--- Robustness 6: Winsorized injury rate (99th pctile) ---\n")

p99 <- quantile(panel$injury_rate, 0.99)
panel[, injury_rate_w := pmin(injury_rate, p99)]

r6 <- feols(injury_rate_w ~ treat_intensity:post | MINE_ID + yq,
            data = panel, cluster = ~MINE_ID)
cat(sprintf("Winsorized: coef=%.4f, se=%.4f, p=%.4f\n",
            coef(r6)["treat_intensity:post"],
            se(r6)["treat_intensity:post"],
            fixest::pvalue(r6)["treat_intensity:post"]))

## --- Save ---
saveRDS(list(
  state_cluster = r1,
  placebo       = r2,
  no_transition = r3,
  ss_count      = r4,
  coal          = r5_coal,
  metal         = r5_metal,
  winsorized    = r6
), file.path(data_dir, "robustness_models.rds"))

cat("\n=== 04_robustness.R: DONE ===\n")
