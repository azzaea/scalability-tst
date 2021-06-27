params.log = 'log.txt' // Default value
logfile = params.log

params.ntasks = 1   // Default value
ntasks1 = Channel.from(1..params.ntasks)

process host1 {
    input:
        val n from ntasks1

    output:
    	val n into ntasks2
        stdout names1

    """ 
    hostname 
    """
}

process host2 {
    input:
        val n from ntasks2

    output:
    	stdout names2

    """
    hostname 

    """
}




names1
     .mix(names2)
     .unique()
     .collectFile(name: "$logfile", storeDir: "$workflow.launchDir/nf.nf/hosts")
     .subscribe {println "Hostname: ${it.text}" }

