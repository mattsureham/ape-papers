# 03_main_analysis.R — Main event-study DiD for apep_0774
source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel.rds"))

cat("Panel:", formatC(nrow(panel), big.mark = ","), "rows\n")
cat("Events:", formatC(uniqueN(panel$event_id), big.mark = ","), "\n")

# =============================================================================
# 1. Summary statistics
# =============================================================================
cat("\n=== Summary Statistics ===\n")

# At event time 0 (treatment quarter)
t0 <- panel[event_time == 0]
cat("Mean employment:\n")
print(t0[, .(
  n_events = .N,
  mean_emp = round(mean(emp, na.rm = TRUE), 1),
  sd_emp = round(sd(emp, na.rm = TRUE), 1),
  mean_hours = round(mean(hours, na.rm = TRUE), 0),
  mean_log_emp = round(mean(log_emp, na.rm = TRUE), 3)
), by = event_treatment])


# =============================================================================
# 2. Main event-study: log employment
# =============================================================================
cat("\n=== Main Event Study ===\n")

# Create treatment indicator
panel[, treated := as.integer(event_treatment == "severe")]

# Event study with fixest i() syntax
# Reference period: event_time = -1
m1 <- feols(
  log_emp ~ i(event_time, treated, ref = -1) |
    event_id + MINE_ID,
  data = panel,
  cluster = ~MINE_ID
)

cat("Event study coefficients:\n")
summary(m1)

# =============================================================================
# 3. Simple DiD: pre vs post
# =============================================================================
cat("\n=== Simple DiD: Pre vs Post ===\n")

panel[, post := as.integer(event_time >= 0)]

m2 <- feols(
  log_emp ~ treated:post |
    event_id + MINE_ID,
  data = panel,
  cluster = ~MINE_ID
)
cat("DiD coefficient (treated × post):\n")
summary(m2)

# =============================================================================
# 4. Level specification
# =============================================================================
cat("\n=== Level Specification ===\n")

m3 <- feols(
  emp ~ i(event_time, treated, ref = -1) |
    event_id + MINE_ID,
  data = panel,
  cluster = ~MINE_ID
)
cat("Level event study:\n")
summary(m3)

# Simple DiD in levels
m4 <- feols(
  emp ~ treated:post |
    event_id + MINE_ID,
  data = panel,
  cluster = ~MINE_ID
)
cat("Level DiD:\n")
summary(m4)


# =============================================================================
# 5. Hours worked specification
# =============================================================================
cat("\n=== Hours Worked ===\n")

panel[, log_hours := log(pmax(hours, 1))]

m5 <- feols(
  log_hours ~ treated:post |
    event_id + MINE_ID,
  data = panel,
  cluster = ~MINE_ID
)
cat("Log hours DiD:\n")
summary(m5)


# =============================================================================
# 6. Save diagnostics and models
# =============================================================================

n_treated_mines <- uniqueN(panel[treated == 1, MINE_ID])
pre_quarters <- sort(unique(panel[event_time < 0, event_time]))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated_mines,
  n_pre = length(pre_quarters),
  n_obs = n_obs,
  n_mines = uniqueN(panel$MINE_ID),
  n_events = uniqueN(panel$event_id),
  mean_emp_severe = mean(t0[event_treatment == "severe", emp], na.rm = TRUE),
  mean_emp_clean = mean(t0[event_treatment == "clean", emp], na.rm = TRUE),
  sd_log_emp = sd(panel$log_emp, na.rm = TRUE)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                      auto_unbox = TRUE)
cat(sprintf("\nn_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_mines, length(pre_quarters), n_obs))

saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5),
        file.path(data_dir, "main_models.rds"))
cat("Models saved.\n")
