
task hostTask {
	Int i

	command {
		hostname	
	}
	output {
		Int taskID = i 
		String result = read_string(stdout())
	}
	runtime {
		cpu:  1
	}
}

task catHostsTask {
	Array[String] result1
	Array[String] result2
	String logfile

	command {
		#echo "${sep=';' result1}"| tr ";" "\n" | sort -u > ${logfile}
        echo "${sep=';' result1};${sep=';' result2}" | tr ";" "\n" | sort -u > ${logfile}
	}
	output {
		File result = "${logfile}"
	}
}

workflow hostwf {
    String logfile2
	Int ntasks

	scatter (n in range(ntasks)) {
		call hostTask as host1 {input: i=n}
		call hostTask as host2 {input: i=host1.taskID}
	}

	call catHostsTask {input: result1 = host1.result, result2 = host2.result, logfile = logfile2 }

	output {
		File log = catHostsTask.result
	}
}

