## 04_robustness.R — Robustness checks
## apep_1395: Denmark Renovation Arbitrage Ban

source("00_packages.R")

permits <- readRDS("../data/permits_panel.rds")
dwellings <- readRDS("../data/dwellings_panel.rds")

permits$muni_id <- as.numeric(factor(permits$muni_name))
permits$time_id <- as.numeric(factor(paste(permits$year, permits$quarter)))
permits$log_permits <- log(permits$total_permits + 1)
permits$log_multi <- log(permits$multifamily_permits + 1)

dwellings$muni_id <- as.numeric(factor(dwellings$muni_name))
names(dwellings) <- make.names(names(dwellings))
rental_col <- grep("tenant|lejer|rental", names(dwellings), value = TRUE, ignore.case = TRUE)
owner_col <- grep("owner|ejer", names(dwellings), value = TRUE, ignore.case = TRUE)
dwellings$rental <- dwellings[[rental_col[1]]]
dwellings$owner_occ <- dwellings[[owner_col[1]]]
dwellings$log_rental <- log(dwellings$rental + 1)
dwellings$log_owner <- log(dwellings$owner_occ + 1)

# ---- 1. Restricted pre-period (2015+) ----
cat("=== ROBUSTNESS 1: Restricted pre-period (2015+) ===\n")
permits_short <- permits %>% filter(year >= 2015)
permits_short$time_id <- as.numeric(factor(paste(permits_short$year, permits_short$quarter)))

r1 <- feols(total_permits ~ treated:post | muni_id + time_id,
            data = permits_short, cluster = ~muni_id)
cat("Total permits (2015+):\n")
summary(r1)

r1b <- feols(log_permits ~ treated:post | muni_id + time_id,
             data = permits_short, cluster = ~muni_id)
cat("Log permits (2015+):\n")
summary(r1b)

# ---- 2. Municipality-specific linear trends ----
cat("\n=== ROBUSTNESS 2: Municipality-specific linear trends ===\n")
permits$trend <- permits$time_q - 2020
r2 <- feols(total_permits ~ treated:post | muni_id[trend] + time_id,
            data = permits, cluster = ~muni_id)
cat("Total permits with muni-specific trends:\n")
summary(r2)

# ---- 3. Exclude COVID quarters (2020Q1-2021Q2) ----
cat("\n=== ROBUSTNESS 3: Exclude COVID period ===\n")
permits_nocovid <- permits %>%
  filter(!(year == 2020 & quarter %in% 1:2) &
         !(year == 2020 & quarter %in% 3:4) &
         !(year == 2021 & quarter %in% 1:2))
permits_nocovid$time_id <- as.numeric(factor(paste(permits_nocovid$year, permits_nocovid$quarter)))

r3 <- feols(total_permits ~ treated:post | muni_id + time_id,
            data = permits_nocovid, cluster = ~muni_id)
cat("Total permits (excl. COVID):\n")
summary(r3)

# ---- 4. Placebo treatment date (2017Q3) ----
cat("\n=== ROBUSTNESS 4: Placebo treatment (2017Q3) ===\n")
permits_placebo <- permits %>% filter(year <= 2019)
permits_placebo$post_placebo <- as.integer(permits_placebo$year > 2017 |
                                           (permits_placebo$year == 2017 & permits_placebo$quarter >= 3))
permits_placebo$time_id <- as.numeric(factor(paste(permits_placebo$year, permits_placebo$quarter)))

r4 <- feols(total_permits ~ treated:post_placebo | muni_id + time_id,
            data = permits_placebo, cluster = ~muni_id)
cat("Placebo (2017Q3):\n")
summary(r4)

# ---- 5. Late post-period only (2022Q3+, capturing delayed effect) ----
cat("\n=== ROBUSTNESS 5: Late post-period only (2022Q3+) ===\n")
permits_late <- permits %>%
  filter(year < 2020 | (year >= 2022 & quarter >= 3) | year >= 2023)
permits_late$post_late <- as.integer(permits_late$year >= 2023 |
                                     (permits_late$year == 2022 & permits_late$quarter >= 3))
permits_late$time_id <- as.numeric(factor(paste(permits_late$year, permits_late$quarter)))

r5 <- feols(total_permits ~ treated:post_late | muni_id + time_id,
            data = permits_late, cluster = ~muni_id)
cat("Late post only:\n")
summary(r5)

# ---- 6. Intensive margin: permits per capita (normalize by 2019 dwelling stock) ----
cat("\n=== ROBUSTNESS 6: Permits per dwelling ===\n")
dw_2019 <- dwellings %>%
  filter(year == 2019) %>%
  select(muni_name, rental_2019 = rental, owner_2019 = owner_occ)

permits_pc <- permits %>%
  left_join(dw_2019, by = "muni_name") %>%
  filter(!is.na(rental_2019), rental_2019 > 0) %>%
  mutate(permits_per_rental = total_permits / rental_2019 * 1000)

r6 <- feols(permits_per_rental ~ treated:post | muni_id + time_id,
            data = permits_pc, cluster = ~muni_id)
cat("Permits per 1000 rental dwellings:\n")
summary(r6)

# ---- 7. Event study on multifamily permits only ----
cat("\n=== ROBUSTNESS 7: Event study — multifamily ===\n")
m_es_multi <- feols(multifamily_permits ~ i(rel_q, treated, ref = -1) | muni_id + time_id,
                    data = permits, cluster = ~muni_id)

es_multi_coefs <- as.data.frame(coeftable(m_es_multi))
es_multi_coefs$rel_q <- as.numeric(str_extract(rownames(es_multi_coefs), "-?\\d+"))
es_multi_coefs <- es_multi_coefs[!is.na(es_multi_coefs$rel_q), ]
names(es_multi_coefs)[1:4] <- c("estimate", "se", "tstat", "pvalue")
saveRDS(es_multi_coefs, "../data/event_study_multi_coefs.rds")

# ---- 8. Callaway-Sant'Anna (all units share single treatment date) ----
cat("\n=== ROBUSTNESS 8: Callaway-Sant'Anna ===\n")
# Since all treated units share the same treatment date (2020Q3),
# CS-DiD simplifies to canonical 2x2 DiD. But we run it for completeness.
permits_cs <- permits %>%
  mutate(
    # Create integer time variable
    t = (year - 2006) * 4 + quarter,
    # Treatment group: treated units get g = treatment period, control get g = 0
    g = ifelse(treated == 1, (2020 - 2006) * 4 + 3, 0)  # 2020Q3
  )

cs_out <- tryCatch({
  att_gt(yname = "total_permits",
         tname = "t",
         idname = "muni_id",
         gname = "g",
         data = as.data.frame(permits_cs),
         control_group = "nevertreated",
         base_period = "universal")
}, error = function(e) {
  cat("CS-DiD error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_out)) {
  cat("CS-DiD ATT(g,t) summary:\n")
  agg_simple <- aggte(cs_out, type = "simple")
  print(summary(agg_simple))

  agg_dynamic <- aggte(cs_out, type = "dynamic")
  cat("\nCS-DiD dynamic aggregation:\n")
  print(summary(agg_dynamic))
  saveRDS(agg_dynamic, "../data/cs_dynamic.rds")
}

# ---- Save all robustness results ----
saveRDS(list(
  r1 = r1, r1b = r1b, r2 = r2, r3 = r3, r4 = r4, r5 = r5, r6 = r6,
  m_es_multi = m_es_multi, cs_out = if (exists("cs_out")) cs_out else NULL
), "../data/robustness_models.rds")

cat("\nAll robustness checks complete.\n")
