# Test data

`lambda_A.fastq.gz` and `lambda_B.fastq.gz` are simulated Nanopore-like reads
(about 30x coverage, 6% error rate) from the Enterobacteria phage lambda
reference genome ([NC_001416.1](https://www.ncbi.nlm.nih.gov/nuccore/NC_001416.1)).
They are small enough to keep in the repository and assemble in a few minutes.

Regenerate them with:

```bash
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NC_001416.1&rettype=fasta" > lambda.fasta
python simulate_reads.py lambda.fasta lambda_A.fastq.gz --seed 1 --coverage 30
python simulate_reads.py lambda.fasta lambda_B.fastq.gz --seed 2 --coverage 30
```
