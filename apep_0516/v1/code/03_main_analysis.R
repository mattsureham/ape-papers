## ============================================================
## 03_main_analysis.R — Primary DiD and event study estimates
## apep_0516: PTZ Geographic Withdrawal and Housing Markets
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"

panel <- fread(file.path(DATA_DIR, "panel_main.csv"))
panel_border <- fread(file.path(DATA_DIR, "panel_border.csv"))

# ============================================================
# Sample restrictions
# ============================================================

# Main sample: B1 vs B2/C, valid prices
main <- panel[zone_group %in% c("B1", "B2/C") & !is.na(log_price_m2)]
cat(sprintf("Main sample: %s commune-years, %s communes\n",
            formatC(nrow(main), big.mark = ","),
            formatC(uniqueN(main$code_commune), big.mark = ",")))

# ============================================================
# 1. FIRST STAGE: New construction (VEFA) volume
# ============================================================

main[, log_vefa := log(n_vefa + 1)]

fs_reg <- feols(log_vefa ~ treated:post |
                  code_commune + year,
                data = main,
                cluster = ~code_departement)

cat("=== FIRST STAGE: VEFA transactions ===\n")
summary(fs_reg)

# First stage event study
fs_event <- feols(log_vefa ~ i(event_time, treated, ref = -1) |
                    code_commune + year,
                  data = main,
                  cluster = ~code_departement)

cat("\n=== FIRST STAGE EVENT STUDY ===\n")
summary(fs_event)

fs_coefs <- as.data.table(coeftable(fs_event), keep.rownames = "term")
fwrite(fs_coefs, file.path(DATA_DIR, "first_stage_event_coefs.csv"))

# First stage aggregates for figure
fs_agg <- main[, .(n_vefa = sum(n_vefa, na.rm = TRUE),
                    n_transactions = sum(n_transactions, na.rm = TRUE),
                    vefa_share = sum(n_vefa, na.rm = TRUE) / sum(n_transactions, na.rm = TRUE)),
               by = .(zone_group, year)]
fwrite(fs_agg, file.path(DATA_DIR, "first_stage_agg.csv"))

# ============================================================
# 2. MAIN RESULT: Price effects (all residential, price/m2)
# ============================================================

# 2a. Simple DiD
did_simple <- feols(log_price_m2 ~ did |
                      code_commune + year,
                    data = main,
                    cluster = ~code_departement)

cat("\n=== MAIN DiD: All residential (price/m2) ===\n")
summary(did_simple)

# 2b. Event study
es_main <- feols(log_price_m2 ~ i(event_time, treated, ref = -1) |
                   code_commune + year,
                 data = main,
                 cluster = ~code_departement)

cat("\n=== EVENT STUDY: All residential ===\n")
summary(es_main)

es_main_coefs <- as.data.table(coeftable(es_main), keep.rownames = "term")
fwrite(es_main_coefs, file.path(DATA_DIR, "event_study_main_coefs.csv"))

# ============================================================
# 3. MECHANISM: New-build vs existing housing prices
# ============================================================

# VEFA apartment prices
main[, log_vefa_price := log(price_m2_vefa_apt)]
main[, log_sale_price := log(price_m2_sale_apt)]

# 3a. VEFA prices
did_vefa <- feols(log_vefa_price ~ did |
                    code_commune + year,
                  data = main[!is.na(log_vefa_price)],
                  cluster = ~code_departement)

cat("\n=== DiD: New-build (VEFA) apartment prices/m2 ===\n")
summary(did_vefa)

es_vefa <- feols(log_vefa_price ~ i(event_time, treated, ref = -1) |
                   code_commune + year,
                 data = main[!is.na(log_vefa_price)],
                 cluster = ~code_departement)

es_vefa_coefs <- as.data.table(coeftable(es_vefa), keep.rownames = "term")
fwrite(es_vefa_coefs, file.path(DATA_DIR, "event_study_vefa_coefs.csv"))

# 3b. Existing housing prices
did_existing <- feols(log_sale_price ~ did |
                        code_commune + year,
                      data = main[!is.na(log_sale_price)],
                      cluster = ~code_departement)

cat("\n=== DiD: Existing housing apartment prices/m2 ===\n")
summary(did_existing)

es_existing <- feols(log_sale_price ~ i(event_time, treated, ref = -1) |
                       code_commune + year,
                     data = main[!is.na(log_sale_price)],
                     cluster = ~code_departement)

es_existing_coefs <- as.data.table(coeftable(es_existing), keep.rownames = "term")
fwrite(es_existing_coefs, file.path(DATA_DIR, "event_study_existing_coefs.csv"))

# ============================================================
# 4. MECHANISM: Transaction volume effects
# ============================================================

main[, log_transactions := log(n_transactions + 1)]

vol_did <- feols(log_transactions ~ did |
                   code_commune + year,
                 data = main,
                 cluster = ~code_departement)

cat("\n=== DiD: Transaction volume ===\n")
summary(vol_did)

es_volume <- feols(log_transactions ~ i(event_time, treated, ref = -1) |
                     code_commune + year,
                   data = main,
                   cluster = ~code_departement)

es_volume_coefs <- as.data.table(coeftable(es_volume), keep.rownames = "term")
fwrite(es_volume_coefs, file.path(DATA_DIR, "event_study_volume_coefs.csv"))

# ============================================================
# 5. BORDER SAMPLE
# ============================================================

border <- panel_border[!is.na(log_price_m2)]

did_border <- feols(log_price_m2 ~ did |
                      code_commune + year,
                    data = border,
                    cluster = ~code_departement)

cat("\n=== BORDER DiD ===\n")
summary(did_border)

es_border <- feols(log_price_m2 ~ i(event_time, treated, ref = -1) |
                     code_commune + year,
                   data = border,
                   cluster = ~code_departement)

es_border_coefs <- as.data.table(coeftable(es_border), keep.rownames = "term")
fwrite(es_border_coefs, file.path(DATA_DIR, "event_study_border_coefs.csv"))

# ============================================================
# 6. TWO-STAGE TREATMENT (2018 halving + 2020 elimination)
# ============================================================

did_twostage <- feols(log_price_m2 ~ treated:post_2018 + treated:post_2020 |
                        code_commune + year,
                      data = main,
                      cluster = ~code_departement)

cat("\n=== TWO-STAGE DiD (2018 halving + 2020 elimination) ===\n")
summary(did_twostage)

# ============================================================
# 7. HOUSE PRICES (median total value, not per m2)
# ============================================================

main[, log_house_price := log(median_price_sale_house)]

did_house <- feols(log_house_price ~ did |
                     code_commune + year,
                   data = main[!is.na(log_house_price)],
                   cluster = ~code_departement)

cat("\n=== DiD: House prices (total, not per m2) ===\n")
summary(did_house)

# ============================================================
# 8. Save all models
# ============================================================

models <- list(
  fs_reg = fs_reg,
  fs_event = fs_event,
  did_simple = did_simple,
  es_main = es_main,
  did_vefa = did_vefa,
  es_vefa = es_vefa,
  did_existing = did_existing,
  es_existing = es_existing,
  vol_did = vol_did,
  es_volume = es_volume,
  did_border = did_border,
  es_border = es_border,
  did_twostage = did_twostage,
  did_house = did_house
)

saveRDS(models, file.path(DATA_DIR, "models_main.rds"))

cat("\n=== All main models saved ===\n")
