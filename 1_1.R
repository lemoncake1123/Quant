#언어 변경
Sys.setenv(LANG="en")

#패키지 설치
pkg = c('magrittr', 'quantmod', 'rvest', 'httr', 'jsonlite',
        'readr', 'readxl', 'stringr', 'lubridate', 'dplyr',
        'tidyr', 'ggplot2', 'corrplot', 'dygraphs',
        'highcharter', 'plotly', 'PerformanceAnalytics',
        'nloptr', 'quadprog', 'RiskPortfolios', 'cccp',
        'timetk', 'broom', 'stargazer', 'timeSeries')

new.pkg = pkg[!(pkg %in% installed.packages()[, "Package"])]
if (length(new.pkg)) {
  install.packages(new.pkg, dependencies = TRUE)}

##크롤링
#주소 불러오기
url.aapl = "https://www.quandl.com/api/v3/datasets/WIKI/AAPL/data.csv?api_key=xw3NU3xLUZ7vZgrz5QnG"
data.aapl = read.csv(url.aapl)

#getSymbol을 이용한 API에 접속
library(quantmod)
ticker <- c('NVDA', 'AAPL') #애플과 앤비디아
getSymbols(ticker)

#Ad는 배당이 반영된 수정주가, 
chart_Series(Ad(NVDA), 
             from = '2020-01-01', 
             to = Sys.time(),
             auto.assign = FALSE)

#국내 종목 주가 다운로드, 삼성전자, 따음표 방향에 주의.
getSymbols('005930.KS',
           from = '2020-01-01', 
           to = '2020-10-17')
tail(Ad(`005930.KS`))
chart_Series(Ad(`005930.KS`), 
             from = '2020-01-01', 
             to = Sys.time(),
             auto.assign = FALSE)

# FRED 데이터 다운로드, 미 국채 10년물 금리
getSymbols('DGS10', src='FRED')
chart_Series(DGS10)

#FRED 사이트 내 원/달러 환율의 티커 확인 
getSymbols('DEXKOUS', src='FRED')
tail(DEXKOUS)
