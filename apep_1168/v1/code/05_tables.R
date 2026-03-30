##############################################################################
# 05_tables.R — Generate all LaTeX tables (plain LaTeX, no modelsummary)
# apep_1168: Contagious NIMBYism
##############################################################################

source("00_packages.R")
DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

load(file.path(DATA_DIR, "regressions.RData"))
load(file.path(DATA_DIR, "robustness.RData"))

# Ensure types
panel[, fips := as.character(fips)]
panel_no_turb[, fips := as.character(fips)]

# Helper: format coef with stars
fmt_coef <- function(b, se, fmt = "%.4f") {
  p <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  sprintf(paste0(fmt, "$", stars, "$"), b)
}
fmt_se <- function(se, fmt = "%.4f") sprintf(paste0("(", fmt, ")"), se)
fmt_n <- function(n) formatC(n, format = "d", big.mark = ",")

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Table 1 ===\n")
cs <- panel[year == 2024]
cs_nt <- panel_no_turb[year == 2024]

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics (2024 Cross-Section)}",
  "\\label{tab:summary}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{All Counties} & Zero-Turbine \\\\",
  " & Mean & SD & Mean \\\\",
  "\\midrule",
  sprintf("Ordinance adopted & %.3f & %.3f & %.3f \\\\",
    mean(cs$ordinance_adopted, na.rm=T), sd(cs$ordinance_adopted, na.rm=T),
    mean(cs_nt$ordinance_adopted, na.rm=T)),
  sprintf("Own turbines (count) & %.1f & %.1f & 0.0 \\\\",
    mean(cs$own_turbines, na.rm=T), sd(cs$own_turbines, na.rm=T)),
  sprintf("SCI-weighted exposure & %.1f & %.1f & %.1f \\\\",
    mean(cs$sci_exposure_turbines, na.rm=T), sd(cs$sci_exposure_turbines, na.rm=T),
    mean(cs_nt$sci_exposure_turbines, na.rm=T)),
  sprintf("Geo-weighted exposure & %.1f & %.1f & %.1f \\\\",
    mean(cs$geo_exposure_turbines, na.rm=T), sd(cs$geo_exposure_turbines, na.rm=T),
    mean(cs_nt$geo_exposure_turbines, na.rm=T)),
  sprintf("Population (thousands) & %.1f & %.1f & %.1f \\\\",
    mean(cs$pop/1000, na.rm=T), sd(cs$pop/1000, na.rm=T),
    mean(cs_nt$pop/1000, na.rm=T)),
  sprintf("Median household income (\\$) & %s & %s & %s \\\\",
    fmt_n(round(mean(cs$medinc, na.rm=T))), fmt_n(round(sd(cs$medinc, na.rm=T))),
    fmt_n(round(mean(cs_nt$medinc, na.rm=T)))),
  sprintf("College share & %.3f & %.3f & %.3f \\\\",
    mean(cs$college_share, na.rm=T), sd(cs$college_share, na.rm=T),
    mean(cs_nt$college_share, na.rm=T)),
  sprintf("Republican vote share (2020) & %.3f & %.3f & %.3f \\\\",
    mean(cs$gop_share, na.rm=T), sd(cs$gop_share, na.rm=T),
    mean(cs_nt$gop_share, na.rm=T)),
  "\\midrule",
  sprintf("Counties & %s & & %s \\\\", fmt_n(nrow(cs)), fmt_n(nrow(cs_nt))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Cross-section at 2024. ``All Counties'' includes 3,204 U.S. counties in the SCI data. ``Zero-Turbine'' restricts to 2,518 counties that never hosted a turbine. SCI-weighted and geographic-weighted exposure measure weighted cumulative turbines in connected or nearby counties.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{adjustbox}",
  "\\end{table}"
)
writeLines(tab1, file.path(TABLE_DIR, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main Results
# ============================================================================
cat("=== Table 2 ===\n")

# Extract coefficients
get_row <- function(models, varname, label, fmt = "%.6f") {
  coef_line <- paste0(label, " & ")
  se_line <- " & "
  for (m in models) {
    if (varname %in% names(coef(m))) {
      b <- coef(m)[varname]
      s <- se(m)[varname]
      coef_line <- paste0(coef_line, fmt_coef(b, s, fmt), " & ")
      se_line <- paste0(se_line, fmt_se(s, fmt), " & ")
    } else {
      coef_line <- paste0(coef_line, " & ")
      se_line <- paste0(se_line, " & ")
    }
  }
  # Remove trailing " & " and add "\\"
  coef_line <- sub(" & $", " \\\\\\\\", coef_line)
  se_line <- sub(" & $", " \\\\\\\\", se_line)
  c(coef_line, se_line)
}

models <- list(m1, m2, m3, m5, m6)
n_obs <- sapply(models, function(m) fmt_n(m$nobs))

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Wind Turbine Exposure and Anti-Wind Ordinance Adoption}",
  "\\label{tab:main}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{All Counties} & \\multicolumn{2}{c}{Zero-Turbine} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule"
)

# SCI exposure
b <- sapply(models, function(m) if ("sci_exposure_turbines" %in% names(coef(m))) coef(m)["sci_exposure_turbines"] else NA)
s <- sapply(models, function(m) if ("sci_exposure_turbines" %in% names(coef(m))) se(m)["sci_exposure_turbines"] else NA)
p <- 2 * pnorm(-abs(b / s))
stars <- ifelse(p < 0.01, "$^{***}$", ifelse(p < 0.05, "$^{**}$", ifelse(p < 0.1, "$^{*}$", "")))
coef_str <- ifelse(is.na(b), "", sprintf("%.6f%s", b, stars))
se_str <- ifelse(is.na(s), "", sprintf("(%.6f)", s))

tab2 <- c(tab2,
  paste0("SCI-weighted exposure & ", paste(coef_str, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_str, collapse = " & "), " \\\\"),
  "\\addlinespace"
)

# Geo exposure
b2 <- sapply(models, function(m) if ("geo_exposure_turbines" %in% names(coef(m))) coef(m)["geo_exposure_turbines"] else NA)
s2 <- sapply(models, function(m) if ("geo_exposure_turbines" %in% names(coef(m))) se(m)["geo_exposure_turbines"] else NA)
p2 <- 2 * pnorm(-abs(b2 / s2))
stars2 <- ifelse(is.na(p2), "", ifelse(p2 < 0.01, "$^{***}$", ifelse(p2 < 0.05, "$^{**}$", ifelse(p2 < 0.1, "$^{*}$", ""))))
coef_str2 <- ifelse(is.na(b2), "", sprintf("%.6f%s", b2, stars2))
se_str2 <- ifelse(is.na(s2), "", sprintf("(%.6f)", s2))

tab2 <- c(tab2,
  paste0("Geo-weighted exposure & ", paste(coef_str2, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_str2, collapse = " & "), " \\\\"),
  "\\addlinespace"
)

# Own turbines
b3 <- sapply(models, function(m) if ("own_turbines" %in% names(coef(m))) coef(m)["own_turbines"] else NA)
s3 <- sapply(models, function(m) if ("own_turbines" %in% names(coef(m))) se(m)["own_turbines"] else NA)
p3 <- 2 * pnorm(-abs(b3 / s3))
stars3 <- ifelse(is.na(p3), "", ifelse(p3 < 0.01, "$^{***}$", ifelse(p3 < 0.05, "$^{**}$", ifelse(p3 < 0.1, "$^{*}$", ""))))
coef_str3 <- ifelse(is.na(b3), "", sprintf("%.6f%s", b3, stars3))
se_str3 <- ifelse(is.na(s3), "", sprintf("(%.6f)", s3))

tab2 <- c(tab2,
  paste0("Own turbines & ", paste(coef_str3, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_str3, collapse = " & "), " \\\\"),
  "\\midrule",
  paste0("Observations & ", paste(n_obs, collapse = " & "), " \\\\"),
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Within $R^2$ & %.4f & %.4f & %.4f & %.4f & %.4f \\\\",
    fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]], fitstat(m3, "wr2")[[1]],
    fitstat(m5, "wr2")[[1]], fitstat(m6, "wr2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Linear probability model. Dependent variable: indicator for county having adopted an anti-wind ordinance by year $t$. Standard errors clustered by state in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{adjustbox}",
  "\\end{table}"
)
writeLines(tab2, file.path(TABLE_DIR, "tab2_main.tex"))

# ============================================================================
# Table 3: Distance Bands
# ============================================================================
cat("=== Table 3 ===\n")

b_d <- coef(r3_dist)
s_d <- se(r3_dist)
p_d <- 2 * pnorm(-abs(b_d / s_d))
stars_d <- ifelse(p_d < 0.01, "$^{***}$", ifelse(p_d < 0.05, "$^{**}$", ifelse(p_d < 0.1, "$^{*}$", "")))

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Distance Gradient: Turbine Proximity and Ordinance Adoption}",
  "\\label{tab:distance}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  " & Ordinance Adopted \\\\",
  "\\midrule",
  sprintf("Turbines within 100km & %.6f%s \\\\", b_d["turb_0_100km"], stars_d["turb_0_100km"]),
  sprintf(" & (%.6f) \\\\", s_d["turb_0_100km"]),
  "\\addlinespace",
  sprintf("Turbines 100--200km & %.6f%s \\\\", b_d["turb_100_200km"], stars_d["turb_100_200km"]),
  sprintf(" & (%.6f) \\\\", s_d["turb_100_200km"]),
  "\\addlinespace",
  sprintf("Turbines 200--500km & %.6f%s \\\\", b_d["turb_200_500km"], stars_d["turb_200_500km"]),
  sprintf(" & (%.6f) \\\\", s_d["turb_200_500km"]),
  "\\midrule",
  sprintf("Observations & %s \\\\", fmt_n(r3_dist$nobs)),
  "County FE & Yes \\\\",
  "Year FE & Yes \\\\",
  sprintf("Within $R^2$ & %.4f \\\\", fitstat(r3_dist, "wr2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Linear probability model with county and year fixed effects. Regressors count cumulative turbines in all other counties within each distance band. Standard errors clustered by state. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3, file.path(TABLE_DIR, "tab3_distance.tex"))

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("=== Table 4 ===\n")

rob_models <- list(r1, r4)
rob_names <- c("State $\\times$ Year FE", "Excl.\\\\ Preemption")

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & State $\\times$ Year FE & Excl.\\ Preemption \\\\",
  " & (1) & (2) \\\\",
  "\\midrule"
)

for (vn in c("sci_exposure_turbines", "geo_exposure_turbines", "own_turbines")) {
  label <- switch(vn,
    "sci_exposure_turbines" = "SCI-weighted exposure",
    "geo_exposure_turbines" = "Geo-weighted exposure",
    "own_turbines" = "Own turbines")
  bc <- sapply(rob_models, function(m) coef(m)[vn])
  sc <- sapply(rob_models, function(m) se(m)[vn])
  pc <- 2 * pnorm(-abs(bc / sc))
  st <- ifelse(pc < 0.01, "$^{***}$", ifelse(pc < 0.05, "$^{**}$", ifelse(pc < 0.1, "$^{*}$", "")))
  tab4 <- c(tab4,
    sprintf("%s & %.6f%s & %.6f%s \\\\", label, bc[1], st[1], bc[2], st[2]),
    sprintf(" & (%.6f) & (%.6f) \\\\", sc[1], sc[2]),
    "\\addlinespace"
  )
}

tab4 <- c(tab4,
  "\\midrule",
  sprintf("Observations & %s & %s \\\\", fmt_n(r1$nobs), fmt_n(r4$nobs)),
  "County FE & Yes & Yes \\\\",
  sprintf("Within $R^2$ & %.4f & %.4f \\\\", fitstat(r1, "wr2")[[1]], fitstat(r4, "wr2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column (1) adds state $\\times$ year fixed effects. Column (2) excludes Oregon and Washington (state siting preemption). Standard errors clustered by state. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4, file.path(TABLE_DIR, "tab4_robustness.tex"))

# ============================================================================
# Table F1: SDE
# ============================================================================
cat("=== Table F1 ===\n")

sd_y_pre <- sd(panel[year < 2010]$ordinance_adopted, na.rm = TRUE)
sd_sci <- sd(panel$sci_exposure_turbines, na.rm = TRUE)
sd_geo <- sd(panel$geo_exposure_turbines, na.rm = TRUE)

# Distance band SD
panel_db2 <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel_db2[, fips := as.character(fips)]
# Re-load distance-band data
load(file.path(DATA_DIR, "robustness.RData"))
sd_turb100 <- sd(panel_db$turb_0_100km, na.rm = TRUE)

# Main outcomes
outcomes <- data.table(
  label = c("Geo-weighted exposure $\\rightarrow$ Ordinance",
            "SCI-weighted exposure $\\rightarrow$ Ordinance",
            "Turbines $<$100km $\\rightarrow$ Ordinance"),
  beta = c(coef(m2)["geo_exposure_turbines"],
           coef(m2)["sci_exposure_turbines"],
           coef(r3_dist)["turb_0_100km"]),
  se_b = c(se(m2)["geo_exposure_turbines"],
           se(m2)["sci_exposure_turbines"],
           se(r3_dist)["turb_0_100km"]),
  sd_x = c(sd_geo, sd_sci, sd_turb100),
  sd_y = rep(sd_y_pre, 3)
)
outcomes[, sde := beta * sd_x / sd_y]
outcomes[, se_sde := se_b * sd_x / sd_y]
outcomes[, class := fcase(
  sde < -0.15, "Large negative",
  sde < -0.05, "Moderate negative",
  sde < -0.005, "Small negative",
  sde <= 0.005, "Null",
  sde <= 0.05, "Small positive",
  sde <= 0.15, "Moderate positive",
  default = "Large positive"
)]

# Panel B: Heterogeneity
med_pop <- median(panel$pop, na.rm = TRUE)
m_rural <- feols(ordinance_adopted ~ geo_exposure_turbines + own_turbines |
                   fips + year, data = panel[pop < med_pop], cluster = ~state_fips)
m_urban <- feols(ordinance_adopted ~ geo_exposure_turbines + own_turbines |
                   fips + year, data = panel[pop >= med_pop], cluster = ~state_fips)

sd_y_r <- sd(panel[pop < med_pop & year < 2010]$ordinance_adopted, na.rm = TRUE)
sd_y_u <- sd(panel[pop >= med_pop & year < 2010]$ordinance_adopted, na.rm = TRUE)
sd_geo_r <- sd(panel[pop < med_pop]$geo_exposure_turbines, na.rm = TRUE)
sd_geo_u <- sd(panel[pop >= med_pop]$geo_exposure_turbines, na.rm = TRUE)

het <- data.table(
  label = c("Geo exposure $\\times$ Rural", "Geo exposure $\\times$ Urban"),
  beta = c(coef(m_rural)["geo_exposure_turbines"], coef(m_urban)["geo_exposure_turbines"]),
  se_b = c(se(m_rural)["geo_exposure_turbines"], se(m_urban)["geo_exposure_turbines"]),
  sd_x = c(sd_geo_r, sd_geo_u),
  sd_y = c(sd_y_r, sd_y_u)
)
het[, sde := beta * sd_x / sd_y]
het[, se_sde := se_b * sd_x / sd_y]
het[, class := fcase(
  sde < -0.15, "Large negative",
  sde < -0.05, "Moderate negative",
  sde < -0.005, "Small negative",
  sde <= 0.005, "Null",
  sde <= 0.05, "Small positive",
  sde <= 0.15, "Moderate positive",
  default = "Large positive"
)]

f <- function(x, d=4) formatC(x, format="f", digits=d)

tabF <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace"
)

for (i in 1:nrow(outcomes)) {
  tabF <- c(tabF, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    outcomes$label[i], f(outcomes$beta[i],6), f(outcomes$se_b[i],6),
    f(outcomes$sd_y[i]), f(outcomes$sde[i]), f(outcomes$se_sde[i]),
    outcomes$class[i]))
}

tabF <- c(tabF,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\",
  "\\addlinespace"
)

for (i in 1:nrow(het)) {
  tabF <- c(tabF, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    het$label[i], f(het$beta[i],6), f(het$se_b[i],6),
    f(het$sd_y[i]), f(het$sde[i]), f(het$se_sde[i]),
    het$class[i]))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does geographic proximity to wind turbine installations in neighboring ",
  "counties increase the probability of adopting anti-wind energy siting ordinances? ",
  "\\textbf{Policy mechanism:} Wind turbines installed in nearby counties generate local opposition ",
  "through visual, noise, and property-value concerns that spread to adjacent jurisdictions, triggering ",
  "preemptive restrictive siting ordinances even in counties without turbines. ",
  "\\textbf{Outcome definition:} Binary indicator equal to one if county has adopted a wind energy ",
  "siting ordinance (setback, noise, or capacity restriction) by year $t$, from NREL 2025 Wind ",
  "Ordinance Database. ",
  "\\textbf{Treatment:} Continuous; geographic-weighted cumulative turbine count uses inverse-distance-squared ",
  "weights for all counties within 500km, normalized to sum to one. ",
  "\\textbf{Data:} NREL Wind Ordinance Database (2025), USGS Wind Turbine Database v8.3, Facebook SCI (2026), ",
  "ACS 2020 5-year, county-level panel 2000--2024, 80,100 county-year observations across 3,204 counties. ",
  "\\textbf{Method:} Linear probability model with county and year fixed effects, standard errors ",
  "clustered by state (56 clusters). ",
  "\\textbf{Sample:} All U.S. counties in Facebook SCI data; Panel B splits at median population. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-2010 ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF <- c(tabF,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{adjustbox}",
  "\\end{table}"
)

writeLines(tabF, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("All tables generated.\n")
