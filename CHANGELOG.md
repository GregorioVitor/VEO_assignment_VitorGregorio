# Changelog

## [2.0.0] - 2026-10-07

A refactor of the assignment pipeline. The analysis steps are the same; how the
pipeline is configured, run and tested is not.

### Reproducibility

- Every container is pinned to an exact Bioconda build on quay.io. v1.0 used
  `staphb/*:latest`, so the software could change between runs.
- CheckV is pinned to 1.0.3, the release that ships database v1.5 (the one used in
  the original analysis).
- Each process writes a `versions.yml`. They are merged, deduplicated and added to
  the MultiQC report and to `pipeline_info/veo_software_mqc_versions.yml`.
- `manifest` block with name, version and minimum Nextflow version (25.10.0).

### Multiple samples

- Input is now a CSV samplesheet (`sample,fastq`) validated with nf-schema,
  replacing `Channel.fromPath(params.input)`.
- A meta map carries the sample id through the workflow. Outputs are named and
  published per sample, so running several samples no longer overwrites results.
- Flye contigs are renamed `<sample>_contig_N`, keeping CheckV and QUAST tables
  unambiguous when samples are combined.

### CheckV database

- New `--checkv_db` parameter for an existing database.
- Without it, the database is downloaded once into `--checkv_db_cache` (via
  `storeDir`) and reused. v1.0 downloaded it on every run and copied several GB
  into the results folder.
- The hardcoded `checkv-db-v1.5` subpath is gone.
- New `--skip_checkv`.

### Configuration

- Resources come from process labels in `conf/base.config` with retry on
  out-of-memory, capped by `process.resourceLimits`. Removed `--threads`.
- Publishing rules and tool arguments moved to `conf/modules.config`.
- Profiles: `docker`, `singularity`, `apptainer`, `conda`, `test`. Docker is no
  longer always on.
- `nextflow_schema.json` documents and validates every parameter and enables `--help`.
- New Flye options: `--flye_mode`, `--flye_meta`, `--genome_size`.
- Default output folder is `results` (was `resultados`). `--output` was renamed to `--outdir`.
- Execution report, timeline and trace are written to `pipeline_info/`.

### Code layout

- `VEO_pipeline.nf` became `main.nf`, so the pipeline runs straight from GitHub
  with `nextflow run GregorioVitor/VEO_assignment_VitorGregorio`.
- One module file per tool under `modules/local/`, each with a stub block.
- The code passes `nextflow lint` with the strict syntax.
- Removed the BUSCO process. It was already disabled in the workflow, and BUSCO is
  not meaningful for phage genomes (see the report in `docs/`).
- Removed the empty `environment.yml`. Conda is supported through per-process
  `conda` directives and `-profile conda`.
- The assignment report moved to `docs/`.

### Testing

- nf-test suite: a real run of the `test` profile and a stub run of the full
  workflow, CheckV included.
- Bundled test data: two simulated Nanopore read sets from phage lambda, with the
  script that generates them.
- GitHub Actions runs `nextflow lint` and nf-test on Nextflow 25.10.0 and the
  latest stable release.

## [1.0-assignment] - 2026-04

The pipeline as submitted for the VEO assignment: NanoPlot, Flye, QUAST, CheckV
and MultiQC for a single sample, run with Docker.
