#!/usr/bin/env python3
"""
For each matched pair, compute TF-IDF cosine distance between proposed and final
text. Pairs where either text is missing are dropped — text distance is a
secondary outcome computed on the cached subsample. Outputs data/textdist.csv
keyed on the proposed-rule document number.
"""
import csv, re, sys
from pathlib import Path
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import normalize

OUT = Path(__file__).resolve().parent.parent / "data"
TXT = OUT / "text"

def fname(url):
    return re.sub(r"[^A-Za-z0-9_.-]","_", url.split("/")[-1])

def load(url):
    if not url: return None
    p = TXT / fname(url)
    if not p.exists(): return None
    t = p.read_text(errors="ignore")
    if len(t) < 200: return None
    return t

def main():
    rows = list(csv.DictReader(open(OUT/"pairs_meta.csv")))
    print(f"loaded {len(rows)} pair rows")
    keep, p_texts, f_texts = [], [], []
    for r in rows:
        pt = load(r["p_raw_text_url"]); ft = load(r["f_raw_text_url"])
        if pt is None or ft is None: continue
        keep.append(r); p_texts.append(pt); f_texts.append(ft)
    print(f"pairs with both texts cached: {len(keep)}")
    if len(keep) < 50:
        sys.exit("ERROR: too few cached pairs")
    vec = TfidfVectorizer(stop_words="english", min_df=2, max_df=0.7,
                          ngram_range=(1,2), max_features=50000)
    P = vec.fit_transform(p_texts); F = vec.transform(f_texts)
    sims = np.asarray(normalize(P).multiply(normalize(F)).sum(axis=1)).ravel()
    dists = 1 - sims
    out_path = OUT / "textdist.csv"
    with open(out_path,"w",newline="") as fh:
        w = csv.writer(fh); w.writerow(["p_doc","text_dist","p_chars","f_chars"])
        for i,r in enumerate(keep):
            w.writerow([r["p_doc"], float(dists[i]), len(p_texts[i]), len(f_texts[i])])
    print(f"wrote {out_path}: mean={dists.mean():.3f} sd={dists.std():.3f} n={len(keep)}")

if __name__ == "__main__":
    main()
