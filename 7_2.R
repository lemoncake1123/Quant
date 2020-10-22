#7.2 재무제표 정리하기
#재무제표는 각 종목별 재무 항목이 모두 달라 정리하기 번거롭습니다.

library(stringr)
library(magrittr)
library(dplyr)

KOR_ticker=read.csv('data/KOR_ticker.csv', row.names = 1)
KOR_ticker$'종목코드' = str_pad(KOR_ticker$'종목코드', 6, side = c('left'), pad = 0)

data_fs=list()
for (i in 1:nrow(KOR_ticker)) {
  
  name=KOR_ticker[i, '종목코드']
  data_fs[[i]]=read.csv(paste0('data/KOR_fs/', name, '_fs.csv'), row.names = 1)
  
}

#종목별 재무제표 데이터를 읽어온 후 리스트에 저장합니다.
fs_item=data_fs[[1]] %>% rownames()
length(fs_item)
print(head(fs_item))

#다음으로 재무제표 항목의 기준을 정해줄 필요가 있습니다. 재무제표 작성 항목은 각 업종별로 상이하므로, 이를 모두 고려하면 지나치게 데이터가 커지게 됩니다. 또한 퀀트 투자에는 일반적이고 공통적인 항목을 주로 사용하므로 대표적인 재무 항목을 정해 이를 기준으로 데이터를 정리해도 충분합니다.
#이를 모두 고려하면 지나치게 데이터가 커지게 됩니다. 또한 퀀트 투자에는 일반적이고 공통적인 항목을 주로 사용하므로 대표적인 재무 항목을 정해 이를 기준으로 데이터를 정리해도 충분합니다.
# %in% 함수를 통해 만일 매출액이라는 항목이 행 이름에 있으면 해당 부분의 데이터를 select_fs 리스트에 저장하고, 해당 항목이 없는 경우 NA로 이루어진 데이터 프레임을 저장합니다.
#dplyr 패키지의 bind_rows() 함수를 이용해 리스트 내 데이터들을 행으로 묶어줍니다. rbind()에서는 리스트 형태를 테이블로 묶으려면 모든 데이터의 열 개수가 동일해야 하는 반면, bind_rows()에서는 열 개수가 다를 경우 나머지 부분을 NA로 처리해 합쳐주는 장점이 있습니다.
select_fs=lapply(data_fs, 
                 function(x) { 
                              #해당항목이 있을시 데이터선택
                               if ('매출액' %in% rownames(x)) {x[which(rownames(x) == '매출액'), ] } 
                               else {data.frame(NA)} # 해당 항목이 존재하지 않을 시, NA로 된 데이터프레임 생성
                              }
                 )

select_fs=bind_rows(select_fs)

#합쳐진 데이터를 살펴보면, 먼저 열 이름이 . 혹은 NA.인 부분이 있습니다. 이는 매출액 항목이 없는 종목의 경우 NA 데이터 프레임을 저장해 생긴 결과입니다. 또한 연도가 순서대로 저장되지 않은 경우가 있습니다. 이 두 가지를 고려해 데이터를 클렌징합니다.
#!와 %in% 함수를 이용해, 열 이름에 . 혹은 NA.가 들어가지 않은 열만 선택합니다.
select_fs=select_fs[!colnames(select_fs) %in% c('.', 'NA.')]
select_fs=select_fs[, order(names(select_fs))]    #열 이름의 연도별 순서를 구한 후 이를 바탕으로 열을 다시 정리
rownames(select_fs)=KOR_ticker[, '종목코드']    #행 이름을 티커들로 변경



#for loop 구문을 이용해 모든 재무 항목에 대한 데이터를 정리하는 방법은 다음과 같습니다.
fs_list = list()

for (i in 1 : length(fs_item)) {
  select_fs = lapply(data_fs, function(x) {
    # 해당 항목이 있을시 데이터를 선택
    if ( fs_item[i] %in% rownames(x) ) {
      x[which(rownames(x) == fs_item[i]), ]
      
      # 해당 항목이 존재하지 않을 시, NA로 된 데이터프레임 생성
    } else {
      data.frame(NA)
    }
  })
  
  # 리스트 데이터를 행으로 묶어줌 
  select_fs = bind_rows(select_fs)
  
  # 열이름이 '.' 혹은 'NA.'인 지점은 삭제 (NA 데이터)
  select_fs = select_fs[!colnames(select_fs) %in%
                          c('.', 'NA.')]
  
  # 연도 순별로 정리
  select_fs = select_fs[, order(names(select_fs))]
  
  # 행이름을 티커로 변경
  rownames(select_fs) = KOR_ticker[, '종목코드']
  
  # 리스트에 최종 저장
  fs_list[[i]] = select_fs
  
}

# 리스트 이름을 재무 항목으로 변경
names(fs_list) = fs_item

#마지막으로 해당 데이터를 data 폴더 내에 저장합니다. 리스트 형태 그대로 저장하기 위해 saveRDS() 함수를 이용해 KOR_fs.Rds 파일로 저장합니다.
saveRDS(fs_list, 'data/KOR_fs.Rds')

#Rds 형식은 파일을 더블 클릭한 후 연결 프로그램을 R Studio로 설정해 파일을 불러올 수 있습니다. 혹은 readRDS() 함수를 이용해 파일을 읽어올 수도 있습니다.