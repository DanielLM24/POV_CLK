;Universidad del Valle de Guatemala
;Microcontroladores Aplicados a la Industria
;Secci�n 21
;Daniel Lara Moir
;13424
;Reloj.asm   
;Programa para reloj en formato 24h HH:MM:SS.	
	
list      p=16F84A            ; list directive to define processor
#include <p16F84A.inc>        ; processor specific variable definitions

__CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC
    
;***************VARIABLE DEFINITION*********************************************
UDATA_SHR 0x0C
w_temp		EQU	0x20		; variable used for context saving
w_temp1		EQU	0xA0		; reserve bank1 equivalent of w_temp 
status_temp	EQU	0x21		; variable used for context saving
pclath_temp	EQU	0x22		; variable used for context saving
delay_counter	res 1			; For one second delay.
seconds		res 1			; Variables for time storage.
seconds_t	res 1	
seconds_u	res 1
minutes		res 1
minutes_t	res 1
minutes_u	res 1
hours		res 1
hours_t		res 1
hours_u		res 1
alarm_minutes	res 1			; Variables for alarm setting.
alarm_hours	res 1
alarm_status	res 1	
;*******************************************************************************
ORG 0x0000
    NOP
    GOTO SETUP
;*******************************************************************************
ORG 0x0004
    PUSH:
	movwf   w_temp            ; save off current W register contents
	movf    STATUS,w          ; move status register into W register
	bcf     STATUS,RP0        ; ensure file register bank set to 0
	movwf   status_temp       ; save off contents of STATUS register
	movf    PCLATH,w	  ; move pclath register into w register
	movwf   pclath_temp	  ; save off contents of PCLATH register

;********TMR0 INTERRUPTION**************************************************
	BTFSS INTCON, T0IF	  ; Check T0IF.
        GOTO RBI		  ; Exit interrupt vector. 
	BCF INTCON, T0IF
	MOVLW .61		  ; Pre-load TMR0
	MOVWF TMR0
	BSF INTCON, RBIE	

	DECFSZ delay_counter, 1	  ; 1 second has passed.
	GOTO POP
	
	MOVLW .40		    ; For 1 second delay.
	MOVWF delay_counter	
	GOTO SECONDS_INCREMENT
	
    RBI:
	BTFSS INTCON, RBIF	    ; Interrupt not caused by button press.
	GOTO POP
	BCF INTCON, RBIF	    ; Interrupt flag clear.
	
	CHECK_MODE:
	    BTFSS PORTB, RB6
	    GOTO CHECK_ALARM_STATE
	    BTFSC alarm_status, 0	    ; Check clock mode (Alarm Set/Run)		
	    GOTO alarm_setting	
	    BSF alarm_status, 0		    ; Enable alarm setting.
	    GOTO POP
	    alarm_setting:
            BCF alarm_status, 0		    ; Enable run mode.
	    GOTO POP
	
	CHECK_ALARM_STATE:
	    BTFSS PORTB, RB7	    
	    GOTO CHECK_MINUTES_INC
	    BTFSC alarm_status, 1   ; Check alarm status (ON/OFF)		
	    GOTO alarm_on	
	    BSF alarm_status, 1	    ; Enable alarm.
	    GOTO POP
	    alarm_on:
            BCF alarm_status, 1	    ; Disable alarm.
	    GOTO POP
	    
	CHECK_MINUTES_INC:
	    BTFSC PORTB, RB4
	    GOTO MINUTES_INCREMENT
	CHECK_HOURS_INC:  
	    BTFSC PORTB, RB5
	    GOTO HOURS_INCREMENT
	    GOTO POP
	
	   
	    
	
	SECONDS_DISPLAY:
	;    BTFSC PORTA,0		
	 ;   GOTO second_hand_on	
	  ;  BSF PORTA,0			; Apaga el LED
	   ; GOTO SECONDS_INCREMENT
	    ;second_hand_on:
             ;   BCF PORTA,0			; Enciende el LED 
	
	SECONDS_INCREMENT:
	    INCF seconds, f			; Circular increment of seconds.
	    MOVF seconds, 0
	    SUBLW .60
	    BTFSS STATUS, Z
	    GOTO POP
	    MOVLW .0
	    MOVWF seconds

	MINUTES_DISPLAY:
	    ;BTFSC PORTA, 1
	    ;GOTO minute_hand_on
	    ;BSF PORTA, 1
	    ;GOTO MINUTES_INCREMENT
	    ;minute_hand_on:
	;	BCF PORTA, 1
		
	MINUTES_INCREMENT:
	    INCF minutes, f			; Circular increment of minutes.	
	    MOVF minutes, 0
	    SUBLW .60
	    BTFSS STATUS, Z
	    GOTO POP
	    MOVLW .0
	    MOVWF minutes
	
	HOURS_DISPLAY:
	 ;   BTFSC PORTA, 2
	  ;  GOTO hour_hand_on
	   ; BSF PORTA, 2
	    ;GOTO HOURS_INCREMENT
	    ;hour_hand_on:
	;	BCF PORTA, 2
	
	HOURS_INCREMENT:
	    INCF hours, f			; Circular increment of hours.
	    MOVF hours, 0
	    SUBLW .24
	    BTFSS STATUS, Z
	    GOTO POP
	    MOVLW .0
	    MOVWF hours
;*******EXIT INTERRUPT VECTOR***********************************************        
    POP:
	bcf	STATUS,RP0        ; ensure file register bank set to 0
	movf    pclath_temp,w	  ; retrieve copy of PCLATH register
	movwf   PCLATH		  ; restore pre-isr PCLATH register contents
	movf    status_temp,w     ; retrieve copy of STATUS register
	movwf   STATUS            ; restore pre-isr STATUS register contents
	swapf   w_temp,f
        swapf   w_temp,w          ; restore pre-isr W register contents
        RETFIE
;*******************************************************************************
    
SETUP:
    BSF STATUS, RP0             ; Bank select 1
    CLRF TRISA       
    CLRF TRISB       
    MOVLW b'11110000'
    MOVWF TRISB
    CLRF TRISA
    MOVLW b'10101000'		; Enables interrupts from TMR0 an RB (IOC).
    MOVWF INTCON
	    
    BCF OPTION_REG, T0CS        ; TMR0 CLOCK SOURCE: INTERNAL INSTRUCTION CYCLE CLOCK
    BCF OPTION_REG, PSA         ; PRESCALER ASSIGNMENT: TIMER0 MODULE
    BSF OPTION_REG, PS2         ; PRESCALER RATE: 1:256
    BSF OPTION_REG, PS1         ; PRESCALER RATE: 1:256
    BSF OPTION_REG, PS0         ; PRESCALER RATE: 1:256

    BCF STATUS, RP0             ; bank select 1	
    CLRF PORTA			
    CLRF PORTB
    
    MOVLW .40			; For TMR0 delay of 1000ms 
    MOVWF delay_counter
    
    MOVLW .15			; Initial time.
    MOVWF seconds
    MOVWF minutes
    MOVWF hours
    
    CLRF alarm_minutes
    CLRF alarm_hours
    CLRF alarm_status		;To determine whether alarm is ON/OFF or in SET mode.
				;  Bit	|   State   |	Mode
				;   0	|     S	    |	Set
				;	|     C	    |	Run
				;   1	|     S	    |	Alarm ON
				;	|     C	    |	Alarm OFF
MAINPROGRAM:
    CALL SPLIT_SECONDS		; Call to get HH:MM:SS
    CALL SPLIT_MINUTES
    CALL SPLIT_HOURS
    MOVF alarm_status, 0
    MOVWF PORTA
    GOTO MAINPROGRAM		; Unconditional loop.
    
SPLIT_SECONDS:				; Splits digits.
    MOVF seconds, 0	    
    MOVWF seconds_u
    CLRF seconds_t
    SPLIT_SECONDS_LOOP:			; Succesive substraction algorithm.
	MOVLW .10
	SUBWF seconds_u, f
	BTFSC STATUS, Z			; Check for zero in result. 
	GOTO SPLIT_SECONDS_ZERO
	BTFSS STATUS, C			; Check for underflow.
	GOTO SPLIT_SECONDS_BORROW
	INCF seconds_t			; If none of the above -> increment.
	GOTO SPLIT_SECONDS_LOOP		; Loop.
    SPLIT_SECONDS_ZERO:
	INCF seconds_t, f		; Increment and exit.
	RETURN
    SPLIT_SECONDS_BORROW:
	MOVLW .10			; Restore original value and exit.
	ADDWF seconds_u, f
	RETURN

SPLIT_MINUTES:
    MOVF minutes, 0
    MOVWF minutes_u
    CLRF minutes_t
    SPLIT_MINUTES_LOOP:
	MOVLW .10
	SUBWF minutes_u, f
	BTFSC STATUS, Z
	GOTO SPLIT_MINUTES_ZERO
	BTFSS STATUS, C
	GOTO SPLIT_MINUTES_BORROW
	INCF minutes_t
	GOTO SPLIT_MINUTES_LOOP
    SPLIT_MINUTES_ZERO:
	INCF minutes_t, f 
	RETURN
    SPLIT_MINUTES_BORROW:
	MOVLW .10
	ADDWF minutes_u, f
	RETURN
	
SPLIT_HOURS:
    MOVF hours, 0
    MOVWF hours_u
    CLRF hours_t
    SPLIT_HOURS_LOOP:
	MOVLW .10
	SUBWF hours_u, f
	BTFSC STATUS, Z
	GOTO SPLIT_HOURS_ZERO
	BTFSS STATUS, C
	GOTO SPLIT_HOURS_BORROW
	INCF hours_t
	GOTO SPLIT_HOURS_LOOP
    SPLIT_HOURS_ZERO:
	INCF hours_t, f 
	RETURN
    SPLIT_HOURS_BORROW:
	MOVLW .10
	ADDWF hours_u, f
	RETURN
	
END