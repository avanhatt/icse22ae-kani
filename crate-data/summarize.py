import csv
import sys
import statistics
import json


def summarize():
    reader = csv.DictReader(sys.stdin)
    counts = [int(row['result']) for row in reader]

    nonzero = sum(c > 0 for c in counts)
    vals = {
        'total': len(counts),
        'nonzero': sum(c > 0 for c in counts),
        'nonzero-pct': '{:.0f}'.format(nonzero / len(counts) * 100),
        'mean': statistics.mean(counts),
        'median': statistics.median(counts),
    }

    print(json.dumps(vals, indent=2, sort_keys=True))


if __name__ == '__main__':
    summarize()