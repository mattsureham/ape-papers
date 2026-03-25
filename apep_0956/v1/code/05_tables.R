# 05_tables.R — Generate all LaTeX tables
# APEP Paper apep_0956: Rockets and Feathers in Food Taxation

source("00_packages.R")

dk_panel <- readRDS("../data/dk_panel_agg.rds")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
summary_stats <- readRDS("../data/summary_stats.rds")
period_stats <- readRDS("../data/period_stats.rds")

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics\n")

# By-period means for key products
tab1_data <- period_stats %>%
  filter(product_name %in% c("Butter/Oils", "Cheese", "Meat", "Fish", "Bread/Cereals")) %>%
  mutate(
    period_short = case_when(
      grepl("Pre-tax", period) ~ "Pre-tax",
      grepl("Tax period", period) ~ "Tax period",
      grepl("Post-abolition", period) ~ "Post-abolition"
    ),
    period_order = case_when(
      period_short == "Pre-tax" ~ 1,
      period_short == "Tax period" ~ 2,
      period_short == "Post-abolition" ~ 3
    )
  ) %>%
  arrange(product_name, period_order) %>%
  select(product_name, treated, period_short, mean_cpi, sd_cpi)

# Compute changes
change_data <- tab1_data %>%
  group_by(product_name) %>%
  summarise(
    pretax_mean = mean_cpi[period_short == "Pre-tax"],
    tax_mean = mean_cpi[period_short == "Tax period"],
    post_mean = mean_cpi[period_short == "Post-abolition"],
    pretax_sd = sd_cpi[period_short == "Pre-tax"],
    intro_change_pct = (tax_mean / pretax_mean - 1) * 100,
    abolish_change_pct = (post_mean / tax_mean - 1) * 100,
    treated = first(treated),
    .groups = "drop"
  ) %>%
  arrange(desc(treated), product_name)

# Generate LaTeX
tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Monthly Consumer Price Indices by Product Group}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{3}{c}{Mean CPI (2015=100)} & & \\multicolumn{2}{c}{Change (\\%)} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){6-7}\n",
  "Product Group & Pre-Tax & Tax Period & Post-Abolition & SD & Intro & Abolition \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Treated Products (Saturated Fat $> 2.3\\%$)}} \\\\\n"
)

for (i in 1:nrow(change_data)) {
  row <- change_data[i, ]
  if (i == sum(change_data$treated == 1) + 1) {
    tab1_tex <- paste0(tab1_tex,
      "\\midrule\n",
      "\\multicolumn{7}{l}{\\textit{Panel B: Control Products}} \\\\\n"
    )
  }
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %.1f & %.1f & %.1f & %.1f & %+.1f & %+.1f \\\\\n",
            row$product_name, row$pretax_mean, row$tax_mean, row$post_mean,
            row$pretax_sd, row$intro_change_pct, row$abolish_change_pct)
  )
}

n_months_pre <- n_distinct(dk_panel$date[dk_panel$date < as.Date("2011-10-01")])
n_months_tax <- n_distinct(dk_panel$date[dk_panel$date >= as.Date("2011-10-01") & dk_panel$date < as.Date("2013-01-01")])
n_months_post <- n_distinct(dk_panel$date[dk_panel$date >= as.Date("2013-01-01")])

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sprintf("\\item \\textit{Notes:} Monthly CPI data from Statistics Denmark (table PRIS6), index 2015=100. Pre-tax: January 2008--September 2011 (%d months). Tax period: October 2011--December 2012 (%d months). Post-abolition: January 2013--December 2015 (%d months). Treated products contain $>2.3\\%%$ saturated fat and were subject to the Danish fat tax (16 DKK/kg saturated fat). Change columns show percentage change in period mean relative to previous period mean.\n",
          n_months_pre, n_months_tax, n_months_post),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# =============================================================================
# Table 2: Main DiD Results
# =============================================================================
cat("Generating Table 2: Main DiD Results\n")

m1 <- results$m1
m2 <- results$m2
product_asym <- results$product_asym
at <- results$asymmetry_test

# Extract coefficients from m1
b1_intro <- coef(m1)["treated:post_intro"]
se1_intro <- se(m1)["treated:post_intro"]
b1_abolish <- coef(m1)["treated:post_abolish_ind"]
se1_abolish <- se(m1)["treated:post_abolish_ind"]

# Stars function
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

pval_m1 <- pvalue(m1)

# Extract product-specific from m2
coefs_m2 <- coef(m2)
ses_m2 <- se(m2)
pvals_m2 <- pvalue(m2)

# Build table
tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Denmark's Fat Tax on Consumer Prices}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & All Treated & Butter/Oils & Cheese & Meat \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Tax Introduction (October 2011)}} \\\\\n",
  sprintf("Treated $\\times$ Post-Introduction & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\\n",
          b1_intro, stars(pval_m1["treated:post_intro"]),
          coefs_m2["is_butter:post_intro"], stars(pvals_m2["is_butter:post_intro"]),
          coefs_m2["is_cheese:post_intro"], stars(pvals_m2["is_cheese:post_intro"]),
          coefs_m2["is_meat:post_intro"], stars(pvals_m2["is_meat:post_intro"])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se1_intro,
          ses_m2["is_butter:post_intro"],
          ses_m2["is_cheese:post_intro"],
          ses_m2["is_meat:post_intro"]),
  "[0.5em]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Tax Abolition (January 2013)}} \\\\\n",
  sprintf("Treated $\\times$ Post-Abolition & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\\n",
          b1_abolish, stars(pval_m1["treated:post_abolish_ind"]),
          coefs_m2["is_butter:post_abolish_ind"], stars(pvals_m2["is_butter:post_abolish_ind"]),
          coefs_m2["is_cheese:post_abolish_ind"], stars(pvals_m2["is_cheese:post_abolish_ind"]),
          coefs_m2["is_meat:post_abolish_ind"], stars(pvals_m2["is_meat:post_abolish_ind"])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se1_abolish,
          ses_m2["is_butter:post_abolish_ind"],
          ses_m2["is_cheese:post_abolish_ind"],
          ses_m2["is_meat:post_abolish_ind"]),
  "[0.5em]\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Asymmetry Test}} \\\\\n",
  sprintf("Net effect ($\\hat{\\beta}_1 + \\hat{\\beta}_2$) & $%.4f$ & $%.4f$ & $%.4f$ & $%.4f$ \\\\\n",
          at$net_effect,
          product_asym$net_effect[product_asym$product == "Butter/Oils"],
          product_asym$net_effect[product_asym$product == "Cheese"],
          product_asym$net_effect[product_asym$product == "Meat"]),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          at$se_net,
          product_asym$se_net[product_asym$product == "Butter/Oils"],
          product_asym$se_net[product_asym$product == "Cheese"],
          product_asym$se_net[product_asym$product == "Meat"]),
  sprintf("Reversal (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          abs(b1_abolish / b1_intro) * 100,
          product_asym$reversal_pct[product_asym$product == "Butter/Oils"],
          product_asym$reversal_pct[product_asym$product == "Cheese"],
          product_asym$reversal_pct[product_asym$product == "Meat"]),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          formatC(nrow(dk_panel), format = "d", big.mark = ","),
          formatC(nrow(dk_panel), format = "d", big.mark = ","),
          formatC(nrow(dk_panel), format = "d", big.mark = ","),
          formatC(nrow(dk_panel), format = "d", big.mark = ",")),
  "Product FE & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes \\\\\n",
  "Cluster & Product & Product & Product & Product \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable: log CPI index (2015=100). Panel A shows the effect of tax introduction (October 2011). Panel B shows the additional effect of tax abolition (January 2013). Panel C reports the net effect ($\\hat{\\beta}_1 + \\hat{\\beta}_2$), testing whether prices fully reversed upon abolition; a positive net effect indicates incomplete reversal (``rockets and feathers''). Reversal percentage $= |\\hat{\\beta}_2 / \\hat{\\beta}_1| \\times 100$; values below 100\\% indicate asymmetric pass-through. Column (1) pools all treated products; columns (2)--(4) estimate product-specific effects. Standard errors clustered at the product-group level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# =============================================================================
# Table 3: Event Study Coefficients
# =============================================================================
cat("Generating Table 3: Event Study\n")

# Introduction event study coefficients
es_intro_coefs <- data.frame(
  event_time = as.integer(gsub("treated:et", "", names(coef(results$es_intro)))),
  coef = coef(results$es_intro),
  se = se(results$es_intro),
  pval = pvalue(results$es_intro)
) %>%
  arrange(event_time) %>%
  filter(event_time >= -6 & event_time <= 6)

# Abolition event study coefficients
es_abolish_coefs <- data.frame(
  event_time = as.integer(gsub("treated:et", "", names(coef(results$es_abolish)))),
  coef = coef(results$es_abolish),
  se = se(results$es_abolish),
  pval = pvalue(results$es_abolish)
) %>%
  arrange(event_time) %>%
  filter(event_time >= -6 & event_time <= 6)

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: Month-by-Month Treatment Effects}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Tax Introduction} & \\multicolumn{2}{c}{Tax Abolition} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  "Event Month & Coefficient & SE & Coefficient & SE \\\\\n",
  "\\midrule\n"
)

for (t in -6:6) {
  intro_row <- es_intro_coefs %>% filter(event_time == t)
  abolish_row <- es_abolish_coefs %>% filter(event_time == t)

  if (t == -1) {
    tab3_tex <- paste0(tab3_tex,
      sprintf("$t = %d$ (ref.) & --- & --- & --- & --- \\\\\n", t))
  } else {
    i_coef <- if (nrow(intro_row) > 0) sprintf("$%.4f%s$", intro_row$coef, stars(intro_row$pval)) else "---"
    i_se <- if (nrow(intro_row) > 0) sprintf("(%.4f)", intro_row$se) else ""
    a_coef <- if (nrow(abolish_row) > 0) sprintf("$%.4f%s$", abolish_row$coef, stars(abolish_row$pval)) else "---"
    a_se <- if (nrow(abolish_row) > 0) sprintf("(%.4f)", abolish_row$se) else ""

    tab3_tex <- paste0(tab3_tex,
      sprintf("$t = %+d$ & %s & %s & %s & %s \\\\\n", t, i_coef, i_se, a_coef, a_se))
  }
}

tab3_tex <- paste0(tab3_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Event study estimates from $\\log(\\text{CPI}_{it}) = \\alpha_i + \\gamma_t + \\sum_k \\hat{\\beta}_k (\\text{Treated}_i \\times \\mathbf{1}[t = k]) + \\varepsilon_{it}$. Reference period: $t=-1$ (September 2011 for introduction; December 2012 for abolition). Treated products: butter/oils, cheese, meat. Control products: fish, bread/cereals, fruit, vegetables. Standard errors clustered at the product-group level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_eventstudy.tex")

# =============================================================================
# Table 4: Robustness
# =============================================================================
cat("Generating Table 4: Robustness\n")

rob_specs <- list(
  list(name = "Baseline", model = results$m1),
  list(name = "Narrow window", model = robustness$m_narrow),
  list(name = "Product trends", model = robustness$m_trends),
  list(name = "HAC(12) SEs", model = robustness$m_hac)
)

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness: Alternative Specifications}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Baseline & Narrow & Prod. Trends & HAC(12) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Introduction Effect}} \\\\\n"
)

intro_names <- c("treated:post_intro")
abolish_names <- c("treated:post_abolish_ind")

for (spec in rob_specs) {
  m <- spec$model
  coefs_r <- coef(m)
  ses_r <- se(m)
  pvals_r <- pvalue(m)

  b_i <- coefs_r[names(coefs_r) %in% intro_names][1]
  se_i <- ses_r[names(ses_r) %in% intro_names][1]
  p_i <- pvals_r[names(pvals_r) %in% intro_names][1]

  if (spec$name == rob_specs[[1]]$name) {
    tab4_tex <- paste0(tab4_tex,
      sprintf("Treated $\\times$ Post-Intro & $%.4f%s$ ", b_i, stars(p_i)))
  } else {
    tab4_tex <- paste0(tab4_tex, sprintf("& $%.4f%s$ ", b_i, stars(p_i)))
  }
}
tab4_tex <- paste0(tab4_tex, "\\\\\n")

for (spec in rob_specs) {
  m <- spec$model
  se_i <- se(m)[names(se(m)) %in% intro_names][1]
  if (spec$name == rob_specs[[1]]$name) {
    tab4_tex <- paste0(tab4_tex, sprintf(" & (%.4f) ", se_i))
  } else {
    tab4_tex <- paste0(tab4_tex, sprintf("& (%.4f) ", se_i))
  }
}
tab4_tex <- paste0(tab4_tex, "\\\\\n[0.5em]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Abolition Effect}} \\\\\n")

for (spec in rob_specs) {
  m <- spec$model
  coefs_r <- coef(m)
  pvals_r <- pvalue(m)
  b_a <- coefs_r[names(coefs_r) %in% abolish_names][1]
  p_a <- pvals_r[names(pvals_r) %in% abolish_names][1]
  if (spec$name == rob_specs[[1]]$name) {
    tab4_tex <- paste0(tab4_tex,
      sprintf("Treated $\\times$ Post-Abolish & $%.4f%s$ ", b_a, stars(p_a)))
  } else {
    tab4_tex <- paste0(tab4_tex, sprintf("& $%.4f%s$ ", b_a, stars(p_a)))
  }
}
tab4_tex <- paste0(tab4_tex, "\\\\\n")

for (spec in rob_specs) {
  m <- spec$model
  se_a <- se(m)[names(se(m)) %in% abolish_names][1]
  if (spec$name == rob_specs[[1]]$name) {
    tab4_tex <- paste0(tab4_tex, sprintf(" & (%.4f) ", se_a))
  } else {
    tab4_tex <- paste0(tab4_tex, sprintf("& (%.4f) ", se_a))
  }
}

# Net effects
tab4_tex <- paste0(tab4_tex, "\\\\\n[0.5em]\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Net Effect (Intro + Abolish)}} \\\\\n")

for (spec in rob_specs) {
  m <- spec$model
  coefs_r <- coef(m)
  vcov_r <- vcov(m)
  b_i <- coefs_r[names(coefs_r) %in% intro_names][1]
  b_a <- coefs_r[names(coefs_r) %in% abolish_names][1]
  n_intro <- names(coefs_r)[names(coefs_r) %in% intro_names][1]
  n_abolish <- names(coefs_r)[names(coefs_r) %in% abolish_names][1]
  net <- b_i + b_a
  se_n <- sqrt(vcov_r[n_intro, n_intro] + vcov_r[n_abolish, n_abolish] +
               2 * vcov_r[n_intro, n_abolish])
  p_n <- 2 * pnorm(abs(net / se_n), lower.tail = FALSE)

  if (spec$name == rob_specs[[1]]$name) {
    tab4_tex <- paste0(tab4_tex,
      sprintf("Net effect & $%.4f%s$ ", net, stars(p_n)))
  } else {
    tab4_tex <- paste0(tab4_tex, sprintf("& $%.4f%s$ ", net, stars(p_n)))
  }
}
tab4_tex <- paste0(tab4_tex, "\\\\\n")

for (spec in rob_specs) {
  m <- spec$model
  coefs_r <- coef(m)
  vcov_r <- vcov(m)
  n_intro <- names(coefs_r)[names(coefs_r) %in% intro_names][1]
  n_abolish <- names(coefs_r)[names(coefs_r) %in% abolish_names][1]
  se_n <- sqrt(vcov_r[n_intro, n_intro] + vcov_r[n_abolish, n_abolish] +
               2 * vcov_r[n_intro, n_abolish])
  if (spec$name == rob_specs[[1]]$name) {
    tab4_tex <- paste0(tab4_tex, sprintf(" & (%.4f) ", se_n))
  } else {
    tab4_tex <- paste0(tab4_tex, sprintf("& (%.4f) ", se_n))
  }
}

tab4_tex <- paste0(tab4_tex, "\\\\\n",
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          formatC(nobs(results$m1), big.mark = ","),
          formatC(nobs(robustness$m_narrow), big.mark = ","),
          formatC(nobs(robustness$m_trends), big.mark = ","),
          formatC(nobs(robustness$m_hac), big.mark = ",")),
  "Product FE & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes \\\\\n",
  "Product trends & No & No & Yes & No \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications estimate: $\\log(\\text{CPI}_{it}) = \\alpha_i + \\gamma_t + \\beta_1(\\text{Treated}_i \\times \\text{Post-Intro}_t) + \\beta_2(\\text{Treated}_i \\times \\text{Post-Abolish}_t) + \\varepsilon_{it}$. Column (1): baseline (2008M01--2015M12). Column (2): narrow window (2011M04--2013M06). Column (3): adds product-specific linear time trends. Column (4): Newey-West HAC standard errors with 12-month bandwidth instead of cluster-robust SEs. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# =============================================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Extract coefficients and compute SDEs
# Main outcome: log CPI for pooled treated products
sd_y <- sd(dk_panel$log_cpi[dk_panel$treated == 1], na.rm = TRUE)

# Panel A: Pooled — introduction effect
b_pooled_intro <- coef(results$m1)["treated:post_intro"]
se_pooled_intro <- se(results$m1)["treated:post_intro"]
sde_pooled_intro <- b_pooled_intro / sd_y
se_sde_pooled_intro <- se_pooled_intro / sd_y

# Panel A: Pooled — net effect (introduction + abolition)
b_pooled_net <- results$asymmetry_test$net_effect
se_pooled_net <- results$asymmetry_test$se_net
sde_pooled_net <- b_pooled_net / sd_y
se_sde_pooled_net <- se_pooled_net / sd_y

# Panel B: Product-specific
# Butter/Oils
sd_y_butter <- sd(dk_panel$log_cpi[dk_panel$product_code == "011500"], na.rm = TRUE)
b_butter <- results$product_asym$net_effect[results$product_asym$product == "Butter/Oils"]
se_butter <- results$product_asym$se_net[results$product_asym$product == "Butter/Oils"]
sde_butter <- b_butter / sd_y_butter
se_sde_butter <- se_butter / sd_y_butter

# Cheese
sd_y_cheese <- sd(dk_panel$log_cpi[dk_panel$product_code == "011440"], na.rm = TRUE)
b_cheese <- results$product_asym$net_effect[results$product_asym$product == "Cheese"]
se_cheese <- results$product_asym$se_net[results$product_asym$product == "Cheese"]
sde_cheese <- b_cheese / sd_y_cheese
se_sde_cheese <- se_cheese / sd_y_cheese

# Classification function
classify_sde <- function(s) {
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

# Build SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Denmark. ",
  "\\textbf{Research question:} Does a saturated-fat tax generate asymmetric price pass-through, ",
  "with prices rising at tax introduction but not fully reversing at abolition, across food product categories? ",
  "\\textbf{Policy mechanism:} The Danish fat tax imposed 16 DKK per kilogram of saturated fat on ",
  "foods exceeding a 2.3\\% saturated-fat threshold, directly raising production costs for butter, cheese, ",
  "and fatty meats; abolition removed the cost shock but may not reverse retailer price adjustments ",
  "due to menu costs or strategic margin retention. ",
  "\\textbf{Outcome definition:} Log of monthly consumer price index (CPI, base 2015=100) from Statistics Denmark ",
  "PRIS6 table, measuring retail price levels for specific COICOP food product groups. ",
  "\\textbf{Treatment:} Binary; product groups with saturated-fat content above the 2.3\\% statutory threshold. ",
  "\\textbf{Data:} Statistics Denmark PRIS6, monthly frequency, January 2008--December 2015, product-group-by-month panel, ",
  formatC(nrow(dk_panel), big.mark = ","), " observations across 7 product groups. ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with product-group and calendar-month fixed effects; ",
  "standard errors clustered at the product-group level. ",
  "\\textbf{Sample:} All food product groups in PRIS6 with consistent monthly coverage 2008--2015; ",
  "treated products defined by statutory saturated-fat threshold. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of log CPI. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\footnotesize\n",
  "\\begin{minipage}{\\textwidth}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular*}{\\textwidth}{@{\\extracolsep{\\fill}}llcccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Log CPI (treated) & Introduction & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          b_pooled_intro, se_pooled_intro, sd_y, sde_pooled_intro, se_sde_pooled_intro,
          classify_sde(sde_pooled_intro)),
  sprintf("Log CPI (treated) & Net (intro+abolish) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          b_pooled_net, se_pooled_net, sd_y, sde_pooled_net, se_sde_pooled_net,
          classify_sde(sde_pooled_net)),
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by product saturation intensity)}} \\\\\n",
  sprintf("Butter/Oils & Net effect & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          b_butter, se_butter, sd_y_butter, sde_butter, se_sde_butter,
          classify_sde(sde_butter)),
  sprintf("Cheese & Net effect & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
          b_cheese, se_cheese, sd_y_cheese, sde_cheese, se_sde_cheese,
          classify_sde(sde_cheese)),
  "\\bottomrule\n",
  "\\end{tabular*}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\scriptsize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
cat("  tab1_summary.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_eventstudy.tex\n")
cat("  tab4_robustness.tex\n")
cat("  tabF1_sde.tex\n")
