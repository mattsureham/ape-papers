# Research Plan

Full paper concept: `projects/congressional_lm/PAPER_IDEA.md`
Training strategy: `projects/congressional_lm/TRAINING_STRATEGY.md`
Session guide: `projects/congressional_lm/SKILL.md`
Replication guide: `projects/congressional_lm/REPLICATION.md`

## Core Question
How predictable is Congressional debate, and what does predictability reveal about deliberation?

## Method
Train a GPT language model from scratch on 30 years of U.S. Congressional floor debate (1994-2024, 473M tokens). Use perplexity decomposed into three levels (conditional H_c, marginal H_m, Deliberation Index D = H_m - H_c) as measurement instruments.

## Analysis (completed)
1. Perplexity time series by year and chamber (House vs Senate)
2. Deliberation Index (sampled, 832 turns, holdout 2015-2024)
3. Speaker identification accuracy (party and individual, by year)
4. TF-IDF + SVM baselines for comparison
5. Four publication figures
