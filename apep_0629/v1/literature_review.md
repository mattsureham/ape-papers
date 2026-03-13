# Literature Review

## Novelty Check

No existing paper combines: (1) autoregressive language model, (2) trained from scratch on legislative text, (3) used for measurement (not classification).

### Closest precedents:
- **Zhou et al. (2024, PNAS Nexus):** Fine-tuned GPT-2 on presidential speeches for speaker uniqueness. Different: fine-tuned (contaminated), speaker-level (not conversational), presidential (not legislative).
- **Gentzkow, Shapiro & Taddy (2019, Econometrica):** Vocabulary divergence classifier. Different: bag-of-words (not sequential), classification (not measurement), cannot distinguish theater from debate.
- **Steiner et al. (2004):** Discourse Quality Index. Right concept but manual coding, small samples.
- **RooseBERT, ParlBERT, PoliBERTweet:** BERT-family (masked, not autoregressive). Used for classification, cannot compute perplexity.

## Conclusion
The gap is clear: no autoregressive + from-scratch + measurement approach exists in the literature.
