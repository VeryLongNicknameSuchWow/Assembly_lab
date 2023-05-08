.MODEL small
.STACK 100

data1 segment
    t1    db "Hello world! $"
data1 ends

code1 segment
    start1:
           mov ax, seg t1
           mov ds, ax
           mov dx, offset t1
           mov ah, 9
           int 21h

           mov ah, 4ch
           int 21h
code1 ends

end start1
