
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

workflow hostwf {
	Int ntasks
	scatter (n in range(ntasks)) {
		call hostTask as host1 {input: i=n}
	}
	output {
		File logfile = write_lines(host1.result)
	}
}





