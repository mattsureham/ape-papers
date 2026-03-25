## 04_robustness.R — Robustness checks
## apep_0958: Dutch Nitrogen Ruling and Populist Backlash

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
cross_section <- readRDS(file.path(data_dir, "cross_section_clean.rds"))
rk <- readRDS(file.path(data_dir, "regional_keys_clean.rds"))

## ============================================================
## R1: Alternative treatment intensity — nitrogen excretion
## ============================================================
cat("=== R1: Nitrogen excretion as treatment ===\n")

cross_section <- cross_section %>%
  mutate(
    log_nitrogen = log(pmax(nitrogen_excretion, 1)),
    nitrogen_q = ntile(nitrogen_excretion, 4),
    high_nitrogen = as.integer(nitrogen_q >= 3)
  )

r1a <- feols(bbb_share ~ log_nitrogen, data = cross_section, vcov = "hetero")
r1b <- feols(bbb_share ~ log_nitrogen + bev_dichtheid + log(population),
             data = cross_section, vcov = "hetero")
r1c <- feols(bbb_share ~ log_nitrogen + n2k_share + bev_dichtheid + log(population),
             data = cross_section, vcov = "hetero")

cat("Nitrogen results:\n")
etable(r1a, r1b, r1c, se.below = TRUE)

## ============================================================
## R2: Agricultural land share as treatment
## ============================================================
cat("\n=== R2: Agricultural land share ===\n")

r2a <- feols(bbb_share ~ agri_land_pct, data = cross_section, vcov = "hetero")
r2b <- feols(bbb_share ~ agri_land_pct + bev_dichtheid + log(population),
             data = cross_section, vcov = "hetero")

cat("Agricultural land results:\n")
etable(r2a, r2b, se.below = TRUE)

## ============================================================
## R3: Placebo outcomes — FvD and PVV
## ============================================================
cat("\n=== R3: Placebo — other populist parties ===\n")

# FvD was founded 2016, ran in PS2019. If exposure predicts FvD, it's pre-existing.
r3_fvd <- feols(fvd_share ~ exposure + bev_dichtheid + log(population),
                data = cross_section, vcov = "hetero")
r3_pvv <- feols(pvv_share ~ exposure + bev_dichtheid + log(population),
                data = cross_section, vcov = "hetero")
r3_bbb <- feols(bbb_share ~ exposure + bev_dichtheid + log(population),
                data = cross_section, vcov = "hetero")

cat("Placebo (other populist parties):\n")
etable(r3_bbb, r3_fvd, r3_pvv,
       headers = c("BBB", "FvD", "PVV"), se.below = TRUE)

## ============================================================
## R4: Building permits — alternative measures
## ============================================================
cat("\n=== R4: Building permits with nitrogen treatment ===\n")

# Use nitrogen excretion instead of N2K × agri
panel <- panel %>%
  left_join(
    cross_section %>% select(gm_code, nitrogen_excretion, agri_land_pct) %>% distinct(),
    by = "gm_code"
  ) %>%
  mutate(
    log_nitrogen = log(pmax(nitrogen_excretion, 1)),
    nitrogen_post = log_nitrogen * post
  )

r4a <- feols(log_permits ~ nitrogen_post | gm_code + time_fe, data = panel,
             cluster = ~gm_code)
r4b <- feols(total_dwellings ~ nitrogen_post | gm_code + time_fe, data = panel,
             cluster = ~gm_code)

cat("Building permits with nitrogen treatment:\n")
etable(r4a, r4b, se.below = TRUE)

## ============================================================
## R5: Placebo treatment dates
## ============================================================
cat("\n=== R5: Placebo treatment dates ===\n")

for (placebo_year in c(2016, 2017, 2018)) {
  panel_placebo <- panel %>%
    filter(year <= 2019, quarter <= 2) %>%  # Only pre-treatment
    mutate(
      post_placebo = as.integer(year > placebo_year | (year == placebo_year & quarter >= 3)),
      exposure_post_placebo = exposure * post_placebo
    )

  m_placebo <- feols(log_permits ~ exposure_post_placebo | gm_code + time_fe,
                     data = panel_placebo, cluster = ~gm_code)
  cat(sprintf("  Placebo %d: beta=%.4f (se=%.4f), p=%.3f\n",
              placebo_year, coef(m_placebo)[1], se(m_placebo)[1],
              pvalue(m_placebo)[1]))
}

## ============================================================
## R6: Leave-one-province-out
## ============================================================
cat("\n=== R6: Leave-one-province-out (BBB) ===\n")

# Get province codes from municipality boundaries
treatment_full <- readRDS(file.path(data_dir, "treatment_full.rds"))
muni_sf <- readRDS(file.path(data_dir, "municipalities_sf.rds"))

# Extract province from municipality code (first 2 digits approximate)
# Actually use the CBS regional keys which have province info
cross_section <- cross_section %>%
  mutate(
    # Dutch GM codes: first 2 digits roughly indicate province
    # But better to use the population data which has province codes
    gm_num = as.integer(gm_code),
    province = case_when(
      gm_num < 60 ~ "Groningen",
      gm_num < 100 ~ "Friesland",
      gm_num < 120 ~ "Drenthe",
      gm_num < 200 ~ "Overijssel",
      gm_num < 300 ~ "Flevoland/Gelderland",
      gm_num < 400 ~ "Gelderland",
      gm_num < 500 ~ "Utrecht",
      gm_num < 600 ~ "Noord-Holland",
      gm_num < 700 ~ "Zuid-Holland",
      gm_num < 800 ~ "Zeeland",
      gm_num < 900 ~ "Noord-Brabant",
      TRUE ~ "Limburg"
    )
  )

lopo_results <- tibble()
for (prov in unique(cross_section$province)) {
  cs_sub <- cross_section %>% filter(province != prov)
  m <- feols(bbb_share ~ agri_share + bev_dichtheid + log(population),
             data = cs_sub, vcov = "hetero")
  lopo_results <- bind_rows(lopo_results, tibble(
    province = prov,
    beta_agri = coef(m)["agri_share"],
    se_agri = se(m)["agri_share"],
    n = nrow(cs_sub)
  ))
}

cat("LOPO results (agriculture coefficient):\n")
print(lopo_results)
cat(sprintf("Range: [%.3f, %.3f] (main: 0.601)\n",
            min(lopo_results$beta_agri), max(lopo_results$beta_agri)))

## ============================================================
## R7: Wild cluster bootstrap for DiD
## ============================================================
cat("\n=== R7: Wild cluster bootstrap ===\n")

# Use fixest's built-in wild bootstrap
boot_m2 <- feols(log_permits ~ exposure_post | gm_code + time_fe,
                 data = panel %>% filter(!is.na(exposure)), cluster = ~gm_code)
boot_pval <- tryCatch({
  # Wild bootstrap with 999 replications
  b <- boot(boot_m2, type = "wild", B = 999, cluster = ~gm_code)
  cat(sprintf("  Wild bootstrap p-value: %.3f\n", b$p[1]))
  b$p[1]
}, error = function(e) {
  cat(sprintf("  Bootstrap error: %s\n", e$message))
  NA
})

cat("\n=== Robustness complete ===\n")
