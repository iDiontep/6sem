;*************************************
;* Designer        Mechtcherjakowa R.I.
;* Version:        1.0
;* Date            08.04.2010
;* Title:          ADC_proj.asm
;* Device          ATmega16
;* Clock frequency:Частота кв.резонатора 8 mHz
;*************************************
; учебная
;*************************************
;Программа  осуществляет измерение напряжения,снимаемого с 2-х переменных резисторов,
;подключенных к цепи AREF=2,56B(вывод 32)и вывод измеренного значения на семисегм. индикаторы
;измеряемые напряжения подаются на вх PA0 (ADC0) и PA3 (ADC3)
;выбор канала, выводимого на индикаторы осуществляется нажатием кнопки "Выбор канала",
;подключенной к выводу PD3
;данные с АЦП усредняются путем суммирования (Val_N_ADC=1,2,4,8) раз и нахождения
;среднего значения, используя для деления сдвиг вправо
;измеренное значение Vin=(ADC*2,56)/1024=ADC/400. Используем только целые числа для
;вывода на дисплей, т.е. Vin*100. таким образом измеренное значение равно ADC/4
;увеличение в 100 раз при выводе на дисплей компенсируем выводом точки у первой зн.цифры
;семисегментные индикаторы подключены к PC0-PC7(выходы), 
;PC0-a,PC1-b,PC2-c,PC3-d,PC4-e,PC5-f,PC6-g,PC7-h
;сигналы выбора индикатора PB3-номер канала АЦП,PB2 - единицы,PB1-десятые,PB0-сотые (выходы)
;===================================================================================
;ЗАДАНИЕ: подключить резисторы к цепи VCC и изменить программные настройки и рез.измер-й
;продемонстрировать умение выполнять операции с битами
;доработать программу на выполнение одного преобразования
;***********************************************
.include "m16def.inc"
; присоединение файла описаний; 
.list                   ;включение листинга                                                                      
;*******************
;*******************
; Register Variables
;*******************
.def  temp_L     =R16
.def  temp_H     =R17
.def  Number     =R18 
.def  Hundreds   =R19;
.def  Tens       =R20
.def  Ones       =R21
.def  Disp_Numb  =R22
.def  Disp_Count =R23
.def  Time       =R24;счетчик переполн.Т0(1024*255/8000000*Xotc=1cek(Xotc=30)
.def  ADC_h      =R3
.def  ADC_l      =R4
.def  cou_ADC    =R25
;-------------------
.def  byte_fl    =R9
;-------------------
.equ  F_iz_kan    =0;флаг изменения канала:0 2-й канал.1 6-й канал
.equ  F_end_ADC   =1;флаг завершения (Val_N_ADC) преобразований АЦП
.equ  Disab_Key   =2;бит запрещения опроса кнопки "Выбор канала"
;******************* 
; Constants
;*******************
.equ   Val_dispCount=50
.equ   Val_N_ADC    =4;4;колич-во преобразований АЦП(1,2,4,8.16..)
.equ   VAL_time =30;30 переполнений соответствуют 1 сек
;***************************************
.cseg
.org $0000
rjmp Init
;****************
;****************
.org  INT0addr;=$002	;External Interrupt0 Vector Address
reti;
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
rjmp  time_d_k ;
.org  SPIaddr; =$014	;SPI Interrupt Vector Address
reti
.org  URXCaddr;=$016	;UART Receive Complete Interrupt Vector Address
reti
.org  UDREaddr;=$018	;UART Data Register Empty Interrupt Vector Address
reti
.org UTXCaddr; =$01A	;UART Transmit Complete Interrupt Vector Address
reti
.org ADCCaddr; =$01C	;ADC Interrupt Vector Address
rjmp  IN_ADC
.org ERDYaddr; =$01E	;EEPROM Interrupt Vector Address
reti
.org ACIaddr;  =$020	;Analog Comparator Interrupt Vector Address
reti
.org TWIaddr;  =$022    ;Irq. vector address for Two-Wire Interface
reti
.org INT2addr; =$024    ;External Interrupt2 Vector Address
reti
.org OC0addr;  =$026    ;Output Compare0 Interrupt Vector Address
reti
.org SPMRaddr; =$028    ;Store Program Memory Ready Interrupt Vector Address
reti
;***********************************
;***********************************
Init:
       ldi   temp_L,LOW(RAMEND);выбор вершины стека
	   out   SPL, temp_L;Указатель стека 
	   ldi   temp_L,HIGH(RAMEND)
	   out   SPH,temp_L
	   ; ------Инициализация портов В/B
;
	   ldi   temp_L,0b11111111;(PB1-PB7)-выходы,
       out   DDRB,temp_L
       ldi   temp_L,0b00001000;выбраны PB3-номер байта (1-й индикатор)
	   out   PORTB,temp_L
;
       ldi   temp_L,0b00000000;PD3-кнопка "Выбор канала" (вход)
	   out   DDRD,temp_L
	   ldi   temp_L,0b00001000;Вкл подтяжка на кнопке PD3  
	   out   PORTD,temp_L;
;
       ldi   temp_L,0b11111111;(PС1-PС7)-выходы
       out   DDRC,temp_L
;Analog-to-digital
       ldi   temp_L,0x00
	   out   DDRA,temp_L; входы АЦП
;       
;(Internal 2.56V Voltage Refer. with external capacitor at AREF pin)REFS1,REFS0=1
;0-й канал ADC0
       ldi   temp_L,(0<<REFS1)|(0<<REFS0);
	   out   ADMUX,temp_L  
;
       ldi   temp_L,(1<<ADPS2)|(1<<ADPS1);
	   out   ADCSR,temp_L
;
       clr   byte_fl
	   clr   cou_ADC
;	      
	   clr   ADC_h;
       clr   ADC_l
;
       clr   Disp_Numb
	   clr    Hundreds;включение индикаторов 0 знач.
       clr    Tens
       clr    Ones
	   ldi    Number,0;0-й канал
	   ldi    Disp_Count,Val_dispCount
       sei	   
; 
;;==================================================
;начало цикла программы
;==================================================
Start:    rcall  start_ADC
;
wait_ADC: rcall  Display
          sbrs   byte_fl,F_end_ADC
          rjmp   wait_ADC
		  rcall  out_ADC
          sbrc   Byte_fl,Disab_Key;
          rjmp   Start;   wait_ADC
          sbis   PinD,3;Проверка нажатия кнопки
          rcall  izm_Nkan;;по нажатию кнопки инвертировать флаг изменения канала
          rjmp   Start;   wait_ADC
;==================================================	   
; конец цикла программы	   
;==================================================
; Подпрограмма смены канала преобразования
;==================================================
izm_Nkan:   
			set
	   		bld    Byte_fl,Disab_Key; бит запрещ. опроса кнопки "Выбор канала" от дребезга
			
			clt
            sbrs  byte_fl,F_iz_kan
		    set
            bld   byte_fl,F_iz_kan
;изменить № канала АЦП
            in     temp_L,ADMUX
            andi   temp_L,0b11100000
ch_mux_ADC: sbrs  byte_fl,F_iz_kan
            rjmp  kanN2
			ldi   Number,3;3-й канал 
            ori   temp_L,(1<<MUX0)|(1<<MUX1)
ex_c_mux:	out   ADMUX,temp_L
            ldi   temp_L,(1<<CS02)|(1<<CS00);частота TCNT0 Clk/1024,(CS02,CS01,CS00) - 101
            out   TCCR0,temp_L
	        ldi   temp_L,(1<<TOIE0);TOIE0-Timer/Counter0 Overflow Interrupt Enable
	        out    TIMSK,temp_L; разрешить прерывание Tov0
            ret
;---------------
kanN2:      ldi   Number,0;0-й канал 
            rjmp  ex_c_mux
;**************************************************
; Подпрограмма запуска преобразования АЦП
;**************************************************
start_ADC:  ldi   temp_L,(1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1);ч-та преобр.64(125кГц)
			out   ADCSR,temp_L
            ldi   temp_L,(1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADSC);
			out   ADCSR,temp_L
			ret 
;**************************************************
;Подпрограмма out_ADC изменение данных выводимых на дисплей
;**************************************************
;данные с АЦП усредняются путем суммирования (Val_N_ADC=1,2,4,8.16) раз и нахождения
;среднего значения, используя для деления сдвиг вправо
;измеренное значение Vin=(ADC*2,54)/1024=ADC/400. Используем только целые числа для
;вывода на дисплей, т.е. Vin*100. таким образом измеренное значение равно ADC/4
;увеличение в 100 раз при выводе на дисплей компенсируем выводом точки у первой
; зн.цифры
;кол-во сдвигов вправо для нах-я средн.значения
out_ADC:    ldi    temp_L,Val_N_ADC;
            cpi    temp_L,8; 8 накоплений
			brne   ch_4izm
			ldi    temp_L,3
			rjmp   sh_ADC
ch_4izm:    cpi    temp_L,4; 4 накоплений
			brne   ch_2izm
            ldi    temp_L,2
			rjmp   sh_ADC
ch_2izm:    cpi    temp_L,2; 2 накоплений
			brne   ch_1izm 
			ldi    temp_L,1
			rjmp   sh_ADC  
ch_1izm:    cpi    temp_L,1
			breq   norm_ADC  
            rjmp   ex_out 
sh_ADC:		lsr    ADC_h 		   
            ror    ADC_l
		    dec    temp_L
		    cpi    temp_L,0x00
		    brne   sh_ADC;в ADC_h,ADC_l среднее значение
;
norm_ADC:   lsr    ADC_h 		   
            ror    ADC_l
			;lsr    ADC_h 		   
            ;ror    ADC_l; в ADC_l значение,увеличенное в 100 раз
;
            mov    temp_L,ADC_l
			mov    temp_H,ADC_h
            clr    ADC_h
       		clr    ADC_l
			rcall  digitConvert
			clt
			bld    byte_fl,F_end_ADC
ex_out:     ret
;**************************************************
; Подпрограмма Display работы с дисплеем (динам. индикация)
;**************************************************  
Display:   dec   Disp_Count
           brne  ex_displ
;
           ldi   Disp_Count,Val_dispCount
;           
		   inc   Disp_Numb
		   cpi   Disp_Numb,4
		   brne  Out_disp
		   clr   Disp_Numb

;
Out_disp:  
           ldi   ZL,18;     ;указатель на Number
		   ldi   ZH,00
           add   ZL,Disp_Numb
		   ld    temp_L,Z
		   cpi   Disp_Numb,1;позиция Hundreds
		   breq  sym_toch
;                           преобразуем в семисегментный код
           ldi   ZL,low(TABLE*2);загружаем адрес начала 
	       ldi   ZH,high(TABLE*2);таблицы в памяти программ (*2 - для байтовой 
out_date:  add   ZL,temp_L   ;адресации)
	       lpm   temp_L,Z    ;читаем семисегментный код значения ; 
		   out   PortC,temp_L; передаем на индикатор
;
           in    temp_L,PINB
		   lsr   temp_L
		   brcc  PC+2
		   ldi   temp_L,0b00001000; в начало (Number)	   
           out   PORTB,temp_L
		   ;
ex_displ:  ret
;________________________________
sym_toch:  ldi   ZL,low(TABLE1*2);загружаем адрес начала 
	       ldi   ZH,high(TABLE1*2);таблицы в памяти программ (*2 - для байтовой адрес.
           rjmp  out_date
;==================================================
;------- Таблица перекодировки символов
TABLE:    .db   0b00111111,0b00000110; коды "0","1"
          .db   0b01011011,0b01001111; коды "2","3"
          .db   0b01100110,0b01101101;;коды "4","5"
		  .db   0b01111101,0b00000111;;коды "6","7"
		  .db   0b01111111,0b01101111;;коды "8","9" 
;==================================================
;------- Таблица перекодировки символов c точкой, отделяющей целые числа от дробных
TABLE1:   .db   0b10111111,0b10000110; коды "0","1"
          .db   0b11011011,0b11001111; коды "2","3"
          .db   0b11100110,0b11101101;;коды "4","5"
		  .db   0b11111101,0b10000111;;коды "6","7"
		  .db   0b11111111,0b11101111;;коды "8","9" 
;==================================================
;****************************************************
;Конвертирует двоичное 1-e байтное число в двоично-десятичный код 
;===================================================
digitConvert:
            clr   Hundreds
			clr   Tens  
			clr   Ones
;
FindHundreds:
            subi  temp_L,100
			sbci  temp_H,0;
			brcs  FindTens
            inc   Hundreds
			rjmp  FindHundreds
;
FindTens: 
            subi  temp_L,-100
            subi  temp_L,10
            brcs  FindOnes
            inc   Tens 
			rjmp  FindTens+1
;
FindOnes:
            subi  temp_L,-10
            mov   Ones,temp_L
            ret
;*******************************************
;Subroutine interrupt ADC
;***********************************
IN_ADC:    push   temp_L
           push   temp_H
           in     temp_L,SREG
		   push   temp_L
;            
rd_ADC:	   in     temp_L,ADCL
		   in     temp_H,ADCH
		   add    ADC_l,temp_L
		   adc    ADC_h,temp_H 
           inc    cou_ADC
           cpi    cou_ADC,Val_N_ADC;колич-во преобразований АЦП
           breq   end_ADC
           ldi   temp_L,(1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADSC);;start convers.
           out    ADCSR,temp_L
ex_INADC:  pop    temp_L         
           out    SREG,temp_L
		   pop    temp_H
		   pop    temp_L
           reti
;-------------------------
end_ADC:   clr    cou_ADC
           set
		   bld    byte_fl,F_end_ADC
		   rjmp   ex_INADC
;*******************************************
;Subroutine interrupt Overflow 0  
;Подпрограмма обработки прерывания переполнения таймера Т0
;Т0 - 8 разр таймер. Counter0 оverflow соотвествуетвремени 256*1024/8000000=0,033с
;за 1cек =(1024/8000000)*256*N_отсчетов(переполнений)=30 переполнений
;(предотвращение срабатываний от дребезга контактов кнопки "Просмотр")
;*********************************************
time_d_k:  push   temp_L
           in     temp_L,SREG
		   push   temp_L 
;            
           inc    Time
		   cpi    Time,VAL_time 
		   brne   ex_timDK
		   clt
		   bld    Byte_fl,Disab_Key; бит разр. опроса кнопки "Просмотр" от дребезга
	       ldi    temp_L,0x00;(1<<CS02)|(1<<CS00);No clock source,(CS02,CS01,CS00) - 000
           out    TCCR0,temp_L
	       in     temp_L,TIMSK
	       clt
	       bld    temp_L,TOIE0 ;TOIE0-Timer/Counter0 Overflow Interrupt Enable
	       out    TIMSK,temp_L; запрещение прерывание Tov0
		   clr    Time
;
ex_timDK:  pop    temp_L         
           out    SREG,temp_L
		   pop    temp_L
           reti
;***********************************
