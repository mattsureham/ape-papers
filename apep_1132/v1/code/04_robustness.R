# 04_robustness.R — Robustness checks
source("00_packages.R")

data_dir <- "../data"
fca <- readRDS(file.path(data_dir, "fca_panel.rds"))
load(file.path(data_dir, "regression_results.RData"))

fca$product_fe <- factor(fca$Product)
fca$time_fe    <- factor(fca$Semester)

# ==============================================================================
# 1. Exclude Travel (COVID-confounded)
# ==============================================================================
cat("=== Robustness 1: Exclude Travel ===\n")

fca_no_travel <- fca %>% filter(Product != "Travel")
fca_no_travel$product_fe <- droplevels(factor(fca_no_travel$Product))
fca_no_travel$time_fe    <- factor(fca_no_travel$Semester)

r1 <- feols(complaint_rate ~ treated:post | product_fe + time_fe,
            data = fca_no_travel, cluster = ~product_fe)
summary(r1)

# ==============================================================================
# 2. Drop COVID acute period (2020 H1, 2020 H2)
# ==============================================================================
cat("\n=== Robustness 2: Drop COVID period ===\n")

fca_no_covid <- fca %>% filter(!Semester %in% c("2020 H1", "2020 H2"))
fca_no_covid$product_fe <- droplevels(factor(fca_no_covid$Product))
fca_no_covid$time_fe    <- factor(fca_no_covid$Semester)

r2 <- feols(complaint_rate ~ treated:post | product_fe + time_fe,
            data = fca_no_covid, cluster = ~product_fe)
summary(r2)

# ==============================================================================
# 3. Exclude Travel AND drop COVID
# ==============================================================================
cat("\n=== Robustness 3: Exclude Travel + Drop COVID ===\n")

fca_clean <- fca %>%
  filter(Product != "Travel", !Semester %in% c("2020 H1", "2020 H2"))
fca_clean$product_fe <- droplevels(factor(fca_clean$Product))
fca_clean$time_fe    <- factor(fca_clean$Semester)

r3 <- feols(complaint_rate ~ treated:post | product_fe + time_fe,
            data = fca_clean, cluster = ~product_fe)
summary(r3)

# ==============================================================================
# 4. Placebo test: Pretend treatment at 2020 H1 (pre-actual reform)
# ==============================================================================
cat("\n=== Robustness 4: Placebo treatment at 2020 H1 ===\n")

fca_pre <- fca %>% filter(Semester < "2022 H1")  # Only pre-period
fca_pre$placebo_post <- as.integer(fca_pre$Semester >= "2020 H1")
fca_pre$product_fe <- droplevels(factor(fca_pre$Product))
fca_pre$time_fe    <- factor(fca_pre$Semester)

r4 <- feols(complaint_rate ~ treated:placebo_post | product_fe + time_fe,
            data = fca_pre, cluster = ~product_fe)
summary(r4)

# ==============================================================================
# 5. Triple-diff: Motor vs Property (within treated group)
# ==============================================================================
cat("\n=== Robustness 5: Motor vs Property within treated ===\n")

fca_treated <- fca %>% filter(treated == 1)
fca_treated$is_motor <- as.integer(fca_treated$Product == "Motor & transport")
fca_treated$product_fe <- droplevels(factor(fca_treated$Product))
fca_treated$time_fe    <- factor(fca_treated$Semester)

r5 <- feols(complaint_rate ~ is_motor:post | product_fe + time_fe,
            data = fca_treated, cluster = ~product_fe)
summary(r5)

# ==============================================================================
# 6. Randomization Inference (Fisher permutation)
# ==============================================================================
cat("\n=== Robustness 6: Randomization Inference ===\n")

# Permute treatment assignment across products
set.seed(42)
n_perms <- 1000
actual_coef <- coef(m1_rate)[["treated:post"]]

perm_coefs <- numeric(n_perms)
products <- unique(fca$Product)

for (i in seq_len(n_perms)) {
  # Randomly assign 2 products as "treated"
  perm_treated <- sample(products, 2)
  fca$perm_treat <- as.integer(fca$Product %in% perm_treated)

  m_perm <- tryCatch(
    feols(complaint_rate ~ perm_treat:post | product_fe + time_fe, data = fca),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) {
    perm_coefs[i] <- coef(m_perm)[["perm_treat:post"]]
  } else {
    perm_coefs[i] <- NA
  }
}

ri_pval <- mean(abs(perm_coefs) >= abs(actual_coef), na.rm = TRUE)
cat(sprintf("  Actual coefficient: %.4f\n", actual_coef))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_pval))
cat(sprintf("  Permutation distribution: mean=%.4f, sd=%.4f\n",
            mean(perm_coefs, na.rm = TRUE), sd(perm_coefs, na.rm = TRUE)))

# ==============================================================================
# 7. Summary of all robustness checks
# ==============================================================================
cat("\n=== Robustness Summary ===\n")

results <- data.frame(
  Specification = c(
    "Baseline",
    "Exclude Travel",
    "Drop COVID",
    "Exclude Travel + Drop COVID",
    "Placebo (2020H1)",
    "Motor vs Property"
  ),
  Coef = c(
    coef(m1_rate)[["treated:post"]],
    coef(r1)[["treated:post"]],
    coef(r2)[["treated:post"]],
    coef(r3)[["treated:post"]],
    coef(r4)[["treated:placebo_post"]],
    coef(r5)[["is_motor:post"]]
  ),
  SE = c(
    se(m1_rate)[["treated:post"]],
    se(r1)[["treated:post"]],
    se(r2)[["treated:post"]],
    se(r3)[["treated:post"]],
    se(r4)[["treated:placebo_post"]],
    se(r5)[["is_motor:post"]]
  ),
  Pval = c(
    pvalue(m1_rate)[["treated:post"]],
    pvalue(r1)[["treated:post"]],
    pvalue(r2)[["treated:post"]],
    pvalue(r3)[["treated:post"]],
    pvalue(r4)[["treated:placebo_post"]],
    pvalue(r5)[["is_motor:post"]]
  ),
  N = c(nrow(fca), nrow(fca_no_travel), nrow(fca_no_covid),
        nrow(fca_clean), nrow(fca_pre), nrow(fca_treated))
)
results$Stars <- ifelse(results$Pval < 0.01, "***",
                   ifelse(results$Pval < 0.05, "**",
                     ifelse(results$Pval < 0.1, "*", "")))

print(results, digits = 3)

# Save robustness results
save(r1, r2, r3, r4, r5, ri_pval, perm_coefs, results,
     file = file.path(data_dir, "robustness_results.RData"))

cat("\n=== Robustness checks complete ===\n")
