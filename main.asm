;
; LM35 con displays en ensamblador.asm
;
; Created: 29/01/2019 11:52:55 a. m.
; Author : dx_ch
;

.INCLUDE "m32def.inc"

.DEF REG=R16
.DEF REG2=R17
.DEF CIF1=R18
.DEF CIF2=R19
.DEF MULTREG=R20
.DEF VZORREG=R21

.EQU SMER=DDRD
.EQU PORT=PORTD
.EQU SMER2=DDRC
.EQU PORT2=PORTC
.EQU SMER3=DDRB
.EQU PORT3=PORTB

.CSEG
.ORG 0
RJMP START

;Vectores de interrupcion
.ORG OC2addr	;interrumpido por el contador 2, subidas multiplex, frecuencia de actualización
RJMP MULTIPLEX

.ORG ADCCaddr	;interrumpir al completar conversiones AD
RJMP HOTOVO


START:
;establece puerto D como salida
LDI REG,0xFF
OUT SMER,REG
LDI REG,0xFF
OUT PORT,REG

;establece el puerto C como entrada, activa las resistencias pullup PC 4 y 5
LDI REG,0x00		;0b00000000
OUT SMER2,REG
LDI REG,0x30		;0b00110000
OUT PORT2,REG

;establece el puerto B como salida
LDI REG,0xFF
OUT SMER3,REG
LDI REG,0xFF
OUT PORT3,REG


LDI REG,LOW(RAMEND)	;Inicia el stack pointer
OUT SPL,REG
LDI REG,HIGH(RAMEND)
OUT SPH,REG	


LDI MULTREG,1		;prestablece un registro de estado para multiplexar


;AJUSTES DE INTERRUPCIÓN
LDI	REG,0x0D		;0b00001101 	; Restablecer valores en comparación con ...
OUT TCCR2,REG    	; (llamado CTC), OC0 no se ocupa. prescalador de 128
LDI	REG,38	      	; establecer el valor a comparar (dividido por n + 1)
OUT	OCR2,REG     	; 

LDI	REG,0x80		;0b10000000	; liberar CTC OCIE2
OUT	TIMSK,REG    	; 


;AJUSTE ADC MCU
LDI	REG,0xE0		;0b11100000	; 2.56V como referencia, a la derecha, seleccione la entrada ADC0
OUT	ADMUX,REG    	 

LDI	REG,0x8b		;0b10001011	; ADC habilitado, una vez, prescalador permitido,  
OUT	ADCSRA,REG    	; dividir 8 (de 1MHz a 125kHz.)

LDI	REG,0x90		;0b10010000	;deja dormir y establece el modo
OUT	MCUCR,REG


SEI ;se habilitan interrupciones globales

;Apaga el analógico. comparador - nunca usar (energía setri)
LDI	REG,0x80;0b10000000	
OUT	ACSR,REG  

;lazo infinito
SMYCKA:
RJMP SMYCKA


ZMERIT:		;Al ingresar al modo de suspensión de reducción de ruido ADC, se activa la conversión ADC
SEI
SLEEP	
RET


HOTOVO:			;desconectar al completar conversiones AD
IN REG,ADCH

LDI CIF1,0
LDI CIF2,0

CPI REG,100		;una condición mayor o igual a 10
BRSH NAD99		;cuando la cifra 3 = 10 está fuera de rango

ZNOVU10:
CPI REG,10		;una condición mayor o igual a 10
BRLO POD10
SUBI REG,10		;restando el número 10 del resultado
INC CIF2
RJMP ZNOVU10
POD10:

MOV CIF1,REG

RJMP DO99

NAD99:			;¿Qué pasa si el resultado es más de 999?

LDI CIF1,255	;Aparece el ajuste de cifras fuera de 0-9 "-"
LDI CIF2,255

DO99:
RETI


MULTIPLEX:
RCALL MULT
DEC MULTREG
BRNE MULTHOP
LDI MULTREG,2

DEC VZORREG
BRNE MULTHOP
LDI VZORREG,50		;muestreo f = 100 / n
RCALL ZMERIT
MULTHOP:
RETI


MULT:				;multiplexacion
LDI REG,0x00		;0b00000000
OUT PORT3,REG

CPI MULTREG,1
BREQ MULT1
CPI MULTREG,2
BREQ MULT2


MULT1:
MOV REG,CIF1
RCALL Displays
OUT PORT,REG
LDI REG,0x01		;0b00000001
OUT PORT3,REG
RET

MULT2:
MOV REG,CIF2
RCALL Displays
OUT PORT,REG
LDI REG,0x02		;0b00000010
OUT PORT3,REG
RET


Displays:	;Subrutina para displays

CPI REG,0			;Digito 0
BREQ Display0
CPI REG,1			;Digito 1
BREQ Display1
CPI REG,2			;Digito 2
BREQ Display2
CPI REG,3			;Digito 3
BREQ Display3
CPI REG,4			;Digito 4
BREQ Display4
CPI REG,5			;Digito 5
BREQ Display5
CPI REG,6			;Digito 6
BREQ Display6
CPI REG,7			;Digito 7
BREQ Display7
CPI REG,8			;Digito 8
BREQ Display8
CPI REG,9			;Digito 9
BREQ Display9

LDI REG,0xbf		;0b10111111	
RET

Display0:
LDI REG,0xC0		;0b11000000	;Carga registro al valor en ánodo comun del digito 0
RET

Display1:
LDI REG,0xF9		;0b11111001	;Carga registro al valor en ánodo comun del digito 1
RET

Display2:
LDI REG,0xA4		;0b10100100	;Carga registro al valor en ánodo comun del digito 2
RET

Display3:
LDI REG,0xB0		;0b10110000	;Carga registro al valor en ánodo comun del digito 3
RET

Display4:
LDI REG,0x99		;0b10011001	;Carga registro al valor en ánodo comun del digito 4
RET

Display5:	
LDI REG,0x92		;0b10010010	;Carga registro al valor en ánodo comun del digito 5
RET

Display6:
LDI REG,0x82		;0b10000010	;Carga registro al valor en ánodo comun del digito 6
RET

Display7:
LDI REG,0xF8		;0b11111000	;Carga registro al valor en ánodo comun del digito 7
RET

Display8:
LDI REG,0x80		;0b10000000	;Carga registro al valor en ánodo comun del digito 8
RET

Display9:
LDI REG,0x90		;0b10010000	;Carga registro al valor en ánodo comun del digito 9
RET