rm(list=ls())
getwd()
library(tidyverse)
library(stringr)
require(scales)
library(viridis)
library(ggthemes)

# Biocluster results
cores.per.node <- 72 # 72 for biocluster, 96 for aws

data_nf_1h <- read_csv("../../results.biocluster/nf/logs-nf/bioinfoScaling_processes-1_host.txt", skip = 2) %>%
  mutate(wf = "Nextflow", processes = 1)
data_nf_2h <- read_csv("../../results.biocluster/nf/logs-nf/bioinfoScaling_processes-2_host.txt", skip = 2) %>%
  mutate(wf = "Nextflow", processes = 2)
data_wdl_1h <- read_csv("../../results.biocluster/cromwell.wdl/logs-wdl/bioinfoScaling_processes-1_host.txt") %>% 
  mutate(wf = "Cromwell_wdl", processes = 1)
data_wdl_2h <- read_csv("../../results.biocluster/cromwell.wdl/logs-wdl/bioinfoScaling_processes-2_host.txt") %>% 
  mutate(wf = "Cromwell_wdl", processes = 2)
data_cwl_1h <- read_csv("../../results.biocluster/cromwell.cwl//logs-cwl/bioinfoScaling_processes-1_host.txt") %>% 
  mutate(wf = "Cromwell_cwl", processes = 1)
data_cwl_2h <- read_csv("../../results.biocluster/cromwell.cwl/logs-cwl/bioinfoScaling_processes-2_host.txt") %>%
  mutate(wf = "Cromwell_cwl", processes = 2)


res_performance <- bind_rows(data_nf_1h, data_nf_2h, data_wdl_1h, data_wdl_2h ) %>% 
  bind_rows(data_cwl_1h, data_cwl_2h) %>% #CWL results if present
  filter(!is.na(exitStatus)) %>% 
  mutate(processes = processes)

(plot_time <- res_performance %>%
  ggplot() + geom_line(aes(x = cores, y = elapsed, color = wf, linetype = as.factor(processes))) +
  geom_point(aes(x = cores, y = elapsed, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("Total runtime (s)") + theme_bw() +
  labs(color = str_wrap("Executor", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 2)) + 
  scale_color_colorblind())
    

speedup <- res_performance %>%
  select(elapsed, wf, processes, cores) %>% 
  spread(wf, elapsed) %>%
  mutate(ratio_wdl = Cromwell_wdl/Nextflow) %>%
  mutate(ratio_cwl = Cromwell_cwl/ Nextflow) #CWL results if present



(plot_speedup <- speedup %>% select(-Nextflow, -contains("Cromwell")) %>%
  gather(ratio, value, -cores, -processes) %>% filter(!is.na(value)) %>% ggplot() + 
  geom_line(aes(x = cores, y = value, linetype = as.factor(processes),
                color = as.factor(ratio))) +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("Speed up") + theme_bw() +
  labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  scale_color_colorblind())



cowplot::plot_grid(plot_time + theme(legend.position = "none", 
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
  labs(color = str_wrap("Engine", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + theme(legend.position = "top", legend.box = "vertical") +
  scale_color_colorblind() +
  ggsave("CPU_utilization.png")

plot_involuntaryContextSwitch <- res_performance %>% 
  mutate(processes = as.factor(processes)) %>%
  ggplot() + geom_line(aes(x = cores, y = involuntaryContextSwitch, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = involuntaryContextSwitch, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') + 
  xlab("Number of tasks") +  ylab("Involuntary Context Switches") + theme_bw() +
  labs(color = str_wrap("Engine", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  scale_color_colorblind() + theme(legend.position = "top", legend.box = "vertical") +
  ggsave("InvoluntaryContextSwitch.png")

plot_voluntaryContextSwitch <- res_performance %>% 
  mutate(processes = as.factor(processes)) %>%
  ggplot() + geom_line(aes(x = cores, y = voluntaryContextSwitch, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = voluntaryContextSwitch, color = wf))  +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("Voluntary Context Switches") + theme_bw() +
  labs(color = str_wrap("Engine", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  scale_color_colorblind() + theme(legend.position = "top", legend.box = "vertical") +
  ggsave("VoluntaryContextSwitch.png")

data_nf_hosts_nodes <- read_delim("../../results.biocluster/nf/summarize_hosts_nodes.txt", delim = " ") %>%
  mutate(wf = "Nextflow")
data_wdl_hosts_nodes <- read_delim("../../results.biocluster/cromwell.wdl/summarize_hosts_nodes.txt", delim = " ") %>%
  mutate(wf = "Cromwell_wdl")
data_cwl_hosts_nodes <- read_delim("../../results.biocluster/cromwell.cwl/summarize_hosts_nodes.txt", delim = " ") %>%
  mutate(wf = "Cromwell_cwl")
  
nodes <- bind_rows(data_nf_hosts_nodes, data_wdl_hosts_nodes) %>%
  bind_rows(data_cwl_hosts_nodes) %>% # if cwl results exist
  mutate(processes = as.double(str_replace(processes, "host", "")),
         tasks = as.double(str_replace_all(tasks, "[^0-9]", "")))
          
# plot_nodes <- 
  nodes %>% #filter(!duplicated(tasks)) %>% mutate(wf = "theory", nodes = ceiling(tasks/96)))) %>%
  mutate(theory = ceiling(tasks/cores.per.node)) %>% 
  ggplot() + 
    geom_line(aes(x=tasks, y = theory), size = 1.5, color = "#009E73") +
  geom_line(aes(x=tasks, y = nodes, color =wf, linetype = as.factor(processes))) + 
  geom_point(aes(x=tasks, y = nodes, color = wf)) +
  scale_x_log10(name = "Number of tasks") + #,
    # breaks = trans_breaks("log10", function(x) 10^x),
    #             labels = trans_format("log10", math_format(10^.x))) +
  scale_y_continuous(name = "Total occupied nodes", breaks = seq(1,10,1)) +
  scale_color_colorblind() +
  annotation_logticks(sides = 'b') +
  theme_bw() + 
  labs(color = str_wrap("Executor", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  # annotate("Text", x = 1, y = 7, hjust = 0,
  #           label = "Biocluster Compute nodes:\n\tType: Supermicro SYS-2049U-TR4 \n\tCores: 72") +
  theme(legend.position = "none") #+
  ggsave("Execution_nodes.png")

  