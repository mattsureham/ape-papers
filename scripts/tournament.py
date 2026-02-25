#!/usr/bin/env python3
"""
APE Tournament System
Head-to-head paper matches with TrueSkill ratings - Using Kimi K2.5 for judging
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime
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

# Simple TrueSkill-like rating system
class Rating:
    def __init__(self, mu=25.0, sigma=8.333):
        self.mu = mu
        self.sigma = sigma
    
    def __repr__(self):
        return f"Rating(mu={self.mu:.2f}, sigma={self.sigma:.2f})"
    
    @property
    def conservative(self):
        return self.mu - 3 * self.sigma

def update_ratings(winner_rating, loser_rating):
    """Update ratings after a match"""
    beta = 4.166
    diff = winner_rating.mu - loser_rating.mu
    c = (winner_rating.sigma**2 + loser_rating.sigma**2 + 2*beta**2)**0.5
    v = 1 / (1 + (2.71828**(-diff/c)))
    
    winner_rating.mu += (winner_rating.sigma**2 / c) * (1 - v)
    loser_rating.mu -= (loser_rating.sigma**2 / c) * (1 - v)
    
    winner_rating.sigma = (winner_rating.sigma**2 * (1 - (winner_rating.sigma**2/c**2)*v*(1-v)))**0.5
    loser_rating.sigma = (loser_rating.sigma**2 * (1 - (loser_rating.sigma**2/c**2)*v*(1-v)))**0.5

class KimiJudge:
    """Kimi K2.5 as judge"""
    def __init__(self, api_key=None):
        self.api_key = api_key or os.getenv("MOONSHOT_API_KEY")
        self.model = "moonshot-v1-8k"
        self.base_url = "https://api.moonshot.cn/v1"
    
    def judge(self, paper1, paper2):
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        prompt = f"""You are a senior editor at QJE/AER. Compare these two economics papers and declare a winner.

PAPER 1:
{paper1[:3500]}

---

PAPER 2:
{paper2[:3500]}

Evaluate on (score 1-10 each):
1. Identification strategy credibility
2. Novelty and originality
3. Policy relevance
4. Execution quality
5. Appropriate scope

Declare winner: Paper 1 or Paper 2. Be decisive and explain why."""
        
        response = requests.post(
            f"{self.base_url}/chat/completions",
            headers=headers,
            json={
                "model": self.model,
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 2048,
                "temperature": 0.3
            },
            timeout=120
        )
        response.raise_for_status()
        judgment = response.json()["choices"][0]["message"]["content"]
        
        # Determine winner
        response_lower = judgment.lower()
        if "paper 1" in response_lower or "paper1" in response_lower:
            return "paper1", judgment
        elif "paper 2" in response_lower or "paper2" in response_lower:
            return "paper2", judgment
        else:
            return "tie", judgment

def load_ratings():
    """Load tournament ratings from file"""
    ratings_file = Path(__file__).parent.parent / "tournaments" / "ratings.json"
    if ratings_file.exists():
        with open(ratings_file) as f:
            data = json.load(f)
            return {k: Rating(v['mu'], v['sigma']) for k, v in data.items()}
    return {}

def save_ratings(ratings):
    """Save tournament ratings to file"""
    ratings_file = Path(__file__).parent.parent / "tournaments" / "ratings.json"
    ratings_file.parent.mkdir(exist_ok=True)
    data = {k: {'mu': v.mu, 'sigma': v.sigma} for k, v in ratings.items()}
    with open(ratings_file, 'w') as f:
        json.dump(data, f, indent=2)

def run_match(paper1_id, paper2_id):
    """Run a tournament match between two papers"""
    project_dir = Path(__file__).parent.parent
    papers_dir = project_dir / "papers"
    
    p1_path = papers_dir / f"{paper1_id}.md"
    p2_path = papers_dir / f"{paper2_id}.md"
    
    if not p1_path.exists() or not p2_path.exists():
        print("❌ One or both papers not found")
        sys.exit(1)
    
    with open(p1_path) as f:
        paper1 = f.read()
    with open(p2_path) as f:
        paper2 = f.read()
    
    print(f"🏆 Match: {paper1_id} vs {paper2_id}")
    print("=" * 50)
    
    # Get ratings
    ratings = load_ratings()
    r1 = ratings.get(paper1_id, Rating())
    r2 = ratings.get(paper2_id, Rating())
    
    print(f"\nPre-match ratings:")
    print(f"  {paper1_id}: μ={r1.mu:.2f}, σ={r1.sigma:.2f} (conservative={r1.conservative:.2f})")
    print(f"  {paper2_id}: μ={r2.mu:.2f}, σ={r2.sigma:.2f} (conservative={r2.conservative:.2f})")
    
    # Judge with Kimi
    api_key = os.getenv("MOONSHOT_API_KEY")
    if not api_key:
        print("❌ MOONSHOT_API_KEY not set")
        sys.exit(1)
    
    try:
        judge = KimiJudge(api_key=api_key)
        winner, judgment = judge.judge(paper1, paper2)
        
        print(f"\n📝 Kimi K2.5 Judge's decision:")
        print(judgment[:600] + "...")
        
        # Update ratings
        if winner == "paper1":
            update_ratings(r1, r2)
            print(f"\n✅ Winner: {paper1_id}")
        elif winner == "paper2":
            update_ratings(r2, r1)
            print(f"\n✅ Winner: {paper2_id}")
        else:
            print(f"\n⚖️  Tie")
        
        # Save updated ratings
        ratings[paper1_id] = r1
        ratings[paper2_id] = r2
        save_ratings(ratings)
        
        print(f"\nPost-match ratings:")
        print(f"  {paper1_id}: μ={r1.mu:.2f}, σ={r1.sigma:.2f} (conservative={r1.conservative:.2f})")
        print(f"  {paper2_id}: μ={r2.mu:.2f}, σ={r2.sigma:.2f} (conservative={r2.conservative:.2f})")
        
        # Save match result
        matches_file = project_dir / "tournaments" / "matches.json"
        matches = []
        if matches_file.exists():
            with open(matches_file) as f:
                matches = json.load(f)
        
        matches.append({
            "paper1": paper1_id,
            "paper2": paper2_id,
            "winner": winner,
            "timestamp": datetime.now().isoformat()
        })
        
        with open(matches_file, 'w') as f:
            json.dump(matches, f, indent=2)
        
    except Exception as e:
        print(f"❌ Judging error: {e}")

def show_leaderboard():
    """Display tournament leaderboard"""
    ratings = load_ratings()
    
    if not ratings:
        print("No tournament data yet.")
        return
    
    print("🏆 APE Tournament Leaderboard")
    print("=" * 60)
    print(f"{'Rank':<6}{'Paper ID':<25}{'μ':<10}{'σ':<10}{'Rating':<10}")
    print("-" * 60)
    
    sorted_papers = sorted(ratings.items(), key=lambda x: x[1].conservative, reverse=True)
    
    for rank, (paper_id, rating) in enumerate(sorted_papers, 1):
        print(f"{rank:<6}{paper_id:<25}{rating.mu:<10.2f}{rating.sigma:<10.2f}{rating.conservative:<10.2f}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python tournament.py match [paper1_id] [paper2_id]")
        print("  python tournament.py leaderboard")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "match" and len(sys.argv) >= 4:
        run_match(sys.argv[2], sys.argv[3])
    elif command == "leaderboard":
        show_leaderboard()
    else:
        print("Invalid command")
        sys.exit(1)
