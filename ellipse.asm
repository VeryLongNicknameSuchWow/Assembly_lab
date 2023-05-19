OPTION SCOPED

data1 segment
    vga   dw 0a000h
data1 ends

code1 segment

main proc

    setupStack:     
                    mov  ax, seg stack1                 ; setup stack1 as stack segment
                    mov  ss, ax
                    mov  sp, offset s1top               ; setup stack pointer (top of the stack)

    setupData:      
                    mov  ax, seg data1                  ; setup data1 as data segment
                    mov  ds, ax

    setupVGA:       
                    mov  ah, 0h
                    mov  al, 13h                        ; 320x200, 256 colors
                    int  10h

                    mov  word ptr cs:[ellipseX], 60
                    mov  word ptr cs:[ellipseY], 40

    mainLoop:       
                    call nowDrawing
                    call drawEllipse

                    mov  ah, 01h
                    int  16h
                    jz   mainLoop

                    mov  ah, 00h
                    int  16h

                    cmp  al, 1bh
                    je   textMode

                    cmp  al, 00h
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
                    call nowErasing
                    call drawEllipse
                    add  word ptr cs:[ellipseY], 1
                    jmp  checkBounds

    downArrow:      
                    call nowErasing
                    call drawEllipse
                    sub  word ptr cs:[ellipseY], 1
                    jmp  checkBounds

    leftArrow:      
                    call nowErasing
                    call drawEllipse
                    sub  word ptr cs:[ellipseX], 1
                    jmp  checkBounds

    rightArrow:     
                    call nowErasing
                    call drawEllipse
                    add  word ptr cs:[ellipseX], 1
                    jmp  checkBounds

    checkBounds:    
    checkOverfowX:  
                    cmp  word ptr cs:[ellipseX], 160
                    jbe  checkUnderflowX
                    sub  word ptr cs:[ellipseX], 1

    checkUnderflowX:
                    cmp  word ptr cs:[ellipseX], 2
                    jae  checkOverflowY
                    add  word ptr cs:[ellipseX], 1

    checkOverflowY: 
                    cmp  word ptr cs:[ellipseY], 100
                    jbe  checkUnderflowY
                    sub  word ptr cs:[ellipseY], 1

    checkUnderflowY:
                    cmp  word ptr cs:[ellipseY], 2
                    jae  mainLoop
                    add  word ptr cs:[ellipseY], 1
                    jmp  mainLoop

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
                    push es
                    push ax
                    push bx

    draw:           
                    mov  es, word ptr ds:[vga]
                    mov  ax, word ptr cs:[pointY]
                    mov  bx, 320
                    mul  bx
                    mov  bx, word ptr cs:[pointX]
                    add  bx, ax
                    mov  al, byte ptr cs:[pointK]
                    mov  byte ptr es:[bx], al
               
    exit:           
                    pop  bx
                    pop  ax
                    pop  es
                    ret

    pointX          dw   ?
    pointY          dw   ?
    pointK          db   ?

drawPoint endp

sine proc
    ; sine of ax=alpha, using Bhaskara I's formula
    ; returns in ax (*1000)

    init:           
                    push cx
                    mov  dx, 0

    calculate:      
                    mov  bx, 360
                    sub  bx, ax                         ; bx = 360 - alpha
                    mul  bx                             ; dx:ax = alpha(360 - alpha)
                    push dx
                    push ax

                    mov  cx, 4
                    div  cx                             ; dx:ax = alpha(360 - alpha)/4
                    mov  cx, 40500
                    sub  cx, ax                         ; cx = 40500 - alpha(360 - alpha)/4
                
                    pop  ax
                    pop  dx                             ; dx:ax = alpha(360 - alpha)

                    mov  bx, 1000
                    mul  bx                             ; dx:ax = 1000*alpha(360 - alpha)
                    div  cx                             ; dx:ax = dx:ax/cx

    exit:           
                    pop  cx
                    ret

sine endp

drawEllipse proc

    init:           

                    mov  cx, 179
    drawLoop:       
                    mov  ax, cx
                    call sine
                    mov  bx, word ptr cs:[ellipseX]
                    mul  bx
                    mov  bx, 1000
                    div  bx
                    mov  bx, 160
                    add  bx, ax
                    push bx
                    mov  word ptr cs:[pointX], bx

                    mov  ax, cx
                    add  ax, 180
                    call sine
                    mov  bx, word ptr cs:[ellipseY]
                    mul  bx
                    mov  bx, 1000
                    div  bx
                    mov  bx, 100
                    add  bx, ax
                    mov  word ptr cs:[pointY], bx
                    call drawPoint

                    mov  ax, word ptr cs:[pointX]
                    sub  ax, 160
                    mov  bx, 160
                    sub  bx, ax
                    mov  word ptr cs:[pointX], bx
                    call drawPoint

                    mov  ax, word ptr cs:[pointY]
                    sub  ax, 100
                    mov  bx, 100
                    sub  bx, ax
                    mov  word ptr cs:[pointY], bx
                    call drawPoint

                    pop  bx
                    mov  word ptr cs:[pointX], bx
                    call drawPoint

                    loop drawLoop

    exit:           
                    ret

    ellipseX        dw   ?
    ellipseY        dw   ?

drawEllipse endp

nowDrawing proc

    init:           
                    push ax
                    mov  al, cs:[drawingColor]
                    mov  byte ptr cs:[pointK], al

    exit:           
                    pop  ax
                    ret
    
    drawingColor    db   13

nowDrawing endp

nowErasing proc

    init:           
                    push ax
                    mov  al, cs:[erasingColor]
                    mov  byte ptr cs:[pointK], al

    exit:           
                    pop  ax
                    ret

    erasingColor    db   0

nowErasing endp

code1 ends

stack1 segment stack
    s1     dw 256 dup(?)
    s1top  dw ?
stack1 ends

end main
