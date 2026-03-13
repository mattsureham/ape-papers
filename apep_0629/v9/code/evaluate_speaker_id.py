#!/usr/bin/env python3
"""
Core Paper 1 result: Speaker identification evaluation.

For each conversation in the validation set:
  1. Find positions where a speaker token appears
  2. Feed the context (up to 2048 tokens) up to that position through the model
  3. At the speaker position, restrict logits to speaker token IDs only
  4. Check if the model's top prediction matches the true speaker

Metrics computed by year at 3 levels:
  - Party (R/D): Does predicted speaker match true speaker's party?
  - Individual: Exact match of speaker token
  - Within-party: Correct individual given correct party

Also computes top-5, top-10 accuracy and baselines.

Usage:
    python evaluate_speaker_id.py --checkpoint data/checkpoints/congressional_d6_v2/best.pt
    python evaluate_speaker_id.py --checkpoint data/checkpoints/congressional_d6_v2/best.pt --samples-per-year 1000
"""

import argparse
import json
import math
import os
import pickle
import random
import re
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
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
    # Load tokenizer
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

    # Build speaker token ID set
    speaker_token_ids = []
    speaker_id_to_bioguide = {}
    for token_name, token_id in data["special_tokens"].items():
        match = re.match(r'<\|speaker:(\w+)\|>', token_name)
        if match:
            bioguide = match.group(1)
            speaker_token_ids.append(token_id)
            speaker_id_to_bioguide[token_id] = bioguide

    speaker_token_ids = sorted(speaker_token_ids)
    print(f"Speaker token IDs: {len(speaker_token_ids)} "
          f"(range {min(speaker_token_ids)}-{max(speaker_token_ids)})")

    # Load model
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
    n_params = sum(p.numel() for p in model.parameters())
    print(f"Model loaded: depth={depth}, {n_params/1e6:.1f}M params, "
          f"step={checkpoint.get('step', '?')}")

    return model, tokenizer, speaker_token_ids, speaker_id_to_bioguide


def find_speaker_positions(tokens: list[int], speaker_token_ids: set) -> list[int]:
    """Find positions in token sequence where speaker tokens appear."""
    return [i for i, t in enumerate(tokens) if t in speaker_token_ids]


@torch.no_grad()
def evaluate_conversation(model, tokens: list[int], speaker_positions: list[int],
                           speaker_token_ids_tensor: torch.Tensor,
                           device: str, seq_len: int = 2048) -> list[dict]:
    """Evaluate speaker prediction at each speaker position in a conversation."""
    results = []
    tokens_tensor = torch.tensor(tokens, dtype=torch.long)

    for pos in speaker_positions:
        if pos < 2:  # need some context
            continue

        # Context window: up to seq_len tokens before this position
        start = max(0, pos - seq_len + 1)
        context = tokens_tensor[start:pos].unsqueeze(0).to(device)

        # Forward pass
        logits = model(context)
        # Get logits at the last position (predicting the speaker token)
        next_logits = logits[0, -1, :]

        # Restricted softmax over speaker tokens only
        speaker_logits = next_logits[speaker_token_ids_tensor]
        speaker_probs = F.softmax(speaker_logits, dim=-1)

        # Top-k predictions
        topk_vals, topk_idx = torch.topk(speaker_probs, min(10, len(speaker_logits)))
        topk_token_ids = speaker_token_ids_tensor[topk_idx].tolist()

        # True speaker
        true_token_id = tokens[pos]

        results.append({
            'position': pos,
            'true_token_id': true_token_id,
            'pred_token_id': topk_token_ids[0],
            'top5_token_ids': topk_token_ids[:5],
            'top10_token_ids': topk_token_ids[:10],
            'top1_prob': topk_vals[0].item(),
            'true_rank': (speaker_token_ids_tensor == true_token_id).nonzero(as_tuple=True)[0].item()
                         if true_token_id in speaker_token_ids_tensor else -1,
            'context_len': context.shape[1],
        })

    return results


def compute_metrics(eval_results: list[dict], speaker_id_to_bioguide: dict,
                    registry: dict) -> dict:
    """Compute accuracy metrics from evaluation results."""
    if not eval_results:
        return {}

    n = len(eval_results)

    # Individual accuracy
    top1_correct = sum(1 for r in eval_results if r['true_token_id'] == r['pred_token_id'])
    top5_correct = sum(1 for r in eval_results if r['true_token_id'] in r['top5_token_ids'])
    top10_correct = sum(1 for r in eval_results if r['true_token_id'] in r['top10_token_ids'])

    # Party accuracy
    party_correct = 0
    party_total = 0
    within_party_correct = 0
    within_party_total = 0

    for r in eval_results:
        true_bio = speaker_id_to_bioguide.get(r['true_token_id'])
        pred_bio = speaker_id_to_bioguide.get(r['pred_token_id'])
        if not true_bio or not pred_bio:
            continue

        true_info = registry.get(true_bio, {})
        pred_info = registry.get(pred_bio, {})
        true_party = true_info.get('party')
        pred_party = pred_info.get('party')

        if true_party in ('Democrat', 'Republican') and pred_party in ('Democrat', 'Republican'):
            party_total += 1
            if true_party == pred_party:
                party_correct += 1
                # Within-party: correct individual given correct party
                within_party_total += 1
                if r['true_token_id'] == r['pred_token_id']:
                    within_party_correct += 1

    return {
        'n_predictions': n,
        'top1_accuracy': top1_correct / n if n > 0 else 0,
        'top5_accuracy': top5_correct / n if n > 0 else 0,
        'top10_accuracy': top10_correct / n if n > 0 else 0,
        'party_accuracy': party_correct / party_total if party_total > 0 else 0,
        'party_n': party_total,
        'within_party_accuracy': within_party_correct / within_party_total if within_party_total > 0 else 0,
        'within_party_n': within_party_total,
        'avg_context_len': np.mean([r['context_len'] for r in eval_results]),
        'avg_top1_prob': np.mean([r['top1_prob'] for r in eval_results]),
    }


def main():
    parser = argparse.ArgumentParser(description="Speaker identification evaluation")
    parser.add_argument("--checkpoint", required=True, help="Model checkpoint path")
    parser.add_argument("--tokenizer-dir", default=str(DATA_DIR / "tokenizer_v2"))
    parser.add_argument("--depth", type=int, default=6)
    parser.add_argument("--device", default="mps")
    parser.add_argument("--samples-per-year", type=int, default=500,
                        help="Max speaker positions to evaluate per year")
    parser.add_argument("--max-conversations", type=int, default=500,
                        help="Max conversations to process per year")
    args = parser.parse_args()

    # Set random seed for reproducibility (AER replication standard)
    random.seed(42)

    # Load model and tokenizer
    print("Loading model and tokenizer...")
    model, tokenizer, speaker_token_ids, speaker_id_to_bioguide = \
        load_model_and_tokenizer(args.checkpoint, args.tokenizer_dir,
                                  args.depth, args.device)

    speaker_token_ids_set = set(speaker_token_ids)
    speaker_token_ids_tensor = torch.tensor(speaker_token_ids, dtype=torch.long,
                                             device=args.device)

    # Load speaker registry
    with open(DATA_DIR / "speaker_registry.json") as f:
        registry_list = json.load(f)
    registry = {e['bioguide_id']: e for e in registry_list}

    # Load validation conversations
    print("Loading validation conversations...")
    val_df = pl.read_parquet(DATA_DIR / "conversations_val_full.parquet")

    # Also load train for full time range
    train_df = pl.read_parquet(DATA_DIR / "conversations_train_full.parquet")
    all_df = pl.concat([train_df, val_df])
    print(f"Total: {len(all_df)} conversations")

    years = sorted(all_df['year'].unique().to_list())
    all_results = []

    for year in years:
        year_df = all_df.filter(pl.col('year') == year)
        # Sample conversations
        if len(year_df) > args.max_conversations:
            year_df = year_df.sample(n=args.max_conversations, seed=42)

        year_evals = []
        n_positions_found = 0
        t0 = time.time()

        for row in year_df.iter_rows(named=True):
            if len(year_evals) >= args.samples_per_year:
                break

            tokens = tokenizer.enc.encode(row['text'], allowed_special="all")
            positions = find_speaker_positions(tokens, speaker_token_ids_set)
            n_positions_found += len(positions)

            if not positions:
                continue

            # Sample positions if too many
            remaining = args.samples_per_year - len(year_evals)
            if len(positions) > remaining:
                positions = random.sample(positions, remaining)

            conv_results = evaluate_conversation(
                model, tokens, positions, speaker_token_ids_tensor,
                args.device,
            )
            year_evals.extend(conv_results)

        # Compute metrics for this year
        metrics = compute_metrics(year_evals, speaker_id_to_bioguide, registry)
        metrics['year'] = year

        # Count unique speakers this year
        year_speakers = set()
        for ids_json in all_df.filter(pl.col('year') == year)['speaker_ids'].to_list():
            year_speakers.update(json.loads(ids_json))
        metrics['n_active_speakers'] = len(year_speakers)
        metrics['random_individual_baseline'] = 1.0 / len(year_speakers) if year_speakers else 0

        elapsed = time.time() - t0
        print(f"  {year}: party={metrics.get('party_accuracy', 0):.3f}, "
              f"top1={metrics.get('top1_accuracy', 0):.3f}, "
              f"top5={metrics.get('top5_accuracy', 0):.3f}, "
              f"n={metrics.get('n_predictions', 0)}, "
              f"speakers={metrics.get('n_active_speakers', 0)}, "
              f"{elapsed:.1f}s")

        all_results.append(metrics)

    # Save results
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    results_df = pl.DataFrame(all_results)
    results_path = RESULTS_DIR / "speaker_id_accuracy.parquet"
    results_df.write_parquet(results_path)
    print(f"\nSaved {len(all_results)} year results to {results_path}")

    # Summary table
    print("\n=== SPEAKER IDENTIFICATION RESULTS ===")
    print(f"{'Year':>6} {'Party':>8} {'Top1':>8} {'Top5':>8} {'Top10':>8} "
          f"{'W/Party':>8} {'Random':>8} {'N':>6} {'Spk':>5}")
    for r in sorted(all_results, key=lambda x: x['year']):
        print(f"{r['year']:>6} {r.get('party_accuracy', 0):>8.3f} "
              f"{r.get('top1_accuracy', 0):>8.3f} "
              f"{r.get('top5_accuracy', 0):>8.3f} "
              f"{r.get('top10_accuracy', 0):>8.3f} "
              f"{r.get('within_party_accuracy', 0):>8.3f} "
              f"{r.get('random_individual_baseline', 0):>8.4f} "
              f"{r.get('n_predictions', 0):>6} "
              f"{r.get('n_active_speakers', 0):>5}")


if __name__ == "__main__":
    main()
