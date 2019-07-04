library(tidyverse)
library(stringr)
getwd()
data_nf_1h <- read_csv("../nf/logs-nf/bioinfoScaling_processes-1_host.txt") %>%
  mutate(wf = "Nextflow", processes = 1)
data_nf_2h <- read_csv("../nf/logs-nf/bioinfoScaling_processes-2_host.txt") %>%
  mutate(wf = "Nextflow", processes = 2)
data_wdl_1h <- read_csv("../wdl/logs-wdl/bioinfoScaling_processes-1_host.txt") %>% 
  mutate(wf = "Cromwell", processes = 1)
data_wdl_2h <- read_csv("../wdl/logs-wdl/bioinfoScaling_processes-2_host.txt") %>% 
  mutate(wf = "Cromwell", processes = 2)


bind_rows(data_nf_1h, data_nf_2h, data_wdl_1h, data_wdl_2h) %>%
  mutate(processes = as.factor(processes)) %>%
  ggplot() + geom_line(aes(x = cores, y = elapsed, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = elapsed, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Cores (==Tasks)") +  ylab("Elapsed time (s)") + theme_bw() +
  labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  ggsave("Execution_time.png")

data_nf_hosts_nodes <- read_delim("../nf/summarize_hosts_nodes.txt", delim = " ") %>%
  mutate(wf = "Nextflow")
data_wdl_hosts_nodes <- read_delim("../wdl/summarize_hosts_nodes.txt", delim = " ") %>%
  mutate(wf = "Cromwell")
  
bind_rows(data_nf_hosts_nodes, data_wdl_hosts_nodes) %>% 
  mutate(processes = as.factor(str_replace(processes, "host", "")),
         tasks = as.integer(str_replace_all(tasks, "[^0-9]", "")),
         wf = as.factor(wf)) %>%
  ggplot() + geom_line(aes(x=tasks, y = nodes, color =wf, linetype = processes)) + 
  geom_point(aes(x=tasks, y = nodes, color = wf)) +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Cores (==Tasks)") +  ylab("Nodes") + theme_bw() +
  labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  ggsave("Execution_nodes.png")
