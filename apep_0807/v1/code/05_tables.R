## 05_tables.R — Generate all tables for paper
## APEP-0807: Legislating at Midnight

source("00_packages.R")

df <- readRDS("../data/analysis_data.rds")
sub <- filter(df, substantive == 1)
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robust_results.rds")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

vars_of_interest <- c("n_major_actions", "deliberation_days",
                       "has_roll_call", "has_conference", "voice_only",
                       "has_unanimous", "is_house")
var_labels <- c("Major Legislative Actions", "Days: Introduction to Enactment",
                "Recorded Roll-Call Vote", "Conference Committee Used",
                "Voice Vote Only", "Unanimous Consent", "House Origin")

stats_earlier <- sub %>% filter(final_30 == 0) %>%
  summarise(across(all_of(vars_of_interest), list(mean = mean, sd = sd)))
stats_final <- sub %>% filter(final_30 == 1) %>%
  summarise(across(all_of(vars_of_interest), list(mean = mean, sd = sd)))

# Build LaTeX table
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Substantive Enacted Laws, 93rd--118th Congress}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Earlier (Days $> 30$)} & \\multicolumn{2}{c}{Final 30 Days} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in seq_along(vars_of_interest)) {
  v <- vars_of_interest[i]
  m0 <- stats_earlier[[paste0(v, "_mean")]]
  s0 <- stats_earlier[[paste0(v, "_sd")]]
  m1 <- stats_final[[paste0(v, "_mean")]]
  s1 <- stats_final[[paste0(v, "_sd")]]
  tab1_lines <- c(tab1_lines,
                   sprintf("%s & %.3f & (%.3f) & %.3f & (%.3f) \\\\",
                           var_labels[i], m0, s0, m1, s1))
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(sum(sub$final_30 == 0), big.mark = ","),
          format(sum(sub$final_30 == 1), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Sample restricted to substantive enacted laws (excluding naming/postal designations). ``Final 30 Days'' indicates laws enacted within 30 days of the constitutional January 3 session deadline. Congresses 93--118 (1973--2025). Standard deviations in parentheses.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Saved tables/tab1_summary.tex\n")

# ============================================================
# TABLE 2: Main Results (Roll-Call Vote)
# ============================================================

cat("=== Generating Table 2: Main Results ===\n")

m1 <- feols(has_roll_call ~ final_30, data = sub, vcov = ~congress)
m2 <- feols(has_roll_call ~ final_30 | congress, data = sub, vcov = ~congress)
m3 <- feols(has_roll_call ~ final_30 + is_house + is_joint_res | congress,
            data = sub, vcov = ~congress)
m4 <- feols(has_roll_call ~ log1p(days_remaining) | congress,
            data = sub, vcov = ~congress)
m5 <- feols(has_conference ~ final_30 | congress, data = sub, vcov = ~congress)
m6 <- feols(voice_only ~ final_30 | congress, data = sub, vcov = ~congress)

# Use fixest::etable for clean LaTeX output
etable(m1, m2, m3, m4, m5, m6,
       dict = c("final_30" = "Final 30 Days",
                "log1p(days_remaining)" = "Log(Days Remaining + 1)",
                "is_house" = "House Origin",
                "is_joint_res" = "Joint Resolution"),
       se.below = TRUE,
       signif.code = c("***" = 0.001, "**" = 0.01, "*" = 0.05),
       title = "Calendar Pressure and Legislative Process Quality",
       label = "tab:main",
       depvar = TRUE,
       file = "../tables/tab2_main.tex",
       replace = TRUE,
       notes = c("Standard errors clustered by Congress in parentheses.",
                 "Columns 1--4: Dep.~var.~is recorded roll-call vote (indicator).",
                 "Column 5: Conference committee. Column 6: Voice-only passage.",
                 "Final 30 Days $=$ enacted within 30 days of Jan.~3 deadline."))
cat("  Saved tables/tab2_main.tex\n")

# ============================================================
# TABLE 3: Compression Gradient
# ============================================================

cat("=== Generating Table 3: Compression Gradient ===\n")

gradient <- results$gradient

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Deliberation Deficit Across Compression Windows}",
  "\\label{tab:gradient}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Window (Days $\\leq$) & 7 & 14 & 30 & 60 & 90 \\\\",
  "\\midrule"
)

coef_row <- paste0("Calendar Pressure & ",
                    paste(sprintf("%.4f%s", gradient$coef, gradient$stars), collapse = " & "),
                    " \\\\")
se_row <- paste0(" & ",
                  paste(sprintf("(%.4f)", gradient$se), collapse = " & "),
                  " \\\\")
n_row <- paste0("Treated (N) & ",
                paste(format(gradient$n_treated, big.mark = ","), collapse = " & "),
                " \\\\")

tab3_lines <- c(tab3_lines, coef_row, se_row, "\\midrule", n_row,
  sprintf("Total N & \\multicolumn{5}{c}{%s} \\\\", format(nrow(sub), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports the coefficient on a binary indicator for whether the law was enacted within the specified number of days before the constitutional January 3 deadline. All specifications include Congress fixed effects with standard errors clustered by Congress. Sample: substantive enacted laws, 93rd--118th Congress. $^{*}p<0.05$; $^{**}p<0.01$; $^{***}p<0.001$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_gradient.tex")
cat("  Saved tables/tab3_gradient.tex\n")

# ============================================================
# TABLE 4: Robustness and Placebo Tests
# ============================================================

cat("=== Generating Table 4: Robustness ===\n")

# Placebo: mid-session
sub_plac <- sub %>%
  mutate(
    session_midpoint = session_start + (session_end - session_start) / 2,
    days_from_mid = as.integer(session_midpoint - enacted_date),
    placebo_final30 = as.integer(days_from_mid >= 0 & days_from_mid <= 30)
  )
mp <- feols(has_roll_call ~ placebo_final30 | congress, data = sub_plac, vcov = ~congress)

# Naming bills
naming <- filter(df, substantive == 0)
mn <- feols(has_roll_call ~ final_30 | congress, data = naming, vcov = ~congress)

# House vs Senate
mh <- feols(has_roll_call ~ final_30 | congress,
            data = filter(sub, is_house == 1), vcov = ~congress)
ms <- feols(has_roll_call ~ final_30 | congress,
            data = filter(sub, is_house == 0), vcov = ~congress)

# Logit
ml <- feglm(has_roll_call ~ final_30 | congress,
            data = sub, family = binomial, vcov = ~congress)

etable(mp, mn, mh, ms, ml,
       headers = c("Placebo:\\\\Mid-Session", "Placebo:\\\\Naming", "House\\\\Bills",
                    "Senate\\\\Bills", "Logit"),
       dict = c("final_30" = "Final 30 Days",
                "placebo_final30" = "Placebo Final 30"),
       se.below = TRUE,
       signif.code = c("***" = 0.001, "**" = 0.01, "*" = 0.05),
       title = "Robustness Checks and Placebo Tests",
       label = "tab:robust",
       depvar = TRUE,
       file = "../tables/tab4_robustness.tex",
       replace = TRUE,
       notes = c("Standard errors clustered by Congress in parentheses.",
                 "All specifications include Congress fixed effects.",
                 "Col.~1: placebo using 30-day window around session midpoint.",
                 "Col.~2: sample restricted to naming/postal bills.",
                 "Cols.~3--4: sample split by chamber of origin.",
                 "Col.~5: logit specification (log-odds)."))
cat("  Saved tables/tab4_robustness.tex\n")

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY
# ============================================================

cat("=== Generating Table F1: Standardized Effect Sizes ===\n")

# Main outcomes: roll-call vote, conference committee, voice-only
outcomes <- list(
  list(name = "Recorded Roll-Call Vote", var = "has_roll_call",
       model_fn = function(d) feols(has_roll_call ~ final_30 | congress, data = d, vcov = ~congress)),
  list(name = "Conference Committee", var = "has_conference",
       model_fn = function(d) feols(has_conference ~ final_30 | congress, data = d, vcov = ~congress)),
  list(name = "Voice-Only Passage", var = "voice_only",
       model_fn = function(d) feols(voice_only ~ final_30 | congress, data = d, vcov = ~congress))
)

sde_rows <- map_dfr(outcomes, function(o) {
  m <- o$model_fn(sub)
  beta <- coef(m)["final_30"]
  se_beta <- se(m)["final_30"]
  # SD of outcome among non-treated (pre-treatment analog)
  sd_y <- sd(sub[[o$var]][sub$final_30 == 0])
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  # Classification
  class_label <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )

  tibble(
    Outcome = o$name,
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = class_label
  )
})

print(sde_rows)

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does constitutional calendar pressure at the end of congressional sessions reduce the deliberative quality of enacted federal legislation, as measured by procedural process indicators? ",
  "\\textbf{Policy mechanism:} The U.S. Constitution mandates that each Congress expires on January 3 of odd-numbered years, creating a hard deadline that compresses legislative activity in the final weeks; this calendar pressure forces Congress to shortcut procedural safeguards including recorded votes and bicameral conference reconciliation. ",
  "\\textbf{Outcome definition:} Recorded roll-call vote is a binary indicator for whether at least one chamber held a recorded vote on the bill; conference committee is a binary indicator for bicameral reconciliation; voice-only passage indicates both chambers passed the bill without any recorded vote. ",
  "\\textbf{Treatment:} Binary indicator for enactment within 30 days of the constitutional January 3 deadline. ",
  "\\textbf{Data:} GovTrack API, 93rd--118th Congress (1973--2025), unit of observation is an individual enacted public law, N = 10,377 substantive laws. ",
  "\\textbf{Method:} OLS with Congress fixed effects, standard errors clustered by Congress. ",
  "\\textbf{Sample:} Substantive enacted public laws only; naming/postal designation bills excluded as trivially non-deliberative. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the standard deviation among laws enacted outside the final 30 days. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build SDE table
tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
            r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  Saved tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
