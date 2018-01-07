data segment
	io_address equ 210h	;8254
	io8255_a equ 200h	;8255
	io8255_b equ 201h 
	io8255_c equ 202h
	io8255_k equ 203h
	count db 0			;记录秒数
	portc1 db 0ch,14h,21h,22h	;通过增加状态字实现红绿灯与黄灯时间比例
	led db 3fh,06h,5bh,4fh,66h,6dh,7dh	;0-6
data ends
code segment
	assume cs:code,ds:data
start:    
    cli             ;关中断
	mov ax,data
	mov ds,ax                	
;-----------------8254初始化------------------
	call init_8254
;-----------------8255初始化------------------
	mov dx,io8255_k
	mov al,90h      ;PA输入，PC输出
	out dx,al  
;-----------------8259初始化------------------
	in al,21h
    and al,11011011b    		;开放主片MIR5中断
    out 21h,al  
    in al,0A1h
    and al,11111110b    		;开放从片IR0中断
    out 0A1h,al  
;----------------设置中断向量表----------------
	push ds
	mov ax,0
	mov ds,ax
;----------------设置MIR5对应的中断向量-----------
	lea ax,cs:int_proc1
	mov si,35h
	add si,si
	add si,si
	mov ds:[si],ax			;偏移量
	push cs
	pop ax
	mov ds:[si+2],ax		;段地址	
;---------------设置SIR0对应的中断向量-----------
	lea ax,cs:int_proc2
	mov si,70h
	add si,si
	add si,si
	mov ds:[si],ax
	push cs
	pop ax
	mov ds:[si+2],ax
	pop ds
	sti
;-------------主程序-----------------
led_reon:
	mov si,0
	jmp go
ddd:
	mov dx,io8255_a
	in al,dx
	and al,01h			;al=0表明out1=0
	jnz ddd
	cmp count,0
	je led_reon
go:
	inc count			;每过5s对应一个区间
	jmp chack0
on:
	mov dx,io8255_c		;pc输出对应led灯管
	mov al,portc1[bx]
	out dx,al
	mov dx,io8255_b		;pb输出对应数码管的位码
	mov al,led[si]		;数码管输出，对应的字型码
	out dx,al
	dec si				;循环一次对应减一
lop:
	mov dx,io8255_a		;耗时1s
	in al,dx
	and al,01h
	jz lop
	jmp ddd
chack0:
	cmp count,5	;判断进行了几秒
	ja chack1
	mov bx,0	;红绿灯状态字0
	cmp si,1	;si=1说明是第一次赋值
	jb led1
	jmp on
chack1:
	cmp count,7
	ja chack2
	mov bx,1
	cmp si,1
	jb led2
	jmp on
chack2:
	cmp count,15
	ja chack3
	mov bx,2
	cmp si,1
	jb led3
	jmp on
chack3:
	mov bx,3
	cmp count,19
	jae re_on	;大于上界说明一次循环完成
	cmp si,1
	jb led4
	jmp on
led1:
	mov si,5	;计时2s
	jmp on
led2:
	mov si,2	
	jmp on
led3:
	mov si,8
	jmp on
led4:
	mov si,4
	jmp on
re_on:
	mov count,0
	jmp on
	
	
;----------------初始化8254---------------
init_8254 proc 
	mov dx,io_address
	add dx,3
	mov al,00110111b
	out dx,al
	mov dx,io_address
	mov al,0
	out dx,al
	out dx,al		;1Mhz/10000=100hz
	mov dx,io_address
	add dx,3
	mov al,01110101b;
	out dx,al
	mov dx,io_address
	inc dx
	mov al,00h		
	out dx,al
	mov al,05h		;out1(PA)输出脉冲5s
	out dx,al
	mov dx,io_address+3
	mov al,10110101b
	out dx,al
	mov dx,io_address+2
	mov al,00h
	out dx,al
	mov al,01h
	out dx,al 		;out2(PB)输出脉冲1s
	ret
init_8254 endp    
;---------------中断子程序1---------------
int_proc1 proc
    push bx
    push dx
    mov dx,io8255_c
    mov al,0ch	;主干道绿灯
	out dx,al
	mov cx,1000
de1:
	mov di,2000
de0:
	dec di
	jnz de0
	loop de1
	mov al,20h	
	out 20h,al
	pop dx
	pop bx
	sti
	iret
int_proc1 endp
;---------------中断子程序2---------------
int_proc2 proc
	push bx
	push dx
	mov dx,io8255_c
	mov al,21h	;支线绿灯
	out dx,al
	mov cx,1000
de2:
	mov di,2000
de3:
	dec di
	jnz de3
	loop de2
	mov al,20h
	out 20h,al
	mov al,20h
	out 0A0h,al ;发送中断命令(向386EX从8259的SIR0)
	pop dx
	pop bx
	sti
	iret
int_proc2 endp
	
code ends
end start