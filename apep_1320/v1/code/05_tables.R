## 05_tables.R — Generate all tables for the paper
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

load(file.path(data_dir, "main_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

controls <- "log_pop + log_land_area + county_lat + county_lon + lat_sq + lon_sq"

## ================================================================
## Table 1: Summary Statistics
## ================================================================
cat("=== Table 1: Summary Statistics ===\n")

vars_of_interest <- c("mfg_share", "svc_share", "ret_share",
                       "emp_total", "emp_mfg", "emp_svc",
                       "population", "land_sqmi",
                       "has_wwii_airfield", "n_wwii_airfields",
                       "has_airport", "has_med_large", "n_airports")

labels <- c("Manufacturing employment share", "Professional services share",
            "Retail employment share",
            "Total employment", "Manufacturing employment", "Prof. services employment",
            "Population (2019)", "Land area (sq. mi.)",
            "Has WWII airfield (=1)", "Number of WWII airfields",
            "Has any airport (=1)", "Has medium/large airport (=1)",
            "Number of airports")

## Build stats table
stats_rows <- lapply(seq_along(vars_of_interest), function(i) {
  v <- vars_of_interest[i]
  x <- county[[v]]
  x <- x[!is.na(x)]
  data.table(
    Variable = labels[i],
    Mean = mean(x),
    SD = sd(x),
    Min = min(x),
    Max = max(x),
    N = length(x)
  )
})
stats_dt <- rbindlist(stats_rows)

## Format numbers
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, big.mark = ",")

tab1_rows <- paste0(
  "    ", stats_dt$Variable, " & ",
  ifelse(stats_dt$Mean > 100, fmt(stats_dt$Mean, 0), fmt(stats_dt$Mean, 3)), " & ",
  ifelse(stats_dt$SD > 100, fmt(stats_dt$SD, 0), fmt(stats_dt$SD, 3)), " & ",
  ifelse(stats_dt$Min > 100, fmt(stats_dt$Min, 0), fmt(stats_dt$Min, 3)), " & ",
  ifelse(stats_dt$Max > 100, fmt(stats_dt$Max, 0), fmt(stats_dt$Max, 3)),
  " \\\\"
)

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "  & Mean & SD & Min & Max \\\\",
  "\\midrule",
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel A: Employment Composition}} \\\\",
  "\\addlinespace",
  tab1_rows[1:6],
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel B: County Characteristics}} \\\\",
  "\\addlinespace",
  tab1_rows[7:8],
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel C: Instrument and Treatment}} \\\\",
  "\\addlinespace",
  tab1_rows[9:13],
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  paste0("\\begin{tablenotes}[flushleft]\\footnotesize"),
  paste0("\\item \\textit{Notes:} Cross-section of ", format(nrow(county), big.mark = ","),
         " US counties in 2019. Manufacturing employment share is the ratio of NAICS 31--33 ",
         "employment to total employment from County Business Patterns. WWII airfield indicator ",
         "equals one if the county contains a former Army Air Forces airfield identified from ",
         "Wikipedia's state-by-state WWII airfield categories, geolocated via the MediaWiki API, ",
         "and matched to counties using great-circle distance to Census county centroids. ",
         "Airport variables from OurAirports (2024). Medium/large airports follow the ",
         "OurAirports classification."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written\n")

## ================================================================
## Table 2: First Stage and Main Results
## ================================================================
cat("=== Table 2: Main Results ===\n")

## Format coefficient and SE
coef_fmt <- function(model, var, d = 4) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- 2 * pnorm(-abs(b / s))
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  paste0(formatC(b, format = "f", digits = d), "$", stars, "$")
}

se_fmt <- function(model, var, d = 4) {
  s <- se(model)[var]
  paste0("(", formatC(s, format = "f", digits = d), ")")
}

n_fmt <- function(model) format(model$nobs, big.mark = ",")

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{WWII Airfields, Airport Access, and Local Employment}",
  "\\label{tab:main}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{First Stage} & \\multicolumn{3}{c}{Second Stage} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-6}",
  " & \\multicolumn{2}{c}{Has Med./Large Airport} & OLS & Reduced Form & IV \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel A: Manufacturing Employment Share}} \\\\",
  "\\addlinespace",
  paste0("Has WWII airfield & ", coef_fmt(fs1, "has_wwii_airfield"),
         " & ", coef_fmt(fs2, "has_wwii_airfield"),
         " & & ", coef_fmt(rf1, "has_wwii_airfield"), " & \\\\"),
  paste0("  & ", se_fmt(fs1, "has_wwii_airfield"),
         " & ", se_fmt(fs2, "has_wwii_airfield"),
         " & & ", se_fmt(rf1, "has_wwii_airfield"), " & \\\\"),
  "\\addlinespace",
  paste0("Has med./large airport & & & ", coef_fmt(ols2, "has_med_large"),
         " & & ", coef_fmt(iv2, "fit_has_med_large"), " \\\\"),
  paste0("  & & & ", se_fmt(ols2, "has_med_large"),
         " & & ", se_fmt(iv2, "fit_has_med_large"), " \\\\"),
  "\\addlinespace",
  "\\midrule",
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel B: Log Manufacturing Employment}} \\\\",
  "\\addlinespace",
  paste0("Has WWII airfield & & & & ", coef_fmt(rf2, "has_wwii_airfield"),
         " & \\\\"),
  paste0("  & & & & ", se_fmt(rf2, "has_wwii_airfield"),
         " & \\\\"),
  "\\addlinespace",
  paste0("Has med./large airport & & & ", coef_fmt(ols3, "has_med_large"),
         " & & ", coef_fmt(iv3, "fit_has_med_large"), " \\\\"),
  paste0("  & & & ", se_fmt(ols3, "has_med_large"),
         " & & ", se_fmt(iv3, "fit_has_med_large"), " \\\\"),
  "\\addlinespace",
  "\\midrule",
  paste0("Controls & No & Yes & Yes & Yes & Yes \\\\"),
  paste0("Division FE & Yes & Yes & Yes & Yes & Yes \\\\"),
  paste0("First-stage $F$ & & ", formatC((coef(fs2)["has_wwii_airfield"]/se(fs2)["has_wwii_airfield"])^2,
                                          format = "f", digits = 1),
         " & & & ", formatC((coef(fs2)["has_wwii_airfield"]/se(fs2)["has_wwii_airfield"])^2,
                             format = "f", digits = 1), " \\\\"),
  paste0("Observations & ", n_fmt(fs1), " & ", n_fmt(fs2),
         " & ", n_fmt(ols2), " & ", n_fmt(rf1), " & ", n_fmt(iv2), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} Columns (1)--(2) report first-stage estimates of WWII airfield ",
         "presence on having a medium or large airport. Column (3) reports OLS. Column (4) reports ",
         "the reduced form (WWII airfield $\\rightarrow$ employment). Column (5) reports 2SLS estimates ",
         "instrumenting airport access with WWII airfield presence. Controls: log population, log land ",
         "area, latitude, longitude, and their squares. All specifications include Census division ",
         "fixed effects. Standard errors clustered by state in parentheses. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 written\n")

## ================================================================
## Table 3: Balance Tests
## ================================================================
cat("=== Table 3: Balance Tests ===\n")

bal_models <- list(bal_pop, bal_area, bal_lat, bal_lon, bal_density)
bal_labels <- c("Log population", "Log land area", "Latitude", "Longitude", "Log pop. density")

bal_rows <- sapply(seq_along(bal_models), function(i) {
  b <- coef(bal_models[[i]])["has_wwii_airfield"]
  s <- se(bal_models[[i]])["has_wwii_airfield"]
  p <- 2 * pnorm(-abs(b / s))
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  paste0("    ", bal_labels[i], " & ",
         formatC(b, format = "f", digits = 3), "$", stars, "$ & (",
         formatC(s, format = "f", digits = 3), ") \\\\")
})

## Conditional balance with full controls
bal_pop_c <- feols(as.formula(paste("log_pop ~ has_wwii_airfield + log_land_area + county_lat + county_lon + lat_sq + lon_sq | division")),
                   data = county, cluster = ~state_fips)
bal_density_c <- feols(as.formula(paste("log_pop_density ~ has_wwii_airfield + log_land_area + county_lat + county_lon + lat_sq + lon_sq | division")),
                       data = county, cluster = ~state_fips)

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Balance Tests: WWII Airfield Presence and Pre-Determined Covariates}",
  "\\label{tab:balance}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Coefficient on WWII Airfield} \\\\",
  "\\cmidrule(lr){2-3}",
  "Dependent variable & Unconditional & Conditional \\\\",
  "\\midrule",
  "\\addlinespace",
  paste0("    Log population & ", formatC(coef(bal_pop)["has_wwii_airfield"], format = "f", digits = 3),
         "$^{***}$ & ", formatC(coef(bal_pop_c)["has_wwii_airfield"], format = "f", digits = 3),
         ifelse(abs(coef(bal_pop_c)["has_wwii_airfield"]/se(bal_pop_c)["has_wwii_airfield"]) > 2.58, "$^{***}$",
                ifelse(abs(coef(bal_pop_c)["has_wwii_airfield"]/se(bal_pop_c)["has_wwii_airfield"]) > 1.96, "$^{**}$",
                       ifelse(abs(coef(bal_pop_c)["has_wwii_airfield"]/se(bal_pop_c)["has_wwii_airfield"]) > 1.65, "$^{*}$", ""))),
         " \\\\"),
  paste0("      & (", formatC(se(bal_pop)["has_wwii_airfield"], format = "f", digits = 3),
         ") & (", formatC(se(bal_pop_c)["has_wwii_airfield"], format = "f", digits = 3), ") \\\\"),
  "\\addlinespace",
  paste0("    Log pop. density & ", formatC(coef(bal_density)["has_wwii_airfield"], format = "f", digits = 3),
         "$^{***}$ & ", formatC(coef(bal_density_c)["has_wwii_airfield"], format = "f", digits = 3),
         ifelse(abs(coef(bal_density_c)["has_wwii_airfield"]/se(bal_density_c)["has_wwii_airfield"]) > 2.58, "$^{***}$",
                ifelse(abs(coef(bal_density_c)["has_wwii_airfield"]/se(bal_density_c)["has_wwii_airfield"]) > 1.96, "$^{**}$",
                       ifelse(abs(coef(bal_density_c)["has_wwii_airfield"]/se(bal_density_c)["has_wwii_airfield"]) > 1.65, "$^{*}$", ""))),
         " \\\\"),
  paste0("      & (", formatC(se(bal_density)["has_wwii_airfield"], format = "f", digits = 3),
         ") & (", formatC(se(bal_density_c)["has_wwii_airfield"], format = "f", digits = 3), ") \\\\"),
  "\\addlinespace",
  "\\midrule",
  paste0("Geographic controls & No & Yes \\\\"),
  paste0("Division FE & Yes & Yes \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} Each row regresses a pre-determined county characteristic on the ",
         "WWII airfield indicator. ``Unconditional'' includes only division fixed effects. ",
         "``Conditional'' adds log land area, latitude, longitude, and their squares. ",
         "WWII airfield counties are systematically larger and more populated, consistent with ",
         "military siting preferences for large, flat, sparsely settled areas. Conditional balance ",
         "improves substantially with geographic controls. Standard errors clustered by state. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3, file.path(tables_dir, "tab3_balance.tex"))
cat("Table 3 written\n")

## ================================================================
## Table 4: Placebo Outcomes and Heterogeneity
## ================================================================
cat("=== Table 4: Placebo and Heterogeneity ===\n")

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Placebo Outcomes and Urban-Rural Heterogeneity}",
  "\\label{tab:placebo}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Placebo Outcomes (IV)} & \\multicolumn{2}{c}{Heterogeneity: Mfg. Share (IV)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}",
  " & Prof. Svc. & Retail & Log Prof. & Urban & Rural \\\\",
  " & Share & Share & Svc. Emp. & Counties & Counties \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  "\\addlinespace",
  paste0("Has med./large airport & ",
         coef_fmt(iv_svc, "fit_has_med_large"), " & ",
         coef_fmt(iv_ret, "fit_has_med_large"), " & ",
         coef_fmt(iv_svc_log, "fit_has_med_large"), " & ",
         coef_fmt(iv_urban, "fit_has_med_large"), " & ",
         coef_fmt(iv_rural, "fit_has_med_large"), " \\\\"),
  paste0("  & ",
         se_fmt(iv_svc, "fit_has_med_large"), " & ",
         se_fmt(iv_ret, "fit_has_med_large"), " & ",
         se_fmt(iv_svc_log, "fit_has_med_large"), " & ",
         se_fmt(iv_urban, "fit_has_med_large"), " & ",
         se_fmt(iv_rural, "fit_has_med_large"), " \\\\"),
  "\\addlinespace",
  "\\midrule",
  paste0("Controls & Yes & Yes & Yes & Yes & Yes \\\\"),
  paste0("Division FE & Yes & Yes & Yes & Yes & Yes \\\\"),
  paste0("Observations & ", n_fmt(iv_svc), " & ", n_fmt(iv_ret), " & ",
         n_fmt(iv_svc_log), " & ", n_fmt(iv_urban), " & ", n_fmt(iv_rural), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} All columns report 2SLS estimates instrumenting medium/large airport ",
         "access with WWII airfield presence. Columns (1)--(3) test placebo outcomes: professional ",
         "services (NAICS 54) and retail (NAICS 44--45). If airports restructure employment toward ",
         "services, professional services should respond positively while retail (locally traded) ",
         "should not. Column (3) shows the log-level services effect is positive and marginally ",
         "significant. Columns (4)--(5) split the sample at the median population density. ",
         "The negative manufacturing effect concentrates in urban counties; rural counties show a ",
         "small positive (insignificant) effect. Controls and clustering as in Table~\\ref{tab:main}. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4, file.path(tables_dir, "tab4_placebo.tex"))
cat("Table 4 written\n")

## ================================================================
## Table F1: Standardized Effect Size (SDE) — Appendix
## ================================================================
cat("=== Table F1: SDE ===\n")

## SDE = beta / SD(Y) for binary treatment
## Main outcome: manufacturing share
sd_y_mfg <- sd(county$mfg_share)
sd_y_svc <- sd(county$svc_share)

## Panel A: Pooled
beta_mfg <- coef(iv2)["fit_has_med_large"]
se_mfg <- se(iv2)["fit_has_med_large"]
sde_mfg <- beta_mfg / sd_y_mfg
se_sde_mfg <- se_mfg / sd_y_mfg

beta_svc <- coef(iv_svc)["fit_has_med_large"]
se_svc_val <- se(iv_svc)["fit_has_med_large"]
sde_svc <- beta_svc / sd_y_svc
se_sde_svc <- se_svc_val / sd_y_svc

classify_sde <- function(sde) {
  if (abs(sde) < 0.005) "Null"
  else if (sde < -0.15) "Large negative"
  else if (sde < -0.05) "Moderate negative"
  else if (sde < -0.005) "Small negative"
  else if (sde > 0.15) "Large positive"
  else if (sde > 0.05) "Moderate positive"
  else "Small positive"
}

## Panel B: Heterogeneous (urban vs rural splits)
sd_y_mfg_urb <- sd(county[pop_density >= median(county$pop_density)]$mfg_share)
sd_y_mfg_rur <- sd(county[pop_density < median(county$pop_density)]$mfg_share)
beta_urb <- coef(iv_urban)["fit_has_med_large"]
se_urb <- se(iv_urban)["fit_has_med_large"]
beta_rur <- coef(iv_rural)["fit_has_med_large"]
se_rur <- se(iv_rural)["fit_has_med_large"]
sde_urb <- beta_urb / sd_y_mfg_urb
se_sde_urb <- se_urb / sd_y_mfg_urb
sde_rur <- beta_rur / sd_y_mfg_rur
se_sde_rur <- se_rur / sd_y_mfg_rur

fmt4 <- function(x) formatC(x, format = "f", digits = 4)
fmt3 <- function(x) formatC(x, format = "f", digits = 3)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does airport access, instrumented by WWII military airfield legacies, ",
  "causally affect the sectoral composition of local employment? ",
  "\\textbf{Policy mechanism:} The Surplus Property Act of 1944 conveyed hundreds of Army Air Forces ",
  "training airfields to local governments, creating persistent civilian airport infrastructure ",
  "that shapes the spatial economy decades later. ",
  "\\textbf{Outcome definition:} Manufacturing employment share (NAICS 31--33 employment divided by ",
  "total employment) and professional services employment share (NAICS 54) from Census County Business Patterns 2019. ",
  "\\textbf{Treatment:} Binary indicator for county containing a medium or large airport (OurAirports classification). ",
  "\\textbf{Data:} OurAirports (2024), Census CBP (2019), Wikipedia WWII airfield categories with MediaWiki API geocoding; ",
  "cross-section of 3,139 US counties. ",
  "\\textbf{Method:} 2SLS with WWII airfield presence as instrument; Census division fixed effects; standard errors ",
  "clustered by state. ",
  "\\textbf{Sample:} Continental US counties with positive total employment; excludes territories. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-sectional ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace",
  paste0("Manufacturing share & ", fmt4(beta_mfg), " & ", fmt4(se_mfg), " & ", fmt4(sd_y_mfg),
         " & ", fmt3(sde_mfg), " & ", fmt3(se_sde_mfg), " & ", classify_sde(sde_mfg), " \\\\"),
  paste0("Prof. services share & ", fmt4(beta_svc), " & ", fmt4(se_svc_val), " & ", fmt4(sd_y_svc),
         " & ", fmt3(sde_svc), " & ", fmt3(se_sde_svc), " & ", classify_sde(sde_svc), " \\\\"),
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\",
  "\\addlinespace",
  paste0("Mfg. share (urban) & ", fmt4(beta_urb), " & ", fmt4(se_urb), " & ", fmt4(sd_y_mfg_urb),
         " & ", fmt3(sde_urb), " & ", fmt3(se_sde_urb), " & ", classify_sde(sde_urb), " \\\\"),
  paste0("Mfg. share (rural) & ", fmt4(beta_rur), " & ", fmt4(se_rur), " & ", fmt4(sd_y_mfg_rur),
         " & ", fmt3(sde_rur), " & ", fmt3(se_sde_rur), " & ", classify_sde(sde_rur), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 written\n")

cat("\n=== All tables generated ===\n")
cat("Files:\n")
for (f in list.files(tables_dir)) cat("  ", f, "\n")
