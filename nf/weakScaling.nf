// I don't think I can test weak scalability in a non-dedicated cluster!

params.duration = 0
params.cores = 1

duration = params.duration
cores = params.cores

ntask = Channel.from(1..50000)

process weakScalability {
    cpus cores
    maxForks 10 //max number of process instances that can be executed in parallel. 1 means serial execution; default is number of cores-1

    input:
        val i from ntask
        val duration

    """
    sleep $duration 
    """

}
