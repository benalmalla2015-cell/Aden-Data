"""
Aden Data — Decision Tree Model Trainer
Outputs: assets/models/net_quality.aden (custom binary, ~1-3 KB)

Classes:
  0 = NORMAL      (> 500 KB/s)
  1 = DEGRADED    (50–500 KB/s)
  2 = EMERGENCY   (20–50 KB/s)
  3 = DEEP_FREEZE (< 20 KB/s)

Features:
  [throughput_kbps, latency_ms, jitter_ms, packet_loss_pct, conn_type]
"""

import struct
import os
import numpy as np
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import classification_report

rng = np.random.default_rng(42)
N   = 8000

# ── Generate synthetic training data ─────────────────────────────────────
throughput  = rng.uniform(0, 2000, N).astype(np.float32)
latency     = rng.uniform(10, 900, N).astype(np.float32)
jitter      = rng.uniform(0,  250, N).astype(np.float32)
loss        = rng.uniform(0,   70, N).astype(np.float32)
conn_type   = rng.integers(1, 3, N).astype(np.float32)

X = np.stack([throughput, latency, jitter, loss, conn_type], axis=1)

def make_label(t, lat, j, lo, _):
    if t < 20:             return 3   # DEEP_FREEZE
    if t < 50  or lo > 30: return 2   # EMERGENCY
    if t < 500 or lat > 200: return 1  # DEGRADED
    return 0                           # NORMAL

y = np.array([make_label(*row) for row in X], dtype=np.int32)

# Add 8% Gaussian noise to prevent perfect overfitting
X += rng.normal(0, X.std(0) * 0.08, X.shape).astype(np.float32)
X = np.clip(X, 0, None)

# ── Train ─────────────────────────────────────────────────────────────────
clf = DecisionTreeClassifier(
    max_depth        = 5,
    min_samples_leaf = 15,
    class_weight     = 'balanced',
    random_state     = 42,
)
clf.fit(X, y)
preds = clf.predict(X)
print("=== Training report ===")
print(classification_report(y, preds,
      target_names=['NORMAL','DEGRADED','EMERGENCY','DEEP_FREEZE']))
print(f"Nodes in tree: {clf.tree_.node_count}")

# ── Export to custom binary format (.aden) ────────────────────────────────
# Format:
#   Magic     : 4 bytes  "ADEN"
#   Version   : 1 byte   0x01
#   n_nodes   : 4 bytes  int32
#   features  : n_nodes × 4 bytes  int32   (-2 = leaf)
#   thresholds: n_nodes × 4 bytes  float32 (-2.0 = leaf)
#   left      : n_nodes × 4 bytes  int32
#   right     : n_nodes × 4 bytes  int32
#   values    : n_nodes × 4 bytes  int32   (argmax class)

t = clf.tree_
n = t.node_count

values = t.value.squeeze(axis=1).argmax(axis=1).astype(np.int32)

os.makedirs("assets/models", exist_ok=True)
out_path = "assets/models/net_quality.aden"

with open(out_path, "wb") as f:
    f.write(b"ADEN")                              # magic
    f.write(struct.pack("B", 1))                  # version
    f.write(struct.pack("<i", n))                 # n_nodes
    f.write(t.feature.astype(np.int32).tobytes()) # features
    f.write(t.threshold.astype(np.float32).tobytes()) # thresholds
    f.write(t.children_left.astype(np.int32).tobytes())  # left
    f.write(t.children_right.astype(np.int32).tobytes()) # right
    f.write(values.tobytes())                     # class values

size = os.path.getsize(out_path)
print(f"\n✅ Saved: {out_path}  ({size} bytes / {size/1024:.2f} KB)")

# ── Quick self-test ────────────────────────────────────────────────────────
tests = [
    ([2000, 20, 5,  0, 1], "NORMAL"),
    ([200,  80, 20, 5, 2], "DEGRADED"),
    ([40,  300, 80, 35, 2], "EMERGENCY"),
    ([15,  700, 150, 60, 2], "DEEP_FREEZE"),
]
labels = ['NORMAL','DEGRADED','EMERGENCY','DEEP_FREEZE']
print("\n=== Self-test ===")
for feat, expected in tests:
    pred = labels[clf.predict([feat])[0]]
    status = "✅" if pred == expected else "❌"
    print(f"  {status}  {feat} → {pred} (expected {expected})")
