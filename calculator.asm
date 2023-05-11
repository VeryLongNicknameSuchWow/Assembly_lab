OPTION SCOPED

data1 segment
       endlMessage     db 13, 10, '$'                               ; carriage return, line feed (CR-LF)

       queryMessage    db "Wprowadz slowny opis dzialania: $"

       errorMessage    db "Blad danych wejsciowych!$"

       resultMessage   db "Wynikiem jest: $"

       space           db " $"

       inputBuffer     db 24                                        ; the longest possible prompt is 23 chars + carriage return
                       db 0                                         ; actual length of prompt
       inputBufferText db 24 dup('$')                               ; 24 chars (set to $ in case it is shorter)
                       db '$'                                       ; final end of string

       n1Ptr           dw ?                                         ; pointers to the start of each number and operator in inputBufferText
       opPtr           dw ?
       n2Ptr           dw ?

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

                   mov   si, offset inputBufferText       ; save first word to n1Ptr
                   mov   di, offset n1Ptr
                   mov   word ptr ds:[di], si

                   mov   si, offset inputBufferText       ; strtok
                   call  strtok

                   mov   di, offset opPtr                 ; save next word to opPtr
                   mov   word ptr ds:[di], bp

                   mov   si, bp                           ; strtok
                   call  strtok
                
                   mov   di, offset n2Ptr                 ; save next word to n2Ptr
                   mov   word ptr ds:[di], bp

                   mov   si, offset n1Ptr                 ; convert n1Ptr string to number
                   mov   si, word ptr ds:[si]
                   call  parseDigit
                   mov   ax, bp                           ; save first number in ax

                   cmp   ax, 10                           ; handle conversion error
                   je    error

                   mov   si, offset n2Ptr                 ; convert n2Ptr string to number
                   mov   si, word ptr ds:[si]
                   call  parseDigit
                   mov   cx, bp                           ; save second number in cx

                   cmp   cx, 10                           ; handle conversion error
                   je    error

                   mov   si, offset opPtr                 ; convert opPtr string to operation
                   mov   si, word ptr ds:[si]
                   
                   mov   di, offset plus                  ; addition
                   call  strcmp
                   cmp   bp, 0
                   je    addOp

                   mov   di, offset times                 ; multiplication
                   call  strcmp
                   cmp   bp, 0
                   je    mulOp

                   mov   di, offset minus                 ; subtraction
                   call  strcmp
                   cmp   bp, 0
                   je    subOp

                   jmp   error                            ; handle invalid operator error

       addOp:      
                   add   ax, cx                           ; ax = ax + cx
                   jmp   exit

       mulOp:      
                   mul   cx                               ; ax = ax * cx
                   jmp   exit

       subOp:      
                   sub   ax, cx                           ; ax = ax - cx
                   jmp   exit
  
       exit:       
                   mov   dx, offset resultMessage         ; print result
                   call  print
                   call  printNumber

                   mov   al, 0                            ; exit code 0
                   mov   ah, 4ch
                   int   21h

       error:      
                   mov   dx, offset errorMessage          ; print error
                   call  print

                   mov   al, 1                            ; exit code 1
                   mov   ah, 4ch
                   int   21h
main endp

strtok proc
       ; replaces the first encountered space with the end char ($), returns the pointer to char directly after it
       ; si - text address
       ; bp - returns the pointer to next token
       start:      
                   push  ax
                   push  si

       loop1:      
                   lodsb                                  ; load byte at SI into AL and increment SI
                   cmp   al, '$'
                   je    exit
                   cmp   al, ' '
                   je    replace
                   jmp   loop1

       replace:    
                   dec   si
                   mov   byte ptr ds:[si], '$'
                   inc   si

       exit:       
                   mov   bp, si                           ; return the result
                  
                   pop   si
                   pop   ax
                   ret
strtok endp

input proc
       ; runs the buffered input interrupt
       ; dx - buffer offset (first two bytes used for length)
       start:      
                   push  ax
                   mov   ah, 0ah
                   int   21h
                   pop   ax
                   ret
input endp

endl proc
       ; sets up ds with endlMessage for print
       start:      
                   push  dx
                   mov   dx, offset endlMessage
                   call  print
                   pop   dx
                   ret
endl endp

print proc
       ; runs the print interrupt
       ; dx - text offset
       start:      
                   push  ax
                   mov   ah, 09h
                   int   21h
                   pop   ax
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
                   lodsb
                   cmp   al, byte ptr ds:[di]
                   jne   notEqual

                   cmp   al, '$'
                   je    equal

                   inc   di
                   jmp   loops

       equal:      
                   mov   bp, 0
                   jmp   exit

       notEqual:   
                   mov   bp, 1

       exit:       
                   pop   di
                   pop   si
                   pop   ax
                   ret
strcmp endp

parseDigit proc
       ; si - digit string to convert (this is not di for consistency, explained below)
       ; bp - returns the digit as number (or 10 in case of conversion error)
       start:      
                   push  di
                   push  si
                   push  cx

                   mov   cx, 0                            ; offset digits starts from "zero"
                   mov   di, si                           ; strcmp compares both si and di, but i need to check all digits
                   mov   si, offset digits                ; strtok tokenizes the string from si, hence the swap
              
       loop1:      
                   call  strcmp
                   cmp   bp, 0
                   je    exit

                   call  strtok                           ; move si to the next string from offset digits
                   mov   si, bp

                   inc   cx                               ; check next number
              
                   cmp   cx, 10
                   jl    loop1                            ; any number < 10 is a valid digit, otherwise exit

       exit:       
                   mov   bp, cx                           ; return the result

                   pop   cx
                   pop   si
                   pop   di
                   ret
parseDigit endp

printNumber proc
       ; displays the number from ax using subtraction and recusion
       ; ax - number to be printed (both positive and negative) if abs(ax) < 100
       start:      
                   push  ax
                   push  cx
                   push  si
                   
                   cmp   ax, 0
                   jl    negative
                   
                   cmp   ax, 19                           ; for num >= 20 print the tens part first (liczba dziesiątek)
                   mov   si, offset tens
                   jg    loop10

                   mov   si, offset digits                ; for num < 20 print the entire number
                   jmp   loop1

       negative:   
                   mov   dx, offset minus                 ; print "minus "
                   call  print
                   mov   dx, offset space
                   call  print

                   mov   cx, -1                           ; multiply by -1, call function recursively
                   mul   cx
                   jmp   recur

       loop1:      
                   cmp   ax, 0                            ; if ax == 0 then print the number string (break condition)
                   je    output

                   call  strtok                           ; if it's not then use the next number string
                   mov   si, bp

                   dec   ax                               ; and decrement ax
                   jmp   loop1

       loop10:     
                   cmp   ax, 30                           ; if ax < 30 then print the tens part
                   jl    output                           ; this is because the tens part only needs to be printed for numbers > 20, offset tens begins with "dwadziescia"

                   call  strtok                           ; if it's not then use the next number string
                   mov   si, bp

                   sub   ax, 10                           ; ax = ax - 10
                   jmp   loop10

       output:     
                   mov   dx, si                           ; print whichever string loop1 or loop10 put in si
                   call  print
                   mov   dx, offset space
                   call  print

                   cmp   ax, 0                            ; ax == 0, loop1 already finished, nothing to do - return
                   je    exit

                   cmp   ax, 20                           ; ax == 20, loop10 already finished, no need to print the units part - return
                   je    exit

                   sub   ax, 20                           ; loop10 finished, but there is a digit in units part that need to be printed - recursive call

       recur:      
                   call  printNumber

       exit:       
                   pop   si
                   pop   cx
                   pop   ax
                   ret
printNumber endp

code1 ends

stack1 segment stack
       ; 256 bytes of stack and top of stack pointer
       s1     db 256 dup(?)
       s1top  db ?
stack1 ends

end main
