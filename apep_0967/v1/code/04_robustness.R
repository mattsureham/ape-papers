# 04_robustness.R — Robustness checks and additional diagnostics
# apep_0967: CSE Reform and Far-Right Voting in France

source("00_packages.R")

data_dir <- "../data"
load(file.path(data_dir, "main_results.RData"))

# ============================================================================
# 1. EVENT STUDY FOR ALL OUTCOMES
# ============================================================================
cat("\n=== EVENT STUDY: ALL OUTCOMES ===\n")

# Le Pen event study (already run, re-confirm)
es_lepen <- feols(lepen_share ~ interact_2012 + interact_2022 |
                    code_commune + year,
                  data = panel, cluster = ~dep_code)

# Mélenchon event study
panel <- panel |>
  mutate(
    mel_interact_2012 = share_50plus_pct * as.integer(year == 2012),
    mel_interact_2022 = share_50plus_pct * as.integer(year == 2022)
  )

es_melenchon <- feols(melenchon_share ~ mel_interact_2012 + mel_interact_2022 |
                        code_commune + year,
                      data = panel |> filter(!is.na(melenchon_share)),
                      cluster = ~dep_code)
cat("Mélenchon event study:\n")
summary(es_melenchon)

# Turnout event study
es_turnout <- feols(turnout ~ interact_2012 + interact_2022 |
                      code_commune + year,
                    data = panel, cluster = ~dep_code)
cat("Turnout event study:\n")
summary(es_turnout)

# ============================================================================
# 2. PRE-TREND FALSIFICATION (2012→2017 only)
# ============================================================================
cat("\n=== PRE-TREND FALSIFICATION ===\n")

pre_panel <- panel |> filter(year %in% c(2012, 2017)) |>
  mutate(post_placebo = as.integer(year == 2017),
         treat_post_placebo = share_50plus_pct * post_placebo)

pre_lepen <- feols(lepen_share ~ treat_post_placebo | code_commune + year,
                   data = pre_panel, cluster = ~dep_code)
cat("Le Pen pre-trend (2012→2017):\n")
summary(pre_lepen)

pre_melenchon <- feols(melenchon_share ~ treat_post_placebo | code_commune + year,
                       data = pre_panel |> filter(!is.na(melenchon_share)),
                       cluster = ~dep_code)
cat("Mélenchon pre-trend (2012→2017):\n")
summary(pre_melenchon)

# ============================================================================
# 3. ALTERNATIVE CLUSTERING
# ============================================================================
cat("\n=== ALTERNATIVE CLUSTERING ===\n")

# Region-level clustering (13 regions, more conservative)
panel <- panel |>
  mutate(
    reg_code = case_when(
      dep_code %in% c("75","77","78","91","92","93","94","95") ~ "IDF",
      dep_code %in% c("08","10","51","52","54","55","57","67","68","88") ~ "GE",
      dep_code %in% c("02","59","60","62","80") ~ "HDF",
      dep_code %in% c("14","27","50","61","76") ~ "NOR",
      dep_code %in% c("22","29","35","56") ~ "BRE",
      dep_code %in% c("18","28","36","37","41","45") ~ "CVL",
      dep_code %in% c("21","25","39","58","70","71","89","90") ~ "BFC",
      dep_code %in% c("44","49","53","72","85") ~ "PDL",
      dep_code %in% c("16","17","19","23","24","33","40","47","64","79","86","87") ~ "NAQ",
      dep_code %in% c("09","11","12","30","31","32","34","46","48","65","66","81","82") ~ "OCC",
      dep_code %in% c("01","03","07","15","26","38","42","43","63","69","73","74") ~ "ARA",
      dep_code %in% c("04","05","06","13","83","84") ~ "PAC",
      dep_code %in% c("2A","2B","20") ~ "COR",
      TRUE ~ "OTHER"
    )
  )

m_reg <- feols(lepen_share ~ treat_post_pct | code_commune + year,
               data = panel, cluster = ~reg_code)
cat("Region-clustered SEs:\n")
summary(m_reg)

# Commune-level (heteroskedasticity-robust)
m_comm <- feols(lepen_share ~ treat_post_pct | code_commune + year,
                data = panel, vcov = "hetero")
cat("HC-robust SEs:\n")
summary(m_comm)

# ============================================================================
# 4. WEIGHTED REGRESSION (by registered voters)
# ============================================================================
cat("\n=== WEIGHTED REGRESSION ===\n")

m_wt <- feols(lepen_share ~ treat_post_pct | code_commune + year,
              data = panel, cluster = ~dep_code,
              weights = ~inscrits)
cat("Population-weighted:\n")
summary(m_wt)

# ============================================================================
# 5. EMPLOYMENT-WEIGHTED TREATMENT
# ============================================================================
cat("\n=== EMPLOYMENT-WEIGHTED TREATMENT ===\n")

# Instead of share of establishments, use n_50plus / n_has_employees as treatment
panel <- panel |>
  mutate(
    emp_50plus_per_1000 = ifelse(!is.na(n_50plus) & !is.na(inscrits) & inscrits > 0,
                                 n_50plus / (inscrits / 1000), 0),
    emp_treat_post = emp_50plus_per_1000 * post
  )

m_emp <- feols(lepen_share ~ emp_treat_post | code_commune + year,
               data = panel, cluster = ~dep_code)
cat("50+ firms per 1000 registered voters:\n")
summary(m_emp)

# ============================================================================
# 6. DROPPING PARIS AND LARGE CITIES
# ============================================================================
cat("\n=== EXCLUDING LARGE CITIES ===\n")

m_noparis <- feols(lepen_share ~ treat_post_pct | code_commune + year,
                   data = panel |> filter(!grepl("^75", dep_code)),
                   cluster = ~dep_code)
cat("Excluding Paris:\n")
summary(m_noparis)

m_small <- feols(lepen_share ~ treat_post_pct | code_commune + year,
                 data = panel |> filter(inscrits < 10000),
                 cluster = ~dep_code)
cat("Small communes only (inscrits < 10,000):\n")
summary(m_small)

# ============================================================================
# SAVE ALL ROBUSTNESS RESULTS
# ============================================================================
save(es_lepen, es_melenchon, es_turnout,
     pre_lepen, pre_melenchon,
     m_reg, m_comm, m_wt, m_emp, m_noparis, m_small,
     file = file.path(data_dir, "robustness_results.RData"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
