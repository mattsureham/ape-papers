# Prose Review — Gemini 3 Flash (Round 1)

**Role:** Prose editor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T16:46:24.603110
**Route:** Direct Google API + PDF
**Tokens:** 19079 in / 1175 out
**Response SHA256:** aa26398576b64173

---

# Section-by-Section Review

## The Opening
**Verdict:** Slow start. Needs a more striking hook.
The current opening is a dry statement of fact: "India’s Parliament and state legislatures are among the wealthiest in the world." While true, it lacks the Shleifer "vivid observation." 

**Suggestion:** Start with the specific contrast found in your results—the "four times" wealth gap. 
*Draft:* "In the typical Indian legislative race, the wealthier candidate possesses four times the assets of their closest rival. This massive disparity suggests a plutocracy where money buys entry, yet in the closest elections, this wealth advantage vanishes entirely."

## Introduction
**Verdict:** Solid but improvable. It follows the "Shleifer arc" well but gets bogged down in data sources too early.
The transition from the "fundamental question" to "This paper uses a regression discontinuity design" is a bit abrupt. You describe the data sources (DataMeet, ADR) in the middle of the introduction (page 2), which kills the narrative momentum. Move the specific archive names to the Data section. 

**Katz-style improvement:** When previewing results on page 3, don't just say "the elected representative's declared assets are roughly four times higher." Tell us what that means for the legislature: "Electing the wealthier candidate doesn't just change a name on a ballot; it shifts the economic profile of the legislature toward a class of citizens whose net worth is orders of magnitude removed from the median voter."

## Background / Institutional Context
**Verdict:** Vivid and necessary. 
The description of the Supreme Court battle and the "Representation of the People Act" (page 6) is excellent. It creates a sense of "human stakes" (Glaeser-style) by showing the political establishment's resistance to transparency. 
**Trim:** Section 3.3 (State Assembly Elections) feels a bit like a textbook. You can condense the number of members in Puducherry vs. UP into a single sentence about the scale of the Indian democratic exercise.

## Data
**Verdict:** Reads as an inventory.
Page 8 describes the "Asset Parsing Algorithm" in the text. This is a technical triumph but a narrative failure. 
**Rewrite:** "Measuring wealth in India requires more than just reading a table; it requires a parser to decode the idiosyncratic Indian numeral system and its suffixes." Put the "floor of the parsed amount" logic in the appendix. Keep the focus on the *fact* that we now have a window into candidate pockets that was previously shuttered.

## Empirical Strategy
**Verdict:** Clear to non-specialists.
The "Two Channels" (Resource Advantage vs. Voter Preference) on pages 10-11 is the strongest part of the paper's logic. It makes the RDD feel "inevitable."
**Shleifer touch:** The paragraph starting "A third possibility..." on page 11 is perfect—it anticipates the objection and dispatches it with one clean stroke of the RDD logic.

## Results
**Verdict:** Tells a story.
The discussion of Figure 3 (The Disappearing Wealth Premium) is the "punchline" of the paper. 
**Specific Critique:** On page 15, you write: "The 95% confidence interval is [1.112, 1.641]." This is too much "table narration." 
**Rewrite:** "The effect is not just statistically significant, but economically massive: a victory for the wealthier candidate quadruples the assets of the district's representative."

## Discussion / Conclusion
**Verdict:** Resonates.
The final sentence—"the composition of legislatures is shaped not only by what voters want, but by who has the resources to run a competitive campaign in the first place"—is classic Shleifer. It reframes the whole paper from a technical RDD into a meditation on the limits of democracy.

---

## Overall Writing Assessment

- **Current level:** Close but needs polish.
- **Greatest strength:** The "Conceptual Framework" (Section 5.1) which sets up a perfect horse race between two competing theories.
- **Greatest weakness:** Technical "throat-clearing" in the data and results sections (mentioning package names like `rdrobust` in the main flow).
- **Shleifer test:** Yes. The logic is clear enough for any smart reader to follow.

- **Top 5 concrete improvements:**
  1. **Kill the "Package" talk:** Move "I use the rdrobust package" and "triangular kernel weighting" to a footnote or the appendix. A Shleifer paper is about ideas, not software.
  2. **Vivid Opening:** Replace the generic "India's Parliament is wealthy" with a specific anecdote or the striking "4x wealth" statistic.
  3. **Narrative Data:** "I develop a parser that correctly decomposes these concatenated strings..." (page 8) is too technical. Replace with: "I reconstruct the financial profiles of 76,000 candidates by decoding mandatory disclosure affidavits."
  4. **Active Results:** Instead of "Table 3 quantifies the discontinuity" (page 15), use "Winning the election translates the candidate’s personal fortune into the district’s political representation."
  5. **Glaeser-ize the Stakes:** In the "Policy Implications" (page 24), emphasize that the current system effectively "taxes" the entry of the non-wealthy into public service.