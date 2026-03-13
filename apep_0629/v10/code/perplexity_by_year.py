#!/usr/bin/env python3
"""
Compute per-year perplexity using the base model.

Evaluates cross-entropy loss on each year's conversations separately,
broken down by chamber (House/Senate).

No LoRA needed — just computes per-year loss with the base model.

Output: results/perplexity_timeseries.parquet

Usage:
    python perplexity_by_year.py --checkpoint data/checkpoints/congressional_d6_v2/best.pt
    python perplexity_by_year.py --checkpoint data/checkpoints/congressional_d6_v2/best.pt --n-batches 200
"""

import argparse
import json
import math
import os
import pickle
import random
import sys
import time
from pathlib import Path

import polars as pl
import tiktoken
import torch
import torch.nn.functional as F

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
RESULTS_DIR = PROJECT_ROOT / "results"
NANOCHAT_DIR = PROJECT_ROOT / "_nanochat"
sys.path.insert(0, str(NANOCHAT_DIR))


def load_model_and_tokenizer(checkpoint_path: str, tokenizer_dir: str,
                              depth: int, device: str):
    """Load trained model and tokenizer."""
    with open(os.path.join(tokenizer_dir, "tokenizer_data.pkl"), "rb") as f:
        data = pickle.load(f)
    mergeable_ranks = {bytes.fromhex(k): v for k, v in data["mergeable_ranks"].items()}

    with open(os.path.join(tokenizer_dir, "special_tokens.json")) as f:
        special_tokens_list = json.load(f)

    import nanochat.tokenizer as tok_module
    tok_module.SPECIAL_TOKENS = special_tokens_list

    enc = tiktoken.Encoding(
        name="congressional_bpe_v2",
        pat_str=data["pattern"],
        mergeable_ranks=mergeable_ranks,
        special_tokens=data["special_tokens"],
    )
    from nanochat.tokenizer import RustBPETokenizer
    tokenizer = RustBPETokenizer(enc, "<|bos|>")

    from nanochat.gpt import GPT, GPTConfig

    vocab_size = tokenizer.get_vocab_size()
    aspect_ratio = 64
    model_dim = depth * aspect_ratio
    n_head = model_dim // 64
    n_kv_head = max(1, n_head // 4)

    config = GPTConfig(
        sequence_len=2048,
        vocab_size=vocab_size,
        n_layer=depth,
        n_head=n_head,
        n_kv_head=n_kv_head,
        n_embd=model_dim,
    )
    model = GPT(config).to(device)

    checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=True)
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()
    print(f"Model loaded: depth={depth}, step={checkpoint.get('step', '?')}")

    return model, tokenizer


@torch.no_grad()
def evaluate_year_chamber(model, tokenizer, conversations: list[str],
                           device: str, seq_len: int = 2048,
                           n_batches: int = 100, batch_size: int = 4) -> dict:
    """Compute perplexity on a set of conversations."""
    # Tokenize all conversations into one token stream
    all_tokens = []
    for text in conversations:
        tokens = tokenizer.enc.encode(text, allowed_special="all")
        all_tokens.extend(tokens)

    if len(all_tokens) < seq_len + 1:
        return {'loss': float('nan'), 'ppl': float('nan'), 'n_tokens': len(all_tokens)}

    tokens_tensor = torch.tensor(all_tokens, dtype=torch.long)

    total_loss = 0.0
    actual_batches = 0

    for _ in range(n_batches):
        starts = [random.randint(0, len(tokens_tensor) - seq_len - 1)
                  for _ in range(batch_size)]
        x = torch.stack([tokens_tensor[s:s + seq_len] for s in starts]).to(device)
        y = torch.stack([tokens_tensor[s + 1:s + seq_len + 1] for s in starts]).to(device)

        logits = model(x)
        loss = F.cross_entropy(logits.view(-1, logits.size(-1)), y.view(-1))
        total_loss += loss.item()
        actual_batches += 1

    avg_loss = total_loss / actual_batches if actual_batches > 0 else float('nan')
    ppl = math.exp(min(avg_loss, 20)) if not math.isnan(avg_loss) else float('nan')

    return {
        'loss': avg_loss,
        'ppl': ppl,
        'n_tokens': len(all_tokens),
        'n_conversations': len(conversations),
    }


def main():
    parser = argparse.ArgumentParser(description="Per-year perplexity evaluation")
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--tokenizer-dir", default=str(DATA_DIR / "tokenizer_v2"))
    parser.add_argument("--depth", type=int, default=6)
    parser.add_argument("--device", default="mps")
    parser.add_argument("--n-batches", type=int, default=100,
                        help="Batches per year-chamber evaluation")
    parser.add_argument("--batch-size", type=int, default=4)
    args = parser.parse_args()

    model, tokenizer = load_model_and_tokenizer(
        args.checkpoint, args.tokenizer_dir, args.depth, args.device)

    # Load all conversations
    print("Loading conversations...")
    train_df = pl.read_parquet(DATA_DIR / "conversations_train_full.parquet")
    val_df = pl.read_parquet(DATA_DIR / "conversations_val_full.parquet")
    all_df = pl.concat([train_df, val_df])
    print(f"Total: {len(all_df)} conversations, "
          f"years {all_df['year'].min()}-{all_df['year'].max()}")

    results = []
    years = sorted(all_df['year'].unique().to_list())

    for year in years:
        year_df = all_df.filter(pl.col('year') == year)
        t0 = time.time()

        # Overall year
        all_texts = year_df['text'].to_list()
        year_metrics = evaluate_year_chamber(
            model, tokenizer, all_texts, args.device,
            n_batches=args.n_batches, batch_size=args.batch_size)
        year_metrics['year'] = year
        year_metrics['chamber'] = 'ALL'
        results.append(year_metrics)

        # By chamber
        for chamber in ['H', 'S']:
            chamber_df = year_df.filter(pl.col('chamber') == chamber)
            if len(chamber_df) < 10:
                continue
            chamber_texts = chamber_df['text'].to_list()
            chamber_metrics = evaluate_year_chamber(
                model, tokenizer, chamber_texts, args.device,
                n_batches=min(args.n_batches, len(chamber_texts)),
                batch_size=args.batch_size)
            chamber_metrics['year'] = year
            chamber_metrics['chamber'] = chamber
            results.append(chamber_metrics)

        elapsed = time.time() - t0
        chamber_label = "House" if 'H' in year_df['chamber'].to_list() else ""
        print(f"  {year}: PPL={year_metrics['ppl']:.1f} (all), "
              f"{year_metrics['n_tokens']:,} tokens, {elapsed:.1f}s")

    # Save
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    results_df = pl.DataFrame(results)
    results_path = RESULTS_DIR / "perplexity_timeseries.parquet"
    results_df.write_parquet(results_path)
    print(f"\nSaved {len(results)} results to {results_path}")

    # Summary
    print("\n=== PERPLEXITY TIME SERIES ===")
    print(f"{'Year':>6} {'Chamber':>8} {'PPL':>8} {'Loss':>8} {'Tokens':>12} {'Convos':>8}")
    for r in sorted(results, key=lambda x: (x['year'], x['chamber'])):
        ppl_str = f"{r['ppl']:.1f}" if not math.isnan(r['ppl']) else "N/A"
        loss_str = f"{r['loss']:.4f}" if not math.isnan(r['loss']) else "N/A"
        print(f"{r['year']:>6} {r['chamber']:>8} {ppl_str:>8} {loss_str:>8} "
              f"{r['n_tokens']:>12,} {r['n_conversations']:>8}")


if __name__ == "__main__":
    main()
