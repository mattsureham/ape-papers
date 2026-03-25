## 05_tables.R — Generate all LaTeX tables
## apep_0899: Finland compulsory education extension

source("00_packages.R")

load("../data/main_models.RData")
load("../data/robustness_models.RData")
drop_nat <- read_csv("../data/dropout_national_clean.csv", show_col_types = FALSE)

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("=== Table 1: Summary Statistics ===\n")

panel_voc <- filter(panel, sector == "vocational")
panel_gen <- filter(panel, sector == "general")

make_stats <- function(d, label) {
  d %>%
    summarize(
      across(c(employed_pct, unemployed_pct, student_pct, completers),
             list(mean = ~mean(.x, na.rm = TRUE),
                  sd = ~sd(.x, na.rm = TRUE),
                  min = ~min(.x, na.rm = TRUE),
                  max = ~max(.x, na.rm = TRUE)),
             .names = "{.col}_{.fn}")
    ) %>%
    pivot_longer(everything()) %>%
    separate(name, into = c("var", "stat"), sep = "_(?=[^_]+$)") %>%
    pivot_wider(names_from = stat, values_from = value) %>%
    mutate(panel = label)
}

stats_pre_voc <- make_stats(filter(panel_voc, post == 0), "Pre-reform vocational")
stats_post_voc <- make_stats(filter(panel_voc, post == 1), "Post-reform vocational")
stats_pre_gen <- make_stats(filter(panel_gen, post == 0), "Pre-reform general")
stats_post_gen <- make_stats(filter(panel_gen, post == 1), "Post-reform general")

all_stats <- bind_rows(stats_pre_voc, stats_post_voc, stats_pre_gen, stats_post_gen)

# Format variable names nicely
var_labels <- c(
  "employed_pct" = "Employment rate (\\%)",
  "unemployed_pct" = "Unemployment rate (\\%)",
  "student_pct" = "Student continuation rate (\\%)",
  "completers" = "Number of completers"
)

# Build LaTeX table
tab1 <- "\\begin{table}[H]\n\\centering\n\\caption{Summary Statistics}\n\\label{tab:summary}\n"
tab1 <- paste0(tab1, "\\begin{threeparttable}\n")
tab1 <- paste0(tab1, "\\begin{tabular}{lcccc}\n\\toprule\n")
tab1 <- paste0(tab1, " & Mean & Std.~Dev. & Min & Max \\\\\n\\midrule\n")

for (p in c("Pre-reform vocational", "Post-reform vocational",
            "Pre-reform general", "Post-reform general")) {
  tab1 <- paste0(tab1, "\\multicolumn{5}{l}{\\textit{", p, "}} \\\\\n")
  sub <- filter(all_stats, panel == p)
  for (v in names(var_labels)) {
    row <- filter(sub, var == v)
    if (nrow(row) == 0) next
    tab1 <- paste0(tab1, sprintf("%s & %.1f & %.1f & %.1f & %.1f \\\\\n",
                                 var_labels[v], row$mean, row$sd, row$min, row$max))
  }
  tab1 <- paste0(tab1, "\\addlinespace\n")
}

n_voc_pre <- sum(panel_voc$post == 0)
n_voc_post <- sum(panel_voc$post == 1)
n_gen_pre <- sum(panel_gen$post == 0)
n_gen_post <- sum(panel_gen$post == 1)

tab1 <- paste0(tab1, "\\bottomrule\n\\end{tabular}\n")
tab1 <- paste0(tab1, "\\begin{tablenotes}[flushleft]\n\\small\n")
tab1 <- paste0(tab1, sprintf("\\item \\textit{Notes:} Panel of %d regions $\\times$ 18 years (2007--2024). Vocational panel: %d pre-reform, %d post-reform region-years. General panel: %d pre-reform, %d post-reform region-years. Employment, unemployment, and student rates measure activity one year after qualification completion. Data source: Statistics Finland PxWeb API.\n",
                              n_distinct(panel$region_name), n_voc_pre, n_voc_post, n_gen_pre, n_gen_post))
tab1 <- paste0(tab1, "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")

writeLines(tab1, "../tables/tab1_descriptive.tex")
cat("Written tab1_descriptive.tex\n")

## ============================================================
## Table 2: Main Results (DDD)
## ============================================================
cat("\n=== Table 2: Main Results ===\n")

# Extract coefficients and SEs from models
extract_ddd <- function(model, coef_pattern = "vocational.*intensity.*post") {
  ct <- coeftable(model)
  idx <- grep(coef_pattern, rownames(ct))
  if (length(idx) == 0) return(list(b = NA, se = NA, p = NA))
  list(b = ct[idx[1], 1], se = ct[idx[1], 2], p = ct[idx[1], 4])
}

extract_simple <- function(model, coef_pattern = "intensity.*post") {
  ct <- coeftable(model)
  idx <- grep(coef_pattern, rownames(ct))
  if (length(idx) == 0) return(list(b = NA, se = NA, p = NA))
  list(b = ct[idx[1], 1], se = ct[idx[1], 2], p = ct[idx[1], 4])
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# Column 1: Vocational only, intensity × post
r1 <- extract_simple(m1)
# Column 2: DDD (vocational × intensity × post)
r3 <- extract_ddd(m3)
# Column 3: Unemployment DDD
r4 <- extract_ddd(m4)
# Column 4: Student pct DDD
r5 <- extract_ddd(m5)

tab2 <- "\\begin{table}[H]\n\\centering\n\\caption{Effect of Compulsory Education Extension on School-to-Work Transitions}\n\\label{tab:main}\n"
tab2 <- paste0(tab2, "\\begin{threeparttable}\n")
tab2 <- paste0(tab2, "\\begin{tabular}{lcccc}\n\\toprule\n")
tab2 <- paste0(tab2, " & (1) & (2) & (3) & (4) \\\\\n")
tab2 <- paste0(tab2, " & Employed & Employed & Unemployed & Student \\\\\n")
tab2 <- paste0(tab2, " & (Voc.~only) & (DDD) & (DDD) & (DDD) \\\\\n")
tab2 <- paste0(tab2, "\\midrule\n")

# Row: Intensity × Post (or Voc × Intensity × Post for DDD)
tab2 <- paste0(tab2, sprintf("Intensity $\\times$ Post & %.3f%s & & & \\\\\n",
                              r1$b, stars(r1$p)))
tab2 <- paste0(tab2, sprintf(" & (%.3f) & & & \\\\\n", r1$se))
tab2 <- paste0(tab2, "\\addlinespace\n")

tab2 <- paste0(tab2, sprintf("Voc.~$\\times$ Intensity $\\times$ Post & & %.3f%s & %.3f%s & %.3f%s \\\\\n",
                              r3$b, stars(r3$p), r4$b, stars(r4$p), r5$b, stars(r5$p)))
tab2 <- paste0(tab2, sprintf(" & & (%.3f) & (%.3f) & (%.3f) \\\\\n",
                              r3$se, r4$se, r5$se))
tab2 <- paste0(tab2, "\\addlinespace\n")

tab2 <- paste0(tab2, "\\midrule\n")
tab2 <- paste0(tab2, sprintf("Region FE & Yes & & & \\\\\n"))
tab2 <- paste0(tab2, sprintf("Year FE & Yes & & & \\\\\n"))
tab2 <- paste0(tab2, sprintf("Region $\\times$ Sector FE & & Yes & Yes & Yes \\\\\n"))
tab2 <- paste0(tab2, sprintf("Year $\\times$ Sector FE & & Yes & Yes & Yes \\\\\n"))
tab2 <- paste0(tab2, sprintf("Observations & %d & %d & %d & %d \\\\\n",
                              m1$nobs, m3$nobs, m4$nobs, m5$nobs))
tab2 <- paste0(tab2, sprintf("Regions & %d & %d & %d & %d \\\\\n",
                              19, 19, 19, 19))
tab2 <- paste0(tab2, sprintf("Adj.~$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\\n",
                              fitstat(m1, "ar2")[[1]], fitstat(m3, "ar2")[[1]],
                              fitstat(m4, "ar2")[[1]], fitstat(m5, "ar2")[[1]]))
tab2 <- paste0(tab2, "\\bottomrule\n\\end{tabular}\n")
tab2 <- paste0(tab2, "\\begin{tablenotes}[flushleft]\n\\small\n")
tab2 <- paste0(tab2, "\\item \\textit{Notes:} Standard errors clustered at the region level in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$. Intensity is the pre-reform (2007--2020) average unemployment rate for vocational graduates in each region (range: 6--24\\%). Column 1 estimates the intensity $\\times$ post interaction for vocational graduates only. Columns 2--4 report the triple-difference coefficient (vocational $\\times$ intensity $\\times$ post), using general education graduates as the within-region control group. Outcomes are measured one year after qualification completion.\n")
tab2 <- paste0(tab2, "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")

writeLines(tab2, "../tables/tab2_main.tex")
cat("Written tab2_main.tex\n")

## ============================================================
## Table 3: Robustness
## ============================================================
cat("\n=== Table 3: Robustness ===\n")

# Extract from robustness models
r_binary <- extract_ddd(m_binary, "vocational.*high_intensity.*post")
r_alt <- extract_ddd(m_alt_int, "vocational.*intensity_emp.*post")
r_short <- extract_ddd(m_short)
r_placebo_gen <- extract_simple(m_placebo)

tab3 <- "\\begin{table}[H]\n\\centering\n\\caption{Robustness Checks}\n\\label{tab:robust}\n"
tab3 <- paste0(tab3, "\\begin{threeparttable}\n")
tab3 <- paste0(tab3, "\\begin{tabular}{llccc}\n\\toprule\n")
tab3 <- paste0(tab3, " & Specification & Coefficient & SE & $N$ \\\\\n")
tab3 <- paste0(tab3, "\\midrule\n")
tab3 <- paste0(tab3, "\\multicolumn{5}{l}{\\textit{Panel A: Alternative DDD specifications}} \\\\\n")
tab3 <- paste0(tab3, sprintf("(1) & Baseline (continuous intensity) & %.3f%s & (%.3f) & %d \\\\\n",
                              r3$b, stars(r3$p), r3$se, m3$nobs))
tab3 <- paste0(tab3, sprintf("(2) & Binary intensity (above/below median) & %.3f%s & (%.3f) & %d \\\\\n",
                              r_binary$b, stars(r_binary$p), r_binary$se, m_binary$nobs))
tab3 <- paste0(tab3, sprintf("(3) & Alt.~intensity (100 $-$ employment rate) & %.3f%s & (%.3f) & %d \\\\\n",
                              r_alt$b, stars(r_alt$p), r_alt$se, m_alt_int$nobs))
tab3 <- paste0(tab3, sprintf("(4) & Shorter pre-period (2015--2024) & %.3f%s & (%.3f) & %d \\\\\n",
                              r_short$b, stars(r_short$p), r_short$se, m_short$nobs))
tab3 <- paste0(tab3, "\\addlinespace\n")
tab3 <- paste0(tab3, "\\multicolumn{5}{l}{\\textit{Panel B: Placebo and subsample}} \\\\\n")
tab3 <- paste0(tab3, sprintf("(5) & Placebo: general education only & %.3f%s & (%.3f) & %d \\\\\n",
                              r_placebo_gen$b, stars(r_placebo_gen$p), r_placebo_gen$se, m_placebo$nobs))

# LOO range
tab3 <- paste0(tab3, sprintf("(6) & Leave-one-region-out [range] & [%.3f, %.3f] & & %d \\\\\n",
                              min(loo_results$coef, na.rm = TRUE),
                              max(loo_results$coef, na.rm = TRUE), m3$nobs))

tab3 <- paste0(tab3, "\\bottomrule\n\\end{tabular}\n")
tab3 <- paste0(tab3, "\\begin{tablenotes}[flushleft]\n\\small\n")
tab3 <- paste0(tab3, "\\item \\textit{Notes:} Rows 1--4 report the vocational $\\times$ intensity $\\times$ post triple-difference coefficient for the employment rate outcome. Row 5 reports the intensity $\\times$ post coefficient for general education only (placebo). Row 6 shows the range of the DDD coefficient across 19 leave-one-region-out iterations. All specifications include region $\\times$ sector and year $\\times$ sector fixed effects (except column 1 of Table 2 and row 5 which use region and year FE only). Standard errors clustered at the region level.\n")
tab3 <- paste0(tab3, "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")

writeLines(tab3, "../tables/tab3_robustness.tex")
cat("Written tab3_robustness.tex\n")

## ============================================================
## Table 4: Event Study Coefficients
## ============================================================
cat("\n=== Table 4: Event Study ===\n")

es_coefs <- coef(es_voc)
es_ses <- sqrt(diag(vcov(es_voc)))
es_idx <- grep("event_time.*intensity", names(es_coefs))

es_df <- tibble(
  event_time = as.integer(str_extract(names(es_coefs[es_idx]), "-?\\d+")),
  coef = es_coefs[es_idx],
  se = es_ses[es_idx]
) %>%
  mutate(p = 2 * pt(-abs(coef / se), df = es_voc$nobs - length(coef(es_voc)))) %>%
  arrange(event_time)

tab4 <- "\\begin{table}[H]\n\\centering\n\\caption{Event Study: Vocational Employment Rate}\n\\label{tab:eventstudy}\n"
tab4 <- paste0(tab4, "\\begin{threeparttable}\n")
tab4 <- paste0(tab4, "\\begin{tabular}{lccc}\n\\toprule\n")
tab4 <- paste0(tab4, "Event time ($t - 2021$) & Intensity $\\times \\mathbf{1}[t]$ & SE & 95\\% CI \\\\\n")
tab4 <- paste0(tab4, "\\midrule\n")

for (i in 1:nrow(es_df)) {
  et <- es_df$event_time[i]
  b <- es_df$coef[i]
  s <- es_df$se[i]
  ci_lo <- b - 1.96 * s
  ci_hi <- b + 1.96 * s
  marker <- ifelse(et >= 0, " $\\dagger$", "")
  tab4 <- paste0(tab4, sprintf("$t = %+d$%s & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\\n",
                                et, marker, b, stars(es_df$p[i]), s, ci_lo, ci_hi))
}

tab4 <- paste0(tab4, "\\bottomrule\n\\end{tabular}\n")
tab4 <- paste0(tab4, "\\begin{tablenotes}[flushleft]\n\\small\n")
tab4 <- paste0(tab4, "\\item \\textit{Notes:} Each row reports the coefficient on Intensity $\\times \\mathbf{1}[\\text{year} = t]$ from a regression of the vocational employment rate on region and year fixed effects. Base period: $t = -1$ (2020). $\\dagger$ denotes post-reform periods (2021--2024). Standard errors clustered at the region level. The pattern shows no systematic pre-trends in the 2--3 years preceding the reform.\n")
tab4 <- paste0(tab4, "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")

writeLines(tab4, "../tables/tab4_eventstudy.tex")
cat("Written tab4_eventstudy.tex\n")

## ============================================================
## Table F1: Standardized Effect Sizes (SDE)
## ============================================================
cat("\n=== Table F1: SDE ===\n")

# Compute SDE for DDD coefficients
# Employment rate
beta_emp <- coef(m3)[grep("vocational.*intensity.*post", names(coef(m3)))]
se_emp <- sqrt(diag(vcov(m3)))[grep("vocational.*intensity.*post", names(coef(m3)))]
sd_y_emp <- sd(panel$employed_pct, na.rm = TRUE)
sd_x_int <- sd(panel$intensity[panel$sector == "vocational"], na.rm = TRUE)
sde_emp <- beta_emp * sd_x_int / sd_y_emp  # continuous treatment
se_sde_emp <- se_emp * sd_x_int / sd_y_emp

# Unemployment rate
beta_unemp <- coef(m4)[grep("vocational.*intensity.*post", names(coef(m4)))]
se_unemp <- sqrt(diag(vcov(m4)))[grep("vocational.*intensity.*post", names(coef(m4)))]
sd_y_unemp <- sd(panel$unemployed_pct, na.rm = TRUE)
sde_unemp <- beta_unemp * sd_x_int / sd_y_unemp
se_sde_unemp <- se_unemp * sd_x_int / sd_y_unemp

# Student rate
beta_stu <- coef(m5)[grep("vocational.*intensity.*post", names(coef(m5)))]
se_stu <- sqrt(diag(vcov(m5)))[grep("vocational.*intensity.*post", names(coef(m5)))]
sd_y_stu <- sd(panel$student_pct, na.rm = TRUE)
sde_stu <- beta_stu * sd_x_int / sd_y_stu
se_sde_stu <- se_stu * sd_x_int / sd_y_stu

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

cat("SDE Employment:", sde_emp, "->", classify(sde_emp), "\n")
cat("SDE Unemployment:", sde_unemp, "->", classify(sde_unemp), "\n")
cat("SDE Student:", sde_stu, "->", classify(sde_stu), "\n")

# Heterogeneity: high vs low intensity regions
panel_high <- filter(panel, high_intensity == 1, sector == "vocational")
panel_low <- filter(panel, high_intensity == 0, sector == "vocational")

m_high <- feols(employed_pct ~ intensity:post | region_id + year,
                data = panel_high, cluster = ~region_id)
m_low <- feols(employed_pct ~ intensity:post | region_id + year,
               data = panel_low, cluster = ~region_id)

beta_high <- coef(m_high)[1]
se_high <- sqrt(diag(vcov(m_high)))[1]
sd_y_high <- sd(panel_high$employed_pct, na.rm = TRUE)
sd_x_high <- sd(panel_high$intensity, na.rm = TRUE)
sde_high <- beta_high * sd_x_high / sd_y_high
se_sde_high <- se_high * sd_x_high / sd_y_high

beta_low <- coef(m_low)[1]
se_low <- sqrt(diag(vcov(m_low)))[1]
sd_y_low <- sd(panel_low$employed_pct, na.rm = TRUE)
sd_x_low <- sd(panel_low$intensity, na.rm = TRUE)
sde_low <- beta_low * sd_x_low / sd_y_low
se_sde_low <- se_low * sd_x_low / sd_y_low

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Finland. ",
  "\\textbf{Research question:} Does extending compulsory education from age 16 to 18 improve school-to-work transitions for vocational graduates across Finnish regions? ",
  "\\textbf{Policy mechanism:} The Compulsory Education Act (1214/2020), effective August 2021, requires all students to apply for and attend upper secondary education until age 18, provides free textbooks, and mandates municipal tracking of non-attenders. ",
  "\\textbf{Outcome definition:} Employment, unemployment, and student continuation rates one year after qualification completion, from Statistics Finland school-to-work transition statistics. ",
  "\\textbf{Treatment:} Continuous: pre-reform regional vocational unemployment rate (range 6--24\\%) as mandate intensity. ",
  "\\textbf{Data:} Statistics Finland PxWeb API, 2007--2024, region $\\times$ education sector $\\times$ year panel. ",
  "\\textbf{Method:} Triple-difference (vocational vs.\\ general $\\times$ intensity $\\times$ post) with region-sector and year-sector fixed effects, region-clustered standard errors. ",
  "\\textbf{Sample:} 20 Finnish regions (including \\AA{}land and students with unrecorded region of residence), both education sectors, 18 years. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of intensity and SD($Y$) is the unconditional standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- "\\begin{table}[H]\n\\centering\n\\caption{Standardized Effect Sizes for Main Outcomes}\n\\label{tab:sde}\n"
tabF1 <- paste0(tabF1, "\\begin{adjustbox}{max width=\\textwidth}\n")
tabF1 <- paste0(tabF1, "\\begin{tabular}{llcccccl}\n\\toprule\n")
tabF1 <- paste0(tabF1, "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
tabF1 <- paste0(tabF1, "\\midrule\n")
tabF1 <- paste0(tabF1, "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n")
tabF1 <- paste0(tabF1, sprintf("Employment rate & DDD & %.3f & %.2f & %.2f & %.4f & %.4f & %s \\\\\n",
                                beta_emp, sd_x_int, sd_y_emp, sde_emp, se_sde_emp, classify(sde_emp)))
tabF1 <- paste0(tabF1, sprintf("Unemployment rate & DDD & %.3f & %.2f & %.2f & %.4f & %.4f & %s \\\\\n",
                                beta_unemp, sd_x_int, sd_y_unemp, sde_unemp, se_sde_unemp, classify(sde_unemp)))
tabF1 <- paste0(tabF1, sprintf("Student cont.~rate & DDD & %.3f & %.2f & %.2f & %.4f & %.4f & %s \\\\\n",
                                beta_stu, sd_x_int, sd_y_stu, sde_stu, se_sde_stu, classify(sde_stu)))
tabF1 <- paste0(tabF1, "\\midrule\n")
tabF1 <- paste0(tabF1, "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (vocational graduates by regional intensity)}} \\\\\n")
tabF1 <- paste0(tabF1, sprintf("Employment (high-intensity) & Voc.~only & %.3f & %.2f & %.2f & %.4f & %.4f & %s \\\\\n",
                                beta_high, sd_x_high, sd_y_high, sde_high, se_sde_high, classify(sde_high)))
tabF1 <- paste0(tabF1, sprintf("Employment (low-intensity) & Voc.~only & %.3f & %.2f & %.2f & %.4f & %.4f & %s \\\\\n",
                                beta_low, sd_x_low, sd_y_low, sde_low, se_sde_low, classify(sde_low)))
tabF1 <- paste0(tabF1, "\\bottomrule\n\\end{tabular}\n")
tabF1 <- paste0(tabF1, "\\end{adjustbox}\n")
tabF1 <- paste0(tabF1, "\\par\\vspace{0.3em}\n")
tabF1 <- paste0(tabF1, "{\\scriptsize ", gsub("\\\\item \\\\textit\\{Notes:\\} ", "\\\\textit{Notes:} ", sde_notes), "}\n")
tabF1 <- paste0(tabF1, "\\end{table}\n")

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("Written tabF1_sde.tex\n")

cat("\n=== All tables complete ===\n")
cat("Files:\n")
list.files("../tables/")
