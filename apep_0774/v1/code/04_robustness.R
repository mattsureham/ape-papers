# 04_robustness.R — Robustness checks for apep_0774
source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel.rds"))
panel[, treated := as.integer(event_treatment == "severe")]
panel[, post := as.integer(event_time >= 0)]
panel[, log_hours := log(pmax(hours, 1))]

# =============================================================================
# 1. Coal vs Metal/NonMetal heterogeneity
# =============================================================================
cat("=== 1. Coal vs Metal/NonMetal ===\n")

# Need to get coal/metal indicator from inspections
insp <- fread(file.path(data_dir, "Inspections.txt"), sep = "|", fill = TRUE,
              select = c("EVENT_NO", "COAL_METAL_IND"))

panel_cm <- merge(panel, insp[, .(event_id = EVENT_NO, coal_metal = COAL_METAL_IND)],
                   by = "event_id", all.x = TRUE)

r1a <- feols(log_emp ~ treated:post | event_id + MINE_ID,
             data = panel_cm[coal_metal == "C"], cluster = ~MINE_ID)
cat("Coal mines:\n")
summary(r1a)

r1b <- feols(log_emp ~ treated:post | event_id + MINE_ID,
             data = panel_cm[coal_metal == "M"], cluster = ~MINE_ID)
cat("Metal/NonMetal mines:\n")
summary(r1b)


# =============================================================================
# 2. Dose-response by S&S count
# =============================================================================
cat("\n=== 2. Dose-response ===\n")

# Reload with full S&S counts
insp_full <- fread(file.path(data_dir, "Inspections.txt"), sep = "|", fill = TRUE,
                    select = c("EVENT_NO", "MINE_ID", "INSPECTION_BEGIN_DT", "ACTIVITY_CODE"))
insp_full <- insp_full[ACTIVITY_CODE %in% c("E01", "01", "AAA")]
insp_full[, insp_date := as.Date(INSPECTION_BEGIN_DT, format = "%m/%d/%Y")]

viol <- fread(file.path(data_dir, "Violations.txt"), sep = "|", fill = TRUE,
              select = c("EVENT_NO", "SIG_SUB"))
ss <- viol[SIG_SUB == "Y", .(n_ss = .N), by = EVENT_NO]

# Merge S&S count into panel
panel_dose <- merge(panel, ss[, .(event_id = EVENT_NO, n_ss)],
                     by = "event_id", all.x = TRUE)
panel_dose[is.na(n_ss), n_ss := 0L]

# Create dose bins
panel_dose[, dose := fcase(
  n_ss == 0, "0 S&S",
  n_ss %between% c(1, 2), "1-2 S&S",
  n_ss %between% c(3, 5), "3-5 S&S",
  n_ss %between% c(6, 10), "6-10 S&S",
  n_ss > 10, "10+ S&S"
)]

r2 <- feols(log_emp ~ i(dose, post, ref = "0 S&S") | event_id + MINE_ID,
            data = panel_dose, cluster = ~MINE_ID)
cat("Dose-response:\n")
summary(r2)


# =============================================================================
# 3. Large mine subsample (>=20 employees)
# =============================================================================
cat("\n=== 3. Large mines (>=20 emp) ===\n")

# Identify mines that are large at event time -1
large_at_baseline <- panel[event_time == -1 & emp >= 20, unique(event_id)]
panel_large <- panel[event_id %in% large_at_baseline]

r3 <- feols(log_emp ~ treated:post | event_id + MINE_ID,
            data = panel_large, cluster = ~MINE_ID)
cat("Large mines DiD:\n")
summary(r3)


# =============================================================================
# 4. Pre-trend-adjusted: restrict to 2010+
# =============================================================================
cat("\n=== 4. Post-2010 sample ===\n")

r4 <- feols(log_emp ~ treated:post | event_id + MINE_ID,
            data = panel[event_year >= 2010], cluster = ~MINE_ID)
cat("Post-2010:\n")
summary(r4)


# =============================================================================
# 5. Alternative clustering (state level)
# =============================================================================
cat("\n=== 5. State clustering ===\n")

r5 <- feols(log_emp ~ treated:post | event_id + MINE_ID,
            data = panel, cluster = ~state)
cat("State-clustered:\n")
summary(r5)


# =============================================================================
# Save
# =============================================================================
rob_results <- list(
  coal = r1a, metal = r1b, dose = r2,
  large = r3, post2010 = r4, state_cluster = r5
)
saveRDS(rob_results, file.path(data_dir, "robustness_models.rds"))
cat("\nAll robustness models saved.\n")
