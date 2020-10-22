# 6.3 DART의 Open API를 이용한 데이터 수집하기

# 발급받은 API Key를 .Renviron 파일에 추가
file.edit("~/.Renviron")

# API Key를 불러오도록 합니다.
dart_api = Sys.getenv("dart_api_key")



#6.3.2 고유번호 다운로드
library(httr)
library(rvest)

#Open API에서 각 기업의 데이터를 받기 위해서는 종목에 해당하는 고유번호를 알아야 합니다.
codezip_url = paste0(
  'https://opendart.fss.or.kr/api/corpCode.xml?crtfc_key=',dart_api) #본인의 API 키를 입력

codezip_data = GET(codezip_url)
print(codezip_data)
#[1] ": attachment; filename=CORPCODE.zip"

#headers의 “content-disposition” 부분을 확인해보면 CORPCODE.zip 파일이 첨부
codezip_data$headers[["content-disposition"]]

#해당 파일의 압축을 풀어 첨부된 내용을 확인
#tempfile() 함수 통해 빈 .zip 파일을 만듭니다.
tf=tempfile(fileext = '.zip')

#writeBin() 함수는 바이너리 형태의 파일을 저장하는 함수이며, content()를 통해 첨부 파일 내용을 raw 형태로 저장
writeBin(
  content(codezip_data, as='raw'),
  file.path(tf)
)

#unzip() 함수를 통해 zip 내 파일 리스트를 확인
nm=unzip(tf, list = T)

#zip 파일 내에는 CORPCODE.xml 파일이 있으며, read_xml() 함수를 통해 이를 불러오도록 합니다.
code_data=read_xml(unzip(tf, nm$Name))
# corp_code: 고유번호
# corp_name: 종목명
# corp_stock: 거래소 상장 티커

#HTML의 태그를 이용해 각 부분을 추출한 후 하나의 데이터로 합치도록 하겠습니다.
#html_nodes() 함수를 이용해 고유번호, 종목명, 상장티커를 선택한 후, html_text() 함수를 이용해 문자열만 추출
corp_code=code_data %>% html_nodes('corp_code') %>% html_text()
corp_name=code_data %>% html_nodes('corp_name') %>% html_text()
corp_stock=code_data %>% html_nodes('stock_code') %>% html_text()

#data.frame() 함수를 통해 데이터프레임 형식으로 묶어주도록 합니다.
corp_list=data.frame(
  'code'=corp_code,
  'name'=corp_name,
  'stock'=corp_stock,
  stringsAsFactors = F
)

#stock 열이 빈 종목은 거래소에 상장되지 않은 종목입니다. 따라서 해당 데이터는 삭제하여 거래소 상장 종목만을 남긴 후, csv 파일로 저장하도록 합니다.
corp_list=corp_list[corp_list$stock !=" ",]
write.csv(corp_list, 'data/corp_list.csv')



#6.3.3.1 전체 공시 검색
library(lubridate)
library(stringr)
library(jsonlite)

bgn_date=(Sys.Date()-days(7)) %>% str_remove_all('-') #bgn_date에는 현재로부터 일주일 전
end_date=(Sys.Date()) %>% str_remove_all('-')         #end_date는 오늘 날짜
notice_url=paste0('https://opendart.fss.or.kr/api/list.json?crtfc_key=', dart_api,'&bgn_de=',
                  bgn_date, '&end_de=', end_date, '&corp_cls=Y&page_no=1&page_count=100') #페이지별 건수에 해당하는 page_count에는 100

# XML 보다는 JSON 형식으로 url을 생성 후 요청하는 것이 데이터 처리 측면에서 훨씬 효율적
notice_data=fromJSON(notice_url)
notice_data=notice_data[['list']]



#6.3.3.2 특정 기업의 공시 검색
#고유번호를 추가하여 원하는 기업의 공시만 확인
#고유번호는 위에서 다운받은 corp_list.csv 파일을 통해 확인
bgn_date=(Sys.Date()-days(30)) %>% str_remove_all('-') #bgn_date에는 현재로부터 30일 전
end_date=(Sys.Date()) %>% str_remove_all('-')         #end_date는 오늘 날짜
corp_code='00126380'    #삼성전자의 고유번호

notice_url_ss = paste0(
  'https://opendart.fss.or.kr/api/list.json?crtfc_key=',dart_api,
  '&corp_code=', corp_code,                       #기존 url에 &corp_code= 부분을 추가
  '&bgn_de=', bgn_date,'&end_de=',
  end_date,'&page_no=1&page_count=100')

notice_data_ss=fromJSON(notice_url_ss)
notice_data_ss=notice_data_ss[['list']]    
#이 중 rcept_no는 공시번호에 해당하며, 해당 데이터를 이용해 공시에 해당하는 url에 접속을 할 수도 있습니다.

notice_url_exam=notice_data_ss[1, 'rcept_no']
notice_dart_url = paste0(
  'http://dart.fss.or.kr/dsaf001/main.do?rcpNo=',notice_url_exam)



#6.3.4 사업보고서 주요 정보
# 삼성전자의 2019년 사업보고서를 통해 배당에 관한 사항
# crtfc_key	API 인증키	발급받은 인증키
# corp_code	고유번호	공시대상회사의 고유번호(8자리)
# bsns_year	사업년도	사업연도(4자리)
# reprt_code	보고서 코드, 1분기보고서 : 11013, 반기보고서 : 11012, 3분기보고서 : 11014, 사업보고서 : 11011
corp_code = '00126380'
bsns_year = '2020'
reprt_code = '11013'
url_div = paste0('https://opendart.fss.or.kr/api/alotMatter.json?crtfc_key=',
                 dart_api, 
                 '&corp_code=', corp_code,
                 '&bsns_year=', bsns_year,
                 '&reprt_code=', reprt_code )

#API 인증키, 고유번호, 사업년도, 보고서 코드에 각각 해당하는 데이터를 입력하여 url 생성하도록 합니다.
div_data_ss=fromJSON(url_div)
div_data_ss=div_data_ss[['list']]
# JSON 파일을 다운로드 받은 후 데이터를 확인해보면, 사업보고서 중 배당에 관한 사항만이 나타나 있습니다. 
# 위 url의 alotMatter 부분을 각 사업보고서에 해당하는 값으로 변경해주면 다른 정보 역시 동일한 방법으로 수집이 가능합니다.



# 6.3.5 상장기업 재무정보
# 단일회사 주요계정: https://opendart.fss.or.kr/guide/detail.do?apiGrpCd=DS003&apiId=2019016
# 다중회사 주요계정: https://opendart.fss.or.kr/guide/detail.do?apiGrpCd=DS003&apiId=2019017
corp_code = '00126380'
bsns_year = '2019'
reprt_code = '11011'

url_single = paste0(
  'https://opendart.fss.or.kr/api/fnlttSinglAcnt.json?crtfc_key=',
  dart_api, 
  '&corp_code=', corp_code,
  '&bsns_year=', bsns_year,
  '&reprt_code=', reprt_code
)

#url을 생성하는 방법이 기존 사업보고서 주요 정보 에서 살펴본 바와 매우 비슷하며, /api 뒷부분을 [fnlttSinglAcnt.json] 으로 변경하기만 하면 됩니다.
fs_data_single=fromJSON(url_single)
fs_data_single=fs_data_single[['list']]
#연결재무제표와 재무상태표에 해당하는 주요 내용이 수집되었으며, 각 열에 해당하는 내용은 페이지의 개발가이드의 [응답 결과]에서 확인할 수 있습니다.

#이번에는 url을 수정하여 여러 회사의 주요계정을 한번에 받도록 하겠으며, 그 예로써 삼성전자, 셀트리온, KT의 데이터를 다운로드 받도록 합니다.
#원하는 기업들의 고유번호를 나열.
corp_code = c('00126380,00413046,00190321')
bsns_year = '2019'
reprt_code = '11011'

##url 중 [fnlttSinglAcnt]을 [fnlttMultiAcnt]로 수정합니다.
url_multiple = paste0(
  'https://opendart.fss.or.kr/api/fnlttMultiAcnt.json?crtfc_key=',
  dart_api, 
  '&corp_code=', corp_code,
  '&bsns_year=', bsns_year,
  '&reprt_code=', reprt_code )

#3개 기업의 주요계정이 하나의 데이터 프레임으로 다운로드 됩니다. 
fs_data_multiple=fromJSON(url_multiple)
fs_data_multiple=fs_data_multiple[['list']]

#각 회사별로 데이터를 나눠주도록 하겠습니다.
#split() 함수 내 f 인자를 통해 corp_code, 즉 고유번호 단위로 각각의 리스트에 데이터가 저장됩니다.
fs_data_list=fs_data_multiple %>% split(f= .$corp_code)
lapply(fs_data_list, head, 2)



# 6.3.6 단일회사 전체 재무제표
corp_code = '00126380'
bsns_year = 2019
reprt_code = '11011'

#연결재무제표와 일반재무제표를 구분하는 fs_div 인자는 연결재무제표를 의미하는 CFS로 선택
#url의 api/ 뒷 부분을 [fnlttSinglAcntAll.json] 으로 변경
url_fs_all = paste0(
  'https://opendart.fss.or.kr/api/fnlttSinglAcntAll.json?crtfc_key=',
  dart_api, 
  '&corp_code=', corp_code,
  '&bsns_year=', bsns_year,
  '&reprt_code=', reprt_code,'&fs_div=CFS' )    

fs_data_all=fromJSON(url_fs_all)
fs_data_all=fs_data_all[['list']]

# 총 210개의 재무제표 항목이 다운로드 됩니다. 이 중 thstrm_nm와 thstrm_amount는 당기(금년), frmtrm_nm과 frmtrm_amount는 전기, 
# bfefrmtrm_nm과 bfefrmtrm_amount는 전전기를 의미합니다. 따라서 해당 열을 통해 최근 3년 재무제표 만을 선택할 수도 있습니다.

#str_detect() 함수를 이용해 열 이름에 trm_amount 들어간 갯수를 확인.
#이는 최근 3개년 데이터가 없는 경우도 고려하기 위함입니다. (일반적으로 3이 반환될 것이며, 재무데이터가 2년치 밖에 없는 경우 2가 반환될 것입니다.)
yr_count=str_detect(colnames(fs_data_all), 'trm_amount') %>% sum()

# 위에서 계산된 갯수를 이용해 열이름에 들어갈 년도를 생성합니다
yr_name=seq(bsns_year, (bsns_year - yr_count + 1))

#corp_code(고유번호), sj_nm(재무제표명), account_nm(계정명), account_detail(계정상세) 및 연도별 금액에 해당하는 trm_amount가 포함된 열을 선택합니다.
fs_data_all=fs_data_all[, c('corp_code', 'sj_nm', 'account_detail')] %>%
  cbind(fs_data_all[, str_which(colnames(fs_data_all), 'trm_amount')])

#연도별 데이터에 해당하는 열의 이름을 yr_name, 즉 각 연도로 변경합니다.
colnames(fs_data_all)[str_which(colnames(fs_data_all), 'amount')]=yr_name

