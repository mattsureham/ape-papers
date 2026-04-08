## 05_tables.R
## apep_1428: Does Financial Parity Follow Legal Parity?
## Generate all LaTeX tables

source("code/00_packages.R")

models <- readRDS("data/models.rds")
df <- readRDS("data/df_clean.rds")
df_mayor_long <- readRDS("data/df_mayor_long.rds")
robustness <- readRDS("data/robustness.rds")
state_year_gaps <- readRDS("data/state_year_gaps.rds")
desc <- readRDS("data/df_descriptives.rds")

dir.create("tables", showWarnings = FALSE)

## ── Table 1: Descriptive Statistics ───────────────────────────────────────
desc_wide <- desc %>%
  mutate(Gender = ifelse(female == 1, "Women", "Men")) %>%
  select(Year = year, Gender, N = n,
         `Party Transfers` = party_transfer_mean,
         `Sympathizer Donations` = sympathizer_mean,
         `Self-Finance` = self_finance_mean)

tab1_tex <- desc_wide %>%
  mutate(across(where(is.numeric) & !c(Year, N), ~ scales::comma(round(., 0)))) %>%
  kable(format = "latex", booktabs = TRUE,
        caption = "Descriptive Statistics: Mayoral Campaign Finance by Gender and Year",
        label = "tab1_descriptive",
        escape = FALSE) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  add_header_above(c(" " = 3, "Mean Income (MXN)" = 3)) %>%
  footnote(
    general = paste0(
      "\\\\textbf{Country:} Mexico. ",
      "\\\\textbf{Research question:} Does the 2019 Parity in Everything mandate narrow ",
      "the gender gap in party-controlled campaign transfers? ",
      "\\\\textbf{Policy mechanism:} Gender parity mandate for municipal president candidates. ",
      "\\\\textbf{Outcome definition:} Mean campaign income by source (MXN), mayoral candidates only. ",
      "\\\\textbf{Treatment:} Female candidate (SEXO = M). ",
      "\\\\textbf{Data:} INE fiscalizaci\\\\'{o}n local election income CSVs (2018, 2021). ",
      "\\\\textbf{Method:} Descriptive. ",
      "\\\\textbf{Sample:} Candidates for municipal president (presidente municipal / alcalde). "
    ),
    escape = FALSE,
    general_title = ""
  )

writeLines(tab1_tex, "tables/tab1_descriptive.tex")
cat("Wrote tables/tab1_descriptive.tex\n")

## ── Table 2: Gender Gap Summary ────────────────────────────────────────────
gap_summary <- df %>%
  filter(office_type == "MAYOR") %>%
  group_by(year, female) %>%
  summarise(
    n = n(),
    party_mean = mean(party_transfer, na.rm = TRUE),
    simpatiz_mean = mean(sympathizer, na.rm = TRUE),
    self_mean = mean(self_finance, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(Gender = ifelse(female == 1, "Women", "Men")) %>%
  pivot_wider(id_cols = year, names_from = Gender,
              values_from = c(n, party_mean, simpatiz_mean)) %>%
  mutate(
    `Party W/M ratio` = party_mean_Women / party_mean_Men,
    `Sympatiz W/M ratio` = simpatiz_mean_Women / simpatiz_mean_Men,
    `Log party gap` = log(party_mean_Men + 1) - log(party_mean_Women + 1),
    `Log simpatiz gap` = log(simpatiz_mean_Men + 1) - log(simpatiz_mean_Women + 1)
  )

tab2_tex <- gap_summary %>%
  select(Year = year,
         `Men N` = n_Men, `Women N` = n_Women,
         `Party W/M` = `Party W/M ratio`,
         `Simpatiz W/M` = `Sympatiz W/M ratio`,
         `Log Party Gap` = `Log party gap`,
         `Log Simpatiz Gap` = `Log simpatiz gap`) %>%
  mutate(across(c(`Party W/M`, `Simpatiz W/M`, `Log Party Gap`, `Log Simpatiz Gap`),
                ~ round(., 3)),
         across(c(`Men N`, `Women N`), ~ scales::comma(.))) %>%
  kable(format = "latex", booktabs = TRUE,
        caption = "Gender Gap in Campaign Finance: 2018 vs 2021",
        label = "tab2_gender_gap",
        escape = FALSE) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(
    general = paste0(
      "W/M ratio = women's mean / men's mean. ",
      "Log gap = log(men's mean + 1) - log(women's mean + 1). ",
      "DDD estimate = change in log party gap minus change in log sympathizer gap = ",
      sprintf("(%.3f - %.3f) - (%.3f - %.3f).",
              gap_summary$`Log party gap`[1],
              gap_summary$`Log party gap`[2],
              gap_summary$`Log simpatiz gap`[1],
              gap_summary$`Log simpatiz gap`[2])
    ),
    escape = FALSE,
    general_title = ""
  )

writeLines(tab2_tex, "tables/tab2_gender_gap.tex")
cat("Wrote tables/tab2_gender_gap.tex\n")

## ── Table 3: Main DDD Regression Results ──────────────────────────────────
m1 <- models$m1  # DDD: party vs sympathizer
m3 <- models$m3  # DiD: party transfers only
m4 <- models$m4  # DiD: sympathizer (placebo)
m2 <- models$m2  # DDD: party vs self-finance

modelsummary(
  list(
    "(1) DDD: Party vs Sympathizer" = m1,
    "(2) DiD: Party Transfers" = m3,
    "(3) DiD: Sympathizer" = m4,
    "(4) DDD: Party vs Self-Finance" = m2
  ),
  coef_map = c(
    "female" = "Female",
    "post" = "Post-2019",
    "is_party_source" = "Party source",
    "female:post" = "Female $\\times$ Post",
    "female:is_party_source" = "Female $\\times$ Party",
    "post:is_party_source" = "Post $\\times$ Party",
    "female:post:is_party_source" = "Female $\\times$ Post $\\times$ Party (DDD)"
  ),
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map = list(
    list(raw = "nobs", clean = "Observations", fmt = 0)
  ),
  title = "Triple-Differences Estimates: Gender Gap in Party Campaign Finance",
  notes = paste0(
    "\\begin{flushleft}\\small ",
    "Dependent variable: log(income + 1). ",
    "Standard errors clustered at state level in parentheses. ",
    "All models include party $\\times$ state fixed effects. ",
    "\\textbf{Country:} Mexico. ",
    "\\textbf{Research question:} Does the 2019 Parity in Everything mandate narrow the party-controlled funding gap? ",
    "\\textbf{Policy mechanism:} Mandatory gender parity in all elected positions (2019). ",
    "\\textbf{Outcome definition:} Log campaign income by source (MXN). ",
    "\\textbf{Treatment:} Female candidate interacted with post-2019 period. ",
    "\\textbf{Data:} INE fiscalizacion 2018 + 2021 local elections. ",
    "\\textbf{Method:} DDD (triple difference: gender $\\times$ year $\\times$ income source). ",
    "\\textbf{Sample:} Municipal president (alcalde) candidates. ",
    "\\end{flushleft}"
  ),
  output = "tables/tab3_main_ddd.tex"
)
cat("Wrote tables/tab3_main_ddd.tex\n")

## ── Table 4: State-Year Gender Gaps ────────────────────────────────────────
tab4_tex <- state_year_gaps %>%
  mutate(across(c(log_men, log_women, gender_gap), ~ round(., 2))) %>%
  arrange(state, year) %>%
  pivot_wider(id_cols = state,
              names_from = year,
              values_from = gender_gap,
              names_prefix = "Gap_") %>%
  mutate(Change = Gap_2021 - Gap_2018) %>%
  rename(State = state, `2018 Gap` = Gap_2018, `2021 Gap` = Gap_2021, `Change` = Change) %>%
  arrange(`Change`) %>%
  kable(format = "latex", booktabs = TRUE,
        caption = "State-Level Gender Gap in Party Transfers: 2018 vs 2021",
        label = "tab4_state_gaps",
        digits = 2) %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(
    general = "Gap = log(men's mean party transfer + 1) - log(women's mean party transfer + 1). Lower values indicate smaller gender gap. Sorted by change (states with largest reduction at top).",
    general_title = ""
  )

writeLines(tab4_tex, "tables/tab4_state_gaps.tex")
cat("Wrote tables/tab4_state_gaps.tex\n")

## ── Table F1: SDE Appendix (mandatory) ────────────────────────────────────
key <- models$key
m1 <- models$m1

# Compute SDE: beta / SD(outcome)
df_ddd <- df_mayor_long %>%
  filter(income_source %in% c("party_transfer", "sympathizer"))

sd_y <- sd(df_ddd$log_amount, na.rm = TRUE)

sde_rows <- tribble(
  ~Outcome, ~Beta, ~SE, ~SD_Y, ~SDE, ~SE_SDE, ~Classification,
  "Log(Party Transfer+1) — DDD",
    key$ddd_main, key$ddd_se, sd_y,
    key$ddd_main / sd_y, key$ddd_se / sd_y,
    ifelse(abs(key$ddd_main / sd_y) > 0.15, "Large",
           ifelse(abs(key$ddd_main / sd_y) > 0.05, "Moderate",
                  ifelse(abs(key$ddd_main / sd_y) > 0.005, "Small", "Null"))),
  "Log(Party Transfer+1) — DiD",
    key$did_party, key$did_party_se, sd(df_mayor_long$log_amount[df_mayor_long$income_source=="party_transfer"], na.rm=TRUE),
    key$did_party / sd(df_mayor_long$log_amount[df_mayor_long$income_source=="party_transfer"], na.rm=TRUE),
    key$did_party_se / sd(df_mayor_long$log_amount[df_mayor_long$income_source=="party_transfer"], na.rm=TRUE),
    ifelse(abs(key$did_party / sd(df_mayor_long$log_amount[df_mayor_long$income_source=="party_transfer"], na.rm=TRUE)) > 0.05, "Moderate", "Small"),
  "Log(Sympathizer+1) — Placebo",
    key$placebo_simpatiz, key$placebo_se,
    sd(df_mayor_long$log_amount[df_mayor_long$income_source=="sympathizer"], na.rm=TRUE),
    key$placebo_simpatiz / sd(df_mayor_long$log_amount[df_mayor_long$income_source=="sympathizer"], na.rm=TRUE),
    key$placebo_se / sd(df_mayor_long$log_amount[df_mayor_long$income_source=="sympathizer"], na.rm=TRUE),
    "Null (Placebo)"
)

sde_tex <- sde_rows %>%
  mutate(across(c(Beta, SE, SDE, SE_SDE), ~ round(., 4)),
         SD_Y = round(SD_Y, 3)) %>%
  kable(format = "latex", booktabs = TRUE,
        col.names = c("Outcome", "$\\hat{\\beta}$", "SE", "SD(Y)", "SDE",
                      "SE(SDE)", "Classification"),
        escape = FALSE,
        caption = "Standardized Effect Sizes",
        label = "tabF1_sde") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  pack_rows("Panel A: Main Estimates (Pooled)", 1, 2) %>%
  pack_rows("Panel B: Placebo Test", 3, 3) %>%
  footnote(
    general = paste0(
      "\\\\begin{flushleft}\\\\small ",
      "SDE = $\\\\hat{\\\\beta}$ / SD(Y). Classification refers to magnitude, not statistical significance. ",
      "Buckets: Large ($|$SDE$|$ $>$ 0.15), Moderate (0.05--0.15), Small (0.005--0.05), Null ($<$ 0.005). ",
      "\\\\textbf{Country:} Mexico. ",
      "\\\\textbf{Research question:} Does the 2019 Parity in Everything mandate narrow the ",
      "party-controlled funding gap for female mayoral candidates? ",
      "\\\\textbf{Policy mechanism:} Mandatory gender parity (Article 41 constitutional reform, 2019). ",
      "\\\\textbf{Outcome definition:} Log(campaign income + 1) from INE fiscalizaci\\\\'{o}n data. ",
      "\\\\textbf{Treatment:} Female candidate in 2021 vs 2018 (post-mandate period). ",
      "\\\\textbf{Data:} INE fiscalizaci\\\\'{o}n CSV files, local elections 2018 and 2021. ",
      "\\\\textbf{Method:} Triple difference (DDD): female $\\\\times$ year $\\\\times$ income source. ",
      "\\\\textbf{Sample:} 19,912 municipal president candidates, 23--28 Mexican states. ",
      "\\\\end{flushleft}"
    ),
    escape = FALSE,
    general_title = ""
  )

writeLines(sde_tex, "tables/tabF1_sde.tex")
cat("Wrote tables/tabF1_sde.tex\n")

cat("\nAll tables written successfully.\n")
