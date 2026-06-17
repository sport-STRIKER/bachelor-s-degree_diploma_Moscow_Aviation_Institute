process VG_ALIGN {    
    tag "$meta.id"
    label 'process_high'

    container "quay.io/vg-zalupa-kmc:v1.60.0"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(index)

    output:
    tuple val(meta), path("*.bam"), optional: true, emit: bam
    path "versions.yml"           , emit: versions
    when:
    task.ext.when == null || task.ext.when
"""
    vg giraffe --progress \
        --sample ${meta.patient}_${meta.sample} \
        -o BAM \
        --ref-paths \$PATHLIST \
        -P -L 3000 \
        -f ${reads[0]} \
        -f ${reads[1]} \
        -Z \$INDEX_GBZ \
        --kff-name ${prefix}.kff \
        --haplotype-name \$INDEX_HAPL \
        -t ${task.cpus} \
        ${args} > raw.bam

    samtools fixmate -@ ${task.cpus-1} -m -O SAM raw.bam fixmate.sam
    samtools sort -l 2 \
        -m ${(task.memory * 3 / task.cpus / 4).getMega()}M \
        -@ ${task.cpus} \
        -o sorted.bam fixmate.sam
    samtools reheader -c "sed 's|SN:GRCh38#0#|SN:|g'" sorted.bam > reheader.bam
    samtools markdup -d 100 \
        -@ ${task.cpus-1} \
        -f ${prefix}.duplicate_metrics \
        reheader.bam ${prefix}.bam
"""
}