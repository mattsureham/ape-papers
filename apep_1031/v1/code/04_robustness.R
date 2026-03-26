# =============================================================================
# 04_robustness.R — Robustness checks
# apep_1031: Kitchen Table Capitalism
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
df_by_sex <- readRDS("../data/sex_panel.rds")
treatment <- readRDS("../data/treatment_coding.rds")
results <- readRDS("../data/main_results.rds")

robustness <- list()

add_post <- function(data) {
  data %>% mutate(post = as.numeric(first_treat > 0 & time_q >= first_treat))
}

# =============================================================================
# 1. FOOD FREEDOM ONLY (Tier 1 states — the sharpest treatment)
# =============================================================================
cat("=== Robustness: Food Freedom Acts only (Tier 1) ===\n")

tier1_states <- treatment$state_fips[treatment$tier == 1]
df_722_t1 <- df %>%
  filter(industry == "722", !is.na(log_emp)) %>%
  mutate(first_treat = ifelse(state_fips %in% tier1_states, first_treat, 0)) %>%
  add_post()

twfe_t1 <- feols(log_emp ~ post | state_fips + time_q, data = df_722_t1, cluster = ~state_fips)
robustness$tier1 <- twfe_t1
cat(sprintf("  Coef: %.4f (SE: %.4f, p: %.4f)\n",
            coef(twfe_t1)["post"], se(twfe_t1)["post"], pvalue(twfe_t1)["post"]))

# =============================================================================
# 2. WILD CLUSTER BOOTSTRAP
# =============================================================================
cat("=== Wild Cluster Bootstrap: NAICS 722 Employment ===\n")

df_722 <- df %>% filter(industry == "722", !is.na(log_emp)) %>% add_post()
twfe_main <- feols(log_emp ~ post | state_fips + time_q, data = df_722, cluster = ~state_fips)

set.seed(42)
wcb <- tryCatch({
  boottest(twfe_main, param = "post", B = 9999, clustid = ~state_fips,
           type = "webb", impose_null = TRUE)
}, error = function(e) {
  cat(sprintf("  WCB error: %s\n", e$message))
  NULL
})

if (!is.null(wcb)) {
  robustness$wcb <- wcb
  cat(sprintf("  WCB p-value: %.4f\n", wcb$p_val))
}

# =============================================================================
# 3. PRE-COVID COHORTS ONLY (treated before 2020)
# =============================================================================
cat("=== Robustness: Pre-COVID cohorts only ===\n")

df_722_precovid <- df %>%
  filter(industry == "722", !is.na(log_emp)) %>%
  mutate(first_treat = ifelse(first_treat >= 2020, 0, first_treat)) %>%
  add_post()

twfe_precovid <- feols(log_emp ~ post | state_fips + time_q, data = df_722_precovid,
                       cluster = ~state_fips)
robustness$precovid <- twfe_precovid
cat(sprintf("  Coef: %.4f (SE: %.4f, p: %.4f)\n",
            coef(twfe_precovid)["post"], se(twfe_precovid)["post"],
            pvalue(twfe_precovid)["post"]))

# =============================================================================
# 4. HETEROGENEITY: Female vs Male employment (NAICS 722)
# =============================================================================
cat("=== Heterogeneity: Female vs Male (NAICS 722) ===\n")

for (sx in c("Female", "Male")) {
  df_sx <- df_by_sex %>% filter(sex_label == sx, !is.na(log_emp)) %>% add_post()
  twfe_sx <- feols(log_emp ~ post | state_fips + time_q, data = df_sx, cluster = ~state_fips)
  robustness[[paste0("het_", tolower(sx))]] <- twfe_sx
  cat(sprintf("  %s: Coef = %.4f (SE: %.4f, p: %.4f)\n",
              sx, coef(twfe_sx)["post"], se(twfe_sx)["post"], pvalue(twfe_sx)["post"]))
}

# =============================================================================
# SAVE
# =============================================================================
saveRDS(robustness, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
