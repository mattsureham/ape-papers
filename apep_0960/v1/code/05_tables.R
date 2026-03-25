## 05_tables.R — Generate all LaTeX tables
## apep_0960: Zambia mining royalty reform

source("00_packages.R")

df <- readRDS("../data/district_panel.rds")
models <- readRDS("../data/models.rds")
rob <- readRDS("../data/robustness_models.rds")
diag <- fromJSON("../data/diagnostics.json")

# ── Table 1: Summary Statistics ──────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

pre <- df %>% filter(year < 2019)

sum_stats <- pre %>%
  group_by(Group = ifelse(mining_district == 1, "Mining Districts", "Non-Mining Districts")) %>%
  summarise(
    N_districts = n_distinct(GID_2),
    `Mean NTL` = sprintf("%.3f", mean(ntl_mean)),
    `SD NTL` = sprintf("%.3f", sd(ntl_mean)),
    `Mean asinh(NTL)` = sprintf("%.3f", mean(asinh_ntl)),
    `SD asinh(NTL)` = sprintf("%.3f", sd(asinh_ntl)),
    `Mean log(NTL)` = sprintf("%.2f", mean(log_ntl)),
    `Median NTL` = sprintf("%.3f", mean(ntl_median)),
    .groups = "drop"
  )

# Also compute post-period
post <- df %>% filter(year >= 2019)
post_stats <- post %>%
  group_by(Group = ifelse(mining_district == 1, "Mining Districts", "Non-Mining Districts")) %>%
  summarise(
    `Mean NTL (Post)` = sprintf("%.3f", mean(ntl_mean)),
    `SD NTL (Post)` = sprintf("%.3f", sd(ntl_mean)),
    .groups = "drop"
  )

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Reform Period (2012--2018)}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Mining Districts & Non-Mining Districts \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: District Characteristics}} \\\\\n",
  "\\addlinespace\n",
  "Number of districts & ", sum_stats$N_districts[sum_stats$Group == "Mining Districts"],
  " & ", sum_stats$N_districts[sum_stats$Group == "Non-Mining Districts"], " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Nighttime Light Intensity (Pre-Reform)}} \\\\\n",
  "\\addlinespace\n",
  "Mean NTL (nW/cm$^2$/sr) & ",
  sum_stats$`Mean NTL`[sum_stats$Group == "Mining Districts"], " & ",
  sum_stats$`Mean NTL`[sum_stats$Group == "Non-Mining Districts"], " \\\\\n",
  "SD NTL & ",
  sum_stats$`SD NTL`[sum_stats$Group == "Mining Districts"], " & ",
  sum_stats$`SD NTL`[sum_stats$Group == "Non-Mining Districts"], " \\\\\n",
  "Mean asinh(NTL) & ",
  sum_stats$`Mean asinh(NTL)`[sum_stats$Group == "Mining Districts"], " & ",
  sum_stats$`Mean asinh(NTL)`[sum_stats$Group == "Non-Mining Districts"], " \\\\\n",
  "SD asinh(NTL) & ",
  sum_stats$`SD asinh(NTL)`[sum_stats$Group == "Mining Districts"], " & ",
  sum_stats$`SD asinh(NTL)`[sum_stats$Group == "Non-Mining Districts"], " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Nighttime Light Intensity (Post-Reform)}} \\\\\n",
  "\\addlinespace\n",
  "Mean NTL (nW/cm$^2$/sr) & ",
  post_stats$`Mean NTL (Post)`[post_stats$Group == "Mining Districts"], " & ",
  post_stats$`Mean NTL (Post)`[post_stats$Group == "Non-Mining Districts"], " \\\\\n",
  "SD NTL & ",
  post_stats$`SD NTL (Post)`[post_stats$Group == "Mining Districts"], " & ",
  post_stats$`SD NTL (Post)`[post_stats$Group == "Non-Mining Districts"], " \\\\\n",
  "\\addlinespace\n",
  "Observations (district-years) & \\multicolumn{2}{c}{", nrow(df), "} \\\\\n",
  "Years & \\multicolumn{2}{c}{2012--2023} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Mining districts are those in Zambia's Copperbelt and North-Western ",
  "provinces with active copper/cobalt mining operations: Kitwe, Ndola, Mufulira, Chingola, ",
  "Luanshya, Kalulushi, Chililabombwe, Mpongwe, Solwezi, Kalumbila, and Kasempa. ",
  "NTL is the annual mean nighttime light intensity from NASA VIIRS Black Marble (VNP46A4) ",
  "measured in nanowatts per square centimeter per steradian.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ── Table 2: Main DiD Results ────────────────────────────────────────────
cat("Generating Table 2: Main DiD Results...\n")

m1 <- models$m1
m2 <- models$m2
m3 <- models$m3
m4 <- models$m4

# Extract coefficients
get_row <- function(m, coef_name) {
  b <- coef(m)[coef_name]
  s <- se(m)[coef_name]
  p <- pvalue(m)[coef_name]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(coef = sprintf("%.4f%s", b, stars), se = sprintf("(%.4f)", s))
}

r1_main <- get_row(m1, "mining_district:post")
r2_main <- get_row(m2, "mining_province:post")
r3_main <- get_row(m3, "mining_district:post")
r4_main <- get_row(m4, "mining_district:post")

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Mining Tax Reform on Nighttime Light Intensity}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & asinh(NTL) & asinh(NTL) & log(NTL) & asinh(NTL) \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "Mining District $\\times$ Post & ", r1_main$coef, " & & ", r3_main$coef, " & ", r4_main$coef, " \\\\\n",
  " & ", r1_main$se, " & & ", r3_main$se, " & ", r4_main$se, " \\\\\n",
  "\\addlinespace\n",
  "Mining Province $\\times$ Post & & ", r2_main$se, " & & \\\\\n",
  " & & ", r2_main$se, " & & \\\\\n",
  "\\addlinespace\n",
  "Copper Price $\\times$ Mining & & & & Yes \\\\\n",
  "District FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "\\addlinespace\n",
  "Observations & ", formatC(nrow(df), big.mark=","), " & ", formatC(nrow(df), big.mark=","),
  " & ", formatC(nrow(df), big.mark=","), " & ", formatC(nrow(df), big.mark=","), " \\\\\n",
  "Districts & 115 & 115 & 115 & 115 \\\\\n",
  "Treated districts & 11 & 21 & 11 & 11 \\\\\n",
  "R$^2$ (within) & ", sprintf("%.4f", fitstat(m1, "wr2")$wr2), " & ",
  sprintf("%.4f", fitstat(m2, "wr2")$wr2), " & ",
  sprintf("%.4f", fitstat(m3, "wr2")$wr2), " & ",
  sprintf("%.4f", fitstat(m4, "wr2")$wr2), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each column reports a two-way fixed effects regression of nighttime light ",
  "intensity on the interaction of mining district status and the post-reform indicator (2019--2023). ",
  "Column~(1) uses the inverse hyperbolic sine of mean NTL. Column~(2) broadens treatment to all ",
  "districts in mining provinces (Copperbelt and North-Western). Column~(3) uses log(NTL + 0.01). ",
  "Column~(4) adds an interaction of mining district with annual copper prices. ",
  "Standard errors clustered at the district level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ── Table 3: Event Study ─────────────────────────────────────────────────
cat("Generating Table 3: Event Study...\n")

es <- models$es
es_ct <- as.data.frame(coeftable(es))
es_ct$event_time <- as.numeric(gsub(".*::", "", gsub(":mining.*", "", rownames(es_ct))))
es_ct <- es_ct %>% arrange(event_time)

es_rows <- ""
for (i in 1:nrow(es_ct)) {
  et <- es_ct$event_time[i]
  b <- es_ct$Estimate[i]
  s <- es_ct$`Std. Error`[i]
  p <- es_ct$`Pr(>|t|)`[i]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  label <- ifelse(et == -1, "$t=-1$ (ref.)", paste0("$t=", ifelse(et >= 0, "+", ""), et, "$"))
  if (et == -1) {
    es_rows <- paste0(es_rows, label, " & --- & --- \\\\\n")
  } else {
    es_rows <- paste0(es_rows, label, " & ", sprintf("%.4f%s", b, stars),
                      " & (", sprintf("%.4f", s), ") \\\\\n")
  }
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Mining District $\\times$ Year Interactions}\n",
  "\\label{tab:event}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Event Time & Coefficient & SE \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{3}{l}{\\textit{Pre-reform}} \\\\\n",
  "\\addlinespace\n",
  es_rows,
  "\\addlinespace\n",
  "District FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Year FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Observations & \\multicolumn{2}{c}{", formatC(nrow(df), big.mark=","), "} \\\\\n",
  "Districts & \\multicolumn{2}{c}{115} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on the interaction of mining district ",
  "status with a year indicator, relative to $t=-1$ (2018). Dependent variable is asinh(NTL). ",
  "Standard errors clustered at the district level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_event.tex")

# ── Table 4: Robustness ─────────────────────────────────────────────────
cat("Generating Table 4: Robustness...\n")

get_rob_row <- function(m, cn) {
  b <- coef(m)[cn]
  s <- se(m)[cn]
  p <- pvalue(m)[cn]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  paste0(sprintf("%.4f%s", b, stars), " & (", sprintf("%.4f", s), ")")
}

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Specification & Coefficient & SE \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "(1) Main specification & ", get_rob_row(models$m1, "mining_district:post"), " \\\\\n",
  "(2) 2019 only (pre-reversal) & ", get_rob_row(rob$r1, "mining_district:post"), " \\\\\n",
  "(3) Drop Lusaka Province & ", get_rob_row(rob$r3, "mining_district:post"), " \\\\\n",
  "(4) Sum of NTL & ", get_rob_row(rob$r4, "mining_district:post"), " \\\\\n",
  "(5) Placebo (fake 2016 reform) & ", get_rob_row(rob$r5, "mining_district:post_fake"), " \\\\\n",
  "(6) Mining province treatment & ", get_rob_row(rob$r6, "mining_province:post"), " \\\\\n",
  "(7) District-specific trends & ", get_rob_row(rob$r7, "mining_district:post"), " \\\\\n",
  "(8) P75 of NTL & ", get_rob_row(rob$r8, "mining_district:post"), " \\\\\n",
  "(9) Copperbelt only & ", get_rob_row(rob$r9, "copperbelt:post"), " \\\\\n",
  "\\addlinespace\n",
  "Randomization inference $p$-value & \\multicolumn{2}{c}{",
  sprintf("%.3f", rob$ri_pval), "} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each row reports the DiD coefficient from a separate regression. ",
  "Row~(1) is the baseline. Row~(2) restricts to 2019 as the only post-treatment year. ",
  "Row~(5) uses 2016 as a placebo reform date with pre-2019 data only. ",
  "Row~(7) adds district-specific linear time trends. ",
  "Row~(8) uses the 75th percentile of pixel-level NTL within each district. ",
  "The randomization inference $p$-value is from 1,000 random permutations of treatment status. ",
  "Standard errors clustered at the district level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robust.tex")

# ── Table F1: Standardized Effect Sizes (SDE) ───────────────────────────
cat("Generating Table F1: SDE...\n")

sd_y_pre <- sd(df$asinh_ntl[df$year < 2019])
main_coef <- as.numeric(coef(models$m1)["mining_district:post"])
main_se <- as.numeric(se(models$m1)["mining_district:post"])
sde_main <- main_coef / sd_y_pre
sde_se_main <- main_se / sd_y_pre

# Copperbelt (heterogeneity split)
df_cb <- df %>% filter(copperbelt == 1 | mining_district == 0)
m_cb <- feols(asinh_ntl ~ copperbelt:post | GID_2 + year,
              data = df_cb, vcov = ~GID_2)
cb_coef <- as.numeric(coef(m_cb)["copperbelt:post"])
cb_se <- as.numeric(se(m_cb)["copperbelt:post"])
sd_y_cb <- sd(df_cb$asinh_ntl[df_cb$year < 2019])
sde_cb <- cb_coef / sd_y_cb
sde_se_cb <- cb_se / sd_y_cb

# NW Province (heterogeneity split)
nw_districts <- c("Solwezi", "Kalumbila", "Kasempa")
df_nw <- df %>% filter(NAME_2 %in% nw_districts | mining_district == 0)
df_nw$nw_mining <- as.integer(df_nw$NAME_2 %in% nw_districts)
m_nw <- feols(asinh_ntl ~ nw_mining:post | GID_2 + year,
              data = df_nw, vcov = ~GID_2)
nw_coef <- as.numeric(coef(m_nw)["nw_mining:post"])
nw_se <- as.numeric(se(m_nw)["nw_mining:post"])
sd_y_nw <- sd(df_nw$asinh_ntl[df_nw$year < 2019])
sde_nw <- nw_coef / sd_y_nw
sde_se_nw <- nw_se / sd_y_nw

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde < 0) return("Small negative") else return("Small positive")
  }
  if (abs_sde < 0.15) {
    if (sde < 0) return("Moderate negative") else return("Moderate positive")
  }
  if (sde < 0) return("Large negative") else return("Large positive")
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Zambia. ",
  "\\textbf{Research question:} Does confiscatory mining taxation---raising effective tax rates ",
  "to 86--105\\%---reduce local economic activity in mining-dependent districts? ",
  "\\textbf{Policy mechanism:} The January 2019 mining royalty restructuring made mineral royalties ",
  "non-deductible from corporate income tax and raised royalty rates, increasing the combined effective ",
  "tax burden on copper mining to 86--105\\% of profits, making Zambia the least competitive of 12 major ",
  "mining jurisdictions and triggering mine closures and investment halts. ",
  "\\textbf{Outcome definition:} Annual mean nighttime light intensity (asinh-transformed) from NASA ",
  "VIIRS Black Marble VNP46A4, measured in nanowatts per square centimeter per steradian. ",
  "\\textbf{Treatment:} Binary indicator for mining-dependent districts (Copperbelt and North-Western provinces). ",
  "\\textbf{Data:} NASA VIIRS Black Marble annual composites (2012--2023), GADM Level 2 boundaries, ",
  "115 districts, 1,380 district-year observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with district and year fixed effects; standard errors ",
  "clustered at the district level; randomization inference with 1,000 permutations. ",
  "\\textbf{Sample:} All 115 Zambian districts; 11 classified as mining-dependent based on location ",
  "in Copperbelt or North-Western provinces with active copper/cobalt operations. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "\\addlinespace\n",
  "asinh(NTL) & ", sprintf("%.4f", main_coef), " & ", sprintf("%.4f", main_se),
  " & ", sprintf("%.3f", sd_y_pre), " & ", sprintf("%.4f", sde_main),
  " & ", sprintf("%.4f", sde_se_main), " & ", classify_sde(sde_main), " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  "\\addlinespace\n",
  "Copperbelt only & ", sprintf("%.4f", cb_coef), " & ", sprintf("%.4f", cb_se),
  " & ", sprintf("%.3f", sd_y_cb), " & ", sprintf("%.4f", sde_cb),
  " & ", sprintf("%.4f", sde_se_cb), " & ", classify_sde(sde_cb), " \\\\\n",
  "North-Western only & ", sprintf("%.4f", nw_coef), " & ", sprintf("%.4f", nw_se),
  " & ", sprintf("%.3f", sd_y_nw), " & ", sprintf("%.4f", sde_nw),
  " & ", sprintf("%.4f", sde_se_nw), " & ", classify_sde(sde_nw), " \\\\\n",
  "\\addlinespace\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_event.tex\n")
cat("  tables/tab4_robust.tex\n")
cat("  tables/tabF1_sde.tex\n")
