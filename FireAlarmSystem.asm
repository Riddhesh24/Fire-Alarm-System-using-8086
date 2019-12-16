
#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=1FFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

	jmp    st1 
    db     509 dup(0)
	
	;IVT entry for 80H
count 		db		00h
	dw     t_isr
	dw     0000
	db     508 dup(0)

st1: cli 
	; intialize ds, es,ss to start of RAM
    mov       ax,0100h
    mov       ds,ax
    mov       es,ax
    mov       ss,ax
    mov       sp,0FFFEH
	
;initialize 8255
	;portA	equ	0000h
	;portB	equ 0002h
	;portC	equ	0004h
	;creg	equ	0006h

	mov al, 10010001b					; portA = input, portB = output, portC lower = input, portC upper = output
	out 0006H, al
	
	;enables the motors, rotates the motors in the clockwise direction, enables gate for clock0 for 500 clock pulses
	
	mov al, 00000000b		;Resets ADC	
	out 0004H, al
	
	
	;8259 - 18H to 1AH
	;8259 -	enable IRO alone use AEOI	  
	mov       al,00010011b		;icw1
	out       18h,al
	mov       al,10000000b    	;icw2
	out       1Ah,al
	mov       al,00000011b		;icw4
	out       1Ah,al
	mov       al,11111110b		;ocw1
	out       1Ah,al
		
	;initialize 8253
	sti				

x1: ;cnt0	equ	0010h
	;cnt1	equ	0012h
	;cnt2	equ	0014h
	;0016h	equ	0016h
	
	mov al,00110110b; load counter to mode 2
	out 0016H, al
	
	mov al,10h; load count 10000 in the counter
	out 0010H, al
	
	mov al,27h;
	out 0010H, al
	
	mov al,00001001b
	out 0004h,al		; port C gate enable 
	mov al, 00000000b
	out 0002h, al 	;send address 000 to ADC
	
	mov al, 01000000b;set ALE
	out 0002h, al 	
	
	mov al, 01100000b;set Start
	out 0002h, al 	
	
	mov al, 01000000b;set ALE and clear start
	out 0002h, al	
	;input of smoke sensor 0
	
x2 :in al, 0004h	
	and al, 01h
	cmp al, 01h
	jnz x2			;if EOC is low, loop back to x2, else proceed
	mov al, 00000000b
	out 0002h, al
	
	in al, 0000h	;since EOC is high, take the input from the ADC of smoke sensor 0
	out 0002h, al
	
	mov cl, 90h		;CL has threshold smoke value(90h)
	cmp al, cl		;compare al with the threshold value
	jna  x21		;if al<= danger level count is not increased else increased
	inc count
	
x21:mov bl, al		
	mov al, 00h
	
	mov al, 10000000b
	out 0002h, al 	;send address 001 to ADC
	
	mov al, 11000000b ;set ALE
	out 0002h, al 	
	
	mov al, 11100000b;Set Start
	out 0002h, al 	
	
	mov al, 11000000b;Reset start
	out 0002h, al 
	;input of smoke sensor 1
	
x3 :in al, 0004h	;checks for EOC signal
	and al, 01h
	cmp al, 01h
	mov al, 00000000b ;reset ADC
	out 0002h, al
	
	jnz x3			;if EOC is low, loop back to x3, else proceed
	mov al, 00000000b
	out 0002h, al
	
	in al, 0000h	;since EOC is high, take the input from the ADC of smoke sensor 0
	out 0002h, al
	
	mov cl, 90h		;CL has threshold smoke value(90h)
	cmp al, cl		;compare al with the threshold value
	jna  x31		;if al<= danger level count is not increased else increased
	inc count
	
x31:mov bl, al		
	mov al, 00h
	
	mov al, 00010000b
	out 0002h, al 	;send address 010 to ADC
	
	mov al, 01010000b ;set ALE
	out 0002h, al 	
	
	mov al, 01110000b;Set Start
	out 0002h, al 	
	
	mov al, 01010000b;Reset start
	out 0002h, al
	;input of smoke sensor 2

x4 :in al, 0004h	;checks for EOC signal
	and al, 01h
	cmp al, 01h
	mov al, 00000000b ;reset ADC
	out 0002h, al
	
	jnz x4			;if EOC is low, loop back to x4, else proceed
	mov al, 00h
	
	in al, 0000h	;since EOC is high, take input from ADC of smoke sensor 2
	out 0002h, al
	
	mov cl, 90h		;CL has threshold smoke value(90h)
	cmp al, cl		;compare al with the threshold value
	jna  x41		;if al<= danger level count is not increased else increased
	inc count 
	
x41:cmp count,01d
	je x5		;if count=1 ring only warning alarm
	ja x6		;if count>1 ring fire alarm and open windows,valve and doors 
	jmp x0		;define x0 later
	
x5: mov al, 00000000b
	out 0002h, al
		
	mov al, 10000000b
	out 0004h, al	;ringing the warning alarm
	
	mov dl, 00h		;set state of doors, windows, valves as open and raise alarm
	jmp x1;  		GO TO THE END OF PROGRAM.................... 
	
x6: mov al, 00000000b
	out 0002h, al
		
	mov al, 00110000b
	out 0004h, al	;rotating the motors in anticlockwise direction
	
	mov dl, 01h		;set state of doors, windows, valves as open and raise alarm
	
x99:mov al, 00000000b	
	out 0002h, al 	;send address 000 to ADC
	
	; CHECKING IF SMOKE HAS REDUCED
	and count,00h
	mov al, 01000000b	;set ALE
	out 0002h, al 	
	
	mov al, 01100000b
	out 0002h, al 	
	
	mov al, 01000000b
	out 0002h, al	
	
	
x7:in al, 0004h	;checks for EOC signal
	and al, 01h
	cmp al, 01h
	jnz x7			;if EOC is low, loop back to x7, else proceed
	mov al, 00000000b
	out 0002h, al
	
	in al, 0000h	;since EOC is high, take the input from the ADC of smoke sensor 0
	out 0002h, al
	
	mov cl, 93h
	cmp al, cl		;compare al with an arbitrary value
	jna x71			;if al <= danger level, jump to x17
	inc count
x71:mov bl, al		
	mov al, 00h
	
	mov al, 10000000b
	out 0002h, al 	;send address 001 to ADC
	
	mov al, 11000000b
	out 0002h, al 	
	
	mov al, 11100000b
	out 0002h, al 	
	
	mov al, 11000000b
	out 0002h, al	
	
x8:	in al, 0004h	;checks for EOC signal
	and al, 01h
	cmp al, 01h
	mov al, 00000000b
	out 0002h, al
	
	jnz x8			;if EOC is low, loop back to x8, else proceed
	
	mov al, 00h
	
	in al, 0000h	;since EOC is high, take input from ADC of smoke sensor 1
	in al, 0000h
	out 0002h, al
	
	mov cl, 93h
	cmp al, cl		;compare al with the arbitrary value
	jna x81			;if al <= danger level, jump to x10
	inc count
x81:mov bl, al		
	mov al, 00h
	
	mov al, 00010000b
	out 0002h, al 	;send address 010 to ADC
	
	mov al, 01010000b ;set ALE
	out 0002h, al 	
	
	mov al, 01110000b;Set Start
	out 0002h, al 	
	
	mov al, 01010000b;Reset start
	out 0002h, al
	;input of smoke sensor 2

x9 :in al, 0004h	;	checks for EOC signal
	and al, 01h
	cmp al, 01h
	mov al, 00000000b ;reset ADC
	out 0002h, al
	
	jnz x9			;if EOC is low, loop back to x4, else proceed
	mov al, 00h
	
	in al, 0000h	;since EOC is high, take input from ADC of smoke sensor 2
	out 0002h, al
	
	mov cl, 90h		;CL has threshold smoke value(90h)
	cmp al, cl		;compare al with the threshold value
	jna  x91		;if al<= danger level count is not increased else increased
	inc count
	
x91:cmp count,00d
	ja x99		;if count>1 ring only warning alarm 
	jmp xa		
	
xa: ;close doors, windows,valve and sound alarm
		
	mov al, 01000000b
	out 0004h, al			
	
	mov dl, 00h				;set previous state
x0: jmp x0  		; initial run till an interrupt is raised 

t_isr:
; IVT code
	
y1:	;cnt0	equ	0010h
	;cnt1	equ	0012h
	;cnt2	equ	0014h
	;0016h	equ	0016h
	
	mov al,00110110b; load counter to mode 2
	out 0016H, al
	
	mov al,10h; load count 10000 in the counter
	out 0010H, al
	
	mov al,27h;
	out 0010H, al
	
	mov al,00010000b
	out 0004h,al		; port C gate enable 
	mov al, 00000000b
	out 0002h, al 	;send address 000 to ADC
	
	mov al, 01000000b;set ALE
	out 0002h, al 	
	
	mov al, 01100000b;set Start
	out 0002h, al 	
	
	mov al, 01000000b;set ALE and clear start
	out 0002h, al	
	;input of smoke sensor 0
	
y2 :in al, 0004h	
	and al, 01h
	cmp al, 01h
	jnz y2			;if EOC is low, loop back to x2, else proceed
	mov al, 00000000b
	out 0002h, al
	
	in al, 0000h	;since EOC is high, take the input from the ADC of smoke sensor 0
	out 0002h, al
	
	mov cl, 90h		;CL has threshold smoke value(90h)
	cmp al, cl		;compare al with the threshold value
	jna  y21		;if al<= danger level count is not increased else increased
	inc count
	
y21:mov bl, al		
	mov al, 00h
	
	mov al, 10000000b
	out 0002h, al 	;send address 001 to ADC
	
	mov al, 11000000b ;set ALE
	out 0002h, al 	
	
	mov al, 11100000b;Set Start
	out 0002h, al 	
	
	mov al, 11000000b;Reset start
	out 0002h, al 
	;input of smoke sensor 1
	
y3 :in al, 0004h	;checks for EOC signal
	and al, 01h
	cmp al, 01h
	mov al, 00000000b ;reset ADC
	out 0002h, al
	
	jnz y3			;if EOC is low, loop back to x3, else proceed
	mov al, 00000000b
	out 0002h, al
	
	in al, 0000h	;since EOC is high, take the input from the ADC of smoke sensor 0
	out 0002h, al
	
	mov cl, 90h		;CL has threshold smoke value(90h)
	cmp al, cl		;compare al with the threshold value
	jna  y31		;if al<= danger level count is not increased else increased
	inc count
	
y31:mov bl, al		
	mov al, 00h
	
	mov al, 00010000b
	out 0002h, al 	;send address 010 to ADC
	
	mov al, 01010000b ;set ALE
	out 0002h, al 	
	
	mov al, 01110000b;Set Start
	out 0002h, al 	
	
	mov al, 01010000b;Reset start
	out 0002h, al
	;input of smoke sensor 2

y4 :in al, 0004h	;checks for EOC signal
	and al, 01h
	cmp al, 01h
	mov al, 00000000b ;reset ADC
	out 0002h, al
	
	jnz y4			;if EOC is low, loop back to x4, else proceed
	mov al, 00h
	
	in al, 0000h	;since EOC is high, take input from ADC of smoke sensor 2
	out 0002h, al
	
	mov cl, 90h		;CL has threshold smoke value(90h)
	cmp al, cl		;compare al with the threshold value
	jna y41		;if al<= danger level count is not increased else increased
	inc count 
	
y41:mov ch,01d
	cmp count,ch
	je y5		;if count=1 ring only warning alarm
	ja y6		;if count>1 ring fire alarm and open windows,valve and doors 
	jmp y0		;go to iret
	
y5: mov al, 00000000b
	out 0002h, al
		
	mov al, 10000000b
	out 0004h, al	;ringing the warning alarm
	
	mov dl, 00h		;set state of doors, windows, valves as open and raise alarm
	jmp y1;  		GO TO THE END OF PROGRAM.................... 
	
y6: mov al, 00000000b
	out 0002h, al
		
	mov al, 00110000b
	out 0004h, al	;rotating the motors in clockwise direction
	
	mov dl, 01h		;set state of doors, windows, valves as open and raise alarm
	
y99:mov al, 00000000b	
	out 0002h, al 	;send address 000 to ADC
	
	; CHECKING IF SMOKE HAS REDUCED
	and count,00h
	mov al, 01000000b
	out 0002h, al 	
	
	mov al, 01100000b
	out 0002h, al 	
	
	mov al, 01000000b
	out 0002h, al	
	
	
y7:in al, 0004h	;checks for EOC signal
	and al, 01h
	cmp al, 01h
	jnz y7			;if EOC is low, loop back to x7, else proceed
	mov al, 00000000b
	out 0002h, al
	
	in al, 0000h	;since EOC is high, take the input from the ADC of smoke sensor 0
	out 0002h, al
	
	mov cl, 93h
	cmp al, cl		;compare al with an arbitrary value
	jna y71			;if al <= danger level, jump to x17
	inc count
y71:mov bl, al		
	mov al, 00h
	
	mov al, 10000000b
	out 0002h, al 	;send address 001 to ADC
	
	mov al, 11000000b
	out 0002h, al 	
	
	mov al, 11100000b
	out 0002h, al 	
	
	mov al, 11000000b
	out 0002h, al	
	
y8:	in al, 0004h	;checks for EOC signal
	and al, 01h
	cmp al, 01h
	mov al, 00000000b
	out 0002h, al
	
	jnz y8			;if EOC is low, loop back to x8, else proceed
	
	mov al, 00h
	
	in al, 0000h	;since EOC is high, take input from ADC of smoke sensor 1
	in al, 0000h
	out 0002h, al
	
	mov cl, 93h
	cmp al, cl		;compare al with the arbitrary value
	jna y81			;if al <= danger level, jump to x10
	inc count
y81:mov bl, al		
	mov al, 00h
	
	mov al, 00010000b
	out 0002h, al 	;send address 010 to ADC
	
	mov al, 01010000b ;set ALE
	out 0002h, al 	
	
	mov al, 01110000b;Set Start
	out 0002h, al 	
	
	mov al, 01010000b;Reset start
	out 0002h, al
	;input of smoke sensor 2

y9 :in al, 0004h	;checks for EOC signal
	and al, 01h
	cmp al, 01h
	mov al, 00000000b ;reset ADC
	out 0002h, al
	
	jnz y9			;if EOC is low, loop back to x4, else proceed
	mov al, 00h
	
	in al, 0000h	;since EOC is high, take input from ADC of smoke sensor 2
	out 0002h, al
	
	mov cl, 90h		;CL has threshold smoke value(90h)
	cmp al, cl		;compare al with the threshold value
	jna  y91		;if al<= danger level count is not incressased else increased
	inc count
	
y91:cmp count,00d
	ja y99		;if count>1 ring only warning alarm 
	jmp ya		
	
ya: ;close doors, windows,valve and sound alarm
		
	mov al, 01000000b
	out 0004h, al			
	
	mov dl, 00h				;set previous state

y0:
	iret	
	
	
	
