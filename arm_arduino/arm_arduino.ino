#include <Wire.h>
#include <PCA9685.h>            //PCA9685用ヘッダーファイル（秋月電子通商作成）

PCA9685 pwm = PCA9685(0x40);    //PCA9685のアドレス指定（アドレスジャンパ未接続時）
PCA9685 pwm2 = PCA9685(0x41);   //PCA9685のアドレス指定（A0接続時）

#define SERVOMIN 150            //最小パルス幅 (標準的なサーボパルスに設定)
#define SERVOMAX 600            //最大パルス幅 (標準的なサーボパルスに設定)

void setup() {
 Serial.begin(9600);
 pwm.begin();                   //初期設定 (アドレス0x40用)
 pwm.setPWMFreq(60);            //PWM周期を60Hzに設定 (アドレス0x40用)
 pwm2.begin();                   //初期設定 (アドレス0x41用)
 pwm2.setPWMFreq(60);            //PWM周期を60Hzに設定 (アドレス0x41用)
}

double theta_ref[6] = {90.0, 90.0, 90.0, 90.0, 90.0, 90.0};
double theta[6]     = {90.0, 90.0, 90.0, 90.0, 90.0, 90.0};

void loop() {
  if(Serial.available()) {
    String str = Serial.readStringUntil('\n');
    Serial.println(str);

    int data[6];
    stringToIntValues(str, data, ',');
    //目標関節角度設定
    for(int i = 0; i < 6; i++) {
      theta_ref[i] = double(data[i]);
    }
  }
  //目標角度に対して比例制御, max_deltaは最大変化量, kはゲイン
  double max_delta = 1.0;
  double k = 0.1;
  for(int i = 0; i < 6; i++) {
    double delta = k * (theta_ref[i] - theta[i]);
    if(delta > max_delta) {
      delta = max_delta;
    }
    else if(delta < -max_delta) {
      delta = -max_delta;
    }
    theta[i] += delta;
    servo_write(i, int(theta[i]));
  }
  delay(10);
}

void servo_write(int ch, int ang){ //動かすサーボチャンネルと角度を指定
  ang = map(ang, 0, 180, SERVOMIN, SERVOMAX); //角度（0～180）をPWMのパルス幅（150～600）に変換
  pwm.setPWM(ch, 0, ang);
  pwm2.setPWM(ch, 0, ang);
  //delay(1);
}

void stringToIntValues(String str, int value[], char delim) {
  int k = 0;
  int j = 0;
  char text[8];

  for (int i = 0; i <= str.length(); i++) {
    char c  = str.charAt(i);
    if(c == delim || i == str.length()) {
      text[k] = '\0';
      value[j] = atoi(text);
      j++;
      k = 0;
    }
    else {
      text[k] = c;
      k++;
    }
  }
}
