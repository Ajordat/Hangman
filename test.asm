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
    N_LINE_H EQU 0x00	;NÚMERO DE LÍNIES HIGH
    N_LINE_L EQU 0x01	;NÚMERO DE LÍNIES LOW
    COLOR EQU 0x02	;COLOR DEL DIBUIX. USUALMENT SERÀ BLANC, VERD O VERMELL
    ERRORS EQU 0x03	;NOMBRE D'ERRORS. S'EXTREU DEL PORT D
    
;*************
;* CONSTANTS *
;*************
    BLACK EQU 0x00	;CONSTANTS AMB EL VALOR RGB DEL COLOR QUE REPRESENTEN
    RED EQU 0x01
    GREEN EQU 0x02
    YELLOW EQU 0x03
    BLUE EQU 0x04
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
    call INIT_TMR   ;ACTIVEM DE NOU LA INTERRUPCIÓ
    movlw 0x00
    cpfseq N_LINE_H ;SI LA PART SUPERIOR VAL 0 HI HA LA POSSIBILITAT D'HAVER D'ACTIVAR EL SINCRONISME VERTICAL
    goto HSYNC_1    ;SI NOMÉS S'HA D'ACTIVAR EL SINCRONISME HORITZONTAL
    movlw 0x01
    cpfseq N_LINE_L
    bcf LATE, 1, 0  ;SI ESTEM A LA PRIMERA LÍNIA NO ENS INTERESSA BAIXAR EL SINCRONISME VERTICAL
    movlw 0x01
    cpfsgt N_LINE_L, 0
    bsf LATE, 1, 0  ;SI N_LINE ÉS 0 o 1 S'ACTIVEN ELS DOS SINCRONISMES
    bsf LATE, 0, 0  ;SI N_LINE ÉS MÉS GRAN NOMÉS S'ACTIVA EL SINCRONISME HORITZONTAL
    NOP
    
COUNT_LINE
    incf N_LINE_L, 1, 0	;SEMPRE AUGMENTEM LA PART INFERIOR DEL COMPTADOR
    btfsc STATUS, C, 0	;I SI DESPRÉS DE L'OPERACIÓ INCF ELS BITS DE CARRY O OVERFLOW ESTAN ACTIUS
    incf N_LINE_H, 1, 0	;VOL DIR QUE HEM FET UNA VOLTA SENCERA I HEM D'AUGMENTAR LA PART SUPERIOR DEL COMPTADOR
    movlw 0x02	    ;ARA TOCA SABER SI S'HA DE REINICIAR EL COMPTADOR O ÚNICAMENT BAIXAR ELS SINCRONISMES ACTIUS
    cpfseq N_LINE_H	
    goto STOP_SIGNAL_1	;SI N_LINE VAL 0x0000 O 0x01FF NOMÉS BAIXEM ELS SINCRONISMES
    movlw 0x0D
    cpfseq N_LINE_L
    goto STOP_SIGNAL_2	;SI N_LINE VAL ENTRE 0x0200 I 0x020C NOMÉS BAIXEM ELS SINCRONISMES
    NOP
    clrf N_LINE_H
    clrf N_LINE_L
    goto STOP_SIGNAL_3	;SI N_LINE VAL 0x020D HEM REINICIAT EL COMPTADOR DE LÍNIES
    
HSYNC_1
    NOP		    ;ACTIVEM EL SENYAL DE SINCRONISME HORITZONTAL I ANEM A INCREMENTAR EL COMPTADOR DE LÍNIES
    call CINC_NOPS
    bsf LATE, 0, 0
    goto COUNT_LINE
    
STOP_SIGNAL_1
    movlw 0x00		;A CONTINUACIÓ VENEN UN SEGUIT DE NOPS PER A IGUALAR EL TEMPS EN PRENDRE CADASCUN DELS CAMINS
    cpfseq N_LINE_H	;PER A APAGAR EL SENYAL DE SINCRONISME HORITZONTAL UN COP HAGI PASSAT EL TEMPS CORRECTE
    goto STOP_SIGNAL_11
    goto STOP_SIGNAL_10

STOP_SIGNAL_11
    call CINC_NOPS
    call NOU_NOPS
    call NOU_NOPS
    goto STOP_SIGNAL
    
STOP_SIGNAL_10
    call NOU_NOPS
    call DOTZE_NOPS
    goto STOP_SIGNAL

STOP_SIGNAL_2
    call DEU_NOPS
    call SET_NOPS
    goto STOP_SIGNAL
    
STOP_SIGNAL_3
    call DEU_NOPS
    call DOTZE_NOPS
    
STOP_SIGNAL
    bcf LATE, 0, 0
    retfie FAST	    ;FI DE LA INTERRUPCIÓ

LOW_INT
    retfie FAST
    
;*********
;* INITS *
;*********
INIT_PORTS	    ;CONFIGURACIÓ DE I/O DELS BITS DELS PORTS
    bcf TRISA, 0, 0 ;RED
    bcf TRISA, 1, 0 ;GREEN
    bcf TRISA, 2, 0 ;BLUE
    bcf TRISE, 0, 0 ;HSYNC
    bcf TRISE, 1, 0 ;VSYNC
    bsf TRISD, 0, 0 ;NUMERRORS[0]
    bsf TRISD, 1, 0 ;NUMERRORS[1]
    bsf TRISD, 2, 0 ;NUMERRORS[2]
    bsf TRISD, 3, 0 ;NUMERRORS[3]
    bsf TRISD, 4, 0 ;PARTIDAGUANYADA
    bsf TRISD, 5, 0 ;GAMEOVER
    return

INIT_INTS	;INICIALITZACIÓ DE LES INTERRUPCIONS
    bcf RCON, IPEN, 0	;DESABILITEM LES PRIORITATS DE LES INTERRUPCIONS
    movlw 0xA0
    movwf INTCON, 0	;HABILITEM INTERRUPCIONS, HABILITEM EL BIT D'OVERFLOW DEL TMR0
    movlw 0x88
    movwf T0CON, 0	;HABILITEM TMR0, 16 BITS, SENSE PREESCALER
    return
    
INIT_TMR	    ;INICIALITZACIÓ DE LA INTERRUPCIÓ DEL TMR0
    movlw 0xFE	    ;ESCRIVIM EL VALOR 0xFECF, COSA QUE IMPLICA QUE SALTARÀ LA INTERRUPCIÓ EN 0x0130 (o 304d)
    movwf TMR0H, 0
    movlw 0xCF
    movwf TMR0L, 0
    bcf INTCON, TMR0IF, 0   ;DESACTIVEM EL BIT D'INTERRUPCIÓ DE TMR0
    return
    
INIT_VARS		;INICIALITZACIÓ DE LES VARIABLES
    clrf N_LINE_H, 0	;PARTIM DE LA LÍNIA 0
    clrf N_LINE_L, 0
    bcf LATA, 0, 0	;MOSTREM EL COLOR NEGRE
    bcf LATA, 1, 0
    bcf LATA, 2, 0
    movlw WHITE		;COMENCEM AMB EL NINOT DE COLOR BLANC
    movwf COLOR, 0  
    clrf ERRORS, 0	;I CAP ERROR
    return
    
;********
;* MAIN *
;********
MAIN	    ;COMENCEM CRIDANT TOTES LES INICIALITZACIONS I PASSEM A UN BUCLE INFINIT
    call INIT_VARS
    call INIT_PORTS
    call INIT_INTS
    call INIT_TMR
    
BUCLE	    ;BUCLE INFINIT, ESTAREM MIRANT LA LÍNIA PER LA QUE ANEM TOTA L'ESTONA PER SABER COM S'HA D'ACTUAR
    movlw 0x00		;SI N_LINE VAL 0x0100 O MÉS ÉS IMPOSSIBLE QUE ESTIGUEM PER SOBRE DEL LÍMIT SUPERIOR DE LA PANTALLA
    cpfseq N_LINE_H
    goto NEXT_IF	;ANEM A COMPROVAR SI ESTEM PER SOTA DEL LÍMIT INFERIOR DE LA PANTALLA
    movlw 0x23
    cpfsgt N_LINE_L
    goto BUCLE		;ESTEM PER SOBRE DEL LÍMIT SUPERIOR DE LA PANTALLA
    goto PINTA		;ESTEM A LA PART DE LA PANTALLA ON PODEM PINTAR
    
NEXT_IF
    movlw 0x02		;SI N_LINE VAL MENYS DE 0x0200 ÉS IMPOSSIBLE QUE ESTIGUEM PER SOTA DEL LÍMIT INFERIOR DE LA PANTALLA
    cpfseq N_LINE_H
    goto PINTA		;ESTEM A LA PART DE LA PANTALLA ON PODEM PINTAR
    movlw 0x03
    cpfslt N_LINE_L
    goto BUCLE		;ESTEM PER SOTA DEL LÍMIT INFERIOR DE LA PANTALLA
    goto PINTA		;ESTEM A LA PART DE LA PANTALLA ON PODEM PINTAR
    
    ;ESTEM A LA PART DE LA PANTALLA ON PODEM PINTAR, ARA TOCA SABER A QUINA DE LES PARTS. SI ANÈSSIM COMPARANT
    ;SEQÜENCIALMENT TOTS ELS VALORS POSSIBLES, QUAN ARRIBÉSSIM A L'ÚLTIM TRAM POSSIBLE JA NO EL PODRÍEM DIBUIXAR
    ;PERQUÈ SE'NS HAURIA PASSAT EL TEMPS DE DIBUIX O ESTARIEM MOLT DESPLAÇATS, AIXÍ QUE MIREM LA PART SUPERIOR
    ;DE LA VARIABLE I NO HEM DE FER TANTES COMPARACIONS. A MÉS A MÉS, TAMBÉ HEM D'ACONSEGUIR QUE ES TRIGUI EL MATEIX
    ;EN ARRIBAR A LA PART DE PINTAR LA PANTALLA PER TOTS ELS CAMINS DE LES COMPROVACIONS, TANT SI ÉS EL PRIMER TRAM DE
    ;LA PART SUPERIOR DE LA PANTALLA COM L'ÚLTIM DE LA PART INFERIOR.
PINTA
    movlw 0x00
    cpfseq N_LINE_H 
    goto PART_INFERIOR	;ESTEM A LA PART INFERIOR DE LA PANTALLA
    
PART_SUPERIOR		;ESTEM A LA PART SUPERIOR DE LA PANTALLA
    movlw 0x5F
    cpfsgt N_LINE_L
    goto ID_0_SUP_20_NOPS   ;NO ÉS UN TRAM ON ES PINTI A LA PANTALLA (TRAM 0 DE LA PANTALLA)
    movlw 0x69
    cpfsgt N_LINE_L
    goto TRAM_1		;TRAM 1 DE LA PANTALLA
    movlw 0x91
    cpfsgt N_LINE_L
    goto TRAM_2		;TRAM 2 DE LA PANTALLA
    movlw 0xB9
    cpfsgt N_LINE_L
    goto TRAM_3		;TRAM 3 DE LA PANTALLA
    movlw 0xCD
    cpfsgt N_LINE_L
    goto TRAM_4		;TRAM 4 DE LA PANTALLA
    movlw 0xD7
    cpfsgt N_LINE_L
    goto TRAM_5		;TRAM 5 DE LA PANTALLA
    goto TRAM_6		;TRAM 6 DE LA PANTALLA
    
PART_INFERIOR
    movlw 0x01
    cpfseq N_LINE_H
    goto ID_0_INF_25_NOPS   ;NO ÉS UN TRAM ON ES PINTI A LA PANTALLA (TRAM 16 DE LA PANTALLA)
    movlw 0x09
    cpfsgt N_LINE_L
    goto TRAM_7		;TRAM 7 DE LA PANTALLA
    movlw 0x31
    cpfsgt N_LINE_L
    goto TRAM_8		;TRAM 8 DE LA PANTALLA
    movlw 0x59
    cpfsgt N_LINE_L
    goto TRAM_9		;TRAM 9 DE LA PANTALLA
    movlw 0x63
    cpfsgt N_LINE_L
    goto TRAM_10	;TRAM 10 DE LA PANTALLA
    movlw 0x8B
    cpfsgt N_LINE_L
    goto TRAM_11	;TRAM 11 DE LA PANTALLA
    movlw 0x95
    cpfsgt N_LINE_L
    goto TRAM_12	;TRAM 12 DE LA PANTALLA
    movlw 0xBD
    cpfsgt N_LINE_L
    goto TRAM_13	;TRAM 13 DE LA PANTALLA
    movlw 0xC7
    cpfsgt N_LINE_L
    goto TRAM_14	;TRAM 14 DE LA PANTALLA
    NOP
    NOP
    goto ID_0_INF	;NO ÉS UN TRAM ON ES PINTI A LA PANTALLA (TRAM 15 DE LA PANTALLA)
    
    ;A CADA TRAM DE LA PANTALLA NOMÉS HI PODEN HAVER UNES POQUES LÍNIES CONCRETES DIBUIXADES. AQUESTS DIFERENTS MODELS HAN ESTAT
    ;DIBUIXATS I CLASSIFICATS EN ELS CONJUNTS D'INSTRUCCIONS ANOMENTATS ID{0..14}. SEGONS EL NOMBRE D'ERRORS CADASCUN DELS TRAMS
    ;UTILITZARÀ UN CONJUNT O ALTRE D'INSTRUCCIONS.
    
TRAM_1
    movlw 0x01
    cpfsgt ERRORS
    goto ID_0_SUP_13_NOPS
    call SET_NOPS
    goto ID_1
    
TRAM_2
    movlw 0x00
    cpfsgt ERRORS
    goto ID_0_SUP_10_NOPS
    movlw 0x02
    cpfsgt ERRORS
    goto ID_2_SUP_10_NOPS
    call DEU_NOPS
    call CINC_NOPS
    goto ID_3
    
TRAM_3
    movlw 0x00
    cpfsgt ERRORS
    goto ID_0_SUP_7_NOPS
    movlw 0x03
    cpfsgt ERRORS
    goto ID_2_SUP_7_NOPS
    call DOTZE_NOPS
    NOP
    goto ID_4_SUP

TRAM_4
    movlw 0x00
    cpfsgt ERRORS
    goto ID_0_SUP_4_NOPS
    movlw 0x04
    cpfsgt ERRORS
    goto ID_2_SUP_4_NOPS
    call SET_NOPS
    goto ID_3

TRAM_5
    movlw 0x00
    NOP
    cpfsgt ERRORS
    goto ID_0_SUP_0_NOPS
    movlw 0x04
    cpfsgt ERRORS
    goto ID_2_SUP
    movlw 0x05
    cpfsgt ERRORS
    goto ID_3
    goto ID_4_SUP
    
TRAM_6
    movlw 0x00
    cpfsgt ERRORS
    goto ID_0_SUP
    movlw 0x04
    cpfsgt ERRORS
    goto ID_2_SUP_V2
    NOP
    NOP
    goto ID_3_V2

TRAM_7
    movlw 0x00
    cpfsgt ERRORS
    goto ID_0_INF_18_NOPS
    movlw 0x06
    cpfsgt ERRORS
    goto ID_2_INF_4_NOPS
    NOP
    goto ID_4_INF

TRAM_8
    movlw 0x00
    cpfsgt ERRORS
    goto ID_0_INF_15_NOPS
    movlw 0x07
    NOP
    cpfsgt ERRORS
    goto ID_2_INF_3_NOPS
    goto ID_5

TRAM_9
    movlw 0x00
    cpfsgt ERRORS
    goto ID_0_INF_12_NOPS
    NOP
    goto ID_2_INF
    
TRAM_10
    movlw 0x00
    cpfsgt ERRORS
    goto ID_11
    NOP
    goto ID_6

TRAM_11
    movlw 0x00
    cpfsgt ERRORS
    goto ID_12
    goto ID_7

TRAM_12
    movlw 0x00
    cpfsgt ERRORS
    goto ID_13
    goto ID_8

TRAM_13
    movlw 0x00
    cpfsgt ERRORS
    goto ID_14
    goto ID_9

TRAM_14
    movlw 0x00
    cpfsgt ERRORS
    goto ID_15
    goto ID_10
    
ID_0_SUP_0_NOPS
    goto ID_0_SUP
    
ID_0_SUP_4_NOPS
    call CINC_NOPS
    goto ID_0_SUP
    
ID_0_SUP_7_NOPS
    call SET_NOPS
    NOP
    goto ID_0_SUP

ID_0_SUP_10_NOPS
    call DOTZE_NOPS
    goto ID_0_SUP
    
ID_0_SUP_13_NOPS
    call DEU_NOPS
    call CINC_NOPS
    NOP
    goto ID_0_SUP
    
ID_0_SUP_20_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    goto ID_0_SUP

ID_0_INF_12_NOPS
    call DEU_NOPS
    call NOU_NOPS
    goto ID_0_INF
    
ID_0_INF_15_NOPS
    call DOTZE_NOPS
    call DEU_NOPS
    goto ID_0_INF
    
ID_0_INF_18_NOPS
    call DOTZE_NOPS
    call CINC_NOPS
    call NOU_NOPS
    goto ID_0_INF
        
ID_0_INF_25_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DEU_NOPS
    goto ID_0_INF
    
ID_2_SUP_3_NOPS
    goto ID_2_SUP
    
ID_2_SUP_4_NOPS
    NOP
    NOP
    NOP
    goto ID_2_SUP
    
ID_2_SUP_7_NOPS
    call SET_NOPS
    goto ID_2_SUP
    
ID_2_SUP_10_NOPS
    call DEU_NOPS
    NOP
    goto ID_2_SUP
    
ID_2_INF_3_NOPS
    goto ID_2_INF
    
ID_2_INF_4_NOPS
    call CINC_NOPS
    goto ID_2_INF
    
    ;DURANT ELS TRAMS QUE PINTEM UN TROS "EN BLANC" DE LA PART SUPERIOR DE LA PANTALLA, COM QUE ES TRACTA DE MOLTES INSTRUCCIONS
    ;DE NO FER RES, APROFITEM AQUEST TEMPS PER A REALITZAR LA COMPROVACIÓ DELS ERRORS DE LA PARTIDA I ELS SENYALS DE VICTÒRIA I
    ;DERROTA. AIXÍ QUE AFEGIM UN CODI QUE RECULL EL VALOR DEL NOMBRE D'ERRORS DEL PORT D I EL GUARDA A LA NOSTRA VARIABLE,
    ;MIRA SI S'HA GUANYAT LA PARTIDA, CAS EN EL QUE ES FICARÀ LA VARIABLE COLOR AMB EL VALOR DE LA CONSTANT "GREEN" I ES MIRA EL 
    ;SENYAL DE DERROTA, CAS EN EL QUE ES FICARÀ LA VARIABLE COLOR AMB EL VALOR DE LA CONSTANT "RED".
    
ID_0_SUP
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    NOP
    NOP
    
DECISION
    movff PORTD, ERRORS	;ES RECULL EL VALOR DEL PORT D
    movlw 0x0F
    andwf ERRORS, 1, 0	;I HI APLIQUEM UNA MÀSCARA PER A NETEJAR ELS BITS DEL PORT QUE NO CONTENEN EL SENYAL NUMERRORS[3..0]
    btfsc PORTD, 4, 0
    goto VICTORY	;EL SENYAL DE VICTÒRIA ESTÀ ACTIU
    btfsc PORTD, 5, 0
    goto DEFEAT		;EL SENYAL DE DERROTA ESTÀ ACTIU
    NOP
    goto ID_0_SUP_CONT	;HEM ACTUALITZAT EL NOMBRE D'ERRORS I NO HI HA CAP SENYAL ACTIU
    
VICTORY		    ;SI ES TRACTA D'UNA VICTÒRIA, EL VALOR DE LA VARIABLE COLOR PASSA A SER "GREEN".
    movlw GREEN	    ;D'AQUESTA MANERA, COM QUE PINTEM EL NINOT EN FUNCIÓ D'AQUESTA VARIABLE, A PARTIR D'ARA ES PINTARÀ
    movwf COLOR, 0  ;DE COLOR VERD
    NOP
    NOP
    goto ID_0_SUP_CONT
    
DEFEAT		    ;SI ES TRACTA D'UNA DERROTA, EL VALOR DE LA VARIABLE COLOR PASSA A SER "RED".
    movlw RED	    ;D'AQUESTA MANERA, COM QUE PINTEM EL NINOT EN FUNCIÓ D'AQUESTA VARIABLE, A PARTIR D'ARA ES PINTARÀ
    movwf COLOR, 0  ;DE COLOR VERMELL
    NOP
    
ID_0_SUP_CONT
    call DOTZE_NOPS
    call DOTZE_NOPS
    call SET_NOPS
    NOP
    goto BUCLE
    
ID_0_INF
    call FORTY_NOPS
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DEU_NOPS
    call DEU_NOPS
    call DEU_NOPS
    goto BUCLE
    
ID_1
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    NOP
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
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    NOP
    NOP
    NOP
    goto BUCLE

ID_2_SUP
    call SET_NOPS
    call SET_NOPS
    NOP
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
    call DOTZE_NOPS
    call DEU_NOPS
    NOP
    goto BUCLE
    
ID_2_SUP_V2
    call SET_NOPS
    call SET_NOPS
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
    call DOTZE_NOPS
    call DOTZE_NOPS
    goto BUCLE
    
ID_2_INF
    call SET_NOPS
    call SET_NOPS
    call CINC_NOPS
    movff COLOR, LATA
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
    goto BUCLE
    
ID_3
    call DEU_NOPS
    NOP
    movff COLOR, LATA
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
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DEU_NOPS
    call CINC_NOPS
    goto BUCLE
    
        
ID_3_V2
    call DEU_NOPS
    movff COLOR, LATA
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
    call DEU_NOPS
    call DEU_NOPS
    call DEU_NOPS
    call DEU_NOPS
    goto BUCLE
    
ID_4_SUP
    call NOU_NOPS
    movff COLOR, LATA
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
    call DEU_NOPS
    call CINC_NOPS
    goto BUCLE
    
ID_4_INF
    call DEU_NOPS
    call SET_NOPS
    call SET_NOPS
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
    goto BUCLE
    
ID_5
    call SET_NOPS
    call SET_NOPS
    call CINC_NOPS
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
    goto BUCLE
    
ID_6
    call DEU_NOPS
    call CINC_NOPS
    movff COLOR, LATA
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call CINC_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    NOP
    NOP
    NOP  
    goto BUCLE
    
ID_7
    NOP
    call CINC_NOPS
    call CINC_NOPS
    NOP
    movff COLOR, LATA
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call CINC_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    NOP
    NOP
    NOP    
    goto BUCLE
    
ID_8
    call SET_NOPS
    NOP
    movff COLOR, LATA
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call CINC_NOPS
    movlw PINK
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_9
    NOP
    NOP
    NOP
    NOP
    movff COLOR, LATA
    NOP
    NOP
    NOP
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call CINC_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_10
    movff COLOR, LATA
    call DEU_NOPS
    clrf LATA, 0
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DEU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_11
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call CINC_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    call DOTZE_NOPS
    call DEU_NOPS
    call CINC_NOPS
    clrf LATA, 0
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_12
    call FORTY_NOPS
    call FORTY_NOPS
    call DEU_NOPS  
    call DEU_NOPS
    call CINC_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    NOP
    NOP
    NOP
    goto BUCLE
    
ID_13
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call NOU_NOPS
    movlw PINK
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    NOP
    NOP
    NOP    
    goto BUCLE
    
ID_14
    call FORTY_NOPS
    call FORTY_NOPS
    call DOTZE_NOPS
    call DOTZE_NOPS
    call DEU_NOPS
    call SET_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call NOU_NOPS
    call NOU_NOPS
    movlw PINK
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
    call DOTZE_NOPS
    call DEU_NOPS
    call DEU_NOPS
    call CINC_NOPS
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call DOTZE_NOPS
    call DOTZE_NOPS
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    NOP
    NOP
    NOP
    clrf LATA, 0
    call CINC_NOPS
    NOP
    movlw PINK
    movwf LATA, 0
    call DEU_NOPS
    call DEU_NOPS
    call SET_NOPS
    clrf LATA, 0
    NOP
    NOP
    NOP
    goto BUCLE
    
    ;FUNCIONS DE NOPS, PER A ESTALVIAR LÍNIES DE CODI I AUGMENTAR LA COMPRENSIÓ D'AQUEST
CINC_NOPS
    NOP
    return
    
SET_NOPS
    NOP
    NOP
    movf COLOR, 0, 0
    return
    
NOU_NOPS
    call CINC_NOPS
    return

DEU_NOPS
    call CINC_NOPS
    NOP
    return
    
N17_NOPS
    call DOTZE_NOPS
    NOP
    return
    
FORTY_NOPS
    call DEU_NOPS
    call DEU_NOPS
    call DEU_NOPS
    call CINC_NOPS
    movf COLOR, 0, 0
    return
    
DOTZE_NOPS
    call SET_NOPS
    movf COLOR, 0, 0
    return
      
;*******
;* END *
;*******
    END
