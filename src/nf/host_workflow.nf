params.log = 'log.txt' // Default value
logfile = params.log

params.ntasks = 1   // Default value
ntasks1 = Channel.from(1..params.ntasks)

process host1 {
    input:
        val n from ntasks1

    output:
    	val n into ntasks2
        stdout result1

    """ 
    hostname 
    """
}

process host2 {
    input:
        val n from ntasks2

    output:
    	stdout result2

    """
    hostname 

    """
}




result1
     .mix(result2)
     .unique()
     .collectFile(name: "$logfile", storeDir: "$workflow.launchDir/nf.nf/hosts")
     .subscribe {println "Hostname: ${it.text}" }

