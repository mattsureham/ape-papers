# =============================================================================
# 06_eventstudy_table.R — Generate event study coefficient table for appendix
# =============================================================================

source("00_packages.R")

load("../data/main_results.RData")

# Extract event study coefficients for oxy_share interactions only
extract_es <- function(model, outcome_label) {
  ct <- coeftable(model)
  # Filter to only oxy_share interactions (not total_pills_pc)
  all_names <- rownames(ct)
  idx <- grep(":oxy_share$", all_names)
  if (length(idx) == 0) {
    stop("No oxy_share event_time coefficients found in model for ", outcome_label)
  }

  coef_names <- all_names[idx]
  # Extract event time: "event_time::-5:oxy_share" -> -5
  event_times <- as.integer(sub("^event_time::(-?\\d+):oxy_share$", "\\1", coef_names))

  data.table(
    event_time = event_times,
    beta = ct[idx, "Estimate"],
    se = ct[idx, "Std. Error"],
    outcome = outcome_label
  )
}

es_emp_dt <- extract_es(es_emp, "Log Employment")
es_earn_dt <- extract_es(es_earn, "Log Earnings")
es_sep_dt <- extract_es(es_sep, "Separation Rate")
es_hire_dt <- extract_es(es_hire, "Hire Rate")

# Sort by event time
setorder(es_emp_dt, event_time)
setorder(es_earn_dt, event_time)
setorder(es_sep_dt, event_time)
setorder(es_hire_dt, event_time)

# Build wide table manually (to avoid data.table merge issues)
all_times <- sort(unique(c(es_emp_dt$event_time, es_earn_dt$event_time,
                           es_sep_dt$event_time, es_hire_dt$event_time)))

# Add the omitted reference year (-1)
if (!(-1 %in% all_times)) all_times <- sort(c(all_times, -1L))

es_wide <- data.table(event_time = all_times)

# Left-join each outcome
for (dt_name in list(
  list(dt = es_emp_dt, bname = "beta_emp", sname = "se_emp"),
  list(dt = es_earn_dt, bname = "beta_earn", sname = "se_earn"),
  list(dt = es_sep_dt, bname = "beta_sep", sname = "se_sep"),
  list(dt = es_hire_dt, bname = "beta_hire", sname = "se_hire")
)) {
  tmp <- dt_name$dt[, .(event_time, beta, se)]
  setnames(tmp, c("beta", "se"), c(dt_name$bname, dt_name$sname))
  es_wide <- merge(es_wide, tmp, by = "event_time", all.x = TRUE)
}

setorder(es_wide, event_time)

# Stars helper
add_stars <- function(b, s) {
  p <- 2 * pnorm(-abs(b / s))
  ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))
}

# Build LaTeX table
tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study Coefficients: OxyContin Share $\\times$ Year}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Event & Year & Log Emp & Log Earn & Sep Rate & Hire Rate \\\\",
  "Time & & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Pre-reform (parallel trends test)}} \\\\"
)

for (i in 1:nrow(es_wide)) {
  r <- es_wide[i]
  cal_year <- r$event_time + 2010  # event_time 0 = 2010

  fmt_b <- function(b, s) {
    if (is.na(b) | is.na(s)) return("---")
    st <- add_stars(b, s)
    sprintf("$%.3f%s$", b, st)
  }
  fmt_s <- function(s) {
    if (is.na(s)) return("")
    sprintf("(%s)", formatC(s, format = "f", digits = 3))
  }

  # Add separator before post-reform coefficients
  if (r$event_time == 0 && i > 1) {
    tab5_lines <- c(tab5_lines,
      "\\midrule",
      "\\multicolumn{6}{l}{\\textit{Post-reform (treatment effects)}} \\\\"
    )
  }

  # Reference year row
  if (r$event_time == -1) {
    tab5_lines <- c(tab5_lines,
      sprintf("$-1$ & %d & \\multicolumn{4}{c}{[Reference year]} \\\\", cal_year)
    )
    next
  }

  # Coefficient row
  tab5_lines <- c(tab5_lines,
    sprintf("$%d$ & %d & %s & %s & %s & %s \\\\",
      r$event_time, cal_year,
      fmt_b(r$beta_emp, r$se_emp),
      fmt_b(r$beta_earn, r$se_earn),
      fmt_b(r$beta_sep, r$se_sep),
      fmt_b(r$beta_hire, r$se_hire)
    )
  )
  # SE row
  tab5_lines <- c(tab5_lines,
    sprintf(" & & %s & %s & %s & %s \\\\",
      fmt_s(r$se_emp), fmt_s(r$se_earn),
      fmt_s(r$se_sep), fmt_s(r$se_hire)
    )
  )
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  paste0("\\item \\textit{Notes:} Each cell reports the coefficient on OxyContin Share $\\times$ $\\mathbb{I}[\\text{Year} = k]$ ",
         "from equation~(\\ref{eq:eventstudy}). Standard errors clustered at the state level in parentheses. ",
         "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. ",
         "Event time $-1$ (2009) is the omitted reference year. ",
         "Pre-reform coefficients test for differential pre-trends; post-reform coefficients estimate dynamic treatment effects. ",
         "All regressions include county and year FE and control for total opioid pills per capita $\\times$ year. ",
         "Population-weighted. Prime-age workers (25--44)."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_eventstudy.tex")
message("Event study table written to tables/tab5_eventstudy.tex")

# Print summary for verification
message("\n=== Event Study Summary ===")
message("Pre-period employment coefficients:")
pre <- es_emp_dt[event_time < -1]
for (i in 1:nrow(pre)) {
  r <- pre[i]
  message(sprintf("  t=%d (year %d): beta=%.4f, se=%.4f", r$event_time, r$event_time+2010, r$beta, r$se))
}
message("\nPost-period employment coefficients:")
post <- es_emp_dt[event_time >= 0]
for (i in 1:nrow(post)) {
  r <- post[i]
  message(sprintf("  t=%d (year %d): beta=%.4f, se=%.4f", r$event_time, r$event_time+2010, r$beta, r$se))
}
