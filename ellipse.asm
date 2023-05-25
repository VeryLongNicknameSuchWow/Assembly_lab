OPTION SCOPED

data1 segment

    vga          dw 0a000h
    argsOffset   dw 81h

    errorMessage db "Blad danych wejsciowych$"

    w2           dw 2
    w4           dw 4
    w10          dw 10
    w16          dw 16
    w250         dw 250
    w320         dw 320
    w1000        dw 1000

data1 ends


code1 segment

main proc

    setupStack:  
                 mov  ax, seg stack1                    ; setup stack1 as stack segment
                 mov  ss, ax
                 mov  sp, offset s1top                  ; setup stack pointer (top of the stack)

    setupData:   
                 mov  ax, seg data1                     ; setup data1 as data segment
                 mov  ds, ax

    ;testing:
    ;             mov  word ptr cs:[ellipseX], 50
    ;             mov  word ptr cs:[ellipseY], 50
    ;             jmp  setupVGA

    setupPSP:    
                 mov  si, word ptr ds:[argsOffset]      ; arguments offset in PSP (Program Segment Prefix)

                 call skipSpaces
                 call parseNumber
                 call ceilDiv
                 mov  word ptr cs:[ellipseX], ax        ; ellipse width

                 call skipSpaces
                 call parseNumber
                 call ceilDiv
                 mov  word ptr cs:[ellipseY], ax        ; ellipse height
                
                 call skipSpaces
                
                 cmp  al, 0
                 je   setupVGA                          ; may end with null char

                 cmp  al, 13
                 je   setupVGA                          ; or with CR

                 jmp  handleError

    setupVGA:    
                 mov  ah, 0h
                 mov  al, 13h                           ; 320x200, 256 colors
                 int  10h

    redraw:      
                 call nowDrawing
                 call drawEllipse

    mainLoop:    
                 mov  ah, 01h                           ; wait for key
                 int  16h
                 jz   mainLoop

                 mov  ah, 00h                           ; read the key
                 int  16h

                 cmp  al, 1bh                           ; escape
                 je   textMode

                 cmp  al, 00h                           ; arrows are extended keys
                 jne  mainLoop

                 cmp  ah, 48h
                 je   upArrow

                 cmp  ah, 50h
                 je   downArrow

                 cmp  ah, 4bh
                 je   leftArrow

                 cmp  ah, 4dh
                 je   rightArrow

                 jmp  mainLoop

    upArrow:     
                 cmp  word ptr cs:[ellipseY], 100       ; check if maximum
                 jae  mainLoop
                 call nowErasing                        ; erase previous ellipse
                 call drawEllipse
                 add  word ptr cs:[ellipseY], 1         ; increment size
                 jmp  redraw                            ; and redraw (its the same for other keys)

    downArrow:   
                 cmp  word ptr cs:[ellipseY], 1
                 jle  mainLoop
                 call nowErasing
                 call drawEllipse
                 sub  word ptr cs:[ellipseY], 1
                 jmp  redraw

    leftArrow:   
                 cmp  word ptr cs:[ellipseX], 1
                 jle  mainLoop
                 call nowErasing
                 call drawEllipse
                 sub  word ptr cs:[ellipseX], 1
                 jmp  redraw

    rightArrow:  
                 cmp  word ptr cs:[ellipseX], 160
                 jae  mainLoop
                 call nowErasing
                 call drawEllipse
                 add  word ptr cs:[ellipseX], 1
                 jmp  redraw

    textMode:    
                 mov  ah, 0h
                 mov  al, 3h
                 int  10h

    exit:        
                 mov  ax, 4c00h
                 int  21h

main endp

drawPoint proc

    init:        
                 mov  es, word ptr ds:[vga]
                 mov  ax, word ptr cs:[pointY]
                 mul  word ptr ds:[w320]
                 mov  bx, word ptr cs:[pointX]
                 add  bx, ax
                 mov  al, byte ptr cs:[pointK]
                 mov  byte ptr es:[bx], al              ; vga[320 * y + x] = k
               
    exit:        
                 ret

    pointX       dw   ?
    pointY       dw   ?
    pointK       db   ?

drawPoint endp

sine proc
    ; sine of ax=alpha, using Bhaskara I's formula
    ; https://en.wikipedia.org/wiki/Bhaskara_I%27s_sine_approximation_formula
    ; returns in ax (*1000)

    init:        
                 push cx

    calculate:   
                 mov  bx, 360
    ;  mov  bx, 720z
                 sub  bx, ax                            ; bx = 360 - alpha
                 mul  bx                                ; dx:ax = alpha(360 - alpha)
                 push dx
                 push ax

                 div  word ptr ds:[w4]                  ; dx:ax = alpha(360 - alpha)/4
    ;  div  word ptr ds:[w16]                  ; dx:ax = alpha(360 - alpha)/4
                 mov  cx, 40500
                 sub  cx, ax                            ; cx = 40500 - alpha(360 - alpha)/4
                
                 pop  ax
                 pop  dx                                ; dx:ax = alpha(360 - alpha)

                 mul  word ptr ds:[w1000]               ; dx:ax = 1000*alpha(360 - alpha)
    ;  mul  word ptr ds:[w250]               ; dx:ax = 1000*alpha(360 - alpha)
                 div  cx                                ; dx:ax = dx:ax/cx

    exit:        
                 pop  cx
                 ret

sine endp

drawEllipse proc

    init:        
                 mov  cx, 179                           ; start just below pi/2 (down to 0)
    ;  mov  cx, 359                           ; start just below pi/2 (down to 0)
                 
    drawLoop:    
                 mov  ax, cx                            ; ax = alpha
                 call sine                              ; ax = sine(alpha)
                 mul  word ptr cs:[ellipseX]            ; multiply by X radius
                 div  word ptr ds:[w1000]               ; floating numbers "hack"
                 mov  word ptr cs:[offsetX], ax         ; this is the offset of point's X (dX)

                 mov  ax, cx                            ; ax = alpha + pi/2
                 add  ax, 180
    ;  add  ax, 360
                 call sine                              ; ax = cosine(alpha)
                 mul  word ptr cs:[ellipseY]            ; same as above
                 div  word ptr ds:[w1000]
                 mov  word ptr cs:[offsetY], ax         ; offset of point's Y (dY)

                 mov  bx, 160                           ; X midpoint (mX)
                 add  bx, word ptr cs:[offsetX]
                 mov  word ptr cs:[pointX], bx          ; pX = mX + dX
                 push bx
                 
                 mov  bx, 100                           ; Y midpoint (mY)
                 add  bx, word ptr cs:[offsetY]
                 mov  word ptr cs:[pointY], bx          ; pY = mY + dY
                 call drawPoint

                 mov  bx, 160
                 sub  bx, word ptr cs:[offsetX]
                 mov  word ptr cs:[pointX], bx          ; pX = mX - dX
                 call drawPoint

                 mov  bx, 100
                 sub  bx, word ptr cs:[offsetY]
                 mov  word ptr cs:[pointY], bx          ; pY = mY - dY
                 call drawPoint

                 pop  word ptr cs:[pointX]              ; pX = mX - dX
                 call drawPoint

                 loop drawLoop                          ; alpha -> 0

    exit:        
                 ret

    ellipseX     dw   ?
    ellipseY     dw   ?
    offsetX      dw   ?
    offsetY      dw   ?

drawEllipse endp

nowDrawing proc

    init:        
                 mov  al, byte ptr cs:[drawingColor]    ; setup a nice color
                 mov  byte ptr cs:[pointK], al

    exit:        
                 ret
    
    drawingColor db   13

nowDrawing endp

nowErasing proc

    init:        
                 mov  al, byte ptr cs:[erasingColor]    ; black color for erasing
                 mov  byte ptr cs:[pointK], al

    exit:        
                 ret

    erasingColor db   0

nowErasing endp

handleError proc

                 mov  dx, offset errorMessage           ; print error message
                 mov  ah, 09h
                 int  21h

                 mov  ax, 4c01h                         ; exit code 1
                 int  21h

handleError endp

skipSpaces proc
                
    loop1:       
                 mov  al, byte ptr es:[si]              ; reading from ES (PSP)
                 inc  si
                
                 cmp  al, ' '                           ; skip spaces
                 jne  exit

                 jmp  loop1

    exit:        
                 dec  si                                ; make si point to the first character that was not space
                 ret

skipSpaces endp

parseNumber proc

    init:        
                 mov  ax, 0
                 mov  dx, 0
                 mov  cx, 0

    loop1:       
                 mov  bl, byte ptr es:[si]              ; loading from ES (PSP)
                 inc  si

                 cmp  bl, ' '                           ; exit with space, CR or null char
                 je   exit

                 cmp  bl, 0
                 je   exit

                 cmp  bl, 13
                 je   exit

                 cmp  bl, '9'                           ; it should be a number
                 ja   handleError

                 cmp  bl, '0'
                 jb   handleError

                 mov  cx, 10                            ; decimal shift (also used as an indication that a digit was found)
                 mul  cx

                 mov  bh, 0
                 sub  bx, '0'                           ; convert ASCII to number
                 add  ax, bx

                 cmp  ax, 200                           ; number must be in [0; 200]
                 ja   handleError

                 jmp  loop1

    exit:        
                 cmp  cx, 0                             ; there were no digits found
                 je   handleError

                 ret

parseNumber endp

ceilDiv proc

                 mov  dx, 0
                 div  word ptr ds:[w2]                  ; divide by two, add the remainder
                 add  ax, dx
                 ret

ceilDiv endp

code1 ends


stack1 segment stack

    s1     dw 256 dup(?)
    s1top  dw ?

stack1 ends

end main
