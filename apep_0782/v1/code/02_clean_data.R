## 02_clean_data.R — Construct mine-quarter panel for MSHA penalty reform analysis
## APEP paper apep_0782

library(data.table)

cat("=== 02_clean_data.R: Building mine-quarter panel ===\n")

data_dir <- here::here("output", "apep_0782", "v1", "data")

## --- Load raw data ---
accidents  <- readRDS(file.path(data_dir, "accidents_raw.rds"))
violations <- readRDS(file.path(data_dir, "violations_raw.rds"))
mines      <- readRDS(file.path(data_dir, "mines_raw.rds"))

## --- Clean string columns (remove quotes) ---
clean_chr <- function(x) gsub('"', '', x)

accidents[, MINE_ID := clean_chr(MINE_ID)]
accidents[, DEGREE_INJURY_CD := clean_chr(DEGREE_INJURY_CD)]
accidents[, COAL_METAL_IND := clean_chr(COAL_METAL_IND)]

violations[, MINE_ID := clean_chr(MINE_ID)]
violations[, SIG_SUB := clean_chr(SIG_SUB)]
violations[, COAL_METAL_IND := clean_chr(COAL_METAL_IND)]

mines[, MINE_ID := clean_chr(MINE_ID)]
mines[, STATE := clean_chr(STATE)]
mines[, COAL_METAL_IND := clean_chr(COAL_METAL_IND)]
mines[, CURRENT_MINE_TYPE := clean_chr(CURRENT_MINE_TYPE)]
mines[, CURRENT_MINE_STATUS := clean_chr(CURRENT_MINE_STATUS)]

## --- Panel period: 2004Q1 to 2010Q4 ---
PANEL_START_YR <- 2004L
PANEL_END_YR   <- 2010L
REFORM_YR      <- 2007L
REFORM_QTR     <- 2L  # April 2007 = Q2 2007

## --- 1. Construct violation aggregates ---
cat("Building violation aggregates...\n")

# Filter violations to panel period
viol <- violations[CAL_YR >= PANEL_START_YR & CAL_YR <= PANEL_END_YR]
cat(sprintf("Violations in panel period: %s\n", format(nrow(viol), big.mark = ",")))

# S&S flag
viol[, is_ss := (SIG_SUB == "Y")]

# Pre-reform S&S violations per mine (2004-2006) for treatment intensity
viol_pre <- viol[CAL_YR >= 2004L & CAL_YR <= 2006L & is_ss == TRUE]
treat_raw <- viol_pre[, .(
  n_ss_pre     = .N,
  total_pen_ss = sum(PROPOSED_PENALTY, na.rm = TRUE),
  mean_pen_ss  = mean(PROPOSED_PENALTY, na.rm = TRUE)
), by = MINE_ID]

cat(sprintf("Mines with pre-reform S&S violations: %s\n", format(nrow(treat_raw), big.mark = ",")))
cat(sprintf("Mean S&S penalty (pre-reform): $%.0f\n", mean(treat_raw$mean_pen_ss, na.rm = TRUE)))

# Treatment intensity = mean proposed penalty per S&S violation in pre-period
# Standardize by dividing by 100 for interpretability
treat_raw[, treat_intensity := mean_pen_ss / 100]

## --- 2. Construct mine-quarter panel of violations ---
cat("Building mine-quarter violation panel...\n")

viol_mq <- viol[, .(
  n_violations    = .N,
  n_ss_violations = sum(is_ss),
  total_penalty   = sum(PROPOSED_PENALTY, na.rm = TRUE),
  mean_penalty    = mean(PROPOSED_PENALTY, na.rm = TRUE)
), by = .(MINE_ID, CAL_YR, CAL_QTR)]

## --- 3. Construct mine-quarter panel of accidents/injuries ---
cat("Building mine-quarter injury panel...\n")

# Filter accidents to panel period
acc <- accidents[CAL_YR >= PANEL_START_YR & CAL_YR <= PANEL_END_YR]
cat(sprintf("Accidents in panel period: %s\n", format(nrow(acc), big.mark = ",")))

# Define injury severity categories
# 01 = Fatality, 02 = Permanent disability, 03 = Days away from work only
# 04 = Days away + restricted, 05 = Restricted only, 06 = No days lost
# 00 = Accident only (no injury), 07-10 = Other/occupational illness
acc[, is_injury := DEGREE_INJURY_CD %in% c("01", "02", "03", "04", "05", "06")]
acc[, is_serious := DEGREE_INJURY_CD %in% c("01", "02", "03", "04")]
acc[, days_lost_num := as.numeric(gsub('"', '', DAYS_LOST))]

# Mine-quarter injury counts
inj_mq <- acc[, .(
  n_injuries       = sum(is_injury),
  n_serious        = sum(is_serious),
  total_days_lost  = sum(days_lost_num, na.rm = TRUE)
), by = .(MINE_ID, CAL_YR, CAL_QTR)]

## --- 4. Get mine characteristics ---
cat("Merging mine characteristics...\n")

mine_chars <- mines[, .(
  MINE_ID,
  state         = STATE,
  mine_type     = CURRENT_MINE_TYPE,
  coal_metal    = COAL_METAL_IND,
  n_employees   = as.numeric(NO_EMPLOYEES)
)]
mine_chars <- mine_chars[!is.na(n_employees) & n_employees > 0]
cat(sprintf("Mines with employee data: %s\n", format(nrow(mine_chars), big.mark = ",")))

## --- 5. Build balanced panel ---
cat("Constructing balanced mine-quarter panel...\n")

# Get set of mines with pre-reform S&S violations AND employee data
panel_mines <- merge(treat_raw[, .(MINE_ID, treat_intensity, n_ss_pre, mean_pen_ss)],
                     mine_chars, by = "MINE_ID")
cat(sprintf("Mines with treatment + characteristics: %s\n", format(nrow(panel_mines), big.mark = ",")))

# Create all mine-quarter combinations
quarters <- CJ(
  CAL_YR  = PANEL_START_YR:PANEL_END_YR,
  CAL_QTR = 1:4
)
quarters[, yq := sprintf("%dQ%d", CAL_YR, CAL_QTR)]

panel <- CJ(MINE_ID = panel_mines$MINE_ID,
             CAL_YR  = PANEL_START_YR:PANEL_END_YR,
             CAL_QTR = 1:4)

# Merge injuries
panel <- merge(panel, inj_mq, by = c("MINE_ID", "CAL_YR", "CAL_QTR"), all.x = TRUE)
panel[is.na(n_injuries), n_injuries := 0L]
panel[is.na(n_serious), n_serious := 0L]
panel[is.na(total_days_lost), total_days_lost := 0]

# Merge violations
panel <- merge(panel, viol_mq, by = c("MINE_ID", "CAL_YR", "CAL_QTR"), all.x = TRUE)
panel[is.na(n_violations), n_violations := 0L]
panel[is.na(n_ss_violations), n_ss_violations := 0L]
panel[is.na(total_penalty), total_penalty := 0]

# Merge mine characteristics + treatment
panel <- merge(panel, panel_mines, by = "MINE_ID")

# Create time variables
panel[, post := as.integer(CAL_YR > REFORM_YR | (CAL_YR == REFORM_YR & CAL_QTR >= REFORM_QTR))]
panel[, yq := sprintf("%dQ%d", CAL_YR, CAL_QTR)]
panel[, quarter_id := (CAL_YR - PANEL_START_YR) * 4 + CAL_QTR]

# Injury rate per 100 employees (annualized: multiply quarterly by 4)
panel[, injury_rate := (n_injuries / n_employees) * 100]
panel[, serious_rate := (n_serious / n_employees) * 100]
panel[, days_lost_rate := (total_days_lost / n_employees)]

# Treatment quartiles for heterogeneity
panel[, treat_quartile := cut(treat_intensity,
                               breaks = quantile(treat_intensity, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE),
                               labels = c("Q1", "Q2", "Q3", "Q4"),
                               include.lowest = TRUE)]

cat(sprintf("\n=== Panel Summary ===\n"))
cat(sprintf("Mine-quarter observations: %s\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("Unique mines: %s\n", format(uniqueN(panel$MINE_ID), big.mark = ",")))
cat(sprintf("Quarters: %d (Q%d %d to Q%d %d)\n",
            uniqueN(panel$yq),
            min(panel$CAL_QTR[panel$CAL_YR == min(panel$CAL_YR)]),
            min(panel$CAL_YR),
            max(panel$CAL_QTR[panel$CAL_YR == max(panel$CAL_YR)]),
            max(panel$CAL_YR)))
cat(sprintf("Pre-reform obs: %s, Post-reform obs: %s\n",
            format(sum(panel$post == 0), big.mark = ","),
            format(sum(panel$post == 1), big.mark = ",")))
cat(sprintf("Mean injury rate: %.3f per 100 employees\n", mean(panel$injury_rate)))
cat(sprintf("Mean treatment intensity: %.2f\n", mean(panel$treat_intensity)))

## --- 6. Also build pre/post penalty comparison ---
cat("\nBuilding pre/post penalty comparison...\n")

pen_compare <- violations[CAL_YR >= 2004 & CAL_YR <= 2010, .(
  n_violations = .N,
  mean_penalty = mean(PROPOSED_PENALTY, na.rm = TRUE),
  median_penalty = as.numeric(median(PROPOSED_PENALTY, na.rm = TRUE)),
  total_penalty = sum(PROPOSED_PENALTY, na.rm = TRUE)
), by = .(period = ifelse(CAL_YR <= 2006, "Pre-Reform (2004-2006)",
                           ifelse(CAL_YR == 2007, "Transition (2007)",
                                  "Post-Reform (2008-2010)")),
          ss = ifelse(clean_chr(SIG_SUB) == "Y", "S&S", "Non-S&S"))]

cat("Pre/post penalty comparison:\n")
print(pen_compare[order(period, ss)])

## --- Save ---
saveRDS(panel, file.path(data_dir, "panel.rds"))
saveRDS(pen_compare, file.path(data_dir, "penalty_comparison.rds"))

# Also save summary stats for the paper
summary_stats <- panel[, .(
  n_obs         = .N,
  n_mines       = uniqueN(MINE_ID),
  n_states      = uniqueN(state),
  mean_injuries = mean(n_injuries),
  sd_injuries   = sd(n_injuries),
  mean_inj_rate = mean(injury_rate),
  sd_inj_rate   = sd(injury_rate),
  mean_serious  = mean(n_serious),
  mean_days_lost = mean(total_days_lost),
  mean_violations = mean(n_violations),
  mean_treat    = mean(treat_intensity),
  sd_treat      = sd(treat_intensity),
  mean_employees = mean(n_employees),
  sd_employees  = sd(n_employees)
)]
saveRDS(summary_stats, file.path(data_dir, "summary_stats.rds"))

cat("\n=== 02_clean_data.R: DONE ===\n")
