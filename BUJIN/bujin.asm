	KEY BIT P3.4					;KEY=P3.4
	DAT BIT P3.5					;DAT=P3.5
	CLK BIT P3.6					;CLK=P3.6
	CS  BIT P3.7					;CS=P3.7
	VAR SEGMENT DATA				;RAM���������
	PROG SEGMENT CODE				;ROM��������
	STACK SEGMENT IDATA				;RAM�����ջ��                
		RSEG VAR
	BLANK0:DS 1						;
	ZHUANGTAI:DS 2					;״̬��ʾ
	BLANK1:DS 1						;��ʾ������
	DIRECTION:DS 1					;����
	BLANK2:DS 1						;
	SPEED:DS 2						;�ٶ�  ת/����
	PAIXU:DS 1						;����
	DANGWEI:DS 1					;��λ
	SUDU:DS 2						;�ٶȵ��ڵ�Ԫ
		
		RSEG STACK					;��ջ
		DS 20
			
		CSEG AT 0					;������
		USING 0
		LJMP MAIN
	
		ORG 0003H					;�ⲿ�ж�
		USING 0
		LJMP OUTT0
	
		ORG 000BH					;��ʱ�ж�
		USING 1
		LJMP INT_T0
		
		ORG 0100H
		RSEG PROG
MAIN:
	MOV SP,#STACK-1
	MOV SUDU,#3CH					;��ʼ�ٶ�
	MOV SUDU+1,#0B0H
	MOV TMOD,#01H					;T0��ʱ��������
	MOV TH0,SUDU					;50MS
	MOV TL0,SUDU+1
	MOV IE,#82H						;���ж�
	MOV PAIXU,#0					;����Ϊ0
	MOV P1,#0						;P1�����					
	ACALL INITIAL					;��ʼ��
	SETB IT1						;�ⲿ�жϱ��ش�����ʽ
	SETB EX0
M0:
	LCALL DELAY20
	LCALL DISP7279
	LCALL KEYBOARD
	CJNE A,#0FFH,M1
	LCALL DELAY20
	SJMP M0
M1:
	LCALL KEYDEAL					;������
	SJMP M0
;-----------------------------------------------------
KEYDEAL:
	CJNE A,#0AH,D1					;��'A'
	CPL TR0							;TR0������ر�
	JB TR0,D4						;��״̬������ʾ������
	MOV ZHUANGTAI+1,#0FH
	SJMP D0
D4:
	MOV ZHUANGTAI+1,#11H
	LCALL SPEEDTEXT					;���ٶȳ�ֵ�����Ի���
	SJMP D0
D1:
	CJNE A,#0BH,D2					;��'B'
	MOV A,DIRECTION
	CPL ACC.0						;����ȡ���������Ի���
	MOV DIRECTION,A
	SJMP D0
D2:
	CJNE A,#0CH,D3					;��'C'
	MOV A,DANGWEI					
	CJNE A,#4,DD2
DD2:
	JNC D0
	INC DANGWEI						;��λ��1
	LCALL DIAOSU					;����
	LCALL SPEEDTEXT					;��ֵת��
	SJMP D0
D3:
	CJNE A,#0DH,D0					;��'D'
	MOV A,DANGWEI
	CJNE A,#1,DD3
DD3:
	JC D0
	DEC DANGWEI						;��λ��1
	LCALL DIAOSU					;����
	LCALL SPEEDTEXT					;��ֵת��
D0:
	RET
;-----------------------------------------------------
SPEEDTEXT:
	MOV A,DANGWEI					;�ٶ���ʾ���
	RL A							;��˫�ֽ�
	MOV DPTR,#SPEEDTEXTTAB
	MOVC A,@A+DPTR					;����ֽ�
	MOV SPEED,A
	MOV A,DANGWEI					;���Ի���
	RL A
	ADD A,#1						;����ֽ�
	MOVC A,@A+DPTR	
	MOV SPEED+1,A					;���Ի���
	RET
SPEEDTEXTTAB:
	DB 12H,05H						;ת��,0.5
	DB 00H,05H						;05
	DB 01H,00H						;10
	DB 02H,00H						;20
	DB 06H,00H						;60
;-----------------------------------------------------
DIAOSU:
	MOV A,DANGWEI					;�ٶȵ��ڲ��
	RL A
	MOV DPTR,#SPEEDTAB				;�鵵λ
	MOVC A,@A+DPTR					;���ݵ�λ�ı䶨ʱֵ
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
	MOV BLANK0,#10H					;��ʾ'-'
	MOV ZHUANGTAI,#0				;��ʾ'OF'�����ֹͣ
	MOV ZHUANGTAI+1,#0FH
	MOV BLANK1,#10H					;��ʾ'-'
	MOV DIRECTION,#01				;����Ϊ��
	MOV BLANK2,#10H					;��ʾ'-'
	MOV SPEED,#0					;�ٶ�Ϊ0
	MOV SPEED+1,#0
	MOV DANGWEI,#0					;��λ0��
	RET
;----------------------------------
KEYBOARD:
	SETB KEY						;KEYΪ����
	MOV C,KEY						
	JC K1							;�ж�KEY�Ƿ�Ϊ��
	LCALL DELAY20					;Ϊ��,��ʱ
	JC K1							;�ٴ��ж�
	LCALL KEY1						;����ֵ
K0:
	MOV C,KEY						;�жϼ��Ƿ��ͷ�
	JNC K0
	LCALL KEY2						;����ֵת��Ϊ����
	RET
K1:
	MOV A,#0FFH						;�޼���A=0FFH
	RET

KEY1:								
	CLR CS							;CS=0
	MOV R6,#1AH						;50us
K2:
	DJNZ R6,K2
	MOV A,#15H						;���Ͷ���ֵ������
	LCALL STFS
	MOV R6,#0CH						;26us
K3:
	DJNZ R6,K3
	LCALL STJS						;���ܼ�ֵ
	SETB CS
	RET
KEY2:
	MOV B,A							;����ֵ����
	MOV R2,#00H
	MOV R7,#0FH						;����
K4:
	MOV A,R2
	ADD A,#0AH
	MOVC A,@A+PC					;���Ƚϼ�ֵ
	CJNE A,B,K5
	SJMP K6
K5:
	INC R2
	DJNZ R7,K4
K6:
	MOV A,R2						;���ֵ��ȣ��������
	RET
TAB1:
	DB 00H,01H,09H,11H,02H,0AH,12H,03H,0BH,13H,1BH,1AH,19H,18H,10H,08H	;0-F
;----------------------------------------------------------------------		
DISP7279:
	MOV R5,#8						;��ʾ����
	MOV R0,#BLANK0
	MOV R1,#90H						;��ʾλ����
LP1:
	CLR CS							
	MOV R6,#1AH						;CSΪ0
LP2:								;��ʱ50us
	DJNZ R6,LP2
	MOV A,R1						;����λ����
	ACALL STFS
	MOV R6,#8
LP3:
	DJNZ R6,LP3						;18us
	MOV A,@R0						;ת��Ϊ������
	MOV DPTR,#TAB2
	MOVC A,@A+DPTR
	ACALL STFS						;����������
	MOV R6,#4						;10us
LP4:
	DJNZ R6,LP4
	SETB CS
	INC R0
	INC R1
	DJNZ R5,LP1						;�Ƿ���ʾ���
	RET
TAB2:DB 7EH,30H,6DH,79H,33H,5BH,5FH,70H,7FH,7BH  ;0-9
	 DB 77H,1FH,4EH,3DH,4FH,47H					 ;A-F
	 DB	01H  ;'-'
	 DB 76H  ;'N'
	 DB 0FEH ;'0.'
;----------------------------------
DELAY20:       					;20ms��ʱ
	MOV R6,#100
DLY0:
	MOV R7,#98
	NOP
DLY1:
	DJNZ R7,DLY1
	DJNZ R6,DLY0
	RET
;--------------------------------------------------------------
STFS:						;����һ�ֽ�
	MOV R7,#8
L1:
	RLC A
	MOV DAT,C				;C��DATA
	SETB CLK				;CLK������
	MOV R6,#4				;8us
L2:
	DJNZ R6,L2
	CLR CLK					;CLK�½���
	MOV R6,#4
L3:
	DJNZ R6,L3
	DJNZ R7,L1
	RET
;--------------------------------------------------------------
STJS:						;����һ�ֽ�
	MOV R7,#8
Q1:
	SETB CLK				;CLK������
	SETB DAT				;P����'1'
	MOV R6,#4				;8us
Q2:
	DJNZ R6,Q2
	MOV C,DAT				;��������
	RLC A
	CLR CLK
	MOV R6,#2
Q3:
	DJNZ R6,Q3
	DJNZ R7,Q1
	RET
;----------------------------------------------------------
OUTT0:
	PUSH PSW							;�ⲿ��������
	PUSH ACC
	INC PAIXU							;�����1
	MOV A,PAIXU							
	CJNE A,#08,OUT0						;�Ƿ�8��
OUT0:
	JC OUT1
	MOV PAIXU,#0						;����,תΪ0̬
OUT1:
	MOV A,PAIXU
	MOV DPTR,#OUTTAB					;���
	MOVC A,@A+DPTR
	MOV P1,A		;2
	POP ACC			;2
	POP PSW			;2
	LCALL DISP7279
	RETI			;1
OUTTAB:DB 06H,0EH,0CH,0DH,09H,0BH,03H,07H
;----------------------------------------------------------
INT_T0:
	PUSH PSW						;�����ֳ�
	PUSH ACC
	SETB RS0						;ʹ�ù����Ĵ���1
	MOV TH0,SUDU					;��װ��ʱֵ
	MOV TL0,SUDU+1
	INC PAIXU						;�����1,״̬�仯
	MOV A,PAIXU
	CJNE A,#08,II0					;����8��
II0:
	JC II1
	MOV PAIXU,#0					;����,תΪ0̬
II1:
	MOV A,DIRECTION					;���ݷ�����
	JB ACC.0,II5
	MOV DPTR,#FANTAB				;����Ϊ0�鷴ת��
	SJMP II6
II5:
	MOV DPTR,#TAB					;����Ϊ1�鷴ת��
II6:
	MOV A,PAIXU
	MOVC A,@A+DPTR
	MOV P1,A						;��P����ʾ
II4:
	POP ACC
	POP PSW
	RETI
TAB:DB 06H,0EH,0CH,0DH,09H,0BH,03H,07H
FANTAB:
	DB 07H,03H,0BH,09H,0DH,0CH,0EH,06H
	END