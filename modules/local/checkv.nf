// CheckV 1.0.x downloads database v1.5, the release used in the original analysis.

process CHECKV_DOWNLOADDATABASE {
    label 'process_single'

    conda "bioconda::checkv=1.0.3"
    container 'quay.io/biocontainers/checkv:1.0.3--pyhdfd78af_0'

    output:
    path "checkv_db",    emit: db
    path "versions.yml", emit: versions

    script:
    """
    checkv download_database download
    mv download/checkv-db-v* checkv_db
    rm -rf download

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkv: \$(checkv -h 2>&1 | sed -n 's/^.*CheckV v//; s/: assessing.*//; 1p')
    END_VERSIONS
    """

    stub:
    """
    mkdir checkv_db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkv: stub
    END_VERSIONS
    """
}

process CHECKV_ENDTOEND {
    tag "${meta.id}"
    label 'process_medium'

    conda "bioconda::checkv=1.0.3"
    container 'quay.io/biocontainers/checkv:1.0.3--pyhdfd78af_0'

    input:
    tuple val(meta), path(assembly)
    path db

    output:
    tuple val(meta), path("${meta.id}_checkv"),                        emit: results
    tuple val(meta), path("${meta.id}_checkv/quality_summary.tsv"),    emit: quality_summary
    path "versions.yml",                                               emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    checkv end_to_end \\
        ${args} \\
        -t ${task.cpus} \\
        -d ${db} \\
        ${assembly} \\
        ${meta.id}_checkv

    # Intermediate files are large and only useful for debugging
    rm -rf ${meta.id}_checkv/tmp

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkv: \$(checkv -h 2>&1 | sed -n 's/^.*CheckV v//; s/: assessing.*//; 1p')
    END_VERSIONS
    """

    stub:
    """
    mkdir ${meta.id}_checkv
    printf 'contig_id\\tcheckv_quality\\tcompleteness\\n${meta.id}_contig_1\\tHigh-quality\\t100\\n' \\
        > ${meta.id}_checkv/quality_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkv: stub
    END_VERSIONS
    """
}
