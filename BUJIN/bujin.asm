	KEY BIT P3.4					;KEY=P3.4
	DAT BIT P3.5					;DAT=P3.5
	CLK BIT P3.6					;CLK=P3.6
	CS  BIT P3.7					;CS=P3.7
	VAR SEGMENT DATA				;RAM定义变量段
	PROG SEGMENT CODE				;ROM定义程序段
	STACK SEGMENT IDATA				;RAM定义堆栈段                
		RSEG VAR
	BLANK0:DS 1						;
	ZHUANGTAI:DS 2					;状态显示
	BLANK1:DS 1						;显示缓冲区
	DIRECTION:DS 1					;方向
	BLANK2:DS 1						;
	SPEED:DS 2						;速度  转/分钟
	PAIXU:DS 1						;拍序
	DANGWEI:DS 1					;档位
	SUDU:DS 2						;速度调节单元
		
		RSEG STACK					;堆栈
		DS 20
			
		CSEG AT 0					;主程序
		USING 0
		LJMP MAIN
	
		ORG 0003H					;外部中断
		USING 0
		LJMP OUTT0
	
		ORG 000BH					;定时中断
		USING 1
		LJMP INT_T0
		
		ORG 0100H
		RSEG PROG
MAIN:
	MOV SP,#STACK-1
	MOV SUDU,#3CH					;初始速度
	MOV SUDU+1,#0B0H
	MOV TMOD,#01H					;T0定时产生脉冲
	MOV TH0,SUDU					;50MS
	MOV TL0,SUDU+1
	MOV IE,#82H						;开中断
	MOV PAIXU,#0					;拍序为0
	MOV P1,#0						;P1口输出					
	ACALL INITIAL					;初始化
	SETB IT1						;外部中断边沿触发方式
	SETB EX0
M0:
	LCALL DELAY20
	LCALL DISP7279
	LCALL KEYBOARD
	CJNE A,#0FFH,M1
	LCALL DELAY20
	SJMP M0
M1:
	LCALL KEYDEAL					;键处理
	SJMP M0
;-----------------------------------------------------
KEYDEAL:
	CJNE A,#0AH,D1					;是'A'
	CPL TR0							;TR0开启或关闭
	JB TR0,D4						;把状态送入显示缓冲区
	MOV ZHUANGTAI+1,#0FH
	SJMP D0
D4:
	MOV ZHUANGTAI+1,#11H
	LCALL SPEEDTEXT					;把速度初值放入显缓区
	SJMP D0
D1:
	CJNE A,#0BH,D2					;是'B'
	MOV A,DIRECTION
	CPL ACC.0						;方向取反，并送显缓区
	MOV DIRECTION,A
	SJMP D0
D2:
	CJNE A,#0CH,D3					;是'C'
	MOV A,DANGWEI					
	CJNE A,#4,DD2
DD2:
	JNC D0
	INC DANGWEI						;档位加1
	LCALL DIAOSU					;调速
	LCALL SPEEDTEXT					;速值转换
	SJMP D0
D3:
	CJNE A,#0DH,D0					;是'D'
	MOV A,DANGWEI
	CJNE A,#1,DD3
DD3:
	JC D0
	DEC DANGWEI						;档位减1
	LCALL DIAOSU					;调速
	LCALL SPEEDTEXT					;速值转换
D0:
	RET
;-----------------------------------------------------
SPEEDTEXT:
	MOV A,DANGWEI					;速度显示查表
	RL A							;查双字节
	MOV DPTR,#SPEEDTEXTTAB
	MOVC A,@A+DPTR					;查高字节
	MOV SPEED,A
	MOV A,DANGWEI					;放显缓区
	RL A
	ADD A,#1						;查低字节
	MOVC A,@A+DPTR	
	MOV SPEED+1,A					;放显缓区
	RET
SPEEDTEXTTAB:
	DB 12H,05H						;转速,0.5
	DB 00H,05H						;05
	DB 01H,00H						;10
	DB 02H,00H						;20
	DB 06H,00H						;60
;-----------------------------------------------------
DIAOSU:
	MOV A,DANGWEI					;速度调节查表
	RL A
	MOV DPTR,#SPEEDTAB				;查档位
	MOVC A,@A+DPTR					;根据档位改变定时值
	MOV SUDU,A	
	ADD A,#1		
	MOVC A,@A+DPTR	
	MOV SUDU+1,A	
	RET				
SPEEDTAB:
	DB 3CH,0B0H			;50MS
	DB 0B1H,0E0H		;20MS
	DB 0D8H,0F0H		;10MS
	DB 0ECH,78H			;5MS
	DB 0FCH,18H			;1MS
;-----------------------------------------------------
INITIAL:
	MOV BLANK0,#10H					;显示'-'
	MOV ZHUANGTAI,#0				;显示'OF'，电机停止
	MOV ZHUANGTAI+1,#0FH
	MOV BLANK1,#10H					;显示'-'
	MOV DIRECTION,#01				;方向为正
	MOV BLANK2,#10H					;显示'-'
	MOV SPEED,#0					;速度为0
	MOV SPEED+1,#0
	MOV DANGWEI,#0					;档位0档
	RET
;----------------------------------
KEYBOARD:
	SETB KEY						;KEY为输入
	MOV C,KEY						
	JC K1							;判断KEY是否为低
	LCALL DELAY20					;为低,延时
	JC K1							;再次判断
	LCALL KEY1						;读键值
K0:
	MOV C,KEY						;判断键是否释放
	JNC K0
	LCALL KEY2						;将键值转化为键号
	RET
K1:
	MOV A,#0FFH						;无键，A=0FFH
	RET

KEY1:								
	CLR CS							;CS=0
	MOV R6,#1AH						;50us
K2:
	DJNZ R6,K2
	MOV A,#15H						;发送读键值控制字
	LCALL STFS
	MOV R6,#0CH						;26us
K3:
	DJNZ R6,K3
	LCALL STJS						;接受键值
	SETB CS
	RET
KEY2:
	MOV B,A							;将键值保存
	MOV R2,#00H
	MOV R7,#0FH						;键号
K4:
	MOV A,R2
	ADD A,#0AH
	MOVC A,@A+PC					;查表比较键值
	CJNE A,B,K5
	SJMP K6
K5:
	INC R2
	DJNZ R7,K4
K6:
	MOV A,R2						;与键值相等，保存键号
	RET
TAB1:
	DB 00H,01H,09H,11H,02H,0AH,12H,03H,0BH,13H,1BH,1AH,19H,18H,10H,08H	;0-F
;----------------------------------------------------------------------		
DISP7279:
	MOV R5,#8						;显示个数
	MOV R0,#BLANK0
	MOV R1,#90H						;显示位控码
LP1:
	CLR CS							
	MOV R6,#1AH						;CS为0
LP2:								;延时50us
	DJNZ R6,LP2
	MOV A,R1						;发送位控码
	ACALL STFS
	MOV R6,#8
LP3:
	DJNZ R6,LP3						;18us
	MOV A,@R0						;转化为字形码
	MOV DPTR,#TAB2
	MOVC A,@A+DPTR
	ACALL STFS						;发送字形码
	MOV R6,#4						;10us
LP4:
	DJNZ R6,LP4
	SETB CS
	INC R0
	INC R1
	DJNZ R5,LP1						;是否显示完毕
	RET
TAB2:DB 7EH,30H,6DH,79H,33H,5BH,5FH,70H,7FH,7BH  ;0-9
	 DB 77H,1FH,4EH,3DH,4FH,47H					 ;A-F
	 DB	01H  ;'-'
	 DB 76H  ;'N'
	 DB 0FEH ;'0.'
;----------------------------------
DELAY20:       					;20ms延时
	MOV R6,#100
DLY0:
	MOV R7,#98
	NOP
DLY1:
	DJNZ R7,DLY1
	DJNZ R6,DLY0
	RET
;--------------------------------------------------------------
STFS:						;发送一字节
	MOV R7,#8
L1:
	RLC A
	MOV DAT,C				;C送DATA
	SETB CLK				;CLK上升沿
	MOV R6,#4				;8us
L2:
	DJNZ R6,L2
	CLR CLK					;CLK下降沿
	MOV R6,#4
L3:
	DJNZ R6,L3
	DJNZ R7,L1
	RET
;--------------------------------------------------------------
STJS:						;接收一字节
	MOV R7,#8
Q1:
	SETB CLK				;CLK上升沿
	SETB DAT				;P口置'1'
	MOV R6,#4				;8us
Q2:
	DJNZ R6,Q2
	MOV C,DAT				;接收数据
	RLC A
	CLR CLK
	MOV R6,#2
Q3:
	DJNZ R6,Q3
	DJNZ R7,Q1
	RET
;----------------------------------------------------------
OUTT0:
	PUSH PSW							;外部脉冲启动
	PUSH ACC
	INC PAIXU							;拍序加1
	MOV A,PAIXU							
	CJNE A,#08,OUT0						;是否到8？
OUT0:
	JC OUT1
	MOV PAIXU,#0						;到了,转为0态
OUT1:
	MOV A,PAIXU
	MOV DPTR,#OUTTAB					;查表
	MOVC A,@A+DPTR
	MOV P1,A		;2
	POP ACC			;2
	POP PSW			;2
	LCALL DISP7279
	RETI			;1
OUTTAB:DB 06H,0EH,0CH,0DH,09H,0BH,03H,07H
;----------------------------------------------------------
INT_T0:
	PUSH PSW						;保护现场
	PUSH ACC
	SETB RS0						;使用工作寄存器1
	MOV TH0,SUDU					;重装定时值
	MOV TL0,SUDU+1
	INC PAIXU						;拍序加1,状态变化
	MOV A,PAIXU
	CJNE A,#08,II0					;拍序到8？
II0:
	JC II1
	MOV PAIXU,#0					;到了,转为0态
II1:
	MOV A,DIRECTION					;根据方向查表
	JB ACC.0,II5
	MOV DPTR,#FANTAB				;方向为0查反转表
	SJMP II6
II5:
	MOV DPTR,#TAB					;方向为1查反转表
II6:
	MOV A,PAIXU
	MOVC A,@A+DPTR
	MOV P1,A						;送P口显示
II4:
	POP ACC
	POP PSW
	RETI
TAB:DB 06H,0EH,0CH,0DH,09H,0BH,03H,07H
FANTAB:
	DB 07H,03H,0BH,09H,0DH,0CH,0EH,06H
	END