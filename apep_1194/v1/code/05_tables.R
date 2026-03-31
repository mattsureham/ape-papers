# 05_tables.R — Generate all LaTeX tables
# APEP-1194: Positive Train Control and Railroad Accident Prevention

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
results <- readRDS("../data/cs_results.rds")
twfe_results <- readRDS("../data/twfe_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
pre_stats <- readRDS("../data/pre_stats.rds")
pre_sds <- readRDS("../data/pre_sds.rds")
adoption <- readRDS("../data/adoption_summary.rds")

# ---- Table 1: Summary Statistics ----
cat("Generating Table 1: Summary Statistics\n")

# Balance the panel for consistent stats
all_rr <- unique(panel$railroad)
all_years <- min(panel$year):max(panel$year)
full_grid <- expand.grid(railroad = all_rr, year = all_years, stringsAsFactors = FALSE)
rr_info <- panel %>% distinct(railroad, first_treat, railroad_id)

balanced <- full_grid %>%
  left_join(panel %>% select(-first_treat, -railroad_id), by = c("railroad", "year")) %>%
  left_join(rr_info, by = "railroad") %>%
  mutate(across(c(total_accidents, human_factor_accidents, non_human_accidents,
                  track_accidents, equipment_accidents, signal_accidents,
                  total_killed, total_injured, total_damage),
                ~replace_na(., 0)),
         first_treat = as.double(first_treat),
         ever_ptc = ifelse(first_treat > 0, "PTC Railroads", "Never-PTC Railroads"))

summary_stats <- balanced %>%
  group_by(ever_ptc) %>%
  summarise(
    `N (railroad-years)` = n(),
    `Railroads` = n_distinct(railroad),
    `Total Accidents` = sprintf("%.1f (%.1f)", mean(total_accidents), sd(total_accidents)),
    `Human-Factor Accidents` = sprintf("%.1f (%.1f)", mean(human_factor_accidents), sd(human_factor_accidents)),
    `Non-Human Accidents` = sprintf("%.1f (%.1f)", mean(non_human_accidents), sd(non_human_accidents)),
    `Persons Killed` = sprintf("%.2f (%.2f)", mean(total_killed), sd(total_killed)),
    `Persons Injured` = sprintf("%.1f (%.1f)", mean(total_injured), sd(total_injured)),
    `Damage Cost (\\$)` = sprintf("%.0f (%.0f)", mean(total_damage), sd(total_damage)),
    .groups = "drop"
  )

tab1_tex <- "\\begin{table}[!t]
\\centering
\\caption{Summary Statistics: Railroad-Year Panel, 2000--2025}
\\label{tab:summary}
\\small
\\begin{tabular}{lcc}
\\toprule
& PTC Railroads & Never-PTC Railroads \\\\
\\midrule
Railroads & 49 & 114 \\\\
Railroad-Years & "

# Extract values
ptc_row <- summary_stats %>% filter(ever_ptc == "PTC Railroads")
nptc_row <- summary_stats %>% filter(ever_ptc == "Never-PTC Railroads")

tab1_tex <- paste0(tab1_tex, ptc_row$`N (railroad-years)`, " & ",
                   nptc_row$`N (railroad-years)`, " \\\\
\\addlinespace
\\multicolumn{3}{l}{\\textit{Annual Means (SD)}} \\\\
\\addlinespace
Total Accidents & ", ptc_row$`Total Accidents`, " & ", nptc_row$`Total Accidents`, " \\\\
\\quad Human-Factor & ", ptc_row$`Human-Factor Accidents`, " & ", nptc_row$`Human-Factor Accidents`, " \\\\
\\quad Non-Human-Factor & ", ptc_row$`Non-Human Accidents`, " & ", nptc_row$`Non-Human Accidents`, " \\\\
Persons Killed & ", ptc_row$`Persons Killed`, " & ", nptc_row$`Persons Killed`, " \\\\
Persons Injured & ", ptc_row$`Persons Injured`, " & ", nptc_row$`Persons Injured`, " \\\\
Damage Cost (\\$1000s) & ", sprintf("%.0f (%.0f)",
  as.numeric(gsub(" .*", "", ptc_row$`Damage Cost (\\$)`))/1000,
  as.numeric(gsub(".*\\(|\\)", "", ptc_row$`Damage Cost (\\$)`))/1000), " & ",
  sprintf("%.0f (%.0f)",
  as.numeric(gsub(" .*", "", nptc_row$`Damage Cost (\\$)`))/1000,
  as.numeric(gsub(".*\\(|\\)", "", nptc_row$`Damage Cost (\\$)`))/1000), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Panel of 163 railroads observed annually from 2000 to 2025. PTC railroads are those that report Positive Train Control in FRA Form~54 adjunct signal codes at any point during the sample period. Human-factor accidents are those with FRA cause codes beginning with H (overspeed, signal violation, switch misalignment, brake handling). Standard deviations in parentheses.
\\end{tablenotes}
\\end{table}")

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  Written tables/tab1_summary.tex\n")

# ---- Table 2: Main CS DiD Results ----
cat("Generating Table 2: Main Results\n")

# Extract CS DiD aggregate ATTs
extract_cs <- function(agg_obj, name) {
  data.frame(
    outcome = name,
    att = agg_obj$overall.att,
    se = agg_obj$overall.se,
    stringsAsFactors = FALSE
  )
}

cs_table <- bind_rows(
  extract_cs(results$agg_human, "Human-Factor Accidents"),
  extract_cs(results$agg_nonhuman, "Non-Human-Factor Accidents"),
  extract_cs(results$agg_total, "Total Accidents"),
  extract_cs(results$agg_injured, "Injuries"),
  extract_cs(results$agg_killed, "Fatalities"),
  extract_cs(results$agg_damage, "Damage Cost (log)")
)

stars <- function(att, se) {
  p <- 2 * pnorm(-abs(att / se))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

# Also get TWFE estimates for comparison
twfe_names <- c("twfe_human", "twfe_nonhuman", "twfe_total",
                "twfe_injured", "twfe_killed", "twfe_damage")
twfe_ests <- sapply(twfe_names, function(n) coef(twfe_results[[n]])["post_ptc"])
twfe_ses <- sapply(twfe_names, function(n) se(twfe_results[[n]])["post_ptc"])

tab2_tex <- "\\begin{table}[!t]
\\centering
\\caption{Effect of Positive Train Control on Railroad Safety Outcomes}
\\label{tab:main}
\\small
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{Callaway-Sant'Anna} & \\multicolumn{2}{c}{TWFE} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Outcome & ATT & SE & $\\hat{\\beta}$ & SE \\\\
\\midrule
"

for (i in 1:nrow(cs_table)) {
  cs_star <- stars(cs_table$att[i], cs_table$se[i])
  twfe_star <- stars(twfe_ests[i], twfe_ses[i])

  tab2_tex <- paste0(tab2_tex,
    cs_table$outcome[i], " & ",
    sprintf("%.3f%s", cs_table$att[i], cs_star), " & ",
    sprintf("(%.3f)", cs_table$se[i]), " & ",
    sprintf("%.3f%s", twfe_ests[i], twfe_star), " & ",
    sprintf("(%.3f)", twfe_ses[i]), " \\\\\n")
}

tab2_tex <- paste0(tab2_tex, "\\midrule
Railroads & \\multicolumn{2}{c}{163} & \\multicolumn{2}{c}{163} \\\\
\\quad Treated & \\multicolumn{2}{c}{49} & \\multicolumn{2}{c}{49} \\\\
\\quad Never-treated & \\multicolumn{2}{c}{114} & \\multicolumn{2}{c}{114} \\\\
Observations & \\multicolumn{2}{c}{4,238} & \\multicolumn{2}{c}{4,238} \\\\
Railroad FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\
Year FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Callaway-Sant'Anna (2021) estimates use never-treated railroads as the control group with doubly-robust estimation. TWFE estimates use two-way fixed effects with standard errors clustered at the railroad level. Outcomes are in inverse hyperbolic sine (asinh) except Damage Cost which uses log(1+cost). The sample is a balanced panel of 163 railroads over 2000--2025. Human-factor accidents have FRA cause codes beginning with H; non-human-factor accidents serve as a placebo outcome since PTC does not address track, equipment, or environmental causes.
$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}")

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("  Written tables/tab2_main.tex\n")

# ---- Table 3: Event Study Coefficients ----
cat("Generating Table 3: Event Study\n")

es_human <- results$es_human
es_nonhuman <- results$es_nonhuman

tab3_tex <- "\\begin{table}[!t]
\\centering
\\caption{Dynamic Treatment Effects: Event Study Estimates}
\\label{tab:eventstudy}
\\small
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{Human-Factor} & \\multicolumn{2}{c}{Non-Human-Factor} \\\\
& \\multicolumn{2}{c}{(Treatment)} & \\multicolumn{2}{c}{(Placebo)} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Event Time & ATT & SE & ATT & SE \\\\
\\midrule
"

for (i in seq_along(es_human$egt)) {
  e <- es_human$egt[i]
  h_att <- es_human$att.egt[i]
  h_se <- es_human$se.egt[i]
  nh_att <- es_nonhuman$att.egt[i]
  nh_se <- es_nonhuman$se.egt[i]

  if (e == -1) {
    tab3_tex <- paste0(tab3_tex,
      sprintf("$t%+d$ & \\multicolumn{2}{c}{[Reference]} & \\multicolumn{2}{c}{[Reference]} \\\\\n", e))
  } else {
    h_star <- if (!is.na(h_se) && h_se > 0) stars(h_att, h_se) else ""
    nh_star <- if (!is.na(nh_se) && nh_se > 0) stars(nh_att, nh_se) else ""
    tab3_tex <- paste0(tab3_tex,
      sprintf("$t%+d$ & %.3f%s & (%.3f) & %.3f%s & (%.3f) \\\\\n",
              e, h_att, h_star, h_se, nh_att, nh_star, nh_se))
  }
}

tab3_tex <- paste0(tab3_tex, "\\midrule
Post-treatment ATT & ",
  sprintf("%.3f%s", es_human$overall.att, stars(es_human$overall.att, es_human$overall.se)),
  " & (", sprintf("%.3f", es_human$overall.se), ") & ",
  sprintf("%.3f%s", es_nonhuman$overall.att, stars(es_nonhuman$overall.att, es_nonhuman$overall.se)),
  " & (", sprintf("%.3f", es_nonhuman$overall.se), ") \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Dynamic ATT estimates from Callaway and Sant'Anna (2021), aggregated by event time relative to PTC adoption. Reference period is $t-1$. Human-factor accidents (H-codes) are the treatment outcome; non-human-factor accidents serve as a placebo. Simultaneous confidence bands based on 1,000 bootstrap iterations. Outcomes in asinh.
$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}")

writeLines(tab3_tex, "../tables/tab3_eventstudy.tex")
cat("  Written tables/tab3_eventstudy.tex\n")

# ---- Table 4: Robustness Checks ----
cat("Generating Table 4: Robustness\n")

# Poisson
ppml_h_coef <- coef(robustness$ppml$human)["post_ptc"]
ppml_h_se <- se(robustness$ppml$human)["post_ptc"]
ppml_i_coef <- coef(robustness$ppml$injured)["post_ptc"]
ppml_i_se <- se(robustness$ppml$injured)["post_ptc"]

# Levels
lvl_h_coef <- coef(robustness$twfe_level$human)["post_ptc"]
lvl_h_se <- se(robustness$twfe_level$human)["post_ptc"]
lvl_i_coef <- coef(robustness$twfe_level$injured)["post_ptc"]
lvl_i_se <- se(robustness$twfe_level$injured)["post_ptc"]

# Pre-2020
pre20_coef <- coef(robustness$pre2020)["post_ptc"]
pre20_se <- se(robustness$pre2020)["post_ptc"]

# Wild bootstrap p-values
boot_h_p <- if (!is.null(robustness$boot_human)) sprintf("%.3f", robustness$boot_human$p_val) else "---"
boot_i_p <- if (!is.null(robustness$boot_injured)) sprintf("%.3f", robustness$boot_injured$p_val) else "---"

tab4_tex <- paste0("\\begin{table}[!t]
\\centering
\\caption{Robustness: Alternative Specifications and Inference}
\\label{tab:robustness}
\\small
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{Human-Factor} & \\multicolumn{2}{c}{Injuries} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Specification & Estimate & SE & Estimate & SE \\\\
\\midrule
\\textit{Panel A: Functional Form} \\\\
\\quad Asinh (baseline TWFE) & ", sprintf("%.3f", coef(twfe_results$twfe_human)["post_ptc"]),
  " & (", sprintf("%.3f", se(twfe_results$twfe_human)["post_ptc"]), ") & ",
  sprintf("%.3f%s", coef(twfe_results$twfe_injured)["post_ptc"],
          stars(coef(twfe_results$twfe_injured)["post_ptc"],
                se(twfe_results$twfe_injured)["post_ptc"])),
  " & (", sprintf("%.3f", se(twfe_results$twfe_injured)["post_ptc"]), ") \\\\
\\quad Levels & ", sprintf("%.2f%s", lvl_h_coef, stars(lvl_h_coef, lvl_h_se)),
  " & (", sprintf("%.2f", lvl_h_se), ") & ",
  sprintf("%.2f%s", lvl_i_coef, stars(lvl_i_coef, lvl_i_se)),
  " & (", sprintf("%.2f", lvl_i_se), ") \\\\
\\quad Poisson PPML & ", sprintf("%.3f", ppml_h_coef),
  " & (", sprintf("%.3f", ppml_h_se), ") & ",
  sprintf("%.3f", ppml_i_coef),
  " & (", sprintf("%.3f", ppml_i_se), ") \\\\
\\addlinespace
\\textit{Panel B: Inference} \\\\
\\quad Wild cluster bootstrap $p$-value & \\multicolumn{2}{c}{", boot_h_p,
  "} & \\multicolumn{2}{c}{", boot_i_p, "} \\\\
\\addlinespace
\\textit{Panel C: Sample} \\\\
\\quad Pre-2020 cohorts only & ", sprintf("%.3f", pre20_coef),
  " & (", sprintf("%.3f", pre20_se), ") & \\multicolumn{2}{c}{---} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} All specifications include railroad and year fixed effects with standard errors clustered at the railroad level. Asinh = inverse hyperbolic sine; Levels = raw accident/injury counts; Poisson PPML = pseudo-Poisson maximum likelihood. Wild cluster bootstrap uses the Webb (2023) six-point distribution with 9,999 iterations. Pre-2020 cohorts restrict to railroads adopting PTC before 2020 (20 treated, 114 never-treated).
$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}")

writeLines(tab4_tex, "../tables/tab4_robustness.tex")
cat("  Written tables/tab4_robustness.tex\n")

# ---- Table F1: SDE Appendix (MANDATORY) ----
cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDEs using CS DiD ATTs and pre-treatment SDs
# For asinh outcomes, SDE = ATT / SD(asinh(Y))
# Pre-treatment SDs of asinh outcomes
balanced_pre <- balanced %>%
  filter(first_treat == 0 | year < first_treat) %>%
  mutate(
    asinh_human = asinh(human_factor_accidents),
    asinh_nonhuman = asinh(non_human_accidents),
    asinh_injured = asinh(total_injured),
    asinh_killed = asinh(total_killed),
    asinh_total = asinh(total_accidents),
    log_damage = log1p(total_damage)
  )

sd_asinh_human <- sd(balanced_pre$asinh_human)
sd_asinh_nonhuman <- sd(balanced_pre$asinh_nonhuman)
sd_asinh_injured <- sd(balanced_pre$asinh_injured)
sd_asinh_killed <- sd(balanced_pre$asinh_killed)
sd_asinh_total <- sd(balanced_pre$asinh_total)
sd_log_damage <- sd(balanced_pre$log_damage)

# Compute SDEs
sde_data <- data.frame(
  outcome = c("Human-Factor Accidents", "Non-Human-Factor Accidents",
              "Total Accidents", "Injuries", "Fatalities", "Damage Cost"),
  beta = c(results$agg_human$overall.att, results$agg_nonhuman$overall.att,
           results$agg_total$overall.att, results$agg_injured$overall.att,
           results$agg_killed$overall.att, results$agg_damage$overall.att),
  se_beta = c(results$agg_human$overall.se, results$agg_nonhuman$overall.se,
              results$agg_total$overall.se, results$agg_injured$overall.se,
              results$agg_killed$overall.se, results$agg_damage$overall.se),
  sd_y = c(sd_asinh_human, sd_asinh_nonhuman, sd_asinh_total,
           sd_asinh_injured, sd_asinh_killed, sd_log_damage),
  stringsAsFactors = FALSE
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Panel B: Heterogeneity — Class I vs non-Class I railroads
class1_codes <- c("BNSF", "CSX", "NS", "UP", "CN", "CP", "KCS", "CSXT")
balanced_het <- balanced %>%
  mutate(
    is_class1 = railroad %in% class1_codes,
    asinh_human = asinh(human_factor_accidents),
    post_ptc = ifelse(first_treat > 0 & year >= first_treat, 1, 0)
  )

twfe_class1 <- feols(asinh_human ~ post_ptc | railroad_id + year,
                     data = balanced_het %>% filter(is_class1),
                     cluster = ~railroad_id)
twfe_nonclass1 <- feols(asinh_human ~ post_ptc | railroad_id + year,
                        data = balanced_het %>% filter(!is_class1),
                        cluster = ~railroad_id)

sd_class1 <- sd(balanced_het$asinh_human[balanced_het$is_class1 &
                (balanced_het$first_treat == 0 | balanced_het$year < balanced_het$first_treat)])
sd_nonclass1 <- sd(balanced_het$asinh_human[!balanced_het$is_class1 &
                   (balanced_het$first_treat == 0 | balanced_het$year < balanced_het$first_treat)])

het_data <- data.frame(
  outcome = c("Human-Factor (Class I)", "Human-Factor (Non-Class I)"),
  beta = c(coef(twfe_class1)["post_ptc"], coef(twfe_nonclass1)["post_ptc"]),
  se_beta = c(se(twfe_class1)["post_ptc"], se(twfe_nonclass1)["post_ptc"]),
  sd_y = c(sd_class1, sd_nonclass1),
  stringsAsFactors = FALSE
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Build SDE table
sde_notes <- paste0(
  "\\\\item \\\\textit{Notes:} ",
  "\\\\textbf{Country:} United States. ",
  "\\\\textbf{Research question:} Does federally mandated Positive Train Control technology reduce railroad accidents caused by human error? ",
  "\\\\textbf{Policy mechanism:} The Rail Safety Improvement Act of 2008 required railroads operating on Class~I main lines carrying passengers or toxic-by-inhalation materials to install PTC systems that automatically enforce speed restrictions, signal compliance, and track authority limits, removing human error from the causal chain for specific accident types. ",
  "\\\\textbf{Outcome definition:} Annual count of FRA Form~54 reportable rail equipment accidents/incidents, classified by cause code prefix (H = human factor, T = track, E = equipment, S = signal). ",
  "\\\\textbf{Treatment:} Binary; first year a railroad reports PTC presence in FRA Form~54 adjunct signal system codes. ",
  "\\\\textbf{Data:} FRA Form~54 Rail Equipment Accident/Incident Data via Socrata API, 2000--2025, railroad-by-year panel, 4,238 observations across 163 railroads. ",
  "\\\\textbf{Method:} Callaway and Sant\\\\textquotesingle Anna (2021) staggered DiD with never-treated comparison group and doubly-robust estimation; TWFE with railroad and year fixed effects, standard errors clustered at railroad level. ",
  "\\\\textbf{Sample:} Railroads with at least 10 years of accident data and 20 or more total accidents; 49 treated (PTC-adopting) and 114 never-treated railroads. ",
  "SDE $= \\\\hat{\\\\beta} / \\\\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

format_sde_row <- function(d) {
  paste0(
    d$outcome, " & ",
    sprintf("%.4f", d$beta), " & ",
    sprintf("(%.4f)", d$se_beta), " & ",
    sprintf("%.4f", d$sd_y), " & ",
    sprintf("%.4f", d$sde), " & ",
    sprintf("(%.4f)", d$se_sde), " & ",
    d$classification, " \\\\"
  )
}

tabF1_tex <- paste0("\\begin{table}[!t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\small
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
",
paste(sapply(1:nrow(sde_data), function(i) format_sde_row(sde_data[i,])), collapse = "\n"),
"
\\addlinespace
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Class~I vs.\\ Non-Class~I)}} \\\\
",
paste(sapply(1:nrow(het_data), function(i) format_sde_row(het_data[i,])), collapse = "\n"),
"
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
", sde_notes, "
\\end{tablenotes}
\\end{table}")

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("  Written tables/tabF1_sde.tex\n")

# ---- Table 5: Bacon Decomposition ----
cat("Generating Table 5: Bacon Decomposition\n")

bacon_data <- robustness$bacon
if (!is.null(bacon_data)) {
  est_col <- intersect(c("estimate", "avg_est"), names(bacon_data))

  bacon_summary <- bacon_data %>%
    group_by(type) %>%
    summarise(
      n_comparisons = n(),
      weight = sum(weight),
      avg_est = sum(weight * .data[[est_col[1]]]) / sum(weight),
      .groups = "drop"
    )

  tab5_tex <- "\\begin{table}[!t]
\\centering
\\caption{Goodman-Bacon Decomposition of TWFE Estimate}
\\label{tab:bacon}
\\small
\\begin{tabular}{lccc}
\\toprule
Comparison Type & Weight & Avg.\\ Estimate & $N$ Comparisons \\\\
\\midrule
"

  for (i in 1:nrow(bacon_summary)) {
    tab5_tex <- paste0(tab5_tex,
      bacon_summary$type[i], " & ",
      sprintf("%.3f", bacon_summary$weight[i]), " & ",
      sprintf("%.4f", bacon_summary$avg_est[i]), " & ",
      bacon_summary$n_comparisons[i], " \\\\\n")
  }

  tab5_tex <- paste0(tab5_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Goodman-Bacon (2021) decomposition of the TWFE DiD estimate for asinh(human-factor accidents). Each row shows a comparison type, its weight in the overall TWFE estimate, the weighted average 2$\\times$2 DiD estimate, and the number of 2$\\times$2 comparisons. Treated vs.\\ Untreated comparisons receive 86.5\\% of the weight, indicating the TWFE estimate is primarily identified from variation between PTC-adopting and never-PTC railroads.
\\end{tablenotes}
\\end{table}")

  writeLines(tab5_tex, "../tables/tab5_bacon.tex")
  cat("  Written tables/tab5_bacon.tex\n")
}

cat("\nAll tables generated successfully.\n")
