## 05_tables.R — Generate all LaTeX tables including SDE appendix
## apep_0649: Clean Air Zone property values

source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")
options("modelsummary_factory_latex" = "kableExtra")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

load(file.path(DATA_DIR, "main_results.RData"))
load(file.path(DATA_DIR, "robustness_results.RData"))
df <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
df[, date := as.Date(date)]

# ═══════════════════════════════════════════════════════════════
# TABLE 1: SUMMARY STATISTICS
# ═══════════════════════════════════════════════════════════════

df500 <- df[abs(signed_dist_m) <= 500]

# Panel A: By side of boundary
panel_a <- df500[, .(
  `N` = format(.N, big.mark = ","),
  `Mean Price (£)` = format(round(mean(price)), big.mark = ","),
  `Median Price (£)` = format(round(median(price)), big.mark = ","),
  `SD log(Price)` = sprintf("%.3f", sd(log(price))),
  `\\% Flat` = sprintf("%.1f", 100 * mean(prop_type == "F")),
  `\\% Terraced` = sprintf("%.1f", 100 * mean(prop_type == "T")),
  `\\% Semi/Detached` = sprintf("%.1f", 100 * mean(prop_type %in% c("S", "D")))
), by = .(Side = ifelse(inside == 1, "Inside CAZ", "Outside CAZ"))]

# Panel B: By city
panel_b <- df500[, .(
  Class = first(class),
  N = format(.N, big.mark = ","),
  `Mean Price (£)` = format(round(mean(price)), big.mark = ","),
  `Launch` = format(first(as.Date(launch)), "%b %Y"),
  `\\% Post` = sprintf("%.1f", 100 * mean(post))
), by = .(City = city)][order(-as.numeric(gsub(",", "", N)))]

# Write Table 1
sink(file.path(TABLE_DIR, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Property Transactions Within 500m of CAZ Boundaries}\n")
cat("\\label{tab:summary}\n")
cat("\\small\n")

# Panel A
cat("\\vspace{0.5em}\n")
cat("\\textit{Panel A: By Side of Boundary}\n")
cat("\\vspace{0.3em}\n\n")
cat("\\begin{tabular}{lrrrrrrr}\n")
cat("\\hline\\hline\n")
cat(" & N & Mean Price & Median Price & SD log(P) & \\% Flat & \\% Terraced & \\% Semi/Det \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(panel_a)) {
  cat(sprintf("%s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
              panel_a$Side[i], panel_a$N[i], panel_a$`Mean Price (£)`[i],
              panel_a$`Median Price (£)`[i], panel_a$`SD log(Price)`[i],
              panel_a$`\\% Flat`[i], panel_a$`\\% Terraced`[i],
              panel_a$`\\% Semi/Detached`[i]))
}
cat("\\hline\n")
cat("\\end{tabular}\n\n")

# Panel B
cat("\\vspace{1em}\n")
cat("\\textit{Panel B: By City}\n")
cat("\\vspace{0.3em}\n\n")
cat("\\begin{tabular}{llrrrr}\n")
cat("\\hline\\hline\n")
cat("City & Class & N & Mean Price & Launch & \\% Post \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(panel_b)) {
  cat(sprintf("%s & %s & %s & %s & %s & %s \\\\\n",
              panel_b$City[i], panel_b$Class[i], panel_b$N[i],
              panel_b$`Mean Price (£)`[i], panel_b$Launch[i], panel_b$`\\% Post`[i]))
}
cat("\\hline\n")
cat("\\end{tabular}\n\n")

cat("\\vspace{0.5em}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Sample includes all HM Land Registry residential transactions within 500m of a Clean Air Zone boundary, 2018--2024. ")
cat("Class B charges buses, coaches, and HGVs; Class C adds taxis, private hire vehicles, and light goods vehicles; ")
cat("Class D adds non-compliant private cars. ")
cat("Contains HM Land Registry data \\textcopyright\\ Crown copyright and database right.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tab1_summary.tex\n")

# ═══════════════════════════════════════════════════════════════
# TABLE 2: MAIN DIFF-IN-DISC RESULTS
# ═══════════════════════════════════════════════════════════════

tab2_models <- list(
  "(1)" = m1,
  "(2)" = m2,
  "(3)" = m3,
  "(4)" = m4,
  "(5)" = m5
)

cm <- c("inside_post" = "Inside $\\times$ Post",
        "inside" = "Inside CAZ",
        "post" = "Post-launch")

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(x, big.mark = ",")),
  list("raw" = "r.squared", "clean" = "R$^2$", "fmt" = 3)
)

note_tab2 <- paste0("Sample: HM Land Registry residential transactions near CAZ boundaries, 2018--2024. ",
                     "Dependent variable: log(transaction price). ",
                     "Columns (1)--(3) use 500m bandwidth; (4) uses 250m; (5) uses 1,000m. ",
                     "Column (1): city and year-quarter FE. ",
                     "Column (2): adds property type controls. ",
                     "Columns (3)--(5): add local linear polynomial in distance and distance interactions. ",
                     "Standard errors clustered at postcode level in parentheses. ",
                     "* p$<$0.10, ** p$<$0.05, *** p$<$0.01.")

msummary(tab2_models,
         coef_map = cm,
         gof_map = gm,
         stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
         title = "Main Results: Effect of Clean Air Zones on Property Values\\label{tab:main}",
         notes = note_tab2,
         output = file.path(TABLE_DIR, "tab2_main.tex"),
         fmt = 4,
         escape = FALSE)
cat("Wrote tab2_main.tex\n")

# ═══════════════════════════════════════════════════════════════
# TABLE 3: HETEROGENEITY BY CHARGE CLASS
# ═══════════════════════════════════════════════════════════════

tab3_models <- list()
if (!is.null(m_B)) tab3_models[["Class B"]] <- m_B
tab3_models[["Class C"]] <- m_C
tab3_models[["Class D"]] <- m_D

note_tab3 <- paste0("500m bandwidth. Dependent variable: log(transaction price). ",
                     "Class B charges buses, coaches, HGVs only (Portsmouth). ",
                     "Class C adds taxis and LGVs (Bath, Bradford, Tyneside). ",
                     "Class D adds non-compliant private cars (Birmingham, Bristol, Sheffield). ",
                     "All specifications include city (where applicable) and year-quarter FE, property type controls. ",
                     "Standard errors clustered at postcode level. ",
                     "* p$<$0.10, ** p$<$0.05, *** p$<$0.01.")

msummary(tab3_models,
         coef_map = cm,
         gof_map = gm,
         stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
         title = "Heterogeneity by Charge Class\\label{tab:class}",
         notes = note_tab3,
         output = file.path(TABLE_DIR, "tab3_class.tex"),
         fmt = 4,
         escape = FALSE)
cat("Wrote tab3_class.tex\n")

# ═══════════════════════════════════════════════════════════════
# TABLE 4: ROBUSTNESS CHECKS
# ═══════════════════════════════════════════════════════════════

# Collect robustness results into a summary table
rob_rows <- list()

# Bandwidth sensitivity
for (bw_name in names(bw_results)) {
  m <- bw_results[[bw_name]]
  b <- coef(m)["inside_post"]
  s <- se(m)["inside_post"]
  p <- 2 * pnorm(-abs(b / s))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  rob_rows[[length(rob_rows) + 1]] <- data.table(
    Specification = sprintf("Bandwidth: %sm", bw_name),
    Coefficient = sprintf("%.4f%s", b, stars),
    SE = sprintf("(%.4f)", s),
    N = format(nobs(m), big.mark = ",")
  )
}

# Pre-period placebo
if (!is.null(m_pre)) {
  b <- coef(m_pre)["placebo_inside_post"]
  s <- se(m_pre)["placebo_inside_post"]
  p <- 2 * pnorm(-abs(b / s))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  rob_rows[[length(rob_rows) + 1]] <- data.table(
    Specification = "Pre-period placebo",
    Coefficient = sprintf("%.4f%s", b, stars),
    SE = sprintf("(%.4f)", s),
    N = format(nobs(m_pre), big.mark = ",")
  )
}

# Shifted boundary placebo
if (!is.null(m_shifted)) {
  b <- coef(m_shifted)["inside_post_shifted"]
  s <- se(m_shifted)["inside_post_shifted"]
  p <- 2 * pnorm(-abs(b / s))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  rob_rows[[length(rob_rows) + 1]] <- data.table(
    Specification = "Shifted boundary (+500m)",
    Coefficient = sprintf("%.4f%s", b, stars),
    SE = sprintf("(%.4f)", s),
    N = format(nobs(m_shifted), big.mark = ",")
  )
}

# Donut hole
if (!is.null(m_donut)) {
  b <- coef(m_donut)["inside_post"]
  s <- se(m_donut)["inside_post"]
  p <- 2 * pnorm(-abs(b / s))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  rob_rows[[length(rob_rows) + 1]] <- data.table(
    Specification = "Donut hole (50--500m)",
    Coefficient = sprintf("%.4f%s", b, stars),
    SE = sprintf("(%.4f)", s),
    N = format(nobs(m_donut), big.mark = ",")
  )
}

rob_dt <- rbindlist(rob_rows)

sink(file.path(TABLE_DIR, "tab4_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Specification & Inside $\\times$ Post & SE & N \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(rob_dt)) {
  cat(sprintf("%s & %s & %s & %s \\\\\n",
              rob_dt$Specification[i], rob_dt$Coefficient[i], rob_dt$SE[i], rob_dt$N[i]))
}
cat("\\hline\n")
cat("\\end{tabular}\n\n")
cat("\\vspace{0.5em}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Each row reports the Inside $\\times$ Post coefficient from a separate regression. ")
cat("Dependent variable: log(transaction price). All specifications include city and year-quarter FE, ")
cat("property type controls, and local linear polynomial in distance. ")
cat("``Pre-period placebo'' uses only pre-CAZ data and tests for a boundary discontinuity one year before launch. ")
cat("``Shifted boundary'' moves the boundary 500m outward and re-estimates. ")
cat("``Donut hole'' excludes transactions within 50m of the boundary. ")
cat("Standard errors clustered at postcode level. ")
cat("* p$<$0.10, ** p$<$0.05, *** p$<$0.01.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tab4_robustness.tex\n")

# ═══════════════════════════════════════════════════════════════
# TABLE F1: STANDARDIZED EFFECT SIZES (SDE APPENDIX)
# ═══════════════════════════════════════════════════════════════

# SDE = β̂ / SD(Y) for binary treatment
sd_y <- sd(df500$log_price, na.rm = TRUE)

sde_rows <- list()

# Main specification (m3)
b3 <- coef(m3)["inside_post"]
se3 <- se(m3)["inside_post"]
sde3 <- b3 / sd_y
se_sde3 <- se3 / sd_y
class3 <- ifelse(abs(sde3) < 0.005, "Null",
           ifelse(sde3 > 0.15, "Large positive",
           ifelse(sde3 > 0.05, "Moderate positive",
           ifelse(sde3 > 0.005, "Small positive",
           ifelse(sde3 < -0.15, "Large negative",
           ifelse(sde3 < -0.05, "Moderate negative", "Small negative"))))))

sde_rows[[1]] <- data.table(
  Outcome = "log(Price) --- Pooled",
  Beta = sprintf("%.4f", b3),
  SE = sprintf("%.4f", se3),
  SD_Y = sprintf("%.3f", sd_y),
  SDE = sprintf("%.4f", sde3),
  SE_SDE = sprintf("%.4f", se_sde3),
  Classification = class3
)

# Class C
if (!is.null(m_C)) {
  sd_y_C <- sd(df500[class == "C"]$log_price, na.rm = TRUE)
  bC <- coef(m_C)["inside_post"]
  seC <- se(m_C)["inside_post"]
  sdeC <- bC / sd_y_C
  classC <- ifelse(abs(sdeC) < 0.005, "Null",
             ifelse(sdeC > 0.15, "Large positive",
             ifelse(sdeC > 0.05, "Moderate positive",
             ifelse(sdeC > 0.005, "Small positive",
             ifelse(sdeC < -0.15, "Large negative",
             ifelse(sdeC < -0.05, "Moderate negative", "Small negative"))))))
  sde_rows[[length(sde_rows) + 1]] <- data.table(
    Outcome = "log(Price) --- Class C",
    Beta = sprintf("%.4f", bC), SE = sprintf("%.4f", seC),
    SD_Y = sprintf("%.3f", sd_y_C), SDE = sprintf("%.4f", sdeC),
    SE_SDE = sprintf("%.4f", seC / sd_y_C), Classification = classC
  )
}

# Class D
if (!is.null(m_D)) {
  sd_y_D <- sd(df500[class == "D"]$log_price, na.rm = TRUE)
  bD <- coef(m_D)["inside_post"]
  seD <- se(m_D)["inside_post"]
  sdeD <- bD / sd_y_D
  classD <- ifelse(abs(sdeD) < 0.005, "Null",
             ifelse(sdeD > 0.15, "Large positive",
             ifelse(sdeD > 0.05, "Moderate positive",
             ifelse(sdeD > 0.005, "Small positive",
             ifelse(sdeD < -0.15, "Large negative",
             ifelse(sdeD < -0.05, "Moderate negative", "Small negative"))))))
  sde_rows[[length(sde_rows) + 1]] <- data.table(
    Outcome = "log(Price) --- Class D",
    Beta = sprintf("%.4f", bD), SE = sprintf("%.4f", seD),
    SD_Y = sprintf("%.3f", sd_y_D), SDE = sprintf("%.4f", sdeD),
    SE_SDE = sprintf("%.4f", seD / sd_y_D), Classification = classD
  )
}

sde_dt <- rbindlist(sde_rows)

sink(file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(sde_dt)) {
  cat(sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
              sde_dt$Outcome[i], sde_dt$Beta[i], sde_dt$SE[i], sde_dt$SD_Y[i],
              sde_dt$SDE[i], sde_dt$SE_SDE[i], sde_dt$Classification[i]))
}
cat("\\hline\n")
cat("\\end{tabular}\n\n")
cat("\\vspace{0.5em}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} This table reports standardized effect sizes (SDE) for the main causal estimates. ")
cat("SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where $Y$ is log(transaction price). ")
cat("The research question asks whether Clean Air Zones affect nearby property values. ")
cat("Data: HM Land Registry Price Paid Data, 2018--2024, within 500m of CAZ boundaries across 7 English cities. ")
cat("Method: difference-in-discontinuities with city and year-quarter FE, property type controls, and local linear polynomial. ")
cat(sprintf("Sample size: %s transactions. Treatment: being inside a CAZ boundary after its launch date. ", format(nrow(df500), big.mark = ",")))
cat("Classification refers to effect magnitude, not statistical significance: ")
cat("Null ($|$SDE$|<$0.005), Small (0.005--0.05), Moderate (0.05--0.15), Large ($>$0.15).\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
