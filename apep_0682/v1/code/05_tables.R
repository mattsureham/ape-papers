## 05_tables.R — Generate all tables including SDE appendix
## apep_0682: Sewage EDM Information Revelation and House Prices

library(data.table)
library(fixest)
library(modelsummary)

DATA_DIR <- "data"
TABLE_DIR <- "tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

options("modelsummary_format_numeric_latex" = "plain")
options("tinytable_tt_eval" = FALSE)

## ── 1. Load data and models ──────────────────────────────────────────────
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
models <- readRDS(file.path(DATA_DIR, "twfe_models.rds"))
rob_models <- readRDS(file.path(DATA_DIR, "robustness_models.rds"))

## ── 2. Table 1: Summary Statistics ───────────────────────────────────────
cat("=== Table 1: Summary Statistics ===\n")

treated_pd <- unique(panel[gname > 0, postcode_district])
control_pd <- unique(panel[gname == 0, postcode_district])

make_summ <- function(dt, label) {
  dt[, .(
    Panel = label,
    `Mean Price (GBP)` = sprintf("%.0f", mean(exp(mean_log_price))),
    `Median Price (GBP)` = sprintf("%.0f", mean(median_price)),
    `Transactions/District-Year` = sprintf("%.1f", mean(n_transactions)),
    `Pct Detached` = sprintf("%.1f", mean(pct_detached, na.rm=TRUE) * 100),
    `Pct Flat` = sprintf("%.1f", mean(pct_flat, na.rm=TRUE) * 100),
    `Districts` = uniqueN(postcode_district),
    `District-Years` = .N
  )]
}

t1 <- rbind(
  make_summ(panel, "Full Sample"),
  make_summ(panel[gname > 0], "Overflow Districts"),
  make_summ(panel[gname == 0], "No-Overflow Districts")
)

# Write LaTeX
t1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lrrrrrrr}\n",
  "\\toprule\n",
  " & Mean Price & Median Price & Txns/Dist-Yr & \\% Detached & \\% Flat & Districts & Dist-Yrs \\\\\n",
  "\\midrule\n"
)
for (i in 1:nrow(t1)) {
  t1_tex <- paste0(t1_tex,
    t1$Panel[i], " & ", t1$`Mean Price (GBP)`[i], " & ", t1$`Median Price (GBP)`[i],
    " & ", t1$`Transactions/District-Year`[i], " & ", t1$`Pct Detached`[i],
    " & ", t1$`Pct Flat`[i], " & ", t1$Districts[i], " & ", t1$`District-Years`[i],
    " \\\\\n"
  )
}
t1_tex <- paste0(t1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Sample covers England, 2016--2024. ``Overflow Districts'' are postcode districts containing at least one storm overflow with EDM monitoring data. Prices from HM Land Registry Price Paid Data. District-years with fewer than 5 transactions excluded.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(t1_tex, file.path(TABLE_DIR, "tab1_summary.tex"))

## ── 3. Table 2: EDM Monitoring Rollout ───────────────────────────────────
cat("=== Table 2: EDM Monitoring Rollout ===\n")

edm_pd <- fread(file.path(DATA_DIR, "edm_postcode_district.csv"))
rollout <- edm_pd[, .(
  Districts = .N,
  `Mean Overflows` = sprintf("%.1f", mean(n_overflows)),
  `Mean Spills` = sprintf("%.1f", mean(mean_spill_count, na.rm=TRUE)),
  `Pct High-Spill` = sprintf("%.1f", mean(high_spill, na.rm=TRUE) * 100)
), by = .(Year = first_treatment_year)]
setorder(rollout, Year)

t2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{EDM Monitoring Rollout by Year}\n",
  "\\label{tab:rollout}\n",
  "\\begin{tabular}{lrrrr}\n",
  "\\toprule\n",
  "Treatment Year & Districts & Mean Overflows & Mean Spills & \\% High-Spill \\\\\n",
  "\\midrule\n"
)
for (i in 1:nrow(rollout)) {
  t2_tex <- paste0(t2_tex,
    rollout$Year[i], " & ", rollout$Districts[i], " & ", rollout$`Mean Overflows`[i],
    " & ", rollout$`Mean Spills`[i], " & ", rollout$`Pct High-Spill`[i], " \\\\\n"
  )
}
t2_tex <- paste0(t2_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Treatment year is the year after the overflow's EDM data collection began (i.e., the first year monitoring data was publicly available). ``High-Spill'' indicates overflows with mean annual spill count $>30$. Data from EA EDM Storm Overflow Annual Returns 2024.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(t2_tex, file.path(TABLE_DIR, "tab2_rollout.tex"))

## ── 4. Table 3: Main Results ─────────────────────────────────────────────
cat("=== Table 3: Main Results ===\n")

cm <- c(
  "treated" = "EDM Revealed",
  "treated_x_spills" = "EDM Revealed $\\times$ log(Spills)",
  "treated_high" = "EDM Revealed $\\times$ High-Spill",
  "treated_low" = "EDM Revealed $\\times$ Low-Spill",
  "pct_detached" = "Pct Detached",
  "pct_flat" = "Pct Flat",
  "pct_new" = "Pct New Build"
)

# Generate Table 3 manually for clean booktabs LaTeX
t3_tex <- "\\begin{table}[htbp]\n\\centering\n\\caption{Effect of EDM Information Revelation on House Prices}\n\\label{tab:main}\n\\begin{tabular}{lcccc}\n\\toprule\n & (1) & (2) & (3) & (4) \\\\\n\\midrule\n"

format_coef <- function(model, var) {
  b <- coef(model)[var]
  se <- sqrt(vcov(model)[var, var])
  stars <- ifelse(abs(b/se) > 2.576, "***",
           ifelse(abs(b/se) > 1.96, "**",
           ifelse(abs(b/se) > 1.645, "*", "")))
  paste0(sprintf("%.4f%s", b, stars), " & (", sprintf("%.4f", se), ")")
}

# Row: EDM Revealed
b1 <- coef(models$m1)["treated"]; se1 <- sqrt(vcov(models$m1)["treated","treated"])
b2 <- coef(models$m2)["treated"]; se2 <- sqrt(vcov(models$m2)["treated","treated"])
b3 <- coef(models$m3)["treated"]; se3 <- sqrt(vcov(models$m3)["treated","treated"])

star <- function(b, se) ifelse(abs(b/se)>2.576,"***",ifelse(abs(b/se)>1.96,"**",ifelse(abs(b/se)>1.645,"*","")))

t3_tex <- paste0(t3_tex,
  "EDM Revealed & ", sprintf("%.4f%s", b1, star(b1,se1)), " & ",
  sprintf("%.4f%s", b2, star(b2,se2)), " & ",
  sprintf("%.4f%s", b3, star(b3,se3)), " & \\\\\n",
  " & (", sprintf("%.4f", se1), ") & (", sprintf("%.4f", se2), ") & (",
  sprintf("%.4f", se3), ") & \\\\\n"
)

# Row: EDM x log(Spills)
b3s <- coef(models$m3)["treated_x_spills"]; se3s <- sqrt(vcov(models$m3)["treated_x_spills","treated_x_spills"])
t3_tex <- paste0(t3_tex,
  "EDM $\\times$ log(Spills) & & & ",
  sprintf("%.4f%s", b3s, star(b3s,se3s)), " & \\\\\n",
  " & & & (", sprintf("%.4f", se3s), ") & \\\\\n"
)

# Row: High-Spill / Low-Spill
bh <- coef(models$m4)["treated_high"]; seh <- sqrt(vcov(models$m4)["treated_high","treated_high"])
bl <- coef(models$m4)["treated_low"]; sel <- sqrt(vcov(models$m4)["treated_low","treated_low"])
t3_tex <- paste0(t3_tex,
  "EDM $\\times$ High-Spill & & & & ",
  sprintf("%.4f%s", bh, star(bh,seh)), " \\\\\n",
  " & & & & (", sprintf("%.4f", seh), ") \\\\\n",
  "EDM $\\times$ Low-Spill & & & & ",
  sprintf("%.4f%s", bl, star(bl,sel)), " \\\\\n",
  " & & & & (", sprintf("%.4f", sel), ") \\\\\n"
)

t3_tex <- paste0(t3_tex,
  "\\midrule\n",
  "Controls & No & Yes & No & No \\\\\n",
  "District FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", format(nobs(models$m1), big.mark=","), " & ",
  format(nobs(models$m2), big.mark=","), " & ",
  format(nobs(models$m3), big.mark=","), " & ",
  format(nobs(models$m4), big.mark=","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at postcode district level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Dependent variable: log mean transaction price. ``High-Spill'' indicates mean annual spill count $>30$. Controls include share detached, share flat, and share new build.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(t3_tex, file.path(TABLE_DIR, "tab3_main.tex"))

## ── 5. Table 4: Robustness ──────────────────────────────────────────────
cat("=== Table 4: Robustness ===\n")

# Generate Table 4 manually
get_row <- function(model, var, label) {
  b <- coef(model)[var]
  se <- sqrt(vcov(model)[var, var])
  s <- star(b, se)
  list(label = label, b = sprintf("%.4f%s", b, s), se = sprintf("(%.4f)", se))
}

t4_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Robustness Checks}\n\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n\\toprule\n",
  " & Placebo & No London & Prop. Type & WaSC \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n"
)

# Placebo
r1 <- get_row(rob_models$placebo, "fake_treated", "Placebo Treatment")
t4_tex <- paste0(t4_tex, r1$label, " & ", r1$b, " & & & \\\\\n & ", r1$se, " & & & \\\\\n")

# No London
r2 <- get_row(rob_models$no_london, "treated", "EDM Revealed")
t4_tex <- paste0(t4_tex, r2$label, " & & ", r2$b, " & & \\\\\n & & ", r2$se, " & & \\\\\n")

# Prop type
r3a <- get_row(rob_models$prop_type, "treated_x_detached", "EDM $\\times$ High Detached")
r3b <- get_row(rob_models$prop_type, "treated_x_nondetached", "EDM $\\times$ Low Detached")
t4_tex <- paste0(t4_tex,
  r3a$label, " & & & ", r3a$b, " & \\\\\n & & & ", r3a$se, " & \\\\\n",
  r3b$label, " & & & ", r3b$b, " & \\\\\n & & & ", r3b$se, " & \\\\\n"
)

# WaSC
r4a <- get_row(rob_models$wasc, "treated_thames", "EDM $\\times$ Thames")
r4b <- get_row(rob_models$wasc, "treated_other", "EDM $\\times$ Other WaSCs")
t4_tex <- paste0(t4_tex,
  r4a$label, " & & & & ", r4a$b, " \\\\\n & & & & ", r4a$se, " \\\\\n",
  r4b$label, " & & & & ", r4b$b, " \\\\\n & & & & ", r4b$se, " \\\\\n"
)

t4_tex <- paste0(t4_tex,
  "\\midrule\n",
  "Observations & ", format(nobs(rob_models$placebo), big.mark=","), " & ",
  format(nobs(rob_models$no_london), big.mark=","), " & ",
  format(nobs(rob_models$prop_type), big.mark=","), " & ",
  format(nobs(rob_models$wasc), big.mark=","), " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at postcode district level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. All models include district and year FE. Column 1: random treatment assigned to no-overflow districts. Column 2: excludes London postcodes. ``High Detached'' = above-median share of detached properties.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(t4_tex, file.path(TABLE_DIR, "tab4_robustness.tex"))

## ── 6. Table 5: Event Study Coefficients ────────────────────────────────
cat("=== Table 5: Event Study ===\n")

es <- models$es_twfe
es_coefs <- data.table(
  term = names(coef(es)),
  estimate = coef(es),
  se = sqrt(diag(vcov(es)))
)
es_coefs[, `:=`(
  stars = fifelse(abs(estimate/se) > 2.576, "***",
          fifelse(abs(estimate/se) > 1.96, "**",
          fifelse(abs(estimate/se) > 1.645, "*", ""))),
  event_time = as.integer(gsub(".*::", "", term))
)]
setorder(es_coefs, event_time)

t5_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study Estimates}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Event Time & Estimate & Std. Error \\\\\n",
  "\\midrule\n"
)
for (i in 1:nrow(es_coefs)) {
  et <- es_coefs$event_time[i]
  label <- ifelse(et == -1, "$t-1$ (ref.)", paste0("$t", ifelse(et >= 0, "+", ""), et, "$"))
  if (et == -1) {
    t5_tex <- paste0(t5_tex, label, " & --- & --- \\\\\n")
  } else {
    t5_tex <- paste0(t5_tex, label, " & ",
      sprintf("%.4f%s", es_coefs$estimate[i], es_coefs$stars[i]), " & (",
      sprintf("%.4f", es_coefs$se[i]), ") \\\\\n")
  }
}
t5_tex <- paste0(t5_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} TWFE event study estimates. Dependent variable: log mean transaction price. Standard errors clustered at postcode district level. $t-1$ is the omitted reference period. Endpoints binned at $t-4$ and $t+5$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(t5_tex, file.path(TABLE_DIR, "tab5_eventstudy.tex"))

## ── 7. SDE Appendix Table ────────────────────────────────────────────────
cat("=== SDE Appendix Table ===\n")

panel_with_overflow <- panel[gname > 0]
sd_y <- sd(panel_with_overflow$mean_log_price)

# Compute SDE for key specifications
make_sde_row <- function(model, outcome_label, model_name, coef_name = "treated") {
  beta <- coef(model)[coef_name]
  se_beta <- sqrt(vcov(model)[coef_name, coef_name])
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  bucket <- fcase(
    sde < -0.15, "Large negative",
    sde < -0.05, "Moderate negative",
    sde < -0.005, "Small negative",
    sde <= 0.005, "Null",
    sde <= 0.05, "Small positive",
    sde <= 0.15, "Moderate positive",
    default = "Large positive"
  )
  data.table(
    Outcome = outcome_label,
    Beta = sprintf("%.4f", beta),
    SE = sprintf("%.4f", se_beta),
    `SD(Y)` = sprintf("%.4f", sd_y),
    SDE = sprintf("%.4f", sde),
    `SE(SDE)` = sprintf("%.4f", se_sde),
    Classification = bucket
  )
}

sde_rows <- rbind(
  make_sde_row(models$m1, "Log price (baseline)", "TWFE"),
  make_sde_row(models$m2, "Log price (controls)", "TWFE + controls"),
  make_sde_row(models$m3, "Log price (dose-response)", "Dose-response"),
  make_sde_row(models$m4, "Log price (high-spill)", "High-spill", "treated_high"),
  make_sde_row(models$m4, "Log price (low-spill)", "Low-spill", "treated_low"),
  make_sde_row(rob_models$no_london, "Log price (ex-London)", "No London")
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)
for (i in 1:nrow(sde_rows)) {
  sde_tex <- paste0(sde_tex,
    sde_rows$Outcome[i], " & ", sde_rows$Beta[i], " & ", sde_rows$SE[i],
    " & ", sde_rows$`SD(Y)`[i], " & ", sde_rows$SDE[i],
    " & ", sde_rows$`SE(SDE)`[i], " & ", sde_rows$Classification[i], " \\\\\n"
  )
}
sde_tex <- paste0(sde_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} This paper estimates the effect of EDM sewage monitoring information revelation on residential property prices in England (2016--2024). The identification strategy is staggered difference-in-differences exploiting the rollout of Event Duration Monitors across 14,000+ storm overflows. Treatment is binary: a postcode district is treated in the first year its overflow monitoring data is publicly available. Sample: postcode-district $\\times$ year panel ($N = ",
  format(nrow(panel), big.mark=","), "$). SD($Y$) computed over treated districts. SDE = $\\hat{\\beta} / \\text{SD}(Y)$. Classification refers to effect magnitude, not statistical significance. Buckets: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, file.path(TABLE_DIR, "tabF1_sde.tex"))

cat("=== All tables generated ===\n")
cat("Files:", paste(list.files(TABLE_DIR, pattern="\\.tex$"), collapse=", "), "\n")
