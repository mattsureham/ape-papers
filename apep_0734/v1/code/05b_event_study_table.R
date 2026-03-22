# 05b_event_study_table.R — Generate event-study table
# apep_0734

source("00_packages.R")
load("../data/models.RData")

# Extract event-study coefficients from m_es
es_coefs <- coef(m_es)
es_se <- se(m_es)
es_pval <- pvalue(m_es)

# Get the names - they look like "event_q::X:wales"
es_names <- names(es_coefs)

# Parse event times
event_times <- as.numeric(gsub("event_q::([-0-9.]+):wales", "\\1", es_names))

# Create data frame
es_df <- data.frame(
  event_q = event_times,
  coef = as.numeric(es_coefs),
  se = as.numeric(es_se),
  pval = as.numeric(es_pval)
)

# Sort by event time
es_df <- es_df[order(es_df$event_q), ]

# Add reference period
ref_row <- data.frame(event_q = -0.25, coef = 0, se = NA, pval = NA)
es_df <- rbind(es_df, ref_row)
es_df <- es_df[order(es_df$event_q), ]

# Split into pre and post
pre <- es_df[es_df$event_q < 0, ]
post <- es_df[es_df$event_q >= 0, ]

# Create table
stars_fn <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# Format quarter labels
q_label <- function(eq) {
  if (eq == -0.25) return("2023-Q3 (ref.)")
  yr <- 2023.75 + eq
  q <- ((yr %% 1) * 4) + 1
  paste0(floor(yr), "-Q", round(q))
}

tab_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event-Study Estimates: Pre-Treatment Coefficients and Dynamic Effects}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Quarter & Coefficient & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Pre-Treatment (excl.\\ COVID 2020--2021)}} \\\\"
)

# Pre-treatment, excluding COVID (event_q between -1.75 and -0.25 is 2022-2023 non-COVID)
# Actually let's show all pre-treatment but mark COVID
for (i in 1:nrow(pre)) {
  eq <- pre$event_q[i]
  ql <- q_label(eq)

  # Is this COVID period?
  yr_actual <- 2023.75 + eq
  is_covid <- yr_actual >= 2020.0 & yr_actual < 2022.0

  if (is.na(pre$se[i])) {
    # Reference period
    tab_lines <- c(tab_lines, sprintf("%s & 0.000 & [ref.] \\\\", ql))
  } else {
    star <- stars_fn(pre$pval[i])
    if (is_covid) {
      tab_lines <- c(tab_lines, sprintf("%s$^{\\dagger}$ & %.3f & (%.3f)%s \\\\",
                                         ql, pre$coef[i], pre$se[i], star))
    } else {
      tab_lines <- c(tab_lines, sprintf("%s & %.3f & (%.3f)%s \\\\",
                                         ql, pre$coef[i], pre$se[i], star))
    }
  }
}

tab_lines <- c(tab_lines,
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel B: Post-Treatment}} \\\\"
)

for (i in 1:nrow(post)) {
  eq <- post$event_q[i]
  ql <- q_label(eq)
  star <- stars_fn(post$pval[i])
  tab_lines <- c(tab_lines, sprintf("%s & %.3f & (%.3f)%s \\\\",
                                     ql, post$coef[i], post$se[i], star))
}

# Joint test of pre-treatment coefficients (excluding COVID and reference)
pre_nocovid <- es_df[es_df$event_q < -0.25 & !is.na(es_df$se), ]
yr_actual <- 2023.75 + pre_nocovid$event_q
non_covid_pre <- pre_nocovid[!(yr_actual >= 2020.0 & yr_actual < 2022.0), ]

# F-test: are non-COVID pre-treatment coefficients jointly zero?
pre_names_nc <- paste0("event_q::", non_covid_pre$event_q, ":wales")
f_test <- tryCatch({
  wald(m_es, keep = pre_names_nc)
}, error = function(e) NULL)

if (!is.null(f_test)) {
  f_p <- f_test$p
  f_stat <- f_test$stat
  joint_str <- sprintf("Joint $F$-test (non-COVID pre-periods): $F = %.2f$, $p = %.3f$", f_stat, f_p)
} else {
  joint_str <- ""
}

tab_lines <- c(tab_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Each row reports the coefficient on Wales $\\times$ $\\ind[t = k]$ from an event-study regression with LA and quarter fixed effects, relative to 2023-Q3 (the last pre-treatment quarter). Standard errors clustered at the LA level in parentheses. $^{\\dagger}$COVID-affected quarter (Wales imposed stricter lockdowns than England). ",
         ifelse(nchar(joint_str) > 0, joint_str, ""),
         " * $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab_lines, "../tables/tab5_eventstudy.tex")
cat("Event study table written\n")
