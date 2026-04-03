# 02_clean_data.R — Variable construction and sample definition
# apep_1344: The Potency Arms Race

source("00_packages.R")

cat("=== Loading saved data ===\n")
analysis_df <- readRDS("../data/analysis_df.rds")
panel_df <- readRDS("../data/panel_df.rds")
oxy_detail <- readRDS("../data/oxy_detail.rds")

cat(sprintf("Analysis cross-section: %s counties\n", nrow(analysis_df)))
cat(sprintf("Panel: %s county-years\n", nrow(panel_df)))

cat("\n=== Constructing additional variables ===\n")

# Quintiles and standardized share
analysis_df <- analysis_df %>%
  mutate(
    malli_q5 = ntile(malli_share_2006, 5),
    malli_q5_label = paste0("Q", malli_q5),
    malli_share_std = (malli_share_2006 - mean(malli_share_2006, na.rm = TRUE)) /
                       sd(malli_share_2006, na.rm = TRUE)
  )

# Product variety (NDC count change)
ndc_counts <- oxy_detail %>%
  mutate(ndc_id = paste(Revised_Company_Name, dos_str, DRUG_NAME)) %>%
  group_by(BUYER_STATE, BUYER_COUNTY, year) %>%
  summarise(n_ndc = n_distinct(ndc_id), .groups = "drop")

ndc_change <- ndc_counts %>%
  filter(year %in% c(2006, 2007)) %>%
  group_by(BUYER_STATE, BUYER_COUNTY) %>%
  summarise(ndc_pre = mean(n_ndc), .groups = "drop") %>%
  inner_join(
    ndc_counts %>%
      filter(year %in% c(2009, 2010)) %>%
      group_by(BUYER_STATE, BUYER_COUNTY) %>%
      summarise(ndc_post = mean(n_ndc), .groups = "drop"),
    by = c("BUYER_STATE", "BUYER_COUNTY")
  ) %>%
  mutate(delta_ndc = ndc_post - ndc_pre)

analysis_df <- analysis_df %>%
  left_join(ndc_change, by = c("BUYER_STATE", "BUYER_COUNTY"))

# 40mg+ dose share change
dose_shares <- oxy_detail %>%
  mutate(dos_numeric = as.numeric(dos_str)) %>%
  group_by(BUYER_STATE, BUYER_COUNTY, year) %>%
  summarise(
    pills_40plus = sum(total_pills[dos_numeric >= 40]),
    pills_total = sum(total_pills),
    share_40plus = pills_40plus / pills_total,
    .groups = "drop"
  )

delta_40 <- dose_shares %>%
  filter(year %in% c(2006, 2007)) %>%
  group_by(BUYER_STATE, BUYER_COUNTY) %>%
  summarise(share_40plus_pre = weighted.mean(share_40plus, pills_total), .groups = "drop") %>%
  inner_join(
    dose_shares %>%
      filter(year %in% c(2009, 2010)) %>%
      group_by(BUYER_STATE, BUYER_COUNTY) %>%
      summarise(share_40plus_post = weighted.mean(share_40plus, pills_total), .groups = "drop"),
    by = c("BUYER_STATE", "BUYER_COUNTY")
  ) %>%
  mutate(delta_40plus = share_40plus_post - share_40plus_pre)

analysis_df <- analysis_df %>%
  left_join(delta_40 %>% select(BUYER_STATE, BUYER_COUNTY, delta_40plus),
            by = c("BUYER_STATE", "BUYER_COUNTY"))

# Panel variables
panel_df <- panel_df %>%
  mutate(
    malli_share_std = (malli_share_2006 - mean(malli_share_2006, na.rm = TRUE)) /
                       sd(malli_share_2006, na.rm = TRUE),
    event_time = year - 2008,
    county_id = paste(BUYER_STATE, BUYER_COUNTY, sep = "_")
  )

# Log total pills change
analysis_df <- analysis_df %>%
  mutate(delta_log_pills = log(total_pills_post + 1) - log(total_pills_pre + 1))

cat("\n=== Quintile Summary ===\n")
analysis_df %>%
  group_by(malli_q5) %>%
  summarise(
    n = n(),
    mean_share = mean(malli_share_2006),
    delta_mme = mean(delta_mme, na.rm = TRUE),
    delta_hd = mean(delta_high_dose, na.rm = TRUE),
    delta_ndc = mean(delta_ndc, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\n=== Key Stats ===\n")
cat(sprintf("Counties: %s, States: %s\n", nrow(analysis_df), n_distinct(analysis_df$BUYER_STATE)))
cat(sprintf("Mallinckrodt share — mean: %.3f, sd: %.3f\n",
            mean(analysis_df$malli_share_2006), sd(analysis_df$malli_share_2006)))
cat(sprintf("Delta MME/pill — mean: %.3f, sd: %.3f\n",
            mean(analysis_df$delta_mme, na.rm=T), sd(analysis_df$delta_mme, na.rm=T)))

saveRDS(analysis_df, "../data/analysis_clean.rds")
saveRDS(panel_df, "../data/panel_clean.rds")
cat("Cleaned data saved.\n")
