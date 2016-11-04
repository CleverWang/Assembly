DATA SEGMENT
	INFO1 DB 0DH,0AH,10 DUP(' '),'24 POINTS GAME','$'
	INFO2 DB 0DH,0AH,'1.Only Use The 4 Random Numbers','$'
	INFO3 DB 0DH,0AH,'2.Only Use +,-,*,/,(,)','$'
	INFO4 DB 0DH,0AH,31 DUP('-'),'$'
	;TEXT1 DB 0DH,0AH,'Please Input The Playtime:','$'
	TEXT2 DB 0DH,0AH,'Here Are Four Numbers:','$'
	TEXT3 DB 0DH,0AH,'Please Input Your Solution:','$'
	TEXT4 DB 0DH,0AH,'Great!You Win The Game! :)','$'
	TEXT5 DB 0DH,0AH,'Wrong Solution!','$'
	;TEXT6 DB 0DH,0AH,'Sorry,You Lost The Game! :(','$'
	ENTERTEXT DB 0DH,0AH,'$'
	EXPREESION DB 20,0,20 DUP(?)
	FRONTQUEUE DB 20 DUP(?)
	FOURNUM DB 4 DUP(?)
	PLAYTIME DB 0
DATA ENDS

STACK SEGMENT 
	DB 20 DUP(0)
STACK ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:STACK
	
	MAIN PROC FAR
	START:
		MOV AX,DATA
		MOV DS,AX
		LEA DX,INFO1			;显示INFO1
		MOV AH,09H
		INT 21H	
		LEA DX,INFO2			;显示INFO2
		MOV AH,09H
		INT 21H	
		LEA DX,INFO3			;显示INFO3
		MOV AH,09H
		INT 21H	
		LEA DX,INFO4			;显示INFO4
		MOV AH,09H
		INT 21H
		
		;LEA DX,TEXT1			;显示TEXT1
		;MOV AH,09H
		;INT 21H
		;MOV AH,1
		;INT 21H
		;SUB AL,30H
		;MOV BH,AL				;保存高位s
		;MOV AH,1
		;INT 21H
		;SUB AL,30H
		;MOV BL,AL				;保存低位s
		;MOV AL,BH
		;MOV	CL,0AH
		;MUL CL
		;XOR BH,BH
		;ADD AX,BX				;获得playtime
		;LEA BX,PLAYTIME
		;MOV [BX],AL
	
		LEA DI,FOURNUM			;获取FOURNUM的偏移地址
		MOV AX,4				;4个数是否生成完毕的标志
		CALL RAND				;调用RAND函数
		MOV [DI],BL				;将产生的第一个随机数存入FOURNUM第一个位置
		MOV BH,BL				;保存随机数，用于和下一个随机数比较
		INC DI					;FOURNUM的偏移地址加一
		
	GENERATE:					;产生4个不全相同的随机数
		CALL RAND
		CMP BH,BL				
		JE GENERATE				;判断新的随机数是否和之前的一样，防止生成4个一样的随机数
		MOV [DI],BL				;将新的随机数保存
		MOV BH,BL				
		INC DI
		DEC AX					;保存一个新的随机数后，标志减一
		JNE GENERATE			;判断4个数是否生成完毕
		LEA DX,TEXT2			;显示TEXT2
		MOV AH,09H
		INT 21H					
		LEA BX,FOURNUM
		MOV CX,4
		
	DISPLAY:					;显示生成的4个数，以空格隔开
		MOV DL,[BX]
		MOV AH,2
		INT 21H
		MOV DL,20H				;输出空格
		MOV AH,2
		INT 21H
		INC BX
		LOOP DISPLAY
			
	INPUT:
		;判断时间是否到了
		LEA DX,TEXT3			;显示TEXT3
		MOV AH,09H
		INT 21H		
		LEA DX,EXPREESION		;输入表达式
		MOV AH,0AH
		INT 21H
		LEA BX,EXPREESION		
		MOV AH,[BX+1]			;获取EXPRESSION的长度
		INC BX
		XOR DX,DX				;DX清零
		
	;判断输入的表达式是否合法
	LINE:
		INC BX
		CMP AH,0				;判断所有字符是否检查完毕
		JE LINEOVER
		MOV AL,[BX]
		CMP AL,'1'
		JB LINE1
		CMP AL,'9'
		JA TTOVER
		MOV SI,4
		LEA DI,FOURNUM
		
	JUDGE:						;判断输入的数字字符是否是生成的4个数
		CMP SI,0
		JE TTOVER
		MOV CL,[DI]
		CMP AL,CL
		JE ISNUM
		DEC SI
		INC DI
		JMP JUDGE
		
	ISNUM:
		DEC AH
		JMP LINE
	
	LINE1:						;判断字符是不是+
		CMP AL,'+'
		JNE LINE2
		DEC AH
		JMP LINE
		
	LINE2:						;判断字符是不是-
		CMP AL,'-'
		JNE LINE3
		DEC AH
		JMP LINE
		
	LINE3:						;判断字符是不是*
		CMP AL,'*'
		JNE LINE4
		DEC AH
		JMP LINE
		
	LINE4:						;判断字符是不是/
		CMP AL,'/'
		JNE LINE5
		DEC AH
		JMP LINE
		
	LINE5:						;判断字符是不是（
		CMP AL,'('
		JNE LINE6
		INC DL
		DEC AH
		JMP LINE
		
	LINE6:						;判断字符是不是）
		CMP AL,')'
		JNE TEMPOVER
		INC DH
		DEC AH
		JMP LINE
		
	TTOVER:
		JMP TEMPOVER
		
	LINEOVER:					;判断（）是否匹配
		CMP DH,DL
		JNE TEMPOVER
		
		;判断时间是否到了
		
		LEA BX,EXPREESION
		MOV DL,[BX+1]			;取表达式的长度值
		XOR DH,DH
		ADD BX,DX
		INC BX					;表达式最后一个字符偏移地址
		LEA SI,FRONTQUEUE		;取前序表达式序列偏移地址
		
	CYCLE:
		LEA CX,EXPREESION
		INC CX
		CMP CX,BX				;判断字符是否取完
		JE LAST
		MOV AL,[BX]				;取表达式一个字符
		CMP AL,30H				;判断是否小于0
		JB RIGHTPARENTHESE		;小于0说明是操作符
		MOV [SI],AL				;是操作数，存入前序表达式序列
		INC SI					;前序表达式序列偏移地址加一
		DEC BX					;取前一个字符偏移地址
		JMP CYCLE
		
	RIGHTPARENTHESE:
		CMP AL,29H				;判断是否是）
		JNE OP
		XOR AH,AH
		PUSH AX					;是），入栈
		DEC BX					;取前一个字符偏移地址
		JMP CYCLE
		
	OP:
		CMP AL,28H				;判断是否是（
		JE LEFTPARENTHESE
		CMP SP,0000H			;判断栈是否为空
		JNE TOPRIGHT
		XOR AH,AH
		PUSH AX					;栈为空，运算符进栈
		DEC BX
		JMP CYCLE
		
	TOPRIGHT:
		POP DX					;取栈顶
		CMP DL,29H				;判断栈顶是否是）
		PUSH DX
		JNE HIGHPRO				;栈顶不是）
		XOR AH,AH
		PUSH AX					;栈顶是），操作符进栈
		DEC BX					;取前一个字符偏移地址
		JMP CYCLE
		
	HIGHPRO:
		CMP AL,2AH				;判断操作符是不是*
		JNE ISDIV				;不是*，去判断是不是/
		XOR AH,AH
		PUSH AX					;是*，进栈
		DEC BX					;取前一个字符偏移地址
		JMP CYCLE
		
	TEMPOVER:
		JMP OVER
	
	ISDIV:
		CMP AL,2EH				;判断操作符是不是/
		JNE SAMEADD				;不是/，去判断是不是同级
		XOR AH,AH
		PUSH AX					;是/，进栈
		DEC BX					;取前一个字符偏移地址
		JMP CYCLE
		
	SAMEADD:
		CMP DL,2BH				;判断栈顶是不是+
		JNE SAMEMINUS			;不是+，去判断是不是-
		XOR AH,AH
		PUSH AX					;是+，进栈
		DEC BX					;取前一个字符偏移地址
		JMP CYCLE
		
	SAMEMINUS:
		CMP DL,2DH				;判断栈顶是不是-
		JNE POPOUT				;不是-，去出栈
		XOR AH,AH
		PUSH AX					;是-，进栈
		DEC BX					;取前一个字符偏移地址
		JMP CYCLE
		
	POPOUT:
		POP CX					;操作符出栈
		MOV [SI],CL				;输出到前序表达式序列
		INC SI
		JMP OP
		
	LEFTPARENTHESE:
		POP CX					;连续出栈
		CMP CL,29H				;判断是否遇到）
		JE BACK
		MOV [SI],CL				;输出到前序表达式序列
		INC SI
		JMP LEFTPARENTHESE
	
	BACK:
		DEC BX
		JMP CYCLE
		
	LAST:
		POP CX					;全部出栈
		CMP SP,0002H			;判断出栈是否完毕
		JE DONE					;出栈完毕
		MOV [SI],CL				;输出到前序表达式序列
		INC SI
		JMP LAST
	
	DONE:
		;LEA DX,ENTERTEXT		;输出换行
		;MOV AH,09H
		;INT 21H	
		MOV BYTE PTR [SI],24H	;为前序表达式末尾添加$
		;LEA DX,FRONTQUEUE		;显示前序表达式
		;MOV AH,09H
		;INT 21H	
		MOV AX,0000H			
		PUSH AX					;使SP值为0
		LEA BX,FRONTQUEUE		;取前序表达式序列偏移地址
		
	IS24POINTS:
		MOV AL,[BX]
		CMP AL,24H				;判断是否计算结束
		JE RESLUT
		CMP AL,30H				;判断是否是操作数
		JB ISPLUS				;不是操纵数，去判断是否是+
		SUB AL,30H				;将ASCII码转换成十进制数字
		XOR AH,AH
		PUSH AX					;将操作数入栈
		INC BX					;前序表达式序列偏移地址指向下一个字符
		JMP IS24POINTS
		
	ISPLUS:
		CMP AL,2BH
		JNE ISMINUS				;不是+，去判断是不是-
		POP AX
		POP CX
		ADD AX,CX				;出栈两个操作数，做加法
		PUSH AX					;结果入栈
		INC BX					;前序表达式序列偏移地址指向下一个字符
		JMP IS24POINTS
		
	ISMINUS:
		CMP AL,2DH
		JNE ISMULTIPLY			;不是-，去判断是不是*
		POP AX
		POP CX
		SUB AX,CX				;出栈两个操作数，做减法
		PUSH AX					;结果入栈
		INC BX					;前序表达式序列偏移地址指向下一个字符
		JMP IS24POINTS
		
	ISMULTIPLY:
		CMP AL,2AH
		JNE ISDIVIDE			;不是*，去判断是不是/
		POP AX
		POP CX
		IMUL CL					;出栈两个操作数，做带符号数的乘法
		PUSH AX					;结果入栈
		INC BX					;前序表达式序列偏移地址指向下一个字符
		JMP IS24POINTS
	
	ISDIVIDE:
		POP AX
		POP CX
		IDIV CL					;出栈两个操作数，做带符号数的除法
		PUSH AX					;结果入栈
		INC BX					;前序表达式序列偏移地址指向下一个字符
		JMP IS24POINTS
		
	RESLUT:
		;LEA DX,ENTERTEXT		;输出换行
		;MOV AH,09H
		;INT 21H	
		POP DX
		ADD DL,30H
		;MOV AH,02H
		;INT 21H
		;MOV DX,SP
		;ADD DL,30H
		;MOV AH,02H
		;INT 21H
		CMP DL,48H
		JNE OVER
		LEA DX,TEXT4
		MOV AH,09H
		INT 21H	
		JMP FINISH
		
	OVER:
		LEA DX,TEXT5
		MOV AH,09H
		INT 21H		
		JMP INPUT
		
	FINISH:
		MOV AH,4CH				;返回DOS
		INT 21H
	MAIN ENDP
	
	RAND PROC
		PUSH CX
        PUSH DX
        PUSH AX
        STI
        MOV AH, 0                ;读时钟计数器值
        INT 1AH
        MOV AX, DX            
        XOR AX, 9                ;异或
        AND AH, 3                ;清高6位
        MOV DL, 9                ;除9，产生0~8余数
        DIV DL
        MOV BL, AH               ;余数存BL，作随机数
        ADD BL, 31H     		 ;加31H，生成1~9的ASCII码
	    POP AX
        POP DX
        POP CX
        RET
	RAND ENDP
	
CODE ENDS
		END START