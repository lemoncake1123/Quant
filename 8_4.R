#8.4 주가 및 수익률 시각화
Sys.setenv(LANG="en")
library(dplyr)
library(quantmod)

getSymbols('SPY')    #데이터를 xts 형식으로 다운
prices = Cl(SPY)     #종가에 해당하는 데이터만 추출

plot(prices, main = 'Price')

library(ggplot2)

SPY %>% ggplot(aes(x=Index, y=SPY.Close)) +geom_line()

#8.4.2 인터랙티브 그래프 나타내기

library(dygraphs)

dygraph(prices) %>%    #사용자의 움직임에 따라 반응하는 그래프
  dyRangeSelector()

#원하는 기간의 수익률을 선택할 수도 있습니다.

library(highcharter)

#왼쪽 상단의 기간을 클릭하면 해당 기간의 수익률만 확인할 수 있으며, 오른쪽 상단에 기간을 직접 입력할 수도 있습니다.

highchart(type = 'stock') %>% 
  hc_add_series(price) %>% 
  hc_scrollbar(enabled=F)

#단순히 ggplot()을 이용해 나타낸 그림에 ggplotly() 함수를 추가하는 것만으로 인터랙티브한 그래프를 만들어줍니다.

library(plotly)

p=SPY %>% 
  ggplot(aes(x=Index, y=SPY.Close))+
  geom_line()

ggplotly(p)

#해당 패키지는 최근 샤이니에서도 많이 사용되고 있습니다. 따라서 샤이니를 이용한 웹페이지 제작

prices %>% 
  fortify.zoo() %>%    #plot_ly() 함수는 파이프 오퍼레이터(%>%)를 통해 연결
  plot_ly(x=~Index, y=~SPY.Close) %>%    #변수명 앞에 물결표(~)
  add_lines()    


#8.4.3 연도별 수익률 나타내기

library(PerformanceAnalytics)

ret_yearly = prices %>% 
  Return.calculate() %>% 
  apply.yearly(., Return.cumulative) %>%    #연도별 수익률을 계산한 뒤 
  round(4) %>%     #반올림
  fortify.zoo() %>%    #인덱스에 있는 시간 데이터를 Index 열로 이동
  mutate(Index=as.numeric(substring(Index, 1, 4)))    #Index의 1번째부터 4번째 글자, 즉 연도에 해당하는 부분을 뽑아낸 후 숫자 형태로 저장


ggplot(ret_yearly, aes(x=Index, y=SPY.Close))+    #x축에는 연도가 저장된 Index, y축에는 수익률이 저장된 SPY.Close를 입력
  geom_bar(stat='identity')+
  scale_x_continuous(breaks = ret_yearly$Index,    #x축에 모든 연도가 출력
                     expand = c(0.01, 0.01))+
  geom_text(aes(label=paste(round(SPY.Close*100, 2), "%"),    #막대 그래프에 연도별 수익률이 표시
                vjust=ifelse(SPY.Close>=0, -0.5, 1.5)),    #수익률이 0보다 크면 위쪽에 표시하고, 0보다 작으면 아래쪽에 표시
            position = position_dodge(width = 1),
            size=3)+
  xlab(NULL)+ylab(NULL)