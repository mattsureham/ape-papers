# Initial Research Plan

See `projects/congressional_lm/PAPER_IDEA.md` for the full concept and `research_plan.md` for the execution summary.

## Core Question
How predictable is Congressional debate, and what does predictability reveal about deliberation?

## Method
Train GPT language model from scratch on 30 years of U.S. Congressional floor debate (1994-2024, 473M tokens). Use perplexity decomposed into three levels as measurement instruments.

## Analysis Plan
1. Perplexity time series by year and chamber
2. Deliberation Index (sampled, holdout 2015-2024)
3. Speaker identification accuracy (party and individual)
4. TF-IDF + SVM baselines for comparison
5. Four publication figures
