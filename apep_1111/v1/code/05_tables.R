# 05_tables.R — Generate SDE Appendix Table
# FEMA Risk Rating 2.0 and Residential Construction

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

# Standardize treatment
panel <- panel %>%
  mutate(
    claims_std = (claims_per_1000 - mean(claims_per_1000, na.rm = TRUE)) /
                  sd(claims_per_1000, na.rm = TRUE)
  )

# ============================================================================
# SDE Table (Standardized Effect Sizes)
# ============================================================================
cat("=== Generating SDE Table ===\n")

# Compute SDE for each outcome
# For continuous treatment: SDE = beta_hat × SD(X) / SD(Y)
# Since X is already standardized (SD=1), SDE = beta_hat / SD(Y)

# Get pre-treatment SDs
pre_panel <- panel %>% filter(post == 0)

sd_log_total <- sd(pre_panel$log_total_units, na.rm = TRUE)
sd_log_sf <- sd(pre_panel$log_sf_units, na.rm = TRUE)
sd_log_mf <- sd(pre_panel$log_mf_units, na.rm = TRUE)

# Re-run models to get coefficients
m_total <- feols(log_total_units ~ post:claims_std | fips + state_fips^year,
                 data = panel, cluster = ~state_fips)
m_sf <- feols(log_sf_units ~ post:claims_std | fips + state_fips^year,
              data = panel, cluster = ~state_fips)
m_mf <- feols(log_mf_units ~ post:claims_std | fips + state_fips^year,
              data = panel, cluster = ~state_fips)

# Compute SDEs
compute_sde <- function(model, sd_y, var_name = "post:claims_std") {
  # fixest may order the interaction differently
  coef_names <- names(coef(model))
  match_name <- coef_names[grepl("post.*claims_std|claims_std.*post", coef_names)][1]
  if (is.na(match_name)) stop(paste("Cannot find coefficient for", var_name))

  beta <- coef(model)[match_name]
  se_beta <- se(model)[match_name]

  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  classify <- function(x) {
    if (x < -0.15) return("Large negative")
    if (x < -0.05) return("Moderate negative")
    if (x < -0.005) return("Small negative")
    if (x < 0.005) return("Null")
    if (x < 0.05) return("Small positive")
    if (x < 0.15) return("Moderate positive")
    return("Large positive")
  }

  list(
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde)
  )
}

sde_total <- compute_sde(m_total, sd_log_total)
sde_sf <- compute_sde(m_sf, sd_log_sf)
sde_mf <- compute_sde(m_mf, sd_log_mf)

cat(sprintf("Total permits SDE: %.4f (%s)\n", sde_total$sde, sde_total$classification))
cat(sprintf("SF permits SDE: %.4f (%s)\n", sde_sf$sde, sde_sf$classification))
cat(sprintf("MF permits SDE: %.4f (%s)\n", sde_mf$sde, sde_mf$classification))

# --- Panel B: Heterogeneity by population size ---
# Split: urban (pop ≥ 50,000) vs rural (pop < 50,000)
if ("population" %in% names(panel)) {
  panel <- panel %>%
    mutate(urban = as.integer(!is.na(population) & population >= 50000))

  m_urban <- feols(log_total_units ~ post:claims_std | fips + state_fips^year,
                   data = panel %>% filter(urban == 1),
                   cluster = ~state_fips)
  m_rural <- feols(log_total_units ~ post:claims_std | fips + state_fips^year,
                   data = panel %>% filter(urban == 0),
                   cluster = ~state_fips)

  sd_urban <- sd(pre_panel$log_total_units[pre_panel$fips %in%
    panel$fips[panel$urban == 1]], na.rm = TRUE)
  sd_rural <- sd(pre_panel$log_total_units[pre_panel$fips %in%
    panel$fips[panel$urban == 0]], na.rm = TRUE)

  sde_urban <- compute_sde(m_urban, sd_urban)
  sde_rural <- compute_sde(m_rural, sd_rural)
} else {
  # Fallback: split by median claims
  median_claims <- median(panel$claims_per_1000, na.rm = TRUE)
  m_high <- feols(log_total_units ~ post:claims_std | fips + state_fips^year,
                  data = panel %>% filter(claims_per_1000 >= median_claims),
                  cluster = ~state_fips)
  m_low <- feols(log_total_units ~ post:claims_std | fips + state_fips^year,
                 data = panel %>% filter(claims_per_1000 < median_claims),
                 cluster = ~state_fips)

  sd_high <- sd(pre_panel$log_total_units[pre_panel$claims_per_1000 >= median_claims], na.rm = TRUE)
  sd_low <- sd(pre_panel$log_total_units[pre_panel$claims_per_1000 < median_claims], na.rm = TRUE)

  sde_urban <- compute_sde(m_high, sd_high)
  sde_rural <- compute_sde(m_low, sd_low)
}

# Build SDE LaTeX table
format_row <- function(outcome, sde_obj) {
  sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s",
          outcome, sde_obj$beta, sde_obj$se, sde_obj$sd_y,
          sde_obj$sde, sde_obj$se_sde, sde_obj$classification)
}

n_obs_str <- format(nrow(panel), big.mark = ",")
n_counties_str <- format(n_distinct(panel$fips), big.mark = ",")
yr_range <- sprintf("%d--%d", min(panel$year), max(panel$year))

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does FEMA's Risk Rating 2.0, which replaced zone-based flood insurance pricing with property-level actuarial rates, reduce new residential construction in flood-exposed counties? ",
  "\\textbf{Policy mechanism:} Risk Rating 2.0 shifted NFIP premiums from flat zone-based rates to actuarial pricing reflecting property-specific flood frequency, distance to water, and replacement cost, raising premiums substantially in high-risk counties that were previously cross-subsidized. ",
  "\\textbf{Outcome definition:} Log annual residential building permits (total units authorized) from the Census Building Permits Survey, measuring new construction activity at the county level. ",
  "\\textbf{Treatment:} Continuous; standardized pre-RR2.0 NFIP flood claims per 1,000 population, proxying the county-level premium shock intensity. ",
  "\\textbf{Data:} FEMA OpenFEMA NFIP Claims and Census Building Permits Survey, ", yr_range, ", county-year panel with ", n_obs_str, " observations across ", n_counties_str, " counties. ",
  "\\textbf{Method:} Continuous-treatment difference-in-differences with county and state-by-year fixed effects; standard errors clustered by state. ",
  "\\textbf{Sample:} Counties with at least one historical NFIP claim; excludes territories. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  format_row("Total Permits", sde_total), " \\\\\n",
  format_row("Single-Family", sde_sf), " \\\\\n",
  format_row("Multifamily", sde_mf), " \\\\\n",
  "[0.5em]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Urban vs.\\ Rural)}} \\\\\n",
  format_row("Urban Counties", sde_urban), " \\\\\n",
  format_row("Rural Counties", sde_rural), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("SDE table written to tables/tabF1_sde.tex\n")
cat("=== Tables complete ===\n")
