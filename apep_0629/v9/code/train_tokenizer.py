#!/usr/bin/env python3
"""
Train BPE tokenizer on Congressional corpus with special speaker tokens.

Uses nanochat's RustBPE tokenizer with custom special tokens for:
  - <|bos|>           — document start
  - <|chamber:HOUSE|> — House floor
  - <|chamber:SENATE|> — Senate floor
  - <|presiding|>     — presiding officer turn
  - <|speaker:BIOGUIDE_ID|> — one per unique speaker (~1000+)

The speaker tokens are loaded from the speaker registry built by join_bioguide.py.

Usage:
    python train_tokenizer.py
    python train_tokenizer.py --vocab-size 32768
    python train_tokenizer.py --verify-only  # just verify existing tokenizer
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
NANOCHAT_DIR = PROJECT_ROOT / "_nanochat"

# Add nanochat to path
sys.path.insert(0, str(NANOCHAT_DIR))


def build_special_tokens(speaker_registry_path: Path) -> list[str]:
    """Build the full special tokens list including all speaker IDs."""
    # Base tokens (must start with <|bos|>)
    tokens = [
        "<|bos|>",
        "<|chamber:HOUSE|>",
        "<|chamber:SENATE|>",
        "<|presiding|>",
    ]

    # Load speaker registry
    with open(speaker_registry_path) as f:
        registry = json.load(f)

    # Add speaker tokens sorted by bioguide_id for reproducibility
    bioguide_ids = sorted(set(entry["bioguide_id"] for entry in registry))
    for bid in bioguide_ids:
        tokens.append(f"<|speaker:{bid}|>")

    print(f"Special tokens: {len(tokens)} total "
          f"({len(tokens) - 4} speakers + 4 base)")
    return tokens


def text_iterator(training_text_dir: Path, max_chars: int = 2_000_000_000,
                  doc_cap: int = 50_000):
    """Iterate over training text files, yielding document chunks.

    Unlike nanochat's default (10K cap), we use 50K since Congressional
    debates are long and we want the model to see full speaker sequences.
    """
    nchars = 0
    for txt_path in sorted(training_text_dir.glob("congress_*.txt")):
        with open(txt_path) as f:
            text = f.read()

        # Split on double newlines (conversation boundaries)
        docs = text.split("\n\n")
        for doc in docs:
            doc = doc.strip()
            if not doc:
                continue
            if len(doc) > doc_cap:
                doc = doc[:doc_cap]
            nchars += len(doc)
            yield doc
            if nchars >= max_chars:
                return

    print(f"  Tokenizer training consumed {nchars:,} characters")


def load_tokenizer_from_dir(tokenizer_dir: Path):
    """Load tokenizer from saved components (handles both formats)."""
    import pickle
    import tiktoken
    from nanochat.tokenizer import RustBPETokenizer

    # Try standard pickle first
    pkl_path = tokenizer_dir / "tokenizer.pkl"
    if pkl_path.exists():
        try:
            return RustBPETokenizer.from_directory(str(tokenizer_dir))
        except Exception:
            pass

    # Fall back to component-based loading
    data_path = tokenizer_dir / "tokenizer_data.pkl"
    if data_path.exists():
        with open(data_path, "rb") as f:
            data = pickle.load(f)
        mergeable_ranks = {bytes.fromhex(k): v for k, v in data["mergeable_ranks"].items()}
        enc = tiktoken.Encoding(
            name="congressional_bpe",
            pat_str=data["pattern"],
            mergeable_ranks=mergeable_ranks,
            special_tokens=data["special_tokens"],
        )
        return RustBPETokenizer(enc, "<|bos|>")

    raise FileNotFoundError(f"No tokenizer found in {tokenizer_dir}")


def encode_with_special_tokens(enc, text: str) -> list[int]:
    """Encode text recognizing all special tokens as atomic units.

    nanochat's default encode_ordinary() skips special tokens in text.
    We need tiktoken's allowed_special="all" to handle embedded speaker tokens.
    """
    return enc.encode(text, allowed_special="all")


def verify_tokenizer(tokenizer_dir: Path, special_tokens: list[str]):
    """Verify a trained tokenizer handles all special tokens correctly."""
    tokenizer = load_tokenizer_from_dir(tokenizer_dir)

    print(f"\nTokenizer vocab size: {tokenizer.get_vocab_size()}")
    print(f"Special tokens registered: {len(tokenizer.get_special_tokens())}")

    # Test encoding WITH special token recognition
    test_text = (
        "<|bos|><|chamber:SENATE|>\n"
        "<|speaker:T000250|> Mr. President, I rise today to discuss "
        "the economic situation facing American families.\n"
        "<|presiding|> The Senator from South Dakota.\n"
        "<|speaker:K000384|> Thank you, Mr. President."
    )

    # Use allowed_special="all" to recognize embedded special tokens
    encoded = encode_with_special_tokens(tokenizer.enc, test_text)
    decoded = tokenizer.decode(encoded)

    print(f"\nTest encoding ({len(encoded)} tokens):")
    for i, tid in enumerate(encoded[:20]):
        token_str = tokenizer.enc.decode([tid])
        print(f"  [{i:3d}] id={tid:6d}  '{token_str}'")

    # Check that special tokens are atomic
    bos_id = tokenizer.encode_special("<|bos|>")
    chamber_id = tokenizer.encode_special("<|chamber:SENATE|>")
    speaker_id = tokenizer.encode_special("<|speaker:T000250|>")

    print(f"\n  <|bos|> → {bos_id}, in encoded[0]: {encoded[0] == bos_id}")
    print(f"  <|chamber:SENATE|> → {chamber_id}, in encoded[1]: {encoded[1] == chamber_id}")
    # Speaker token position depends on newline tokenization
    speaker_positions = [i for i, t in enumerate(encoded) if t == speaker_id]
    print(f"  <|speaker:T000250|> → {speaker_id}, positions: {speaker_positions}")

    # Verify roundtrip
    if decoded == test_text:
        print("\nRoundtrip: PASS")
    else:
        print(f"\nRoundtrip: FAIL")
        print(f"  Original:  {test_text[:100]}...")
        print(f"  Decoded:   {decoded[:100]}...")

    # Verify all speaker tokens are in vocab
    missing = []
    for st in special_tokens:
        try:
            tid = tokenizer.encode_special(st)
            if tid is None:
                missing.append(st)
        except KeyError:
            missing.append(st)

    if missing:
        print(f"\nMissing special tokens: {len(missing)}")
        for m in missing[:10]:
            print(f"  {m}")
    else:
        print(f"\nAll {len(special_tokens)} special tokens verified")

    return len(missing) == 0


def main():
    parser = argparse.ArgumentParser(description="Train BPE tokenizer for Congressional LM")
    parser.add_argument("--vocab-size", type=int, default=32768,
                        help="Vocabulary size (default: 32768)")
    parser.add_argument("--max-chars", type=int, default=2_000_000_000,
                        help="Max characters for training (default: 2B)")
    parser.add_argument("--verify-only", action="store_true",
                        help="Only verify existing tokenizer")
    parser.add_argument("--output-dir", type=str, default=None,
                        help="Output directory for tokenizer (default: data/tokenizer)")
    args = parser.parse_args()

    # Build special tokens
    registry_path = DATA_DIR / "speaker_registry.json"
    if not registry_path.exists():
        print(f"ERROR: {registry_path} not found. Run join_bioguide.py first.")
        return

    special_tokens = build_special_tokens(registry_path)

    # Monkey-patch nanochat's SPECIAL_TOKENS before importing tokenizer
    import nanochat.tokenizer as tok_module
    tok_module.SPECIAL_TOKENS = special_tokens

    tokenizer_dir = Path(args.output_dir) if args.output_dir else DATA_DIR / "tokenizer"

    if args.verify_only:
        if not tokenizer_dir.exists():
            print(f"ERROR: {tokenizer_dir} not found. Train tokenizer first.")
            return
        verify_tokenizer(tokenizer_dir, special_tokens)
        return

    # Check vocab budget
    vocab_for_bpe = args.vocab_size - len(special_tokens)
    print(f"\nVocab budget: {args.vocab_size} total - {len(special_tokens)} special = "
          f"{vocab_for_bpe} BPE merges")
    if vocab_for_bpe < 256:
        print("ERROR: Too many special tokens for vocab size. Increase --vocab-size.")
        return

    # Train tokenizer
    training_text_dir = DATA_DIR / "training_text"
    if not training_text_dir.exists():
        print(f"ERROR: {training_text_dir} not found. Run format_for_training.py --export-text first.")
        return

    print(f"\nTraining BPE tokenizer (vocab_size={args.vocab_size})...")
    from nanochat.tokenizer import RustBPETokenizer

    t0 = time.time()
    text_iter = text_iterator(training_text_dir, max_chars=args.max_chars)

    # Train BPE (this creates the tokenizer but tiktoken's CoreBPE may not be picklable)
    import rustbpe
    import tiktoken

    bpe_tokenizer = rustbpe.Tokenizer()
    vocab_size_no_special = args.vocab_size - len(special_tokens)
    from nanochat.tokenizer import SPLIT_PATTERN
    bpe_tokenizer.train_from_iterator(text_iter, vocab_size_no_special, pattern=SPLIT_PATTERN)

    # Extract components for saving
    pattern = bpe_tokenizer.get_pattern()
    mergeable_ranks_list = bpe_tokenizer.get_mergeable_ranks()
    mergeable_ranks = {bytes(k): v for k, v in mergeable_ranks_list}
    tokens_offset = len(mergeable_ranks)
    special_tokens_map = {name: tokens_offset + i for i, name in enumerate(special_tokens)}

    # Build tiktoken encoding
    enc = tiktoken.Encoding(
        name="congressional_bpe",
        pat_str=pattern,
        mergeable_ranks=mergeable_ranks,
        special_tokens=special_tokens_map,
    )
    tokenizer = RustBPETokenizer(enc, "<|bos|>")

    t1 = time.time()
    print(f"Training time: {t1 - t0:.1f}s")

    # Save components (avoid pickling CoreBPE directly)
    tokenizer_dir.mkdir(parents=True, exist_ok=True)

    # Save mergeable_ranks + special_tokens + pattern for reconstruction
    save_data = {
        "mergeable_ranks": {k.hex(): v for k, v in mergeable_ranks.items()},
        "special_tokens": special_tokens_map,
        "pattern": pattern,
    }
    import pickle
    with open(tokenizer_dir / "tokenizer_data.pkl", "wb") as f:
        pickle.dump(save_data, f)

    # Also try the standard save (may work with some tiktoken versions)
    try:
        tokenizer.save(str(tokenizer_dir))
    except TypeError:
        print("Note: tiktoken CoreBPE not picklable, using tokenizer_data.pkl instead")
        # Write a loader script
        loader_code = '''
import pickle
import tiktoken
from pathlib import Path

def load_tokenizer(tokenizer_dir):
    """Load tokenizer from saved components."""
    with open(Path(tokenizer_dir) / "tokenizer_data.pkl", "rb") as f:
        data = pickle.load(f)
    mergeable_ranks = {bytes.fromhex(k): v for k, v in data["mergeable_ranks"].items()}
    enc = tiktoken.Encoding(
        name="congressional_bpe",
        pat_str=data["pattern"],
        mergeable_ranks=mergeable_ranks,
        special_tokens=data["special_tokens"],
    )
    return enc
'''
        with open(tokenizer_dir / "loader.py", "w") as f:
            f.write(loader_code)

    # Also save token_bytes for BPB evaluation
    import torch
    vocab_size = tokenizer.get_vocab_size()
    special_set = set(tokenizer.get_special_tokens())
    token_bytes = []
    for token_id in range(vocab_size):
        token_str = tokenizer.enc.decode([token_id])
        if token_str in special_set:
            token_bytes.append(0)
        else:
            token_bytes.append(len(token_str.encode("utf-8")))
    token_bytes_t = torch.tensor(token_bytes, dtype=torch.int32, device="cpu")
    torch.save(token_bytes_t, str(tokenizer_dir / "token_bytes.pt"))

    # Save special tokens list for later use
    with open(tokenizer_dir / "special_tokens.json", "w") as f:
        json.dump(special_tokens, f)

    print(f"\nSaved tokenizer to {tokenizer_dir}/")
    print(f"  tokenizer.pkl, token_bytes.pt, special_tokens.json")

    # Verify
    verify_tokenizer(tokenizer_dir, special_tokens)


if __name__ == "__main__":
    main()
