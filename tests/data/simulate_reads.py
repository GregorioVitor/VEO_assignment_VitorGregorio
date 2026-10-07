#!/usr/bin/env python3
"""Simulate small Nanopore-like read sets for the pipeline tests.

Reads are random fragments of a reference genome (both strands) with
log-normal lengths and about 6% substitution/insertion/deletion errors.
The output is deterministic for a given seed.

Usage:
    python simulate_reads.py lambda.fasta lambda_A.fastq.gz --seed 1 --coverage 30
"""
import argparse
import gzip
import math
import random

COMPLEMENT = str.maketrans("ACGT", "TGCA")
BASES = "ACGT"


def read_fasta(path):
    with open(path) as handle:
        return "".join(line.strip() for line in handle if not line.startswith(">")).upper()


def add_errors(seq, rng, error_rate):
    out = []
    for base in seq:
        r = rng.random()
        if r < error_rate * 0.4:  # substitution
            out.append(rng.choice(BASES.replace(base, "")))
        elif r < error_rate * 0.7:  # deletion
            continue
        elif r < error_rate:  # insertion
            out.append(base)
            out.append(rng.choice(BASES))
        else:
            out.append(base)
    return "".join(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("reference")
    parser.add_argument("output")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--coverage", type=float, default=30)
    parser.add_argument("--mean-length", type=int, default=6000)
    parser.add_argument("--error-rate", type=float, default=0.06)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    genome = read_fasta(args.reference)
    target = len(genome) * args.coverage
    sigma = 0.5
    mu = math.log(args.mean_length) - sigma**2 / 2

    total, n = 0, 0
    with gzip.open(args.output, "wt", compresslevel=9) as out:
        while total < target:
            length = min(max(int(rng.lognormvariate(mu, sigma)), 500), len(genome))
            start = rng.randrange(0, len(genome) - length + 1)
            frag = genome[start : start + length]
            if rng.random() < 0.5:
                frag = frag.translate(COMPLEMENT)[::-1]
            read = add_errors(frag, rng, args.error_rate)
            qual = "".join(chr(33 + min(max(int(rng.gauss(14, 2)), 5), 30)) for _ in read)
            n += 1
            total += len(read)
            out.write(f"@read_{n} sim_start={start} len={length}\n{read}\n+\n{qual}\n")

    print(f"{args.output}: {n} reads, {total} bases, {total / len(genome):.1f}x")


if __name__ == "__main__":
    main()
