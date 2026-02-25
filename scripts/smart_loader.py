#!/usr/bin/env python3
"""
Smart Data/References Loader
Handles directories and multiple file formats

Supports:
- Data: CSV, JSON, TXT, MD, Excel (.xlsx, .xls)
- References: PDF, TXT, MD, DOCX (if available)
"""

import os
import sys
import json
import csv
from pathlib import Path

# Optional imports
try:
    import pandas as pd
    HAS_PANDAS = True
except ImportError:
    HAS_PANDAS = False

try:
    import PyPDF2
    HAS_PYPDF2 = True
except ImportError:
    HAS_PYPDF2 = False

try:
    from docx import Document
    HAS_DOCX = True
except ImportError:
    HAS_DOCX = False


class SmartLoader:
    """Load and process data/references from various formats"""
    
    def __init__(self, directory, is_data_dir=True):
        self.dir = Path(directory)
        self.is_data_dir = is_data_dir  # True for data, False for references
        self.content = []
    
    def load_all(self):
        """Load all supported files from directory"""
        if not self.dir.exists():
            print(f"⚠️  Directory not found: {self.dir}")
            return ""
        
        files = list(self.dir.iterdir())
        print(f"📁 Scanning {len(files)} files in {self.dir}...")
        
        for f in files:
            if f.is_file():
                self._process_file(f)
        
        result = "\n\n".join(self.content) if self.content else ""
        print(f"   Files loaded: {len(self.content)}")
        
        return result
    
    def _process_file(self, filepath):
        """Process a single file based on extension"""
        ext = filepath.suffix.lower()
        
        if self.is_data_dir:
            # Loading data files
            if ext in ['.csv']:
                self._load_csv(filepath)
            elif ext in ['.json']:
                self._load_json(filepath)
            elif ext in ['.xlsx', '.xls'] and HAS_PANDAS:
                self._load_excel(filepath)
            elif ext in ['.txt', '.md', '.data']:
                self._load_text(filepath)
        else:
            # Loading reference files
            if ext == '.pdf' and HAS_PYPDF2:
                self._load_pdf(filepath)
            elif ext == '.docx' and HAS_DOCX:
                self._load_docx(filepath)
            elif ext in ['.txt', '.md', '.bib', '.refs']:
                self._load_text(filepath)
    
    def _load_csv(self, filepath):
        """Load CSV file"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                rows = list(reader)
                
            if rows:
                content = f"### Data from {filepath.name}\n\n"
                content += "| " + " | ".join(rows[0]) + " |\n"
                content += "|" + "|".join(["---" for _ in rows[0]]) + "|\n"
                for row in rows[1:20]:
                    content += "| " + " | ".join(row) + " |\n"
                if len(rows) > 20:
                    content += f"\n*({len(rows) - 20} more rows)*\n"
                
                self.content.append(content)
                print(f"   📊 Loaded CSV: {filepath.name}")
        except Exception as e:
            print(f"   ⚠️  Error loading {filepath.name}: {e}")
    
    def _load_json(self, filepath):
        """Load JSON file"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            content = f"### Data from {filepath.name}\n\n```json\n"
            content += json.dumps(data, indent=2)[:5000]
            content += "\n```\n"
            
            self.content.append(content)
            print(f"   📊 Loaded JSON: {filepath.name}")
        except Exception as e:
            print(f"   ⚠️  Error loading {filepath.name}: {e}")
    
    def _load_excel(self, filepath):
        """Load Excel file"""
        try:
            df = pd.read_excel(filepath)
            content = f"### Data from {filepath.name}\n\n"
            content += df.to_markdown(index=False)[:5000]
            self.content.append(content)
            print(f"   📊 Loaded Excel: {filepath.name}")
        except Exception as e:
            print(f"   ⚠️  Error loading {filepath.name}: {e}")
    
    def _load_pdf(self, filepath):
        """Extract text from PDF"""
        if not HAS_PYPDF2:
            return
        
        try:
            text = ""
            with open(filepath, 'rb') as f:
                reader = PyPDF2.PdfReader(f)
                for page in reader.pages[:5]:
                    text += page.extract_text() + "\n"
            
            content = f"### Reference from {filepath.name}\n\n{text[:8000]}"
            self.content.append(content)
            print(f"   📄 Loaded PDF: {filepath.name}")
        except Exception as e:
            print(f"   ⚠️  Error loading {filepath.name}: {e}")
    
    def _load_docx(self, filepath):
        """Load Word document"""
        if not HAS_DOCX:
            return
        
        try:
            doc = Document(filepath)
            text = "\n".join([para.text for para in doc.paragraphs])
            
            content = f"### Reference from {filepath.name}\n\n{text[:8000]}"
            self.content.append(content)
            print(f"   📄 Loaded DOCX: {filepath.name}")
        except Exception as e:
            print(f"   ⚠️  Error loading {filepath.name}: {e}")
    
    def _load_text(self, filepath):
        """Load plain text file"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                text = f.read()
            
            label = "Data" if self.is_data_dir else "Reference"
            content = f"### {label} from {filepath.name}\n\n{text[:8000]}"
            self.content.append(content)
            print(f"   📄 Loaded {label.lower()}: {filepath.name}")
        except Exception as e:
            print(f"   ⚠️  Error loading {filepath.name}: {e}")


def load_directory(data_dir=None, refs_dir=None):
    """Load data and references from directories"""
    data = ""
    refs = ""
    
    if data_dir:
        print(f"📂 Loading data from: {data_dir}")
        loader = SmartLoader(data_dir, is_data_dir=True)
        data = loader.load_all()
    
    if refs_dir:
        print(f"📂 Loading references from: {refs_dir}")
        loader = SmartLoader(refs_dir, is_data_dir=False)
        refs = loader.load_all()
    
    return data, refs


if __name__ == "__main__":
    # Test
    if len(sys.argv) > 1:
        data_dir = sys.argv[1] if len(sys.argv) > 1 else None
        refs_dir = sys.argv[2] if len(sys.argv) > 2 else None
        
        data, refs = load_directory(data_dir, refs_dir)
        
        print("\n" + "="*50)
        print("DATA:")
        print(data[:500] if data else "(No data)")
        print("\n" + "="*50)
        print("REFERENCES:")
        print(refs[:500] if refs else "(No references)")
