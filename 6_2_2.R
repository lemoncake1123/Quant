# 6.2.2 가치지표 계산하기

# PER	Earnings (순이익)
# PBR	Book Value (순자산)
# PCR	Cashflow (영업활동현금흐름)
# PSR	Sales (매출액)

ifelse(dir.exists('data/KOR_value'), FALSE, dir.create('data/KOR_value'))
value_type = c('지배주주순이익',
               '자본',
               '영업활동으로인한현금흐름',
               '매출액')
#match() 함수를 이용해 해당 항목이 위치하는 지점을 찾습니다. ncol() 함수를 이용해 맨 오른쪽, 즉 최근년도 재무제표 데이터를 선택합니다.
value_index=data_fs[match(value_type, rownames(data_fs)), ncol(data_fs)]


#주가의 Xpath를 이용해 해당 데이터를 크롤링하겠습니다.
library(readr)
url='http://comp.fnguide.com/SVO2/ASP/SVD_main.asp?pGB=1&gicode=A005930'
data = GET(url,
           user_agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64)
                      AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36'))

#readr 패키지의 parse_number() 함수를 적용합니다. 해당 함수는 문자형 데이터에서 콤마와 같은 불필요한 문자를 제거한 후 숫자형 데이터로 변경
price=read_html(data) %>% 
  html_node(xpath = '//*[@id="svdMainChartTxt11"]') %>% 
  html_text() %>% 
  parse_number()

#PER = Price/EPS = 주가/주당순이익

#발행주식수 중 보통주를 선택
share=read_html(data) %>% 
  html_node(
    xpath = '//*[@id="svdMainGrid1"]/table/tbody/tr[7]/td[1]') %>% 
  html_text()
#[1] "5,969,782,550/ 822,886,700"


share=share %>% 
  strsplit('/') %>% #strsplit() 함수를 통해 /를 기준으로 데이터를 나눕니다. 해당 결과는 리스트 형태로 저장됩니다.
  unlist() %>%      #unlist() 함수를 통해 리스트를 벡터 형태로 변환합니다.
  .[1] %>%          #보통주 발행주식수인 첫 번째 데이터를 선택
  parse_number()    #parse_number() 함수를 통해 문자형 데이터를 숫자형으로 변환
#[1] 5969782550

#재무 데이터, 현재 주가, 발행주식수를 이용해 가치지표를 계산해보겠습니다.
#분자에는 현재 주가를 입력하며, 분모에는 재무 데이터를 보통주 발행주식수로 나눈 값을 입력합니다.
#주가는 원 단위, 재무 데이터는 억 원 단위이므로, 둘 사이에 단위를 동일하게 맞춰주기 위해 분모에 억을 곱합니다. 
data_value=price / (value_index*100000000 /share)
names(data_value)=c('PER', 'PBR', 'PCR', 'PSR')
data_value[data_value<0]=NA      #가치지표가 음수인 경우는 NA로 변경

write.csv(data_value, 'data/KOR_value/005930_value.csv')

















