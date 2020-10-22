#최근 영업일 기준 데이터 받기
Sys.setenv(LANG="en")

#크롤링하고자 하는 데이터가 하나거나 소수일때는 HTML 구조를 모두 분해한 후 데이터를 
#추출하는 것보다 Xpath를 이용하는 것이 훨씬 효율적입니다. 
#네이버에서는 날짜만 따옴
library(httr)
library(rvest)
library(readr)
library(stringr)


#Xpath를 이용하면 태그나 속성을 분해하지 않고도 원하는 지점의 데이터를 크롤링할 수 있습니다.
url = 'https://finance.naver.com/sise/sise_deposit.nhn'

biz_day = GET(url) %>%
  read_html(encoding = 'EUC-KR') %>%
  html_nodes(xpath =
               '//*[@id="type_1"]/div/ul[2]/li/span') %>%
  html_text() %>%
  str_match(('[0-9]+.[0-9]+.[0-9]+') ) %>%
  str_replace_all('\\.', '')


# 산업별 현황 OTP 발급
gen_otp_url =
  'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
gen_otp_data = list(
  name = 'fileDown',
  filetype = 'csv',
  url = 'MKD/03/0303/03030103/mkd03030103',
  tp_cd = 'ALL',
  date = '20190607',
  lang = 'ko',
  pagePath = '/contents/MKD/03/0303/03030103/MKD03030103.jsp')
#쿼리 보내기
otp = POST(gen_otp_url, query = gen_otp_data) %>%
  read_html() %>%
  html_text()

#생성된 OTP를 제출하면, 우리가 원하는 데이터를 다운로드할 수 있습니다.
down_url = 'http://file.krx.co.kr/download.jspx'
down_sector = POST(down_url, query = list(code = otp),
                   add_headers(referer = gen_otp_url)) %>%
  read_html() %>%
  html_text() %>%
  read_csv()

#data라는 이름의 폴더가 있으면 FALSE를 반환하고, 없으면 해당 이름으로 폴더를 생성
ifelse(dir.exists('data'), FALSE, dir.create('data'))
write.csv(down_sector, 'data/krx_sector.csv')


# 개별종목 지표 OTP 발급
gen_otp_url = 'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
gen_otp_data = list(
  name = 'fileDown',
  filetype = 'csv',
  url = 'MKD/13/1302/13020401/mkd13020401',
  market_gubun = 'ALL',
  gubun = '1',
  schdate = biz_day,
  pagePath = '/contents/MKD/13/1302/13020401/MKD13020401.jsp')

otp = POST(gen_otp_url, query = gen_otp_data) %>% 
  read_html() %>% 
  html_text()

down_url = 'http://file.krx.co.kr/download.jspx'
down_ind = POST(down_url, query = list(code =otp),
                add_headers(referer = gen_otp_url)) %>% 
  read_html() %>% 
  html_text() %>% 
  read_csv()

write.csv(down_ind, 'data/krx_ind2.csv')


#데이터 정리하기, 첫 번째 열을 행 이름, 문자열 데이터가 팩터 형태로 변형되지 않게
down_sector = read.csv('data/krx_sector.csv', row.names = 1, stringsAsFactors = F)
down_ind = read.csv('data/krx_ind2.csv', row.names = 1, stringsAsFactors = F)

#두 데이터 간 중복되는 열 이름을 살펴보면 종목코드와 종목명이 동일한 위치에 있습니다.
intersect(names(down_sector), names(down_ind))

#두 데이터에 공통적으로 없는 종목명, 즉 하나의 데이터에만 있는 종목
setdiff(down_sector[, '종목명'], down_ind[, '종목명'])
#해당 종목들은 선박펀드, 광물펀드, 해외종목 등 일반적이지 않은 종목들이므로 제외


#둘 사이에 공통적으로 존재하는 종목을 기준으로 데이터를 합쳐주겠습니다
#merge() 함수는 by를 기준으로 두 데이터를 하나로 합치며
#공통으로 존재하는 종목코드, 종목명을 기준으로 입력.
#all 값을 TRUE로 설정하면 합집합을 반환하고, FALSE로 설정하면 교집합을 반환
KOR_ticker = merge(down_sector, down_ind,
                   by = intersect(names(down_sector),
                                  names(down_ind)),
                  all = F)
#내림차순 정렬, R은 기본적으로 오름차순으로 순서를 구하므로 앞에 마이너스(-)를 붙여 내림차순 형태
KOR_ticker = KOR_ticker[order(-KOR_ticker['시가총액.원.']), ]

#스팩, 우선주 종목 제외
#grepl() 함수를 통해 종목명에 ‘스팩’이 들어가는 종목을 찾고
KOR_ticker = KOR_ticker[!grepl('스팩', KOR_ticker[, '종목명']), ]
#stringr 패키지의 str_sub() 함수를 통해 종목코드 끝이 0이 아닌 우선주 종목을 찾을 수 있습니다
KOR_ticker = KOR_ticker[str_sub(KOR_ticker[, '종목코드'], -1, -1) == 0, ]

#행 이름을 초기화한 후 정리된 데이터를 csv 파일로
row.names(KOR_ticker) = NULL
write.csv(KOR_ticker, 'data/KOR_ticker.csv')