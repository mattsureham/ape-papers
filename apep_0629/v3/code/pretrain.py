#!/usr/bin/env python3
"""
Pretrain a GPT model from scratch on Congressional debate text.

This script can run:
  1. Locally (CPU/MPS) for testing
  2. On HF Jobs (GPU) for production training

It handles tokenization, data loading, training, and checkpoint saving.

Usage:
    # Local test (tiny model, few steps)
    python pretrain.py --depth 4 --steps 100 --device cpu

    # Local MPS training
    python pretrain.py --depth 12 --device mps

    # For HF Jobs: this script is packaged into a self-contained job
    # See launch_hf_job() below or use the hf_jobs MCP tool
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

import torch
import torch.nn.functional as F

# Try to add nanochat to path
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
NANOCHAT_DIR = PROJECT_ROOT / "_nanochat"
if NANOCHAT_DIR.exists():
    sys.path.insert(0, str(NANOCHAT_DIR))

DATA_DIR = os.environ.get("CONGRESSIONAL_DATA_DIR", str(PROJECT_ROOT / "data"))


def load_tokenizer(tokenizer_dir: str):
    """Load tokenizer from saved components."""
    import tiktoken

    # Load special tokens list
    special_tokens_path = os.path.join(tokenizer_dir, "special_tokens.json")
    with open(special_tokens_path) as f:
        special_tokens_list = json.load(f)

    # Monkey-patch nanochat's SPECIAL_TOKENS
    import nanochat.tokenizer as tok_module
    tok_module.SPECIAL_TOKENS = special_tokens_list

    # Load tokenizer data
    data_path = os.path.join(tokenizer_dir, "tokenizer_data.pkl")
    with open(data_path, "rb") as f:
        data = pickle.load(f)

    mergeable_ranks = {bytes.fromhex(k): v for k, v in data["mergeable_ranks"].items()}
    enc = tiktoken.Encoding(
        name="congressional_bpe",
        pat_str=data["pattern"],
        mergeable_ranks=mergeable_ranks,
        special_tokens=data["special_tokens"],
    )

    from nanochat.tokenizer import RustBPETokenizer
    return RustBPETokenizer(enc, "<|bos|>")


def tokenize_corpus(tokenizer, data_dir: str, split: str = "train",
                    seq_len: int = 2048) -> torch.Tensor:
    """Load or tokenize the Congressional corpus.

    First checks for pre-tokenized cache (tokens_{split}.pt).
    Falls back to tokenizing from conversations_{split}.parquet.
    """
    # Check for cached tokens first
    cache_path = os.path.join(data_dir, f"tokens_{split}.pt")
    if os.path.exists(cache_path):
        print(f"Loading cached tokens from {cache_path}...")
        tensor = torch.load(cache_path, weights_only=True)
        # Convert to int64 if saved as int32
        if tensor.dtype != torch.long:
            tensor = tensor.to(torch.long)
        print(f"  {split}: {len(tensor):,} tokens")
        return tensor

    # Fall back to tokenization
    import polars as pl

    parquet_path = os.path.join(data_dir, f"conversations_{split}.parquet")
    if not os.path.exists(parquet_path):
        raise FileNotFoundError(f"Neither {cache_path} nor {parquet_path} found")

    print(f"Loading {split} data from {parquet_path}...")
    df = pl.read_parquet(parquet_path, columns=["text"])

    print(f"Tokenizing {len(df):,} conversations...")
    all_tokens = []
    for i, text in enumerate(df["text"].to_list()):
        tokens = tokenizer.enc.encode(text, allowed_special="all")
        all_tokens.extend(tokens)
        if (i + 1) % 500 == 0:
            print(f"  {i+1}/{len(df)} conversations, {len(all_tokens):,} tokens so far")

    token_tensor = torch.tensor(all_tokens, dtype=torch.long)
    print(f"  {split}: {len(token_tensor):,} tokens total")

    # Cache for next time
    torch.save(token_tensor.to(torch.int32), cache_path)
    print(f"  Cached to {cache_path}")

    return token_tensor


def create_model(depth: int, vocab_size: int, seq_len: int = 2048,
                 device: str = "cpu"):
    """Create a GPT model with auto-scaled dimensions from depth."""
    from nanochat.gpt import GPT, GPTConfig

    # nanochat scaling: model_dim = depth * aspect_ratio (default 64)
    aspect_ratio = 64
    model_dim = depth * aspect_ratio
    head_dim = 64
    n_head = model_dim // head_dim
    n_kv_head = max(1, n_head // 4)  # GQA: 4:1 ratio

    config = GPTConfig(
        sequence_len=seq_len,
        vocab_size=vocab_size,
        n_layer=depth,
        n_head=n_head,
        n_kv_head=n_kv_head,
        n_embd=model_dim,
    )

    model = GPT(config).to(device)
    n_params = sum(p.numel() for p in model.parameters())
    print(f"\nModel: depth={depth}, dim={model_dim}, heads={n_head}, "
          f"kv_heads={n_kv_head}")
    print(f"  Parameters: {n_params:,} ({n_params/1e6:.1f}M)")
    print(f"  Vocab size: {vocab_size}")
    print(f"  Sequence length: {seq_len}")

    return model, config, n_params


def train(model, train_tokens: torch.Tensor, val_tokens: torch.Tensor,
          args, device: str = "cpu"):
    """Training loop with validation and checkpointing."""
    seq_len = args.seq_len
    batch_size = args.batch_size
    n_params = sum(p.numel() for p in model.parameters())

    # Compute training horizon if not specified
    if args.steps <= 0:
        # Chinchilla-optimal: ~20 tokens per parameter
        target_tokens = n_params * args.tokens_per_param
        tokens_per_step = batch_size * seq_len
        args.steps = max(1000, int(target_tokens / tokens_per_step))
        print(f"Auto-computed steps: {args.steps} "
              f"(target {target_tokens/1e6:.0f}M tokens, "
              f"{tokens_per_step} tokens/step)")

    # Optimizer
    optimizer = torch.optim.AdamW(
        model.parameters(),
        lr=args.lr,
        weight_decay=args.weight_decay,
        betas=(0.9, 0.95),
    )

    # LR schedule: linear warmup then cosine decay
    warmup_steps = min(100, args.steps // 10)

    def get_lr(step):
        if step < warmup_steps:
            return args.lr * (step + 1) / warmup_steps
        progress = (step - warmup_steps) / max(1, args.steps - warmup_steps)
        return args.lr * 0.5 * (1 + math.cos(math.pi * progress))

    # Training
    model.train()
    best_val_loss = float("inf")
    checkpoint_dir = os.path.join(DATA_DIR, "checkpoints", args.run_name)
    os.makedirs(checkpoint_dir, exist_ok=True)

    print(f"\nTraining for {args.steps} steps "
          f"(batch_size={batch_size}, seq_len={seq_len})...")
    print(f"Checkpoints: {checkpoint_dir}")

    t0 = time.time()
    running_loss = 0.0
    tokens_seen = 0

    for step in range(args.steps):
        # Set LR
        lr = get_lr(step)
        for pg in optimizer.param_groups:
            pg["lr"] = lr

        # Random batch from training tokens
        batch_starts = [random.randint(0, len(train_tokens) - seq_len - 1)
                        for _ in range(batch_size)]
        x = torch.stack([train_tokens[s:s + seq_len] for s in batch_starts]).to(device)
        y = torch.stack([train_tokens[s + 1:s + seq_len + 1] for s in batch_starts]).to(device)

        # Forward + backward
        logits = model(x)
        loss = F.cross_entropy(logits.view(-1, logits.size(-1)), y.view(-1))

        optimizer.zero_grad()
        loss.backward()

        # Gradient clipping
        torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
        optimizer.step()

        running_loss += loss.item()
        tokens_seen += batch_size * seq_len

        # Logging
        if (step + 1) % args.log_every == 0:
            avg_loss = running_loss / args.log_every
            elapsed = time.time() - t0
            tokens_per_sec = tokens_seen / elapsed
            ppl = math.exp(min(avg_loss, 20))
            print(f"  Step {step+1:>6}/{args.steps} | loss={avg_loss:.4f} | "
                  f"ppl={ppl:.1f} | lr={lr:.2e} | "
                  f"{tokens_per_sec:.0f} tok/s | {elapsed:.0f}s")
            running_loss = 0.0

        # Validation
        if (step + 1) % args.eval_every == 0:
            val_loss = evaluate(model, val_tokens, seq_len, batch_size, device)
            val_ppl = math.exp(min(val_loss, 20))
            print(f"  >>> Val loss={val_loss:.4f}, ppl={val_ppl:.1f}")

            if val_loss < best_val_loss:
                best_val_loss = val_loss
                save_checkpoint(model, optimizer, step + 1, val_loss,
                                checkpoint_dir, "best")
                print(f"  >>> New best! Saved checkpoint.")

            model.train()

        # Periodic checkpoint
        if (step + 1) % args.save_every == 0:
            save_checkpoint(model, optimizer, step + 1, loss.item(),
                            checkpoint_dir, f"step_{step+1}")

    # Final checkpoint
    save_checkpoint(model, optimizer, args.steps, loss.item(),
                    checkpoint_dir, "final")

    # Final validation
    val_loss = evaluate(model, val_tokens, seq_len, batch_size, device)
    val_ppl = math.exp(min(val_loss, 20))
    elapsed = time.time() - t0
    print(f"\nTraining complete in {elapsed:.0f}s ({elapsed/60:.1f}min)")
    print(f"Final val loss={val_loss:.4f}, ppl={val_ppl:.1f}")
    print(f"Best val loss={best_val_loss:.4f}, ppl={math.exp(min(best_val_loss, 20)):.1f}")
    print(f"Total tokens seen: {tokens_seen:,}")

    return val_loss


@torch.no_grad()
def evaluate(model, val_tokens: torch.Tensor, seq_len: int,
             batch_size: int, device: str, n_batches: int = 50) -> float:
    """Evaluate model on validation set."""
    model.eval()
    total_loss = 0.0

    for _ in range(n_batches):
        batch_starts = [random.randint(0, len(val_tokens) - seq_len - 1)
                        for _ in range(batch_size)]
        x = torch.stack([val_tokens[s:s + seq_len] for s in batch_starts]).to(device)
        y = torch.stack([val_tokens[s + 1:s + seq_len + 1] for s in batch_starts]).to(device)

        logits = model(x)
        loss = F.cross_entropy(logits.view(-1, logits.size(-1)), y.view(-1))
        total_loss += loss.item()

    return total_loss / n_batches


@torch.no_grad()
def generate_samples(model, tokenizer, device: str, n_samples: int = 5,
                     max_tokens: int = 200, temperature: float = 0.8):
    """Generate sample speeches from the model."""
    model.eval()

    bos_id = tokenizer.encode_special("<|bos|>")
    house_id = tokenizer.encode_special("<|chamber:HOUSE|>")
    senate_id = tokenizer.encode_special("<|chamber:SENATE|>")

    prompts = [
        [bos_id, house_id],
        [bos_id, senate_id],
    ]

    print("\n--- Generated Samples ---")
    for i in range(n_samples):
        prompt = prompts[i % len(prompts)]
        tokens = list(prompt)

        for _ in range(max_tokens):
            x = torch.tensor([tokens[-min(len(tokens), 512):]],
                             dtype=torch.long, device=device)
            logits = model(x)
            next_logits = logits[0, -1, :] / temperature
            probs = F.softmax(next_logits, dim=-1)
            next_tok = torch.multinomial(probs, 1).item()
            tokens.append(next_tok)

            # Stop at BOS (new document)
            if next_tok == bos_id and len(tokens) > 10:
                break

        text = tokenizer.decode(tokens)
        print(f"\nSample {i+1}:")
        print(text[:500])
        print("---")


def save_checkpoint(model, optimizer, step: int, loss: float,
                    checkpoint_dir: str, name: str):
    """Save model checkpoint."""
    path = os.path.join(checkpoint_dir, f"{name}.pt")
    torch.save({
        "step": step,
        "loss": loss,
        "model_state_dict": model.state_dict(),
        "optimizer_state_dict": optimizer.state_dict(),
    }, path)


def main():
    parser = argparse.ArgumentParser(description="Pretrain Congressional GPT")
    parser.add_argument("--depth", type=int, default=12,
                        help="Model depth (12=~50M, 20=~124M params)")
    parser.add_argument("--seq-len", type=int, default=2048)
    parser.add_argument("--batch-size", type=int, default=4)
    parser.add_argument("--steps", type=int, default=-1,
                        help="Training steps (-1 = auto from tokens_per_param)")
    parser.add_argument("--tokens-per-param", type=float, default=10.5,
                        help="Target tokens per parameter (Chinchilla ~20)")
    parser.add_argument("--lr", type=float, default=3e-4)
    parser.add_argument("--weight-decay", type=float, default=0.1)
    parser.add_argument("--device", default="cpu",
                        help="Device (cpu, mps, cuda)")
    parser.add_argument("--log-every", type=int, default=50)
    parser.add_argument("--eval-every", type=int, default=250)
    parser.add_argument("--save-every", type=int, default=1000)
    parser.add_argument("--run-name", default="congressional_pretrain")
    parser.add_argument("--generate", action="store_true",
                        help="Generate samples after training")
    parser.add_argument("--tokenizer-dir", default=None,
                        help="Tokenizer directory (default: data/tokenizer)")
    parser.add_argument("--token-suffix", default="",
                        help="Suffix for token files, e.g. '_v2' loads tokens_train_v2.pt")
    args = parser.parse_args()

    data_dir = DATA_DIR
    tokenizer_dir = args.tokenizer_dir or os.path.join(data_dir, "tokenizer")

    # Load tokenizer
    print("Loading tokenizer...")
    tokenizer = load_tokenizer(tokenizer_dir)
    print(f"  Vocab size: {tokenizer.get_vocab_size()}")

    # Tokenize corpus — use suffix for v2 tokens
    train_split = f"train{args.token_suffix}"
    val_split = f"val{args.token_suffix}"
    train_tokens = tokenize_corpus(tokenizer, data_dir, split=train_split,
                                   seq_len=args.seq_len)
    val_tokens = tokenize_corpus(tokenizer, data_dir, split=val_split,
                                 seq_len=args.seq_len)

    # Create model
    model, config, n_params = create_model(
        depth=args.depth,
        vocab_size=tokenizer.get_vocab_size(),
        seq_len=args.seq_len,
        device=args.device,
    )

    # Train
    val_loss = train(model, train_tokens, val_tokens, args, device=args.device)

    # Generate samples
    if args.generate:
        generate_samples(model, tokenizer, args.device)

    # Save training summary
    summary = {
        "depth": args.depth,
        "n_params": n_params,
        "vocab_size": tokenizer.get_vocab_size(),
        "seq_len": args.seq_len,
        "train_tokens": len(train_tokens),
        "val_tokens": len(val_tokens),
        "steps": args.steps,
        "final_val_loss": val_loss,
        "final_val_ppl": math.exp(min(val_loss, 20)),
        "device": args.device,
        "run_name": args.run_name,
    }
    summary_path = os.path.join(data_dir, "checkpoints", args.run_name,
                                "training_summary.json")
    with open(summary_path, "w") as f:
        json.dump(summary, f, indent=2)
    print(f"\nTraining summary saved to {summary_path}")


if __name__ == "__main__":
    main()
