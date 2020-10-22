# for loop 구문을 이용해 고유번호에 해당하는 corp_code 부분만 변경해주면 전 종목의 API를 통해 재무제표 데이터를 
# 손쉽게 수집할 수도 있습니다. 단, 일부 종목(대부분 금융주)의 경우 API로 파일이 제공되지 않습니다.
library(stringr)
library(dplyr)

KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1)
corp_list =  read.csv('data/corp_list.csv', row.names = 1)

KOR_ticker$'종목코드' =
  str_pad(KOR_ticker$'종목코드', 6, side = c('left'), pad = '0')

corp_list$'code' =
  str_pad(corp_list$'code', 8, side = c('left'), pad = '0')

corp_list$'stock' =
  str_pad(corp_list$'stock', 6, side = c('left'), pad = '0')

ticker_list = KOR_ticker %>% left_join(corp_list, by = c('종목코드' = 'stock')) %>%
  select('종목코드', '종목명', 'code')

ifelse(dir.exists('data/dart_fs'), FALSE, dir.create('data/dart_fs'))


# 먼저 거래소에서 받은 티커 파일과 API를 통해 받은 고유번호 파일을 불러온 후, str_pad() 함수를 통해 0을 채워주며, 
# 고유번호의 경우 8자리로 구성되어 있습니다. 그 후 dart_fs 폴더를 생성해 줍니다.
bsns_year = 2019
reprt_code = '11011'

#for loop 구문을 이용해 고유번호에 해당하는 값을 변경합니다.
for(i in 1 : nrow(ticker_list) ) {
  
  data_fs = c()
  name = ticker_list$code[i]
  
  # 오류 발생 시 이를 무시하고 다음 루프로 진행
  
  tryCatch({
    
    # url 생성
    url = paste0('https://opendart.fss.or.kr/api/fnlttSinglAcntAll.json?crtfc_key=',
                 dart_api, 
                 '&corp_code=', name,
                 '&bsns_year=', bsns_year,
                 '&reprt_code=', reprt_code,'&fs_div=CFS'
    )
    
    # JSON 다운로드
    fs_data_all = fromJSON(url) 
    fs_data_all = fs_data_all[['list']]
    
    # 일부 종목의 경우 연결재무제표가 아닌 재무제표를 업로드 하는 경우가 있으며,만일 연결재무제표 없어서 NULL 반환시
    # (is.null(fs_data_all)) 부분을 통해 연결재무제표가 없을 경우 fs_div를 OFS로 변경하여 재무제표를 다운로드 받습니다.
    if (is.null(fs_data_all)) {
      
      url = paste0('https://opendart.fss.or.kr/api/fnlttSinglAcntAll.json?crtfc_key=',
                   dart_api, 
                   '&corp_code=', name,
                   '&bsns_year=', bsns_year,
                   '&reprt_code=', reprt_code,'&fs_div=OFS'
      )
      
      fs_data_all = fromJSON(url) 
      fs_data_all = fs_data_all[['list']]
      
    }
    
    
    # 데이터 선택 후 열이름을 연도로 변경
    yr_count = str_detect(colnames(fs_data_all), 'trm_amount') %>% sum()
    yr_name = seq(bsns_year, (bsns_year - yr_count + 1))
    
    fs_data_all = fs_data_all[, c('corp_code', 'sj_nm', 'account_nm', 'account_detail')] %>%
      cbind(fs_data_all[, str_which(colnames(fs_data_all), 'trm_amount')])
    
    colnames(fs_data_all)[str_which(colnames(fs_data_all), 'amount')] = yr_name
    
  }, error = function(e) {
    
    # 오류 발생시 해당 종목명을 출력하고 다음 루프로 이동
    data_fs <<- NA
    warning(paste0("Error in Ticker: ", name))
  })
  
  # 다운로드 받은 파일을 생성한 각각의 폴더 내 csv 파일로 저장
  
  # 재무제표 저장
  write.csv(fs_data_all, paste0('data/dart_fs/', ticker_list$종목코드[i], '_fs_dart.csv'))
  
  # 2초간 타임슬립 적용
  Sys.sleep(2)
}