#!/usr/bin/env python3
"""
APE Paper Reviewer
Multi-model review using Moonshot Kimi
"""

import os
import sys
import json
from pathlib import Path
import requests

# Load config
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
    """Moonshot AI Provider (Kimi K2.5)"""
    def __init__(self, api_key=None, model="moonshot-v1-8k"):
        self.api_key = api_key or os.getenv("MOONSHOT_API_KEY")
        self.model = model
        self.base_url = "https://api.moonshot.cn/v1"
    
    def generate(self, prompt, system="", max_tokens=4096):
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
                "temperature": 0.5
            },
            timeout=120
        )
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]

def review_paper(paper_id):
    """Review a paper with Kimi K2.5"""
    
    project_dir = Path(__file__).parent.parent
    papers_dir = project_dir / "papers"
    paper_path = papers_dir / f"{paper_id}.md"
    
    if not paper_path.exists():
        print(f"❌ Paper not found: {paper_id}")
        sys.exit(1)
    
    with open(paper_path) as f:
        paper = f.read()
    
    print(f"🔍 Reviewing paper: {paper_id}")
    print("=" * 50)
    
    # Initialize Kimi
    api_key = os.getenv("MOONSHOT_API_KEY")
    if not api_key:
        print("❌ MOONSHOT_API_KEY not set")
        sys.exit(1)
    
    kimi = MoonshotProvider(api_key=api_key)
    
    # Review 1: Methodology
    print("\n📊 Kimi K2.5 - Methodology Review:")
    try:
        review = kimi.generate(
            prompt=f"Review this paper's methodology:\n\n{paper[:4000]}",
            system="You are a research methods expert. Check for: 1) Identification strategy credibility, 2) Data quality, 3) Statistical approach, 4) Potential biases. Be critical and specific.",
            max_tokens=2048
        )
        print(review[:800] + "...")
        
        # Save review
        reviews_dir = project_dir / "papers" / "reviews"
        reviews_dir.mkdir(exist_ok=True)
        
        review_file = reviews_dir / f"{paper_id}_methodology.md"
        with open(review_file, 'w') as f:
            f.write(f"# Methodology Review: {paper_id}\n\n")
            f.write(review)
        
    except Exception as e:
        print(f"⚠️  Review error: {e}")
    
    # Review 2: Fact Check
    print("\n🔎 Kimi K2.5 - Fact Check:")
    try:
        review = kimi.generate(
            prompt=f"Check this paper for factual errors and claims:\n\n{paper[:4000]}",
            system="You verify academic claims. Check for: 1) Statistical consistency, 2) Citation quality, 3) Logical coherence, 4) Potential hallucinations.",
            max_tokens=2048
        )
        print(review[:800] + "...")
        
        # Save review
        review_file = reviews_dir / f"{paper_id}_factcheck.md"
        with open(review_file, 'w') as f:
            f.write(f"# Fact Check: {paper_id}\n\n")
            f.write(review)
        
    except Exception as e:
        print(f"⚠️  Fact check error: {e}")
    
    # Review 3: Writing Quality
    print("\n✍️  Kimi K2.5 - Writing Quality:")
    try:
        review = kimi.generate(
            prompt=f"Evaluate the writing quality of this paper:\n\n{paper[:3000]}",
            system="You are an academic editor. Evaluate: 1) Clarity, 2) Organization, 3) Academic tone, 4) LaTeX formatting. Give specific improvement suggestions.",
            max_tokens=2048
        )
        print(review[:600] + "...")
        
        # Save review
        review_file = reviews_dir / f"{paper_id}_writing.md"
        with open(review_file, 'w') as f:
            f.write(f"# Writing Review: {paper_id}\n\n")
            f.write(review)
        
    except Exception as e:
        print(f"⚠️  Writing review error: {e}")
    
    print("\n✅ Review complete")
    print(f"   Reviews saved to: {reviews_dir}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python review_paper.py [paper_id]")
        print("Example: python review_paper.py apep_20260225_155335")
        sys.exit(1)
    
    review_paper(sys.argv[1])
