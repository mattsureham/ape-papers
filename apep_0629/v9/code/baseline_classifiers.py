#!/usr/bin/env python3
"""
Bag-of-words baseline classifiers for speaker identification.

Baselines:
  1. TF-IDF + SVM for party classification (R vs D)
  2. TF-IDF + SVM for individual speaker classification
  3. Logistic regression for party classification
  4. Prior-turn baseline (predict same speaker as previous turn)
  5. Random baseline (uniform over active speakers / majority party)

Uses conversations from the validation set. Each turn is a data point:
  - Features: TF-IDF of the turn's text
  - Label: speaker's party (for party task) or speaker BioGuide ID (for individual task)

Output: results/baseline_accuracy.parquet

Usage:
    python baseline_classifiers.py
    python baseline_classifiers.py --max-samples 50000
"""

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

import numpy as np
import polars as pl

PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
RESULTS_DIR = PROJECT_ROOT / "results"


def parse_turns(text: str) -> list[dict]:
    """Parse a conversation text into individual turns with speaker IDs."""
    turns = []
    # Split on speaker tokens or presiding tokens
    parts = re.split(r'(<\|speaker:\w+\|>|<\|presiding\|>)', text)

    current_speaker = None
    current_text_parts = []

    for part in parts:
        speaker_match = re.match(r'<\|speaker:(\w+)\|>', part)
        presiding_match = part == '<|presiding|>'

        if speaker_match:
            # Save previous turn
            if current_speaker and current_text_parts:
                turn_text = ' '.join(current_text_parts).strip()
                if len(turn_text) > 20:  # skip very short turns
                    turns.append({
                        'speaker': current_speaker,
                        'text': turn_text,
                        'is_presiding': False,
                    })
            current_speaker = speaker_match.group(1)
            current_text_parts = []
        elif presiding_match:
            if current_speaker and current_text_parts:
                turn_text = ' '.join(current_text_parts).strip()
                if len(turn_text) > 20:
                    turns.append({
                        'speaker': current_speaker,
                        'text': turn_text,
                        'is_presiding': False,
                    })
            current_speaker = '__PRESIDING__'
            current_text_parts = []
        else:
            # Regular text
            # Strip BOS and chamber tokens
            clean = re.sub(r'<\|[^|]+\|>', '', part).strip()
            if clean:
                current_text_parts.append(clean)

    # Last turn
    if current_speaker and current_text_parts:
        turn_text = ' '.join(current_text_parts).strip()
        if len(turn_text) > 20:
            turns.append({
                'speaker': current_speaker,
                'text': turn_text,
                'is_presiding': False if current_speaker != '__PRESIDING__' else True,
            })

    return turns


def build_turn_dataset(all_df: pl.DataFrame, registry: dict,
                       max_per_year: int = 10000) -> pl.DataFrame:
    """Build a turn-level dataset from conversations, sampling evenly per year."""
    all_rows = []
    years = sorted(all_df['year'].unique().to_list())

    for year in years:
        year_df = all_df.filter(pl.col('year') == year)
        rows = []
        for row in year_df.iter_rows(named=True):
            if len(rows) >= max_per_year:
                break
            turns = parse_turns(row['text'])
            for i, turn in enumerate(turns):
                if turn['is_presiding']:
                    continue
                if turn['speaker'] in ('None', 'R000606R', '__PRESIDING__'):
                    continue

                info = registry.get(turn['speaker'], {})
                party = info.get('party', 'Unknown')
                if party not in ('Democrat', 'Republican'):
                    continue

                rows.append({
                    'conversation_id': row['conversation_id'],
                    'year': year,
                    'chamber': row['chamber'],
                    'turn_idx': i,
                    'speaker': turn['speaker'],
                    'party': party,
                    'text': turn['text'],
                    'prev_speaker': turns[i-1]['speaker'] if i > 0 else None,
                })

                if len(rows) >= max_per_year:
                    break

        print(f"  {year}: {len(rows)} turns")
        all_rows.extend(rows)

    return pl.DataFrame(all_rows)


def run_baselines(turn_df: pl.DataFrame, registry: dict) -> list[dict]:
    """Run all baseline classifiers and return results."""
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.linear_model import LogisticRegression, SGDClassifier
    from sklearn.metrics import accuracy_score, f1_score
    from sklearn.model_selection import train_test_split

    results = []
    years = sorted(turn_df['year'].unique().to_list())

    for year in years:
        year_df = turn_df.filter(pl.col('year') == year)
        if len(year_df) < 100:
            continue

        texts = year_df['text'].to_list()
        parties = year_df['party'].to_list()
        speakers = year_df['speaker'].to_list()
        prev_speakers = year_df['prev_speaker'].to_list()
        chambers = year_df['chamber'].to_list()

        # Get unique speakers this year
        unique_speakers = list(set(speakers))
        n_speakers = len(unique_speakers)

        # Split
        indices = list(range(len(texts)))
        train_idx, test_idx = train_test_split(indices, test_size=0.3,
                                                random_state=42)

        train_texts = [texts[i] for i in train_idx]
        test_texts = [texts[i] for i in test_idx]
        train_parties = [parties[i] for i in train_idx]
        test_parties = [parties[i] for i in test_idx]
        train_speakers = [speakers[i] for i in train_idx]
        test_speakers = [speakers[i] for i in test_idx]

        # TF-IDF
        tfidf = TfidfVectorizer(max_features=10000, min_df=2, max_df=0.95,
                                ngram_range=(1, 2))
        X_train = tfidf.fit_transform(train_texts)
        X_test = tfidf.transform(test_texts)

        # 1. SVM for party classification
        svm_party = SGDClassifier(loss='hinge', max_iter=100, random_state=42,
                                   class_weight='balanced')
        svm_party.fit(X_train, train_parties)
        svm_party_pred = svm_party.predict(X_test)
        svm_party_acc = accuracy_score(test_parties, svm_party_pred)
        svm_party_f1 = f1_score(test_parties, svm_party_pred, average='macro')

        results.append({
            'year': year, 'method': 'svm_party', 'level': 'party',
            'accuracy': svm_party_acc, 'f1': svm_party_f1,
            'n_test': len(test_idx), 'n_classes': 2,
        })

        # 2. Logistic regression for party
        lr_party = LogisticRegression(max_iter=500, random_state=42,
                                       class_weight='balanced')
        lr_party.fit(X_train, train_parties)
        lr_party_pred = lr_party.predict(X_test)
        lr_party_acc = accuracy_score(test_parties, lr_party_pred)
        lr_party_f1 = f1_score(test_parties, lr_party_pred, average='macro')

        results.append({
            'year': year, 'method': 'logistic_party', 'level': 'party',
            'accuracy': lr_party_acc, 'f1': lr_party_f1,
            'n_test': len(test_idx), 'n_classes': 2,
        })

        # 3. SVM for individual speaker (only if manageable number)
        if n_speakers <= 200 and n_speakers >= 5:
            # Filter to speakers with enough samples
            speaker_counts = Counter(train_speakers)
            valid_speakers = {s for s, c in speaker_counts.items() if c >= 3}

            if len(valid_speakers) >= 5:
                train_mask = [s in valid_speakers for s in train_speakers]
                test_mask = [s in valid_speakers for s in test_speakers]

                if sum(test_mask) >= 10:
                    X_train_ind = X_train[train_mask]
                    X_test_ind = X_test[test_mask]
                    y_train_ind = [s for s, m in zip(train_speakers, train_mask) if m]
                    y_test_ind = [s for s, m in zip(test_speakers, test_mask) if m]

                    svm_ind = SGDClassifier(loss='hinge', max_iter=200,
                                            random_state=42)
                    svm_ind.fit(X_train_ind, y_train_ind)
                    svm_ind_pred = svm_ind.predict(X_test_ind)
                    svm_ind_acc = accuracy_score(y_test_ind, svm_ind_pred)

                    results.append({
                        'year': year, 'method': 'svm_individual', 'level': 'individual',
                        'accuracy': svm_ind_acc, 'f1': 0.0,
                        'n_test': sum(test_mask),
                        'n_classes': len(valid_speakers),
                    })

        # 4. Random baseline (party)
        majority_party = Counter(parties).most_common(1)[0][0]
        random_party_acc = sum(1 for p in test_parties if p == majority_party) / len(test_parties)
        results.append({
            'year': year, 'method': 'majority_party', 'level': 'party',
            'accuracy': random_party_acc, 'f1': 0.0,
            'n_test': len(test_idx), 'n_classes': 2,
        })

        # Random baseline (individual)
        random_ind_acc = 1.0 / n_speakers if n_speakers > 0 else 0.0
        results.append({
            'year': year, 'method': 'random_individual', 'level': 'individual',
            'accuracy': random_ind_acc, 'f1': 0.0,
            'n_test': len(test_idx), 'n_classes': n_speakers,
        })

        # 5. Prior-turn baseline
        prior_correct = sum(1 for i in test_idx
                           if prev_speakers[i] is not None
                           and prev_speakers[i] == speakers[i])
        prior_valid = sum(1 for i in test_idx if prev_speakers[i] is not None)
        prior_acc = prior_correct / prior_valid if prior_valid > 0 else 0.0

        results.append({
            'year': year, 'method': 'prior_turn', 'level': 'individual',
            'accuracy': prior_acc, 'f1': 0.0,
            'n_test': prior_valid, 'n_classes': n_speakers,
        })

        # Prior-turn party baseline
        prior_party_correct = 0
        prior_party_valid = 0
        for i in test_idx:
            if prev_speakers[i] is None:
                continue
            prev_info = registry.get(prev_speakers[i], {})
            prev_party = prev_info.get('party', 'Unknown')
            if prev_party in ('Democrat', 'Republican'):
                prior_party_valid += 1
                if prev_party == parties[i]:
                    prior_party_correct += 1
        prior_party_acc = prior_party_correct / prior_party_valid if prior_party_valid > 0 else 0.0

        results.append({
            'year': year, 'method': 'prior_turn_party', 'level': 'party',
            'accuracy': prior_party_acc, 'f1': 0.0,
            'n_test': prior_party_valid, 'n_classes': 2,
        })

        print(f"  {year}: SVM party={svm_party_acc:.3f}, LR party={lr_party_acc:.3f}, "
              f"majority={random_party_acc:.3f}, n_speakers={n_speakers}, "
              f"n_turns={len(year_df)}")

    return results


def main():
    parser = argparse.ArgumentParser(description="Baseline classifiers")
    parser.add_argument("--max-per-year", type=int, default=10000)
    args = parser.parse_args()

    # Load data
    print("Loading validation conversations...")
    val_df = pl.read_parquet(DATA_DIR / "conversations_val_full.parquet")
    print(f"  {len(val_df)} conversations, years {val_df['year'].min()}-{val_df['year'].max()}")

    # Also load train conversations for larger dataset
    print("Loading train conversations...")
    train_df = pl.read_parquet(DATA_DIR / "conversations_train_full.parquet")

    # Combine for more data per year
    all_df = pl.concat([train_df, val_df])
    print(f"  Total: {len(all_df)} conversations")

    # Load speaker registry
    print("Loading speaker registry...")
    with open(DATA_DIR / "speaker_registry.json") as f:
        registry_list = json.load(f)
    registry = {e['bioguide_id']: e for e in registry_list}

    # Build turn dataset
    print("Building turn dataset...")
    turn_df = build_turn_dataset(all_df, registry, max_per_year=args.max_per_year)
    print(f"  {len(turn_df)} turns, {turn_df['speaker'].n_unique()} speakers, "
          f"{turn_df['year'].n_unique()} years")

    # Party distribution
    party_counts = turn_df['party'].value_counts()
    print(f"  Party distribution:")
    for row in party_counts.iter_rows(named=True):
        print(f"    {row['party']}: {row['count']}")

    # Run baselines
    print("\nRunning baselines...")
    results = run_baselines(turn_df, registry)

    # Save results
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    results_df = pl.DataFrame(results)
    results_path = RESULTS_DIR / "baseline_accuracy.parquet"
    results_df.write_parquet(results_path)
    print(f"\nSaved {len(results)} results to {results_path}")

    # Summary table
    print("\n=== BASELINE RESULTS ===")
    print(f"{'Year':>6} {'Method':>20} {'Level':>12} {'Accuracy':>10} {'N_test':>8} {'Classes':>8}")
    for r in sorted(results, key=lambda x: (x['year'], x['level'], x['method'])):
        print(f"{r['year']:>6} {r['method']:>20} {r['level']:>12} "
              f"{r['accuracy']:>10.3f} {r['n_test']:>8} {r['n_classes']:>8}")


if __name__ == "__main__":
    main()
