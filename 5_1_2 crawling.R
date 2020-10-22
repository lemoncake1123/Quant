library(httr)
library(rvest)
library(readr)

gen_otp_url = 'http://marketdata.krx.co.kr/contents/COM/GenerateOTP.jspx'
gen_otp_data = list(
  name = 'fileDown',
  filetype = 'csv',
  url = 'MKD/13/1302/13020401/mkd13020401',
  market_gubun = 'ALL',
  gubun = '1',
  schdate = '20201019',
  pagePath = '/contents/MKD/13/1302/13020401/MKD13020401.jsp')

otp = POST(gen_otp_url, query = gen_otp_data) %>% 
  read_html() %>% 
  html_text()


down_url = 'http://file.krx.co.kr/download.jspx'
down_ind = POST(down_url, query = list(code =otp),
                   add_headers(referer = gen_otp_url)) %>% 
  read_html() %>% 
  html_text() %>% 
  read_csv()
down_ind

write.csv(down_ind, 'data/krx_ind2.csv')