;*************************************
;* Designer        Mechtcherjakowa R.I.
;* Version:        1.0
;* Date            18.03.2009
;* Title:          Reaction.asm
;* Device          ATmega16
;* Clock frequency:Частота кв.резонатора 8 мГц 
;*************************************
; учебная
;*************************************
;(Назначение - программа определяет время реакции пользователя и 
;отображает время реакции пользователя в мсек на дисплее (3 семиcегмент.индикатора).
;после нажатия кнопки "Готовность" через случайный промежуток времени (4...12с)
;загорается светодиод (СИД),при его включении пользователь должен
;нажать кнопку "Реакция")
;Кнопка "Готовность" подключена к PD1,кнопка "Реакция" подключена к PD2(INT0) входы,
;Cветодиод СИД подключенк PB7 - выход
;семигегментные индикаторы   PC0-PC7-выходы,семигегментный индикатор  
;PC0-a,PC1-b,PC2-c,PC3-d,PC4-e,PC5-f,PC6-g,PC7-h
;сигналы выбора индикатора PB2 - сотни,PB1-десятки,PB0 - единицы - выходы
;***********************************************
;***********************************************
;Задание
;1.Выполните проверку работы программы в симуляторе AVR Studio.Измерьте в симуляторе
; время,в течении которого поочередно включен  каждый семисегментный индикатор 
;2.Выполните программирование макетной платы. Проверьте работу платы в 3-х режимах:
;- нажать кнопку PD1-"готовность",после загорания CИД(PB7) нажать  PD2-"реакция"
;- нажать кнопку PD1-"готовность",до загорания CИД(PB7) нажать  PD2-"реакция"
;- нажать кнопку PD1-"готовность",после загорания CИД(PB7) не нажимать  PD2-"реакция"
;3.Найдите и исправьте ошибку в программе
;4.Доработайте программу,увеличив счетчик дисплея Disp_Count до 2-х байт с максимальным
;значением 0xFFFF,введя дополнительный байт Disp_CountH. Запрограммируйте макет.плату
;5.Объясните работу схемы.Экспериментально подберите константу Val_dispCount,опре-
;деляющую время включения  индикатора, когда глаз не воспринимает мигание индикаторов.
;***********************************************************************************
.include "m16def.inc";"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler\Appnotes\m16def.inc"
; присоединение файла описаний; 
.list                   ;включение листинга                                                                      
;*******************
;*******************
; Register Variables
;*******************
.def temp       =R16
.def Random     =R15;буфер случайного числа
.def Hundreds   =R18;
.def Tens       =R19
.def Ones       =R20
.def CountX     =R14;счетчик формирования случайного интервала   
.def Disp_Numb  =R22;указатель включенного интервала
.def Disp_Count =R23; счетчик обновления дисплея
.def TimeH      =R17;счетчик переполнений Т0
.def TimeL      =R25
.def Count3     =R13
.def tempH      =R21
.def tempH2     =R26
.def temp2      =R27 
;*****************
.def Byte_fl    =R24;байт флагов
;------------------
.equ F_ready        =1;бит флага "Готовность" (бит 1 в байте Byte_fl)
;***************** 
; Constants
;*****************
.equ Val_dispCount=50;величина константы,опр. время вкл индикатора 
;***********************************
.cseg
.org $0000
rjmp Init
;****************
;****************
.org  INT0addr;=$002	;External Interrupt0 Vector Address
rjmp  IN_INT0;
;----------------
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
rjmp  IN_T0ovf
;--------------------
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
          ldi   temp,LOW(RAMEND);выбор вершины стека
	      out   SPL, temp;Указатель стека 
	      ldi   temp,HIGH(RAMEND)
	      out   SPH,temp

; ------Инициализация портов В/B

Init_B:	  ldi   temp,0b11111111;(PB1-PB7)-выходы,
          out   DDRB,temp
          ldi   temp,0b00000100;выбраны сотни (1-й индикатор)
	      out   PORTB,temp

Init_C:	  ser   temp;  (PA0-PA7) - выходы
	      out   DDRC,temp
;
Init_D:    ldi   temp,0b11111001;PD1,PD2-входы, остальные-выходы
	      out   DDRD,temp
	      ldi   temp,0b00000110;Вкл подтяжка на кнопках.   
	      out   PORTD,temp;

; ---  Инициализация  таймера TCNT0
Init_T0:  ldi   temp,(1<<TOIE0);TOIE0-Timer/Counter0 Overflow Interrupt Enable
	      out   TIMSK,temp

; ---  Инициализация  внешнего прерывания INT0
;
          ldi   temp,(1<<ISC01); ;прерывание по спаду ISC01=1 ISC00=0
	      out   MCUCR,temp
	      ldi   temp,(1<<INT0);INT0: External Interrupt Request 0 Enable 
	      out   GIMSK,temp
;
Init_R:   ldi   Disp_Count,Val_dispCount
	      clr   Disp_Numb 	    	     
          clr   Byte_fl
	      ldi   temp,1     ;любое число
	      mov   Random,temp;в регистр Random (1)
	      clr    Hundreds;выключение индикаторов
          clr    Tens    ;(0)
          clr    Ones

;==================================================
;начало цикла
;==================================================
Start:    rcall  Display
          sbrc   Byte_fl,F_ready
	      rjmp   Start     ;внутренний цикл
	      sbic   PIND,1    ;ждем нажатия кнопки "Готов" 
	      rjmp   Start
;
Rand_st:  mov    temp,Random;Вычисляем следующее случайное число 
          add    Random,temp;умножаем на 5 сложением
          add    Random,temp;случайное число в диапазоне(0-255)
          add    Random,temp
          add    Random,temp
          add    Random,temp
          inc    Random
;
          mov    temp,Random;Т0 - 8 разр таймер. Counter0 оverflow соотвествует
          lsr    temp;времени 256*1024/8000000=0,033с.Интервал (4...8,4с)->
		             ;                                Формируем интервал(127+Random/2)
	      subi   temp,-127;случайное число (90 - 256)
Rand_end: mov    CountX,temp
	          

          ldi   temp,(1<<CS02)|(1<<CS00);частота TCNT0 Clk/1024,(CS02,CS01,CS00)
  	      out   TCCR0,temp;включаем таймер

          ldi    temp,(1<<INTF0)
          out    GIFR,temp;сбрасываем флаг прерыв.INT0 записью 1

          ldi    temp,(1<<TOV0)
	      out    TIFR,temp;сбрасываем флаг прерыв TOV0 

          sei             ;разрешаем прерывания

          clr    TimeH   ;сброс счетчика переполнений Т0
          clr    Hundreds;выключение индикаторов
          clr    Tens
          clr    Ones
	      set
          bld    Byte_fl,F_ready;Флаг F_ready (бит1) в байте Byte_fl установить в 1
	      rjmp   Start
;==================================================	   
; конец цикла
;==================================================	
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
          rjmp  Out_disp

Out_disp: ldi   ZL,18;     ;указатель на Hundreds
          ldi   ZH,0;
          add   ZL,Disp_Numb
		  ld    temp,Z
;                           преобразуем в семисегментный код
;---------------------------------------------------- 
         ; ldi   ZL,TABLE*2;загружаем адрес начала 
 	     ; ldi   ZH,0x00   ;таблицы в памяти программ (*2 - для байтовой 
	    ;  add   ZL,temp   ;адресации)

 ldi   ZL,low(TABLE*2);загружаем адрес начала 
 ldi   ZH,high(TABLE*2);таблицы в памяти программ (*2 - для байтовой
 add   ZL,temp   ;адресации)
 clr   temp
 adc   ZH,temp
	      lpm   temp,Z    ;читаем семисегментный код значения ; 
		  out   PortC,temp; передаем на индикатор
;
          in    temp,PINB
		  in    temp2,PINB
		  andi  temp,0b00000111;маскируем биты выбора индик.PB2 - сотни,PB1-десятки,PB0 - един.
		  andi  temp2,0b10000000;маскируем бит светодиода (СИД)
		  lsr   temp
		  brcc  PC+2
		  ldi   temp,0b00000100; в начало (Hundreds)	   
          or    temp, temp2;восстанавливаем СИД
		  out   PORTB,temp
		   
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
		  .db   0b01111100,0b01110111; коды "b","A"
		  .db   0b01011110,0b01000000; коды "d","-"
		  .db   0b01110110,0b00110000; коды "H","I"	 
      	   
;================================================== 
;Подпрограмма обработки  внешнего прерывания INT0
;Т0 - 8 разр таймер. Counter0 оverflow соотвествуетвремени 256*1024/8000000=0,033с
;1мсек=7,8125отсчета. т.е за временной интеввал считаем не более 7812,5 отсчета два байта
;для преобразование в мсек делим  на 7,8125 (или *0,128) что можно получить (16/125)
;-> (8/125)*2)
;на 3 семисегмент. индикатора можно вывести максимальное число 999,Этому соответствует
; ограничение в отсчетах 
;за время 999мсек имеем Х_отсч*(16/125), где Х_отсч=7804 (1E7C)h. Контролируем лишь старший байт
; TimeH (1Fh), добавив 84h,а затем вычитая его из результата.
;.
;===================================================
IN_INT0:   push   temp
           in     temp,SREG
		   push   temp 
;
           sbis   PINB,7;проверяем СИД
           rjmp   Cheat
           clr    temp
		   out    TCCR0,temp;остaнов Т0
		   in     TimeL,TCNT0
		   in     temp,TIFR  ;проверяем Т0 на переполнение
           sbrc   temp,1
		   inc    TimeH
		   subi   TimeL,0x84 ;вычитаем 84h
		   sbci   TimeH,0


           ldi    temp,4 
           mov    Count3,temp; умножаем время реакции на 16.логическим сдвигом влево 4 раза
		   clr    tempH2
		   mov    temp,TimeL
		   mov    tempH,TimeH
shl3:	   lsl    temp
		   rol    tempH
		   rol    tempH2
           dec    Count3
		   brne   shl3   
;
           clr    TimeL
		   clr    TimeH
;
Divide12:  subi   temp,125;деление вычитанием
           sbci   tempH,0
		   sbci   tempH2,0
           brcs   DoneDividing
		   inc    TimeL 
		   brne   Divide12
		   inc    TimeH
		   rjmp   Divide12
; 
DoneDividing:
           rcall  digitConvert		   		   		    
;		     
ex_INT0:   clt
		   bld    Byte_fl,F_ready
		   clr    TimeH   ;сброс счетчика переполнений Т0
		   clr    temp
		   out    TCCR0,temp;остaнов Т0
		   cbi    PORTB,7;выключаем СИД
           pop    temp         ;выход без разрешения глоб. прерывания
           out    SREG,temp
		   pop    temp
           ret
;================================================= 
Cheat:     ldi    Hundreds,10;коды "b",
           ldi    Tens,11    ;     "A"
           ldi    Ones,12    ;     "d"
           rjmp   ex_INT0
;
;===================================================
;Конвертирует двоичное 2-х байтное число в двоично-десятичный код 
;===================================================
digitConvert:
            clr   Hundreds
			clr   Tens  
			clr   Ones
;
FindHundreds:
            subi  TimeL,100
			sbci  TimeH,0
			brcs  FindTens
            inc   Hundreds
			rjmp  FindHundreds
;
FindTens:   subi  TimeL,-100
            subi  TimeL,10
            brcs  FindOnes
            inc   Tens 
			rjmp  FindTens+1
;
FindOnes:   subi  TimeL,-10
            mov   Ones,TimeL
            ret
;=================================================== 
;Подпрограмма обработки прерывания переполнения таймера Т0
;Т0 - 8 разр таймер. Counter0 оverflow соотвествуетвремени 256*1024/8000000=0,033с
;1cек =(1024/8000000)*N_отсчетов.(N отсч =7812,5 за секунду)
;1мсек=7,8125отсчета. т.е за временной интеввал считаем не более 7812,5 отсчета два байта
;для преобразование в мсек делим  на 7,8125 (или *0,128) что можно получить (16/125)
;за время 999мсек имеем Х_отсч*(16/125), где Х_отсч=7804 (1E7C)h. Контролируем TimeH (1Fh)
; добавив 84h,а затем вычитая.
;===================================================
IN_T0ovf:  push   temp
           in     temp,SREG
		   push   temp 
;            
           sbic   PINB,7;проверяем СИД
           rjmp   LEDon
		   dec    CountX
		   brne   ex_T0ovf
Start_m:   ldi    temp,0x84
		   out    TCNT0,temp
		   sbi    PORTB,7;включаем СИД
;
ex_T0ovf:  pop    temp         ;выход c разрешениtv глоб. прерывания
           out    SREG,temp
		   pop    temp
           reti
;
LEDon:     inc    TimeH         ;инкрементируем ст байт
           cpi    TimeH,0x1F    ;проверяем на максимальное время   
		   brlo   ex_T0ovf
;                              превышеие времеми > 999 мсек
out_HI:    clt
		   bld    Byte_fl,F_ready 
		   clr    temp
		   out    TCCR0,temp;остaнов Т0
           ldi    Hundreds,13 ;"-"
		   ldi    Tens,14     ;"H" 
		   ldi    Ones,15     ;"I"
		   cbi    PORTB,7;выключаем СИД
		   pop    temp
           out    SREG,temp
		   pop    temp
		   ret                 ;выход без разрешения глоб. прерывания
;=====================================================


;****************************************************  
;          ldi   ZL,18;     ;указатель на Hundreds
;		   ldi   ZH,0
;----------------------------------------------------
;          ldi   ZL,low(TABLE*2);загружаем адрес начала 
;	       ldi   ZH,high(TABLE*2);таблицы в памяти программ (*2 - для байтовой 
;	       add   ZL,temp   ;адресации)
;		   clr   temp
;          adc   ZH,temp
;*******************************************************
;.def Disp_CountH=R1
;---------------------
; Constants
;*****************
;.equ Val_dispCountH=255;величина константы,опр. время вкл индикатора  
;*****************
;          ldi   Disp_Count,Val_dispCount
;          ldi   temp,Val_dispCountH
;          mov   Disp_CountH,temp
;          
;----------------------------------------
;          subi  Disp_Count,0x01
;          ldi   temp,0x00
;   	  sbc   Disp_CountH,temp
;		  ldi   temp,0x00
;		  cp    Disp_Count,temp
;		  brne  ex_displ 
;		  cp    Disp_CountH,temp
;		  brne  ex_displ
;
;          ldi   Disp_Count,Val_dispCount
;          ldi   temp,Val_dispCountH
;          mov   Disp_CountH,temp
;          
;----------------------------------------
