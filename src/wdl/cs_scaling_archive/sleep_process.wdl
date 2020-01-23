task sleepTask {
	Float duration 
	Int i
	
	command {
		sleep ${duration}
	}
	output {
		Int taskID = i 
	}
	runtime {
		cpu:  1
	}
}

workflow sleepwf {
    Float duration
	Int ntasks
	scatter (n in range(ntasks)) {
		call sleepTask as sleep1 {input: i=n, duration=duration}
	}
}





