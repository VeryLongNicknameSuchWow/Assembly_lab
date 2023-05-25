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

    draw:          
                   mov  byte ptr cs:[pointK], 15
                   mov  byte ptr cs:[ellipseA], 50
                   mov  byte ptr cs:[ellipseB], 50
                   call drawEllipse

                   call controls
                   jmp draw

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

    pointX         dw   ?
    pointY         dw   ?
    pointK         dw   ?

drawPoint endp

checkUnderflow proc

    init:          
                   push cx

    body:          
                   cmp  ax, bx
                   jae  exit

                   mov  cx, ax
                   mov  ax, bx
                   mov  bx, cx

    exit:          
                   pop  cx
                   ret

checkUnderflow endp

testPoint proc

    init:          
                   push ax
                   push bx
                   push cx
                   push dx
                   mov  dx, 0

    body:          
                   mov  ax, word ptr cs:[pointX]
                   mov  bx, 160
                   call checkUnderflow
                   sub  ax, bx
                   mul  ax
                   mov  bx, 100
                   mul  bx

                   mov  bx, word ptr cs:[ellipseA]
                   div  bx
                   div  bx

                   push dx
                   push ax

                   mov  dx, 0
                   mov  ax, word ptr cs:[pointY]
                   mov  bx, 100
                   call checkUnderflow
                   sub  ax, bx
                   mul  ax
                   mov  bx, 100
                   mul  bx

                   mov  bx, word ptr cs:[ellipseB]
                   div  bx
                   div  bx

                   pop  bx
                   pop  cx

                   clc
                   add  ax, bx
                   adc  dx, cx

                   mov  bx, 100
                   clc
                   sub  ax, bx
                   sbb  dx, 0

    ;    cmp  dx, 0
    ;    jne   exit

                   cmp  ax, 20
                   ja   exit

    ;    cmp  ax, -5
    ;    jl   exit

    draw:          
                   call drawPoint

    exit:          
                   pop  dx
                   pop  cx
                   pop  bx
                   pop  ax
                   ret

    ellipseA       dw   ?
    ellipseB       dw   ?
testPoint endp

drawEllipse proc

    init:          
                   push ax
                   push bx
                   mov  ax, 0
                   
    loopA:         
                   mov  word ptr[pointX], ax
                   mov  bx, 0
    loopB:         
                   mov  word ptr[pointY], bx
                   call testPoint

                   inc  bx
                   cmp  bx, 199
                   jb   loopB

                   inc  ax
                   cmp  ax, 319
                   jb   loopA

    exit:          
                   pop  bx
                   pop  ax
                   ret

drawEllipse endp

controls proc

    init:          
                   push ax

    body:          
                   mov  ax, 0
                   int  16h

                   cmp  ah, 48h
                   je   up

                   cmp  ah, 50h
                   je   down

                   cmp  ah, 4bh
                   je   left

                   cmp  ah, 4dh
                   je   right

                   jmp  exit

    up:            
                   mov  al, byte ptr cs:[ellipseA]
                   inc  al
                   mov  byte ptr cs:[ellipseA], al
                   jmp  exit

    down:          
                   mov  al, byte ptr cs:[ellipseB]
                   inc  al
                   mov  byte ptr cs:[ellipseB], al
                   jmp  exit

    left:          
                   jmp  exit

    right:         
                   jmp  exit

    exit:          
                   pop  ax
                   ret
    
controls endp

code1 ends

stack1 segment stack
    s1     db 256 dup(?)
    s1top  db ?
stack1 ends

end main
