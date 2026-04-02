# 04_robustness.R — Robustness checks
source("00_packages.R")
load("data/models.RData")
s2 <- readRDS("data/secopii_clean.rds")

# Already have: m_placebo, m_no_bog
# Additional checks:

cat("=== Additional Robustness ===\n")

# (1) By modality within SECOP II
s2c <- s2[is_competitive == TRUE & !is.na(bidders) & bidders >= 1]
adopt_q <- s2c[!is.na(first_treat_q), .(ftq = first_treat_q[1]), by = entity_code]
terciles <- quantile(adopt_q$ftq, probs = c(1/3, 2/3))
s2c[, early_adopter := as.integer(!is.na(first_treat_q) & first_treat_q <= terciles[1])]

cat("\nBy Modality (single-bidder rate):\n")
for (mod_name in c("cuantía", "icitación", "ubasta", "elección")) {
  sub <- s2c[grepl(mod_name, modalidad_de_contratacion, ignore.case = TRUE) &
             !is.na(first_treat_q)]
  if (nrow(sub) > 200) {
    m_mod <- feols(single_bidder ~ early_adopter | yq,
                   data = sub, cluster = ~entity_code)
    cat(sprintf("  %s: coef=%.4f SE=%.4f N=%d\n",
                mod_name, coef(m_mod)["early_adopter"],
                se(m_mod)["early_adopter"], nrow(sub)))
  }
}

# (2) Department-level clustering for SECOP II
m_dept_sb <- feols(single_bidder ~ early_adopter | yq + modalidad_de_contratacion,
                   data = s2c[!is.na(first_treat_q)],
                   cluster = ~departamento_entidad)
cat("\nDept cluster SB:", round(coef(m_dept_sb)["early_adopter"], 4),
    "(SE:", round(se(m_dept_sb)["early_adopter"], 4), ")\n")

# Save
save(m_dept_sb, file = "data/robustness_extra.RData")
cat("Robustness saved.\n")
