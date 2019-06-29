params.duration = 0 // Default value
duration = params.duration

params.ntasks = 1   // Default value
ntasks1 = Channel.from(1..params.ntasks)

params.forks = 1    // Default value
forks = params.forks

process sleep1 {
    // tag "sleep_1-fork_$forks-ntask_$n"
    maxForks forks //max process instances executed in parallel. 1 means serial execution; default is number of cores-1

    input:
        val n from ntasks1
        val duration
	val forks

    output:
    	val n into ntasks2

    """
    #sleep $duration 
    # echo $SLURM_NODEID
    """
}



