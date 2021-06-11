## Loading libraries -----------------------------------------------------------
if (! require(pacman))
  install.packages(pacman)

pacman::p_load(tidyverse, scales, viridis, ggthemes, cowplot, rcartocolor)

## Utility functions -----------------------------------------------------------
read.perf.results <- function(filename){
  #filename = perf.files[1]
  readr::read_csv(filename, 
                  col_types = cols(cores = col_double(), 
                                   tasks = col_double(),
                                   user = col_character(), 
                                   system = col_double(),
                                   elapsed = col_double(), 
                                   cpu = col_character(),
                                   avMemory = col_double(),
                                   involuntaryContextSwitch = col_double(),
                                   voluntaryContextSwitch = col_double(),
                                   faults = col_double(), 
                                   inputs = col_double(),
                                   outputs = col_double(), 
                                   socketsIn = col_double(),
                                   socketsOut = col_double(), 
                                   exitStatus = readr::col_factor())) %>%
    mutate(wf = filename %>% str_remove("/logs.*") %>% basename(), 
           processes = as.numeric(filename %>% basename() %>% str_extract("\\d"))) 
}

read.hosts.results <- function(filename){
  # filename = nodes.files[1]
  readr::read_delim(filename, delim = " ") %>%
    mutate(wf = filename %>% str_remove("/summarize.*") %>% basename())
}

## Basic preps for I/O ---------------------------------------------------------
cores.per.node <- 72 # Biocluster results
results.dir <- "../../results/biocluster.2021"

figs.dir <- file.path(results.dir, "figs")
dir.create(figs.dir)

## Timing and performance ------------------------------------------------------
perf.files <- list.files(pattern = "^bioinfoScaling_processes", 
                         path = results.dir, recursive = T, full.names = T)

# perf.files <- list.files(pattern = "^bioinfoScaling_processes", 
#                        path = "../../results/biocluster.2019/", 
#            recursive = T, full.names = T)

data.perf <- perf.files %>% map_df(read.perf.results) %>% 
  filter(!is.na(exitStatus)) %>% 
  mutate(runStatus = case_when(exitStatus == 0 ~ "Success",
                               exitStatus != 0~ "Failure")) %>%
  mutate(wf_size = as.numeric(factor(wf, levels = sort(unique(wf), decreasing = T))),
         processes = as.factor(processes))

plot_time <-  data.perf %>% ggplot() + 
  geom_line(aes(x = cores, y = elapsed, color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = elapsed, color = wf, shape = runStatus, 
                 size = wf_size))  +
  # geom_rect(data = failed_tasks, aes(xmin = xmin, xmax = xmax, 
  #                                    ymin = ymin, ymax = max(data.perf$elapsed)), alpha = .4) +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("Total runtime (s)") + theme_bw() +
  labs(color = str_wrap("Executor", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 2)) + 
  scale_color_carto_d(palette = "ag_Sunset") + 
  scale_shape_manual(values = c(1, 19, 8)) + 
  scale_size(range = c(1.75, 2.5), guide = "none") + 
  #theme(legend.position = "none") +
  facet_grid(processes~.) + 
  ggsave(file.path(figs.dir, "Execution_time_split.png"))

plot_time

# speedup <- data.perf %>%
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
#     scale_color_carto_d(palette = "ag_Sunset")
# 
# plot_speedup

# cowplot::plot_grid(plot_time + theme(legend.position = "none", 
#                                      axis.title.x = element_blank()), 
#                    plot_speedup + theme(legend.position = "none"), 
#                    nrow = 2, rel_heights = c(.75, .25), align = "v") +  
#   ggsave("Execution_time.png")

plot_cpu <- data.perf %>% 
  mutate(cpu = as.double(str_remove(cpu,"%"))) %>%
  ggplot() + geom_line(aes(x = cores, y = cpu, color = wf, 
                           linetype = processes)) +
  geom_point(aes(x = cores, y = cpu, color = wf, shape = runStatus), size = 2.5) +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("CPU utilization") + theme_bw() +
  labs(color = str_wrap("Engine", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  theme(legend.position = "right", legend.box = "vertical") +
  scale_color_carto_d(palette = "ag_Sunset") + scale_shape_manual(values = c(1, 19, 8)) +
  facet_grid(processes~.) +
  ggsave(file.path(figs.dir, "CPU_utilization_split.png"))

plot_cpu

plot_involuntaryContextSwitch <- data.perf %>% 
  ggplot() + geom_line(aes(x = cores, y = involuntaryContextSwitch, 
                           color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = involuntaryContextSwitch, color = wf, 
                 shape = runStatus), size = 2.5)  +
  scale_x_log10() + annotation_logticks(sides = 'b') + 
  xlab("Number of tasks") +  ylab("Involuntary Context Switches") + theme_bw() +
  labs(color = str_wrap("Engine", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + scale_color_carto_d(palette = "ag_Sunset") + 
  theme(legend.position = "right", legend.box = "vertical") +
  scale_shape_manual(values = c(1, 19, 8)) +
  facet_grid(processes~.) +
  ggsave(file.path(figs.dir, "InvoluntaryContextSwitch_split.png"))

plot_involuntaryContextSwitch

plot_voluntaryContextSwitch <- data.perf %>%
  ggplot() + geom_line(aes(x = cores, y = voluntaryContextSwitch,
                           color = wf, linetype = processes)) +
  geom_point(aes(x = cores, y = voluntaryContextSwitch, color = wf,
                 shape = runStatus), size = 2.5)  +
  scale_x_log10() + annotation_logticks(sides = 'b') +
  xlab("Number of tasks") +  ylab("Voluntary Context Switches") + theme_bw() +
  labs(color = str_wrap("Engine", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) +   scale_color_carto_d(palette = "ag_Sunset") +
  theme(legend.position = "right", legend.box = "vertical") +
  scale_shape_manual(values = c(1, 19, 8)) +
  facet_grid(processes~.) +
  ggsave(file.path(figs.dir, "VoluntaryContextSwitch_split.png"))

plot_voluntaryContextSwitch

## Nodes' allocation -----------------------------------------------------------

nodes.files <- list.files(pattern = "summarize_hosts_nodes.txt", 
                          path = results.dir, recursive = T, full.names = T)

nodes <- nodes.files %>% map_df(read.hosts.results) %>%
  mutate(processes = as.factor(as.numeric(str_replace(processes, "host", ""))),
         tasks = as.numeric(str_replace_all(tasks, "[^0-9]", "")))


data.nodes <- left_join(data.perf, nodes, 
                        by = c("wf" = "wf", "tasks" = "tasks", 
                               "processes" = "processes" ))  %>% 
  select(tasks, wf, processes, nodes, runStatus, wf_size) %>% 
  mutate(theory =ceiling(tasks/cores.per.node), 
         nodes = case_when(!is.na(nodes) ~ nodes,
                           is.na(nodes) ~ 0))

plot_nodes <- data.nodes %>% ggplot() +
  geom_line(aes(x=tasks, y = theory) , size = 1.5, color = carto_pal(5, "TealGrn")[3]) +
  geom_line(aes(x=tasks, y = nodes, color =wf, linetype = processes))+#, 
            #position=position_jitter(w=0.07, h=0)) + 
  geom_point(aes(x=tasks, y = nodes, color = wf, shape = runStatus, size = wf_size)) +
  # geom_rect(data = failed_tasks, aes(xmin = xmin, xmax = xmax, 
  #                                    = ymin, ymax = max(data.nodes$theory)), alpha = .4) +
  scale_x_log10(name = "Number of tasks", ) +
  scale_y_continuous(name = "Total occupied nodes", trans = "pseudo_log", limits = c(0,10)) +
  scale_color_carto_d(palette = "ag_Sunset") +
  scale_size(range = c(1.75, 3.5), guide = "none") +
  annotation_logticks(sides = 'b') +
  theme_bw() + 
  labs(color = str_wrap("Executor", 10), linetype = "Workflow steps") +
  guides(color = guide_legend(order = 1)) + 
  # annotate("Text", x = 1, y = 10, hjust = 0,
  #          label = "AWS Compute nodes:\n\tType: m5a.24xlarge \n\tCores: 96") +
  scale_shape_manual(values = c(1, 19, 8)) +
  facet_grid(processes~.) +
  ggsave(file.path(figs.dir, "Execution_nodes_split.png"))

plot_nodes

plot_times_nodes <- plot_grid(plot_time + theme(legend.position = "none"), 
                              plot_nodes + theme(legend.position = "none"), 
                              nrow = 1) 
plot_times_nodes  

legend <- get_legend(plot_time + theme( legend.position = "top", legend.box = "horizontal"))

plot_grid(legend,plot_times_nodes, nrow=2, rel_heights = c(.5,4)) +
  ggsave(file.path(figs.dir, "times_nodes_split.png"), 
         units = "in", width = 10, height = 4.16)

