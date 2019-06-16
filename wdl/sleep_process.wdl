version 1.0

task sleepTask {
	input {
		Float duration 
		Int i
	}
	command {
		sleep ${duration}
	}
	output {
		Int taskID = i 
	}
}

workflow sleep1 {
	input {
		Int ntasks
	}
	scatter (n in range(ntasks)) {
		call sleepTask {input: i=n}
	}
}





