## ============================================================
## 06_tables.R — All tables for the paper
## The Cost of Sponsorship: Kafala Reform and Firm Value
## ============================================================

source(file.path(dirname(normalizePath(sys.frame(1)$ofile)), "00_packages.R"))

results <- readRDS(file.path(data_dir, "main_results.rds"))
robust  <- readRDS(file.path(data_dir, "robustness_results.rds"))
dat     <- readRDS(file.path(data_dir, "analysis_ready.rds"))
dfm     <- dat$dfm

## ===============================================================
## TABLE 1: Summary Statistics
## ===============================================================

summ_stats <- dfm %>%
  group_by(high_exposure) %>%
  summarise(
    `N Firms` = n_distinct(ticker),
    `N Obs` = n(),
    `Mean Daily Return (%)` = round(mean(ret_w, na.rm = TRUE) * 100, 3),
    `SD Daily Return (%)` = round(sd(ret_w, na.rm = TRUE) * 100, 3),
    `Mean Volume (000)` = round(mean(volume, na.rm = TRUE) / 1000, 1),
    `Median Volume (000)` = round(median(volume, na.rm = TRUE) / 1000, 1),
    .groups = "drop"
  ) %>%
  mutate(Group = ifelse(high_exposure, "High Exposure", "Low Exposure")) %>%
  select(Group, everything(), -high_exposure)

## Full sample stats
full_stats <- dfm %>%
  summarise(
    Group = "Full Sample",
    `N Firms` = n_distinct(ticker),
    `N Obs` = n(),
    `Mean Daily Return (%)` = round(mean(ret_w, na.rm = TRUE) * 100, 3),
    `SD Daily Return (%)` = round(sd(ret_w, na.rm = TRUE) * 100, 3),
    `Mean Volume (000)` = round(mean(volume, na.rm = TRUE) / 1000, 1),
    `Median Volume (000)` = round(median(volume, na.rm = TRUE) / 1000, 1)
  )

tab1 <- bind_rows(summ_stats, full_stats)

tab1_tex <- xtable(tab1, caption = "Summary Statistics: DFM Listed Firms",
                   label = "tab:summary", align = c("l", "l", rep("r", 6)))
print(tab1_tex, file = file.path(tab_dir, "tab1_summary.tex"),
      include.rownames = FALSE, floating = TRUE, booktabs = TRUE,
      sanitize.text.function = identity)
cat("Table 1 saved\n")

## ===============================================================
## TABLE 2: Firm Classification
## ===============================================================

firm_class <- dat$exposure_map %>%
  arrange(desc(high_exposure), desc(migrant_share_approx)) %>%
  mutate(
    `Exposure Group` = ifelse(high_exposure, "High", "Low"),
    `Approx. Migrant Share` = paste0(migrant_share_approx * 100, "\\%")
  ) %>%
  select(Sector = sector, `Exposure Group`, `Approx. Migrant Share`)

## Count firms per sector
firm_counts <- dfm %>%
  distinct(ticker, sector) %>%
  count(sector, name = "N Firms")

firm_class <- firm_class %>%
  left_join(firm_counts, by = c("Sector" = "sector"))

tab2_tex <- xtable(firm_class,
                   caption = "Sector Classification by Kafala Exposure",
                   label = "tab:classification",
                   align = c("l", "l", "c", "r", "r"))
print(tab2_tex, file = file.path(tab_dir, "tab2_classification.tex"),
      include.rownames = FALSE, floating = TRUE, booktabs = TRUE,
      sanitize.text.function = identity)
cat("Table 2 saved\n")

## ===============================================================
## TABLE 3: Main Results — CARs by Event
## ===============================================================

car_test <- results$car_test %>%
  mutate(
    `Mean CAR (%)` = round(mean_car * 100, 2),
    `SE (%)` = round(se_car * 100, 2),
    `t-stat` = round(t_stat, 2),
    Group = ifelse(high_exposure, "High Exposure", "Low Exposure")
  ) %>%
  select(Event = event_label, Group, N = n, `Mean CAR (%)`, `SE (%)`, `t-stat`)

tab3_tex <- xtable(car_test,
                   caption = "Cumulative Abnormal Returns by Event and Exposure Group",
                   label = "tab:car_main",
                   align = c("l", "l", "l", "r", "r", "r", "r"))
print(tab3_tex, file = file.path(tab_dir, "tab3_car_main.tex"),
      include.rownames = FALSE, floating = TRUE, booktabs = TRUE,
      sanitize.text.function = identity)
cat("Table 3 saved\n")

## ===============================================================
## TABLE 4: Main Regression Results
## ===============================================================

## Combine main specifications into etable
etable(
  results$car_reg,
  results$car_reg_cont,
  results$stacked_did,
  results$car_mm_reg,
  headers = c("Binary Exposure", "Continuous Exposure",
              "Stacked DiD", "Market Model"),
  tex = TRUE,
  file = file.path(tab_dir, "tab4_main_regressions.tex"),
  title = "Main Results: Effect of Kafala Reform on Firm Value",
  label = "tab:main_reg",
  notes = "Standard errors clustered at the firm level in parentheses. CAR computed over [-1, +3] event window. High Exposure = firms in construction, real estate, services, and industrial sectors. Continuous Exposure = approximate sector-level migrant worker share."
)
cat("Table 4 saved\n")

## ===============================================================
## TABLE 5: Robustness — Alternative Event Windows
## ===============================================================

tab5 <- robust$window_regs %>%
  mutate(
    `Coefficient (%)` = round(coef * 100, 2),
    `SE (%)` = round(se * 100, 2),
    `95\\% CI` = paste0("[", round(ci_lo * 100, 2), ", ", round(ci_hi * 100, 2), "]"),
    `p-value` = round(p_val, 3)
  ) %>%
  select(Window = window, `Coefficient (%)`, `SE (%)`, `95\\% CI`, `p-value`, N = n)

tab5_tex <- xtable(tab5,
                   caption = "Robustness: Differential CARs Across Alternative Event Windows",
                   label = "tab:windows",
                   align = c("l", "l", "r", "r", "c", "r", "r"))
print(tab5_tex, file = file.path(tab_dir, "tab5_windows.tex"),
      include.rownames = FALSE, floating = TRUE, booktabs = TRUE,
      sanitize.text.function = identity)
cat("Table 5 saved\n")

## ===============================================================
## TABLE 6: Placebo and GCC Results
## ===============================================================

if (nrow(robust$placebo_results) > 0) {
  tab6a <- robust$placebo_results %>%
    mutate(
      `Coefficient (%)` = round(coef * 100, 2),
      `SE (%)` = round(se * 100, 2),
      Significant = ifelse(significant, "Yes", "No")
    ) %>%
    select(`Placebo Date` = placebo_date, `Coefficient (%)`, `SE (%)`, Significant)

  tab6a_tex <- xtable(tab6a,
                      caption = "Placebo Tests: Differential CARs at Non-Event Dates",
                      label = "tab:placebo",
                      align = c("l", "l", "r", "r", "c"))
  print(tab6a_tex, file = file.path(tab_dir, "tab6_placebo.tex"),
        include.rownames = FALSE, floating = TRUE, booktabs = TRUE,
        sanitize.text.function = identity)
}

## GCC placebo table
if (nrow(robust$gcc_car) > 0) {
  gcc_wide <- robust$gcc_car %>%
    mutate(car_pct = round(car * 100, 2)) %>%
    pivot_wider(names_from = market, values_from = car_pct) %>%
    left_join(
      dat$events %>% select(event_id, event_label),
      by = "event_id"
    ) %>%
    select(Event = event_label, everything(), -event_id)

  tab6b_tex <- xtable(gcc_wide,
                      caption = "GCC Placebo: Index CARs Around UAE Reform Dates",
                      label = "tab:gcc_placebo")
  print(tab6b_tex, file = file.path(tab_dir, "tab6b_gcc_placebo.tex"),
        include.rownames = FALSE, floating = TRUE, booktabs = TRUE,
        sanitize.text.function = identity)
}

cat("Table 6 saved\n")

## ===============================================================
## TABLE 7: Market Model Betas
## ===============================================================

beta_summ <- results$betas %>%
  left_join(
    dat$dfm %>% distinct(ticker, name, sector, high_exposure),
    by = "ticker"
  ) %>%
  group_by(high_exposure) %>%
  summarise(
    `N Firms` = n(),
    `Mean Beta` = round(mean(beta), 3),
    `Median Beta` = round(median(beta), 3),
    `Mean R²` = round(mean(r2), 3),
    .groups = "drop"
  ) %>%
  mutate(Group = ifelse(high_exposure, "High Exposure", "Low Exposure")) %>%
  select(Group, everything(), -high_exposure)

tab7_tex <- xtable(beta_summ,
                   caption = "Market Model Estimation: Beta Summary by Exposure Group",
                   label = "tab:betas",
                   align = c("l", "l", "r", "r", "r", "r"))
print(tab7_tex, file = file.path(tab_dir, "tab7_betas.tex"),
      include.rownames = FALSE, floating = TRUE, booktabs = TRUE,
      sanitize.text.function = identity)
cat("Table 7 saved\n")

cat("\n=== ALL TABLES GENERATED ===\n")
