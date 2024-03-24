
.include "m16def.inc"; 
.list                                                                                        
;*******************
;*******************
; Register Variables
;*******************
.def temp     =R16
.def Counter  =R17
.def Delay1   =R18;
.def Delay2   =R19;
.def Delay3   =R20;
;*****************
;***************** 
; Constants
;*****************
.equ Val_del1=0x80;
.equ Val_del2=0x38;
.equ Val_del3=0x01;
;                  		   
;***********************************
.cseg
.org $0000
rjmp Init
;****************
.org  INT0addr;=$002	;External Interrupt0 Vector Address
reti
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

Init:  	  ldi   temp,LOW(RAMEND);выбор вершины стека
	      out   SPL, temp;Указатель стека 
	      ldi   temp,HIGH(RAMEND)
	      out   SPH,temp
;
; ------Инициализация портов В/B
;
Init_B:   ldi   temp,0b11101111;PB4-вход,остальные выходы
          out   DDRB,temp
          ldi   temp,0b00010000;PB4 подт.резистор,выбран индикатор PB0=1 
	      out   PORTB,temp
;
Init_D:   ser   temp;  (PС0-PС7) - выходы
	      out   DDRD,temp
	      ldi   temp,0b00000000;код "0" при включении	    
	      out   PORTD,temp;
;
Init_CNT: ldi   Counter,8;сброс счетчика при включении

;==================================================
;начало цикла
;==================================================	  
Start:    sbic  PinB,4    ;кнопка нажата?
          rjmp  Start     ;нет, остаемся в цикле
		  lsl   Counter 
	      out   PORTD,Counter
          cpi   Counter,128;Counter=10?
	      brne  PC+2      ;Нет, пропускаем команду
	      ldi   Counter,8   ;да, сбрасываем счетчик 	   
delay_1:  rcall delay_DK  ;задержка для подавлениядребезга контактов;	       
End_prog: rjmp  Start
;==================================================	   
; конец цикла	   
;==================================================	
; Подпрограмма Delay_DK
;==================================================   
Delay_DK: ldi   Delay1,Val_del1;
          ldi   Delay2,Val_del2 
          ldi   Delay3,Val_del3
cycle:    subi  Delay1,1;
          sbci  Delay2,0
	      sbci  Delay3,0
	      brcc  cycle
End_deley: ret 



