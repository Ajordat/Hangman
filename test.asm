    LIST P=18F4321, F=INHX32
    #include <P18F4321.INC>	

;******************
;* CONFIGURACIONS *
;******************
    CONFIG OSC = HSPLL          
    CONFIG PBADEN = DIG
    CONFIG WDT = OFF

;*************
;* VARIABLES *
;*************
    N_LINE_H EQU 0x00 ;NÚMERO DE LÍNIES HIGH
    N_LINE_L EQU 0x01 ;NÚMERO DE LÍNIES LOW
    COLOR EQU 0x02

;*************
;* CONSTANTS *
;*************
    BLACK EQU 0x00
    BLUE EQU 0x01
    GREEN EQU 0x02
    YELLOW EQU 0x03
    RED EQU 0x04
    PINK EQU 0x05
    CYAN EQU 0x06
    WHITE EQU 0x07

;*********************************
; VECTORS DE RESET I INTERRUPCIÓ *
;*********************************
    ORG 0x000000
RESET_VECTOR
    goto MAIN

    ORG 0x000008
HI_INT_VECTOR
    goto HIGH_INT

    ORG 0x000018
LOW_INT_VECTOR
    goto LOW_INT

;***********************************
;* RUTINES DE SERVEI D'INTERRUPCIÓ *
;***********************************
HIGH_INT    
    call INIT_TMR
    movlw 0x00
    cpfseq N_LINE_H
    goto HSYNC_1
    movlw 0x01
    cpfseq N_LINE_L
    bcf LATE, 1, 0  
    movlw 0x01
    cpfsgt N_LINE_L, 0
    bsf LATE, 1, 0
    bsf LATE, 0, 0
    NOP
COUNT_LINE
    incf N_LINE_L, 1, 0
    btfsc STATUS, C, 0
    incf N_LINE_H, 1, 0
    movlw 0x02
    cpfseq N_LINE_H
    goto STOP_SIGNAL_1	;SI N_LINE VAL 0x0000 O 0x01FF
    movlw 0x0D
    cpfseq N_LINE_L
    goto STOP_SIGNAL_2	;SI N_LINE VAL ENTRE 0x0200 I 0x020C
    NOP
    clrf N_LINE_H
    clrf N_LINE_L
    goto STOP_SIGNAL_3	;SI N_LINE VAL 0x020D
HSYNC_1
    NOP
    NOP
    NOP
    NOP
    NOP
    
    NOP
    bsf LATE, 0, 0
    goto COUNT_LINE
STOP_SIGNAL_1
    movlw 0x00
    cpfseq N_LINE_H
    goto STOP_SIGNAL_11
    goto STOP_SIGNAL_10

STOP_SIGNAL_11
    NOP
    NOP
    call NOU_NOPS
    call NOU_NOPS
    NOP
    NOP
    NOP
    goto STOP_SIGNAL
    
STOP_SIGNAL_10
    call NOU_NOPS
    call NOU_NOPS
    NOP
    NOP
    NOP
    goto STOP_SIGNAL

STOP_SIGNAL_2
    NOP
    call NOU_NOPS
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    goto STOP_SIGNAL
STOP_SIGNAL_3
    call NOU_NOPS
    call NOU_NOPS
    NOP
    NOP
    NOP
    NOP
STOP_SIGNAL
    bcf LATE, 0, 0
    retfie FAST

LOW_INT
    retfie FAST
    
;*********
;* INITS *
;*********
INIT_PORTS
    bcf TRISA, 0, 0
    bcf TRISA, 1, 0
    bcf TRISA, 2, 0
    bcf TRISE, 0, 0
    bcf TRISE, 1, 0
    return

INIT_INTS
    bcf RCON, IPEN, 0
    movlw 0xA0
    movwf INTCON, 0
    movlw 0x88
    movwf T0CON, 0
    return
    
INIT_TMR 
    movlw 0xFE
    movwf TMR0H, 0
    movlw 0xCF
    movwf TMR0L, 0
    bcf INTCON, TMR0IF, 0
    return
    
INIT_VARS
    clrf N_LINE_H, 0
    clrf N_LINE_L, 0
    bcf LATA, 0, 0
    bcf LATA, 1, 0
    bcf LATA, 2, 0
    movlw WHITE
    movwf COLOR, 0
    return
    
;********
;* MAIN *
;********
MAIN
    call INIT_VARS
    call INIT_PORTS
    call INIT_INTS
    call INIT_TMR
    
BUCLE
    movlw 0x00		;COMPROVEM SI ESTÀ PER SOBRE DEL MARGE INFERIOR DE LÍNIES PER A PINTAR
    cpfseq N_LINE_H
    goto NEXT_IF
    movlw 0x23
    cpfsgt N_LINE_L
    goto BUCLE
    goto PINTA
    
NEXT_IF
    movlw 0x02		;COMPROVEM SI ESTÀ PER SOTA DEL MARGE SUPERIOR DE LÍNIES PER A PINTAR
    cpfseq N_LINE_H
    goto PINTA
    movlw 0x03
    cpfslt N_LINE_L
    goto BUCLE
    goto PINTA
    
PINTA		;ESTEM A LA ZONA ON PODEM PINTAR
    movlw 0x00
    cpfseq N_LINE_H
    goto ID_10   ;INFERIOR
    goto ID_4_SUP	;SUPERIOR  
    
ERRORS_0
    movlw 0x00
    cpfsgt N_LINE_H
    goto ID_0_SUP
    movlw 0x59
    cpfsgt N_LINE_L
    goto ID_0_INF
    movlw 0x63
    cpfsgt N_LINE_L
    goto ID_11
    movlw 0x80
    cpfsgt N_LINE_L
    goto ID_12
    movlw 0x95
    cpfsgt N_LINE_L
    goto ID_13
    movlw 0xBD
    cpfsgt N_LINE_L
    goto ID_14
    movlw 0xC7
    cpfsgt N_LINE_L
    goto ID_15
    goto ID_0_INF
    
ID_0_SUP
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    goto BUCLE
    
ID_0_INF
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    NOP
    NOP
    goto BUCLE
    
ID_1
    call FORTY_NOPS
    movwf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call SET_NOPS  
    goto BUCLE

ID_2_SUP
    call FORTY_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call DEU_NOPS
    call DEU_NOPS
    call DEU_NOPS
    NOP
    goto BUCLE
    
ID_2_INF
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    NOP
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call DEU_NOPS
    call DEU_NOPS
    call DEU_NOPS
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_3
    call FORTY_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call SET_NOPS
    goto BUCLE
    
ID_4_SUP
    call FORTY_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call SET_NOPS
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DEU_NOPS
    NOP
    goto BUCLE
    
ID_4_INF
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    NOP
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call SET_NOPS
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DEU_NOPS
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_5
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    NOP
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DEU_NOPS
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_6
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    NOP
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    NOP
    NOP
    call CINC_NOPS
    NOP    
    goto BUCLE
    
ID_7
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    NOP
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    NOP
    call CINC_NOPS
    NOP
    NOP    
    goto BUCLE
    
ID_8
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    NOP
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call SET_NOPS
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    NOP
    NOP
    call CINC_NOPS
    NOP    
    goto BUCLE
    
ID_9
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    NOP
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    NOP
    NOP
    call CINC_NOPS
    NOP
    goto BUCLE
    
ID_10
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    NOP
    movwf LATA, 0
    call DEU_NOPS
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DEU_NOPS
    NOP
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_11
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call SET_NOPS
    NOP
    NOP
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    NOP
    NOP
    NOP    
    NOP
    NOP
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_12
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call SET_NOPS
    NOP
    NOP
    movwf LATA, 0
    ;bsf LATA, 2, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    ;bcf LATA, 2, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    ;bsf LATA, 2, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    ;bcf LATA, 2, 0
    call SET_NOPS
    movwf LATA, 0
    ;bsf LATA, 2, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    ;bcf LATA, 2, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    ;bsf LATA, 2, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    ;bcf LATA, 2, 0
    call SET_NOPS
    movwf LATA, 0
    ;bsf LATA, 2, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    ;bcf LATA, 0
    call DEU_NOPS
    call NOU_NOPS
    bsf LATA, 2, 0
    ;bcf LATA, 2, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_13
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    movwf LATA, 0
    ;bsf LATA, 2, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    ;bcf LATA, 2, 0
    call SET_NOPS
    movwf LATA, 0
    ;bsf LATA, 2, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    ;bcf LATA, 2, 0
    call SET_NOPS
    movwf LATA, 0
    ;bsf LATA, 2, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    ;bcf LATA, 2, 0
    NOP
    NOP
    NOP    
    goto BUCLE
    
ID_14
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DEU_NOPS
    call NOU_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_15
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    call SET_NOPS
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call SET_NOPS
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    NOP
    NOP
    NOP
    goto BUCLE
    
CINC_NOPS
    NOP
    return
    
SET_NOPS
    NOP
    NOP
    movf COLOR, 0, 0
    return
    
NOU_NOPS
    NOP
    NOP
    NOP
    NOP
    NOP
    return

DEU_NOPS
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    return
    
N23_NOPS
    call DEU_NOPS
    call NOU_NOPS
    return
    
FORTY_NOPS
    call DEU_NOPS
    call DEU_NOPS
    call DEU_NOPS
    NOP
    NOP
    NOP
    NOP
    NOP
    movf COLOR, 0, 0
    return
    
DOTZE_NOPS
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    ;NOP
    movf COLOR, 0, 0
    return
       
PINTA_EBU_H0
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    bsf LATA, 0, 0
    bsf LATA, 1, 0
    bsf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bcf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bsf LATA, 2, 0
    bcf LATA, 0, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bcf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bsf LATA, 0, 0
    bcf LATA, 1, 0
    bsf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bcf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bcf LATA, 0, 0
    bsf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bcf LATA, 2, 0
    call DOTZE_NOPS
    
    goto BUCLE
    
PINTA_EBU_H1
    NOP
    NOP
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    bsf LATA, 0, 0
    bsf LATA, 1, 0
    bsf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bcf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bsf LATA, 2, 0
    bcf LATA, 0, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bcf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bsf LATA, 0, 0
    bcf LATA, 1, 0
    bsf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bcf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bcf LATA, 0, 0
    bsf LATA, 2, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    bcf LATA, 2, 0
    call DOTZE_NOPS
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    goto BUCLE
    
;*******
;* END *
;*******
    END


