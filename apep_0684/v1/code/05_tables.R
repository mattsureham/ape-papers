## 05_tables.R — Generate all LaTeX tables
## MATS Compliance Bifurcation (apep_0684)

source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

plant_chars <- readRDS(file.path(data_dir, "plant_chars.rds"))
state_panel <- readRDS(file.path(data_dir, "state_panel.rds"))
state_retirements <- readRDS(file.path(data_dir, "state_retirements.rds"))

# Ensure deregulated variable
deregulated_states <- c("TX", "PA", "OH", "IL", "NY", "NJ", "MD", "DE", "CT", "MA",
                         "RI", "NH", "ME", "MI", "MT")
state_panel <- state_panel %>%
  mutate(
    deregulated = as.integer(state %in% deregulated_states),
    post_mats = as.integer(year >= 2015),
    mats_post = coalesce(mats_exposure, 0) * post_mats,
    mats_post_reg = mats_post * (1 - deregulated),
    mats_post_dereg = mats_post * deregulated,
    log_price = log(price_cents_kwh)
  )

# Recreate plant_reg for model estimation (models reference data by name)
plant_reg <- plant_chars %>%
  filter(!is.na(heat_rate), heat_rate > 0, !is.na(capacity_mw)) %>%
  mutate(
    log_heat_rate = log(heat_rate),
    log_capacity = log(capacity_mw + 1),
    log_gen_2010 = log(gen_2010 + 1)
  )

# Re-run models so they reference current environment data
m1_plant <- feols(retired ~ log_heat_rate, data = plant_reg, vcov = "hetero")
m2_plant <- feols(retired ~ log_heat_rate + log_capacity, data = plant_reg, vcov = "hetero")
m3_plant <- feols(retired ~ log_heat_rate + log_capacity + log_gen_2010,
                  data = plant_reg, vcov = "hetero")
m4_plant <- feols(retired ~ log_heat_rate + log_capacity + log_gen_2010 | state,
                  data = plant_reg)

m1_did <- feols(log_price ~ mats_post | state + year, data = state_panel, cluster = ~state)
m_mechanism <- feols(log_price ~ mats_post_reg + mats_post_dereg | state + year,
                     data = state_panel, cluster = ~state)
m_reg_only <- feols(log_price ~ mats_post | state + year,
                    data = state_panel %>% filter(deregulated == 0), cluster = ~state)
m_dereg_only <- feols(log_price ~ mats_post | state + year,
                      data = state_panel %>% filter(deregulated == 1), cluster = ~state)

# Sector-specific models
eia_prices <- readRDS(file.path(data_dir, "eia_retail_prices.rds"))
sector_panel <- eia_prices %>%
  filter(!is.na(state_id), nchar(state_id) == 2, sector %in% c("RES", "COM", "IND"),
         year >= 2005, year <= 2022) %>%
  rename(state = state_id) %>%
  left_join(state_retirements %>% select(state, mats_exposure = capacity_retired_share),
            by = "state") %>%
  filter(!is.na(mats_exposure)) %>%
  mutate(post_mats = as.integer(year >= 2015),
         mats_post = mats_exposure * post_mats,
         log_price = log(price_cents_kwh))

m_res <- feols(log_price ~ mats_post | state + year,
               data = sector_panel %>% filter(sector == "RES"), cluster = ~state)
m_com <- feols(log_price ~ mats_post | state + year,
               data = sector_panel %>% filter(sector == "COM"), cluster = ~state)
m_ind <- feols(log_price ~ mats_post | state + year,
               data = sector_panel %>% filter(sector == "IND"), cluster = ~state)

# Coal generation model
coal_panel <- readRDS(file.path(data_dir, "coal_plant_year.rds")) %>%
  group_by(year, state) %>%
  summarise(coal_gen_mwh = sum(generation_mwh, na.rm = TRUE), .groups = "drop") %>%
  filter(year >= 2005, year <= 2022) %>%
  left_join(state_retirements %>% select(state, mats_exposure = capacity_retired_share),
            by = "state") %>%
  filter(!is.na(mats_exposure)) %>%
  mutate(post_mats = as.integer(year >= 2015),
         mats_post = mats_exposure * post_mats,
         log_coal_gen = log(coal_gen_mwh + 1)) %>%
  filter(!is.nan(log_coal_gen))

m_coal <- feols(log_coal_gen ~ mats_post | state + year, data = coal_panel, cluster = ~state)

# Robustness models
state_panel <- state_panel %>%
  mutate(
    mats_post_2013 = mats_exposure * as.integer(year >= 2013),
    mats_post_2016 = mats_exposure * as.integer(year >= 2016)
  )
m_rob_2013 <- feols(log_price ~ mats_post_2013 | state + year, data = state_panel, cluster = ~state)
m_rob_2015 <- feols(log_price ~ mats_post | state + year, data = state_panel, cluster = ~state)
m_rob_2016 <- feols(log_price ~ mats_post_2016 | state + year, data = state_panel, cluster = ~state)

pre_mats_panel <- state_panel %>%
  filter(year >= 2005, year <= 2012) %>%
  mutate(placebo_post = as.integer(year >= 2009),
         placebo_treat = mats_exposure * placebo_post)
m_placebo <- feols(log_price ~ placebo_treat | state + year, data = pre_mats_panel, cluster = ~state)

# -----------------------------------------------------------------------
# Table 1: Summary Statistics
# -----------------------------------------------------------------------
cat("=== Table 1: Summary Statistics ===\n")

# Panel A: Plant-level
plant_stats <- plant_chars %>%
  filter(!is.na(heat_rate)) %>%
  select(heat_rate, capacity_mw, gen_2010, retired) %>%
  rename(
    `Heat Rate (MMBtu/MWh)` = heat_rate,
    `Capacity (MW)` = capacity_mw,
    `Generation 2010 (MWh)` = gen_2010,
    `Retired by 2020` = retired
  )

# Panel B: State-level
state_base <- state_panel %>%
  filter(year == 2010) %>%
  select(price_cents_kwh, mats_exposure, coal_share, n_plants_pre) %>%
  rename(
    `Electricity Price (cents/kWh)` = price_cents_kwh,
    `MATS Capacity Retired Share` = mats_exposure,
    `Coal Generation Share` = coal_share,
    `Number of Coal Plants` = n_plants_pre
  )

make_sumstat_row <- function(x, name) {
  x <- x[!is.na(x)]
  sprintf("%s & %.2f & %.2f & %.2f & %.2f & %d \\\\",
          name, mean(x), sd(x), min(x), max(x), length(x))
}

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  "Variable & Mean & SD & Min & Max & N \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Coal Plants (pre-MATS, 2010--2012)}} \\\\",
  "\\addlinespace",
  make_sumstat_row(plant_chars$heat_rate[!is.na(plant_chars$heat_rate)],
                   "Heat Rate (MMBtu/MWh)"),
  make_sumstat_row(plant_chars$capacity_mw, "Capacity (MW)"),
  make_sumstat_row(plant_chars$gen_2010[plant_chars$gen_2010 > 0],
                   "Generation 2010 (GWh)"),
  make_sumstat_row(plant_chars$retired, "Retired by 2020"),
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel B: States with Coal Plants (2010 baseline)}} \\\\",
  "\\addlinespace",
  make_sumstat_row(state_base$`Electricity Price (cents/kWh)`,
                   "Electricity Price (cents/kWh)"),
  make_sumstat_row(state_base$`MATS Capacity Retired Share`,
                   "MATS Capacity Retired Share"),
  make_sumstat_row(state_base$`Coal Generation Share`[!is.na(state_base$`Coal Generation Share`)],
                   "Coal Generation Share"),
  make_sumstat_row(state_base$`Number of Coal Plants`,
                   "Number of Coal Plants"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item Notes: Panel A reports statistics for %d coal-fired power plants active in 2010--2012. Heat rate measures thermal efficiency (higher = less efficient). Panel B reports 2010 baseline characteristics for %d states with coal plants. MATS Capacity Retired Share is the fraction of pre-MATS coal generation capacity (MW) that retired by 2020. Generation 2010 is in MWh. Coal Generation Share equals state coal generation divided by total retail electricity sales.",
          nrow(plant_chars), n_distinct(state_panel$state)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)

# Fix generation to GWh
tab1_lines <- gsub("Generation 2010 \\(GWh\\)", "Generation 2010 (MWh)", tab1_lines)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# -----------------------------------------------------------------------
# Table 2: Plant-Level Retirement Determinants
# -----------------------------------------------------------------------
cat("=== Table 2: Plant Retirement Determinants ===\n")

cm <- c(
  "log_heat_rate" = "Log Heat Rate",
  "log_capacity" = "Log Capacity (MW)",
  "log_gen_2010" = "Log Generation 2010"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(round(x), big.mark = ",")),
  list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = function(x) sprintf("%.3f", x))
)

tab2_tex <- modelsummary(
  list("(1)" = m1_plant, "(2)" = m2_plant, "(3)" = m3_plant, "(4)" = m4_plant),
  output = file.path(tables_dir, "tab2_first_stage.tex"),
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.05, "**" = 0.01, "***" = 0.001),
  title = "Plant-Level Determinants of MATS-Era Retirement",
  notes = list(
    "Dependent variable: Retired (= 1 if plant had zero coal generation in 2016--2020).",
    "Column (4) includes state fixed effects.",
    "Heteroskedasticity-robust standard errors in columns (1)--(3); state-clustered in (4).",
    sprintf("Sample: %d coal plants active in 2010--2012.", nrow(plant_chars %>% filter(!is.na(heat_rate))))
  )
)

# tab2 written directly by modelsummary

# -----------------------------------------------------------------------
# Table 3: State-Level DiD — Electricity Prices
# -----------------------------------------------------------------------
cat("=== Table 3: State DiD Results ===\n")

cm3 <- c(
  "mats_post" = "MATS Exposure $\\times$ Post",
  "mats_post_reg" = "MATS Exposure $\\times$ Post $\\times$ Regulated",
  "mats_post_dereg" = "MATS Exposure $\\times$ Post $\\times$ Deregulated"
)

gm3 <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(round(x), big.mark = ",")),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = function(x) sprintf("%.4f", x)),
  list("raw" = "FE: state", "clean" = "State FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: year", "clean" = "Year FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No"))
)

tab3_tex <- modelsummary(
  list("(1)" = m1_did, "(2)" = m_mechanism, "(3)" = m_reg_only, "(4)" = m_dereg_only),
  output = file.path(tables_dir, "tab3_main_did.tex"),
  coef_map = cm3,
  gof_map = gm3,
  stars = c("*" = 0.05, "**" = 0.01, "***" = 0.001),
  title = "Effect of MATS Coal Retirements on Electricity Prices",
  notes = list(
    "Dependent variable: Log retail electricity price (cents/kWh).",
    "MATS Exposure is the share of pre-MATS coal capacity retired by 2020.",
    "Post = 1 for years $\\geq$ 2015 (MATS compliance deadline).",
    "Column (3): regulated states only. Column (4): deregulated states only.",
    "Standard errors clustered at the state level.",
    sprintf("Panel: %d states, 2005--2022.", n_distinct(state_panel$state))
  )
)

# tab3 written directly by modelsummary

# -----------------------------------------------------------------------
# Table 4: Sector-Specific and Coal Generation Effects
# -----------------------------------------------------------------------
cat("=== Table 4: Sector and Generation Effects ===\n")

cm4 <- c("mats_post" = "MATS Exposure $\\times$ Post")

tab4_tex <- modelsummary(
  list("All Sectors" = m1_did, "Residential" = m_res,
       "Commercial" = m_com, "Industrial" = m_ind, "Coal Gen." = m_coal),
  output = file.path(tables_dir, "tab4_sectors.tex"),
  coef_map = cm4,
  gof_map = gm3,
  stars = c("*" = 0.05, "**" = 0.01, "***" = 0.001),
  title = "Sector-Specific Price Effects and Coal Generation Decline",
  notes = list(
    "Columns (1)--(4): Dependent variable is log retail electricity price by sector.",
    "Column (5): Dependent variable is log state-level coal generation (MWh).",
    "MATS Exposure defined as share of pre-MATS coal capacity retired by 2020.",
    "Standard errors clustered at the state level."
  )
)

# tab4 written directly by modelsummary

# -----------------------------------------------------------------------
# Table 5: Robustness
# -----------------------------------------------------------------------
cat("=== Table 5: Robustness ===\n")

cm5 <- c(
  "mats_post_2013" = "MATS Exp. $\\times$ Post (2013)",
  "mats_post" = "MATS Exp. $\\times$ Post",
  "mats_post_2016" = "MATS Exp. $\\times$ Post (2016)",
  "placebo_treat" = "MATS Exp. $\\times$ Placebo Post (2009)"
)

tab5_tex <- modelsummary(
  list("Post=2013" = m_rob_2013, "Post=2015" = m_rob_2015,
       "Post=2016" = m_rob_2016, "Placebo" = m_placebo),
  output = file.path(tables_dir, "tab5_robustness.tex"),
  coef_map = cm5,
  gof_map = gm3,
  stars = c("*" = 0.05, "**" = 0.01, "***" = 0.001),
  title = "Robustness: Alternative Timing and Placebo Test",
  notes = list(
    "Dependent variable: Log retail electricity price.",
    "Columns (1)--(3) vary the post-treatment cutoff year.",
    "Column (4): placebo test using only pre-MATS data (2005--2012) with fake treatment at 2009.",
    "Standard errors clustered at the state level."
  )
)

# tab5 written directly by modelsummary

# -----------------------------------------------------------------------
# SDE Table (Appendix F1) — MANDATORY
# -----------------------------------------------------------------------
cat("=== SDE Table ===\n")

# Main outcomes: electricity prices (all, regulated), coal generation
make_sde_row <- function(model, outcome_name, spec_name, data, outcome_var, treat_var = "mats_post") {
  beta <- coef(model)[treat_var]
  se_beta <- sqrt(diag(vcov(model)))[treat_var]
  sd_y <- sd(data[[outcome_var]], na.rm = TRUE)
  # Treatment is continuous — compute SD(X)
  sd_x <- sd(data[[treat_var]], na.rm = TRUE)
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y

  classification <- dplyr::case_when(
    sde < -0.15  ~ "Large negative",
    sde < -0.05  ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <  0.005 ~ "Null",
    sde <  0.05  ~ "Small positive",
    sde <  0.15  ~ "Moderate positive",
    TRUE         ~ "Large positive"
  )

  sprintf("%s & %s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          outcome_name, spec_name, beta, se_beta, sd_y, sde, se_sde, classification)
}

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  make_sde_row(m1_did, "Log Price (All)", "Baseline DiD", state_panel, "log_price"),
  make_sde_row(m_reg_only, "Log Price (Regulated)", "Regulated Only",
               state_panel %>% filter(!state %in% deregulated_states), "log_price"),
  make_sde_row(m_coal, "Log Coal Generation", "Baseline DiD",
               readRDS(file.path(data_dir, "coal_plant_year.rds")) %>%
                 group_by(year, state) %>%
                 summarise(coal_gen_mwh = sum(generation_mwh, na.rm = TRUE), .groups = "drop") %>%
                 filter(year >= 2005, year <= 2022) %>%
                 left_join(readRDS(file.path(data_dir, "state_retirements.rds")) %>%
                           select(state, mats_exposure = capacity_retired_share), by = "state") %>%
                 filter(!is.na(mats_exposure)) %>%
                 mutate(post_mats = as.integer(year >= 2015),
                        mats_post = mats_exposure * post_mats,
                        log_coal_gen = log(coal_gen_mwh + 1)) %>%
                 filter(!is.nan(log_coal_gen)),
               "log_coal_gen"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE)",
  "to facilitate cross-study comparison of treatment effect magnitudes.",
  "Treatment is continuous (MATS Capacity Retired Share), so SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$.",
  "SD($Y$) is the unconditional standard deviation of the outcome.",
  "",
  "\\textbf{Research question:} How did MATS-induced coal plant retirements affect electricity prices and coal generation?",
  "\\textbf{Treatment:} Continuous; share of pre-MATS coal capacity retired by 2020 (mean = 0.19).",
  sprintf("\\textbf{Data:} EIA retail electricity prices and facility-fuel generation, 2005--2022, %d states.", n_distinct(state_panel$state)),
  "\\textbf{Method:} Continuous treatment DiD with state and year fixed effects, state-clustered standard errors.",
  sprintf("\\textbf{Sample:} %d state-year observations from %d coal states.",
          nrow(state_panel), n_distinct(state_panel$state)),
  "",
  "Classification thresholds (7 categories):",
  "large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$),",
  "small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$),",
  "small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$),",
  "large positive ($> 0.15$).",
  "Classification labels refer to the magnitude of the standardized point estimate,",
  "not to statistical significance. ``Null'' denotes a near-zero effect size",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat(sprintf("Tables written to: %s\n", tables_dir))
