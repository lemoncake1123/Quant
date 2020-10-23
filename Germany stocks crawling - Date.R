Sys.setenv(LANG="en")
library(httr, help, pos = 2, lib.loc = NULL)
library(rvest, help, pos = 2, lib.loc = NULL)
library(readr, help, pos = 2, lib.loc = NULL)
library(stringr, help, pos = 2, lib.loc = NULL)


url='https://www.boerse-frankfurt.de/aktien'


biz_day=GET(url) %>%
  read_html(encooding='UTF-8') %>%
  html_nodes(xpath='/html/body/app-root/app-wrapper/div/div[2]/app-equities/div[3]/div[2]/app-widget-market-indicators/div/h2/span') %>%
  html_text() %>%
  str_match(('[0-9]+.[0-9]+.[0-9]+')) %>%
  str_replace_all('\\.', '')


biz_day


