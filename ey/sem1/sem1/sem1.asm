;*************************************
;* Designer        Ionin D.A..
;* Version:        1.0
;* Date            13.03.2024
;* Title:          Countert.asm
;* Device          ATtiny2313
;* Clock frequency:Частота кв.резонатора 8 мГц 
;*************************************
; учебная
;*************************************
;Задание: 1.Записать в ОЗУ 8 зачений случайных чисел
;         2.Просуммировать 8 значений случайных чисел
;		  3.Найти среднее значение случайных чисел         
;*************************************
.include "m16def.inc"	;присоединение файла описаний
.list                   ;включение листинга                                                                      
;*******************
;*******************
; Register Variables
;*******************
.def temp_L   =R16;  регистры
.def Random	  =R17;  регистры
.def cou_rand =R18;  регистры
.def temp_H   =R19;  регистры
.def data	  =R20;  регистры
;*****************
;***************** 
; Variable
;*****************
.DSEG;
;
varBufer:		.BYTE 8; запись в SRAM
; Variable
;***********************************		   
;***********************************
.cseg;
.org $0000;
rjmp Init;
;****************

;***********************************
; Start Of Main Program
;***********************************

Init:  	  ldi   temp_L, LOW(RAMEND);
          out   SPL, temp_L;
          ldi   Random, 10;
;--------------------------------------------------
begin:	  ldi 	cou_rand,8;
		  ldi 	YL,low(varBufer);
		  ldi 	YH,high(varBufer);
		  rcall Random_to_SRAM;
;
		  ldi 	cou_rand,8;
		  ldi 	YL,low(varBufer);
		  ldi 	YH,high(varBufer);
		  rcall val_midl;
;
		  rjmp 	begin
;==================================================
;начало цикла
;==================================================	  

;==================================================	   
; конец цикла	   
;==================================================	
;
;
;
; Подпрограмма Random_to_SRAM
;==================================================   
Random_to_SRAM: rcall val_rand;
			st 		Y+,temp_L;
			dec 	cou_rand;
			cpi 	cou_rand, 0;
			brne 	Random_to_SRAM;

 ret 
; Подпрограмма val_midl
;==================================================   
val_midl: 
			clr 	temp_L;
			clr 	temp_H;
			ldi		cou_rand, 8;	
cyc_v_r: 	ld 		data,Y+;
			add 	temp_L, data;
			clr 	data;
			adc 	temp_H, data;
			dec		cou_rand;
			cpi 	cou_rand, 0;
			brne 	Cyc_v_r
			ldi 	cou_rand, 3;
cyc_sh_r:	lsr 	temp_H;
			ror		temp_L;
			dec		cou_rand;
			brne	cyc_sh_r;
			mov		data, temp_H;

 ret 
; Подпрограмма val_rand
;==================================================   
val_rand: 
			mov 	temp_L,Random;
			add 	temp_L,Random;
			add 	temp_L,Random;
			ldi 	temp_H,5
			add 	temp_L, temp_H;
			mov 	Random, temp_L; 

 ret 
