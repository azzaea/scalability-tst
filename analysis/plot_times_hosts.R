library(tidyverse)
library(stringr)
require(scales)

data_nf_1h <- read_csv("../nf/logs-nf/bioinfoScaling_processes-1_host.txt") %>%
  mutate(wf = "Nextflow", processes = 1)
data_nf_2h <- read_csv("../nf/logs-nf/bioinfoScaling_processes-2_host.txt") %>%
  mutate(wf = "Nextflow", processes = 2)
data_wdl_1h <- read_csv("../wdl/logs-wdl/bioinfoScaling_processes-1_host.txt") %>% 
  mutate(wf = "Cromwell", processes = 1)
data_wdl_2h <- read_csv("../wdl/logs-wdl/bioinfoScaling_processes-2_host.txt") %>% 
  mutate(wf = "Cromwell", processes = 2)

res_performance <- bind_rows(data_nf_1h, data_nf_2h, data_wdl_1h, data_wdl_2h) %>% 
  filter(!is.na(exitStatus)) %>% 
  mutate(processes = processes)

speedup <- res_performance %>%
  select(elapsed, wf, processes, cores) %>%
  spread(wf, elapsed) %>% mutate(ratio = Cromwell/ Nextflow)

plot_time <- res_performance %>%
  ggplot() + geom_line(aes(x = cores, y = elapsed, color = wf, linetype = as.factor(processes))) +
  geom_point(aes(x = cores, y = elapsed, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks (log10 scale)") +  ylab("Elapsed time (s)") + theme_bw() +
  labs(color = str_wrap("Executor", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) # + 

plot_time
plot_speedup <- ggplot(speedup) + geom_line(aes(x = cores, y = ratio, linetype = as.factor(processes))) +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks (log10 scale)") +  ylab("Elapsed time (s)") + theme_bw() +
  labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1))
cowplot::plot_grid(plot_time + theme(legend.position = "top", axis.title.x = element_blank()) , 
                   plot_speedup + theme(legend.position = "none") + ylab("Speed up"), 
                   nrow = 2, rel_heights = c(.75, .25), align = "v") +  ggsave("Execution_time.png")

plot_cpu <- res_performance %>% 
  mutate(cpu = as.double(str_remove(cpu,"%")),
         processes = as.factor(processes)) %>%
  ggplot() + geom_line(aes(x = cores, y = cpu, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = cpu, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("CPU utilization") + theme_bw() +
  labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  ggsave("CPU_utilization.png")

plot_involuntaryContextSwitch <- res_performance %>% 
  mutate(processes = as.factor(processes)) %>%
  ggplot() + geom_line(aes(x = cores, y = involuntaryContextSwitch, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = involuntaryContextSwitch, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') + 
  xlab("Number of tasks") +  ylab("Involuntary Context Switches") + theme_bw() +
  labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  ggsave("InvoluntaryContextSwitch.png")

plot_voluntaryContextSwitch <- res_performance %>% 
  mutate(processes = as.factor(processes)) %>%
  ggplot() + geom_line(aes(x = cores, y = voluntaryContextSwitch, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = voluntaryContextSwitch, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("Voluntary Context Switches") + theme_bw() +
  labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  ggsave("VoluntaryContextSwitch.png")

data_nf_hosts_nodes <- read_delim("../nf/summarize_hosts_nodes.txt", delim = " ") %>%
  mutate(wf = "Nextflow")
data_wdl_hosts_nodes <- read_delim("../wdl/summarize_hosts_nodes.txt", delim = " ") %>%
  mutate(wf = "Cromwell")
  
nodes <- bind_rows(data_nf_hosts_nodes, data_wdl_hosts_nodes) %>% 
  mutate(processes = as.double(str_replace(processes, "host", "")),
         tasks = as.double(str_replace_all(tasks, "[^0-9]", "")))
          
plot_nodes <- left_join(res_performance, nodes, 
                        by = c("wf" = "wf", "tasks" = "tasks", "processes" = "processes" ))  %>%
  mutate(theory = ceiling(tasks/96)) %>% 
  ggplot() + geom_line(aes(x=tasks, y = nodes, color =wf, linetype = as.factor(processes))) + 
  geom_point(aes(x=tasks, y = nodes, color = wf)) +
  geom_line(aes(x=tasks, y = theory)) +
  scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
                labels = trans_format("log10", math_format(10^.x))) +
  annotation_logticks(sides = 'b') +
  xlab("Number of tasks (log10 scale)") +  ylab("Nodes") + theme_bw() +
  labs(color = str_wrap("Executor", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  annotate("Text", x = 1, y = 10, hjust = 0,
           label = "AWS Compute nodes:\n\tType: m5a.24xlarge \n\tCores: 96") +
  theme(legend.position = "top") + 
  ggsave("Execution_nodes.png")

  