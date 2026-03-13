#!/usr/bin/env python3
"""
Quick prototype: compute the Deliberation Index on a sample of conversations.

For each turn in a debate:
  - Marginal perplexity: model sees only <|bos|><|chamber:X|><|speaker:Y|> + turn text
  - Conditional perplexity: model sees full preceding context (up to 2048 tokens)
  - Deliberation Index = marginal_ppl - conditional_ppl (positive = context helps)

Usage:
    python quick_deliberation_test.py --checkpoint data/checkpoints/congressional_d6_v2/best.pt
    python quick_deliberation_test.py --checkpoint data/checkpoints/congressional_d6_v2/best.pt --n-conversations 50
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
from pathlib import Path

import numpy as np
import polars as pl
import tiktoken
import torch
import torch.nn.functional as F

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
NANOCHAT_DIR = PROJECT_ROOT / "_nanochat"
sys.path.insert(0, str(NANOCHAT_DIR))


def load_model_and_tokenizer(checkpoint_path, tokenizer_dir, depth, device):
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

    # Build speaker token lookups
    speaker_token_ids = {}
    for token_name, token_id in data["special_tokens"].items():
        match = re.match(r'<\|speaker:(\w+)\|>', token_name)
        if match:
            speaker_token_ids[token_id] = match.group(1)

    # Build special token set for detecting turn boundaries
    special_token_set = set(data["special_tokens"].values())

    from nanochat.gpt import GPT, GPTConfig
    vocab_size = tokenizer.get_vocab_size()
    model_dim = depth * 64
    n_head = model_dim // 64
    n_kv_head = max(1, n_head // 4)

    config = GPTConfig(
        sequence_len=2048, vocab_size=vocab_size,
        n_layer=depth, n_head=n_head, n_kv_head=n_kv_head, n_embd=model_dim,
    )
    model = GPT(config).to(device)
    checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=True)
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()
    print(f"Model loaded: {sum(p.numel() for p in model.parameters())/1e6:.1f}M params, "
          f"step={checkpoint.get('step', '?')}")

    return model, tokenizer, enc, speaker_token_ids, special_token_set, data["special_tokens"]


def find_turns(tokens, speaker_token_ids, special_tokens_map):
    """Find turn boundaries in a tokenized conversation.

    Returns list of (start_idx, end_idx, speaker_bioguide, speaker_token_id)
    where start_idx is the position of the speaker token and end_idx is
    one past the last token of the turn.
    """
    # Reverse lookup: token_id -> token_name
    id_to_name = {v: k for k, v in special_tokens_map.items()}

    turns = []
    current_speaker = None
    current_speaker_tid = None
    current_start = None

    for i, tid in enumerate(tokens):
        if tid in speaker_token_ids:
            # Save previous turn
            if current_speaker is not None and current_start is not None:
                turns.append((current_start, i, current_speaker, current_speaker_tid))
            current_speaker = speaker_token_ids[tid]
            current_speaker_tid = tid
            current_start = i
        elif id_to_name.get(tid, '').startswith('<|presiding'):
            # Presiding officer — end previous turn, skip this one
            if current_speaker is not None and current_start is not None:
                turns.append((current_start, i, current_speaker, current_speaker_tid))
            current_speaker = None
            current_speaker_tid = None
            current_start = None

    # Last turn
    if current_speaker is not None and current_start is not None:
        turns.append((current_start, len(tokens), current_speaker, current_speaker_tid))

    return turns


@torch.no_grad()
def compute_turn_perplexity(model, tokens_tensor, start, end, device, seq_len=2048):
    """Compute perplexity on tokens[start:end] given context tokens[max(0,start-seq_len):start]."""
    if end - start < 3:
        return float('nan')

    # The turn tokens (what we measure perplexity on)
    turn_tokens = tokens_tensor[start:end]
    turn_len = len(turn_tokens)

    # Context: everything before the turn, up to seq_len
    context_start = max(0, start - (seq_len - turn_len))
    if context_start < start:
        input_tokens = tokens_tensor[context_start:end]
    else:
        input_tokens = turn_tokens

    # Truncate to seq_len
    if len(input_tokens) > seq_len:
        input_tokens = input_tokens[-seq_len:]

    x = input_tokens[:-1].unsqueeze(0).to(device)
    y = input_tokens[1:].unsqueeze(0).to(device)

    logits = model(x)
    # Only compute loss on the TURN tokens (not the context)
    # The turn starts at position (len(input_tokens) - turn_len) in the input
    turn_offset = len(input_tokens) - turn_len
    if turn_offset > 0:
        # Slice to only the turn portion
        turn_logits = logits[0, turn_offset-1:-1, :]  # -1 because logits predict next token
        turn_targets = y[0, turn_offset-1:-1]
    else:
        turn_logits = logits[0]
        turn_targets = y[0]

    if turn_logits.shape[0] == 0:
        return float('nan')

    loss = F.cross_entropy(turn_logits, turn_targets)
    ppl = math.exp(min(loss.item(), 20))
    return ppl


@torch.no_grad()
def compute_marginal_perplexity(model, enc, turn_tokens, speaker_token_id,
                                 chamber_token_id, bos_token_id, device):
    """Compute perplexity with minimal context: just BOS + chamber + speaker + turn text."""
    # Build marginal context: <|bos|> <|chamber:X|> <|speaker:Y|> [turn text]
    prefix = [bos_token_id]
    if chamber_token_id is not None:
        prefix.append(chamber_token_id)
    prefix.append(speaker_token_id)

    # The turn text starts after the speaker token in the original
    # turn_tokens[0] should be the speaker token itself
    turn_text = turn_tokens[1:]  # skip the speaker token (it's in prefix)

    full = torch.tensor(prefix + turn_text.tolist(), dtype=torch.long)

    if len(full) < 3:
        return float('nan')

    x = full[:-1].unsqueeze(0).to(device)
    y = full[1:].unsqueeze(0).to(device)

    logits = model(x)

    # Only measure loss on the turn text portion (skip prefix predictions)
    prefix_len = len(prefix)
    if prefix_len - 1 >= logits.shape[1]:
        return float('nan')

    turn_logits = logits[0, prefix_len-1:, :]
    turn_targets = y[0, prefix_len-1:]

    if turn_logits.shape[0] == 0:
        return float('nan')

    loss = F.cross_entropy(turn_logits, turn_targets)
    ppl = math.exp(min(loss.item(), 20))
    return ppl


def main():
    parser = argparse.ArgumentParser(description="Quick Deliberation Index test")
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--tokenizer-dir", default=str(DATA_DIR / "tokenizer_v2"))
    parser.add_argument("--depth", type=int, default=6)
    parser.add_argument("--device", default="mps")
    parser.add_argument("--n-conversations", type=int, default=20,
                        help="Conversations to sample per year")
    parser.add_argument("--years", type=str, default=None,
                        help="Comma-separated years to test (default: sample across range)")
    parser.add_argument("--split", default="val", choices=["train", "val"],
                        help="Which split to use")
    args = parser.parse_args()

    model, tokenizer, enc, speaker_token_ids, special_token_set, special_tokens_map = \
        load_model_and_tokenizer(args.checkpoint, args.tokenizer_dir, args.depth, args.device)

    # Get special token IDs we need
    bos_id = special_tokens_map.get('<|bos|>')
    chamber_h_id = special_tokens_map.get('<|chamber:HOUSE|>')
    chamber_s_id = special_tokens_map.get('<|chamber:SENATE|>')

    # Load speaker registry for party info
    with open(DATA_DIR / "speaker_registry.json") as f:
        registry = {e['bioguide_id']: e for e in json.load(f)}

    # Load conversations
    if args.split == "val":
        df = pl.read_parquet(DATA_DIR / "conversations_val_full.parquet")
    else:
        df = pl.read_parquet(DATA_DIR / "conversations_train_full.parquet")

    if args.years:
        years = [int(y) for y in args.years.split(',')]
    else:
        all_years = sorted(df['year'].unique().to_list())
        # Sample evenly: pick 5-6 representative years
        if len(all_years) > 6:
            step = len(all_years) // 5
            years = [all_years[i] for i in range(0, len(all_years), step)]
        else:
            years = all_years

    print(f"Testing years: {years}")
    print(f"Split: {args.split} ({len(df)} conversations)")
    print()

    all_results = []

    for year in years:
        year_df = df.filter(pl.col('year') == year)
        if len(year_df) == 0:
            continue

        # Sample conversations
        n_sample = min(args.n_conversations, len(year_df))
        sample_df = year_df.sample(n=n_sample, seed=42)

        year_results = []
        t0 = time.time()

        for row in sample_df.iter_rows(named=True):
            tokens = enc.encode(row['text'], allowed_special="all")
            tokens_tensor = torch.tensor(tokens, dtype=torch.long)

            # Detect chamber from tokens
            chamber_id = None
            for tid in tokens[:10]:
                if tid == chamber_h_id:
                    chamber_id = chamber_h_id
                    break
                elif tid == chamber_s_id:
                    chamber_id = chamber_s_id
                    break

            turns = find_turns(tokens, speaker_token_ids, special_tokens_map)

            for turn_idx, (start, end, bioguide, speaker_tid) in enumerate(turns):
                turn_len = end - start
                if turn_len < 10:  # skip very short turns
                    continue

                # Skip if we don't know their party
                info = registry.get(bioguide, {})
                party = info.get('party', 'Unknown')
                if party not in ('Democrat', 'Republican'):
                    continue

                # Conditional perplexity (with full preceding context)
                cond_ppl = compute_turn_perplexity(
                    model, tokens_tensor, start, end, args.device)

                # Marginal perplexity (speaker + turn only, no context)
                turn_tokens = tokens_tensor[start:end]
                marg_ppl = compute_marginal_perplexity(
                    model, enc, turn_tokens, speaker_tid,
                    chamber_id, bos_id, args.device)

                if math.isnan(cond_ppl) or math.isnan(marg_ppl):
                    continue

                di = marg_ppl - cond_ppl  # positive = context helps

                year_results.append({
                    'year': year,
                    'chamber': row['chamber'],
                    'speaker': bioguide,
                    'party': party,
                    'turn_idx': turn_idx,
                    'turn_len': turn_len,
                    'context_available': start,  # tokens before this turn
                    'marginal_ppl': marg_ppl,
                    'conditional_ppl': cond_ppl,
                    'deliberation_index': di,
                })

        elapsed = time.time() - t0

        if year_results:
            dis = [r['deliberation_index'] for r in year_results]
            margs = [r['marginal_ppl'] for r in year_results]
            conds = [r['conditional_ppl'] for r in year_results]

            # By chamber
            house_dis = [r['deliberation_index'] for r in year_results if r['chamber'] == 'H']
            senate_dis = [r['deliberation_index'] for r in year_results if r['chamber'] == 'S']

            # By party
            dem_dis = [r['deliberation_index'] for r in year_results if r['party'] == 'Democrat']
            rep_dis = [r['deliberation_index'] for r in year_results if r['party'] == 'Republican']

            print(f"=== {year} ({len(year_results)} turns, {elapsed:.1f}s) ===")
            print(f"  Marginal PPL:     mean={np.mean(margs):.1f}, median={np.median(margs):.1f}")
            print(f"  Conditional PPL:  mean={np.mean(conds):.1f}, median={np.median(conds):.1f}")
            print(f"  Deliberation Idx: mean={np.mean(dis):+.1f}, median={np.median(dis):+.1f}")
            if house_dis and senate_dis:
                print(f"    House:  mean={np.mean(house_dis):+.1f} (n={len(house_dis)})")
                print(f"    Senate: mean={np.mean(senate_dis):+.1f} (n={len(senate_dis)})")
            if dem_dis and rep_dis:
                print(f"    Dem:    mean={np.mean(dem_dis):+.1f} (n={len(dem_dis)})")
                print(f"    Rep:    mean={np.mean(rep_dis):+.1f} (n={len(rep_dis)})")

            # Turns with most/least context help
            sorted_by_di = sorted(year_results, key=lambda r: r['deliberation_index'])
            print(f"  Least deliberative: DI={sorted_by_di[0]['deliberation_index']:+.1f} "
                  f"(speaker={sorted_by_di[0]['speaker']}, {sorted_by_di[0]['party'][0]}, "
                  f"ctx={sorted_by_di[0]['context_available']} tokens)")
            print(f"  Most deliberative:  DI={sorted_by_di[-1]['deliberation_index']:+.1f} "
                  f"(speaker={sorted_by_di[-1]['speaker']}, {sorted_by_di[-1]['party'][0]}, "
                  f"ctx={sorted_by_di[-1]['context_available']} tokens)")
            print()

            all_results.extend(year_results)

    # Summary across all years
    if all_results:
        print("=" * 60)
        print("SUMMARY ACROSS ALL YEARS")
        print("=" * 60)

        results_df = pl.DataFrame(all_results)

        # By year
        print(f"\n{'Year':>6} {'N':>6} {'Marg PPL':>10} {'Cond PPL':>10} {'DI':>8} {'House DI':>10} {'Senate DI':>10}")
        for year in years:
            yr = results_df.filter(pl.col('year') == year)
            if len(yr) == 0:
                continue
            h = yr.filter(pl.col('chamber') == 'H')
            s = yr.filter(pl.col('chamber') == 'S')
            h_di = h['deliberation_index'].mean() if len(h) > 0 else float('nan')
            s_di = s['deliberation_index'].mean() if len(s) > 0 else float('nan')
            print(f"{year:>6} {len(yr):>6} {yr['marginal_ppl'].mean():>10.1f} "
                  f"{yr['conditional_ppl'].mean():>10.1f} {yr['deliberation_index'].mean():>+8.1f} "
                  f"{h_di:>+10.1f} {s_di:>+10.1f}")

        # Overall
        print(f"\n  Overall DI: {results_df['deliberation_index'].mean():+.2f} "
              f"(std={results_df['deliberation_index'].std():.2f})")

        h_all = results_df.filter(pl.col('chamber') == 'H')
        s_all = results_df.filter(pl.col('chamber') == 'S')
        print(f"  House:  {h_all['deliberation_index'].mean():+.2f} (n={len(h_all)})")
        print(f"  Senate: {s_all['deliberation_index'].mean():+.2f} (n={len(s_all)})")

        d_all = results_df.filter(pl.col('party') == 'Democrat')
        r_all = results_df.filter(pl.col('party') == 'Republican')
        print(f"  Dem:    {d_all['deliberation_index'].mean():+.2f} (n={len(d_all)})")
        print(f"  Rep:    {r_all['deliberation_index'].mean():+.2f} (n={len(r_all)})")

        # Context effect
        print(f"\n  Turns where context helps (DI > 0): "
              f"{(results_df['deliberation_index'] > 0).sum()}/{len(results_df)} "
              f"({(results_df['deliberation_index'] > 0).mean()*100:.1f}%)")

        # Save
        out_path = PROJECT_ROOT / "results" / "quick_deliberation_test.parquet"
        results_df.write_parquet(out_path)
        print(f"\n  Saved {len(results_df)} results to {out_path}")


if __name__ == "__main__":
    main()
