#금융 데이터 수집하기 (심화)
#6.1 수정주가 크롤링

#URL에서 symbol= 뒤에 6자리 티커
library(stringr)
#csv 파일을 불러옵니다
KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1)

#005930이어야 할 삼성전자의 티커가 5930으로 입력되어 있습니다. 
print(KOR_ticker$'종목코드'[1])

#stringr 패키지의 str_pad() 함수를 사용해 6자리가 되지 않는 문자는 왼쪽에 0을 추가해 강제로 6자리로
KOR_ticker$'종목코드' = str_pad(KOR_ticker$'종목코드', 6, side = c('left'), pad = '0')

#삼성전자의 주가를 크롤링한 후 가공
library(xts)
# data 폴더 내에 KOR_price 폴더를 생성
ifelse(dir.exists('data/KOR_price'), FALSE,
       dir.create('data/KOR_price'))
# 향후 for loop 구문을 통해 i 값만 변경하면 모든 종목의 주가를 다운로드할 수 있습니다.
i=1

# name에 해당 티커를 입력
name=KOR_ticker$'종목코드'[i]

# xts() 함수를 이용해 빈 시계열 데이터를 생성하며, 인덱스는 Sys.Date()를 통해 현재 날짜를 입력
price=xts(NA, order.by = Sys.Date())

library(httr)
library(rvest)
#url 중 티커에 해당하는 6자리 부분만 위에서 입력한 name으로 설정
url=paste0(
  'https://fchart.stock.naver.com/sise.nhn?symbol=', name, '&timeframe=day&count=500&requestType=0')

data=GET(url)

#html_nodes()와 html_attr() 함수를 통해 item 태그 및 data 속성의 데이터를 추출합니다. 
data_html=read_html(data, encoding = 'EUC-KR')  %>% 
  html_nodes('item') %>% 
  html_attr('data')

#날짜 및 주가, 거래량 데이터가 추출됩니다. 해당 데이터는 |으로 구분되어 있으며, 이를 테이블 형태로 바꿀 필요
# readr 패키지의 read_delim() 함수를 쓰면 구분자로 이루어진 데이터를 테이블로 쉽게 변경
library(readr)
price = read_delim(data_html, delim = '|')
print(head(price))

#우리가 필요한 날짜와 종가를 선택한 후 데이터 클렌징
library(lubridate)
library(timetk)

#날짜에 해당하는 첫 번째 열과, 종가에 해당하는 다섯 번째 열만 선택해 저장
price=price[c(1, 5)]

#티블 형태의 데이터를 데이터 프레임 형태로 변경
price=data.frame(price)

#열 이름을 Date와 Price로 변경
colnames(price)=c('Date', 'Price')

#lubridate 패키지의 ymd() 함수를 이용하면 yyyymmdd 형태가 yyyy-mm-dd로 변경되며 데이터 형태 또한 Date 타입으로 변경
price[, 1]=ymd(price[,1])

#timetk 패키지의 tk_xts() 함수를 이용해 시계열 형태로 변경하며, 인덱스는 Date 열을 설정합니다. 
#형태를 변경한 후 해당 열은 자동으로 삭제됩니다.
price=tk_xts(price, date_var = Date)

write.csv(price, paste0('data/KOR_price/', name, '_price.csv'))