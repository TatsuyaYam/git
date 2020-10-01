import requests
import time

def PythonNotify(message):
    # 諸々の設定
    line_notify_api = 'https://notify-api.line.me/api/notify'
    line_notify_token = 'rK8Q93cc1g4bOsvvYCvrs4ZU1COEcC4Y9Z5BqAZ02Gb'

    headers = {'Authorization': 'Bearer ' + line_notify_token}
    # メッセージ
    payload = {'message': ("\n"+message)}
    requests.post(line_notify_api, data=payload, headers=headers)

number_pre=-1
while True:
    #ファイルパス（本番用）
    file = open("C:\Program Files (x86)\XMTrading MT4\MQL4\Files\MQL4\Files\Line.txt", 'r')
    #ファイルパス（デモ用）
    #file = open("C:/Program Files (x86)/XMTrading MT4/tester/files/MQL4/Files/Line.txt", 'r')
    data = file.read()  # ファイル終端まで全て読む
    file.close()
    lines = data.split('\n') # 改行で区切る
    number = int(lines[0].strip("Number:")) #乱数部分

    #乱数部分が異なるとき
    if(number!=number_pre):
        PythonNotify(lines[1]+"\n"+lines[2]+"\n"+lines[3])
        print('Update')
    time.sleep(10)
    number_pre=number