# 6.2 재무제표 및 가치지표 크롤링

library(httr)
library(rvest)

ifelse(dir.exists('data/KOR_fs'), FALSE, dir.create('data/KOR_fs'))
Sys.setlocale("LC_ALL", "English")
url=paste0('http://comp.fnguide.com/SVO2/ASP/SVD_Finance.asp?pGB=1&gicode=A005930')

# user_agent() 항목에 웹브라우저 구별을 입력해줍니다. 해당 사이트는 크롤러와 같이 정체가 불분명한 웹브라우저를 
# 통한 접속이 막혀 있어, 마치 모질라 혹은 크롬을 통해 접속한 것 처럼 데이터를 요청합니다. 
data = GET(url,
           user_agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64)
                      AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36'))

data=data %>% 
  read_html() %>% 
  html_table()
Sys.setlocale("LC_ALL", "Korean")

# 과정을 거치면 data 변수에는 리스트 형태로 총 6개의 테이블이 들어오게 되며.
lapply(data, function(x){
  head(x, 3)
})

#연간 기준 재무제표에 해당하는 첫 번째, 세 번째, 다섯 번째 테이블을 선택.
data_IS=data[[1]] #포괄손익계산서 (연간)
data_BS=data[[3]] #재무상태표 (연간)
data_CF=data[[5]] #현금흐름표 (연간)
print(names(data_IS))

# 포괄손익계산서 테이블(data_IS)에는 전년동기, 전년동기(%) 열이 있는데 통일성을 위해 해당 열을 삭제합니다. 
data_IS=data_IS[, 1:(ncol(data_IS)-2)]

#테이블을 묶은 후 클렌징
#rbind() 함수를 이용해 세 테이블을 행으로 묶은 후 data_fs에 저장
data_fs=rbind(data_IS, data_BS, data_CF)

#첫 번째 열인 계정명에는 ‘계산에 참여한 계정 펼치기’라는 글자가 들어간 항목이 있습니다. 
#이는 페이지 내에서 펼치기 역할을 하는 (+) 항목에 해당하며 gsub() 함수를 이용해 해당 글자를 삭제합니다.
data_fs[, 1]=gsub('계산에 참여한 계정 펼치기', '' , data_fs[, 1])

#중복되는 계정명이 다수 있는데 대부분 불필요한 항목입니다. !duplicated() 함수를 사용해 중복되지 않는 계정명만 선택합니다.
data_fs=data_fs[!duplicated(data_fs[, 1]),]
write.csv(data_fs, 'data/KOR_fs/005930_fs.csv')


#행 이름을 초기화한 후 첫 번째 열의 계정명을 행 이름으로 변경합니다. 그 후 첫 번째 열은 삭제합니다.
rownames(data_fs)=NULL
rownames(data_fs)=data_fs[,1]
data_fs[,1]=NULL


#간혹 12월 결산법인이 아닌 종목이거나 연간 재무제표임에도 불구하고 분기 재무제표가 들어간 경우가 있습니다. 
#비교의 통일성을 위해 substr() 함수를 이용해 끝 글자가 12인 열, 즉 12월 결산 데이터만 선택합니다.
data_fs=data_fs[, substr(colnames(data_fs), 6,7)=='12']

print(head(data_fs))
sapply(data_fs, typeof)

#sapply() 함수를 이용해 각 열에 stringr 패키지의 str_replace_allr() 함수를 적용해 콤마(,)를 제거한 후 
#as.numeric() 함수를 통해 숫자형 데이터로 변경합니다.
library(stringr)
data_fs=sapply(data_fs, function(x){
  str_replace_all(x, ',', '') %>% 
    as.numeric()
}) %>% 
#data.frame() 함수를 이용해 데이터 프레임 형태로 만들어주며, 행 이름은 기존 내용을 그대로 유지합니다.
  data.frame(., row.names = rownames(data_fs))

write.csv(data_fs, 'data/KOR_fs/005930_fs.csv')


print(head(data_fs))
sapply(data_fs, typeof)
write.csv(data_fs, 'data/KOR_fs/005930_fs.csv')