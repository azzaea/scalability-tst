params.log = 'log.txt' // Default value
logfile = params.log

params.ntasks = 1   // Default value
ntasks1 = Channel.from(1..params.ntasks)

params.forks = 1    // Default value
forks = params.forks

process host1 {
    maxForks forks //max process instances executed in parallel. 1 means serial execution; default is number of cores-1

    input:
        val n from ntasks1
	val forks

    output:
    	val n into ntasks2
	stdout result1

    """ 
    
    hostname 

    """
}


result1
     .unique()
     .collectFile(name: "$logfile", storeDir: "$workflow.launchDir/nf.nf/hosts")
     .subscribe {println "Hostname: ${it.text}" }

