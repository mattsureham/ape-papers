# APE Pipeline - Directory Support Guide

## 🎉 New Feature: Load Data & References from Directories

You can now pass entire directories of files instead of individual files!

## Command Format

```bash
./ape.sh generate-dir "Question" Method data_dir/ refs_dir/
```

## Supported Formats

### 📊 Data Directory

| Format | How It's Processed |
|--------|-------------------|
| **CSV** | Converted to Markdown tables |
| **JSON** | Formatted as JSON blocks |
| **Excel (.xlsx/.xls)** | Converted to Markdown tables |
| **TXT / MD** | Plain text inclusion |

### 📄 References Directory

| Format | How It's Processed |
|--------|-------------------|
| **PDF** | Text extracted from first 5 pages |
| **TXT / MD** | Plain text inclusion |
| **DOCX** | Text extracted from document |

## Quick Start Example

```bash
cd /Users/matthew/.openclaw/workspace/ape-pipeline

# Create directories
mkdir -p myproject/data myproject/refs

# Add data files (multiple formats supported!)
cp my_data.csv myproject/data/
cp policy_info.json myproject/data/
cp extra_notes.txt myproject/data/

# Add reference files
cp card_kruger_1994.pdf myproject/refs/
cp bibliography.txt myproject/refs/
cp citations.md myproject/refs/

# Generate paper with ALL files
./ape.sh generate-dir "Minimum wage effects" DiD myproject/data/ myproject/refs/
```

## Real Example

The `examples/` directory shows it working:

```
examples/
├── data_dir/
│   ├── employment.csv    # Employment data by state/year
│   ├── policy.json       # Policy details (dates, wages)
│   └── notes.txt         # Key facts and context
└── refs_dir/
    ├── card_kruger.txt   # Citation with key finding
    └── citations.md      # List of important papers
```

### Generated Output

The AI properly:
- ✅ Created LaTeX tables from CSV data
- ✅ Included JSON policy info
- ✅ Added notes as context
- ✅ Cited references in literature review
- ✅ **CALCULATED actual DiD estimate** from the data!

## Benefits

1. **Organize by project**: Keep all data/refs in one place
2. **Multiple files**: No need to merge files manually
3. **Any format**: Mix CSV, JSON, Excel, PDF, TXT as needed
4. **Automatic processing**: AI reads and understands all files

## Tips

- **Name files clearly**: `employment_1991_1993.csv` > `data.csv`
- **Limit file sizes**: Very large files may be truncated
- **PDFs**: Only first 5 pages extracted (for speed)
- **Excel**: First sheet only

## Full Workflow

```bash
# 1. Create project structure
mkdir -p projects/min_wage/{data,refs}

# 2. Download real data
# - QWI data → save as data/qwi_nj_pa.csv
# - Policy dates → save as data/policy.json

# 3. Collect references
# - Download PDFs → save to refs/
# - Copy citations → save as refs/bib.txt

# 4. Generate
./ape.sh generate-dir "Min wage effects on fast food" DiD \
  projects/min_wage/data/ \
  projects/min_wage/refs/

# 5. Review
./ape.sh review apep_20260225_xxxxxx

# 6. Tournament
./ape.sh tournament apep_xxxx apep_yyyy
```

**Now you can organize papers with real data and references easily!** 🦆
