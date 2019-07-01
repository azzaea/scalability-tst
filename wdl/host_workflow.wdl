
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
	command {
		echo -e "${sep='\n' result1}\n${sep='\n' result2}"| sort -u
	}
	output {
		String result = stdout()
	}

}

workflow hostwf {
	Int ntasks
	scatter (n in range(ntasks)) {
		call hostTask as host1 {input: i=n}
		call hostTask as host2 {input: i=host1.taskID}
	}
	call catHostsTask {input: result1 = host1.result, result2 = host2.result }
	output {
		File logfile = catHostsTask.result
	}
}


