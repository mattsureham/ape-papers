## 02_clean_data.R — Construct analysis panel
## APEP-0705: Sweden's RUT Household Services Deduction

source("00_packages.R")

data_dir <- "../data"

## Load raw data
income_df     <- readRDS(file.path(data_dir, "income_municipality.rds"))
treatment_df  <- readRDS(file.path(data_dir, "treatment_intensity.rds"))
emp07_df      <- readRDS(file.path(data_dir, "employment_sni07.rds"))
emp02_df      <- readRDS(file.path(data_dir, "employment_sni02.rds"))
emprate_df    <- readRDS(file.path(data_dir, "employment_rate_origin.rds"))
muni_names    <- readRDS(file.path(data_dir, "municipality_names.rds"))

## ============================================================
## 1. MAIN PANEL: Income x Treatment Intensity (1999-2024)
## ============================================================
cat("Building main income panel...\n")

panel <- income_df %>%
  left_join(treatment_df, by = "region") %>%
  mutate(
    post = as.integer(year >= 2007),
    log_mean_income = log(mean_income),
    # Interaction for basic DiD
    treat_x_post = treat_intensity * post
  ) %>%
  filter(!is.na(treat_intensity))

cat("  Panel: ", n_distinct(panel$region), "municipalities x",
    n_distinct(panel$year), "years =", nrow(panel), "obs\n")
cat("  Pre-reform years (1999-2006):", sum(panel$year < 2007), "\n")
cat("  Post-reform years (2007-2024):", sum(panel$year >= 2007), "\n")

## ============================================================
## 2. SERVICE SECTOR EMPLOYMENT PANEL (2008-2018)
## ============================================================
cat("\nBuilding employment panel...\n")

# Aggregate both sexes for sector-level panel
emp_sector <- emp07_df %>%
  group_by(region, sector, year) %>%
  summarise(emp = sum(emp, na.rm = TRUE), .groups = "drop")

# Add treatment intensity
emp_panel <- emp_sector %>%
  left_join(treatment_df, by = "region") %>%
  filter(!is.na(treat_intensity)) %>%
  mutate(log_emp = log(pmax(emp, 1)))

cat("  Employment panel:", nrow(emp_panel), "obs\n")
cat("  Sectors:", paste(unique(emp_panel$sector), collapse = ", "), "\n")

# By-sex panel for gender mechanism
# Sector labels use full names from JSON-stat
mn_label <- unique(emp07_df$sector)[grepl("professional", unique(emp07_df$sector))]
cat("  M+N sector label:", mn_label, "\n")

emp_sex <- emp07_df %>%
  left_join(treatment_df, by = "region") %>%
  filter(!is.na(treat_intensity), sector == mn_label) %>%
  mutate(
    female = as.integer(sex == "women"),
    log_emp = log(pmax(emp, 1))
  )

cat("  M+N by sex:", nrow(emp_sex), "obs\n")

## ============================================================
## 3. EMPLOYMENT RATE PANEL (native vs foreign-born, 2004-2018)
## ============================================================
cat("\nBuilding employment rate panel...\n")

emprate_panel <- emprate_df %>%
  left_join(treatment_df, by = "region") %>%
  filter(!is.na(treat_intensity)) %>%
  mutate(
    post = as.integer(year >= 2007),
    foreign_born = as.integer(origin == "foreign-born"),
    treat_x_post = treat_intensity * post,
    treat_x_post_x_fb = treat_intensity * post * foreign_born
  )

cat("  Employment rate panel:", nrow(emprate_panel), "obs\n")
cat("  Years:", paste(range(emprate_panel$year), collapse = "-"), "\n")

## ============================================================
## 4. PRE-REFORM EMPLOYMENT (SNI2002, 2004-2007)
## ============================================================
cat("\nBuilding pre-reform employment panel...\n")

# SNI2002 "J+Kexkl73" ≈ business services (rough analogue to SNI2007 M+N)
emp_pre <- emp02_df %>%
  group_by(region, sector, year) %>%
  summarise(emp = sum(emp, na.rm = TRUE), .groups = "drop") %>%
  left_join(treatment_df, by = "region") %>%
  filter(!is.na(treat_intensity))

cat("  Pre-reform employment:", nrow(emp_pre), "obs\n")

## ============================================================
## SUMMARY STATISTICS
## ============================================================
cat("\n=== Summary Statistics ===\n")

cat("\nIncome panel (1999-2024):\n")
cat("  N municipalities:", n_distinct(panel$region), "\n")
cat("  Mean income (SEK thousands): mean =", round(mean(panel$mean_income), 1),
    ", sd =", round(sd(panel$mean_income), 1), "\n")
cat("  Log mean income: mean =", round(mean(panel$log_mean_income), 2),
    ", sd =", round(sd(panel$log_mean_income), 2), "\n")

cat("\nTreatment intensity (2006 mean income, SEK thousands):\n")
q_labels <- treatment_df %>%
  group_by(income_quartile) %>%
  summarise(
    mean_inc = round(mean(mean_income_2006), 1),
    n = n(),
    .groups = "drop"
  )
print(q_labels)

cat("\nM+N employment (2008-2018):\n")
mn_stats <- emp_panel %>% filter(sector == "M+N")
cat("  Mean:", round(mean(mn_stats$emp), 0), ", SD:", round(sd(mn_stats$emp), 0), "\n")

cat("\nEmployment rates (2004-2018):\n")
cat("  Native-born: mean =", round(mean(emprate_panel$emp_rate[emprate_panel$foreign_born == 0], na.rm=TRUE), 1), "%\n")
cat("  Foreign-born: mean =", round(mean(emprate_panel$emp_rate[emprate_panel$foreign_born == 1], na.rm=TRUE), 1), "%\n")

## ============================================================
## SAVE ANALYSIS PANELS
## ============================================================
saveRDS(panel, file.path(data_dir, "panel_income.rds"))
saveRDS(emp_panel, file.path(data_dir, "panel_employment.rds"))
saveRDS(emp_sex, file.path(data_dir, "panel_emp_sex.rds"))
saveRDS(emprate_panel, file.path(data_dir, "panel_emprate.rds"))
saveRDS(emp_pre, file.path(data_dir, "panel_emp_pre.rds"))

cat("\n=== PANEL CONSTRUCTION COMPLETE ===\n")
