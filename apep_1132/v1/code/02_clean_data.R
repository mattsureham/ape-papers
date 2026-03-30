# 02_clean_data.R — Clean and merge FCA complaints + BoE insurance data
source("00_packages.R")

data_dir <- "../data"

# ==============================================================================
# 1. FCA Complaints Panel
# ==============================================================================
cat("=== Building FCA Complaints Panel ===\n")

# Read the two files that together cover 2016 H2 - 2025 H1
df_early <- read_excel(file.path(data_dir, "fca_complaints_2022h1.xlsx"),
                       sheet = "Product Specific")
df_late  <- read_excel(file.path(data_dir, "fca_complaints_2025h1.xlsx"),
                       sheet = "Product Specific")

# Standardize column names
names(df_early)[4] <- "Variable_type"
names(df_late)[4]  <- "Variable_type"

# Remove "Grand Total" semester
df_early <- df_early %>% filter(Semester != "Grand Total")
df_late  <- df_late  %>% filter(Semester != "Grand Total")

# Combine: use df_late for overlapping periods (more recent file)
overlap_semesters <- intersect(df_early$Semester, df_late$Semester)
cat("  Overlap semesters:", paste(overlap_semesters, collapse = ", "), "\n")

df_early_unique <- df_early %>% filter(!Semester %in% overlap_semesters)
fca_raw <- bind_rows(df_early_unique, df_late)

cat("  Combined semesters:", paste(sort(unique(fca_raw$Semester)), collapse = ", "), "\n")

# Define insurance products
treated_products  <- c("Motor & transport", "Property")
control_products  <- c("Pet", "Travel", "Medical/health", "Warranty", "Assistance")
all_products      <- c(treated_products, control_products)

# Filter to insurance products and "Complaints opened" + "Provision"
fca_ins <- fca_raw %>%
  filter(Product %in% all_products,
         Variable_type %in% c("Complaints opened", "Provision")) %>%
  select(Semester, Product, Variable_type, Volume)

cat("  Insurance product-semester obs:", nrow(fca_ins), "\n")

# Pivot wider: one row per product x semester
fca_panel <- fca_ins %>%
  pivot_wider(names_from = Variable_type, values_from = Volume) %>%
  rename(complaints = `Complaints opened`, provision = Provision)

# Compute complaint rate per 1,000 policies
fca_panel <- fca_panel %>%
  mutate(
    complaint_rate = (complaints / provision) * 1000,
    treated = as.integer(Product %in% treated_products),
    # Parse semester into numeric time index
    year = as.integer(str_extract(Semester, "^\\d{4}")),
    half = as.integer(str_extract(Semester, "\\d$")),
    time_idx = (year - 2016) * 2 + half,  # 2016 H2 = 2, 2017 H1 = 3, etc.
    post = as.integer(Semester >= "2022 H1"),
    log_complaints = log(complaints + 1),
    log_provision = log(provision)
  )

# Verify no missing data
n_missing <- sum(is.na(fca_panel$complaint_rate))
if (n_missing > 0) {
  cat(sprintf("  WARNING: %d missing complaint rates\n", n_missing))
  # Show which products have missing data
  fca_panel %>% filter(is.na(complaint_rate)) %>%
    select(Semester, Product) %>% print()
}

cat("  Final FCA panel:", nrow(fca_panel), "observations\n")
cat("  Products:", paste(sort(unique(fca_panel$Product)), collapse = ", "), "\n")
cat("  Semesters:", length(unique(fca_panel$Semester)), "\n")
cat("  Treated products:", sum(fca_panel$treated == 1) / length(unique(fca_panel$Semester)), "\n")
cat("  Control products:", sum(fca_panel$treated == 0) / length(unique(fca_panel$Semester)), "\n")

# Summary stats
cat("\n--- Complaint Rates by Product ---\n")
fca_panel %>%
  group_by(Product, treated) %>%
  summarise(
    mean_rate = mean(complaint_rate, na.rm = TRUE),
    mean_complaints = mean(complaints, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(treated), Product) %>%
  print(n = 20)

# ==============================================================================
# 2. BoE Insurance Panel
# ==============================================================================
cat("\n=== Building BoE Insurance Panel ===\n")

boe_raw <- read.csv(file.path(data_dir, "boe_insurance_aggregate.csv"))

# Lines of business mapping to treated/control
boe_treated_lines <- c("Motor liability", "Motor other", "Property")
boe_control_lines <- c("Medical expense", "Legal expenses", "Assistance")
boe_all_lines     <- c(boe_treated_lines, boe_control_lines)

boe_panel <- boe_raw %>%
  filter(Chart.Feature.1 %in% boe_all_lines,
         Chart.Feature.2 %in% c("Net Written Premium", "Loss ratio")) %>%
  select(quarter = Reporting.Period, line = Chart.Feature.1,
         metric = Chart.Feature.2, gbp = GBP.Value, ratio = Ratio) %>%
  mutate(
    value = ifelse(!is.na(gbp), gbp, ratio),
    treated = as.integer(line %in% boe_treated_lines)
  )

# Pivot to get NWP and Loss Ratio as separate columns
boe_wide <- boe_panel %>%
  mutate(metric_short = ifelse(metric == "Net Written Premium", "nwp", "loss_ratio")) %>%
  select(quarter, line, metric_short, value, treated) %>%
  pivot_wider(names_from = metric_short, values_from = value) %>%
  mutate(
    year = as.integer(substr(quarter, 1, 4)),
    qtr  = as.integer(substr(quarter, 6, 6)),
    time_idx = (year - 2017) * 4 + qtr,
    post = as.integer(quarter >= "2022Q1"),
    log_nwp = log(nwp)
  )

cat("  BoE panel:", nrow(boe_wide), "observations\n")
cat("  Lines:", paste(sort(unique(boe_wide$line)), collapse = ", "), "\n")
cat("  Quarters:", length(unique(boe_wide$quarter)), "\n")

cat("\n--- NWP by Line (millions GBP) ---\n")
boe_wide %>%
  group_by(line, treated) %>%
  summarise(mean_nwp_m = mean(nwp, na.rm = TRUE) / 1e6,
            mean_lr = mean(loss_ratio, na.rm = TRUE),
            n = n(), .groups = "drop") %>%
  arrange(desc(treated), line) %>%
  print()

# ==============================================================================
# 3. Save panels
# ==============================================================================

saveRDS(fca_panel, file.path(data_dir, "fca_panel.rds"))
saveRDS(boe_wide, file.path(data_dir, "boe_panel.rds"))
write.csv(fca_panel, file.path(data_dir, "fca_panel.csv"), row.names = FALSE)
write.csv(boe_wide, file.path(data_dir, "boe_panel.csv"), row.names = FALSE)

cat("\n=== Panels saved ===\n")
