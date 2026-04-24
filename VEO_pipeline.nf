#!/usr/bin/env nextflow 

params.threads = params.threads ?: 8
params.output = params.output ?: "resultados"

process qc_nanoplot { 
    container 'staphb/nanoplot:latest' 
    cpus params.threads
    publishDir params.output + "/qc", mode: 'copy'

    input: 
    path raw_file 
    
    output: 
    path "nanoplot_output" 
    
    script: 
    """ 
    NanoPlot -t ${task.cpus} --fastq ${raw_file} -o nanoplot_output
    """ 
} 

process assembly_flye { 
    container 'staphb/flye:latest' 
    cpus params.threads
    publishDir params.output + "/assembly", mode: 'copy'
    input: 
    path raw_file 
    
    output: 
    path "flye_output/flye.log", emit: flye_logs
    path "flye_output/assembly.fasta", emit: assembly
    
    script: 
    """ 
    flye --nano-raw ${raw_file} --out-dir flye_output --threads ${task.cpus} 
    """ 
}

process qc_assembly_quast { 
    container 'staphb/quast:latest' 
    cpus params.threads
    publishDir params.output + "/quast", mode: 'copy'
    input: 
    path assembly
    
    output: 
    path "quast_output" 
    
    script: 
    """ 
    quast.py ${assembly} -o quast_output -t ${task.cpus} 
    """ 
}

process characterize_busco { 
    container 'ezlabgva/busco:v6.0.0_cv1' 
    cpus params.threads
    publishDir params.output + "/busco", mode: 'copy'

    input: 
    path assembly
    
    output: 
    path "busco_output" 
    
    script: 
    """ 
    busco -i ${assembly} -o busco_output -m genome -c ${task.cpus} --auto-lineage
    """ 
}

process download_checkv_db {
    container 'staphb/checkv:latest'
    containerOptions '--entrypoint ""'
    publishDir params.output + "/checkv_db", mode: 'copy'

    output:
    path "checkv_db_files", emit: db_folder

    script:
    """
    checkv download_database checkv_db_files
    """
}

process characterize_checkv { 
    container 'staphb/checkv:latest' 
    cpus params.threads
    containerOptions '--entrypoint ""'
    publishDir params.output + "/checkv", mode: 'copy'

    input: 
    path assembly
    path db_path

    output: 
    path "checkv_output/*", emit: chv_logs
    
    script: 
    """ 
    checkv end_to_end ${assembly} checkv_output -t ${task.cpus} -d ${db_path}/checkv-db-v1.5
    """ 
}

process generate_report_multiqc {
    container 'staphb/multiqc:latest'
    publishDir params.output + "/final_report", mode: 'copy'

    input:
    path results

    output:
    path "multiqc_report.html"

    script:
    """
    multiqc . -f
    """
}


workflow { 
    reads_ch = Channel.fromPath(params.input)

    qcr = qc_nanoplot(reads_ch)
    asm = assembly_flye(reads_ch)
    qca = qc_assembly_quast(asm.assembly)
    //bus = characterize_busco(asm.assembly)
    db = download_checkv_db()
    chv = characterize_checkv(asm.assembly, db.db_folder)
    generate_report_multiqc( qcr.mix(asm.flye_logs, qca, chv.chv_logs).collect() )

}
