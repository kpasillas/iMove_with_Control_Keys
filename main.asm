TITLE iMove_with_Control_Keys 				(main.asm)

;------------------------------------------------------------------------------
; Program:     Chapter 11, iMove_with_Control_Keys
; Description: This exercise is to try practice using control keys by a
; programming exercise to run like this. You can use arrow keys and other
; control keys to move a character within the rectangle area. When press
; ESC to exit.
; Student:     Kristopher Pasillas
; Date:        05/09/2018
; Class:       CSCI 241
; Instructor:  Mr. Ding
;------------------------------------------------------------------------------

INCLUDE Irvine32.inc

;-----------------------------------------------------------------------
DrawChar PROTO charToWrite:BYTE, x:BYTE, y:BYTE, clr:BYTE
; Draws a character at a given position.
; Receives: charToWrite - the character used to represent
;           x, y - position at coordinate x, y (Col, Row)
;           clr - the color used to draw char
;-----------------------------------------------------------------------

.data
MinX = 4
MinY = 5
MaxX = 76
MaxY = 16
origX = (MinX + MaxX) / 2
origY = (MinY + MaxY) / 2
oldX		BYTE ?
oldY		BYTE ?
currX		BYTE ?
currY		BYTE ?
clrToShow	BYTE ?
clrToHide	BYTE ?
playerChar	BYTE 'I'
helpOn		BYTE 0
guideStr	BYTE "iMove Guide: ", 0Dh, 0Ah, 0
helpStrOff	BYTE "Press the F1 key for help...", 0
clearStr	BYTE MaxX DUP(20h), 0Dh, 0Ah
			BYTE MaxX DUP(20h), 0Dh, 0Ah
			BYTE MaxX DUP(20h), 0Dh, 0Ah, 0
helpStrOn	BYTE "1. Directly use four arrow keys for Up, Right, Down, Left.", 0Dh, 0Ah
			BYTE "2. ^Up: Up-Right, ^Right: Down-Right, ^Down: Down-Left, ^Left: Up-Left.", 0Dh, 0Ah
			BYTE "3. Home: Back to center, ESC: Exit, F1: Toggle help text.", 0
outHandle	HANDLE ?
cursorInfo	CONSOLE_CURSOR_INFO <1, FALSE>

.code
main PROC
	call Clrscr

	mov		edx, OFFSET guideStr
	call	WriteString
	
	call	ToggleHelp						; Help initialized to Off
	
	INVOKE	GetStdHandle, STD_OUTPUT_HANDLE
	mov		outHandle, eax
	INVOKE	SetConsoleCursorInfo, outHandle, ADDR cursorInfo
	
	call	DrawRectangle
	mov		eax, 0
	call	GetTextColor
	mov		clrToShow, al					; set clrToShow
	mov		bl, al
	shr		al, 4
	AND		bl, 11110000b
	OR		bl, al
	mov		clrToHide, bl					; set ClrToHide
	INVOKE	DrawChar, playerChar, origX, origY, clrToShow
	mov		oldX, origX
	mov		oldY, origY
	
LookForKey:
	mov		eax,50          ; sleep, to allow OS to time slice
	call	Delay           ; (otherwise, some key presses are lost)

	call	ReadKey         ; look for keyboard input
	jz		LookForKey      ; no key pressed yet
	
	call	ProcessKey

	jnc		LookForKey

	mov		dl, 0							; reset cursor
	mov		dh, MaxY + 1
	call	Gotoxy

	exit
main ENDP

;-----------------------------------------------------------------------
ToggleHelp PROC
; Turns on/off the help text when F1 pressed
;-----------------------------------------------------------------------
	push edx

	mov		dl, 0
	mov		dh, 1
	call	Gotoxy
	mov		edx, OFFSET clearStr
	call	WriteString

	cmp		helpOn, 0
	jne		TurnOn
	mov		dl, 0
	mov		dh, 1
	call	Gotoxy
	mov		edx, OFFSET helpStrOff
	call	WriteString
	mov		helpOn, 1
	jmp		Quit1
	
TurnOn:
	mov		dl, 0
	mov		dh, 1
	call	Gotoxy
	mov		edx, OFFSET helpStrOn
	call	WriteString
	mov		helpOn, 0

Quit1:	
	pop		edx
	ret
ToggleHelp ENDP

;-----------------------------------------------------------------------
DrawRectangle PROC
; Draws a boarder rectangle from MinX, MinY to MaxX MaxY.
; Receives: Conctant symbils: MinX, MinY to MaxX MaxY
;-----------------------------------------------------------------------

	; draw top border
	mov		dl, Minx
	mov		dh, MinY
	call	Gotoxy
	mov		ecx, MaxX - MinX + 1
	mov		eax, 205
L1:
	call	WriteChar
	loop	L1

	; draw left border
	mov		dl, Minx
	mov		ecx, MaxY - MinY - 1
	mov		ebx, MinY
	mov		eax, 186
L2:
	inc		bl
	mov		dh, bl 
	call	Gotoxy
	call	WriteChar
	loop	L2

	; draw right border
	mov		dl, MaxX
	mov		ecx, MaxY - MinY - 1
	mov		ebx, MinY
	mov		eax, 186
L3:
	inc		bl
	mov		dh, bl 
	call	Gotoxy
	call	WriteChar
	loop	L3
	
	; draw bottom border
	mov		dl, Minx
	mov		dh, MaxY
	call	Gotoxy
	mov		ecx, MaxX - MinX + 1
	mov		eax, 205
L4:
	call	WriteChar
	loop	L4

	ret
DrawRectangle ENDP

;-----------------------------------------------------------------------
DrawChar PROC charToWrite:BYTE, x:BYTE, y:BYTE, clr:BYTE
;-----------------------------------------------------------------------
	push	eax
	push	edx
	mov		eax, 0

	mov		dl, x
	mov		dh, y
	call	Gotoxy
	mov		al, clr
	call	SetTextColor
	mov		al, charToWrite
	call	WriteChar
	call	Gotoxy

	pop		edx
	pop		eax
	ret
DrawChar ENDP

;-----------------------------------------------------------------------
ProcessKey PROC
; By reading a char, checks its scan code to recognize
; Arrow, Control Arrow, Home, ESC, and F1 keys. Then take
; the action accordingly
; Return: carry flage set if ESC pressed, else cleared
;-----------------------------------------------------------------------

	cmp		ax, 011Bh						; check for ESC
	jne		NotEsc
	stc
	jmp		Quit2

NotEsc:
	cmp		ah, 3bh							; check if F1
	jne		NotHelp
	call	ToggleHelp
	jmp		Quit2

NotHelp:
	mov		dl, oldX
	mov		currX, dl
	mov		dh, oldY
	mov		currY, dh

	.IF		(ah == 47h)						; check if Home
		mov		currX, origX
		mov		currY, origY
	.ELSEIF	(ah == 3bh)
		call	ToggleHelp
	.ELSEIF									; check which direction to move
		.IF		(ah == 48h) || (ah == 8Dh) || (ah == 73h)		; check if Up arrow
			dec		currY
		.ENDIF
		.IF		(ah == 4Dh) || (ah == 8Dh) || (ah == 74h)		; check if Right arrow
			inc		currX
		.ENDIF
		.IF		(ah == 50h) || (ah == 74h) || (ah == 91h)		; check if Down arrow
			inc		currY
		.ENDIF
		.IF		(ah == 4Bh) || (ah == 91h) || (ah == 73h)		; check if Left arrow
			dec		currX
		.ENDIF
	.ENDIF

	; check if border reached
	.IF		(currX == MinX) || (currX == MaxX) || (currY == MinY) || (currY == MaxY)
		mov		dl, oldX
		mov		currX, dl
		mov		dh, oldY
		mov		currY, dh
		mov		al, 7
		call	WriteChar
		jmp		Quit2
	.ELSEIF
		mov		dl, oldX
		mov		dh, oldY
		INVOKE	DrawChar, playerChar, dl, dh, clrToHide			; previous 'I' at dx

		mov		bl, currX
		mov		oldX, bl
		mov		bh, currY
		mov		oldY, bh
		INVOKE	DrawChar, playerChar, bl, bh, clrToShow			; current  'I' at bx
	.ENDIF

Quit2:
	ret
ProcessKey ENDP

END main