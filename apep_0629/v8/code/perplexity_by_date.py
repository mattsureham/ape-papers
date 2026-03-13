#!/usr/bin/env python3
"""
Compute per-date perplexity using the base model.

Scores each conversation individually (respecting speaker tokens, turn structure,
and conversation boundaries), then aggregates to daily level weighted by token count.

Uses exhaustive non-overlapping windows — every token scored exactly once.

Output: results/daily_perplexity.parquet

Usage:
    python perplexity_by_date.py --checkpoint data/checkpoints/congressional_d6_v2/best.pt
    python perplexity_by_date.py --checkpoint data/checkpoints/congressional_d6_v2/best.pt --device cpu
"""

import argparse
import math
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

from perplexity_by_year import load_model_and_tokenizer


@torch.no_grad()
def score_conversation(model, tokenizer, text: str, device: str,
                       seq_len: int = 2048) -> dict:
    """Score a single conversation using non-overlapping windows.

    Tokenizes the conversation (preserving speaker tokens and structure),
    then slides non-overlapping windows across it. Every token is scored
    exactly once.

    Returns dict with total_loss (sum of per-token losses), n_tokens_scored,
    and conversation-level perplexity.
    """
    tokens = tokenizer.enc.encode(text, allowed_special="all")
    n_tokens = len(tokens)

    if n_tokens < 2:
        return {"loss": float("nan"), "ppl": float("nan"),
                "n_tokens": n_tokens, "n_tokens_scored": 0}

    tokens_tensor = torch.tensor(tokens, dtype=torch.long)

    total_loss_sum = 0.0  # sum of (loss * n_predictions) across windows
    total_predictions = 0

    # Non-overlapping windows
    pos = 0
    while pos < n_tokens - 1:
        end = min(pos + seq_len, n_tokens)
        window = tokens_tensor[pos:end]

        if len(window) < 2:
            break

        x = window[:-1].unsqueeze(0).to(device)
        y = window[1:].unsqueeze(0).to(device)

        logits = model(x)
        loss = F.cross_entropy(logits.view(-1, logits.size(-1)), y.view(-1))

        n_preds = y.shape[1]
        total_loss_sum += loss.item() * n_preds
        total_predictions += n_preds

        pos = end  # non-overlapping: advance to end of window

    if total_predictions == 0:
        return {"loss": float("nan"), "ppl": float("nan"),
                "n_tokens": n_tokens, "n_tokens_scored": 0}

    avg_loss = total_loss_sum / total_predictions
    ppl = math.exp(min(avg_loss, 20))

    return {"loss": avg_loss, "ppl": ppl,
            "n_tokens": n_tokens, "n_tokens_scored": total_predictions}


def main():
    parser = argparse.ArgumentParser(description="Per-date perplexity (conversation-level)")
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--tokenizer-dir", default=str(DATA_DIR / "tokenizer_v2"))
    parser.add_argument("--depth", type=int, default=6)
    parser.add_argument("--device", default="mps")
    args = parser.parse_args()

    model, tokenizer = load_model_and_tokenizer(
        args.checkpoint, args.tokenizer_dir, args.depth, args.device
    )

    # Load holdout conversations only
    print("Loading holdout conversations...", flush=True)
    val_df = pl.read_parquet(DATA_DIR / "conversations_val_full.parquet")
    print(f"  {len(val_df)} conversations, {val_df['year'].min()}-{val_df['year'].max()}", flush=True)

    results = []
    t0 = time.time()
    total_tokens_scored = 0
    total_conversations_scored = 0

    # Process each conversation individually, accumulate per-date
    # Sort by date for streaming aggregation
    val_df = val_df.sort("date")
    dates = val_df["date"].unique().sort().to_list()
    print(f"  {len(dates)} unique dates", flush=True)

    for date_idx, date_val in enumerate(dates):
        day_df = val_df.filter(pl.col("date") == date_val)
        texts = day_df["text"].to_list()

        # Score each conversation, aggregate weighted by tokens scored
        day_loss_sum = 0.0
        day_tokens_scored = 0
        day_tokens_total = 0
        n_valid_convos = 0

        for text in texts:
            metrics = score_conversation(model, tokenizer, text, args.device)
            day_tokens_total += metrics["n_tokens"]

            if not math.isnan(metrics["loss"]):
                day_loss_sum += metrics["loss"] * metrics["n_tokens_scored"]
                day_tokens_scored += metrics["n_tokens_scored"]
                n_valid_convos += 1

        if day_tokens_scored > 0:
            avg_loss = day_loss_sum / day_tokens_scored
            ppl = math.exp(min(avg_loss, 20))
        else:
            avg_loss = float("nan")
            ppl = float("nan")

        results.append({
            "date": date_val,
            "chamber": "ALL",
            "n_conversations": len(texts),
            "n_conversations_scored": n_valid_convos,
            "loss": avg_loss,
            "ppl": ppl,
            "n_tokens": day_tokens_total,
            "n_tokens_scored": day_tokens_scored,
        })

        total_tokens_scored += day_tokens_scored
        total_conversations_scored += n_valid_convos

        if (date_idx + 1) % 100 == 0:
            elapsed = time.time() - t0
            ppl_str = f"{ppl:.1f}" if not math.isnan(ppl) else "N/A"
            print(f"  [{date_idx+1}/{len(dates)}] {date_val}: "
                  f"PPL={ppl_str}, {n_valid_convos}/{len(texts)} convos, "
                  f"{day_tokens_scored:,} tokens, {elapsed:.0f}s elapsed", flush=True)

    # Save
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    results_df = pl.DataFrame(results)
    out_path = RESULTS_DIR / "daily_perplexity.parquet"
    results_df.write_parquet(out_path)

    total_time = time.time() - t0
    valid = results_df.filter(~pl.col("ppl").is_nan())
    print(f"\nDone in {total_time:.0f}s", flush=True)
    print(f"Saved {len(results_df)} rows to {out_path}")
    print(f"  Valid PPL measurements: {len(valid)} / {len(results_df)} dates")
    print(f"  Total conversations scored: {total_conversations_scored:,}")
    print(f"  Total tokens scored: {total_tokens_scored:,}")
    print(f"  Date range: {results_df['date'].min()} to {results_df['date'].max()}")
    print(f"  Mean PPL: {valid['ppl'].mean():.1f}")
    print(f"  Std PPL:  {valid['ppl'].std():.1f}")


if __name__ == "__main__":
    main()
