import sys;

@dispatch=WORKER
app (void signal) sleep (int secs) {
          "/bin/sleep" secs
}

int duration = string2int(argv("duration"));
int ntask = string2int(argv("ntask"));

foreach i in [1:ntask:1] {
        sleep(duration);
}

