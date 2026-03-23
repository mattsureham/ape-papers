## 05_tables.R — Generate all LaTeX tables
## apep_0825: Networked Backlash in Sweden

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

## Load all model results
df          <- read_csv(file.path(DATA_DIR, "analysis.csv"), show_col_types = FALSE)
own_models  <- readRDS(file.path(DATA_DIR, "own_exposure_models.rds"))
net_models  <- readRDS(file.path(DATA_DIR, "network_models.rds"))
placebo     <- readRDS(file.path(DATA_DIR, "placebo_models.rds"))
alt_treat   <- readRDS(file.path(DATA_DIR, "alt_treatment_model.rds"))
county_fe   <- readRDS(file.path(DATA_DIR, "county_fe_model.rds"))
excl_big3   <- readRDS(file.path(DATA_DIR, "excl_big3_model.rds"))
pop_wt      <- readRDS(file.path(DATA_DIR, "pop_weighted_model.rds"))
persist     <- readRDS(file.path(DATA_DIR, "persistence_model.rds"))

## ============================================================================
## TABLE 1: Summary Statistics
## ============================================================================

summ_df <- readRDS(file.path(DATA_DIR, "summary_stats.rds"))
# Fix the sd_2018 entry (it may be character due to CSV)
summ_clean <- summ_df %>%
  filter(!is.na(Mean))

tab1_body <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  "Variable & Mean & SD & Min & Max & N \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(summ_clean))) {
  r <- summ_clean[i, ]
  tab1_body <- paste0(tab1_body,
    sprintf("%s & %.2f & %.2f & %.2f & %.2f & %d \\\\\n",
            r$Variable, r$Mean, r$SD, r$Min, r$Max, r$N))
}

tab1_body <- paste0(tab1_body,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Sample of 283 Swedish municipalities with complete data. ",
  "SD Vote Share is the Sweden Democrats (Sverigedemokraterna) share of valid votes. ",
  "Non-EU Foreign-Born Share is from Kolada (N02925). ",
  "Network Exposure is the SCI-weighted average of other counties' refugee treatment. ",
  "Population from Kolada (N01951).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_body, file.path(TABLE_DIR, "tab1_summary.tex"))

## ============================================================================
## TABLE 2: Own Exposure (OLS)
## ============================================================================

tab2_dict <- c(
  delta_fnoneu = "$\\Delta$ Non-EU Foreign-Born (pp)",
  sd_2014 = "SD Vote Share 2014",
  fnoneu_2014 = "Non-EU Foreign-Born 2014",
  log_pop = "Log Population"
)

etable(own_models$m1, own_models$m2, own_models$m3, own_models$m4, own_models$m5,
       dict = tab2_dict,
       se.below = TRUE,
       depvar = FALSE,
       style.tex = style.tex("aer"),
       title = "Own Refugee Exposure and Sweden Democrats Vote Share Change, 2014--2018",
       label = "tab:own_exposure",
       notes = paste0(
         "Sample: 283 Swedish municipalities. ",
         "Dependent variable: change in SD vote share 2014--2018 (pp). ",
         "Columns (1)--(4) use heteroskedasticity-robust SEs. ",
         "Column (5) clusters at county (l\\\"an) level (20 clusters); ",
         "wild cluster bootstrap (Webb, 9{,}999 draws) $p$-value for treatment: ",
         sprintf("%.3f.", own_models$wcb5$p_val)
       ),
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab2_own_exposure.tex"),
       replace = TRUE)

## ============================================================================
## TABLE 3: Network Exposure — Horse Race
## ============================================================================

tab3_dict <- c(
  network_exposure = "Network Exposure (SCI-weighted)",
  delta_fnoneu = "$\\Delta$ Non-EU Foreign-Born (pp)",
  sd_2014 = "SD Vote Share 2014",
  fnoneu_2014 = "Non-EU Foreign-Born 2014",
  log_pop = "Log Population"
)

etable(net_models$n1, net_models$n2, net_models$n3, net_models$n4,
       dict = tab3_dict,
       se.below = TRUE,
       depvar = FALSE,
       style.tex = style.tex("aer"),
       title = "Network Exposure and Sweden Democrats Vote Share Change, 2014--2018",
       label = "tab:network_exposure",
       notes = paste0(
         "Sample: 283 Swedish municipalities. ",
         "Dependent variable: change in SD vote share 2014--2018 (pp). ",
         "Network Exposure = $\\sum_{k \\neq c} w_{ck} \\times \\Delta\\text{ForeignBorn}_k$, ",
         "where $w_{ck}$ are row-normalized Facebook SCI weights between counties $c$ and $k$. ",
         "Column (4) clusters at county level; ",
         "wild cluster bootstrap $p$-values: network ",
         sprintf("%.3f", net_models$wcb_net$p_val),
         ", own ",
         sprintf("%.3f.", net_models$wcb_own_hr$p_val)
       ),
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab3_network_exposure.tex"),
       replace = TRUE)

## ============================================================================
## TABLE 4: Robustness
## ============================================================================

tab4_dict <- c(
  network_exposure = "Network Exposure",
  delta_fnoneu = "$\\Delta$ Non-EU Foreign-Born",
  delta_fborn = "$\\Delta$ Total Foreign-Born",
  sd_2014 = "SD Vote Share 2014",
  fnoneu_2014 = "Non-EU Foreign-Born 2014",
  fb_2014 = "Foreign-Born 2014",
  log_pop = "Log Population"
)

etable(placebo$p2, alt_treat, county_fe, excl_big3, pop_wt, persist,
       dict = tab4_dict,
       se.below = TRUE,
       depvar = FALSE,
       style.tex = style.tex("aer"),
       title = "Robustness Checks",
       label = "tab:robustness",
       headers = c("Placebo\\\\(2010--14)", "Total\\\\Foreign", "County\\\\FE",
                    "Excl.\\\\Big 3", "Pop.\\\\Weighted", "Persist.\\\\(2018--22)"),
       notes = paste0(
         "Column (1): placebo outcome is $\\Delta$SD 2010--2014 (pre-treatment). ",
         "Column (2): total foreign-born change replaces non-EU. ",
         "Column (3): county (l\\\"an) fixed effects absorb all county-level shocks. ",
         "Column (4): excludes Stockholm, Gothenburg, Malm\\\"o. ",
         "Column (5): population-weighted. ",
         "Column (6): outcome is $\\Delta$SD 2018--2022 (persistence). ",
         "All columns cluster SEs at county level."
       ),
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab4_robustness.tex"),
       replace = TRUE)

## ============================================================================
## TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
## ============================================================================

cat("\n=== Computing SDE table ===\n")

sd_y <- sd(df$delta_sd_1418, na.rm = TRUE)
cat("SD(Y) = SD(ΔSD 2014→2018):", sd_y, "\n")

# Main results from the horse-race model (n4)
n4 <- net_models$n4

# Own exposure SDE
beta_own <- coef(n4)["delta_fnoneu"]
se_own <- sqrt(vcov(n4)["delta_fnoneu", "delta_fnoneu"])
sd_x_own <- sd(df$delta_fnoneu, na.rm = TRUE)
sde_own <- beta_own * sd_x_own / sd_y  # continuous treatment
se_sde_own <- se_own * sd_x_own / sd_y

# Network exposure SDE
beta_net <- coef(n4)["network_exposure"]
se_net <- sqrt(vcov(n4)["network_exposure", "network_exposure"])
sd_x_net <- sd(df$network_exposure, na.rm = TRUE)
sde_net <- beta_net * sd_x_net / sd_y  # continuous treatment
se_sde_net <- se_net * sd_x_net / sd_y

# Classification
classify_sde <- function(s) {
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s <= 0.005) "Null"
  else if (s <= 0.05) "Small positive"
  else if (s <= 0.15) "Moderate positive"
  else "Large positive"
}

sde_rows <- tibble(
  Outcome = c("$\\Delta$ SD Vote Share (own exposure)",
              "$\\Delta$ SD Vote Share (network exposure)"),
  beta = c(beta_own, beta_net),
  SE = c(se_own, se_net),
  SD_Y = c(sd_y, sd_y),
  SDE = c(sde_own, sde_net),
  SE_SDE = c(se_sde_own, se_sde_net),
  Classification = c(classify_sde(sde_own), classify_sde(sde_net))
)

cat("\nSDE Results:\n")
print(sde_rows)

# Generate LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Sweden. ",
  "\\textbf{Research question:} Does the 2016 mandatory refugee settlement law (Bos\\\"attningslagen) ",
  "cause anti-immigration party support to increase, and does this backlash propagate through ",
  "social network ties across counties? ",
  "\\textbf{Policy mechanism:} The law assigned binding refugee quotas to all 290 Swedish ",
  "municipalities using a formula based on labor market capacity and population share, ",
  "eliminating the previous voluntary placement system. ",
  "\\textbf{Outcome definition:} Change in Sweden Democrats (Sverigedemokraterna) vote share ",
  "of valid votes in Riksdag elections, measured in percentage points. ",
  "\\textbf{Treatment:} Continuous; own exposure is the change in non-EU/EFTA foreign-born ",
  "population share 2014--2017 (pp); network exposure is the SCI-weighted average of other ",
  "counties' own treatment. ",
  "\\textbf{Data:} SCB election results (ME0104T3) and Kolada municipality demographics (N02925), ",
  "2010--2022, municipality level, $N = 283$ municipalities. ",
  "\\textbf{Method:} OLS long-difference (2014--2018), clustered at county (l\\\"an) level ",
  "(20 clusters), wild cluster bootstrap (Webb, 9{,}999 draws). ",
  "\\textbf{Sample:} All Swedish municipalities with complete election and demographic data; ",
  "excludes municipalities missing non-EU foreign-born share or SCI county mapping. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, ",
  "where SD($Y$) is the cross-sectional standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(sde_rows))) {
  r <- sde_rows[i, ]
  sde_tab <- paste0(sde_tab, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    r$Outcome, r$beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification
  ))
}

sde_tab <- paste0(sde_tab,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_tab, file.path(TABLE_DIR, "tabF1_sde.tex"))

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Files:\n")
for (f in list.files(TABLE_DIR)) {
  cat("  ", f, "\n")
}
