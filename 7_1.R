#Chapter 7 데이터 정리하기, 각각 csv 파일로 저장된 데이터들을 하나로 합친 후 저장
#7.1 주가 정리하기

library(stringr)
library(xts)
library(magrittr)

#티커가 저장된 csv 파일을 불러.
KOR_ticker=read.csv('data/KOR_ticker.csv', row.names = 1)

#티커를 6자리로 맞춰줍니다.
KOR_ticker$'종목코드'=
  str_pad(KOR_ticker$'종목코드', 6, side = c('left'), pad = '0')

price_list=list()  #빈 리스트인 price_list를 생성


for (i in 1 : nrow(KOR_ticker)) {
  
  name = KOR_ticker[i, '종목코드']
  price_list[[i]] =
    read.csv(paste0('data/KOR_price/', name,
                    '_price.csv'),row.names = 1) %>%
    as.xts()    #as.xts()를 통해 시계열 형태로 데이터를 변경
}

price_list = do.call(cbind, price_list) %>% na.locf() #do.call() 리스트를 열 형태로 묶습니다
colnames(price_list) = KOR_ticker$'종목코드'    #행 이름을 각 종목의 티커로 변경.

#개별 csv 파일로 흩어져 있던 가격 데이터가 하나의 데이터로 묶이게 됩니다.
write.csv(data.frame(price_list), 'data/KOR_price.csv')