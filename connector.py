import serial
from socket import *

#受信側アドレスの設定
#受信側IP
SrcIP = "127.0.0.1"
#受信側ポート番号  
SrcPort = 12345
#受信側アドレスをtupleに格納
SrcAddr = (SrcIP, SrcPort)
#バッファサイズ指定
BUFSIZE = 1024
#ソケット作成
udpServSock = socket(AF_INET, SOCK_DGRAM)
#受信側アドレスでソケットを設定
udpServSock.bind(SrcAddr)

#Arduinoへの送信設定
writeSer = serial.Serial('/dev/tty.usbserial-10', 9600, timeout=3)

#While文を使用して常に受信待ちのループを実行
while True:
    #ソケットにデータを受信した場合の処理
    #受信データを変数に設定
    data, addr = udpServSock.recvfrom(BUFSIZE)
    #デコード
    msg = data.decode()
    #終了処理
    if msg == "finish":
        break
    #メッセージ表示
    print("joint angles = [{}]".format(msg))
    #Arduinoへデータ送信
    writeSer.readline()
    writeSer.write(data)
