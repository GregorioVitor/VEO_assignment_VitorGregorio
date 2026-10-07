process NANOPLOT {
    tag "${meta.id}"
    label 'process_low'

    conda "bioconda::nanoplot=1.46.2"
    container 'quay.io/biocontainers/nanoplot:1.46.2--pyhdfd78af_1'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_nanoplot"), emit: report
    path "versions.yml",                          emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    NanoPlot \\
        ${args} \\
        --threads ${task.cpus} \\
        --fastq ${reads} \\
        --outdir ${meta.id}_nanoplot \\
        --prefix ${meta.id}_

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: \$(NanoPlot --version 2>&1 | sed 's/^NanoPlot //')
    END_VERSIONS
    """

    stub:
    """
    mkdir ${meta.id}_nanoplot
    touch ${meta.id}_nanoplot/${meta.id}_NanoStats.txt
    touch ${meta.id}_nanoplot/${meta.id}_NanoPlot-report.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: stub
    END_VERSIONS
    """
}
