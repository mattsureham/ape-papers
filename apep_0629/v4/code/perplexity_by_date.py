#!/usr/bin/env python3
"""
Compute per-date perplexity using the base model.

Groups conversations by date and chamber, computes mean cross-entropy loss.
Only evaluates holdout data (2015-2024).

Output: results/daily_perplexity.parquet

Usage:
    python perplexity_by_date.py --checkpoint data/checkpoints/congressional_d6_v2/best.pt
    python perplexity_by_date.py --checkpoint data/checkpoints/congressional_d6_v2/best.pt --device cpu
"""

import argparse
import math
import random
import sys
import time
from pathlib import Path

import polars as pl
import torch
import torch.nn.functional as F

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
RESULTS_DIR = PROJECT_ROOT / "results"
sys.path.insert(0, str(PROJECT_ROOT / "_nanochat"))

# Reuse model loading from perplexity_by_year
from perplexity_by_year import load_model_and_tokenizer


@torch.no_grad()
def compute_perplexity_simple(model, tokenizer, texts: list[str],
                                device: str, seq_len: int = 2048,
                                n_batches: int = 20, batch_size: int = 4) -> dict:
    """Compute perplexity on a list of texts.

    Simpler than perplexity_by_year: fewer batches (speed over precision for daily).
    For days with very little text, uses all available tokens.
    """
    all_tokens = []
    for text in texts:
        tokens = tokenizer.enc.encode(text, allowed_special="all")
        all_tokens.extend(tokens)

    n_tokens = len(all_tokens)
    if n_tokens < seq_len + 1:
        return {"loss": float("nan"), "ppl": float("nan"), "n_tokens": n_tokens}

    tokens_tensor = torch.tensor(all_tokens, dtype=torch.long)
    max_start = len(tokens_tensor) - seq_len - 1

    # Scale batches to available data
    effective_batches = min(n_batches, max(1, max_start // (seq_len // 2)))

    total_loss = 0.0
    for _ in range(effective_batches):
        starts = [random.randint(0, max_start) for _ in range(batch_size)]
        x = torch.stack([tokens_tensor[s : s + seq_len] for s in starts]).to(device)
        y = torch.stack([tokens_tensor[s + 1 : s + seq_len + 1] for s in starts]).to(device)

        logits = model(x)
        loss = F.cross_entropy(logits.view(-1, logits.size(-1)), y.view(-1))
        total_loss += loss.item()

    avg_loss = total_loss / effective_batches
    ppl = math.exp(min(avg_loss, 20))

    return {"loss": avg_loss, "ppl": ppl, "n_tokens": n_tokens, "n_batches": effective_batches}


def main():
    parser = argparse.ArgumentParser(description="Per-date perplexity evaluation")
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--tokenizer-dir", default=str(DATA_DIR / "tokenizer_v2"))
    parser.add_argument("--depth", type=int, default=6)
    parser.add_argument("--device", default="mps")
    parser.add_argument("--n-batches", type=int, default=20)
    parser.add_argument("--batch-size", type=int, default=4)
    args = parser.parse_args()

    model, tokenizer = load_model_and_tokenizer(
        args.checkpoint, args.tokenizer_dir, args.depth, args.device
    )

    # Load holdout conversations only
    print("Loading holdout conversations...", flush=True)
    val_df = pl.read_parquet(DATA_DIR / "conversations_val_full.parquet")
    print(f"  {len(val_df)} conversations, {val_df['year'].min()}-{val_df['year'].max()}", flush=True)

    # Group by date only (both chambers combined — event study needs aggregate)
    date_groups = (
        val_df.group_by("date")
        .agg(
            pl.col("text").alias("texts"),
            pl.len().alias("n_convos"),
        )
        .sort("date")
    )
    print(f"  {len(date_groups)} date groups", flush=True)

    results = []
    t0 = time.time()

    for i, row in enumerate(date_groups.iter_rows(named=True)):
        date_val = row["date"]
        texts = row["texts"]

        metrics = compute_perplexity_simple(
            model, tokenizer, texts, args.device,
            n_batches=args.n_batches, batch_size=args.batch_size,
        )

        results.append({
            "date": date_val,
            "chamber": "ALL",
            "n_conversations": row["n_convos"],
            **metrics,
        })

        if (i + 1) % 100 == 0:
            elapsed = time.time() - t0
            ppl_str = f"{metrics['ppl']:.1f}" if not math.isnan(metrics["ppl"]) else "N/A"
            print(f"  [{i+1}/{len(date_groups)}] {date_val}: "
                  f"PPL={ppl_str}, {elapsed:.0f}s elapsed", flush=True)

    # Save
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    results_df = pl.DataFrame(results)
    out_path = RESULTS_DIR / "daily_perplexity.parquet"
    results_df.write_parquet(out_path)

    total_time = time.time() - t0
    valid = results_df.filter(~pl.col("ppl").is_nan())
    print(f"\nDone in {total_time:.0f}s")
    print(f"Saved {len(results_df)} rows to {out_path}")
    print(f"  Valid PPL measurements: {len(valid)}")
    print(f"  Date range: {results_df['date'].min()} to {results_df['date'].max()}")
    print(f"  Mean PPL (ALL): {valid.filter(pl.col('chamber') == 'ALL')['ppl'].mean():.1f}")


if __name__ == "__main__":
    main()
