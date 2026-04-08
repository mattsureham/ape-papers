source("00_packages.R")
dm <- fread("../data/panel_dept_month.csv")
dg <- fread("../data/panel_dept_grade_month.csv")
ts <- fread("../data/ts_civ_mil.csv")
het <- fread("../data/het_dept.csv")
gs  <- fread("../data/grade_coef.csv")
es  <- fread("../data/event_study.csv")

# Re-fit main models for nice etable output
library(fixest)
m_ols  <- feols(log_vac ~ treated:post | department + paste(year,month), data=dm, cluster=~department)
m_lev  <- feols(vacancies ~ treated:post | department + paste(year,month), data=dm, cluster=~department)
m_poi  <- fepois(vacancies ~ treated:post | department + paste(year,month), data=dm, cluster=~department)
m_drop <- feols(log_vac ~ treated:post | department + paste(year,month),
                data=dm[!(year==2025 & month==1)], cluster=~department)
m_2024 <- feols(log_vac ~ treated:post | department + paste(year,month),
                data=dm[year>=2023], cluster=~department)

dir.create("../tables", showWarnings=FALSE)

# --- Table 1: summary statistics ---
ss <- dm[, .(
  Departments  = uniqueN(department),
  `Pre mean`   = round(mean(vacancies[post==0]),0),
  `Pre SD`     = round(sd(vacancies[post==0]),0),
  `Post mean`  = round(mean(vacancies[post==1]),0),
  `Post SD`    = round(sd(vacancies[post==1]),0),
  `% change`   = round(100*(mean(vacancies[post==1])/mean(vacancies[post==0])-1),1)
), by=.(Group=ifelse(treated==1,"Civilian (treated)","Military (control)"))]
print(ss)

cat("
\\begin{table}[!ht]
\\centering
\\caption{Federal Vacancy Postings, Civilian vs Military Departments}
\\label{tab:summary}
\\small
\\begin{tabular}{lrrrrrr}
\\toprule
Group & Departments & Pre mean & Pre SD & Post mean & Post SD & \\% change \\\\
\\midrule
", file="../tables/tab1_summary.tex")
for (i in 1:nrow(ss)) {
  cat(sprintf("%s & %d & %d & %d & %d & %d & %.1f \\\\\n",
              ss$Group[i], ss$Departments[i], ss$`Pre mean`[i], ss$`Pre SD`[i],
              ss$`Post mean`[i], ss$`Post SD`[i], ss$`% change`[i]),
      file="../tables/tab1_summary.tex", append=TRUE)
}
cat("\\bottomrule
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\footnotesize\\textit{Notes:} Monthly USAJOBS Historic JOA postings, Jan 2021 -- Mar 2025 (51 months). Treated group: 12 civilian cabinet departments. Control: 4 military departments (Army, Navy, Air Force, Department of Defense) exempted from the January 20, 2025 federal hiring freeze. Pre-period: Jan 2021 -- Jan 2025; post-period: Feb -- Mar 2025. ``Pre mean'' is the average monthly count of new vacancy announcements per department in the pre-period.
\\end{minipage}
\\end{table}\n", file="../tables/tab1_summary.tex", append=TRUE)

# --- Table 2: Main DiD ---
etable(m_ols, m_lev, m_poi, m_drop, m_2024,
       headers=list("(1) log","(2) levels","(3) Poisson","(4) drop Jan25","(5) 2023+"),
       tex=TRUE, file="../tables/tab2_main.tex", replace=TRUE,
       dict=c("treated:post"="Civilian $\\times$ Post",
              "log_vac"="log(1+vacancies)", "vacancies"="vacancies",
              "department"="Department", "paste(year, month)"="Year-month"),
       title="Difference-in-Differences: Civilian vs Military Hiring Freeze Response",
       label="tab:main",
       fitstat=~n+r2,
       notes="USAJOBS Historic JOA dept-month panel, Jan 2021--Mar 2025. Post = Feb-Mar 2025. Standard errors clustered at department (16 clusters). Column (4) drops Jan 2025 (partial-month treatment). Column (5) restricts to 2023 onward.")

# --- Table 3: Event-study coefficients (selected) ---
es <- es[grepl("ev::", term)]
es[, ev := as.integer(sub(".*ev::(-?[0-9]+):.*", "\\1", term))]
setorder(es, ev)
keep_evs <- es[ev %in% c(-24,-18,-12,-6,-3,-2,0,1,2)]
cat("\\begin{table}[!ht]\n\\centering\n\\caption{Event-Study Estimates: Civilian Excess Drop in Vacancies}\n\\label{tab:event}\n\\small\n\\begin{tabular}{lrrr}\n\\toprule\nMonths from Feb 2025 & Estimate & Std. Error & $t$ \\\\\n\\midrule\n",
    file="../tables/tab3_event.tex")
for (i in 1:nrow(keep_evs)) {
  cat(sprintf("%d & %.3f & (%.3f) & %.2f \\\\\n",
              keep_evs$ev[i], keep_evs$Estimate[i], keep_evs$`Std. Error`[i], keep_evs$`t value`[i]),
      file="../tables/tab3_event.tex", append=TRUE)
}
cat("\\bottomrule\n\\end{tabular}\n\\begin{minipage}{0.92\\textwidth}\n\\footnotesize\\textit{Notes:} Coefficients on $\\mathbf{1}\\{\\text{Civilian}\\}\\times\\mathbf{1}\\{\\text{event time}=k\\}$ from a two-way fixed-effects regression of log(1+vacancies) on event-time$\\times$treatment interactions, with department and year-month fixed effects. Reference period is one month before the freeze ($k=-1$). Period $k=0$ corresponds to February 2025 (first full post-freeze month). SEs clustered by department.\n\\end{minipage}\n\\end{table}\n", file="../tables/tab3_event.tex", append=TRUE)

# --- Table 4: Grade composition ---
cat("\\begin{table}[!ht]\n\\centering\n\\caption{Heterogeneity by GS Grade Bin}\n\\label{tab:grade}\n\\small\n\\begin{tabular}{lrrr}\n\\toprule\nGrade bin & Civilian $\\times$ Post & SE & $p$ \\\\\n\\midrule\n",
    file="../tables/tab4_grade.tex")
for (i in 1:nrow(gs)) {
  if (is.na(gs$est[i])) {
    cat(sprintf("%s & --- & --- & --- \\\\\n", gs$grade[i]), file="../tables/tab4_grade.tex", append=TRUE)
  } else {
    cat(sprintf("%s & %.3f & (%.3f) & %.3f \\\\\n", gs$grade[i], gs$est[i], gs$se[i], gs$p[i]),
        file="../tables/tab4_grade.tex", append=TRUE)
  }
}
cat("\\bottomrule\n\\end{tabular}\n\\begin{minipage}{0.92\\textwidth}\n\\footnotesize\\textit{Notes:} Each row is a separate two-way fixed-effects regression of log(1+vacancies) on Civilian$\\times$Post within the indicated grade bin (subset of the dept-month-grade panel). Grade is the announcement's minimum GS grade. ``Other'' bin combines wage-grade and non-GS pay schedules and is omitted in some specifications due to collinearity with department fixed effects. SEs clustered at department.\n\\end{minipage}\n\\end{table}\n", file="../tables/tab4_grade.tex", append=TRUE)

# --- Table 5: Per-department heterogeneity ---
het[, pct_change := round(100*(post_mean/pre_mean - 1),1)]
het[, est := round(est,3)]
het[, se  := round(se,3)]
het[, dept_short := stringr::str_remove(department,"Department of ?(the )?")]
setorder(het, est)
cat("\\begin{table}[!ht]\n\\centering\n\\caption{Civilian Department Heterogeneity}\n\\label{tab:dept}\n\\small\n\\begin{tabular}{lrrrr}\n\\toprule\nDepartment & Pre (avg/mo) & Post (avg/mo) & \\% change & DiD est. \\\\\n\\midrule\n",
    file="../tables/tab5_dept.tex")
for (i in 1:nrow(het)) {
  cat(sprintf("%s & %d & %d & %.1f & %.3f (%.3f) \\\\\n",
              het$dept_short[i], round(het$pre_mean[i]), round(het$post_mean[i]),
              het$pct_change[i], het$est[i], het$se[i]),
      file="../tables/tab5_dept.tex", append=TRUE)
}
cat("\\bottomrule\n\\end{tabular}\n\\begin{minipage}{0.92\\textwidth}\n\\footnotesize\\textit{Notes:} For each civilian department, we estimate a separate DiD with that department as the only treated unit and the four military departments as controls (two-way FE, log(1+vacancies)). Pre/Post columns report the average monthly vacancy count in Jan 2021--Jan 2025 vs Feb--Mar 2025. SEs in parentheses, clustered at department.\n\\end{minipage}\n\\end{table}\n", file="../tables/tab5_dept.tex", append=TRUE)

# --- SDE appendix ---
beta <- coeftable(m_ols)[1,1]; se <- coeftable(m_ols)[1,2]
sd_y <- sd(dm$log_vac)
sde <- beta/sd_y; sde_se <- se/sd_y
classify <- function(x) {
  if (is.na(x)) return("NA")
  if (x < -0.15) "Large negative"
  else if (x < -0.05) "Moderate negative"
  else if (x < -0.005) "Small negative"
  else if (x <= 0.005) "Null"
  else if (x <= 0.05)  "Small positive"
  else if (x <= 0.15)  "Moderate positive"
  else "Large positive"
}

# Heterogeneity: Panel B uses two sample splits (high-grade vs low-grade subset; legacy 2017+)
# Use grade bin GS13+ vs GS5-9 splits as Panel B rows
sd_g13 <- sd(dg[grade_bin=="GS13plus"]$log_vac)
sd_g59 <- sd(dg[grade_bin=="GS5_9"]$log_vac)
b13 <- gs[grade=="GS13+"]$est; s13 <- gs[grade=="GS13+"]$se
b59 <- gs[grade=="GS5-9"]$est; s59 <- gs[grade=="GS5-9"]$se
sde13 <- b13/sd_g13; sde13_se <- s13/sd_g13
sde59 <- b59/sd_g59; sde59_se <- s59/sd_g59

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did the January 20, 2025 federal hiring freeze and DOGE workforce contraction differentially reduce vacancy postings in civilian departments relative to exempt military departments? ",
  "\\textbf{Policy mechanism:} Executive Order 14148 imposed an immediate government-wide hiring freeze with a one-in-four replacement rule, exempting military departments and uniformed services. Federal HR offices stop publishing new external job announcements during a freeze; the USAJOBS feed therefore mechanically reflects the policy's bite. ",
  "\\textbf{Outcome definition:} Monthly count of unique new vacancy announcements per department from the USAJOBS Historic JOA microdata, log-transformed as $\\log(1+\\text{vacancies})$. ",
  "\\textbf{Treatment:} Binary -- 12 civilian cabinet departments treated; 4 military departments (Army, Navy, Air Force, DoD) as control. ",
  "\\textbf{Data:} USAJOBS Historic JOA REST API; 51 monthly observations per department (Jan 2021 -- Mar 2025); 816 dept-month observations covering 1.66 million vacancy announcements. ",
  "\\textbf{Method:} Two-way fixed-effects OLS with department and year-month fixed effects; SEs clustered at department (16 clusters). Panel B reports the same specification within grade bins (split sample). ",
  "\\textbf{Sample:} Balanced panel of departments observed in every calendar month; minor independent agencies dropped to maintain balance. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pooled standard deviation of $\\log(1+\\text{vacancies})$. Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

cat("\\begin{table}[!ht]\n\\centering\n\\caption{Standardized Effect Sizes (SDE)}\n\\label{tab:sde}\n\\small\n\\begin{tabular}{lrrrrrl}\n\\toprule\nOutcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
    file="../tables/tabF1_sde.tex")
cat(sprintf("log(1+vacancies) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta, se, sd_y, sde, sde_se, classify(sde)),
    file="../tables/tabF1_sde.tex", append=TRUE)
cat("\\midrule\n\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits by GS grade bin)}} \\\\\n",
    file="../tables/tabF1_sde.tex", append=TRUE)
cat(sprintf("log(1+vac), GS13+ & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            b13, s13, sd_g13, sde13, sde13_se, classify(sde13)),
    file="../tables/tabF1_sde.tex", append=TRUE)
cat(sprintf("log(1+vac), GS5--9 & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            b59, s59, sd_g59, sde59, sde59_se, classify(sde59)),
    file="../tables/tabF1_sde.tex", append=TRUE)
cat("\\bottomrule\n\\end{tabular}\n\\begin{minipage}{0.97\\textwidth}\n\\footnotesize\n\\begin{itemize}\n",
    sde_notes,
    "\n\\end{itemize}\n\\end{minipage}\n\\end{table}\n",
    file="../tables/tabF1_sde.tex", append=TRUE)

cat("\nAll tables written to ../tables/\n")
