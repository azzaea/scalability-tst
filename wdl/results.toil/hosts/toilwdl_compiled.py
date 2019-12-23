from toil.job import Job
from toil.common import Toil
from toil.lib.docker import apiDockerCall
from toil.wdl.wdl_functions import generate_docker_bashscript_file
from toil.wdl.wdl_functions import select_first
from toil.wdl.wdl_functions import sub
from toil.wdl.wdl_functions import size
from toil.wdl.wdl_functions import glob
from toil.wdl.wdl_functions import process_and_read_file
from toil.wdl.wdl_functions import process_infile
from toil.wdl.wdl_functions import process_outfile
from toil.wdl.wdl_functions import abspath_file
from toil.wdl.wdl_functions import combine_dicts
from toil.wdl.wdl_functions import parse_memory
from toil.wdl.wdl_functions import parse_cores
from toil.wdl.wdl_functions import parse_disk
from toil.wdl.wdl_functions import read_string
from toil.wdl.wdl_functions import read_int
from toil.wdl.wdl_functions import read_float
from toil.wdl.wdl_functions import read_tsv
from toil.wdl.wdl_functions import read_csv
from toil.wdl.wdl_functions import defined
from toil.wdl.wdl_functions import basename
import fnmatch
import textwrap
import subprocess
import os
import errno
import time
import shutil
import shlex
import uuid
import logging

asldijoiu23r8u34q89fho934t8u34fcurrentworkingdir = os.getcwd()

logger = logging.getLogger(__name__)



def initialize_jobs(job):
    job.fileStore.logToMaster("initialize_jobs")


class hostTaskCls(Job):
    def __init__(self, i=None, *args, **kwargs):
        super(hostTaskCls, self).__init__(*args, **kwargs)
        cores=parse_cores(1)
        Job.__init__(self, cores=cores)

        self.id_i = i
    
    def run(self, fileStore):
        fileStore.logToMaster("hostTask")
        tempDir = fileStore.getLocalTempDir()
    
        try:
            os.makedirs(os.path.join(tempDir, 'execution'))
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
    
        i = self.id_i


        try:
            # Intended to deal with "optional" inputs that may not exist
            # TODO: handle this better
            command0 = r'''
        		hostname	
        		sleep 30
        	'''
        except:
            command0 = ''
        

        cmd = command0
        cmd = textwrap.dedent(cmd.strip("\n"))

        this_process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = this_process.communicate()
        
        taskID = 'i'
        result = (read_string((stdout)))
        rvDict = {"taskID": taskID, "result": result}
        return rvDict



class catHostsTaskCls(Job):
    def __init__(self, result1="", logfile="", *args, **kwargs):
        super(catHostsTaskCls, self).__init__(*args, **kwargs)
        self.id_result1 = result1
        self.id_logfile = logfile
    
    def run(self, fileStore):
        fileStore.logToMaster("catHostsTask")
        tempDir = fileStore.getLocalTempDir()
    
        try:
            os.makedirs(os.path.join(tempDir, 'execution'))
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
    
        result1 = self.id_result1
        logfile = self.id_logfile


        try:
            # Intended to deal with "optional" inputs that may not exist
            # TODO: handle this better
            command1 = r'''
        		echo "'''
        except:
            command1 = ''
        

        try:
            # Intended to deal with "optional" inputs that may not exist
            # TODO: handle this better
            command2 = str(';'.join(str(x) for x in result1) if not isinstance(';'.join(str(x) for x in result1), tuple) else process_and_read_file(';'.join(str(x) for x in result1), tempDir, fileStore)).strip("\n")
        except:
            command2 = ''
        

        try:
            # Intended to deal with "optional" inputs that may not exist
            # TODO: handle this better
            command3 = r'''"| tr ";" "\n" | sort -u > '''
        except:
            command3 = ''
        

        try:
            # Intended to deal with "optional" inputs that may not exist
            # TODO: handle this better
            command4 = str(logfile if not isinstance(logfile, tuple) else process_and_read_file(logfile, tempDir, fileStore)).strip("\n")
        except:
            command4 = ''
        

        try:
            # Intended to deal with "optional" inputs that may not exist
            # TODO: handle this better
            command5 = r'''
        	'''
        except:
            command5 = ''
        

        cmd = command1 + command2 + command3 + command4 + command5
        cmd = textwrap.dedent(cmd.strip("\n"))

        this_process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = this_process.communicate()
        
        # output-type: File
        output_filename = str(logfile)
        result = process_outfile(output_filename, fileStore, tempDir, '/home/a-m/azzaea/scalability-tst/wdl/results.toil/hosts')
        
        rvDict = {"result": result}
        return rvDict



class scatter0Cls(Job):
    def __init__(self, logfile=None, ntasks=None, *args, **kwargs):
        Job.__init__(self)

        self.id_logfile = logfile
        self.id_ntasks = ntasks
    
    def run(self, fileStore):
        fileStore.logToMaster("scatter0")
        tempDir = fileStore.getLocalTempDir()
    
        try:
            os.makedirs(os.path.join(tempDir, 'execution'))
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
    
        logfile = self.id_logfile
        ntasks = self.id_ntasks

        host1_taskID = []
        host1_result = []
        for n in (range(ntasks)):
            job_host1 = self.addFollowOn(hostTaskCls(i=n))
            host1_taskID.append(job_host1.rv("taskID"))
            host1_result.append(job_host1.rv("result"))

        rvDict = {"host1_taskID": host1_taskID, "host1_result": host1_result}
        return rvDict

if __name__=="__main__":
    parser = Job.Runner.getDefaultArgumentParser()
    options = parser.parse_args()
    options.clean = 'always'
    with Toil(options) as fileStore:

        # WF Declarations
        logfile = "log.txt"
        ntasks = 3

        job0 = Job.wrapJobFn(initialize_jobs)
        job0 = job0.encapsulate()
        scatter0 = job0.addChild(scatter0Cls(logfile=logfile, ntasks=ntasks))
        host1_taskID = scatter0.rv("host1_taskID")
        host1_result = scatter0.rv("host1_result")
        job0 = job0.encapsulate()
        catHostsTask = job0.addChild(catHostsTaskCls(result1=(host1_result), logfile=logfile))
        catHostsTask_result = catHostsTask.rv("result")

        fileStore.start(job0)
