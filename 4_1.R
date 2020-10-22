Sys.setenv(LANG="en")

library(rvest)
library(httr)

#해당 페이지 전체 다운
url <- 'https://finance.naver.com/news/news_list.nhn?mode=LSS2D&section_id=101&section_id2=258'
data <- GET(url)
print(data)

#제목만 추출, 아래에서부터 위로, 역피라미드
data_title <- data %>%
  read_html(encoding = 'EUC-KR') %>%
  html_nodes('dl') %>%
  html_nodes('.articleSubject') %>%
  html_nodes('a') %>%
  html_attr('title')

#출력
print(data_title)


#예제 2, 기업 공시 오늘의 공시
#한글(korean)로 작성된 페이지를 크롤링하면 오류가 발생하는 
#경우가 종종 있으므로 Sys.setlocale() 함수를 통해 로케일 
#언어를 영어(English)로 설정합니다.
Sys.setlocale("LC_ALL", "English")

url <- "https://kind.krx.co.kr/disclosure/todaydisclosure.do"

#POST() 함수를 통해 해당 url에 원하는 쿼리를 요청하며, 
#쿼리는 body 내에 리스트 형태로 입력해줍니다. 
#해당 값은 개발자 도구 화면의 Form Data와 동일하게 입력해주며
#marketType과 같이 값이 없는 항목은 입력하지 않아도 됩니다.
data <- POST(url, body = 
               list(
                 method = 'searchTodayDisclosureSub',
                 currentPageSize = '15',
                 pageIndex = '1',
                 orderMode = '0',
                 orderStat = 'D',
                 forward = 'todaydisclosure_sub',
                 chose = 'S',
                 todayFlag ='N',
                 selDate = '2020-10-15'
               ))

data <- read_html(data) %>%
  html_table(fill = TRUE) %>%   #T는 셀 병합이 된 열이 있어서.
  .[[1]]   #첫번째 리스트 선택

Sys.setlocale("LC_ALL", "Korean") #한글읽기위해 다시 언어 한글로

print(data)



#예제 3 네이버 주식 티커
i = 0 #코스피
ticker = list()
url = paste0('https://finance.naver.com/sise/',
              'sise_market_sum.nhn?sosok=',i,'&page=1')
down_table <- GET(url)


#마지막 페이지가 몇번째 페이지인지 찾아내는 작업
navi.final = read_html(down_table, encoding = 'EUC-KR') %>% #해당 페이지 읽어옴
  html_nodes(., '.pgRR') %>% #pgRR클래스만 불러옴, 마침표는 클래스 속성이기에 붙이는것
  html_nodes(., 'a') %>% #a태그 정보만 불러옴
  html_attr(., 'href') #href태그 정보만 불러옴
print(navi.final) #href 주소 출력


#맨끝 페이지 숫자 추출
navi.final = navi.final %>% 
  strsplit(., '=') %>% #전체 문장을 특정 글자 기준으로 나눔
  unlist() %>% #결과를 벡터 형태로 변환
  tail(., 1) %>% #뒤에서 첫번째 데이터만 선택
  as.numeric() #해당값을 숫자 형태로 변경경
print(navi.final) #몇페이지까지 있는지 확인




#코스피의 첫 번째 페이지에서 우리가 원하는 데이터를 추출
i = 0 #코스피
j = 1 #첫번째 페이지
url = paste0('https://finance.naver.com/sise/',
              'sise_market_sum.nhn?sosok=',i,'&page=', j)
down_table = GET(url)

Sys.setlocale("LC_ALL", "English")
table = read_html(down_table, encoding = "EUC-KR") %>% 
  html_table(fill = TRUE)
table = table[[2]] #여기서는 3개의 테이블 중 두번째 테이블만 필요함
Sys.setlocale("LC_ALL", "Korean")

print(head(table))


#마지막 열인 토론실 삭제
table[, ncol(table)] = NULL
table = na.omit(table)
print(head(table))

#필요한 6자리 티커. 티커추출
symbol = read_html(down_table, encoding = "EUC-KR") %>% 
  html_nodes(., 'tbody') %>% 
  html_nodes(., 'td') %>% 
  html_nodes(., 'a') %>% 
  html_attr(., 'href')
print(head(symbol, 10))

library(stringr)
symbol <- sapply(symbol, function(x) {
  str_sub(x, -6. -1) #마지막 6글자만 추출
})
print(head(symbol, 10))

symbol <- unique(symbol) #중복제거 함수
print(head(symbol, 10))

table$N = symbol #구한 티커를 N열에 입력
colnames(table)[1] = '종목코드' #해당 열의 이름을 종목코드로 변경
rownames(table) = NULL #앞에서 na.omit함수로 특정행을 삭제했으므로 행 이름을 초기화
ticker[[j]] =table #j번째 리스트에 정리된 데이터를 입력합니다.



################################################################################
################################################################################
################################################################################
# i와 j 값을 for loop 구문에 이용하면 코스피와 코스닥 
#전 종목의 티커가 정리된 테이블을 만들 수 있습니다
data = list()

for (i in 0:1) {
  
  ticker = list()
  url =
    paste0('https://finance.naver.com/sise/',
                'sise_market_sum.nhn?sosok=',i,'&page=1')
  
  down_table = GET(url)
  
  navi.final = read_html(down_table, encoding = "EUC-KR") %>% 
    html_nodes(., ".pgRR") %>% 
    html_nodes(., "a") %>% 
    html_attr(., "href") %>% 
    strsplit(., "=") %>% 
    unlist() %>% 
    tail(., 1) %>% 
    as.numeric()
  
  
  for (j in 1:navi.final) {
    url =
      paste0('https://finance.naver.com/sise/',
             'sise_market_sum.nhn?sosok=',i,'&page=',j)
    down_table = GET(url)
    
    Sys.setlocale("LC_ALL", "English")
    
    table = read_html(down_table, encoding = "EUC-KR") %>% 
      html_table(fill = TRUE)
    table = table[[2]]
    
    Sys.setlocale("LC_ALL","Korean")
    
    table[, ncol(table)] = NULL
    table = na.omit(table)
    
    symbol = read_html(down_table, encoding = "EUC-KR") %>% 
      html_nodes(., "tbody") %>% 
      html_nodes(., "td") %>% 
      html_nodes(., "a") %>% 
      html_attr(., "href")
    
    symbol = sapply(symbol, function(x) {
      str_sub(x, -6, -1)
    })
    
      symbol = unique(symbol)
      
      table$N =symbol
      colnames(table)[1] = "종목코드"
      
      rownames(table) = NULL
      ticker[[j]] = table
      
      Sys.sleep(0.5)
  }
  
  ticker = do.call(rbind, ticker)
  data[[i+1]] = ticker
  
}

data = do.call(rbind, data)


write.csv(data, file = "4강 예제.csv")