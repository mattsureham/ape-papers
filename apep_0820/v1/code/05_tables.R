## 05_tables.R — Generate SDE appendix table
## apep_0820: Gaussian Plume IV for Pollution and Test Scores

source("00_packages.R")

DATA_DIR <- normalizePath("../data", mustWork = FALSE)
TABLE_DIR <- normalizePath("../tables", mustWork = FALSE)

diagnostics <- jsonlite::fromJSON(file.path(DATA_DIR, "diagnostics.json"))

beta_main <- diagnostics$beta_main
se_main <- diagnostics$se_main

# SDE: since both X and Y are standardized, SDE = beta
sde_math <- beta_main
se_sde <- se_main

classify_sde <- function(sde) {
  a <- abs(sde)
  if (a < 0.005) return("Null")
  if (a < 0.05) return(ifelse(sde < 0, "Small negative", "Small positive"))
  if (a < 0.15) return(ifelse(sde < 0, "Moderate negative", "Moderate positive"))
  return(ifelse(sde < 0, "Large negative", "Large positive"))
}

class_math <- classify_sde(sde_math)
cat("SDE:", round(sde_math, 4), "→", class_math, "\n")

fmt <- function(x, d = 4) formatC(x, format = "f", digits = d)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does predicted ground-level industrial air pollution from nearby major-emitting facilities reduce school-level math proficiency in U.S. public schools? ",
  "\\textbf{Policy mechanism:} Major air-emitting facilities regulated under the Clean Air Act release pollutants from industrial stacks; a Gaussian plume dispersion model predicts where emissions settle at ground level based on plant engineering parameters (stack height, meteorology) and plant-school geometry, creating within-school variation in predicted exposure driven by year-to-year wind pattern shifts that are independent of economic sorting or school investment. ",
  "\\textbf{Outcome definition:} School-level percentage of students scoring at or above proficiency on state math assessments (grades 3--8), from EdFacts, standardized to mean zero and unit variance within the analysis sample. ",
  "\\textbf{Treatment:} Continuous; sum of Gaussian plume predicted ground-level concentrations (per unit emission) from all major facilities within 50km of each school, based on Pasquill--Gifford Class D dispersion coefficients and ASOS wind direction frequencies, standardized to mean zero and unit variance. ",
  "\\textbf{Data:} EPA ECHO major air-emitting facility locations, Iowa Mesonet ASOS hourly wind data (2010, 2013, 2015, 2017), EdFacts school-level math proficiency (2013--2018), NCES EDGE school geocodes; school-year panel; ",
  format(diagnostics$n_obs, big.mark = ","), " observations across ",
  format(diagnostics$n_schools, big.mark = ","), " schools. ",
  "\\textbf{Method:} Reduced-form OLS with school and year fixed effects; standard errors clustered at county level (",
  format(diagnostics$n_counties, big.mark = ","), " counties). ",
  "\\textbf{Sample:} U.S. public schools (grades 3--8) within 50km of at least one EPA ECHO major air-emitting facility, restricted to years with ASOS wind data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  paste0("Math proficiency (std.) & ", fmt(beta_main), " & ", fmt(se_main), " & ",
         fmt(1, 2), " & ", fmt(sde_math), " & ", fmt(se_sde), " & ", class_math, " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_tex, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("SDE table written.\n05_tables.R COMPLETE\n")
