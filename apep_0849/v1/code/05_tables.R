# 05_tables.R — Generate all LaTeX tables
# apep_0849: Taiwan IIA R&D Tax Credit Transition

source("00_packages.R")

tw <- fread("../data/tw_panel.csv")
panel <- fread("../data/analysis_panel.csv")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

sui_classes <- c("257","438","345","349","362","359","385","348","315",
                 "455","375","370","343","382","324","356","365","710","711","713","714","716")
semi_classes <- c("257", "438")
opto_classes <- c("345", "349", "362", "359", "385", "348", "315")

# ── Table 1: Summary Statistics ────────────────────────────────────────────
cat("Table 1\n")
ss <- tw[, .(N = .N, mean_pat = round(mean(n_patents), 1), sd_pat = round(sd(n_patents), 1),
             mean_claims = round(mean(mean_claims, na.rm = TRUE), 1),
             mean_cite = round(mean(mean_citations, na.rm = TRUE), 2)
), by = .(treated_class, post)]

tab1 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Taiwan USPTO Patents by Technology Class and Period}
\\label{tab:sumstats}
\\begin{tabular}{lccccc}
\\toprule
& Class-Years & Mean & SD & Mean & Mean \\\\
& (N) & Patents & Patents & Claims & Citations \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel A: SUI Strategic Classes (22 classes)}} \\\\[3pt]
Pre-IIA (2003--2009) & %d & %.1f & %.1f & %.1f & %.2f \\\\
Post-IIA (2010--2013) & %d & %.1f & %.1f & %.1f & %.2f \\\\[6pt]
\\multicolumn{6}{l}{\\textit{Panel B: Non-Strategic Classes (28 classes)}} \\\\[3pt]
Pre-IIA (2003--2009) & %d & %.1f & %.1f & %.1f & %.2f \\\\
Post-IIA (2010--2013) & %d & %.1f & %.1f & %.1f & %.2f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Unit of observation is USPC class $\\times$ year. SUI strategic classes are 22 USPC mainclasses corresponding to Taiwan's Statute for Upgrading Industries designated sectors: semiconductors (257, 438), optoelectronics (345, 348, 349, 359, 362, 385), communications (343, 370, 375, 455), precision instruments (324, 356, 382), and IT hardware (365, 710--716). Panel restricted to top 50 USPC classes by Taiwan patent volume; utility patents filed at the USPTO, 2003--2013.
\\end{tablenotes}
\\end{table}",
  ss[treated_class == 1 & post == 0, N], ss[treated_class == 1 & post == 0, mean_pat],
  ss[treated_class == 1 & post == 0, sd_pat], ss[treated_class == 1 & post == 0, mean_claims],
  ss[treated_class == 1 & post == 0, mean_cite],
  ss[treated_class == 1 & post == 1, N], ss[treated_class == 1 & post == 1, mean_pat],
  ss[treated_class == 1 & post == 1, sd_pat], ss[treated_class == 1 & post == 1, mean_claims],
  ss[treated_class == 1 & post == 1, mean_cite],
  ss[treated_class == 0 & post == 0, N], ss[treated_class == 0 & post == 0, mean_pat],
  ss[treated_class == 0 & post == 0, sd_pat], ss[treated_class == 0 & post == 0, mean_claims],
  ss[treated_class == 0 & post == 0, mean_cite],
  ss[treated_class == 0 & post == 1, N], ss[treated_class == 0 & post == 1, mean_pat],
  ss[treated_class == 0 & post == 1, sd_pat], ss[treated_class == 0 & post == 1, mean_claims],
  ss[treated_class == 0 & post == 1, mean_cite]
)
writeLines(tab1, "../tables/tab1_sumstats.tex")

# ── Table 2: Main DiD ─────────────────────────────────────────────────────
cat("Table 2\n")
m1 <- feols(ln_patents ~ treated_class:post | uspc_mainclass + year_id, data = tw, cluster = ~uspc_mainclass)
m2 <- feols(ln_patents ~ treated_class:post + log(mean_claims + 1) | uspc_mainclass + year_id, data = tw, cluster = ~uspc_mainclass)
m3 <- fepois(n_patents ~ treated_class:post | uspc_mainclass + year_id, data = tw, cluster = ~uspc_mainclass)
m4 <- feols(mean_claims ~ treated_class:post | uspc_mainclass + year_id, data = tw, cluster = ~uspc_mainclass)
m5 <- feols(mean_citations ~ treated_class:post | uspc_mainclass + year_id, data = tw, cluster = ~uspc_mainclass)

etable(m1, m2, m3, m4, m5,
       headers = c("$\\ln(\\text{Pat.})$", "$\\ln(\\text{Pat.})$", "Patents", "Claims", "Citations"),
       se.below = TRUE,
       title = "Effect of IIA Transition on Taiwan USPTO Patenting",
       label = "tab:main_did",
       notes = paste0("Unit: USPC class $\\times$ year. Treated = 22 SUI strategic classes. ",
                      "Post = 2010--2013. Col.\\ (2) controls for $\\ln(\\text{claims}+1)$. ",
                      "Col.\\ (3) Poisson QMLE. SE clustered by USPC class. ",
                      "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$."),
       file = "../tables/tab2_main_did.tex", replace = TRUE)

# ── Table 3: Placebo ──────────────────────────────────────────────────────
cat("Table 3\n")
il <- panel[assignee_country == "IL"]
kr <- panel[assignee_country == "KR"]
m_il <- feols(ln_patents ~ treated_class:post | uspc_mainclass + year_id, data = il, cluster = ~uspc_mainclass)
m_kr <- feols(ln_patents ~ treated_class:post | uspc_mainclass + year_id, data = kr, cluster = ~uspc_mainclass)
panel[, is_taiwan := ifelse(assignee_country == "TW", 1L, 0L)]
m_ddd <- feols(ln_patents ~ is_taiwan:treated_class:post |
                 assignee_country^uspc_mainclass + assignee_country^year_id + uspc_mainclass^year_id,
               data = panel, cluster = ~assignee_country^uspc_mainclass)
etable(m1, m_il, m_kr, m_ddd,
       headers = c("Taiwan", "Israel", "S.~Korea", "DDD"),
       se.below = TRUE,
       title = "Placebo Tests: Taiwan vs.\\ Israel and South Korea",
       label = "tab:placebo",
       notes = paste0("DV: $\\ln(\\text{Patents}+1)$. Col.\\ (4): DDD estimate. ",
                      "Israel and Korea had no R\\&D credit restructuring in 2010. ",
                      "SE clustered by class (1--3) or country$\\times$class (4)."),
       file = "../tables/tab3_placebo.tex", replace = TRUE)

# ── Table 4: Robustness ──────────────────────────────────────────────────
cat("Table 4\n")
tw_pre <- tw[filing_year <= 2009]
tw_pre[, placebo_post := ifelse(filing_year >= 2007, 1L, 0L)]
m_plac <- feols(ln_patents ~ treated_class:placebo_post | uspc_mainclass + year_id,
                data = tw_pre, cluster = ~uspc_mainclass)
tw[, semi := ifelse(uspc_mainclass %in% semi_classes, 1L, 0L)]
tw[, opto := ifelse(uspc_mainclass %in% opto_classes, 1L, 0L)]
m_semi <- feols(ln_patents ~ semi:post | uspc_mainclass + year_id, data = tw, cluster = ~uspc_mainclass)
m_opto <- feols(ln_patents ~ opto:post | uspc_mainclass + year_id, data = tw, cluster = ~uspc_mainclass)
share <- panel[, .(total = sum(n_patents), tr = sum(n_patents[treated_class == 1])),
               by = .(assignee_country, filing_year)]
share[, sh := tr / total]; share[, post := ifelse(filing_year >= 2010, 1L, 0L)]
share[, is_tw := ifelse(assignee_country == "TW", 1L, 0L)]
share[, yid := as.integer(factor(filing_year))]
m_share <- feols(sh ~ is_tw:post | assignee_country + yid, data = share, cluster = ~assignee_country)
etable(m1, m_plac, m_semi, m_opto, m_share,
       headers = c("Baseline", "Placebo 2007", "Semicond.", "Optoelec.", "Share DiD"),
       se.below = TRUE,
       title = "Robustness Checks and Heterogeneity",
       label = "tab:robustness",
       notes = paste0("Col.\\ (2): placebo treatment at 2007 (pre-period only). ",
                      "Cols.\\ (3)--(4): semiconductor (257, 438) and optoelectronics (345--385) sub-sectors. ",
                      "Col.\\ (5): DV is share of patents in SUI classes; DiD vs.\\ Israel/Korea. ",
                      "SE clustered by class (1--4) or country (5)."),
       file = "../tables/tab4_robustness.tex", replace = TRUE)

# ── SDE Table ─────────────────────────────────────────────────────────────
cat("Table F1: SDE\n")
sd_ln <- tw[post == 0, sd(ln_patents)]
sd_cl <- tw[post == 0, sd(mean_claims, na.rm = TRUE)]
sd_ci <- tw[post == 0, sd(mean_citations, na.rm = TRUE)]

b1 <- coef(m1)["treated_class:post"]; s1 <- se(m1)["treated_class:post"]
b4 <- coef(m4)["treated_class:post"]; s4 <- se(m4)["treated_class:post"]
b5 <- coef(m5)["treated_class:post"]; s5 <- se(m5)["treated_class:post"]
bs <- coef(m_semi)["semi:post"]; ss_v <- se(m_semi)["semi:post"]
bo <- coef(m_opto)["opto:post"]; so <- se(m_opto)["opto:post"]

classify <- function(s) {
  a <- abs(s)
  if (a < 0.005) return("Null")
  if (a < 0.05) return(ifelse(s > 0, "Small positive", "Small negative"))
  if (a < 0.15) return(ifelse(s > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(s > 0, "Large positive", "Large negative"))
}
fmt <- function(x) formatC(x, format = "f", digits = 4)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Taiwan. ",
  "\\textbf{Research question:} Did the 2010 transition from sector-targeted R\\&D tax credits (up to 35\\% for strategic industries under the SUI) to a uniform 15\\% credit (IIA) reduce patenting effort in previously favored technology classes at the USPTO? ",
  "\\textbf{Policy mechanism:} The IIA replaced the SUI's sector-specific enhanced credits with a uniform 15\\% credit for all industries, imposing an effective 20 percentage-point credit reduction on designated strategic sectors including semiconductors, optoelectronics, communications, and IT hardware. ",
  "\\textbf{Outcome definition:} Annual count of utility patent applications filed at the USPTO by Taiwan-based assignees, aggregated at the USPC technology class level; claims per patent measures patent scope; forward citations count subsequent US patents citing each patent. ",
  "\\textbf{Treatment:} Binary; 22 USPC classes corresponding to SUI-designated strategic industries are treated after January 2010. ",
  "\\textbf{Data:} PatentsView bulk download, 2003--2013, USPC class $\\times$ year level, approximately 190,000 utility patents across 50 technology classes and 11 years for three countries (Taiwan, Israel, South Korea). ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with USPC class and year fixed effects; standard errors clustered at the USPC class level; heterogeneity via sample splits between semiconductor and optoelectronics sub-sectors. ",
  "\\textbf{Sample:} Top 50 USPC classes by Taiwan patent volume; utility patents only. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
$\\ln(\\text{Patents})$ & ",fmt(b1)," & ",fmt(s1)," & ",fmt(sd_ln)," & ",fmt(b1/sd_ln)," & ",fmt(s1/sd_ln)," & ",classify(b1/sd_ln)," \\\\
Claims/patent & ",fmt(b4)," & ",fmt(s4)," & ",fmt(sd_cl)," & ",fmt(b4/sd_cl)," & ",fmt(s4/sd_cl)," & ",classify(b4/sd_cl)," \\\\
Forward citations & ",fmt(b5)," & ",fmt(s5)," & ",fmt(sd_ci)," & ",fmt(b5/sd_ci)," & ",fmt(s5/sd_ci)," & ",classify(b5/sd_ci)," \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\[3pt]
$\\ln(\\text{Pat.})$, Semicond. & ",fmt(bs)," & ",fmt(ss_v)," & ",fmt(sd_ln)," & ",fmt(bs/sd_ln)," & ",fmt(ss_v/sd_ln)," & ",classify(bs/sd_ln)," \\\\
$\\ln(\\text{Pat.})$, Optoelec. & ",fmt(bo)," & ",fmt(so)," & ",fmt(sd_ln)," & ",fmt(bo/sd_ln)," & ",fmt(so/sd_ln)," & ",classify(bo/sd_ln)," \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
",sde_notes,"
\\end{tablenotes}
\\end{table}")

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat("\nAll tables done.\n")
