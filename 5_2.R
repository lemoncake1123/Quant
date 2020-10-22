#WICS 기준 섹터정보 크롤링

library(httr)
library(rvest)
library(readr)
library(stringr)

#네이버에서는 날짜만 따옴
#Xpath를 이용하면 태그나 속성을 분해하지 않고도 원하는 지점의 데이터를 크롤링할 수 있습니다.

url = 'https://finance.naver.com/sise/sise_deposit.nhn'
biz_day = GET(url) %>%
  read_html(encoding = 'EUC-KR') %>%
  html_nodes(xpath =
               '//*[@id="type_1"]/div/ul[2]/li/span') %>%
  html_text() %>%
  str_match(('[0-9]+.[0-9]+.[0-9]+') ) %>%
  str_replace_all('\\.', '')

#글자들은 페이지에 출력된 내용이지만 매우 특이한 형태로 구성되어 있는데 이것은 JSON 형식의 데이터
#JSON 형식은 문법이 단순하고 데이터의 용량이 작아 빠른 속도로 데이터를 교환할 수 있습니다
library(jsonlite)
url = 'http://www.wiseindex.com/Index/GetIndexComponets?ceil_yn=0&dt=20201019&sec_cd=G10'
data = fromJSON(url)

#$list 항목에는 해당 섹터의 구성종목 정보가 있으며, $sector 항목을 통해 다른 섹터의 코드도 확인
#for loop 구문을 이용해 URL의 sec_cd=에 해당하는 부분만 변경하면 모든 섹터의 구성종목을 얻을.
sector_code = c('G25', 'G35', 'G50', 'G40', 'G10',
                'G20', 'G55', 'G30', 'G15', 'G45')
data_sector = list()
for (i in sector_code) {
  
  url = paste0(
    'http://www.wiseindex.com/Index/GetIndexComponets',
    '?ceil_yn=0&dt=', biz_day, '&sec_cd=', i)
  data = fromJSON(url)
  data = data$list
  
  data_sector[[i]] = data
  Sys.sleep(1)
}

data_sector = do.call(rbind, data_sector)

write.csv(data_sector, 'data/KOR_sector.csv')