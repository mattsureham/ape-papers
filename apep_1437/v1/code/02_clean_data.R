source("00_packages.R")
dm <- fread("../data/dept_month.csv")
dg <- fread("../data/dept_grade_month.csv")

# Military / exempt departments (per EO 14148: military depts and uniformed services exempt)
mil_depts <- c(
  "Department of the Army",
  "Department of the Navy",
  "Department of the Air Force",
  "Department of Defense"
)
# Note: "Department of Defense" includes DoD-wide civilian agencies; treat as control
# (manifest specifies military depts as control). Exclude from civilian treated.

dm[, time := year + (month-1)/12]
dm[, military := as.integer(department %in% mil_depts)]
dm[, post := as.integer(year > 2024 | (year==2025 & month>=2))]
dm[, treated := 1L - military]
dm[, log_vac := log1p(vacancies)]

# Balance: keep only departments observed in every month of the panel
n_periods <- dm[, uniqueN(paste(year,month))]
keep <- dm[, .N, by=department][N == n_periods, department]
dm <- dm[department %in% keep]

# Make event time (months relative to Feb 2025 = period 0)
dm[, period := (year - 2025)*12 + (month - 2)]

fwrite(dm, "../data/panel_dept_month.csv")

dg[, military := as.integer(department %in% mil_depts)]
dg[, post := as.integer(year > 2024 | (year==2025 & month>=2))]
dg[, treated := 1L - military]
dg[, log_vac := log1p(vacancies)]
keep_g <- dg[, .N, by=.(department, grade_bin)][N == n_periods, paste(department,grade_bin)]
dg[, key := paste(department, grade_bin)]
dg <- dg[key %in% keep_g][, key := NULL]
fwrite(dg, "../data/panel_dept_grade_month.csv")

cat("Departments in panel:", uniqueN(dm$department), "\n")
cat("Military depts kept:", paste(intersect(unique(dm$department), mil_depts), collapse=", "), "\n")
cat("Months:", n_periods, "\n")
cat("Total obs (dept-month):", nrow(dm), "\n")

# Diagnostics for validate_v1
diag <- list(
  n_treated = uniqueN(dm[treated==1]$department),
  n_pre = uniqueN(dm[post==0, paste(year,month)]),
  n_obs = nrow(dm)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox=TRUE)
print(diag)
