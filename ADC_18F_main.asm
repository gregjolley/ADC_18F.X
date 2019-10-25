;*******************************************************************************
;   PIC18F ADC library routines. Extended instruction set.
;   Date:	    2/10/19
;   File Version:   1.1
;   Files required: 
;   Author:	    Greg Jolley
;
;   Device compatibility: PIC18F47J13
;*******************************************************************************


    #include <p18cxxx.inc>	    ; processor specific variable definitions
    
    global  ADC_read, ADC_wait_read, ADC_go_read, ADC_channel_sel
    global  ADC_channel_sel_go, ADC_channel_sel_go_read, ADC_calibrate
    
	CODE
		
; Selects analog channel number, initiates a conversion and returns result	
; [0] input the channel number 
; D'0' -> D'15': AN0,...,AN12, reserved, Vddcore, Vbg (1.2 V)
; [1] returns Low Byte
; [2] returns High Byte	
; Assumes that the ADC is turned on and appropriately configured. 
;-------------------------------------------; 
ADC_channel_sel_go_read:		    ; 
	movf	[D'0'], W		    ;
	andlw	B'00001111'		    ; Permit only valid channels and 
	movwf	[D'1']			    ; do not alter other register bits
	rlncf	[D'1'], F		    ;
	rlncf	[D'1'], F		    ;    
					    ;
	movf	ADCON0, W, A		    ;
	andlw	B'11000011'		    ; 
	iorwf	[D'1'], W		    ;
					    ;   
ADC_channel_sel_go_read_1		    ;
	btfsc	ADCON0, GO, A		    ;    
	bra	ADC_channel_sel_go_read_1   ; wait for ADC free
					    ;
	movwf	ADCON0, A		    ; load the channel number
	bsf	ADCON0, GO, A		    ;
channel_sel_and_go_read_2		    ;
	nop				    ;
	btfsc	ADCON0, GO, A		    ;
	bra	channel_sel_and_go_read_2   ; wait for conversion completion 
	movf	ADRESL, W, A		    ;
	movwf	[D'1']			    ;
	movf	ADRESH, W, A		    ;
	movwf	[D'2']			    ;
					    ;
	return				    ;
;-------------------------------------------;	
	
	
; Selects analog channel number and initiates a conversion	
; [0] input the channel number 
; D'0' -> D'15': AN0,...,AN12, reserved, Vddcore, Vbg (1.2 V)
; A separate routine is required to read the ADC result
;-------------------------------------------; 
ADC_channel_sel_go:			    ;
	subfsr	2, D'1'			    ;
	movf	[D'1'], W		    ;
	andlw	B'00001111'		    ; Permit only valid channels and
	movwf	[D'0']			    ; do not alter other register bits
	rlncf	[D'0'], F		    ;
	rlncf	[D'0'], F		    ;    
					    ;
	movf	ADCON0, W, A		    ;
	andlw	B'11000011'		    ; 
	iorwf	[D'0'], W		    ;
					    ;   
ADC_channel_sel_go_1			    ;
	btfsc	ADCON0, GO, A		    ;    
	bra	ADC_channel_sel_go_1	    ; wait for ADC free
					    ;
	movwf	ADCON0, A		    ; load the channel number
	bsf	ADCON0, GO, A		    ;
					    ;
	addulnk	D'1'			    ;
;-------------------------------------------;		
	
; Only selects an analog channel	
; [0] input the channel number 
; D'0' -> D'15': AN0,...,AN12, reserved, Vddcore, Vbg (1.2 V)
;-------------------------------------------; 
ADC_channel_sel:			    ;
	subfsr	2, D'1'			    ;
	movf	[D'1'], W		    ;
	andlw	B'00001111'		    ; Permit only valid channels / do not
	movwf	[D'0']			    ; mess with other register bits
	rlncf	[D'0'], F		    ;
	rlncf	[D'0'], F		    ;    
					    ;
	movf	ADCON0, W, A		    ;
	andlw	B'11000011'		    ; clear the channel selection bits
	iorwf	[D'0'], W		    ;
					    ;   
ADC_channel_sel_1			    ;
	btfsc	ADCON0, GO, A		    ;    
	bra	ADC_channel_sel_1	    ; wait for ADC free
					    ;
	movwf	ADCON0, A		    ;
					    ;
	addulnk	D'1'			    ;
;-------------------------------------------;	
	
; Initiates a coversion on the currently selected channel. Assumes ADC is ON
; and no conversion is in progress.	
; [0] returns Low Byte
; [1] returns High Byte	
;-------------------------------------------; 
ADC_go_read:				    ; 
	bsf	ADCON0, GO, A		    ; Start conversion
					    ;
ADC_go_read_1			    ;
	nop				    ;
	btfsc	ADCON0, GO, A		    ;
	bra	ADC_go_read_1		    ; wait for completion 
	movf	ADRESL, W, A		    ;
	movwf	[D'0']			    ;
	movf	ADRESH, W, A		    ;
	movwf	[D'1']			    ;
					    ;
	return				    ;
;-------------------------------------------;	
	
; Waits for a conversion to complete before reading result	
; [0] returns Low Byte
; [1] returns High Byte		
;-------------------------------------------; 
ADC_wait_read:				    ; 
	btfsc	ADCON0, GO, A		    ;
	bra	ADC_wait_read		    ; wait for completion 
	movf	ADRESL, W, A		    ;
	movwf	[D'0']			    ;
	movf	ADRESH, W, A		    ;
	movwf	[D'1']			    ;
					    ;
	return				    ;
;-------------------------------------------;	
	
; Returns ADC result registers	
; [0] returns Low Byte
; [1] returns High Byte	
;-------------------------------------------; 
ADC_read:				    ; 
	movf	ADRESL, W, A		    ;
	movwf	[D'0']			    ;
	movf	ADRESH, W, A		    ;
	movwf	[D'1']			    ;
					    ;
	return				    ;
;-------------------------------------------;		
	
	
; Performs an ADC offset calibration.
; Result is stored and handled internally by the ADC
; Assumed ADC is on
;-------------------------------------------;
ADC_calibrate:				    ;
	subfsr	2, D'3'			    ;
	bsf	ADCON1, ADCAL, A	    ;
	clrf	[D'0']			    ;
	call	ADC_channel_sel_go_read	    ;
	bcf	ADCON1, ADCAL, A	    ; Perform usual ADC measurements
					    ;
	addulnk	D'3'			    ;
;-------------------------------------------;
	
	
	END