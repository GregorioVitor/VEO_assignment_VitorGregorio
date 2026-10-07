process QUAST {
    tag "${meta.id}"
    label 'process_low'

    conda "bioconda::quast=5.3.0"
    container 'quay.io/biocontainers/quast:5.3.0--py313pl5321h5ca1c30_2'

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${meta.id}_quast"), emit: results
    path "versions.yml",                       emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    quast.py \\
        ${args} \\
        --threads ${task.cpus} \\
        --labels ${meta.id} \\
        --output-dir ${meta.id}_quast \\
        ${assembly}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/^.*QUAST v//; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    mkdir ${meta.id}_quast
    touch ${meta.id}_quast/report.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: stub
    END_VERSIONS
    """
}
