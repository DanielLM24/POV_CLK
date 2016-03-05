;Universidad del Valle de Guatemala
;Microcontroladores Aplicados a la Industria
;Sección 21
;Daniel Lara Moir
;13424
;Reloj.asm   
;Programa para reloj en formato 24h HH:MM:SS.	
	
list      p=16F84A            ; list directive to define processor
#include <p16F84A.inc>        ; processor specific variable definitions

__CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _HS_OSC
    
;***************VARIABLE DEFINITION*********************************************
UDATA_SHR 0x0C
w_temp		EQU	0x20		; variable used for context saving
w_temp1		EQU	0xA0		; reserve bank1 equivalent of w_temp 
status_temp	EQU	0x21		; variable used for context saving
pclath_temp	EQU	0x22		; variable used for context saving
delay_counter	res 1			; For one second delay.
delay_counter_1 res 1			
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
column_counter	res 1
column_index	res 1
stripe_1	res 1
stripe_2	res 1
stripe_3	res 1
stripe_4	res 1
space_stripe	res 1
msb		res 1
xor_var		res 1
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
	MOVLW .248		  ; Pre-load TMR0
	MOVWF TMR0
	
    COLUMN_COUNTER_CONTROL:
	    MOVF column_counter, 0
	    SUBLW .5
	    BTFSS STATUS, Z
	    GOTO COUNTER_INCREMENT
	    GOTO COUNTER_RESET
	    COUNTER_INCREMENT:
		INCF column_counter, 1
		GOTO COLUMN_INDEX_CONTROL
	    COUNTER_RESET:
		MOVLW .1
		MOVWF column_counter
		
	COLUMN_INDEX_CONTROL:
	    MOVF column_index, 0
	    SUBLW .60
	    BTFSS STATUS, Z
	    GOTO INDEX_INCREMENT
	    GOTO INDEX_RESET
	    INDEX_INCREMENT:
		INCF column_index, 1
		GOTO SECONDS_CONTROL
	    INDEX_RESET:
		MOVLW .1
		MOVWF column_index

	SECONDS_CONTROL:
	DECFSZ delay_counter, 1	  ; 1 second has passed.
	GOTO POP
	
	MOVLW .200		    ; For 1 second delay.
	MOVWF delay_counter
	DECFSZ delay_counter_1, 1
	GOTO POP
	
	MOVLW .5
	MOVWF delay_counter_1
	GOTO SECONDS_INCREMENT
	
    RBI:
	BTFSS INTCON, RBIF	    ; Interrupt not caused by button press.
	GOTO POP
	BCF INTCON, RBIF	    ; Interrupt flag clear.
	CHECK_MODE:
	    BTFSC PORTB, RB6
	    GOTO CHECK_ALARM_STATE
	    BTFSC alarm_status, 0	    ; Check clock mode (Alarm Set/Run)		
	    GOTO alarm_setting	
	    BSF alarm_status, 0		    ; Enable alarm setting.
	    GOTO POP
	    alarm_setting:
            BCF alarm_status, 0		    ; Enable run mode.
	    GOTO POP
	
	CHECK_ALARM_STATE:
	    BTFSC PORTB, RB7	    
	    GOTO CHECK_MINUTES_INC
	    BTFSC alarm_status, 1   ; Check alarm status (ON/OFF)		
	    GOTO alarm_on	
	    BSF alarm_status, 1	    ; Enable alarm.
	    GOTO POP
	    alarm_on:
            BCF alarm_status, 1	    ; Disable alarm.
	    GOTO POP
	    
	CHECK_MINUTES_INC:
	    BTFSS PORTB, RB4
	    GOTO MINUTES_INCREMENT
	CHECK_HOURS_INC:  
	    BTFSS PORTB, RB5
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
	    BTFSC alarm_status, 0
	    GOTO MINUTES_INCREMENT_ALARM
	    INCF minutes, f			; Circular increment of minutes.	
	    MOVF minutes, 0
	    SUBLW .60
	    BTFSS STATUS, Z
	    GOTO POP
	    MOVLW .0
	    MOVWF minutes
	    GOTO HOURS_INCREMENT
	    MINUTES_INCREMENT_ALARM:
		INCF alarm_minutes, f			; Circular increment of alarm minutes.	
		MOVF alarm_minutes, 0
		SUBLW .60
		BTFSS STATUS, Z
		GOTO POP
		MOVLW .0
		MOVWF alarm_minutes
		GOTO POP
	HOURS_DISPLAY:
	 ;   BTFSC PORTA, 2
	  ;  GOTO hour_hand_on
	   ; BSF PORTA, 2
	    ;GOTO HOURS_INCREMENT
	    ;hour_hand_on:
	;	BCF PORTA, 2
	
	HOURS_INCREMENT:
	    BTFSC alarm_status, 0
	    GOTO HOURS_INCREMENT_ALARM
	    INCF hours, f			; Circular increment of hours.
	    MOVF hours, 0
	    SUBLW .24
	    BTFSS STATUS, Z
	    GOTO POP
	    MOVLW .0
	    MOVWF hours
	    GOTO POP
	    HOURS_INCREMENT_ALARM:
		INCF alarm_hours, f			; Circular increment of alarm hours.
		MOVF alarm_hours, 0
		SUBLW .24
		BTFSS STATUS, Z
		GOTO POP
		MOVLW .0
		MOVWF alarm_hours
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
    CLRF TRISB
    CLRF TRISA
    MOVLW b'10100000'		; Enables interrupts from TMR0 an RB (IOC).
    MOVWF INTCON
	    
    BCF OPTION_REG, T0CS        ; TMR0 CLOCK SOURCE: INTERNAL INSTRUCTION CYCLE CLOCK
    BCF OPTION_REG, PSA         ; PRESCALER ASSIGNMENT: TIMER0 MODULE
    BSF OPTION_REG, PS2         ; PRESCALER RATE: 1:256
    BSF OPTION_REG, PS1         ; PRESCALER RATE: 1:256
    BSF OPTION_REG, PS0         ; PRESCALER RATE: 1:256

    BCF STATUS, RP0             ; bank select 1	
    CLRF PORTA			
    CLRF PORTB
    
    MOVLW .200			; For TMR0 delay of 1000ms 
    MOVWF delay_counter
    MOVLW .5
    MOVWF delay_counter_1
    
    MOVLW .15			; Initial time.
    MOVWF seconds
    MOVWF minutes
    MOVWF hours
    
    MOVLW .1
    MOVWF column_counter
    MOVWF column_index
    
    CLRF xor_var
    CLRF stripe_1
    CLRF stripe_2
    CLRF stripe_3
    CLRF stripe_4
    CLRF space_stripe
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
    ;CALL CHECK_ALARM
    
   CHECK_HOURS_T:
   MOVF column_index, 0
   SUBLW .4
   BTFSC STATUS, C
   CALL display_hours_t
   
   MOVF column_index, 0
   SUBLW .5
   BTFSS STATUS, Z
   GOTO CHECK_HOURS_U
   CLRF PORTA
   CLRF PORTB 
   GOTO EXIT
   
   ;INDEX=5
   ;	clrf porta
   ;	CLRF PORTB
   ;	GOTO EXIT
   
   CHECK_HOURS_U:
   MOVF column_index, 0
   SUBLW .9
   BTFSC STATUS, C
   GOTO SMALLER_EQUAL_9
   GOTO EMPTY_SPACE_2
   SMALLER_EQUAL_9:
   MOVF column_index, 0
   SUBLW .6
   BTFSC STATUS, C
   GOTO EQUAL_6
   CALL display_hours_u
   GOTO EMPTY_SPACE_2
   EQUAL_6:
   MOVF column_index, 0
   SUBLW .6
   BTFSS STATUS, Z
   GOTO EMPTY_SPACE_2
   CALL display_hours_u
   
   
   EMPTY_SPACE_2:   
   MOVF column_index, 0
   SUBLW .10
   BTFSS STATUS, Z
   GOTO CHECK_MINUTES_T
   CLRF PORTA
   CLRF PORTB 
   GOTO EXIT
   
   CHECK_MINUTES_T:
    MOVF column_index, 0
    SUBLW .14
    BTFSC STATUS, C
    GOTO SMALLER_EQUAL_14
    GOTO EMPTY_SPACE_3
   SMALLER_EQUAL_14:
    MOVF column_index, 0
    SUBLW .11
    BTFSC STATUS, C
    GOTO EQUAL_11
    CALL display_minutes_t
    GOTO EMPTY_SPACE_3
   EQUAL_11:
    MOVF column_index, 0
    SUBLW .11
    BTFSS STATUS, Z
    GOTO EMPTY_SPACE_3
    CALL display_minutes_t
   
   EMPTY_SPACE_3:
   MOVF column_index, 0
   SUBLW .15
   BTFSS STATUS, Z
   GOTO CHECK_MINUTES_U
   CLRF PORTA
   CLRF PORTB 
   GOTO EXIT
   
   CHECK_MINUTES_U:
    MOVF column_index, 0
    SUBLW .19
    BTFSC STATUS, C
    GOTO SMALLER_EQUAL_19
    GOTO EMPTY_SPACE_4
   SMALLER_EQUAL_19:
    MOVF column_index, 0
    SUBLW .16
    BTFSC STATUS, C
    GOTO EQUAL_16
    CALL display_minutes_u
    GOTO EMPTY_SPACE_4
   EQUAL_16:
    MOVF column_index, 0
    SUBLW .16
    BTFSS STATUS, Z
    GOTO EMPTY_SPACE_4
    CALL display_minutes_u
   
   EMPTY_SPACE_4:
   MOVF column_index, 0
   SUBLW .20
   BTFSS STATUS, Z
   GOTO CHECK_SECONDS_T
   CLRF PORTA
   CLRF PORTB 
   GOTO EXIT
   
   CHECK_SECONDS_T:
    MOVF column_index, 0
    SUBLW .24
    BTFSC STATUS, C
    GOTO SMALLER_EQUAL_24
    GOTO EMPTY_SPACE_5
   SMALLER_EQUAL_24:
    MOVF column_index, 0
    SUBLW .21
    BTFSC STATUS, C
    GOTO EQUAL_21
    CALL display_seconds_t
    GOTO EMPTY_SPACE_5
   EQUAL_21:
    MOVF column_index, 0
    SUBLW .21
    BTFSS STATUS, Z
    GOTO EMPTY_SPACE_5
    CALL display_seconds_t
    
   EMPTY_SPACE_5:
   MOVF column_index, 0
   SUBLW .25
   BTFSS STATUS, Z
   GOTO CHECK_SECONDS_U
   CLRF PORTA
   CLRF PORTB 
   GOTO EXIT
   
   CHECK_SECONDS_U:
    MOVF column_index, 0
    SUBLW .29
    BTFSC STATUS, C
    GOTO SMALLER_EQUAL_29
    GOTO EMPTY_SPACE_6
   SMALLER_EQUAL_29:
    MOVF column_index, 0
    SUBLW .26
    BTFSC STATUS, C
    GOTO EQUAL_26
    CALL display_seconds_u
    GOTO EMPTY_SPACE_6
   EQUAL_26:
    MOVF column_index, 0
    SUBLW .26
    BTFSS STATUS, Z
    GOTO EMPTY_SPACE_6
    CALL display_seconds_u
   
   EMPTY_SPACE_6:
   MOVF column_index, 0
   SUBLW .30
   BTFSS STATUS, Z
   GOTO HALF_OFF
   CLRF PORTA
   CLRF PORTB 
   GOTO EXIT
   
   HALF_OFF:
    CLRF PORTA
    CLRF PORTB

EXIT:
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

display_hours_t:
    MOVF hours_t, 0
    MOVWF xor_var
    CALL SWITCHCASE
    MOVF column_counter, 0
    SUBLW .1
    BTFSS STATUS, Z
    GOTO hours_t_2
    hours_t_1:
	MOVF stripe_1, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_1, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    hours_t_2:
	MOVF column_counter, 0
	SUBLW .2
	BTFSS STATUS, Z
	GOTO hours_t_3
    	MOVF stripe_2, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_2, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    hours_t_3:
	MOVF column_counter, 0
	SUBLW .3
	BTFSS STATUS, Z
	GOTO hours_t_4
	MOVF stripe_3, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_3, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
	RETURN
    hours_t_4:
	MOVF column_counter, 0
	SUBLW .4
	BTFSS STATUS, Z
	RETURN
	MOVF stripe_4, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_4, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
RETURN

display_hours_u:
    MOVF hours_u, 0
    MOVWF xor_var
    CALL SWITCHCASE
    MOVF column_counter, 0
    SUBLW .1
    BTFSS STATUS, Z
    GOTO hours_u_2
    hours_u_1:
	MOVF stripe_1, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_1, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    hours_u_2:
	MOVF column_counter, 0
	SUBLW .2
	BTFSS STATUS, Z
	GOTO hours_u_3
    	MOVF stripe_2, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_2, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    hours_u_3:
	MOVF column_counter, 0
	SUBLW .3
	BTFSS STATUS, Z
	GOTO hours_u_4
	MOVF stripe_3, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_3, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
	RETURN
    hours_u_4:
	MOVF column_counter, 0
	SUBLW .4
	BTFSS STATUS, Z
	RETURN
	MOVF stripe_4, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_4, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
RETURN
	
display_minutes_t:
    MOVF minutes_t, 0
    MOVWF xor_var
    CALL SWITCHCASE   
    MOVF column_counter, 0
    SUBLW .1
    BTFSS STATUS, Z
    GOTO minutes_t_2
    minutes_t_1:
	MOVF stripe_1, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_1, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    minutes_t_2:
	MOVF column_counter, 0
	SUBLW .2
	BTFSS STATUS, Z
	GOTO minutes_t_3
    	MOVF stripe_2, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_2, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    minutes_t_3:
	MOVF column_counter, 0
	SUBLW .3
	BTFSS STATUS, Z
	GOTO minutes_t_4
	MOVF stripe_3, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_3, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
	RETURN
    minutes_t_4:
	MOVF column_counter, 0
	SUBLW .4
	BTFSS STATUS, Z
	RETURN
	MOVF stripe_4, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_4, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
RETURN

display_minutes_u:
    MOVF minutes_u, 0
    MOVWF xor_var
    CALL SWITCHCASE
    MOVF column_counter, 0
    SUBLW .1
    BTFSS STATUS, Z
    GOTO minutes_u_2
    minutes_u_1:
	MOVF stripe_1, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_1, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    minutes_u_2:
	MOVF column_counter, 0
	SUBLW .2
	BTFSS STATUS, Z
	GOTO minutes_u_3
    	MOVF stripe_2, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_2, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    minutes_u_3:
	MOVF column_counter, 0
	SUBLW .3
	BTFSS STATUS, Z
	GOTO minutes_u_4
	MOVF stripe_3, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_3, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
	RETURN
    minutes_u_4:
	MOVF column_counter, 0
	SUBLW .4
	BTFSS STATUS, Z
	RETURN
	MOVF stripe_4, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_4, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
RETURN
	
display_seconds_t:
    MOVF seconds_t, 0
    MOVWF xor_var
    CALL SWITCHCASE
    MOVF column_counter, 0
    SUBLW .1
    BTFSS STATUS, Z
    GOTO seconds_t_2
    seconds_t_1:
	MOVF stripe_1, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_1, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    seconds_t_2:
	MOVF column_counter, 0
	SUBLW .2
	BTFSS STATUS, Z
	GOTO seconds_t_3
    	MOVF stripe_2, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_2, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    seconds_t_3:
	MOVF column_counter, 0
	SUBLW .3
	BTFSS STATUS, Z
	GOTO seconds_t_4
	MOVF stripe_3, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_3, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
	RETURN
    seconds_t_4:
	MOVF column_counter, 0
	SUBLW .4
	BTFSS STATUS, Z
	RETURN
	MOVF stripe_4, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_4, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
RETURN

display_seconds_u:
    MOVF seconds_u, 0
    MOVWF xor_var
    CALL SWITCHCASE
    MOVF column_counter, 0
    SUBLW .1
    BTFSS STATUS, Z
    GOTO seconds_u_2
    seconds_u_1:
	MOVF stripe_1, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_1, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    seconds_u_2:
	MOVF column_counter, 0
	SUBLW .2
	BTFSS STATUS, Z
	GOTO seconds_u_3
    	MOVF stripe_2, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_2, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB	
	RETURN
    seconds_u_3:
	MOVF column_counter, 0
	SUBLW .3
	BTFSS STATUS, Z
	GOTO seconds_u_4
	MOVF stripe_3, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_3, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
	RETURN
    seconds_u_4:
	MOVF column_counter, 0
	SUBLW .4
	BTFSS STATUS, Z
	RETURN
	MOVF stripe_4, 0
	ANDLW b'00001111'
	MOVWF PORTA
	MOVF stripe_4, 0
	ANDLW b'11110000'
	MOVWF msb
	SWAPF msb, 0
	MOVWF PORTB
RETURN
	
ZERO:
    MOVLW .255
    MOVWF stripe_1
    MOVWF stripe_4
    MOVLW b'10000001'
    MOVWF stripe_2
    MOVWF stripe_3
    RETURN
    
ONE:
    CLRF stripe_1
    CLRF stripe_2
    CLRF stripe_3
    MOVLW .255
    MOVWF stripe_4
    RETURN
    
TWO:
    MOVLW b'01000011'
    MOVWF stripe_1
    MOVLW b'10000101'
    MOVWF stripe_2
    MOVLW b'10001001'
    MOVWF stripe_3
    MOVLW b'01110001'
    MOVWF stripe_4
    RETURN
    
THREE:
    MOVLW b'01000010'
    MOVWF stripe_1
    MOVLW b'10000001'
    MOVWF stripe_2
    MOVLW b'10010001'
    MOVWF stripe_3
    MOVLW b'01101110'
    MOVWF stripe_4
    RETURN

FOUR:
    MOVLW b'11111000'
    MOVWF stripe_1
    MOVLW b'00001000'
    MOVWF stripe_2
    MOVLW b'00111111'
    MOVWF stripe_3
    MOVLW b'00001000'
    MOVWF stripe_4
    RETURN
    
FIVE:
    MOVLW b'11111010'
    MOVWF stripe_1
    MOVLW b'10010001'
    MOVWF stripe_2
    MOVLW b'10010001'
    MOVWF stripe_3
    MOVLW b'10001110'
    MOVWF stripe_4
    RETURN

SIX:
    MOVLW b'00011110'
    MOVWF stripe_1
    MOVLW b'00110001'
    MOVWF stripe_2
    MOVLW b'01010001'
    MOVWF stripe_3
    MOVLW b'10001110'
    MOVWF stripe_4
    RETURN
    
SEVEN:
    MOVLW b'10000000'
    MOVWF stripe_1
    MOVLW b'10010000'
    MOVWF stripe_2
    MOVWF stripe_3
    MOVLW b'11111111'
    MOVWF stripe_4
    RETURN
    
EIGHT:
    MOVLW b'01100110'
    MOVWF stripe_4
    MOVWF stripe_1
    MOVLW b'10011001'
    MOVWF stripe_2
    MOVWF stripe_3
    RETURN
 
NINE:
    MOVLW b'01110001'
    MOVWF stripe_1
    MOVLW b'10001001'
    MOVWF stripe_2
    MOVWF stripe_3
    MOVLW b'01010111'
    MOVWF stripe_4
    RETURN

SWITCHCASE:		; Case implementation for display value assignment.
    MOVF xor_var,0
    XORLW .0		; Zero will result if W=L.
    BTFSC STATUS, Z
    GOTO CASE_ZERO
    MOVF xor_var,0
    XORLW .1		; Zero will result if W=L.
    BTFSC STATUS, Z
    GOTO CASE_ONE
    MOVF xor_var,0
    XORLW .2		; Zero will result if W=L.
    BTFSC STATUS, Z
    GOTO CASE_TWO
    MOVF xor_var,0
    XORLW .3		; Zero will result if W=L.
    BTFSC STATUS, Z
    GOTO CASE_THREE
    MOVF xor_var,0
    XORLW .4		; Zero will result if W=L.
    BTFSC STATUS, Z
    GOTO CASE_FOUR
    MOVF xor_var,0
    XORLW .5		; Zero will result if W=L.
    BTFSC STATUS, Z
    GOTO CASE_FIVE
    MOVF xor_var,0
    XORLW .6		; Zero will result if W=L.
    BTFSC STATUS, Z
    GOTO CASE_SIX
    MOVF xor_var,0
    XORLW .7		; Zero will result if W=L.
    BTFSC STATUS, Z
    GOTO CASE_SEVEN
    MOVF xor_var,0
    XORLW .8		; Zero will result if W=L.
    BTFSC STATUS, Z
    GOTO CASE_EIGHT
    MOVF xor_var,0
    XORLW .9		; Zero will result if W=L.
    BTFSC STATUS, Z
    GOTO CASE_NINE
    GOTO DEFAULT  
    
   CASE_ZERO:
	CALL ZERO
	RETURN
   CASE_ONE:
	CALL ONE
	RETURN
   CASE_TWO:
	CALL TWO
	RETURN
   CASE_THREE:
	CALL THREE
	RETURN
   CASE_FOUR:
	CALL FOUR
	RETURN
   CASE_FIVE:
	CALL FIVE
	RETURN
   CASE_SIX:
	CALL SIX
	RETURN
   CASE_SEVEN:
	CALL SEVEN
	RETURN
   CASE_EIGHT:
	CALL EIGHT
	RETURN
   CASE_NINE:
	CALL NINE
	RETURN
   DEFAULT:
    RETURN
    
    
CHECK_ALARM:
    BTFSS alarm_status, 1   ;Alarm ON or OFF?
    RETURN
    MOVF minutes, 0
    SUBWF alarm_minutes, 0
    BTFSS STATUS, Z
    RETURN
    MOVF hours, 0
    SUBWF alarm_hours, 0
    BTFSS STATUS, Z
    RETURN
    ;Do something!!
    RETURN
END