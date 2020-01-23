getwd()
library(tidyverse)
library(stringr)
require(scales)

data_nf_1h <- read_csv("../nf/results.nf/logs-nf/bioinfoScaling_processes-1_host.txt") %>%
  mutate(wf = "Nextflow", processes = 1)
data_nf_2h <- read_csv("../nf/results.nf/logs-nf/bioinfoScaling_processes-2_host.txt") %>%
  mutate(wf = "Nextflow", processes = 2)
data_wdl_1h <- read_csv("../wdl/results.cromwell/logs-wdl/bioinfoScaling_processes-1_host.txt") %>% 
  mutate(wf = "Cromwell_wdl", processes = 1)
data_wdl_2h <- read_csv("../wdl/results.cromwell/logs-wdl/bioinfoScaling_processes-2_host.txt") %>% 
  mutate(wf = "Cromwell_wdl", processes = 2)
data_cwl_1h <- read_csv("../cwl/results.cromwell/logs-cwl/bioinfoScaling_processes-1_host.txt") %>% 
  mutate(wf = "Cromwell_cwl", processes = 1)
data_cwl_2h <- read_csv("../cwl/results.cromwell/logs-cwl/bioinfoScaling_processes-2_host.txt") %>% 
  mutate(wf = "Cromwell_cwl", processes = 2)


colors <- c("#CC6666", "#9999CC", "#66CC99")

res_performance <- bind_rows(data_nf_1h, data_nf_2h, data_wdl_1h, data_wdl_2h,
                             data_cwl_1h, data_cwl_2h) %>% 
  filter(!is.na(exitStatus)) %>% 
  mutate(processes = processes)

speedup <- res_performance %>%
  select(elapsed, wf, processes, cores) %>%
  spread(wf, elapsed) %>% 
  mutate(ratioCWL = Cromwell_cwl/ Nextflow, ratioWDL = Cromwell_wdl/Nextflow)

plot_time <- res_performance %>%
  ggplot() + geom_line(aes(x = cores, y = elapsed, color = wf, linetype = as.factor(processes))) +
  geom_point(aes(x = cores, y = elapsed, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks (log10 scale)") +  ylab("Elapsed time (s)") + theme_bw() +
  labs(color = str_wrap("Executor", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) +
  scale_color_manual(values = colors)

plot_time 

plot_speedup <- speedup %>% select(-Cromwell_cwl, -Cromwell_wdl, -Nextflow) %>% 
  gather(ratio, value, -cores, -processes) %>% ggplot() + 
  geom_line(aes(x = cores, y = value, linetype = as.factor(processes),
                color = as.factor(ratio))) +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks (log10 scale)") +  ylab("Speed up") + theme_bw() +
  labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  scale_color_manual(values = colors)

plot_speedup 

cowplot::plot_grid(plot_time + theme(legend.position = "top", 
                                     axis.title.x = element_blank()), 
                   plot_speedup + theme(legend.position = "none"), 
                   nrow = 2, rel_heights = c(.75, .25), align = "v") +  
  ggsave("Execution_time.png")


plot_cpu <- res_performance %>% 
  mutate(cpu = as.double(str_remove(cpu,"%")),
         processes = as.factor(processes)) %>%
  ggplot() + geom_line(aes(x = cores, y = cpu, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = cpu, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("CPU utilization") + theme_bw() +
  labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  scale_color_manual(values = colors) +
  ggsave("CPU_utilization.png")

plot_involuntaryContextSwitch <- res_performance %>% 
  mutate(processes = as.factor(processes)) %>%
  ggplot() + geom_line(aes(x = cores, y = involuntaryContextSwitch, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = involuntaryContextSwitch, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') + 
  xlab("Number of tasks") +  ylab("Involuntary Context Switches") + theme_bw() +
  labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  scale_color_manual(values = colors) +
  ggsave("InvoluntaryContextSwitch.png")

plot_voluntaryContextSwitch <- res_performance %>% 
  mutate(processes = as.factor(processes)) %>%
  ggplot() + geom_line(aes(x = cores, y = voluntaryContextSwitch, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = voluntaryContextSwitch, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("Voluntary Context Switches") + theme_bw() +
  labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  scale_color_manual(values = colors) +
  ggsave("VoluntaryContextSwitch.png")

data_nf_hosts_nodes <- read_delim("../nf/results.nf/summarize_hosts_nodes.txt", delim = " ") %>%
  mutate(wf = "Nextflow")
data_wdl_hosts_nodes <- read_delim("../wdl/results.cromwell/summarize_hosts_nodes.txt", delim = " ") %>%
  mutate(wf = "Cromwell_wdl")
data_cwl_hosts_nodes <- read_delim("../cwl/results.cromwell/summarize_hosts_nodes.txt", delim = " ") %>%
  mutate(wf = "Cromwell_cwl")
  
nodes <- bind_rows(data_nf_hosts_nodes, data_wdl_hosts_nodes, data_cwl_hosts_nodes) %>% 
  mutate(processes = as.double(str_replace(processes, "host", "")),
         tasks = as.double(str_replace_all(tasks, "[^0-9]", "")))
          
plot_nodes <- left_join(res_performance, nodes, 
                        by = c("wf" = "wf", "tasks" = "tasks", "processes" = "processes" ))  %>%
  mutate(theory = ceiling(tasks/96)) %>% 
  ggplot() + 
  geom_line(aes(x=tasks, y = nodes, color =wf, linetype = as.factor(processes))) + 
  geom_point(aes(x=tasks, y = nodes, color = wf)) +
  geom_line(aes(x=tasks, y = theory)) +
  scale_x_log10(name = "Number of tasks (log10 scale)",
    breaks = trans_breaks("log10", function(x) 10^x),
                labels = trans_format("log10", math_format(10^.x))) +
  scale_y_continuous(name = "Nodes", breaks = seq(1,10,1)) +
  scale_color_manual(values = colors) +
  annotation_logticks(sides = 'b') +
  theme_bw() +
  labs(color = str_wrap("Executor", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  # annotate("Text", x = 1, y = 10, hjust = 0,
  #          label = "AWS Compute nodes:\n\tType: m5a.24xlarge \n\tCores: 96") +
  theme(legend.position = "top") +
  ggsave("Execution_nodes.png")

  