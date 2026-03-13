#!/usr/bin/env python3
"""
Retokenize full corpus with v2 tokenizer (all 1,701 speakers).

Reads conversations_train_full.parquet and conversations_val_full.parquet,
tokenizes with tokenizer_v2, saves as tokens_train_v2.pt and tokens_val_v2.pt.

Also verifies that GovInfo-era speaker tokens are now atomic (not subwords).

Usage:
    python retokenize_v2.py
"""

import json
import os
import pickle
import sys
import time
from pathlib import Path

import polars as pl
import tiktoken
import torch

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
NANOCHAT_DIR = PROJECT_ROOT / "_nanochat"
sys.path.insert(0, str(NANOCHAT_DIR))


def load_tokenizer_v2():
    """Load the v2 tokenizer with all 1,701 speakers."""
    tokenizer_dir = DATA_DIR / "tokenizer_v2"
    with open(tokenizer_dir / "tokenizer_data.pkl", "rb") as f:
        data = pickle.load(f)
    mergeable_ranks = {bytes.fromhex(k): v for k, v in data["mergeable_ranks"].items()}
    enc = tiktoken.Encoding(
        name="congressional_bpe_v2",
        pat_str=data["pattern"],
        mergeable_ranks=mergeable_ranks,
        special_tokens=data["special_tokens"],
    )
    from nanochat.tokenizer import RustBPETokenizer
    return RustBPETokenizer(enc, "<|bos|>")


def verify_speaker_tokens(tokenizer, registry_path: Path):
    """Verify GovInfo-era speakers are now atomic tokens."""
    with open(registry_path) as f:
        registry = json.load(f)

    govinfo_speakers = [e for e in registry if e.get("source") == "govinfo"]
    n_atomic = 0
    n_fragmented = 0

    for entry in govinfo_speakers[:10]:  # spot-check first 10
        bid = entry["bioguide_id"]
        token_str = f"<|speaker:{bid}|>"
        encoded = tokenizer.enc.encode(token_str, allowed_special="all")
        if len(encoded) == 1:
            n_atomic += 1
        else:
            n_fragmented += 1
            print(f"  WARNING: {token_str} → {len(encoded)} tokens (expected 1)")

    # Full check
    for entry in govinfo_speakers:
        bid = entry["bioguide_id"]
        token_str = f"<|speaker:{bid}|>"
        encoded = tokenizer.enc.encode(token_str, allowed_special="all")
        if len(encoded) != 1:
            n_fragmented += 1

    total = len(govinfo_speakers)
    n_atomic = total - n_fragmented
    print(f"GovInfo speaker tokens: {n_atomic}/{total} atomic, {n_fragmented} fragmented")
    return n_fragmented == 0


def tokenize_split(df: pl.DataFrame, tokenizer, split_name: str) -> torch.Tensor:
    """Tokenize a split's conversation text."""
    all_tokens = []
    texts = df["text"].to_list()
    t0 = time.time()

    for i, text in enumerate(texts):
        tokens = tokenizer.enc.encode(text, allowed_special="all")
        all_tokens.extend(tokens)
        if (i + 1) % 1000 == 0:
            elapsed = time.time() - t0
            rate = (i + 1) / elapsed
            remaining = (len(texts) - i - 1) / rate
            print(f"  {split_name}: {i+1}/{len(texts)} conversations, "
                  f"{len(all_tokens):,} tokens, "
                  f"~{remaining:.0f}s remaining")

    tensor = torch.tensor(all_tokens, dtype=torch.int32)
    print(f"  {split_name}: {len(tensor):,} tokens total ({time.time()-t0:.1f}s)")

    cache_path = DATA_DIR / f"tokens_{split_name}_v2.pt"
    torch.save(tensor, cache_path)
    print(f"  Saved to {cache_path} ({os.path.getsize(cache_path) / 1e9:.1f} GB)")

    return tensor


def main():
    tokenizer = load_tokenizer_v2()
    print(f"Tokenizer v2 vocab size: {tokenizer.get_vocab_size()}")

    # Verify speaker tokens
    print("\nVerifying speaker tokens...")
    verify_speaker_tokens(tokenizer, DATA_DIR / "speaker_registry.json")

    # Load conversations
    train_path = DATA_DIR / "conversations_train_full.parquet"
    val_path = DATA_DIR / "conversations_val_full.parquet"

    print(f"\nLoading train split from {train_path.name}...")
    train_df = pl.read_parquet(train_path)
    print(f"  {len(train_df):,} conversations")

    print(f"Loading val split from {val_path.name}...")
    val_df = pl.read_parquet(val_path)
    print(f"  {len(val_df):,} conversations")

    # Tokenize
    print("\nTokenizing train split...")
    train_tokens = tokenize_split(train_df, tokenizer, "train")

    print("\nTokenizing val split...")
    val_tokens = tokenize_split(val_df, tokenizer, "val")

    # Summary
    print("\n" + "=" * 60)
    print("RETOKENIZE v2 COMPLETE")
    print("=" * 60)
    print(f"Train: {len(train_tokens):,} tokens")
    print(f"Val: {len(val_tokens):,} tokens")
    print(f"Total: {len(train_tokens) + len(val_tokens):,} tokens")

    # Compare with v1 tokens
    v1_train = DATA_DIR / "tokens_train_full.pt"
    if v1_train.exists():
        v1 = torch.load(v1_train, weights_only=True)
        diff = len(train_tokens) - len(v1)
        print(f"\nv1 train tokens: {len(v1):,}")
        print(f"v2 train tokens: {len(train_tokens):,}")
        print(f"Difference: {diff:+,} ({diff/len(v1)*100:+.1f}%)")


if __name__ == "__main__":
    main()
