params.duration = 0
params.cores = 1

duration = params.duration
cores = params.cores

ntask = Channel.from(1..params.ntasks)

process strongScalability {
    tag "process_$i"
    input:
        val i from ntask
        val duration

    """
    sleep $duration 
    """

}
