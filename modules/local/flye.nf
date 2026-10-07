process FLYE {
    tag "${meta.id}"
    label 'process_high'

    conda "bioconda::flye=2.9.6"
    container 'quay.io/biocontainers/flye:2.9.6--py310h275bdba_0'

    input:
    tuple val(meta), path(reads)
    val mode

    output:
    tuple val(meta), path("${meta.id}.assembly.fasta"),      emit: fasta
    tuple val(meta), path("${meta.id}.assembly_info.txt"),   emit: info
    tuple val(meta), path("${meta.id}.assembly_graph.gfa"),  emit: gfa
    tuple val(meta), path("${meta.id}.flye.log"),            emit: log
    path "versions.yml",                                     emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    flye \\
        --${mode} ${reads} \\
        --out-dir flye_out \\
        --threads ${task.cpus} \\
        ${args}

    # Prefix contig names with the sample id so downstream tables stay unambiguous
    sed 's/^>/>${meta.id}_/' flye_out/assembly.fasta > ${meta.id}.assembly.fasta
    mv flye_out/assembly_info.txt  ${meta.id}.assembly_info.txt
    mv flye_out/assembly_graph.gfa ${meta.id}.assembly_graph.gfa
    mv flye_out/flye.log           ${meta.id}.flye.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$(flye --version)
    END_VERSIONS
    """

    stub:
    """
    printf '>${meta.id}_contig_1\\nACGT\\n' > ${meta.id}.assembly.fasta
    touch ${meta.id}.assembly_info.txt ${meta.id}.assembly_graph.gfa ${meta.id}.flye.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: stub
    END_VERSIONS
    """
}
