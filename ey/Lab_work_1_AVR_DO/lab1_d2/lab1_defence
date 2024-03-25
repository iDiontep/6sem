;*************************************
;* Designer        Ionin D.A..
;* Version:        2.0
;* Date            23.03.2024
;* Title:          Countert.asm
;* Device          ATmega16
;* Clock frequency: 8 MHz Crystal Resonator
;*************************************

.include "m16def.inc"

.def temp = R16
.def Counter = R17

.cseg
.org $0000
rjmp Init

; Initialize Ports
Init:
    ldi temp, 0xFF    ; Set PortA as outputs
    out DDRA, temp
    ldi temp, 0xEF    ; Set PB4 as input
    out DDRB, temp
    
    ldi temp, 0x10    ; Enable pull-up for PB4
    out PORTB, temp
    
    ldi Counter, 0x00 ; Initialize counter

MainLoop:
    sbic PINB, 4       ; Check if button on PB4 is pressed
    rjmp MainLoop      ; Button not pressed, continue loop

    inc Counter        ; Increment counter

    cpi Counter, 0x03  ; Check if counter equals 3
    brne CheckCounter  ; If not 3, continue

    ldi Counter, 0x00  ; Reset counter after reaching 3

CheckCounter:
    ldi temp, Counter  ; Load counter value to temp

    ; Shift the LED pattern to the left based on the counter value
    lsl temp
    out PORTA, temp    ; Output to LEDs

    rcall Delay        ; Delay for debounce

    rjmp MainLoop      ; Continue looping

Delay:
    ldi temp, 0xFF     ; Load delay value
    delay_loop:
        dec temp
        brne delay_loop
    ret

.end
