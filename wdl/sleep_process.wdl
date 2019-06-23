task sleepTask {
	Float duration 
	Int i
	
	command {
		sleep ${duration}
	}
	output {
		Int taskID = i 
	}
}

workflow sleepwf {
    Float duration
	Int ntasks
	scatter (n in range(ntasks)) {
		call sleepTask as sleep1 {input: i=n, duration=duration}
	}
}





