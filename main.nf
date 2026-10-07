#!/usr/bin/env nextflow
/*
 * Nanopore phage assembly and QC
 *
 *   reads -> NanoPlot (read QC)
 *         -> Flye (de novo assembly) -> QUAST (assembly QC)
 *                                    -> CheckV (viral genome completeness)
 *   all QC outputs + software versions -> MultiQC
 */

include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'

include { NANOPLOT                                 } from './modules/local/nanoplot'
include { FLYE                                     } from './modules/local/flye'
include { QUAST                                    } from './modules/local/quast'
include { CHECKV_DOWNLOADDATABASE; CHECKV_ENDTOEND } from './modules/local/checkv'
include { MULTIQC                                  } from './modules/local/multiqc'

workflow {

    validateParameters()
    log.info paramsSummaryLog(workflow)

    def ch_reads    = channel.fromList(readSamplesheet(params.input))
    def ch_versions = channel.empty()
    def ch_multiqc  = channel.empty()

    // Read QC
    NANOPLOT(ch_reads)
    ch_versions = ch_versions.mix(NANOPLOT.out.versions)
    ch_multiqc  = ch_multiqc.mix(NANOPLOT.out.report.map { _meta, dir -> dir })

    // Assembly
    FLYE(ch_reads, params.flye_mode)
    ch_versions = ch_versions.mix(FLYE.out.versions)

    // Assembly QC
    QUAST(FLYE.out.fasta)
    ch_versions = ch_versions.mix(QUAST.out.versions)
    ch_multiqc  = ch_multiqc.mix(QUAST.out.results.map { _meta, dir -> dir })

    // Viral completeness
    if (!params.skip_checkv) {
        def ch_checkv_db
        if (params.checkv_db) {
            ch_checkv_db = channel.value(file(params.checkv_db, checkIfExists: true))
        }
        else {
            CHECKV_DOWNLOADDATABASE()
            ch_checkv_db = CHECKV_DOWNLOADDATABASE.out.db
            ch_versions  = ch_versions.mix(CHECKV_DOWNLOADDATABASE.out.versions)
        }
        CHECKV_ENDTOEND(FLYE.out.fasta, ch_checkv_db)
        ch_versions = ch_versions.mix(CHECKV_ENDTOEND.out.versions)
        ch_multiqc  = ch_multiqc.mix(CHECKV_ENDTOEND.out.quality_summary.map { _meta, tsv -> tsv })
    }

    // Software versions, deduplicated across samples, in the format MultiQC expects
    def ch_versions_yml = ch_versions
        .map { yml -> yml.text.trim() }
        .unique()
        .mix(channel.value(workflowVersionsYaml()))
        .collectFile(
            name: 'veo_software_mqc_versions.yml',
            storeDir: "${params.outdir}/pipeline_info",
            newLine: true,
            sort: true,
        )

    MULTIQC(
        ch_multiqc.mix(ch_versions_yml).collect(),
        file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
    )
}

/*
 * Parse and validate the samplesheet. Relative fastq paths are resolved against
 * the samplesheet's own directory, so a samplesheet can travel with its data.
 */
def readSamplesheet(input) {
    def samplesheet = file(input, checkIfExists: true)
    return samplesheetToList(samplesheet, "${projectDir}/assets/schema_input.json").collect { meta, fastq ->
        def reads = fastq ==~ /^(\/|[a-zA-Z][a-zA-Z0-9+.-]*:\/\/).*/
            ? file(fastq)
            : samplesheet.parent.resolve(fastq)
        if (!reads.exists()) {
            error("Sample '${meta.id}': fastq file not found: ${reads}")
        }
        [meta, reads]
    }
}

def workflowVersionsYaml() {
    return """
    Workflow:
        ${workflow.manifest.name}: ${workflow.manifest.version}
        Nextflow: ${workflow.nextflow.version}
    """.stripIndent().trim()
}
