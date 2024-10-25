close all; clear; clc %初期化

prompt = 'Input words = ?';    %文字列のコマンドウィンドウからの入力
X = input(prompt, "s");        %入力された文字列を代入
Xnum = double(X);              %文字列の倍精度整数型変換
Xbit = int2bit(Xnum, 8);       %8ビット型2進数変換
BitNumber = 8 * length(Xnum);    %送信総ビット数（パルス信号列）
TXbit = reshape(Xbit, [1, BitNumber]);    %送信ビット生成（横ベクトル化）

fs = 10000;        %サンプリング周波数
ts = 1 / fs;       %サンプリング間隔
SampleOfPuls = 200;%1パルス信号当たりのサンプル数
SampleAll = SampleOfPuls * BitNumber;%総サンプル数
Tp = ts * SampleOfPuls;%1パルス信号あたりの時間
Tx = ts * (SampleAll-1);%総時間
t = 0:ts:Tx;%サンプル値信号用時間軸ベクトル

%送信側
fr = 1000;    %搬送波周波数
P0 = +pi / 4;    %位相変調値
P1 = -pi / 4;    %位相変調値
S0 = sin(2*pi*fr*t + P0);    %PSK変調の位相P0[rad](ビット0)
S1 = sin(2*pi*fr*t + P1);    %PSK変調の位相P1[rad](ビット1)
TXbit1Sample = repelem(TXbit, SampleOfPuls);     %送信ビット列信号
TXbit0Sample = repelem(1-TXbit, SampleOfPuls);   %送信ビット列信号(0-1反転)

Mwave = TXbit0Sample.*S0 + TXbit1Sample.*S1;    %PSK変調信号
spls = repelem(TXbit, SampleOfPuls);            %ビット列を表すパルス列信号
SX = Mwave;                                     %送信変調波
RX = SX;                                        %受信変調波

%判定処理%
SCOR0 = RX.*S0;    %受信変調波とビット0変調波の乗算（相関）
SCOR1 = RX.*S1;    %受信変調波とビット1変調波の乗算（相関）
SS0 = reshape(SCOR0,[SampleOfPuls, BitNumber]);    %ビット単位に相関の整列
SS1 = reshape(SCOR1,[SampleOfPuls, BitNumber]);    %ビット単位に相関の整列
SDC0 = zeros(1, BitNumber);    %ビット0との相関値の配列の初期化
SDC1 = zeros(1, BitNumber);    %ビット1との相関値の配列の初期化
RXbit = zeros(1, BitNumber);   %相関の強弱の判定の配列初期化
for m=1:BitNumber
    SDC0(1, m) = sum(SS0(:,m)) / SampleOfPuls;    %ビット0との正規化平均相関値
    SDC1(1, m) = sum(SS1(:,m)) / SampleOfPuls;    %ビット1との正規化平均相関値
    RXbit(1, m) = SDC1(1, m) >= SDC0(1, m);       %相関値の判定
end
dpuls = repelem(RXbit, SampleOfPuls);       %受信判定復元パルス列信号
deX = reshape(RXbit, [8, length(Xnum)]);    %8ビット2進数変換
deMoji =  bit2int(deX, 8);                  %2進数の整数型変換
mojiretsu = char(deMoji);                   %整数型文字列変換

BER = (sum(xor(TXbit, RXbit)) / BitNumber);    %BER算出


%コマンドウィンドウ表示
disp([num2str(BitNumber), 'bit送信'])
disp(['送信bit列', num2str(TXbit)])
disp(['受信bit列', num2str(RXbit)])
disp(['BER=', num2str(100*BER), '% [誤りbit数 / 送信bit数]'])
disp(['Recieved string = ',mojiretsu])

%波形表示
figure(1)
subplot(311)    %(1)ビット列を表すパルス列信号(8bit)の表示
stairs(t, spls);
axis([0,8*Tp,-0.5,1.5]);xlabel('Time[s]');ylabel('SX pulse sequence');title('8bit');
subplot(312)    %(2)FSK変調波信号(8bit)の表示
plot(t, Mwave);
axis([0,8*Tp,-1.5,1.5]);xlabel('Time[s]');ylabel('Modulated signal');title('8bit');
subplot(313)    %(3)受信判定復元パルス列信号(8bit)
stairs(t, dpuls);
axis([0,8*Tp,-0.5,1.5]);xlabel('Time[s]');ylabel('RX pulse sequence');title('8bit');
