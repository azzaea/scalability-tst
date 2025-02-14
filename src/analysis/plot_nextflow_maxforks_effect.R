rm(list=ls())
## Loading libraries -----------------------------------------------------------
if (! require(pacman))
  install.packages(pacman)

pacman::p_load(tidyverse, scales, viridis, ggthemes, cowplot, rcartocolor)

## Utility functions -----------------------------------------------------------
read.perf.results <- function(filename, run = F, maxForks = T){
  #filename = files.perf[1]
  data <- readr::read_csv(filename, 
                          col_types = cols(cores = col_double(), 
                                           tasks = col_double(),
                                           user = col_character(), 
                                           system = col_double(),
                                           elapsed = col_double(), 
                                           cpu = col_character(),
                                           avMemory = col_double(),
                                           involuntaryContextSwitch = 
                                             col_double(),
                                           voluntaryContextSwitch = 
                                             col_double(),
                                           faults = col_double(), 
                                           inputs = col_double(),
                                           outputs = col_double(), 
                                           socketsIn = col_double(),
                                           socketsOut = col_double(), 
                                           exitStatus = readr::col_factor()
                          )) %>%
    mutate(wf = filename %>% str_remove("/logs.*") %>% basename(), 
           processes = as.numeric(filename %>% basename() %>% 
                                    str_extract("\\d")))  
  
  if (run == T)
    data <- data %>% 
      mutate(run = filename %>% str_extract("run\\d") %>% str_remove("run"))
  
  if (maxForks == T)
    data <- data %>%
      mutate(maxForks = filename %>% str_extract(".*maxForks"),
             maxForks = basename(maxForks))
  
  return(data)
}

read.hosts.results <- function(filename, run = F, maxForks = T){
  # filename = files.nodes[1]
  data <- readr::read_delim(filename, delim = " ", 
                            col_types = list(col_double(), col_character(),
                                             col_character(), col_character())) %>%
    mutate(wf = filename %>% str_remove("/summarize.*") %>% basename())
  
  if (run == T)
    data <- data %>% 
      mutate(run = filename %>% str_extract("run\\d") %>% str_remove("run"))
  
  if (maxForks == T)
    data <- data %>%
      mutate(maxForks = filename %>% str_extract(".*maxForks"),
             maxForks = basename(maxForks))
  
  return(data)
}

plot.figs <- function(data, feature, ylabel, baseline = F){
  # data = speedup; feature = "ratio"; ylabel = "Total runtime (s)"
  frame <- data %>% 
    ggplot() + facet_grid(processes ~ .) + theme_bw() 
  
  if (baseline)
    frame <- frame + geom_line(aes(x=tasks, y = theory) , size = 1.5,
                               color = carto_pal(5, "TealGrn")[3]) 
  
  frame +  geom_smooth(aes(x = tasks, y = get(feature), color = maxForks)) +
    geom_jitter(aes(x = tasks, y = get(feature), color = maxForks, shape = maxForks),
               size = 4, width = 0)  +
    scale_shape_manual(values = c(19, 8)) +
    #scale_size(range = c(1.75, 2.5), guide = "none") + 
    scale_color_carto_d(palette = "ag_Sunset") + 
    #guides(color = guide_legend(order = 2)) +   
    scale_x_log10() + annotation_logticks(sides = 'b') +
    labs(x = "Number of tasks", y = ylabel) 
}


## Basic preps for I/O ---------------------------------------------------------
cores.per.node <- 72 # Biocluster results
results.dir <- "../../results/biocluster.2021/"

figs.dir <- file.path(results.dir, "nf.maxForks.figs")
dir.create(figs.dir)

## Timing and performance ------------------------------------------------------
files.perf <- list.files(pattern = "^bioinfoScaling_processes", 
                         path = results.dir, recursive = T, full.names = T) %>%
  str_subset("nf.nf")


data.perf <- files.perf %>% map_df(read.perf.results, run = T) %>% 
  filter(!is.na(exitStatus)) %>% 
  mutate(runStatus = fct_recode(as.character(exitStatus), 
                                Success = "0", Failure = "1" )) %>% 
  mutate(processes = factor(x = processes, 
                            labels = c("One-step", "Two-step")),
         cpu = as.double(str_remove(cpu,"%")),
         wf_order = as.numeric(factor(wf, levels = sort(unique(wf), 
                                                        decreasing = T) ))) %>% 
  select(-cores, -user, -system, -avMemory, -faults, -inputs, -outputs, 
         -socketsIn, -socketsOut, -exitStatus) 




plot_time <-  data.perf %>% #filter(!str_detect(run, '1')) %>% 
  plot.figs(feature = "elapsed", ylabel = "Total runtime (s)") +
  theme(legend.position = "none") 
ggsave(file.path(figs.dir, "Execution_time.png"), plot = plot_time)



speedup <- data.perf %>%
  select(run, wf, processes, tasks, elapsed, runStatus, maxForks) %>%
  mutate(elapsed = ifelse(runStatus == "Success", elapsed, NA)) %>% 
  # filter(!(wf == "nf.nf" & tasks == 2)) %>% 
  select(-runStatus) %>%
  pivot_wider(names_from = maxForks, values_from = elapsed) %>% #drop_na(nf.nf) %>% 
  mutate(across(matches("maxForks"), .fns = ~ . / nomaxForks)) %>% 
  pivot_longer(matches("maxForks"), names_to = "maxForks", values_to = "ratio") %>%
  mutate(wf_order = as.numeric(factor(wf, levels = sort(unique(wf), 
                                                       decreasing = T))),
         runStatus = fct_recode(as.character(!is.na(ratio)),
                                Success = "TRUE", Failure = "FALSE" ) %>%
           fct_inorder(),
         ratio = case_when(is.na(ratio) ~ 0, TRUE ~ ratio)) 



plot_speedup <- speedup %>% #filter(runStatus == "Failure") %>% View()
  plot.figs(feature = "ratio", ylabel = "Speed up") +
  scale_y_continuous(trans = "pseudo_log") + theme(legend.position = "none") 

ggsave(file.path(figs.dir, "Speedup.png"), plot = plot_speedup)

plot_speedup

# cowplot::plot_grid(plot_time + theme(legend.position = "none",
#                                      axis.title.x = element_blank()),
#                    plot_speedup + theme(legend.position = "none"),
#                    nrow = 1, rel_heights = c(.75, .25), align = "v") +


plot_cpu <- data.perf %>% 
  plot.figs(feature = "cpu", ylabel = "CPU utilization") 

ggsave(file.path(figs.dir, "CPU_utilization.png"), plot = plot_cpu)

plot_cpu

plot_involuntaryContextSwitch <- data.perf %>% #filter(!str_detect(run, '1')) %>%
  plot.figs(feature = "involuntaryContextSwitch", 
            ylabel = "Involuntary Context Switches") 
ggsave(file.path(figs.dir, "InvoluntaryContextSwitch.png"))

plot_involuntaryContextSwitch

plot_voluntaryContextSwitch <- data.perf %>% #filter(!str_detect(run, '1')) %>%
  plot.figs(feature = "voluntaryContextSwitch", ylabel = "Voluntary Context Switches") 
ggsave(file.path(figs.dir, "VoluntaryContextSwitch.png"))

plot_voluntaryContextSwitch

## Nodes' allocation -----------------------------------------------------------

files.nodes <- list.files(pattern = "summarize_hosts_nodes.txt", 
                          path = results.dir, recursive = T, full.names = T) %>%
  str_subset("nf.nf")

nodes.info <- files.nodes %>% map_df(read.hosts.results, run = T) %>%
  mutate(tasks = as.numeric(str_replace_all(tasks, "[^0-9]", ""))) %>%
  mutate(processes = as.numeric(str_replace(processes, "host", "")) %>%
           factor(x = ., labels = c("One-step", "Two-step"))) %>%
  filter(tasks < 1000) %>% complete(wf, run, tasks, processes)


data.nodes <- left_join(data.perf, nodes.info, 
                        by = c( "tasks" = "tasks", "wf" = "wf",
                               "processes" = "processes", "run" = "run",
                               "maxForks" = "maxForks"))  %>%
  #"processes" = "processes"))  %>% # 2019 compatible
  select(tasks, wf, processes, nodes, runStatus, wf_order, maxForks) %>% 
  mutate(theory =ceiling(tasks/cores.per.node), 
         nodes = case_when(!is.na(nodes) ~ nodes,
                           is.na(nodes) ~ 0))

plot_nodes <- data.nodes %>% 
  plot.figs(feature = "nodes", ylabel = "Total occupied nodes", baseline = T) +
  scale_y_continuous(trans = "pseudo_log", limits = c(0,10)) 
# annotate("Text", x = 1, y = 10, hjust = 0,
#          label = "AWS Compute nodes:\n\tType: m5a.24xlarge \n\tCores: 96") +
ggsave(file.path(figs.dir, "Execution_nodes.png"))

plot_nodes

plot_times_nodes <- plot_grid(plot_time + theme(legend.position = "none"), 
                              plot_nodes + theme(legend.position = "none"), 
                              nrow = 1) 
plot_times_nodes  

legend <- get_legend(plot_time + theme( legend.position = "top", 
                                        legend.box = "horizontal"))

plot_grid(legend,plot_times_nodes, nrow=2, rel_heights = c(.5,4))
ggsave(file.path(figs.dir, "times_nodes.png"), 
       units = "in", width = 10, height = 4.16)

plot_time_speed_nodes <- plot_grid(plot_time, plot_speedup, 
                                   plot_nodes + theme(legend.position = "none"),
                                   nrow = 1)
plot_grid(legend, plot_time_speed_nodes, nrow = 2, rel_heights = c(.5, 4)) 
ggsave(file.path(figs.dir, "times_speed_nodes.png"), 
       units = "in", width = 10, height = 4.16)
