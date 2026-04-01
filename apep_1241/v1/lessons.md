## Discovery
- **Idea selected:** idea_1639 — EU fur farming bans × trade diversion. Selected for sharp staggered policy variation across 15+ countries, zero APEP overlap on animal welfare regulation, and portable "animal welfare haven" mechanism.
- **Data source:** Open Trade Statistics (api.tradestatistics.io) — COMTRADE was unreachable; OTS mirrors COMTRADE perfectly. Fetched bilateral HS 430110 (mink furskins), plus HS 410120 and 510111 as placebos.
- **Key risk:** Small cluster count (14 EU countries). Mitigated by focusing on active producers (10 countries) where the treatment is economically meaningful.

## Execution
- **What worked:** The treatment effect among active producers is sharp (-1.34 log points, p=0.024). Poland's trade diversion pattern is striking ($13M→$407M, 2002-2014). The "animal welfare haven" framing generates a vivid, portable mechanism name.
- **What didn't:** TWFE on the full EU sample is attenuated to near-zero because many ban countries had no fur industry. This is informative but initially surprising. Bovine hide placebo shows a noisy positive coefficient — addressed by discussing rather than ignoring it.
- **Review feedback adopted:** Toned down overclaims in conclusion ("failed to reduce" → "geographic reallocation partially offset"). Added pre-trend evidence discussion. Made placebo interpretation more honest. Added caveat about cluster count and inference limitations.
