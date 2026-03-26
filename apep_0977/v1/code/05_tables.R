## 05_tables.R — Generate all LaTeX tables
## apep_0977: Korea-Japan boycott trade hysteresis

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 1: Summary Statistics
## ═══════════════════════════════════════════════════════════════════════════

cat("Generating Table 1: Summary Statistics\n")

# Pre/post means by group
summ <- df |>
  mutate(
    group = case_when(
      consumer == 1 & korea == 1 ~ "Consumer, Korea",
      consumer == 1 & korea == 0 ~ "Consumer, China",
      consumer == 0 & korea == 1 ~ "Industrial, Korea",
      consumer == 0 & korea == 0 ~ "Industrial, China"
    ),
    post_label = ifelse(post == 1, "Post (Jul 2019--Dec 2023)", "Pre (Jan 2018--Jun 2019)")
  ) |>
  group_by(group, post_label) |>
  summarize(
    mean_trade_m = mean(trade_value, na.rm = TRUE) / 1e6,
    sd_trade_m   = sd(trade_value, na.rm = TRUE) / 1e6,
    n_months     = n_distinct(period),
    n_products   = n_distinct(hs2),
    n_obs        = n(),
    .groups = "drop"
  )

# Format as LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Monthly Bilateral Trade (\\$M)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Korea (Treated)} & \\multicolumn{2}{c}{China (Control)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Pre & Post & Pre & Post \\\\",
  "\\midrule"
)

for (gtype in c("Consumer", "Industrial")) {
  kr_pre <- summ |> filter(group == paste0(gtype, ", Korea"), grepl("Pre", post_label))
  kr_pst <- summ |> filter(group == paste0(gtype, ", Korea"), grepl("Post", post_label))
  cn_pre <- summ |> filter(group == paste0(gtype, ", China"), grepl("Pre", post_label))
  cn_pst <- summ |> filter(group == paste0(gtype, ", China"), grepl("Post", post_label))

  tab1_lines <- c(tab1_lines,
    sprintf("\\textit{%s goods} & & & & \\\\", gtype),
    sprintf("\\quad Mean trade (\\$M) & %.1f & %.1f & %.1f & %.1f \\\\",
            kr_pre$mean_trade_m, kr_pst$mean_trade_m,
            cn_pre$mean_trade_m, cn_pst$mean_trade_m),
    sprintf("\\quad SD & %.1f & %.1f & %.1f & %.1f \\\\",
            kr_pre$sd_trade_m, kr_pst$sd_trade_m,
            cn_pre$sd_trade_m, cn_pst$sd_trade_m),
    sprintf("\\quad Products & %d & %d & %d & %d \\\\",
            kr_pre$n_products, kr_pst$n_products,
            cn_pre$n_products, cn_pst$n_products),
    sprintf("\\quad Observations & %s & %s & %s & %s \\\\",
            formatC(kr_pre$n_obs, format = "d", big.mark = ","),
            formatC(kr_pst$n_obs, format = "d", big.mark = ","),
            formatC(cn_pre$n_obs, format = "d", big.mark = ","),
            formatC(cn_pst$n_obs, format = "d", big.mark = ","))
  )
  if (gtype == "Consumer") tab1_lines <- c(tab1_lines, "[6pt]")
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Monthly bilateral exports from Japan to Korea (treated) and China (control), HS 2-digit level, January 2018--December 2023. Consumer goods include food, beverages, apparel, vehicles, personal care, and household items. Industrial goods include chemicals, metals, machinery, and intermediate inputs. Source: UN Comtrade.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 2: Main DDD Results
## ═══════════════════════════════════════════════════════════════════════════

cat("Generating Table 2: Main DDD\n")

# Extract from models
m1 <- results$m1_ddd
m7 <- results$m7_recovery

# Build table manually for precise control
beta1 <- coef(m1)["treat_ddd"]
se1   <- se(m1)["treat_ddd"]
stars1 <- ifelse(abs(beta1/se1) > 2.576, "***",
          ifelse(abs(beta1/se1) > 1.96, "**",
          ifelse(abs(beta1/se1) > 1.645, "*", "")))

# Recovery model
coefs7 <- coef(m7)
ses7   <- se(m7)
# Find the early and late post coefficient names
early_name <- grep("early_post", names(coefs7), value = TRUE)
late_name  <- grep("late_post", names(coefs7), value = TRUE)

beta7_early <- coefs7[early_name]
se7_early   <- ses7[early_name]
beta7_late  <- coefs7[late_name]
se7_late    <- ses7[late_name]

stars_fn <- function(b, s) {
  t <- abs(b / s)
  ifelse(t > 2.576, "***", ifelse(t > 1.96, "**", ifelse(t > 1.645, "*", "")))
}

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Triple-Difference Estimates: Effect of Boycott on Japanese Exports}",
  "\\label{tab:ddd}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & Pooled & Recovery \\\\",
  "\\midrule",
  sprintf("Consumer $\\times$ Korea $\\times$ Post & %.3f%s & \\\\", beta1, stars1),
  sprintf(" & (%.3f) & \\\\[6pt]", se1),
  sprintf("Consumer $\\times$ Korea $\\times$ Early Post & & %.3f%s \\\\",
          beta7_early, stars_fn(beta7_early, se7_early)),
  sprintf(" & & (%.3f) \\\\", se7_early),
  sprintf("Consumer $\\times$ Korea $\\times$ Late Post & & %.3f%s \\\\",
          beta7_late, stars_fn(beta7_late, se7_late)),
  sprintf(" & & (%.3f) \\\\[6pt]", se7_late),
  "\\midrule",
  "Product $\\times$ Destination FE & Yes & Yes \\\\",
  "Destination $\\times$ Month FE & Yes & Yes \\\\",
  "Product $\\times$ Month FE & Yes & Yes \\\\",
  sprintf("Observations & %s & %s \\\\",
          formatC(nobs(m1), format = "d", big.mark = ","),
          formatC(nobs(m7), format = "d", big.mark = ",")),
  sprintf("R$^2$ (within) & %.3f & %.3f \\\\", fitstat(m1, "r2")$r2, fitstat(m7, "r2")$r2),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Dependent variable is log monthly bilateral trade value (USD). Consumer goods are HS 2-digit chapters classified as household-facing (food, beverages, apparel, vehicles, personal care). Korea is the treated destination; China is the control. Post = July 2019 onward. Early Post = July 2019--December 2020. Late Post = January 2021--December 2023. Standard errors clustered at the product$\\times$destination level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_ddd.tex"))

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 3: Product-Level Heterogeneity (Key Products)
## ═══════════════════════════════════════════════════════════════════════════

cat("Generating Table 3: Product-Level Heterogeneity\n")

prod_res <- results$product_did |>
  filter(!is.na(coef)) |>
  arrange(coef)

# HS2 product descriptions (manual lookup since API returned NA)
hs2_labels <- c(
  "02" = "Meat", "03" = "Fish", "04" = "Dairy/eggs", "06" = "Live plants",
  "07" = "Vegetables", "08" = "Fruits/nuts", "09" = "Coffee/tea/spices",
  "10" = "Cereals", "11" = "Milling products", "12" = "Oil seeds",
  "15" = "Fats/oils", "16" = "Prepared meat/fish", "17" = "Sugar",
  "18" = "Cocoa preparations", "19" = "Prepared cereals", "20" = "Prepared veg/fruit",
  "21" = "Misc food preparations", "22" = "Beverages", "24" = "Tobacco",
  "33" = "Cosmetics/perfumery", "34" = "Soap/washing", "42" = "Leather articles",
  "43" = "Furskins", "46" = "Straw articles", "49" = "Books/newspapers",
  "57" = "Carpets", "61" = "Knitted apparel", "62" = "Woven apparel",
  "63" = "Textile articles", "64" = "Footwear", "65" = "Headgear",
  "66" = "Umbrellas", "87" = "Vehicles", "91" = "Watches/clocks",
  "92" = "Musical instruments", "94" = "Furniture", "95" = "Toys/sports",
  "96" = "Misc manufactured", "97" = "Works of art"
)

prod_res <- prod_res |>
  mutate(desc = ifelse(is.na(desc) | desc == "NA", hs2_labels[hs2], desc))

# Select key products to display (most affected + anomalies)
key_hs2 <- c("22", "87", "33", "95", "62", "02", "94", "09", "64")
key_prod <- prod_res |> filter(hs2 %in% key_hs2) |> arrange(coef)

# If we don't have all, use top/bottom
if (nrow(key_prod) < 5) {
  key_prod <- bind_rows(
    prod_res |> head(5),
    prod_res |> tail(3)
  ) |> distinct() |> arrange(coef)
}

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Product-Level Boycott Effects: Korea $\\times$ Post (Consumer Goods)}",
  "\\label{tab:products}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llccc}",
  "\\toprule",
  "HS2 & Product & Coefficient & SE & N \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(key_prod))) {
  r <- key_prod[i, ]
  stars <- stars_fn(r$coef, r$se)
  desc_short <- str_trunc(r$desc, 35)
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %s & %.3f%s & (%.3f) & %s \\\\",
            r$hs2, desc_short, r$coef, stars, r$se,
            formatC(r$n_obs, format = "d", big.mark = ","))
  )
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each row shows the coefficient on Korea $\\times$ Post from a product-specific difference-in-differences regression. Dependent variable is log trade value. Destination and month fixed effects included. Heteroskedasticity-robust (HC1) standard errors in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_products.tex"))

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 4: Mechanism Tests — Sample Splits (Visibility + Rauch)
## ═══════════════════════════════════════════════════════════════════════════

cat("Generating Table 4: Mechanism Tests (Sample Splits)\n")

# Split-sample DDD: run the Korea × Post DD on consumer subgroups
df_cons <- df |> filter(consumer == 1)

# Visible consumer goods only
df_vis <- df_cons |> filter(visible == 1)
m_vis <- feols(log_trade ~ korea:post | pd_id + period, data = df_vis, cluster = ~pd_id)

# Private (non-visible) consumer goods only
df_priv <- df_cons |> filter(visible == 0)
m_priv <- feols(log_trade ~ korea:post | pd_id + period, data = df_priv, cluster = ~pd_id)

# Differentiated consumer goods only
df_diff <- df_cons |> filter(differentiated == 1)
m_diff <- feols(log_trade ~ korea:post | pd_id + period, data = df_diff, cluster = ~pd_id)

# Homogeneous consumer goods only
df_homog <- df_cons |> filter(differentiated == 0)
m_homog <- feols(log_trade ~ korea:post | pd_id + period, data = df_homog, cluster = ~pd_id)

# Save split results for SDE table
saveRDS(list(m_vis = m_vis, m_priv = m_priv, m_diff = m_diff, m_homog = m_homog,
             df_vis = df_vis, df_priv = df_priv),
        "../data/split_results.rds")

get_kr_post <- function(mod) {
  nm <- grep("korea.*post", names(coef(mod)), value = TRUE)[1]
  list(beta = coef(mod)[nm], se = se(mod)[nm], n = nobs(mod))
}

rv <- get_kr_post(m_vis)
rp <- get_kr_post(m_priv)
rd <- get_kr_post(m_diff)
rh <- get_kr_post(m_homog)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Mechanism Tests: Sample Splits within Consumer Goods}",
  "\\label{tab:mechanisms}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) Visible & (2) Private & (3) Differ. & (4) Homog. \\\\",
  "\\midrule",
  sprintf("Korea $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          rv$beta, stars_fn(rv$beta, rv$se),
          rp$beta, stars_fn(rp$beta, rp$se),
          rd$beta, stars_fn(rd$beta, rd$se),
          rh$beta, stars_fn(rh$beta, rh$se)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\[6pt]",
          rv$se, rp$se, rd$se, rh$se),
  "\\midrule",
  "Product $\\times$ Destination FE & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(rv$n, format = "d", big.mark = ","),
          formatC(rp$n, format = "d", big.mark = ","),
          formatC(rd$n, format = "d", big.mark = ","),
          formatC(rh$n, format = "d", big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each column runs the Korea $\\times$ Post difference-in-differences on a subsample of consumer goods. Visible: beverages, vehicles, clothing, footwear, handbags, watches, sporting goods. Private: cosmetics, food preparations, household items. Differentiated: goods classified as differentiated in Rauch (1999). Homogeneous: reference-priced or exchange-traded goods. Standard errors clustered at product$\\times$destination level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_mechanisms.tex"))

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 5: Robustness Checks
## ═══════════════════════════════════════════════════════════════════════════

cat("Generating Table 5: Robustness\n")

r1 <- robust$r1_nocovid
r2 <- robust$r2_placebo
r3 <- robust$r3_levels

# Main result for comparison
m_main <- results$m1_ddd
beta_main <- coef(m_main)["treat_ddd"]
se_main   <- se(m_main)["treat_ddd"]

beta_nocovid <- coef(r1)["treat_ddd"]
se_nocovid   <- se(r1)["treat_ddd"]

# Placebo - find the coefficient name
coefs_r2 <- coef(r2)
ses_r2   <- se(r2)
plac_name <- grep("korea.*post|post.*korea", names(coefs_r2), value = TRUE)[1]
beta_plac <- coefs_r2[plac_name]
se_plac   <- ses_r2[plac_name]

beta_levels <- coef(r3)["treat_ddd"]
se_levels   <- se(r3)["treat_ddd"]

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Baseline & No COVID & Ind.\\ Placebo & Levels \\\\",
  "\\midrule",
  sprintf("DDD Coefficient & %.3f%s & %.3f%s & %.3f%s & %.0f%s \\\\",
          beta_main, stars_fn(beta_main, se_main),
          beta_nocovid, stars_fn(beta_nocovid, se_nocovid),
          beta_plac, stars_fn(beta_plac, se_plac),
          beta_levels, stars_fn(beta_levels, se_levels)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.0f) \\\\[6pt]",
          se_main, se_nocovid, se_plac, se_levels),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs(m_main), format = "d", big.mark = ","),
          formatC(nobs(r1), format = "d", big.mark = ","),
          formatC(nobs(r2), format = "d", big.mark = ","),
          formatC(nobs(r3), format = "d", big.mark = ",")),
  sprintf("Permutation $p$-value & %.3f & & & \\\\", robust$perm_p)
)

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Column (1) reproduces the baseline DDD from Table \\ref{tab:ddd}. Column (2) excludes January 2020--June 2021 (COVID period). Column (3) runs the Korea $\\times$ Post specification on industrial goods only (placebo). Column (4) uses trade value in levels (USD) instead of logs. All columns include product$\\times$destination, destination$\\times$month, and product$\\times$month fixed effects. Standard errors clustered at the product$\\times$destination level. Permutation $p$-value from 500 random reassignments of consumer/industrial labels. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_robust.tex"))

## ═══════════════════════════════════════════════════════════════════════════
## TABLE F1: Standardized Effect Sizes (SDE) — Appendix
## ═══════════════════════════════════════════════════════════════════════════

cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SD(Y) from pre-treatment period for key outcomes
df_pre <- df |> filter(post == 0)

# Main outcome: all consumer goods
sd_y_main <- sd(df_pre$log_trade[df_pre$consumer == 1 & df_pre$korea == 1], na.rm = TRUE)

# Heterogeneity: visible vs private
sd_y_vis  <- sd(df_pre$log_trade[df_pre$visible == 1 & df_pre$korea == 1], na.rm = TRUE)
sd_y_priv <- sd(df_pre$log_trade[df_pre$visible == 0 & df_pre$consumer == 1 & df_pre$korea == 1], na.rm = TRUE)

# Main DDD coefficient
beta_pool <- coef(results$m1_ddd)["treat_ddd"]
se_pool   <- se(results$m1_ddd)["treat_ddd"]
sde_pool  <- beta_pool / sd_y_main
se_sde_pool <- se_pool / sd_y_main

# Recovery: early and late
beta_early <- coef(results$m7_recovery)[early_name]
se_early   <- se(results$m7_recovery)[early_name]
beta_late  <- coef(results$m7_recovery)[late_name]
se_late    <- se(results$m7_recovery)[late_name]
sde_early  <- beta_early / sd_y_main
sde_late   <- beta_late / sd_y_main
se_sde_early <- se_early / sd_y_main
se_sde_late  <- se_late / sd_y_main

classify_sde <- function(x) {
  if (is.na(x)) return("---")
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x < 0.005) return("Null")
  if (x < 0.05) return("Small positive")
  if (x < 0.15) return("Moderate positive")
  return("Large positive")
}

# Build Panel A (Pooled)
panel_a <- tibble(
  outcome = c("Consumer exports (pooled)",
              "Consumer exports (early post)",
              "Consumer exports (late post)"),
  beta = c(beta_pool, beta_early, beta_late),
  se   = c(se_pool, se_early, se_late),
  sd_y = c(sd_y_main, sd_y_main, sd_y_main),
  sde  = c(sde_pool, sde_early, sde_late),
  se_sde = c(se_sde_pool, se_sde_early, se_sde_late),
  classification = sapply(c(sde_pool, sde_early, sde_late), classify_sde)
)

# Panel B: Heterogeneous (visibility split — sample-split estimates)
splits <- readRDS("../data/split_results.rds")
vis_nm   <- grep("korea.*post", names(coef(splits$m_vis)), value = TRUE)[1]
priv_nm  <- grep("korea.*post", names(coef(splits$m_priv)), value = TRUE)[1]
vis_coef <- coef(splits$m_vis)[vis_nm]
vis_se_val <- se(splits$m_vis)[vis_nm]
priv_coef <- coef(splits$m_priv)[priv_nm]
priv_se_val <- se(splits$m_priv)[priv_nm]

sd_y_vis_pre  <- sd(splits$df_vis$log_trade[splits$df_vis$post == 0 & splits$df_vis$korea == 1], na.rm = TRUE)
sd_y_priv_pre <- sd(splits$df_priv$log_trade[splits$df_priv$post == 0 & splits$df_priv$korea == 1], na.rm = TRUE)

sde_vis  <- vis_coef / sd_y_vis_pre
sde_priv <- priv_coef / sd_y_priv_pre

panel_b <- tibble(
  outcome = c("Visible consumer goods", "Private consumer goods"),
  beta = c(vis_coef, priv_coef),
  se   = c(vis_se_val, priv_se_val),
  sd_y = c(sd_y_vis_pre, sd_y_priv_pre),
  sde  = c(sde_vis, sde_priv),
  se_sde = c(vis_se_val / sd_y_vis_pre, priv_se_val / sd_y_priv_pre),
  classification = sapply(c(sde_vis, sde_priv), classify_sde)
)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} South Korea (treated destination) and China (control destination); Japan as exporting country. ",
  "\\textbf{Research question:} Does the 2019 grassroots Korean consumer boycott of Japanese goods cause persistent trade diversion, and does recovery depend on product substitutability? ",
  "\\textbf{Policy mechanism:} Japan's July 2019 export controls on semiconductor materials triggered a nationwide Korean consumer boycott of Japanese products, without any government trade restriction on consumer goods; boycott participation reached 61\\% of the population. ",
  "\\textbf{Outcome definition:} Log monthly bilateral export value (USD) from Japan at HS 2-digit product level, capturing the intensive margin of trade flows. ",
  "\\textbf{Treatment:} Binary interaction --- consumer goods exported to Korea in the post-boycott period (July 2019 onward), relative to industrial goods and exports to China. ",
  "\\textbf{Data:} UN Comtrade monthly bilateral trade, HS 2-digit, January 2018--December 2023; approximately 95 product categories observed monthly across two destination countries. ",
  "\\textbf{Method:} Triple-difference (product type $\\times$ destination $\\times$ time) with product$\\times$destination, destination$\\times$month, and product$\\times$month fixed effects; standard errors clustered at product$\\times$destination level. ",
  "\\textbf{Sample:} All HS 2-digit products with positive trade flows in both pre- and post-periods; consumer classification based on BEC correspondence (food, beverages, apparel, vehicles, personal care, household items). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build LaTeX table
tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "{\\small",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\textit{Panel A: Pooled} & & & & & & \\\\"
)

for (i in seq_len(nrow(panel_a))) {
  r <- panel_a[i, ]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification)
  )
}

tabF1_lines <- c(tabF1_lines,
  "[6pt]",
  "\\textit{Panel B: Heterogeneous (visibility)} & & & & & & \\\\"
)

for (i in seq_len(nrow(panel_b))) {
  r <- panel_b[i, ]
  if (!is.na(r$beta)) {
    tabF1_lines <- c(tabF1_lines,
      sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
              r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification)
    )
  }
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\scriptsize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated in tables/ directory.\n")
list.files(tables_dir)
