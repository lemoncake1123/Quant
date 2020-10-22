library(httr)
library(rvest)
library(readr)

gen_otp_url = 'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx' #제출할 주소
gen_otp_data = list(
  name = 'fileDown',
  filetype = 'csv',                              #csv가 xls보다 데이터 처리에 용의함
  url = 'MKD/03/0303/03030103/mkd03030103',
  tp_cd = 'ALL',
  date = '20201016',
  lang = 'ko',
  pagePath = '/contents/MKD/03/0303/03030103/MKD03030103.jsp')


#Send Query - get data
otp = POST(gen_otp_url, query = gen_otp_data) %>%    
  read_html() %>% 
  html_text()


#sending url
down_url = "http://file.krx.co.kr/download.jspx"      
down_sector = POST(down_url, query = list(code = otp), 
                   add_headers(referer = gen_otp_url)) %>%   #referer is visiting trace
  read_html() %>%    #흔적이 없이 OTP를 바로 두번째 URL에 제출하면 서버는 이를 로봇으로 인식해 데이터를 반환하지 않습니다.  
  html_text() %>%  #extract only the text data
  read_csv()
down_sector



#data라는 이름의 폴더가 있으면 FALSE를 반환하고, 없으면 해당 이름으로 폴더를 생성
ifelse(dir.exists('data'), FALSE, dir.create('data'))
write.csv(down_sector, 'data/krx_sector.csv')


























