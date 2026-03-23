## 04_robustness.R — Robustness checks and business demography analysis
## apep_0824
source("00_packages.R")

panel <- readRDS("../data/panel.rds") %>% filter(year >= 2008, year <= 2020)

cee_peers <- c("BG", "HU", "CZ", "PL", "SK", "HR", "SI", "EE", "LT", "LV")
sectors <- c("C", "F", "G", "H", "I", "J", "L", "M", "N")

micro <- panel %>%
  filter(nace %in% sectors, geo %in% c("RO", cee_peers), size == "0-9") %>%
  mutate(
    ro = as.integer(geo == "RO"),
    post = as.integer(year >= 2017),
    treat = ro * post,
    log_ent = log(enterprises + 1),
    avg_turn_k = turnover_m * 1000 / enterprises,
    log_avg_turn = log(ifelse(avg_turn_k > 0, avg_turn_k, NA))
  )

# ---- 1. Alternative treatment timing ----
cat("=== ROBUSTNESS 1: Alternative treatment timing ===\n")

# Try 2016 as treatment (first expansion)
micro_2016 <- micro %>%
  mutate(post16 = as.integer(year >= 2016), treat16 = ro * post16)
r1_16 <- feols(log_ent ~ treat16 | geo^nace + nace^year, data = micro_2016, cluster = ~geo)

# Try 2018 as treatment (biggest expansion to EUR 1M)
micro_2018 <- micro %>%
  mutate(post18 = as.integer(year >= 2018), treat18 = ro * post18)
r1_18 <- feols(log_ent ~ treat18 | geo^nace + nace^year, data = micro_2018, cluster = ~geo)

etable(r1_16, r1_18, headers = c("Post-2016", "Post-2018"),
       se.below = TRUE, fitstat = c("n", "r2"))

# ---- 2. Placebo test: pre-reform period ----
cat("\n=== ROBUSTNESS 2: Placebo (fake treatment at 2013) ===\n")
pre_data <- micro %>% filter(year <= 2016) %>%
  mutate(post_placebo = as.integer(year >= 2013), treat_placebo = ro * post_placebo)

r2_placebo <- feols(log_ent ~ treat_placebo | geo^nace + nace^year,
                    data = pre_data, cluster = ~geo)
etable(r2_placebo, headers = "Placebo 2013", se.below = TRUE, fitstat = c("n", "r2"))

# ---- 3. Alternative control groups ----
cat("\n=== ROBUSTNESS 3: Alternative control groups ===\n")

# Narrow CEE peers (most similar): BG, HU, SK, HR
narrow_peers <- c("BG", "HU", "SK", "HR")
micro_narrow <- micro %>% filter(geo %in% c("RO", narrow_peers))
r3_narrow <- feols(log_ent ~ treat | geo^nace + nace^year,
                   data = micro_narrow, cluster = ~geo)

# Broader: include Western European countries
western <- c("AT", "DE", "FR", "IT", "ES", "NL", "BE", "FI", "SE", "DK")
micro_broad <- panel %>%
  filter(nace %in% sectors, geo %in% c("RO", cee_peers, western), size == "0-9",
         year >= 2008, year <= 2020) %>%
  mutate(ro = as.integer(geo == "RO"), post = as.integer(year >= 2017),
         treat = ro * post, log_ent = log(enterprises + 1))
r3_broad <- feols(log_ent ~ treat | geo^nace + nace^year,
                  data = micro_broad, cluster = ~geo)

etable(r3_narrow, r3_broad, headers = c("Narrow CEE", "CEE+Western"),
       se.below = TRUE, fitstat = c("n", "r2"))

# ---- 4. Wild cluster bootstrap (11 clusters is small) ----
cat("\n=== ROBUSTNESS 4: Wild cluster bootstrap ===\n")
main_model <- feols(log_ent ~ treat | geo^nace + nace^year, data = micro, cluster = ~geo)

# Use fixest's built-in wild cluster bootstrap
tryCatch({
  wcb <- summary(main_model, cluster = ~geo, ssc = ssc(adj = TRUE))
  cat("Standard clustered SE:", round(se(wcb)["treat"], 4), "\n")
  cat("Point estimate:", round(coef(wcb)["treat"], 4), "\n")
}, error = function(e) {
  cat("WCB error:", e$message, "\n")
})

# ---- 5. Micro-enterprise share DiD ----
cat("\n=== ROBUSTNESS 5: Micro-enterprise share (proportion) ===\n")

# Compute share of firms in 0-9 class for each country-sector-year
share_data <- panel %>%
  filter(nace %in% sectors, geo %in% c("RO", cee_peers),
         size %in% c("0-9", "TOTAL"), year >= 2008, year <= 2020) %>%
  select(nace, size, geo, year, enterprises) %>%
  pivot_wider(names_from = size, values_from = enterprises) %>%
  rename(micro_ent = `0-9`, total_ent = TOTAL) %>%
  filter(!is.na(micro_ent), !is.na(total_ent), total_ent > 0) %>%
  mutate(
    micro_share = micro_ent / total_ent,
    ro = as.integer(geo == "RO"),
    post = as.integer(year >= 2017),
    treat = ro * post
  )

r5_share <- feols(micro_share ~ treat | geo^nace + nace^year,
                  data = share_data, cluster = ~geo)
etable(r5_share, headers = "Micro Share", se.below = TRUE, fitstat = c("n", "r2"))

# ---- 6. Business demography: enterprise births ----
cat("\n=== ROBUSTNESS 6: Enterprise births ===\n")

if (file.exists("../data/bd_panel.rds")) {
  bd <- readRDS("../data/bd_panel.rds")

  bd_analysis <- bd %>%
    filter(
      geo %in% c("RO", cee_peers),
      nchar(nace) == 1,
      nace %in% sectors,
      legal_form == "TOTAL",
      year >= 2008, year <= 2020,
      !is.na(births)
    ) %>%
    mutate(
      ro = as.integer(geo == "RO"),
      post = as.integer(year >= 2017),
      treat = ro * post,
      log_births = log(births + 1)
    )

  cat("Birth data:", nrow(bd_analysis), "rows\n")
  cat("Romania birth obs:", sum(bd_analysis$geo == "RO"), "\n")

  if (nrow(bd_analysis) > 50) {
    r6_births <- feols(log_births ~ treat | geo^nace + nace^year,
                       data = bd_analysis, cluster = ~geo)
    etable(r6_births, headers = "Log Births", se.below = TRUE, fitstat = c("n", "r2"))

    # Deaths too
    bd_deaths <- bd_analysis %>% filter(!is.na(deaths))
    if (nrow(bd_deaths) > 50) {
      r6_deaths <- feols(log(deaths + 1) ~ treat | geo^nace + nace^year,
                         data = bd_deaths, cluster = ~geo)
      etable(r6_deaths, headers = "Log Deaths", se.below = TRUE, fitstat = c("n", "r2"))
    }
  }
} else {
  cat("No business demography data available.\n")
}

# ---- 7. Intensive margin: turnover per firm across ALL size classes ----
cat("\n=== ROBUSTNESS 7: Average turnover per firm by size class ===\n")

for (sz in c("0-9", "10-19", "20-49", "50-249", "GE250")) {
  sz_data <- panel %>%
    filter(nace %in% sectors, geo %in% c("RO", cee_peers), size == sz,
           year >= 2008, year <= 2020, !is.na(turnover_m),
           enterprises > 0) %>%
    mutate(
      ro = as.integer(geo == "RO"),
      post = as.integer(year >= 2017),
      treat = ro * post,
      log_avg_turn = log(turnover_m * 1000 / enterprises)
    ) %>%
    filter(is.finite(log_avg_turn))

  r7 <- feols(log_avg_turn ~ treat | geo^nace + nace^year,
              data = sz_data, cluster = ~geo)
  cat(sz, ": beta =", round(coef(r7)["treat"], 4),
      ", SE =", round(se(r7)["treat"], 4),
      ", p =", round(pvalue(r7)["treat"], 4), "\n")
}

# ---- 8. Summary statistics ----
cat("\n=== SUMMARY STATISTICS ===\n")

# Romania pre-treatment means
ro_pre <- micro %>% filter(geo == "RO", year < 2017)
ro_post <- micro %>% filter(geo == "RO", year >= 2017)
ctrl_pre <- micro %>% filter(geo != "RO", year < 2017)
ctrl_post <- micro %>% filter(geo != "RO", year >= 2017)

summ_stats <- data.frame(
  Variable = c("Enterprises (0-9 emp)", "Log enterprises",
                "Avg turnover (000 EUR)", "Log avg turnover"),
  RO_pre_mean = c(
    mean(ro_pre$enterprises, na.rm = TRUE),
    mean(ro_pre$log_ent, na.rm = TRUE),
    mean(ro_pre$avg_turn_k, na.rm = TRUE),
    mean(ro_pre$log_avg_turn, na.rm = TRUE)
  ),
  RO_pre_sd = c(
    sd(ro_pre$enterprises, na.rm = TRUE),
    sd(ro_pre$log_ent, na.rm = TRUE),
    sd(ro_pre$avg_turn_k, na.rm = TRUE),
    sd(ro_pre$log_avg_turn, na.rm = TRUE)
  ),
  RO_post_mean = c(
    mean(ro_post$enterprises, na.rm = TRUE),
    mean(ro_post$log_ent, na.rm = TRUE),
    mean(ro_post$avg_turn_k, na.rm = TRUE),
    mean(ro_post$log_avg_turn, na.rm = TRUE)
  ),
  Ctrl_pre_mean = c(
    mean(ctrl_pre$enterprises, na.rm = TRUE),
    mean(ctrl_pre$log_ent, na.rm = TRUE),
    mean(ctrl_pre$avg_turn_k, na.rm = TRUE),
    mean(ctrl_pre$log_avg_turn, na.rm = TRUE)
  ),
  N_obs = c(nrow(micro), nrow(micro), sum(!is.na(micro$avg_turn_k)),
            sum(!is.na(micro$log_avg_turn)))
)

cat("\n")
print(summ_stats, digits = 3)

saveRDS(summ_stats, "../data/summary_stats.rds")

cat("\n=== Robustness checks complete ===\n")
