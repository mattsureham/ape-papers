# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# Paper: AAA Cotton Displacement and Black Occupational Scarring
# =============================================================================

source("00_packages.R")

models <- readRDS("../data/models.rds")
robustness <- readRDS("../data/robustness.rds")
wide <- as.data.table(readRDS("../data/farm_panel_wide.rds"))
long <- as.data.table(readRDS("../data/panel_long.rds"))
summ <- readRDS("../data/summary_stats.rds")

# Helper: format numbers
# Add county_id to wide early (needed for Tables 3 and SDE)
wide[, county_id := paste0(statefip_1930, "_", countyicp_1930)]

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, big.mark = ",")
fmt2 <- function(x) formatC(x, format = "f", digits = 2, big.mark = ",")
fmtN <- function(x) formatC(x, format = "d", big.mark = ",")

# =============================================================================
# TABLE 1: SUMMARY STATISTICS
# =============================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Compute detailed summary stats by race
black_w <- wide[black == 1]
white_w <- wide[black == 0]

make_stats <- function(dt, label) {
  data.table(
    Group = label,
    N = fmtN(nrow(dt)),
    OccScore1930 = fmt2(mean(dt$occscore_1930, na.rm = TRUE)),
    OccScore1940 = fmt2(mean(dt$occscore_1940, na.rm = TRUE)),
    OccScore1950 = fmt2(mean(dt$occscore_1950, na.rm = TRUE)),
    Gain30_50 = fmt2(mean(dt$occscore_1950 - dt$occscore_1930, na.rm = TRUE)),
    SD_Gain = fmt2(sd(dt$occscore_1950 - dt$occscore_1930, na.rm = TRUE)),
    PctMigrated = fmt2(mean(dt$mover_40_50, na.rm = TRUE) * 100),
    FarmShare = fmt2(mean(dt$farm_share, na.rm = TRUE))
  )
}

tab1_data <- rbind(
  make_stats(black_w, "Black farm workers"),
  make_stats(white_w, "White farm workers"),
  make_stats(wide, "All farm workers")
)

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Cotton-Belt Farm Workers, 1930--1950}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lrrrrrrr}\n",
  "\\toprule\n",
  " & $N$ & \\multicolumn{3}{c}{Mean Occupational Score} & 20-Year & Migrated & Farm \\\\\n",
  " &  & 1930 & 1940 & 1950 & Gain & (\\%) & Share \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(tab1_data)) {
  r <- tab1_data[i]
  tab1_tex <- paste0(tab1_tex,
    r$Group, " & ", r$N, " & ", r$OccScore1930, " & ", r$OccScore1940, " & ",
    r$OccScore1950, " & ", r$Gain30_50, " & ", r$PctMigrated, " & ", r$FarmShare, " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Sample consists of male farm workers in 11 cotton-belt Southern states ",
  "(AL, AR, FL, GA, LA, MS, NC, OK, SC, TN, TX) linked across the 1930, 1940, and 1950 ",
  "censuses via the IPUMS Multigenerational Longitudinal Panel (MLP). ",
  "Occupational income score (occscore) measures the median total income of persons in each occupation in 1950. ",
  "``20-Year Gain'' is the change in occscore from 1930 to 1950. ",
  "``Migrated'' indicates interstate move between 1940 and 1950. ",
  "``Farm Share'' is the county-level share of linked 1930 workers in farming.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# =============================================================================
# TABLE 2: MAIN DDD RESULTS
# =============================================================================
cat("Generating Table 2: Main DDD Results...\n")

m1 <- models$m1
m2 <- models$m2
m3 <- models$m3
m4 <- models$m4

# Extract coefficients for pooled models
get_coef <- function(model, var) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))
  list(b = b, s = s, p = p, stars = stars)
}

# Table 2: Pooled DDD
tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Agricultural Intensity on Occupational Mobility: Triple-Differences}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & \\multicolumn{2}{c}{Pooled Post} & \\multicolumn{2}{c}{Period-Specific} \\\\\n",
  "\\midrule\n"
)

# Row: Farm Share x Black x Post (pooled models)
c1 <- get_coef(m1, "treat_triple")
c2 <- get_coef(m2, "treat_triple")

tab2_tex <- paste0(tab2_tex,
  "Farm Share $\\times$ Black $\\times$ Post & ",
  fmt(c1$b), "$", c1$stars, "$ & ", fmt(c2$b), "$", c2$stars, "$ & & \\\\\n",
  " & (", fmt(c1$s), ") & (", fmt(c2$s), ") & & \\\\\n"
)

# Row: Farm Share x Black x 1940 (period-specific models)
c3_40 <- get_coef(m3, "treat_triple_1940")
c4_40 <- get_coef(m4, "treat_triple_1940")

tab2_tex <- paste0(tab2_tex,
  "Farm Share $\\times$ Black $\\times$ 1940 & & & ",
  fmt(c3_40$b), "$", c3_40$stars, "$ & ", fmt(c4_40$b), "$", c4_40$stars, "$ \\\\\n",
  " & & & (", fmt(c3_40$s), ") & (", fmt(c4_40$s), ") \\\\\n"
)

# Row: Farm Share x Black x 1950
c3_50 <- get_coef(m3, "treat_triple_1950")
c4_50 <- get_coef(m4, "treat_triple_1950")

tab2_tex <- paste0(tab2_tex,
  "Farm Share $\\times$ Black $\\times$ 1950 & & & ",
  fmt(c3_50$b), "$", c3_50$stars, "$ & ", fmt(c4_50$b), "$", c4_50$stars, "$ \\\\\n",
  " & & & (", fmt(c3_50$s), ") & (", fmt(c4_50$s), ") \\\\\n"
)

# Row: Farm Share x Post
c1_fp <- get_coef(m1, "treat_double_farm_post")
c2_fp <- get_coef(m2, "treat_double_farm_post")

tab2_tex <- paste0(tab2_tex,
  "Farm Share $\\times$ Post & ", fmt(c1_fp$b), "$", c1_fp$stars, "$ & ",
  fmt(c2_fp$b), "$", c2_fp$stars, "$ & & \\\\\n",
  " & (", fmt(c1_fp$s), ") & (", fmt(c2_fp$s), ") & & \\\\\n"
)

# Footer
n_ind <- fmtN(length(unique(long$pid)))
n_obs <- fmtN(nrow(long))
n_clust <- fmtN(length(unique(long$county_id)))

tab2_tex <- paste0(tab2_tex,
  "\\midrule\n",
  "Individual FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & & Yes & \\\\\n",
  "State $\\times$ Year FE & & Yes & & Yes \\\\\n",
  "\\midrule\n",
  "Individuals & ", n_ind, " & ", n_ind, " & ", n_ind, " & ", n_ind, " \\\\\n",
  "Observations & ", n_obs, " & ", n_obs, " & ", n_obs, " & ", n_obs, " \\\\\n",
  "Clusters (counties) & ", n_clust, " & ", n_clust, " & ", n_clust, " & ", n_clust, " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the county level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "The dependent variable is the IPUMS occupational income score (occscore). ",
  "``Farm Share'' is the county-level share of all linked 1930 workers in farming. ",
  "``Black'' is an indicator for race\\_1930 = 2. ",
  "``Post'' indicates the 1940 and 1950 census waves (vs.\\ 1930 baseline). ",
  "Columns (3)--(4) decompose the post-treatment effect into separate 1940 and 1950 coefficients. ",
  "Sample: male farm workers in 11 cotton-belt states linked via MLP 1930--1940--1950.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# =============================================================================
# TABLE 3: MIGRATION MECHANISM
# =============================================================================
cat("Generating Table 3: Migration Mechanism...\n")

m_mig <- models$m_migration
m_att <- models$m_attenuate

# Panel A: Does AAA intensity predict Black out-migration?
# Panel B: Does migration attenuate occupational scarring?
tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Migration as a Mechanism: Agricultural Intensity and the Second Great Migration}\n",
  "\\label{tab:migration}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Migrated 1940--50 & Occ.\\ Gain 1930--50 \\\\\n",
  " & (All Farm Workers) & (Black Farm Workers) \\\\\n",
  "\\midrule\n"
)

# Panel A: Migration model
cm1 <- get_coef(m_mig, "farm_share:black")
cm_fs <- get_coef(m_mig, "farm_share")
cm_bl <- get_coef(m_mig, "black")

tab3_tex <- paste0(tab3_tex,
  "Farm Share $\\times$ Black & ", fmt(cm1$b, 4), "$", cm1$stars, "$ & \\\\\n",
  " & (", fmt(cm1$s, 4), ") & \\\\\n",
  "Farm Share & ", fmt(cm_fs$b, 4), "$", cm_fs$stars, "$ & \\\\\n",
  " & (", fmt(cm_fs$s, 4), ") & \\\\\n",
  "Black & ", fmt(cm_bl$b, 4), "$", cm_bl$stars, "$ & \\\\\n",
  " & (", fmt(cm_bl$s, 4), ") & \\\\\n"
)

# Panel B: Attenuation model (Black workers only)
ca_int <- get_coef(m_att, "farm_share:mover_40_50")
ca_fs <- get_coef(m_att, "farm_share")
ca_mv <- get_coef(m_att, "mover_40_50")

tab3_tex <- paste0(tab3_tex,
  "Farm Share $\\times$ Migrant & & ", fmt(ca_int$b), "$", ca_int$stars, "$ \\\\\n",
  " & & (", fmt(ca_int$s), ") \\\\\n",
  "Farm Share & & ", fmt(ca_fs$b), "$", ca_fs$stars, "$ \\\\\n",
  " & & (", fmt(ca_fs$s), ") \\\\\n",
  "Migrant & & ", fmt(ca_mv$b), "$", ca_mv$stars, "$ \\\\\n",
  " & & (", fmt(ca_mv$s), ") \\\\\n"
)

n_mig <- fmtN(nrow(wide))
n_black <- fmtN(nrow(wide[black == 1]))

tab3_tex <- paste0(tab3_tex,
  "\\midrule\n",
  "State FE & & Yes \\\\\n",
  "Observations & ", n_mig, " & ", n_black, " \\\\\n",
  "Clusters & ", n_clust, " & ",
  fmtN(length(unique(wide[black == 1]$county_id))), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the county level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Column (1): dependent variable is an indicator for interstate migration between 1940 and 1950; ",
  "sample includes all farm workers (Black and white). ",
  "Column (2): dependent variable is the 20-year change in occupational score (1930 to 1950); ",
  "sample restricted to Black farm workers only. ",
  "``Migrant'' indicates interstate move between 1940 and 1950.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_migration.tex")

# =============================================================================
# TABLE 4: ROBUSTNESS
# =============================================================================
cat("Generating Table 4: Robustness...\n")

loso <- robustness$loso
m_bin <- robustness$m_binary

# Main estimate for reference
main_b <- coef(m2)["treat_triple"]
main_se <- se(m2)["treat_triple"]

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness of the Triple-Difference Estimate}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Specification & Coefficient & SE \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Baseline}} \\\\\n",
  "Main estimate (Table 2, col.\\ 2) & ", fmt(main_b), " & (", fmt(main_se), ") \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Leave-One-State-Out}} \\\\\n"
)

for (i in 1:nrow(loso)) {
  state_names <- c("1"="AL", "5"="AR", "12"="FL", "13"="GA", "22"="LA",
                   "28"="MS", "37"="NC", "40"="OK", "45"="SC", "47"="TN", "48"="TX")
  sn <- state_names[as.character(loso$excluded_state[i])]
  if (is.na(sn)) sn <- as.character(loso$excluded_state[i])
  tab4_tex <- paste0(tab4_tex,
    "Exclude ", sn, " & ", fmt(loso$coef[i]), " & (", fmt(loso$se[i]), ") \\\\\n")
}

# Binary treatment
cb <- get_coef(m_bin, "treat_binary")
tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Alternative Treatment}} \\\\\n",
  "Binary (above-median farm share) & ", fmt(cb$b), "$", cb$stars, "$ & (", fmt(cb$s), ") \\\\\n"
)

# Placebo
if (!is.null(robustness$m_placebo)) {
  cp <- get_coef(robustness$m_placebo, "treat_triple")
  tab4_tex <- paste0(tab4_tex,
    "\\midrule\n",
    "\\multicolumn{3}{l}{\\textit{Panel D: Placebo (Non-Farm Workers)}} \\\\\n",
    "DDD on non-farm workers & ", fmt(cp$b), "$", cp$stars, "$ & (", fmt(cp$s), ") \\\\\n")
}

tab4_tex <- paste0(tab4_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications include individual and state $\\times$ year fixed effects. ",
  "Standard errors clustered at the county level. ",
  "Panel B excludes one state at a time from the baseline sample. ",
  "Panel C replaces the continuous farm-share treatment with an above-median binary indicator. ",
  "Panel D runs the DDD on non-farm workers in the same counties as a placebo test ",
  "(the coefficient should be near zero if AAA specifically affected farm workers).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# =============================================================================
# TABLE F1: STANDARDIZED EFFECT SIZES (SDE)
# =============================================================================
cat("Generating Table F1: Standardized Effect Sizes...\n")

# Main outcome: occupational score
sd_y <- sd(long$occscore, na.rm = TRUE)

# Get main DDD coefficient (Model 2 — preferred specification)
beta_main <- coef(m2)["treat_triple"]
se_main <- se(m2)["treat_triple"]

# SDE = beta / SD(Y) for binary-style treatment
# But farm_share is continuous, so SDE = beta * SD(X) / SD(Y)
sd_x <- sd(long$farm_share, na.rm = TRUE)
sde_main <- beta_main * sd_x / sd_y
se_sde_main <- se_main * sd_x / sd_y

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

# Need dplyr for case_when
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr", repos = "https://cloud.r-project.org")

# Panel A: Pooled
class_main <- classify(sde_main)

# Panel B: Heterogeneous — split by migration status
# Black stayers
wide[, county_id := paste0(statefip_1930, "_", countyicp_1930)]
wide[, occ_gain := occscore_1950 - occscore_1930]
sd_y_gain <- sd(wide$occ_gain, na.rm = TRUE)

# Heterogeneity 1: Black stayers in high-AAA counties
black_stayers <- wide[black == 1 & mover_40_50 == 0]
m_stayer <- feols(occ_gain ~ farm_share | statefip_1930,
                  data = black_stayers, cluster = ~county_id)
beta_stayer <- coef(m_stayer)["farm_share"]
se_stayer <- se(m_stayer)["farm_share"]
sd_x_fs <- sd(black_stayers$farm_share, na.rm = TRUE)
sde_stayer <- beta_stayer * sd_x_fs / sd_y_gain
se_sde_stayer <- se_stayer * sd_x_fs / sd_y_gain
class_stayer <- classify(sde_stayer)

# Heterogeneity 2: Black migrants in high-AAA counties
black_movers <- wide[black == 1 & mover_40_50 == 1]
if (nrow(black_movers) > 100) {
  m_mover <- feols(occ_gain ~ farm_share | statefip_1930,
                   data = black_movers, cluster = ~county_id)
  beta_mover <- coef(m_mover)["farm_share"]
  se_mover <- se(m_mover)["farm_share"]
  sd_x_fm <- sd(black_movers$farm_share, na.rm = TRUE)
  sde_mover <- beta_mover * sd_x_fm / sd_y_gain
  se_sde_mover <- se_mover * sd_x_fm / sd_y_gain
  class_mover <- classify(sde_mover)
} else {
  beta_mover <- NA; se_mover <- NA; sde_mover <- NA; se_sde_mover <- NA
  class_mover <- "N/A"
}

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did the Agricultural Adjustment Act's cotton acreage reduction program (1933--1936) cause long-run occupational scarring for Black farm workers in the cotton South? ",
  "\\textbf{Policy mechanism:} The AAA paid Southern cotton landlords to reduce planted acreage by 25--40\\%; lacking enforcement of tenant protections, landlords used payments to mechanize and evict Black sharecroppers, displacing them from stable (if low-paid) tenancy into casual labor or migration. ",
  "\\textbf{Outcome definition:} Twenty-year change in IPUMS occupational income score (occscore), which measures median 1950 income for each occupation, from 1930 to 1950 census. ",
  "\\textbf{Treatment:} Continuous; county-level share of all linked 1930 workers engaged in farming, measuring agricultural dependency and hence AAA exposure intensity. ",
  "\\textbf{Data:} IPUMS Multigenerational Longitudinal Panel (MLP) linking individuals across 1930, 1940, and 1950 U.S.\\ censuses; 11 cotton-belt Southern states. ",
  "\\textbf{Method:} Triple-differences (county agricultural intensity $\\times$ Black $\\times$ post-1930) with individual and state $\\times$ year fixed effects; standard errors clustered at the county level. ",
  "\\textbf{Sample:} Male farm workers in the cotton South (AL, AR, FL, GA, LA, MS, NC, OK, SC, TN, TX) successfully linked across all three census waves. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of the treatment variable and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "Occ.\\ Score (DDD) & ", fmt(beta_main), " & ", fmt(sd_x), " & ", fmt(sd_y), " & ",
  fmt(sde_main, 4), " & ", fmt(se_sde_main, 4), " & ", class_main, " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Black Farm Workers Only)}} \\\\\n",
  "Stayers (20-yr gain) & ", fmt(beta_stayer), " & ", fmt(sd_x_fs), " & ",
  fmt(sd_y_gain), " & ", fmt(sde_stayer, 4), " & ", fmt(se_sde_stayer, 4), " & ",
  class_stayer, " \\\\\n"
)

if (!is.na(sde_mover)) {
  sde_tex <- paste0(sde_tex,
    "Migrants (20-yr gain) & ", fmt(beta_mover), " & ", fmt(sd_x_fm), " & ",
    fmt(sd_y_gain), " & ", fmt(sde_mover, 4), " & ", fmt(se_sde_mover, 4), " & ",
    class_mover, " \\\\\n")
}

sde_tex <- paste0(sde_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables generated in tables/\n")
cat("  tab1_summary.tex\n  tab2_main.tex\n  tab3_migration.tex\n  tab4_robustness.tex\n  tabF1_sde.tex\n")
