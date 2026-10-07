process MULTIQC {
    label 'process_single'

    conda "bioconda::multiqc=1.34"
    container 'quay.io/biocontainers/multiqc:1.34--pyhdfd78af_0'

    input:
    path multiqc_files, stageAs: '?/*'
    path multiqc_config

    output:
    path "multiqc_report.html", emit: report
    path "multiqc_report_data", emit: data
    path "versions.yml",        emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    multiqc \\
        --force \\
        ${args} \\
        --filename multiqc_report.html \\
        --config ${multiqc_config} \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version 2>/dev/null | sed 's/^.*version //')
    END_VERSIONS
    """

    stub:
    """
    mkdir multiqc_report_data
    touch multiqc_report.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: stub
    END_VERSIONS
    """
}
