;*************************************
;* Designer        Mechtcherjakowa R.I.
;* Version:        1.0
;* Date            13.04.2020
;* Title:          Dynam_indication.asm
;* Device          ATmega16
;* Clock frequency:Частота кв.резонатора 8 мГц 
;*************************************
; учебная
;*************************************
;При нажатии на кнопку "Случайное число" формируется случайное число, которое 
;выводится на семисегментные индикаторы. 
;Кнопка "Случайное число" подключена к подключена к PD2(INT0),
;семигегментные индикаторы к  PС0-PС7 
;PC0-a,PC1-b,PC2-c,PC3-d,PC4-e,PC5-f,PC6-g,PC7-h
;сигналы выбора индикатора PB2 - сотни,PB1-десятки,PB0 - единицы - выходы
;***********************************************
.include "m16def.inc"
;-----------------------------------------------
.list                   ;включение листинга                                                                      
;*******************
;*******************
; Register Variables
;*******************
.def temp_L      =R16
.def temp_H      =R17
.def Random      =R24;буфер случайного числа
.def Hundreds    =R18;буфер для индикатора "Сотни"
.def Tens        =R19;буфер для индикатора "Десятки"
.def Ones        =R20;буфер для индикатора "Единицы"
.def Disp_Numb   =R22;указатель активного индикатора
.def Disp_Count  =R23;счетчик формирования временного интервала динамической индикации
;-------------------------  
; Constants
;**************************
.equ Val_dispCount=100;величина константы,опр. время вкл индикатора            
;-------------------------
.dseg
Var_buffer: .BYTE 8
;***********************************
.cseg
.org $0000
rjmp Init
;***********************************
;Вектора прерываний
;***********************************
.org  INT0addr;=$002	;External Interrupt0 Vector Address
rjmp  IN_INT0;
;-------------------
.org  INT1addr;=$004	;External Interrupt1 Vector Address
reti
.org  OC2addr; =$006	;Output Compare2 Interrupt Vector Address
reti
.org  OVF2addr;=$008	;Overflow2 Interrupt Vector Address
reti 
.org  ICP1addr;=$00A	;Input Capture1 Interrupt Vector Address
reti
.org  OC1Aaddr;=$00C	;Output Compare1A Interrupt Vector Address
reti
.org  OC1Baddr;=$00E	;Output Compare1B Interrupt Vector Address
reti
.org  OVF1addr;=$010	;Overflow1 Interrupt Vector Address
reti
.org  OVF0addr;=$012	;Overflow0 Interrupt Vector Address
reti
.org  SPIaddr; =$014	;SPI Interrupt Vector Address
reti
.org  URXCaddr;=$016	;UART Receive Complete Interrupt Vector Address
reti
.org  UDREaddr;=$018	;UART Data Register Empty Interrupt Vector Address
reti
.org UTXCaddr; =$01A	;UART Transmit Complete Interrupt Vector Address
reti
.org ADCCaddr; =$01C	;ADC Interrupt Vector Address
reti
.org ERDYaddr; =$01E	;EEPROM Interrupt Vector Address
reti
.org ACIaddr;  =$020	;Analog Comparator Interrupt Vector Address
reti
.org TWIaddr;  =$022   ;Irq. vector address for Two-Wire Interface
reti
.org INT2addr; =$024   ;External Interrupt2 Vector Address
reti
.org OC0addr;  =$026   ;Output Compare0 Interrupt Vector Address
reti
.org SPMRaddr; =$028   ;Store Program Memory Ready Interrupt Vector Address
reti
;***********************************
; Start Of Main Program
;***********************************
Init:
          ldi   temp_L,LOW(RAMEND);выбор вершины стека
	      out   SPL, temp_L;Указатель стека 
	      ldi   temp_L,HIGH(RAMEND)
	      out   SPH,temp_L
; ------Инициализация портов В/B

Init_B:	  ldi   temp_L,0b11111111;(PB1-PB7)-выходы,
          ldi   temp_H,0b00000100;выбраны сотни (1-й индикатор)
          out   DDRB,temp_L        
	      out   PORTB,temp_h
;
Init_C:	  ser   temp_L;  (PC0-PC7) - выходы
	      out   DDRC,temp_l
;
Init_D:   ldi   temp_L,0b11111011;,PD2-вход,(PD4-PD6)-выходы,(PD3,PD7) не исп
          ldi   temp_H,0b00000100;Вкл подтяжка на кнопках. PD2
	      out   DDRD,temp_L  
	      out   PORTD,temp_H;
;
Init_A:   ldi   temp_L,0b00000000;не используются сконфигурированы как входы
          ldi   temp_H,0b11111111;с подтягивающими регистрами
	      out   DDRA,temp_L  
	      out   PORTA,temp_H;
;---------------------------------------
;Инициализация  внешнего прерывания INT0          
          ldi   temp_L,(1<<ISC01); (1<<ISC01);прерывание по спаду
	      out   MCUCR,temp_L
	      ldi   temp_L,(1<<INT0);INT0: External Interrupt Request 0 Enable 
	      out   GIMSK,temp_L
;Инициализация используемых РОН
          ldi   Disp_Count,Val_dispCount
	      clr   Disp_Numb 	    	     
	      ldi   Random,1     ;любое число в регистр Random (1);
	      clr   Hundreds;
          clr   Tens    ;(0) значение на индикаторах
          clr   Ones
		  ldi   YL,low(Var_buffer)
		  ldi   YH,high(Var_buffer)
;
          sei            ;разрешаем прерывания (I)
;**************************************************
;Основной цикл
;==================================================
Start:    rcall  Display
	      rjmp   Start     
;==================================================
;завршение основного цикла	      
;***************************************************	
; Подпрограмма Display работы с дисплеем (динам. индикация)
;==================================================   
Display:  dec   Disp_Count
          brne  ex_displ
;
          ldi   Disp_Count,Val_dispCount
;          
          inc   Disp_Numb
		  cpi   Disp_Numb,3
		  brne  Out_disp
		  clr   Disp_Numb
Out_disp: ldi   ZL,18;  ;указатель на Hundreds адрес R18
          ldi   ZH,0
          add   ZL,Disp_Numb
		  ld    temp_L,Z; читаем двочно-десятичный код,для вывода на индикатор
;преобразуем в семисегментный код
          ldi   ZL,low(TABLE*2) ;загружаем адрес начала 
          ldi   ZH,high(TABLE*2);таблицы в памяти программ (*2 - для байтовой 
          add   ZL,temp_L       ;адресации)
    	  clr   temp_L
          adc   ZH,temp_L                         
	      lpm   temp_L,Z    ;читаем семисегментный код значения ; 
		  out   PortC,temp_L; выводим на индикаторы
;переключаем индикатор
          in    temp_L,PINB
		  andi  temp_L,0b00000111

		  lsr   temp_L
		  brcc  PC+2
		  ldi   temp_L,0b00000100; в начало (Hundreds)	   
		  out   PORTB,temp_L		   
;
ex_displ: ret
;
;==================================================
;------- Таблица перекодировки символов
TABLE:    .db   0b00111111,0b00000110; коды "0","1"
          .db   0b01011011,0b01001111; коды "2","3"
          .db   0b01100110,0b01101101;;коды "4","5"
		  .db   0b01111101,0b00000111;;коды "6","7"
		  .db   0b01111111,0b01101111;;коды "8","9"      	   
;*******************************************************
;Подпрограмма обработки  внешнего прерывания INT0
;*******************************************************
IN_INT0:   push   temp_L
           push   temp_H
           in     temp_L,SREG
		   push   temp_L 
;
           rcall  val_rand;формируем случайное число
           rcall  digitConvert;преобразуем двоичное число в двоично-десятичное

           ldi     temp_L,(1<<INTF0);
		   out     GIFR,temp_L
;
           pop     temp_L
           out     SREG,temp_L
           pop     temp_H
           pop     temp_L
		   reti
;===============================
val_rand:  mov     temp_L,Random 
           add     temp_L,Random 
		   add     temp_L,Random
		   ldi     temp_H,5
		   add     temp_L,temp_H
		   mov     Random,temp_L
		   st      Y+,temp_L
           ret
;===================================================
;Конвертирует двоичное 1-х байтное число в двоично-десятичный код 
;===================================================
digitConvert:
            clr   Hundreds
			clr   Tens  
			clr   Ones
;
FindHundreds:
            subi  temp_L,100
			brcs  FindTens
            inc   Hundreds
			rjmp  FindHundreds
;
FindTens:   subi  temp_L,-100
            subi  temp_L,10
            brcs  FindOnes
            inc   Tens 
			rjmp  FindTens+1
;
FindOnes:   subi  temp_L,-10
            mov   Ones,temp_L
            ret
;===================================================
          
          
