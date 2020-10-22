# 7.3 가치지표 정리하기
library(stringr)
library(magrittr)
library(dplyr)

KOR_ticker = read.csv('data/KOR_ticker.csv', row.names = 1)
KOR_ticker$'종목코드' =
  str_pad(KOR_ticker$'종목코드', 6, side = c('left'), pad = '0')

data_value = list()

for (i in 1 : nrow(KOR_ticker)){
  
  name = KOR_ticker[i, '종목코드']
  data_value[[i]] =
    read.csv(paste0('data/KOR_value/', name,
                    '_value.csv'), row.names = 1) %>%
    t() %>% data.frame()
  
}

# PER	Number 1
# PBR	Number 2
# PCR	Number 3
# PSR	Number 4

#bind_rows() 함수를 이용하여 리스트 내 데이터들을 행으로 묶어준 후 데이터를 확인
data_value = bind_rows(data_value)

#PER, PBR, PCR, PSR 열 외에 불필요한 NA로 이루어진 열이 존재합니다. 해당 열을 삭제한 후 정리 작업을 하겠습니다.
data_value = data_value[colnames(data_value) %in%
                          c('PER', 'PBR', 'PCR', 'PSR')] #열 이름이 가치지표에 해당하는 부분만 선택

#일부 종목은 재무 데이터가 0으로 표기되어 가치지표가 Inf로 계산되는 경우가 있습니다. mutate_all() 내에 na_if() 함수를 이용해 Inf 데이터를 NA로 변경 
data_value = data_value %>%
  mutate_all(list(~na_if(., Inf)))

#행 이름을 티커들로 변경합니다
rownames(data_value) = KOR_ticker[, '종목코드']

write.csv(data_value, 'data/KOR_value.csv')