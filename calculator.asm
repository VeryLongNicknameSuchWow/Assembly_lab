OPTION SCOPED

data1 segment
       endlMessage     db 13, 10, '$'                               ; carriage return, line feed (CR-LF)

       queryMessage    db "Wprowadz slowny opis dzialania: $"

       errorMessage    db "Blad danych wejsciowych!$"

       inputBuffer     db 24                                        ; the longest possible prompt is 23 chars + carriage return
                       db 0                                         ; actual length of prompt
       inputBufferText db 24 dup('$')                               ; 24 chars (set to $ in case it is shorter)
                       db '$'                                       ; final end of string

       num1str         dw ?
       opStr           dw ?
       num2str         dw ?

       digits          db "zero$"
                       db "jeden$"
                       db "dwa$"
                       db "trzy$"
                       db "cztery$"
                       db "piec$"
                       db "szesc$"
                       db "siedem$"
                       db "osiem$"
                       db "dziewiec$"
                       db "dziesiec$"
                       db "jedenascie$"
                       db "dwanascie$"
                       db "trzynascie$"
                       db "czternascie$"
                       db "pietnascie$"
                       db "szesnascie$"
                       db "siedemnascie$"
                       db "osiemnascie$"
                       db "dziewietnascie$"

       tens            db "dwadziescia$"
                       db "trzydziesci$"
                       db "czterdziesci$"
                       db "piecdziesiat$"
                       db "szescdziesiat$"
                       db "siedemdziesiat$"
                       db "osiemdziesiat$"
                       db "dziewiecdziesiat$"

       plus            db "plus$"
       minus           db "minus$"
       times           db "razy$"
data1 ends

code1 segment
main proc
       start:      
                   mov   ax, seg stack1                   ; setup stack1 as stack segment
                   mov   ss, ax
                   mov   sp, offset s1top                 ; setup stack pointer (top of the stack)

                   mov   ax, data1                        ; setup data1 as data segment
                   mov   ds, ax

                   mov   dx, offset queryMessage          ; print queryMessage
                   call  print
                   mov   dx, offset inputBuffer           ; input text into buffer
                   call  input
                   call  endl

                   mov   bp, offset inputBuffer +1        ; remove CR from buffer
                   mov   bl, byte ptr ds:[bp]
                   add   bl, 1
                   mov   bh, 0
                   add   bp, bx
                   mov   byte ptr ds:[bp], '$'

                   mov   si, offset inputBufferText       ; save buffer start to num1str
                   mov   di, offset num1str
                   mov   ds:[di], si

                   mov   si, offset inputBufferText       ; strtok
                   call  strtok

                   mov   di, offset opStr                 ; save next word to opStr
                   mov   ds:[di], bp

                   mov   si, bp                           ; strtok
                   call  strtok
                
                   mov   di, offset num2str               ; save next word to num2str
                   mov   ds:[di], bp
                    
                   mov   si, offset num1str               ; print each substring
                   mov   dx, ds:[si]
                   call  print
                   call  endl

                   mov   si, offset opStr
                   mov   dx, ds:[si]
                   call  print
                   call  endl

                   mov   si, offset num2str
                   mov   dx, ds:[si]
                   call  print
                   call  endl

                   mov   si, offset num1str
                   mov   si, ds:[si]
                   call  parseDigit
                   mov   ax, bp

                   mov   si, offset num2str
                   mov   si, ds:[si]
                   call  parseDigit
                   add   ax, bp


                   call  printNumber
  
                   mov   al, 0                            ; exit code 0
                   mov   ah, 4ch
                   int   21h
main endp

strtok proc
       ; replaces the first encountered space with the end char ($), returns the pointer to character directly after it
       ; si - text address
       ; bp - returns the pointer to next token
       start:      
                   push  ax
                   push  si

       loop1:      
                   lodsb
                   cmp   al, '$'
                   jz    exit
                   cmp   al, ' '
                   jne   loop1

                   dec   si
                   mov   byte ptr ds:[si], '$'
                   inc   si

       exit:       
                   mov   bp, si
                  
                   pop   si
                   pop   ax
                   ret
strtok endp

input proc
       ; runs the buffered input interrupt
       ; dx - buffer offset (first two bytes used for length)
       start:      
                   mov   ah, 0ah
                   int   21h
                   ret
input endp

endl proc
       ; sets up ds with endlMessage for print
       start:      
                   mov   dx, offset endlMessage
                   call  print
                   ret
endl endp

print proc
       ; runs the print interrupt
       ; dx - text offset
       start:      
                   mov   ah, 09h
                   int   21h
                   ret
print endp

strcmp proc
       ; compares two strings
       ; si - str1 address
       ; di - str2 address
       ; bp - returns 0 if equal
       start:      
                   push  ax
                   push  si
                   push  di

       loops:      
                   mov   al, ds:[si]
                   cmp   al, ds:[di]
                   jne   notEqual

                   cmp   al, '$'
                   je    equal

                   inc   si
                   inc   di
                   jmp   loops

       equal:      
                   mov   bp, 0
                   jmp   exit

       notEqual:   
                   mov   bp, 1
                   jmp   exit

       exit:       
                   pop   di
                   pop   si
                   pop   ax
                   ret
strcmp endp

parseDigit proc
       ; si - digit string to convert
       ; bp - returns the digit as number
       start:      
                   push  di
                   push  si
                   push  cx
                   mov   cx, 0
                   mov   di, si
                   mov   si, offset digits
              
       loops:      
                   call  strcmp
                   cmp   bp, 0
                   je    exit

                   call  strtok
                   mov   si, bp

                   inc   cx
              
                   cmp   cx, 10
                   jne   loops

       exit:       
                   mov   bp, cx
                   pop   cx
                   pop   si
                   pop   di
                   ret
parseDigit endp

printNumber proc
       ; ax - number to be printed
       start:      
                   push  cx
                   push  si
                   mov   cx, 0
                   mov   si, offset digits

       loop1:      
                   cmp   cx, ax
                   je    output

                   call  strtok
                   mov   si, bp

                   inc   cx
                   jmp   loop1

       output:     
                   mov   dx, si
                   call  print

       exit:       
                   pop   si
                   pop   cx
                   ret
printNumber endp

code1 ends

stack1 segment
       ; 256 bytes of stack and top of stack pointer
       s1     db 256 dup(?)
       s1top  db ?
stack1 ends

end main
