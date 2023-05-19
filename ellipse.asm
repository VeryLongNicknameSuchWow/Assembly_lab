OPTION SCOPED

data1 segment
    vga   dw 0a000h
data1 ends

code1 segment

main proc

    setupStack: 
                mov  ax, seg stack1                ; setup stack1 as stack segment
                mov  ss, ax
                mov  sp, offset s1top              ; setup stack pointer (top of the stack)

    setupData:  
                mov  ax, seg data1                 ; setup data1 as data segment
                mov  ds, ax

    setupVGA:   
                mov  ah, 0h
                mov  al, 13h                       ; 320x200, 256 colors
                int  10h

                mov  byte ptr cs:[pointK], 13
                mov  word ptr cs:[ellipseX], 60
                mov  word ptr cs:[ellipseY], 40
                call drawEllipse

                mov  byte ptr cs:[pointK], 12
                mov  word ptr cs:[ellipseX], 70
                mov  word ptr cs:[ellipseY], 50
                call drawEllipse

                mov  ah, 0
                int  16h

    textMode:   
                mov  ah, 0h
                mov  al, 3h
                int  10h

    exit:       
                mov  ah, 4ch
                mov  al, 0                         ; exit code 0
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

    pointX      dw   ?
    pointY      dw   ?
    pointK      db   ?

drawPoint endp

sine proc
    ; sine of ax=alpha, using Bhaskara I's formula
    ; returns in ax (*1000)

    init:       
                push bx
                push cx
                push dx

    calculate:  
                mov  bx, 180
                sub  bx, ax                        ; bx = 180 - alpha
                mul  bx                            ; ax = alpha(180 - alpha)
                mov  bx, ax                        ; bx = alpha(180 - alpha)
                mov  ax, 40500
                sub  ax, bx
                mov  cx, ax                        ; cx = 40500 - alpha(180 - alpha)
                mov  ax, 4000
                mul  bx                            ; ax = 4000*alpha(180 - alpha)
                div  cx                            ; ax = ax/cx

    exit:       
                pop  dx
                pop  cx
                pop  bx
                ret

sine endp

drawEllipse proc

    init:       
                push ax
                push bx
                push cx
                push dx

                mov  cx, 89
    testL:      
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
                add  ax, 90
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

    ; loop testL
                dec  cx
                cmp  cx, 0
                jge  testL

    exit:       
                pop  dx
                pop  cx
                pop  bx
                pop  ax
                ret

    ellipseX    dw   ?
    ellipseY    dw   ?

drawEllipse endp

code1 ends

stack1 segment stack
    s1     db 256 dup(?)
    s1top  db ?
stack1 ends

end main
