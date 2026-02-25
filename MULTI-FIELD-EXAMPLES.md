# APE Pipeline - Multi-Field Examples

## Yes! APE Now Works for Multiple Academic Fields

Each field has:
- **Proper paper structure** (field-specific)
- **Appropriate formatting** (APA, LaTeX, etc.)
- **Relevant methodology** examples
- **Journal-appropriate style**

---

## Quick Examples

### 1. Economics (Original)
```bash
./ape.sh generate-field "Minimum wage effects" economics DiD
```
**Output:** LaTeX paper with DiD methodology, AER style

---

### 2. Psychology
```bash
./ape.sh generate-field "Social media and anxiety" psychology "Longitudinal survey"
```
**Output:** APA-style paper with:
- Abstract, Method, Results, Discussion
- Statistical analyses (F-tests, correlations)
- Proper references (Mojtabai, Primack, Spielberger)

---

### 3. Computer Science
```bash
./ape.sh generate-field "New graph neural network" computer_science "Benchmark evaluation"
```
**Output:** ACM-style paper with:
- Algorithm pseudocode
- LaTeX algorithms
- Benchmark results tables
- Citation format: \cite{author}

---

### 4. Medicine
```bash
./ape.sh generate-field "Drug X effectiveness" medicine "RCT"
```
**Output:** NEJM-style paper with:
- Background, Methods, Results
- IMRaD format
- Clinical significance discussion

---

### 5. Sociology
```bash
./ape.sh generate-field "Gentrification effects" sociology "Ethnography"
```
**Output:** ASR-style paper with:
- Theory section
- Rich qualitative description
- Policy implications

---

### 6. Political Science
```bash
./ape.sh generate-field "Voting behavior" political_science "Quantitative analysis"
```
**Output:** APSR-style paper with:
- Theory-driven framework
- Political relevance
- Quantitative analysis

---

### 7. Education
```bash
./ape.sh generate-field "Online learning outcomes" education "Quasi-experiment"
```
**Output:** AERA-style paper with:
- Practice-relevant findings
- Policy implications
- Mixed methods approach

---

### 8. Environmental Science
```bash
./ape.sh generate-field "Climate change impacts" environmental_science "Modeling"
```
**Output:** Nature-style paper with:
- Data-driven analysis
- Environmental significance
- Scientific rigor

---

## With Data & References (Any Field)

```bash
# Create directories
mkdir -p myproject/data myproject/refs

# Add field-specific data
cp survey_results.csv myproject/data/
cp experiment_notes.txt myproject/data/
cp references.pdf myproject/refs/

# Generate with data
./ape.sh generate-dir "Your question" psychology "Survey" myproject/data/ myproject/refs/
```

---

## Field-Specific Features

| Field | Paper Structure | Special Features |
|-------|----------------|------------------|
| Economics | Title, Abstract, Intro, Lit Review, Empirical Strategy, Data, Results, Conclusion | LaTeX, causal inference focus |
| Psychology | Title, Abstract, Intro, Method, Results, Discussion | APA style, statistical tests |
| Computer Science | Title, Abstract, Intro, Related Work, Method, Experiments, Results | Algorithms, benchmarks, code |
| Medicine | Title, Abstract, Background, Methods, Results, Discussion | IMRaD, clinical focus |
| Sociology | Title, Abstract, Intro, Theory, Data/Methods, Findings, Discussion | Theoretical grounding |
| Political Science | Title, Abstract, Intro, Theory, Research Design, Analysis | Theory-driven |
| Education | Title, Abstract, Intro, Lit Review, Methodology, Findings | Practice-relevant |
| Environmental Science | Title, Abstract, Intro, Methods, Results, Discussion | Data-driven, environmental focus |

---

## All Supported Fields

```bash
./ape.sh fields
```

Shows all 8 supported fields with journal targets and methodology examples.

---

**The pipeline adapts to your field automatically!** 🎉
