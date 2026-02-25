#!/usr/bin/env python3
"""
APE Paper Generator - Multi-Field Support
Generates academic papers for various fields
"""

import os
import sys
import json
import requests
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from smart_loader import load_directory

def load_env():
    env_path = Path(__file__).parent.parent / "config" / ".env"
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))

load_env()

class MoonshotProvider:
    """Moonshot AI Provider"""
    def __init__(self, api_key=None, model="moonshot-v1-8k"):
        self.api_key = api_key or os.getenv("MOONSHOT_API_KEY")
        self.model = model
        self.base_url = "https://api.moonshot.cn/v1"
    
    def generate(self, prompt, system="", max_tokens=8192):
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})
        
        response = requests.post(
            f"{self.base_url}/chat/completions",
            headers=headers,
            json={
                "model": self.model,
                "messages": messages,
                "max_tokens": max_tokens,
                "temperature": 0.7
            },
            timeout=120
        )
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]

def get_field_config(field):
    """Get configuration for different academic fields"""
    
    configs = {
        "economics": {
            "journal": "AER/QJE",
            "structure": ["Title", "Abstract", "Introduction", "Literature Review", "Empirical Strategy", "Data", "Results", "Conclusion"],
            "format": "LaTeX",
            "method_examples": "DiD, RDD, IV, RCT",
            "style": "Rigorous empirical analysis with causal identification"
        },
        "psychology": {
            "journal": "JPSP/Psychological Science",
            "structure": ["Title", "Abstract", "Introduction", "Method", "Results", "Discussion", "References"],
            "format": "APA style",
            "method_examples": "Experiment, Survey, Meta-analysis, Longitudinal",
            "style": "Clear hypothesis testing with statistical rigor"
        },
        "computer_science": {
            "journal": "ACM/IEEE",
            "structure": ["Title", "Abstract", "Introduction", "Related Work", "Method/Algorithm", "Experiments", "Results", "Conclusion"],
            "format": "LaTeX with code",
            "method_examples": "Algorithm design, Benchmark evaluation, A/B testing",
            "style": "Novel contribution with reproducible experiments"
        },
        "medicine": {
            "journal": "NEJM/Lancet",
            "structure": ["Title", "Abstract", "Background", "Methods", "Results", "Discussion", "Conclusion"],
            "format": "IMRaD format",
            "method_examples": "RCT, Cohort study, Case-control, Systematic review",
            "style": "Evidence-based with clinical significance"
        },
        "sociology": {
            "journal": "AJS/ASR",
            "structure": ["Title", "Abstract", "Introduction", "Theory", "Data/Methods", "Findings", "Discussion", "Conclusion"],
            "format": "Standard academic",
            "method_examples": "Ethnography, Survey, Interview, Content analysis",
            "style": "Theoretically grounded with rich description"
        },
        "political_science": {
            "journal": "APSR/AJPS",
            "structure": ["Title", "Abstract", "Introduction", "Theory", "Research Design", "Analysis", "Results", "Conclusion"],
            "format": "Standard academic",
            "method_examples": "Quantitative analysis, Case study, Text analysis",
            "style": "Theory-driven with political relevance"
        },
        "education": {
            "journal": "AERA/Review of Educational Research",
            "structure": ["Title", "Abstract", "Introduction", "Literature Review", "Methodology", "Findings", "Discussion", "Implications"],
            "format": "APA style",
            "method_examples": "Quasi-experiment, Survey, Interview, Mixed methods",
            "style": "Practice-relevant with policy implications"
        },
        "environmental_science": {
            "journal": "Nature Climate Change/Science",
            "structure": ["Title", "Abstract", "Introduction", "Methods", "Results", "Discussion", "Conclusion"],
            "format": "Scientific",
            "method_examples": "Modeling, Field measurements, Remote sensing, Lab experiments",
            "style": "Data-driven with environmental significance"
        }
    }
    
    return configs.get(field.lower(), configs["economics"])

def load_file_or_directory(path, is_data=True):
    """Load content from file or directory"""
    if not path:
        return ""
    
    p = Path(path)
    
    if p.is_dir():
        if is_data:
            data, _ = load_directory(data_dir=str(p))
            return data
        else:
            _, refs = load_directory(refs_dir=str(p))
            return refs
    elif p.is_file():
        with open(p, 'r', encoding='utf-8') as f:
            return f.read()
    else:
        print(f"⚠️  Path not found: {path}")
        return ""

def generate_paper(question, field="economics", method="", data_path=None, refs_path=None):
    """Generate academic paper for any field"""
    
    # Get field configuration
    config = get_field_config(field)
    
    # Load data and references
    print("📂 Loading data/references...")
    data_content = load_file_or_directory(data_path, is_data=True) if data_path else ""
    refs_content = load_file_or_directory(refs_path, is_data=False) if refs_path else ""
    
    # Use Moonshot
    api_key = os.getenv("MOONSHOT_API_KEY")
    if not api_key:
        print("❌ MOONSHOT_API_KEY not set")
        sys.exit(1)
    
    ai = MoonshotProvider(api_key=api_key)
    
    # Build field-specific system prompt
    system_prompt = f"""You are an expert researcher writing for top {field} journals ({config['journal']}).

Paper Structure: {', '.join(config['structure'])}
Format: {config['format']}
Style: {config['style']}

Methodology examples for this field: {config['method_examples']}

CRITICAL: Use the provided REAL DATA. Do not fabricate numbers."""

    # Build prompt
    prompt = f"""Research Question: {question}

Field: {field}
Methodology: {method if method else 'Appropriate for the field'}"""
    
    if data_content:
        prompt += f"""

REAL DATA TO INCORPORATE:
```
{data_content[:8000]}
```"""
    
    if refs_content:
        prompt += f"""

REFERENCES TO CITE:
```
{refs_content[:5000]}
```"""
    
    prompt += f"""

Generate a complete {field} research paper with:
{chr(10).join([f"{i+1}. {section}" for i, section in enumerate(config['structure'])])}

Use {config['format']} formatting appropriate for the field."""
    
    print(f"📝 Generating {field} paper: {question}")
    if method:
        print(f"   Method: {method}")
    if data_path:
        print(f"   Data: {data_path}")
    if refs_path:
        print(f"   References: {refs_path}")
    
    try:
        paper = ai.generate(prompt, system_prompt, max_tokens=8192)
        
        # Save paper
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        paper_id = f"apep_{timestamp}"
        papers_dir = Path(__file__).parent.parent / "papers"
        papers_dir.mkdir(exist_ok=True)
        
        filepath = papers_dir / f"{paper_id}.md"
        with open(filepath, 'w') as f:
            f.write(f"# {question}\n\n")
            f.write(f"**Field:** {field}\n")
            if method:
                f.write(f"**Method:** {method}\n")
            f.write(f"**Provider:** moonshot\n")
            f.write(f"**ID:** {paper_id}\n")
            if data_path:
                f.write(f"**Data Source:** {data_path}\n")
            if refs_path:
                f.write(f"**References:** {refs_path}\n")
            f.write("\n---\n\n")
            f.write(paper)
        
        print(f"✅ Paper saved: {filepath}")
        print(f"   ID: {paper_id}")
        return paper_id
        
    except Exception as e:
        print(f"❌ Error: {e}")
        raise

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("APE Multi-Field Paper Generator")
        print("==============================")
        print("")
        print("Usage:")
        print("  python generate_paper.py 'Question' [field] [method] [data_path] [refs_path]")
        print("")
        print("Supported fields:")
        print("  economics, psychology, computer_science, medicine,")
        print("  sociology, political_science, education, environmental_science")
        print("")
        print("Examples:")
        print('  # Economics (default)')
        print('  python generate_paper.py "Min wage effects" economics DiD data/ refs/')
        print("")
        print('  # Psychology')
        print('  python generate_paper.py "Social media impact on anxiety" psychology "Survey experiment" data/ refs/')
        print("")
        print('  # Computer Science')
        print('  python generate_paper.py "New sorting algorithm" computer_science "Benchmark evaluation" data/ refs/')
        print("")
        print('  # Medicine')
        print('  python generate_paper.py "Drug effectiveness" medicine "RCT" data/ refs/')
        sys.exit(1)
    
    question = sys.argv[1]
    field = sys.argv[2] if len(sys.argv) > 2 else "economics"
    method = sys.argv[3] if len(sys.argv) > 3 else ""
    data_path = sys.argv[4] if len(sys.argv) > 4 else None
    refs_path = sys.argv[5] if len(sys.argv) > 5 else None
    
    generate_paper(question, field, method, data_path, refs_path)
