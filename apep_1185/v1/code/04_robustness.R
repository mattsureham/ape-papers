## 04_robustness.R — Robustness checks and inference
## APEP-1185: Kratom Bans and Opioid Overdose Mortality

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
models <- readRDS("../data/twfe_models.rds")

ban_info <- tibble(
  state_name = c("Wisconsin", "Indiana", "Arkansas", "Alabama", "Rhode Island"),
  ban_year   = c(2014L, 2014L, 2015L, 2016L, 2017L),
  ban_month  = c(4L, 7L, 10L, 5L, 6L)
) %>% mutate(ban_ym = ban_year * 12L + ban_month)

ban_states <- ban_info$state_name

df <- df %>%
  mutate(
    log_opioids = log(opioids_all + 1),
    log_synthetic = log(opioids_synthetic + 1),
    log_allod = log(all_drug_od + 1)
  )

# ============================================================================
# 1. Wild Cluster Bootstrap
# ============================================================================

cat("=== Wild Cluster Bootstrap ===\n")

m_boot <- feols(log_opioids ~ post_ban | state_id + ym,
                data = df, cluster = ~state_id)

boot_res <- tryCatch({
  boottest(m_boot, param = "post_ban", clustid = "state_id",
           B = 9999, type = "webb")
}, error = function(e) {
  cat("Wild cluster bootstrap error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(boot_res)) {
  cat("  Bootstrap p-value:", boot_res$p_val, "\n")
  cat("  Bootstrap CI:", boot_res$conf_int, "\n")
  saveRDS(boot_res, "../data/boot_opioid.rds")
}

# Also bootstrap all drug OD (the clean outcome)
m_boot_allod <- feols(log_allod ~ post_ban | state_id + ym,
                      data = df, cluster = ~state_id)

boot_allod <- tryCatch({
  boottest(m_boot_allod, param = "post_ban", clustid = "state_id",
           B = 9999, type = "webb")
}, error = function(e) {
  cat("Bootstrap (all drug OD) error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(boot_allod)) {
  cat("  All drug OD bootstrap p-value:", boot_allod$p_val, "\n")
  saveRDS(boot_allod, "../data/boot_allod.rds")
}

# ============================================================================
# 2. Randomization Inference
# ============================================================================

cat("\n=== Randomization Inference ===\n")

obs_coef <- coef(models$m1_opioid)["post_ban"]

set.seed(42)
n_perms <- 500
perm_coefs <- numeric(n_perms)

# Suppress fixest notes for speed
setFixest_notes(FALSE)

all_states <- unique(df$state_name)
ban_dates <- ban_info$ban_ym

for (i in 1:n_perms) {
  if (i %% 200 == 0) cat("  Permutation", i, "/", n_perms, "\n")

  fake_treated <- sample(all_states, 5)
  fake_dates <- sample(ban_dates, 5)

  df_perm <- df %>%
    mutate(
      fake_post = as.integer(
        state_name %in% fake_treated &
        ym >= fake_dates[match(state_name, fake_treated)]
      ),
      fake_post = replace_na(fake_post, 0L)
    )

  m_perm <- tryCatch(
    feols(log_opioids ~ fake_post | state_id + ym,
          data = df_perm, cluster = ~state_id),
    error = function(e) NULL
  )

  perm_coefs[i] <- if (!is.null(m_perm)) coef(m_perm)["fake_post"] else NA_real_
}

ri_pvalue <- mean(abs(perm_coefs) >= abs(obs_coef), na.rm = TRUE)

cat("  Observed:", obs_coef, "\n")
cat("  RI p-value:", ri_pvalue, "\n")
cat("  Perm dist: mean=", mean(perm_coefs, na.rm = TRUE),
    "sd=", sd(perm_coefs, na.rm = TRUE), "\n")

saveRDS(list(obs_coef = obs_coef, perm_coefs = perm_coefs, ri_pvalue = ri_pvalue),
        "../data/ri_results.rds")

# ============================================================================
# 3. Leave-One-Out
# ============================================================================

cat("\n=== Leave-One-Out ===\n")

loo_results <- list()
for (st in ban_states) {
  df_loo <- df %>% filter(state_name != st)
  m_loo <- tryCatch(
    feols(log_opioids ~ post_ban | state_id + ym,
          data = df_loo, cluster = ~state_id),
    error = function(e) NULL
  )
  if (!is.null(m_loo)) {
    loo_results[[st]] <- tibble(
      dropped = st, coef = coef(m_loo)["post_ban"], se = se(m_loo)["post_ban"]
    )
    cat("  Drop", st, ": β =", round(coef(m_loo), 4), "\n")
  } else {
    cat("  Drop", st, ": collinear (insufficient variation)\n")
  }
}

loo_df <- bind_rows(loo_results)
saveRDS(loo_df, "../data/loo_results.rds")

# ============================================================================
# 4. Neighbor states control group
# ============================================================================

cat("\n=== Neighbor States Control ===\n")

neighbors <- c(
  "Iowa", "Illinois", "Michigan",
  "Ohio", "Kentucky",
  "Missouri", "Tennessee", "Mississippi", "Texas", "Oklahoma",
  "Georgia",
  "Connecticut", "Massachusetts"
) %>% unique()

df_neighbor <- df %>%
  filter(state_name %in% c(ban_states, neighbors))

m_neighbor <- feols(log_opioids ~ post_ban | state_id + ym,
                    data = df_neighbor, cluster = ~state_id)
cat("  N states:", n_distinct(df_neighbor$state_name), "\n")
cat("  β =", round(coef(m_neighbor), 4), "SE =", round(se(m_neighbor), 4), "\n")

saveRDS(m_neighbor, "../data/m_neighbor.rds")

# ============================================================================
# 5. Difference-in-Differences-in-Differences (DDD):
#    Compare opioid vs psychostimulant differential within ban states
# ============================================================================

cat("\n=== Triple Difference (Opioid vs Stimulant) ===\n")

# Reshape to long by drug type for DDD
df_ddd <- df %>%
  select(state_name, state_id, year, month, ym, treated_state, post_ban,
         opioids_all, psychostimulants) %>%
  pivot_longer(
    cols = c(opioids_all, psychostimulants),
    names_to = "drug_type",
    values_to = "deaths"
  ) %>%
  filter(!is.na(deaths)) %>%
  mutate(
    log_deaths = log(deaths + 1),
    is_opioid = as.integer(drug_type == "opioids_all")
  )

m_ddd <- feols(log_deaths ~ post_ban * is_opioid | state_id^is_opioid + ym^is_opioid,
               data = df_ddd, cluster = ~state_id)

cat("DDD (post_ban × is_opioid):\n")
summary(m_ddd)

saveRDS(m_ddd, "../data/m_ddd.rds")

cat("\nRobustness checks complete.\n")
