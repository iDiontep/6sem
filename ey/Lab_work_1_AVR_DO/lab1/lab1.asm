;*************************************
;* Designer        Ionin D.A..
;* Version:        1.0
;* Date            11.03.2024
;* Title:          Countert.asm
;* Device          ATmega16
;* Clock frequency:Частота кв.резонатора 8 мГц 
;*************************************
; учебная
;*************************************
;(Назначение - считает число нажатий на кнопку (0-9 нажатий,сброс,повторение)
;и выводит значение на семиcегментный индикатор).
;Кнопка подключена к PB4 (0V on pin when button is pressed), семигегментный индикатор к  PA0-PA7 
;PC0-a,PC1-b,PC2-c,PC3-d,PC4-e,PC5-f,PC6-g,PC7-h,выбран индикатор PB0(SW6-8)
; 
;Задание: 1.Найти ошибку и устранить
;         2.Уменьшить задержку для подавления дребезга контактов кнопки (< 50mkcek),
;           проверить работу схемы.
;		  3.Подобрать экспериментально длительность задержки,необходимую для 
;	        устойчивого подавления дребезга контактов
;         4.Модифицируйте программу так, чтобы счет цифр при нажатии кнопки проходил
;           в противоположном направлении (от 9 к 0).Запрограммируйте МК стенда 
;           и проверьте правильность работы программы. 
;           
;*************************************
.include "m16def.inc"; присоединение файла описаний; присоединение файла описаний
.list                   ;включение листинга                                                                      
;*******************
;*******************
; Register Variables
;*******************
.def temp     =R16
.def Counter  =R17
.def Delay1   =R18;регистры
.def Delay2   =R19;счетчика подавления дребезга контактов
.def Delay3   =R20;
;*****************
;***************** 
; Constants
;*****************
.equ Val_del1=0x40;0x80;величина константы задержки
.equ Val_del2=0x1F;0x38;(защитной паузы) 
.equ Val_del3=0x00;0x05;(частота 8мГц,5 тактов,время подавления дребезга контактов
;                  5мсек.Количество циклов 
;                  Хотч=8000 (001F40) (1/8000000)*5*Хотч=0,05сек) 
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
;
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
          ldi   temp,0b00010001;PB4 подт.резистор,выбран индикатор PB0=1 
	      out   PORTB,temp
;
Init_C:   ser   temp;  (PС0-PС7) - выходы
	      out   DDRC,temp
	      ldi   temp,0b01101111;код "9" при включении	    
	      out   PORTC,temp;
;
Init_CNT: ldi   Counter, 9;сброс счетчика при включении
;
;==================================================
;начало цикла
;==================================================	  
Start:    sbic  PinB,4    ;кнопка нажата?
          rjmp  Start     ;нет, остаемся в цикле 
	      dec   Counter   ;да, увеличиваем счетчик на 1
	   
          cpi   Counter,-1;Counter= - 1?
	      brne  PC+2      ;Нет, пропускаем команду
		  ldi   Counter, 9;;да, сбрасываем счетчик 


;	   
Read:     ldi   ZL,TABLE*2;загружаем адрес начала 
	      ldi   ZH,0x00   ;таблицы в памяти программ (*2 - для байтовой 
	      add   ZL,Counter;адресации)
	      lpm   temp,Z    ;читаем семисегментный код значения Counter
Write_A:  out   Portc,temp;передаем на индикатор   
delay_1:  rcall delay_DK  ;задержка для подавлениядребезга контактов
;	   
Key_end:  sbis  PinB,4  ;проверка отпускания кнопки
          rjmp  Key_end	    
delay_2:  rcall delay_DK 
End_prog: rjmp  Start
;==================================================	   
; конец цикла	   
;==================================================	
; Подпрограмма Delay_DK
;==================================================   
Delay_DK: ldi   Delay1,Val_del1;загрузка констант
          ldi   Delay2,Val_del2 
          ldi   Delay3,Val_del3

cycle:    subi  Delay1,1; Цикл - 5 тактов
          sbci  Delay2,0
	      sbci  Delay3,0
	      brcc  cycle
End_deley: ret 

;===================================================
;------- Таблица перекодировки символов
TABLE:    .db   0b00111111,0b00000110; коды "0","1"
          .db   0b01011011,0b01001111; коды "2","3"
          .db   0b01100110,0b01101101;;коды "4","5"
		  .db   0b01111101,0b00000111;;коды "6","7"
		  .db   0b01111111,0b01101111;;коды "8","9"   
;****************************************************        

