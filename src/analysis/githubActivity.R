library(gh)
library(plyr)
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))

library(tidyr)
library(curl)
suppressPackageStartupMessages(library(readr))
library(xtable)

repos <- tribble(~owner, ~repo,
                 "swift-lang", "swift-t",
                 "nextflow-io", "nextflow",
                 "common-workflow-language", "common-workflow-language",
                 "openwdl", "wdl",
                 # "toil", "toil", 
                 # "cwltool", "cwltool"
                 # "broadinstitute", "cromwell ",
)


## open/closed issues ------------------------------------------------------------
issues.pulls <- map2(repos$owner, repos$repo, 
               ~gh("/repos/:owner/:repo/issues", owner = .x, repo = .y, state = "all", 
                   .limit = Inf, 
              .token = "37fae244f9523252594034345b1ef99f34aaa39c")) %>% 
  map(function(x) state = map_chr(x, "state")) %>% setNames(repos$repo) %>% 
  map_dfr(table, .id = "wfms") 

## license ------------------------------------------------------------------------
license <- map2(repos$owner, repos$repo, 
                     ~gh("/repos/:owner/:repo/license", owner = .x, repo = .y, .limit = Inf, 
                         .token = "37fae244f9523252594034345b1ef99f34aaa39c")) %>% 
  tibble(wfms = repos$repo, license = map_chr(., c("license", "key"))) %>% 
  select(-`.`)


## contributors ---------------------------------------------------------------------
contribs <- map2(repos$owner, repos$repo, 
              ~gh("/repos/:owner/:repo/contributors", owner = .x, repo = .y, .limit = Inf, 
                  .token = "37fae244f9523252594034345b1ef99f34aaa39c")) %>% 
  tibble(wfms = repos$repo, contributors = map_int(., length)) %>%
  select(-`.`)

  
## first commit ------------------------------------------------------------------------
first.commit <- map2(repos$owner, repos$repo, 
            ~gh("/repos/:owner/:repo/commits", owner = .x, repo = .y, .limit = Inf,
                until = "2017-01-01T00:00:00Z",
                .token = "37fae244f9523252594034345b1ef99f34aaa39c")) %>%
  map(function(x) state = map_chr(x, c("commit", "author", "date" ))) %>% 
  map(as.Date) %>%  map(sort) %>% map(1) %>% map(as.character) %>%
  tibble(wfms = repos$repo, first.com = map_chr(., 1)) %>%
  select(-`.`)

## gitter/slack channels/mailing list,workflows repositories,-----------------------------

## Aggregating data,----------------------------------------------------------------------
join_all(list(first.commit, contribs, issues.pulls, license)) %>% as_tibble()

xtable(join_all(list(first.commit, contribs, issues.pulls, license)), type = "latex")
