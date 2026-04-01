## 05_tables.R — Generate all tables (including SDE appendix)
## apep_1281: Pricing to the Cap

source("00_packages.R")

load("../data/bunching_results.RData")
load("../data/robustness_results.RData")
dt <- fread("../data/analysis_sample.csv")
dt[, contract_date := as.Date(contract_date)]
diag <- jsonlite::fromJSON("../data/diagnostics.json")

# Fix key names: R stores as.character(600000) = "6e+05"
# Rename to human-readable keys
k600  <- as.character(600000)   # "6e+05"
k800  <- as.character(800000)   # "8e+05"
k1m   <- as.character(1000000)  # "1e+06"
k650  <- as.character(650000)   # "6.5e+05"
k550  <- as.character(550000)   # "5.5e+05"
k750  <- as.character(750000)   # "7.5e+05"

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

## ====================================================================
## TABLE 1: Summary Statistics
## ====================================================================

dt_res <- dt[prop_type == "residential"]
dt_vl  <- dt[prop_type == "vacant_land"]
dt_nr  <- dt[prop_type %in% c("commercial", "farm")]

summary_rows <- function(d, label) {
  data.frame(
    Panel = label,
    N = formatC(nrow(d), format = "d", big.mark = ","),
    Mean = formatC(mean(d$purchase_price), format = "f", digits = 0, big.mark = ","),
    Median = formatC(median(d$purchase_price), format = "f", digits = 0, big.mark = ","),
    SD = formatC(sd(d$purchase_price), format = "f", digits = 0, big.mark = ","),
    Min = formatC(min(d$purchase_price), format = "f", digits = 0, big.mark = ","),
    Max = formatC(max(d$purchase_price), format = "f", digits = 0, big.mark = ",")
  )
}

tab1 <- rbind(
  summary_rows(dt_res, "Residential"),
  summary_rows(dt_vl, "Vacant Land"),
  summary_rows(dt_nr, "Commercial/Farm")
)

# Write LaTeX
sink(file.path(tables_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: NSW Property Transactions, 2018--2025}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lrrrrrr}\n")
cat("\\hline\\hline\n")
cat("Property Type & N & Mean & Median & SD & Min & Max \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(tab1)) {
  cat(sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
              tab1$Panel[i], tab1$N[i], tab1$Mean[i], tab1$Median[i],
              tab1$SD[i], tab1$Min[i], tab1$Max[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Universe of NSW Valuer General Property Sales Information (PSI) transactions\n")
cat("with contract dates January 2018--December 2025, purchase prices between \\$100,000 and \\$2,000,000.\n")
cat("Prices are in nominal Australian dollars.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

## ====================================================================
## TABLE 2: Pooled Bunching Estimates
## ====================================================================

sink(file.path(tables_dir, "tab2_bunching.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Bunching Estimates at First Home Buyer Subsidy Thresholds}\n")
cat("\\label{tab:bunching}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat(" & \\$600,000 & \\$800,000 & \\$1,000,000 \\\\\n")
cat(" & (FHOG) & (Stamp Duty) & (Concession) \\\\\n")
cat("\\hline\n")
cat("\\addlinespace\n")
cat("\\multicolumn{4}{l}{\\textit{Panel A: All Residential Transactions}} \\\\\n")
cat("\\addlinespace\n")

cat(sprintf("Excess mass ($\\hat{b}$) & %.3f & %.3f & %.3f \\\\\n",
            results[[k600]]$b, results[[k800]]$b, results[[k1m]]$b))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n",
            results[[k600]]$se, results[[k800]]$se, results[[k1m]]$se))
cat(sprintf("Excess count & %s & %s & %s \\\\\n",
            formatC(results[[k600]]$excess, format = "d", big.mark = ","),
            formatC(results[[k800]]$excess, format = "d", big.mark = ","),
            formatC(results[[k1m]]$excess, format = "d", big.mark = ",")))

cat("\\addlinespace\n")
cat("\\multicolumn{4}{l}{\\textit{Panel B: Supply vs.\\ Demand Decomposition at \\$600K}} \\\\\n")
cat("\\addlinespace\n")
cat(sprintf("Vacant land (supply-side) & %.3f & & \\\\\n", vl_600$b))
cat(sprintf(" & (%.3f) & & \\\\\n", vl_600$se))
cat(sprintf("Existing residence (demand) & %.3f & & \\\\\n", ex_600$b))
cat(sprintf(" & (%.3f) & & \\\\\n", ex_600$se))

cat("\\addlinespace\n")
cat("\\multicolumn{4}{l}{\\textit{Panel C: Supply vs.\\ Demand Decomposition at \\$800K}} \\\\\n")
cat("\\addlinespace\n")
cat(sprintf("Vacant land (supply-side) & & %.3f & \\\\\n", vl_800$b))
cat(sprintf(" & & (%.3f) & \\\\\n", vl_800$se))
cat(sprintf("Existing residence (demand) & & %.3f & \\\\\n", ex_800$b))
cat(sprintf(" & & (%.3f) & \\\\\n", ex_800$se))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Excess mass $\\hat{b}$ estimated following Chetty et al.\\ (2011).\n")
cat("Counterfactual density fitted with degree-7 polynomial excluding a \\$30,000-below / \\$5,000-above window.\n")
cat("Bootstrap standard errors (500 replications) in parentheses.\n")
cat("\\$600,000 is the FHOG notch (new homes forfeit \\$10,000 grant above this price).\n")
cat("\\$800,000 is the stamp duty exemption threshold (post-July 2023; \\$650,000 pre-reform).\n")
cat("\\$1,000,000 is the stamp duty concession phase-out.\n")
cat("Vacant land proxies new construction (supply-side developer pricing).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

## ====================================================================
## TABLE 3: Migration Test
## ====================================================================

sink(file.path(tables_dir, "tab3_migration.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Bunching Migration: Pre vs.\\ Post July 2023 Reform}\n")
cat("\\label{tab:migration}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{Policy Thresholds} & \\multicolumn{2}{c}{Control (Round Numbers)} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")
cat(" & \\$650,000 & \\$800,000 & \\$550,000 & \\$750,000 \\\\\n")
cat("\\hline\n")

# Pre-reform
cat("Pre-reform (Jan 2018 -- Jun 2023) & ")
vals_pre <- c(k650, k800, k550, k750)
for (i in seq_along(vals_pre)) {
  key <- paste0(vals_pre[i], "_pre")
  r <- migration_results[[key]]
  cat(sprintf("%.3f", r$b))
  if (i < length(vals_pre)) cat(" & ") else cat(" \\\\\n")
}
# SE row
cat(" & ")
for (i in seq_along(vals_pre)) {
  key <- paste0(vals_pre[i], "_pre")
  r <- migration_results[[key]]
  cat(sprintf("(%.3f)", r$se))
  if (i < length(vals_pre)) cat(" & ") else cat(" \\\\\n")
}
cat("\\addlinespace\n")

# Post-reform
cat("Post-reform (Jul 2023 -- Dec 2025) & ")
vals_post <- c(k650, k800, k550, k750)
for (i in seq_along(vals_post)) {
  key <- paste0(vals_post[i], "_post")
  r <- migration_results[[key]]
  cat(sprintf("%.3f", r$b))
  if (i < length(vals_post)) cat(" & ") else cat(" \\\\\n")
}
cat(" & ")
for (i in seq_along(vals_post)) {
  key <- paste0(vals_post[i], "_post")
  r <- migration_results[[key]]
  cat(sprintf("(%.3f)", r$se))
  if (i < length(vals_post)) cat(" & ") else cat(" \\\\\n")
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Each cell reports excess mass $\\hat{b}$ with bootstrap SE in parentheses.\n")
cat("The July 1, 2023 reform raised the stamp duty exemption threshold from \\$650,000 to \\$800,000.\n")
cat("Policy-driven bunching should migrate (\\$650K falls, \\$800K rises).\n")
cat("Control round numbers (\\$550K, \\$750K) should show no comparable migration.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

## ====================================================================
## TABLE 4: Robustness — Placebo and Sensitivity
## ====================================================================

sink(file.path(tables_dir, "tab4_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & $\\hat{b}$ & SE \\\\\n")
cat("\\hline\n")
cat("\\addlinespace\n")
cat("\\multicolumn{3}{l}{\\textit{Panel A: Placebo --- Commercial/Farm at \\$800K}} \\\\\n")
cat("\\addlinespace\n")
pr_800 <- placebo_results[[k800]]
if (!is.null(pr_800) && !is.na(pr_800$b)) {
  cat(sprintf("Commercial/Farm transactions & %.3f & (%.3f) \\\\\n", pr_800$b, pr_800$se))
} else {
  cat("Commercial/Farm transactions & --- & --- \\\\\n")
}

cat("\\addlinespace\n")
cat("\\multicolumn{3}{l}{\\textit{Panel B: Polynomial Degree Sensitivity (\\$800K)}} \\\\\n")
cat("\\addlinespace\n")
for (deg in c("5", "6", "7", "8", "9")) {
  r <- poly_sensitivity[[deg]]
  cat(sprintf("Degree %s & %.3f & (%.3f) \\\\\n", deg, r$b, r$se))
}

cat("\\addlinespace\n")
cat("\\multicolumn{3}{l}{\\textit{Panel C: Bin Width Sensitivity (\\$800K)}} \\\\\n")
cat("\\addlinespace\n")
for (bw in c("2000", "5000", "10000")) {
  r <- bin_sensitivity[[bw]]
  cat(sprintf("\\$%s bins & %.3f & (%.3f) \\\\\n",
              formatC(as.numeric(bw), format = "d", big.mark = ","), r$b, r$se))
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Panel A tests whether commercial and farm properties --- which face no\n")
cat("first home buyer thresholds --- show policy-driven bunching at \\$800,000.\n")
cat("Panels B and C report sensitivity of the \\$800,000 stamp duty threshold estimate\n")
cat("to polynomial degree and bin width. Baseline: degree 7, \\$5,000 bins.\n")
cat("Bootstrap standard errors in parentheses.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

## ====================================================================
## TABLE F1: Standardized Effect Sizes (SDE Appendix — MANDATORY)
## ====================================================================

# For bunching, the natural standardized effect is excess mass b itself
# b = (observed - counterfactual) / counterfactual_mean, already scale-free

sd_price_val <- sd(dt_res$purchase_price)

# Build SDE data row by row to avoid length mismatches
n_main <- 5
sde_outcome <- character(n_main)
sde_beta    <- numeric(n_main)
sde_se_beta <- numeric(n_main)
sde_sd_y    <- rep(sd_price_val, n_main)
sde_val     <- numeric(n_main)
sde_se_val  <- numeric(n_main)

sde_outcome[1] <- "Bunching: \\$600K (FHOG)"
sde_beta[1]    <- results[[k600]]$excess
sde_se_beta[1] <- results[[k600]]$se * results[[k600]]$counterfactual
sde_val[1]     <- results[[k600]]$b
sde_se_val[1]  <- results[[k600]]$se

sde_outcome[2] <- "Bunching: \\$800K (Stamp Duty)"
sde_beta[2]    <- results[[k800]]$excess
sde_se_beta[2] <- results[[k800]]$se * results[[k800]]$counterfactual
sde_val[2]     <- results[[k800]]$b
sde_se_val[2]  <- results[[k800]]$se

sde_outcome[3] <- "Bunching: \\$1M (Concession)"
sde_beta[3]    <- results[[k1m]]$excess
sde_se_beta[3] <- results[[k1m]]$se * results[[k1m]]$counterfactual
sde_val[3]     <- results[[k1m]]$b
sde_se_val[3]  <- results[[k1m]]$se

sde_outcome[4] <- "Migration: \\$650K (post-reform)"
sde_beta[4]    <- migration_results[[paste0(k650, "_post")]]$excess - migration_results[[paste0(k650, "_pre")]]$excess
sde_se_beta[4] <- NA
sde_val[4]     <- migration_results[[paste0(k650, "_post")]]$b - migration_results[[paste0(k650, "_pre")]]$b
sde_se_val[4]  <- sqrt(migration_results[[paste0(k650, "_post")]]$se^2 + migration_results[[paste0(k650, "_pre")]]$se^2)

sde_outcome[5] <- "Migration: \\$800K (post-reform)"
sde_beta[5]    <- migration_results[[paste0(k800, "_post")]]$excess - migration_results[[paste0(k800, "_pre")]]$excess
sde_se_beta[5] <- NA
sde_val[5]     <- migration_results[[paste0(k800, "_post")]]$b - migration_results[[paste0(k800, "_pre")]]$b
sde_se_val[5]  <- sqrt(migration_results[[paste0(k800, "_post")]]$se^2 + migration_results[[paste0(k800, "_pre")]]$se^2)

sde_rows <- data.frame(
  outcome = sde_outcome, beta = sde_beta, se_beta = sde_se_beta,
  sd_y = sde_sd_y, sde = sde_val, se_sde = sde_se_val,
  stringsAsFactors = FALSE
)

# Classification
classify_sde <- function(s) {
  if (is.na(s)) return("---")
  abs_s <- abs(s)
  if (abs_s < 0.005) return("Null")
  if (abs_s < 0.05) return(ifelse(s > 0, "Small positive", "Small negative"))
  if (abs_s < 0.15) return(ifelse(s > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(s > 0, "Large positive", "Large negative"))
}

sde_rows$classification <- sapply(sde_rows$sde, classify_sde)

# Heterogeneity panel: supply vs demand at $800K
het_rows <- data.frame(
  outcome = c(
    "\\$800K: Vacant land (supply)",
    "\\$800K: Existing residence (demand)"
  ),
  beta = c(vl_800$excess, ex_800$excess),
  se_beta = c(vl_800$se * vl_800$counterfactual, ex_800$se * ex_800$counterfactual),
  sd_y = rep(sd_price_val, 2),
  sde = c(vl_800$b, ex_800$b),
  se_sde = c(vl_800$se, ex_800$se),
  classification = c(classify_sde(vl_800$b), classify_sde(ex_800$b)),
  stringsAsFactors = FALSE
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Australia. ",
  "\\textbf{Research question:} Do first home buyer subsidy price thresholds distort the housing ",
  "transaction price distribution, and does the pattern of bunching reveal whether subsidies are ",
  "captured by sellers or retained by buyers? ",
  "\\textbf{Policy mechanism:} New South Wales operates three overlapping first home buyer subsidies ",
  "with sharp price eligibility thresholds: a \\$10,000 grant forfeited entirely above \\$600,000 (new homes), ",
  "full stamp duty exemption below \\$800,000, and a concession phasing out at \\$1,000,000. The July 2023 ",
  "reform shifted the exemption threshold from \\$650,000 to \\$800,000. ",
  "\\textbf{Outcome definition:} Excess mass $\\hat{b}$ --- the ratio of observed to counterfactual transaction ",
  "counts in a window around each price threshold, where the counterfactual is estimated by fitting a polynomial ",
  "to the density outside the window. ",
  "\\textbf{Treatment:} Binary at each threshold (price below vs.\\ above the eligibility cutoff). ",
  "\\textbf{Data:} NSW Valuer General Property Sales Information, universe of property transactions, ",
  "January 2018--December 2025, ", formatC(nrow(dt), format = "d", big.mark = ","), " observations. ",
  "\\textbf{Method:} Bunching estimation (Chetty et al.\\ 2011; Kleven and Waseem 2013), degree-7 polynomial, ",
  "\\$5,000 bins, bootstrap standard errors (500 replications). ",
  "\\textbf{Sample:} Transactions with prices \\$100,000--\\$2,000,000; residential properties for main estimates, ",
  "commercial/farm for placebo. ",
  "SDE $= \\hat{b}$ (excess mass ratio), the standard bunching estimand. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\addlinespace\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat("\\addlinespace\n")
for (i in 1:nrow(sde_rows)) {
  cat(sprintf("%s & %s & %s & %s & %.3f & %.3f & %s \\\\\n",
              sde_rows$outcome[i],
              formatC(sde_rows$beta[i], format = "d", big.mark = ","),
              ifelse(is.na(sde_rows$se_beta[i]), "---",
                     formatC(round(sde_rows$se_beta[i]), format = "d", big.mark = ",")),
              formatC(round(sde_rows$sd_y[i]), format = "d", big.mark = ","),
              sde_rows$sde[i], sde_rows$se_sde[i],
              sde_rows$classification[i]))
}
cat("\\addlinespace\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Supply vs.\\ Demand)}} \\\\\n")
cat("\\addlinespace\n")
for (i in 1:nrow(het_rows)) {
  cat(sprintf("%s & %s & %s & %s & %.3f & %.3f & %s \\\\\n",
              het_rows$outcome[i],
              formatC(het_rows$beta[i], format = "d", big.mark = ","),
              ifelse(is.na(het_rows$se_beta[i]), "---",
                     formatC(round(het_rows$se_beta[i]), format = "d", big.mark = ",")),
              formatC(round(het_rows$sd_y[i]), format = "d", big.mark = ","),
              het_rows$sde[i], het_rows$se_sde[i],
              het_rows$classification[i]))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("All tables written to", tables_dir, "\n")
cat("DONE: 05_tables.R\n")
