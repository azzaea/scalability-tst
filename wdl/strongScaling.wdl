version 1.0

task sleepTask {
	input {
		Float duration 
		Int i
	}
	command {
		sleep ${duration}
	}
}

workflow ScalabilityWf {
	input {
		Int ntask
	}
	scatter (n in range(ntask)) {
		call sleepTask {input: i=n}
	}
}



