rm(list=ls())
getwd()
library(tidyverse)
library(stringr)
require(scales)
library(viridis)
library(ggthemes)

# Biocluster results
cores.per.node <- 96 # 72 for biocluster, 96 for aws

data_nf_1h <- read_csv("../../results.aws/nf/logs-nf/bioinfoScaling_processes-1_host.txt", 
                       col_types = cols(cores = col_double(), tasks = col_double(),
                                        user = col_character(), system = col_double(),
                                        elapsed = col_double(), cpu = col_character(),
                                        avMemory = col_double(),
                                        involuntaryContextSwitch = col_double(),
                                        voluntaryContextSwitch = col_double(),
                                        faults = col_double(), inputs = col_double(),
                                        outputs = col_double(), socketsIn = col_double(),
                                        socketsOut = col_double(), 
                                        exitStatus = readr::col_factor())) %>%
  mutate(wf = "Nextflow", processes = 1) 
data_nf_2h <- read_csv("../../results.aws/nf/logs-nf/bioinfoScaling_processes-2_host.txt",
                       col_types = cols(cores = col_double(), tasks = col_double(),
                                        user = col_character(), system = col_double(),
                                        elapsed = col_double(), cpu = col_character(),
                                        avMemory = col_double(),
                                        involuntaryContextSwitch = col_double(),
                                        voluntaryContextSwitch = col_double(),
                                        faults = col_double(), inputs = col_double(),
                                        outputs = col_double(), socketsIn = col_double(),
                                        socketsOut = col_double(), 
                                        exitStatus = readr::col_factor())) %>%
  mutate(wf = "Nextflow", processes = 2) 
data_wdl_1h <- read_csv("../../results.aws/cromwell.wdl/logs-wdl/bioinfoScaling_processes-1_host.txt",
                        col_types = cols(cores = col_double(), tasks = col_double(),
                                         user = col_character(), system = col_double(),
                                         elapsed = col_double(), cpu = col_character(),
                                         avMemory = col_double(),
                                         involuntaryContextSwitch = col_double(),
                                         voluntaryContextSwitch = col_double(),
                                         faults = col_double(), inputs = col_double(),
                                         outputs = col_double(), socketsIn = col_double(),
                                         socketsOut = col_double(), 
                                         exitStatus = readr::col_factor())) %>%
  mutate(wf = "Cromwell_wdl", processes = 1) 
data_wdl_2h <- read_csv("../../results.aws/cromwell.wdl/logs-wdl/bioinfoScaling_processes-2_host.txt",
                        col_types = cols(cores = col_double(), tasks = col_double(),
                                         user = col_character(), system = col_double(),
                                         elapsed = col_double(), cpu = col_character(),
                                         avMemory = col_double(),
                                         involuntaryContextSwitch = col_double(),
                                         voluntaryContextSwitch = col_double(),
                                         faults = col_double(), inputs = col_double(),
                                         outputs = col_double(), socketsIn = col_double(),
                                         socketsOut = col_double(), 
                                         exitStatus = readr::col_factor())) %>%
  mutate(wf = "Cromwell_wdl", processes = 2) %>% filter(!is.na(system))


res_performance <- bind_rows(data_nf_1h, data_nf_2h, data_wdl_1h, data_wdl_2h) %>% 
  filter(!is.na(exitStatus)) %>% 
  mutate(runStatus = case_when(exitStatus == 0 ~ "Success",
                             exitStatus != 0~ "Failure")) %>%
  mutate(wf_size = case_when(wf == "Nextflow" ~ 2,
                             wf == "Cromwell_wdl" ~ 1))
plot_time <- res_performance %>%
    ggplot() + 
  geom_line(aes(x = cores, y = elapsed, color = wf, linetype = as.factor(processes))) +
    geom_point(aes(x = cores, y = elapsed, color = wf, shape = runStatus, size = wf_size))  +
      # geom_rect(data = failed_tasks, aes(xmin = xmin, xmax = xmax, 
      #                                    ymin = ymin, ymax = max(res_performance$elapsed)), alpha = .4) +
    scale_x_log10() + annotation_logticks(sides = 'b') +
    xlab("Number of tasks") +  ylab("Total runtime (s)") + theme_bw() +
    labs(color = str_wrap("Executor", 10), linetype = "Workflow steps") +
    guides(color = guide_legend(order = 2)) + 
    scale_color_colorblind() + scale_shape_manual(values = c(1, 19, 8)) + 
    scale_size(range = c(1.75, 2.5)) +
  theme(legend.position = "none") +
  ggsave("Execution_time.png")
    
plot_time

# speedup <- res_performance %>%
#   select(elapsed, wf, processes, cores) %>% 
#   spread(wf, elapsed) %>%
#   mutate(ratio_wdl = Cromwell_wdl/Nextflow) 

# plot_speedup <- speedup %>% select(-Nextflow, -contains("Cromwell")) %>%
#     gather(ratio, value, -cores, -processes) %>% filter(!is.na(value)) %>% ggplot() + 
#     geom_line(aes(x = cores, y = value, linetype = as.factor(processes),
#                   color = as.factor(ratio))) +
#     geom_rect(data = failed_tasks, aes(xmin = xmin, xmax = xmax,
#                                        ymin = ymin, ymax = ymax/4), alpha = .4) +
#     scale_x_log10() + annotation_logticks(sides = 'b') +
#     xlab("Number of tasks") +  ylab("Speed up") + theme_bw() +
#     labs(color = str_wrap("Workflow management system", 10), linetype = "Workflow steps") +
#     guides(color = guide_legend(order = 1)) + 
#     scale_color_colorblind()
# 
# plot_speedup

# cowplot::plot_grid(plot_time + theme(legend.position = "none", 
#                                      axis.title.x = element_blank()), 
#                    plot_speedup + theme(legend.position = "none"), 
#                    nrow = 2, rel_heights = c(.75, .25), align = "v") +  
#   ggsave("Execution_time.png")


plot_cpu <- res_performance %>% 
  mutate(cpu = as.double(str_remove(cpu,"%")),
         processes = as.factor(processes)) %>%
  ggplot() + geom_line(aes(x = cores, y = cpu, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = cpu, color = wf, shape = runStatus), size = 2.5) +
  # geom_rect(data = failed_tasks, aes(xmin = xmin, xmax = xmax, 
  #                                    ymin = ymin, ymax = ymax + 100), alpha = .4) +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("CPU utilization") + theme_bw() +
  labs(color = str_wrap("Engine", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  theme(legend.position = "top", legend.box = "vertical") +
  scale_color_colorblind() + scale_shape_manual(values = c(1, 19, 8)) +
  ggsave("CPU_utilization.png")

plot_cpu

plot_involuntaryContextSwitch <- res_performance %>% 
  mutate(processes = as.factor(processes)) %>%
  ggplot() + 
  geom_line(aes(x = cores, y = involuntaryContextSwitch, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = involuntaryContextSwitch, color = wf, shape = runStatus), 
             size = 2.5)  +
  # geom_rect(data = failed_tasks, aes(xmin = xmin, xmax = xmax, 
  #                                    ymin = ymin, ymax = max(res_performance$involuntaryContextSwitch)), 
  #           alpha = .4) +
  scale_x_log10() + annotation_logticks(sides = 'b') + 
  xlab("Number of tasks") +  ylab("Involuntary Context Switches") + theme_bw() +
  labs(color = str_wrap("Engine", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  scale_color_colorblind() + theme(legend.position = "top", legend.box = "vertical") +
  scale_shape_manual(values = c(1, 19, 8)) +
  ggsave("InvoluntaryContextSwitch.png")

plot_involuntaryContextSwitch

plot_voluntaryContextSwitch <- res_performance %>% 
  mutate(processes = as.factor(processes)) %>%
  ggplot() + geom_line(aes(x = cores, y = voluntaryContextSwitch, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = voluntaryContextSwitch, color = wf, shape = runStatus), 
             size = 2.5)  +
  # geom_rect(data = failed_tasks, aes(xmin = xmin, xmax = xmax, 
  #                                    ymin = ymin, ymax = max(res_performance$voluntaryContextSwitch)), 
  #           alpha = .4) +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("Voluntary Context Switches") + theme_bw() +
  labs(color = str_wrap("Engine", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  scale_color_colorblind() + theme(legend.position = "top", legend.box = "vertical") +
  scale_shape_manual(values = c(1, 19, 8)) +
  ggsave("VoluntaryContextSwitch.png")

plot_voluntaryContextSwitch

data_nf_hosts_nodes <- read_delim("../../results.aws/nf/summarize_hosts_nodes.txt", delim = " ") %>%
  mutate(wf = "Nextflow")
data_wdl_hosts_nodes <- read_delim("../../results.aws/cromwell.wdl/summarize_hosts_nodes.txt", 
                                   delim = " ") %>%
  mutate(wf = "Cromwell_wdl")


nodes <- bind_rows(data_nf_hosts_nodes, data_wdl_hosts_nodes) %>%
  # bind_rows(data_cwl_hosts_nodes) %>% # if cwl results exist
  mutate(processes = as.double(str_replace(processes, "host", "")),
         tasks = as.double(str_replace_all(tasks, "[^0-9]", "")))


nodes_data <-  left_join(res_performance, nodes, 
                        by = c("wf" = "wf", "tasks" = "tasks", "processes" = "processes" ))  %>% 
  select(tasks, wf, processes, nodes, runStatus, wf_size) %>% 
  mutate(theory =ceiling(tasks/cores.per.node), 
         nodes = case_when(!is.na(nodes) ~ nodes,
                           is.na(nodes) ~ 0))

plot_nodes <- 
  nodes_data %>% ggplot() +
    geom_line(aes(x=tasks, y = theory) , size = 1.5, color = "#009E73") +
  geom_line(aes(x=tasks, y = nodes, color =wf, linetype = factor(processes)), 
             position=position_jitter(w=0.07, h=0)
            ) + 
  geom_point(aes(x=tasks, y = nodes, color = wf, shape = runStatus, size = wf_size)) +

  # geom_rect(data = failed_tasks, aes(xmin = xmin, xmax = xmax, 
  #                                    = ymin, ymax = max(nodes_data$theory)), alpha = .4) +
  scale_x_log10(name = "Number of tasks", ) +
  scale_y_continuous(name = "Total occupied nodes", trans = "pseudo_log", limits = c(0,100)) +
  scale_color_colorblind() +
    scale_size(range = c(1.75, 3.5)) +
    
  annotation_logticks(sides = 'b') +
  theme_bw() + 
  labs(color = str_wrap("Executor", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  # annotate("Text", x = 1, y = 10, hjust = 0,
  #          label = "AWS Compute nodes:\n\tType: m5a.24xlarge \n\tCores: 96") +
  theme(legend.position = "none", axis.ticks.x = element_line()) +
  scale_shape_manual(values = c(1, 19, 8)) +
  ggsave("Execution_nodes.png")


plot_times_nodes <- cowplot::plot_grid(plot_time + theme(legend.position = "none", 
                                     ), 
                   plot_nodes + theme(legend.position = "none"), 
                   nrow = 1) #+  
  
legend <- cowplot::get_legend(
  # create some space to the left of the legend
  plot_time + theme( legend.position = "none")
)

cowplot::plot_grid(legend,plot_times_nodes, nrow=2, rel_heights = c(.5,4)) +
ggsave("times_nodes.png", units = "in", width = 7.25, height = 4.16)

