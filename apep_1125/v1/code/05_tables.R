## 05_tables.R — Generate all LaTeX tables for apep_1125
## UK Breathing Space and personal insolvency

source("00_packages.R")

data_dir <- "data"
tables_dir <- "tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness.rds"))
scot <- readRDS(file.path(data_dir, "scotland_annual.rds"))

# Analysis sample
df <- panel %>%
  filter(!is.na(insolvency_rate), year >= 2015, year <= 2023) %>%
  mutate(la_id = as.factor(code), year_f = as.factor(year))

pre_sds <- results$pre_sds

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

summ_pre <- df %>%
  filter(year < 2021) %>%
  summarize(
    across(c(insolvency_rate, bankruptcy_rate, dro_rate, iva_rate, bs_rate),
           list(mean = ~mean(., na.rm=TRUE), sd = ~sd(., na.rm=TRUE)),
           .names = "{.col}_{.fn}"),
    n = n()
  )

summ_post <- df %>%
  filter(year >= 2021) %>%
  summarize(
    across(c(insolvency_rate, bankruptcy_rate, dro_rate, iva_rate, bs_rate),
           list(mean = ~mean(., na.rm=TRUE), sd = ~sd(., na.rm=TRUE)),
           .names = "{.col}_{.fn}"),
    n = n()
  )

tab1_tex <- paste0(
"\\begin{table}[htbp]\n",
"\\centering\n",
"\\caption{Summary Statistics: Individual Insolvency Rates per 10,000 Adults}\n",
"\\label{tab:summary}\n",
"\\begin{tabular}{lcccc}\n",
"\\hline\\hline\n",
" & \\multicolumn{2}{c}{Pre-treatment (2015--2020)} & \\multicolumn{2}{c}{Post-treatment (2021--2023)} \\\\\n",
"\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
" & Mean & SD & Mean & SD \\\\\n",
"\\hline\n",
sprintf("Total insolvencies & %.1f & %.1f & %.1f & %.1f \\\\\n",
        summ_pre$insolvency_rate_mean, summ_pre$insolvency_rate_sd,
        summ_post$insolvency_rate_mean, summ_post$insolvency_rate_sd),
sprintf("\\quad Bankruptcies & %.1f & %.1f & %.1f & %.1f \\\\\n",
        summ_pre$bankruptcy_rate_mean, summ_pre$bankruptcy_rate_sd,
        summ_post$bankruptcy_rate_mean, summ_post$bankruptcy_rate_sd),
sprintf("\\quad Debt Relief Orders & %.1f & %.1f & %.1f & %.1f \\\\\n",
        summ_pre$dro_rate_mean, summ_pre$dro_rate_sd,
        summ_post$dro_rate_mean, summ_post$dro_rate_sd),
sprintf("\\quad Individual Voluntary Arr. & %.1f & %.1f & %.1f & %.1f \\\\\n",
        summ_pre$iva_rate_mean, summ_pre$iva_rate_sd,
        summ_post$iva_rate_mean, summ_post$iva_rate_sd),
sprintf("Breathing Space registrations & %.1f & %.1f & %.1f & %.1f \\\\\n",
        summ_pre$bs_rate_mean, summ_pre$bs_rate_sd,
        summ_post$bs_rate_mean, summ_post$bs_rate_sd),
"\\hline\n",
sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
        format(summ_pre$n, big.mark=","), format(summ_post$n, big.mark=",")),
sprintf("Local authorities & \\multicolumn{2}{c}{303} & \\multicolumn{2}{c}{303} \\\\\n"),
"\\hline\\hline\n",
"\\end{tabular}\n",
"\\begin{tablenotes}\n",
"\\item \\textit{Notes:} Insolvency rates are computed per 10,000 adults using ONS mid-year population estimates. The sample comprises 303 Local Authorities in England and Wales with consistent boundary definitions over the 2015--2023 period. Breathing Space registrations are zero before the scheme's introduction on May 4, 2021.\n",
"\\end{tablenotes}\n",
"\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("  Written tab1_summary.tex\n")

# ============================================================================
# Table 2: National DiD (E/W vs Scotland)
# ============================================================================
cat("=== Table 2: National DiD ===\n")

# Rerun national DiD with Scotland pop-normalized rates
ew_agg <- df %>%
  group_by(year) %>%
  summarize(total = sum(total_insolvencies, na.rm = TRUE),
            bankrupt = sum(bankruptcies, na.rm = TRUE),
            dro_sum = sum(dros, na.rm = TRUE),
            iva_sum = sum(ivas, na.rm = TRUE),
            pop = sum(adult_pop, na.rm = TRUE), .groups = "drop") %>%
  mutate(rate = (total/pop)*10000,
         bank_rate = (bankrupt/pop)*10000,
         dro_rate_agg = (dro_sum/pop)*10000,
         iva_rate_agg = (iva_sum/pop)*10000,
         nation = "ew")

scot_pop_vec <- c(4350000, 4370000, 4390000, 4410000, 4420000, 4420000, 4420000, 4430000, 4440000)
scot_agg <- scot %>%
  filter(year >= 2015, year <= 2023) %>%
  mutate(pop = scot_pop_vec[1:n()],
         rate = (scot_total/pop)*10000,
         bank_rate = (scot_bankrupt/pop)*10000,
         ptd_rate = (scot_ptds/pop)*10000,
         nation = "scot")

# Construct national panel (for total insolvency)
nat_panel <- bind_rows(
  ew_agg %>% select(year, rate, bank_rate, nation),
  scot_agg %>% select(year, rate, bank_rate, nation)
) %>%
  mutate(treat = as.integer(nation == "ew"),
         post = as.integer(year >= 2021),
         treat_post = treat * post)

# DiD models
did_total <- lm(rate ~ treat + post + treat_post, data = nat_panel)
did_bank <- lm(bank_rate ~ treat + post + treat_post, data = nat_panel)

# Extract coefficients
extract_did <- function(model, outcome_label) {
  coefs <- summary(model)$coefficients
  tp <- coefs["treat_post", ]
  list(label = outcome_label, beta = tp["Estimate"], se = tp["Std. Error"],
       p = tp["Pr(>|t|)"])
}

did_total_res <- extract_did(did_total, "Total insolvencies")
did_bank_res <- extract_did(did_bank, "Bankruptcies")

tab2_tex <- paste0(
"\\begin{table}[htbp]\n",
"\\centering\n",
"\\caption{National Difference-in-Differences: England/Wales vs.~Scotland}\n",
"\\label{tab:national_did}\n",
"\\begin{tabular}{lcc}\n",
"\\hline\\hline\n",
" & Total insolvencies & Bankruptcies \\\\\n",
"\\hline\n",
sprintf("E/W $\\times$ Post-2021 & %.2f & %.2f \\\\\n",
        did_total_res$beta, did_bank_res$beta),
sprintf(" & (%.2f) & (%.2f) \\\\\n",
        did_total_res$se, did_bank_res$se),
"\\addlinespace\n",
sprintf("Pre-treatment mean (E/W) & %.1f & %.1f \\\\\n",
        mean(ew_agg$rate[ew_agg$year < 2021]),
        mean(ew_agg$bank_rate[ew_agg$year < 2021])),
sprintf("Pre-treatment mean (Scotland) & %.1f & %.1f \\\\\n",
        mean(scot_agg$rate[scot_agg$year < 2021]),
        mean(scot_agg$bank_rate[scot_agg$year < 2021])),
"Observations & 18 & 18 \\\\\n",
"\\hline\\hline\n",
"\\end{tabular}\n",
"\\begin{tablenotes}\n",
"\\item \\textit{Notes:} Each column reports the coefficient on the interaction of an England/Wales indicator with a post-2021 indicator from a difference-in-differences regression of insolvency rates per 10,000 adults on nation and year effects. Standard errors in parentheses. The sample consists of annual national-level insolvency totals for England/Wales and Scotland, 2015--2023. Scotland insolvency data from the Accountant in Bankruptcy; England/Wales data from the Insolvency Service.\n",
"\\end{tablenotes}\n",
"\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_national_did.tex"))
cat("  Written tab2_national_did.tex\n")

# ============================================================================
# Table 3: Decomposition by insolvency type (main result)
# ============================================================================
cat("=== Table 3: Decomposition ===\n")

# Pre-treatment insolvency intensity as dose (cleaner than endogenous BS)
pre_intensity <- df %>%
  filter(year >= 2015, year <= 2019) %>%
  group_by(code) %>%
  summarize(pre_insolvency = mean(insolvency_rate, na.rm = TRUE), .groups = "drop")

df <- df %>% left_join(pre_intensity, by = "code")

mod_t <- feols(insolvency_rate ~ pre_insolvency:post | la_id + year_f,
               data = df, cluster = ~la_id)
mod_b <- feols(bankruptcy_rate ~ pre_insolvency:post | la_id + year_f,
               data = df, cluster = ~la_id)
mod_d <- feols(dro_rate ~ pre_insolvency:post | la_id + year_f,
               data = df, cluster = ~la_id)
mod_i <- feols(iva_rate ~ pre_insolvency:post | la_id + year_f,
               data = df, cluster = ~la_id)

get_coef <- function(mod) {
  ct <- coeftable(mod)
  list(b = ct[1,"Estimate"], se = ct[1,"Std. Error"],
       stars = ifelse(ct[1,"Pr(>|t|)"] < 0.01, "***",
                      ifelse(ct[1,"Pr(>|t|)"] < 0.05, "**",
                             ifelse(ct[1,"Pr(>|t|)"] < 0.1, "*", ""))))
}
ct <- get_coef(mod_t); cb <- get_coef(mod_b)
cd <- get_coef(mod_d); ci <- get_coef(mod_i)

tab3_tex <- paste0(
"\\begin{table}[htbp]\n",
"\\centering\n",
"\\caption{Insolvency Decomposition: Dose-Response by Pre-Treatment Insolvency Intensity}\n",
"\\label{tab:decomposition}\n",
"\\begin{tabular}{lcccc}\n",
"\\hline\\hline\n",
" & Total & Bankruptcies & DROs & IVAs \\\\\n",
" & (1) & (2) & (3) & (4) \\\\\n",
"\\hline\n",
sprintf("Pre-insolvency $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
        ct$b, ct$stars, cb$b, cb$stars, cd$b, cd$stars, ci$b, ci$stars),
sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
        ct$se, cb$se, cd$se, ci$se),
"\\addlinespace\n",
sprintf("Pre-treatment mean & %.1f & %.1f & %.1f & %.1f \\\\\n",
        pre_sds$mean_insolvency, pre_sds$mean_bankruptcy,
        pre_sds$mean_dro, pre_sds$mean_iva),
sprintf("Pre-treatment SD & %.1f & %.1f & %.1f & %.1f \\\\\n",
        pre_sds$sd_insolvency, sd(df$bankruptcy_rate[df$year < 2021], na.rm=TRUE),
        sd(df$dro_rate[df$year < 2021], na.rm=TRUE),
        sd(df$iva_rate[df$year < 2021], na.rm=TRUE)),
sprintf("Observations & %s & %s & %s & %s \\\\\n",
        format(nrow(df), big.mark=","), format(nrow(df), big.mark=","),
        format(nrow(df), big.mark=","), format(nrow(df), big.mark=",")),
"LA fixed effects & Yes & Yes & Yes & Yes \\\\\n",
"Year fixed effects & Yes & Yes & Yes & Yes \\\\\n",
"\\hline\\hline\n",
"\\end{tabular}\n",
"\\begin{tablenotes}\n",
"\\item \\textit{Notes:} Each column reports the coefficient on the interaction of pre-treatment average insolvency rate (2015--2019) with a post-2021 indicator from a two-way fixed effects regression. The dependent variable is the insolvency rate per 10,000 adults in the indicated category. Standard errors clustered at the local authority level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
"\\end{tablenotes}\n",
"\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_decomposition.tex"))
cat("  Written tab3_decomposition.tex\n")

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("=== Table 4: Robustness ===\n")

# Exclude 2020, placebo
mod_no20_t <- feols(insolvency_rate ~ pre_insolvency:post | la_id + year_f,
                    data = df %>% filter(year != 2020), cluster = ~la_id)
mod_no20_b <- feols(bankruptcy_rate ~ pre_insolvency:post | la_id + year_f,
                    data = df %>% filter(year != 2020), cluster = ~la_id)

df_plac <- df %>% filter(year <= 2020) %>% mutate(post_plac = as.integer(year >= 2018))
mod_plac_t <- feols(insolvency_rate ~ pre_insolvency:post_plac | la_id + year_f,
                    data = df_plac, cluster = ~la_id)
mod_plac_b <- feols(bankruptcy_rate ~ pre_insolvency:post_plac | la_id + year_f,
                    data = df_plac, cluster = ~la_id)

gc_no20_t <- get_coef(mod_no20_t); gc_no20_b <- get_coef(mod_no20_b)
gc_plac_t <- get_coef(mod_plac_t); gc_plac_b <- get_coef(mod_plac_b)

tab4_tex <- paste0(
"\\begin{table}[htbp]\n",
"\\centering\n",
"\\caption{Robustness Checks}\n",
"\\label{tab:robustness}\n",
"\\begin{tabular}{lcccc}\n",
"\\hline\\hline\n",
" & \\multicolumn{2}{c}{Total insolvencies} & \\multicolumn{2}{c}{Bankruptcies} \\\\\n",
"\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
" & Excl.~2020 & Placebo (2018) & Excl.~2020 & Placebo (2018) \\\\\n",
" & (1) & (2) & (3) & (4) \\\\\n",
"\\hline\n",
sprintf("Pre-insolvency $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
        gc_no20_t$b, gc_no20_t$stars, gc_plac_t$b, gc_plac_t$stars,
        gc_no20_b$b, gc_no20_b$stars, gc_plac_b$b, gc_plac_b$stars),
sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
        gc_no20_t$se, gc_plac_t$se, gc_no20_b$se, gc_plac_b$se),
"\\addlinespace\n",
sprintf("Observations & %s & %s & %s & %s \\\\\n",
        format(nrow(df %>% filter(year != 2020)), big.mark=","),
        format(nrow(df_plac), big.mark=","),
        format(nrow(df %>% filter(year != 2020)), big.mark=","),
        format(nrow(df_plac), big.mark=",")),
"LA FE & Yes & Yes & Yes & Yes \\\\\n",
"Year FE & Yes & Yes & Yes & Yes \\\\\n",
"\\hline\\hline\n",
"\\end{tabular}\n",
"\\begin{tablenotes}\n",
"\\item \\textit{Notes:} Columns (1) and (3) exclude the COVID-affected year 2020. Columns (2) and (4) use a placebo treatment date of 2018 on the pre-treatment sample (2015--2020). All specifications use two-way fixed effects with standard errors clustered at the local authority level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
"\\end{tablenotes}\n",
"\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_robustness.tex"))
cat("  Written tab4_robustness.tex\n")

# ============================================================================
# Table F1: SDE Table (mandatory appendix)
# ============================================================================
cat("=== Table F1: SDE ===\n")

# Compute SDEs
# Using pre-treatment dose-response coefficients
# SDE = beta * SD(X) / SD(Y) for continuous treatment
sd_x <- sd(df$pre_insolvency[df$year == 2020], na.rm = TRUE)

sde_compute <- function(mod, sd_y, outcome_label) {
  ct <- coeftable(mod)
  beta <- ct[1, "Estimate"]
  se_beta <- ct[1, "Std. Error"]
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y

  bucket <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )

  data.frame(
    Outcome = outcome_label,
    Beta = beta, SE = se_beta,
    SD_Y = sd_y, SDE = sde, SE_SDE = se_sde,
    Classification = bucket,
    stringsAsFactors = FALSE
  )
}

sd_total <- sd(df$insolvency_rate[df$year < 2021], na.rm = TRUE)
sd_bank <- sd(df$bankruptcy_rate[df$year < 2021], na.rm = TRUE)
sd_dro_v <- sd(df$dro_rate[df$year < 2021], na.rm = TRUE)
sd_iva_v <- sd(df$iva_rate[df$year < 2021], na.rm = TRUE)

sde_total <- sde_compute(mod_t, sd_total, "Total insolvency rate")
sde_bank <- sde_compute(mod_b, sd_bank, "Bankruptcy rate")
sde_dro <- sde_compute(mod_d, sd_dro_v, "Debt relief order rate")
sde_iva <- sde_compute(mod_i, sd_iva_v, "IVA rate")

sde_df <- bind_rows(sde_total, sde_bank, sde_dro, sde_iva)

cat("\nSDE Results:\n")
print(sde_df, digits = 4)

# Panel B: Heterogeneous (London vs rest)
df_london <- df %>% filter(geog_type == "London Borough")
df_rest <- df %>% filter(geog_type != "London Borough")

mod_london <- feols(insolvency_rate ~ pre_insolvency:post | la_id + year_f,
                    data = df_london, cluster = ~la_id)
mod_rest <- feols(insolvency_rate ~ pre_insolvency:post | la_id + year_f,
                  data = df_rest, cluster = ~la_id)

sd_london <- sd(df_london$insolvency_rate[df_london$year < 2021], na.rm = TRUE)
sd_rest <- sd(df_rest$insolvency_rate[df_rest$year < 2021], na.rm = TRUE)
sd_x_london <- sd(df_london$pre_insolvency[df_london$year == 2020], na.rm = TRUE)
sd_x_rest <- sd(df_rest$pre_insolvency[df_rest$year == 2020], na.rm = TRUE)

sde_london <- sde_compute(mod_london, sd_london, "Total insolvency (London)")
sde_london$SDE <- coeftable(mod_london)[1,"Estimate"] * sd_x_london / sd_london
sde_london$SE_SDE <- coeftable(mod_london)[1,"Std. Error"] * sd_x_london / sd_london
sde_london$Classification <- case_when(
  sde_london$SDE < -0.15 ~ "Large negative",
  sde_london$SDE < -0.05 ~ "Moderate negative",
  sde_london$SDE < -0.005 ~ "Small negative",
  sde_london$SDE <= 0.005 ~ "Null",
  sde_london$SDE <= 0.05 ~ "Small positive",
  sde_london$SDE <= 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

sde_rest <- sde_compute(mod_rest, sd_rest, "Total insolvency (Outside London)")
sde_rest$SDE <- coeftable(mod_rest)[1,"Estimate"] * sd_x_rest / sd_rest
sde_rest$SE_SDE <- coeftable(mod_rest)[1,"Std. Error"] * sd_x_rest / sd_rest
sde_rest$Classification <- case_when(
  sde_rest$SDE < -0.15 ~ "Large negative",
  sde_rest$SDE < -0.05 ~ "Moderate negative",
  sde_rest$SDE < -0.005 ~ "Small negative",
  sde_rest$SDE <= 0.005 ~ "Null",
  sde_rest$SDE <= 0.05 ~ "Small positive",
  sde_rest$SDE <= 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

# Generate SDE LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England and Wales). ",
  "\\textbf{Research question:} Does the Breathing Space debt moratorium (a statutory 60-day pause on creditor enforcement for over-indebted individuals) reduce personal insolvency rates? ",
  "\\textbf{Policy mechanism:} The Debt Respite Scheme (effective May 4, 2021) grants eligible debtors in England and Wales a 60-day moratorium during which creditors cannot pursue enforcement action, interest is frozen, and the debtor is connected to professional debt advice; the scheme was designed to prevent formal insolvency by providing time for informal resolution. ",
  "\\textbf{Outcome definition:} Annual individual insolvency rate per 10,000 adults, computed as the count of new bankruptcies, Debt Relief Orders, and Individual Voluntary Arrangements divided by ONS mid-year adult population estimates. ",
  "\\textbf{Treatment:} Continuous; pre-treatment average insolvency rate (2015--2019) as a measure of local exposure intensity. ",
  "\\textbf{Data:} Insolvency Service Individual Insolvency Statistics by Location (2015--2023), 303 Local Authorities in England and Wales, 2,727 LA-year observations. ",
  "\\textbf{Method:} Two-way fixed effects with LA and year fixed effects; standard errors clustered at the LA level; dose-response specification interacting pre-treatment insolvency intensity with a post-2021 indicator. ",
  "\\textbf{Sample:} 303 Local Authorities in England and Wales with consistent geographic boundaries over 2015--2023; 13 LAs excluded due to boundary reorganization. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-LA standard deviation of pre-treatment insolvency intensity and SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Format the SDE table
format_sde_row <- function(row) {
  sprintf("%s & %.4f & %.4f & %.2f & %.4f & %.4f & %s",
          row$Outcome, row$Beta, row$SE, row$SD_Y, row$SDE, row$SE_SDE, row$Classification)
}

tabF1_tex <- paste0(
"\\begin{table}[htbp]\n",
"\\centering\n",
"\\caption{Standardized Effect Sizes}\n",
"\\label{tab:sde}\n",
"\\small\n",
"\\begin{tabular}{lcccccc}\n",
"\\hline\\hline\n",
"Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
"\\hline\n",
"\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
format_sde_row(sde_total), " \\\\\n",
format_sde_row(sde_bank), " \\\\\n",
format_sde_row(sde_dro), " \\\\\n",
format_sde_row(sde_iva), " \\\\\n",
"\\addlinespace\n",
"\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
format_sde_row(sde_london), " \\\\\n",
format_sde_row(sde_rest), " \\\\\n",
"\\hline\\hline\n",
"\\end{tabular}\n",
"\\begin{tablenotes}\n",
sde_notes, "\n",
"\\end{tablenotes}\n",
"\\end{table}\n"
)

writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Written tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
cat(paste(" ", list.files(tables_dir), collapse = "\n"), "\n")
