	.text
# _buffer_init:
# 	li $a0, 256
# 	li $v0, 9
# 	syscall
# 	sw $v0, _buffer
# 	jr $ra

# copy the string in $a0 to buffer in $a1, with putting '\0' in the end of the buffer
###### Checked ######
# used $v0, $a0, $a1
_string_copy:
	_begin_string_copy:
	lb $v0, 0($a0)
	beqz $v0, _exit_string_copy
	sb $v0, 0($a1)
	add $a0, $a0, 1
	add $a1, $a1, 1
	j _begin_string_copy
	_exit_string_copy:
	sb $zero, 0($a1)
	jr $ra

# string arg in $a0
###### Checked ######
# Change(5/4): you don't need to preserve reg before calling it
func__print:
	li $v0, 4
	syscall
	jr $ra

# string arg in $a0
###### Checked ######
# Change(5/4): you don't need to preserve reg before calling it
func__println:
	li $v0, 4
	syscall
	la $a0, _end
	syscall
	jr $ra

# count the length of given string in $a0
###### Checked ######
# used $v0, $v1, $a0
_count_string_length:
	move $v0, $a0

	_begin_count_string_length:
	lb $v1, 0($a0)
	beqz $v1, _exit_count_string_length
	add $a0, $a0, 1
	j _begin_count_string_length

	_exit_count_string_length:
	sub $v0, $a0, $v0
	jr $ra

# non arg, string in $v0
###### Checked ######
# used $a0, $a1, $t0, $v0, (used in _count_string_length) $v1
func__getString:
	subu $sp, $sp, 4
	sw $ra, 0($sp)

	la $a0, _buffer
	li $a1, 255
	li $v0, 8
	syscall

	jal _count_string_length

	move $a1, $v0			# now $a1 contains the length of the string
	add $a0, $v0, 5			# total required space = length + 1('\0') + 1 word(record the length of the string)
	li $v0, 9
	syscall
	sw $a1, 0($v0)
	add $v0, $v0, 4
	la $a0, _buffer
	move $a1, $v0
	move $t0, $v0
	jal _string_copy
	move $v0, $t0

	lw $ra, 0($sp)
	addu $sp, $sp, 4
	jr $ra

# non arg, int in $v0
###### Checked ######
# Change(5/4): you don't need to preserve reg before calling it
func__getInt:
	li $v0, 5
	syscall
	jr $ra

# int arg in $a0
###### Checked ######
# Bug fixed(5/2): when the arg is a neg number
# Change(5/4): use less regs, you don't need to preserve reg before calling it
# used $v0, $v1
func__toString:
	subu $sp, $sp, 24
	sw $a0, 0($sp)
	sw $t0, 4($sp)
	sw $t1, 8($sp)
	sw $t2, 12($sp)
	sw $t3, 16($sp)
	sw $t5, 20($sp)

	# first count the #digits
	li $t0, 0			# $t0 = 0 if the number is a negnum
	bgez $a0, _skip_set_less_than_zero
	li $t0, 1			# now $t0 must be 1
	neg $a0, $a0
	_skip_set_less_than_zero:
	beqz $a0, _set_zero

	li $t1, 0			# the #digits is in $t1
	move $t2, $a0
	move $t3, $a0
	li $t5, 10

	_begin_count_digit:
	div $t2, $t5
	mflo $v0			# get the quotient
	mfhi $v1			# get the remainder
	bgtz $v0 _not_yet
	bgtz $v1 _not_yet
	j _yet
	_not_yet:
	add $t1, $t1, 1
	move $t2, $v0
	j _begin_count_digit

	_yet:
	beqz $t0, _skip_reserve_neg
	add $t1, $t1, 1
	_skip_reserve_neg:
	add $a0, $t1, 5
	li $v0, 9
	syscall
	sw $t1, 0($v0)
	add $v0, $v0, 4
	add $t1, $t1, $v0
	sb $zero, 0($t1)
	sub $t1, $t1, 1

	_continue_toString:
	div $t3, $t5
	mfhi $v1
	add $v1, $v1, 48	# in ascii 48 = '0'
	sb $v1, 0($t1)
	sub $t1, $t1, 1
	mflo $t3
	# bge $t1, $v0, _continue_toString
	bnez $t3, _continue_toString

	beqz $t0, _skip_place_neg
	li $v1, 45
	sb $v1, 0($t1)
	_skip_place_neg:
	# lw $ra, 0($sp)
	# addu $sp, $sp, 4

	lw $a0, 0($sp)
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	lw $t2, 12($sp)
	lw $t3, 16($sp)
	lw $t5, 20($sp)

	addu $sp, $sp, 24
	jr $ra

	_set_zero:
	li $a0, 6
	li $v0, 9
	syscall
	li $a0, 1
	sw $a0, 0($v0)
	add $v0, $v0, 4
	li $a0, 48
	sb $a0, 0($v0)

	lw $a0, 0($sp)
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	lw $t2, 12($sp)
	lw $t3, 16($sp)
	lw $t5, 20($sp)

	addu $sp, $sp, 24
	jr $ra


# string arg in $a0
# the zero in the end of the string will not be counted
###### Checked ######
# you don't need to preserve reg before calling it
func__length:
	lw $v0, -4($a0)
	jr $ra

# string arg in $a0, left in $a1, right in $a2
###### Checked ######
# used $a0, $a1, $t0, $t1, $t2, $v1, $v0
func__substring:
	subu $sp, $sp, 4
	sw $ra, 0($sp)

	move $t0, $a0

	sub $t1, $a2, $a1
	add $t1, $t1, 1		# $t1 is the length of the substring
	add $a0, $t1, 5
	li $v0, 9
	syscall
	sw $t1, 0($v0)
	add $v1, $v0, 4

	add $a0, $t0, $a1
	add $t2, $t0, $a2
	lb $t1, 1($t2)		# store the ori_begin + right + 1 char in $t1
	sb $zero, 1($t2)	# change it to 0 for the convenience of copying
	move $a1, $v1
	jal _string_copy
	move $v0, $v1
	sb $t1, 1($t2)

	lw $ra, 0($sp)
	addu $sp, $sp, 4
	jr $ra

# string arg in
###### Checked ######
# 16/5/4 Fixed a serious bug: can not parse negtive number
# used $v0, $v1
func__parseInt:
	subu $sp, $sp, 16
	sw $a0, 0($sp)
	sw $t0, 4($sp)
	sw $t1, 8($sp)
	sw $t2, 12($sp)

	li $v0, 0

	lb $t1, 0($a0)
	li $t2, 45
	bne $t1, $t2, _skip_parse_neg
	li $t1, 1			#if there is a '-' sign, $t1 = 1
	add $a0, $a0, 1
	j _skip_set_t1_zero

	_skip_parse_neg:
	li $t1, 0
	_skip_set_t1_zero:
	move $t0, $a0
	li $t2, 1

	_count_number_pos:
	lb $v1, 0($t0)
	bgt $v1, 57, _begin_parse_int
	blt $v1, 48, _begin_parse_int
	add $t0, $t0, 1
	j _count_number_pos

	_begin_parse_int:
	sub $t0, $t0, 1

	_parsing_int:
	blt $t0, $a0, _finish_parse_int
	lb $v1, 0($t0)
	sub $v1, $v1, 48
	mul $v1, $v1, $t2
	add $v0, $v0, $v1
	mul $t2, $t2, 10
	sub $t0, $t0, 1
	j _parsing_int

	_finish_parse_int:
	beqz $t1, _skip_neg
	neg $v0, $v0
	_skip_neg:

	lw $a0, 0($sp)
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	lw $t2, 12($sp)
	addu $sp, $sp, 16
	jr $ra

# string arg in $a0, pos in $a1
###### Checked ######
# used $v0, $v1
func__ord:
	add $v1, $a0, $a1
	lb $v0, 0($v1)
	jr $ra

# array arg in $a0
# used $v0
func__size:
	lw $v0, -4($a0)
	jr $ra

# string1 in $a0, string2 in $a1
###### Checked ######
# change(16/5/4): use less regs, you don't need to preserve reg before calling it
# used $v0, $v1
func__stringConcatenate:

	subu $sp, $sp, 24
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $t0, 12($sp)
	sw $t1, 16($sp)
	sw $t2, 20($sp)

	lw $t0, -4($a0)		# $t0 is the length of lhs
	lw $t1, -4($a1)		# $t1 is the length of rhs
	add $t2, $t0, $t1

	move $t1, $a0

	add $a0, $t2, 5
	li $v0, 9
	syscall

	sw $t2, 0($v0)
	move $t2, $a1

	add $v0, $v0, 4
	move $v1, $v0

	move $a0, $t1
	move $a1, $v1
	jal _string_copy

	move $a0, $t2
	add $a1, $v1, $t0
	# add $a1, $a1, 1
	jal _string_copy

	move $v0, $v1
	lw $ra, 0($sp)
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	lw $t0, 12($sp)
	lw $t1, 16($sp)
	lw $t2, 20($sp)
	addu $sp, $sp, 24
	jr $ra

# string1 in $a0, string2 in $a1
###### Checked ######
# change(16/5/4): use less regs, you don't need to preserve reg before calling it
# used $a0, $a1, $v0, $v1
func__stringIsEqual:
	# subu $sp, $sp, 8
	# sw $a0, 0($sp)
	# sw $a1, 4($sp)

	lw $v0, -4($a0)
	lw $v1, -4($a1)
	bne $v0, $v1, _not_equal

	_continue_compare_equal:
	lb $v0, 0($a0)
	lb $v1, 0($a1)
	beqz $v0, _equal
	bne $v0, $v1, _not_equal
	add $a0, $a0, 1
	add $a1, $a1, 1
	j _continue_compare_equal

	_not_equal:
	li $v0, 0
	j _compare_final

	_equal:
	li $v0, 1

	_compare_final:
	# lw $a0, 0($sp)
	# lw $a1, 4($sp)
	# addu $sp, $sp, 8
	jr $ra


# string1 in $a0, string2 in $a1
###### Checked ######
# change(16/5/4): use less regs, you don't need to preserve reg before calling it
# used $a0, $a1, $v0, $v1
func__stringLess:
	# subu $sp, $sp, 8
	# sw $a0, 0($sp)
	# sw $a1, 4($sp)

	_begin_compare_less:
	lb $v0, 0($a0)
	lb $v1, 0($a1)
	blt $v0, $v1, _less_correct
	bgt $v0, $v1, _less_false
	beqz $v0, _less_false
	add $a0, $a0, 1
	add $a1, $a1, 1
	j _begin_compare_less

	_less_correct:
	li $v0, 1
	j _less_compare_final

	_less_false:
	li $v0, 0

	_less_compare_final:

	# lw $a0, 0($sp)
	# lw $a1, 4($sp)
	# addu $sp, $sp, 8
	jr $ra

# string1 in $a0, string2 in $a1
# used $a0, $a1, $v0, $v1
func__stringLarge:
	subu $sp, $sp, 4
	sw $ra, 0($sp)

	jal func__stringLess

	xor $v0, $v0, 1

	lw $ra, 0($sp)
	addu $sp, $sp, 4
	jr $ra

# string1 in $a0, string2 in $a1
# used $a0, $a1, $v0, $v1
func__stringLeq:
	subu $sp, $sp, 12
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)

	jal func__stringLess

	bnez $v0, _skip_compare_equal_in_Leq

	lw $a0, 4($sp)
	lw $a1, 8($sp)
	jal func__stringIsEqual

	_skip_compare_equal_in_Leq:
	lw $ra, 0($sp)
	addu $sp, $sp, 12
	jr $ra

# string1 in $a0, string2 in $a1
# used $a0, $a1, $v0, $v1
func__stringGeq:
	subu $sp, $sp, 12
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)

	jal func__stringLess

	beqz $v0, _skip_compare_equal_in_Geq

	lw $a0, 4($sp)
	lw $a1, 8($sp)
	jal func__stringIsEqual
	xor $v0, $v0, 1

	_skip_compare_equal_in_Geq:
	xor $v0, $v0, 1
	lw $ra, 0($sp)
	addu $sp, $sp, 12
	jr $ra

# string1 in $a0, string2 in $a1
# used $a0, $a1, $v0, $v1
func__stringNeq:
	subu $sp, $sp, 4
	sw $ra, 0($sp)

	jal func__stringIsEqual

	xor $v0, $v0, 1

	lw $ra, 0($sp)
	addu $sp, $sp, 4
	jr $ra
_origin:
	sub $sp, $sp, 200
	sw $t2, 40($sp)
	sw $t3, 44($sp)
_BeginOfFunctionDecl38:
	lw $t0, 196($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 152($sp)
	lw $t0, 152($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 152($sp)
	lw $a0, 152($sp)
	li $v0, 9
	syscall
	sw $v0, 184($sp)
	lw $t0, 196($sp)
	lw $t1, 184($sp)
	sw $t0, 0($t1)
	lw $t0, 184($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 184($sp)
	lw $t0, 184($sp)
	sw $t0, 140($sp)
	lw $t0, 140($sp)
	sw $t0, global_27
	li $t0, 0
	sw $t0, global_19
_ForLoop48:
	lw $t0, global_19
	lw $t1, 196($sp)
	slt $t1, $t0, $t1
	sw $t1, 188($sp)
	lw $t0, 188($sp)
	beqz $t0, _OutOfFor1
_ForBody0:
	lw $t0, global_19
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 144($sp)
	lw $t0, global_27
	lw $t1, 144($sp)
	add $t2, $t0, $t1
	lw $t0, 196($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 148($sp)
	lw $t0, 148($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 148($sp)
	lw $a0, 148($sp)
	li $v0, 9
	syscall
	sw $v0, 180($sp)
	lw $t0, 196($sp)
	lw $t1, 180($sp)
	sw $t0, 0($t1)
	lw $t0, 180($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 180($sp)
	lw $t0, 180($sp)
	move $t3, $t0
	sw $t3, 0($t2)
	li $t0, 0
	sw $t0, global_20
_ForLoop50:
	lw $t0, global_20
	lw $t1, 196($sp)
	slt $t1, $t0, $t1
	sw $t1, 156($sp)
	lw $t0, 156($sp)
	beqz $t0, _OutOfFor3
_ForBody2:
	lw $t0, global_19
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 192($sp)
	lw $t0, global_27
	lw $t1, 192($sp)
	add $t1, $t0, $t1
	sw $t1, 176($sp)
	lw $t1, 176($sp)
	lw $t0, 0($t1)
	sw $t0, 132($sp)
	lw $t0, global_20
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, 132($sp)
	add $t1, $t0, $t2
	sw $t1, 168($sp)
	li $t0, 0
	lw $t1, 168($sp)
	sw $t0, 0($t1)
_continueFor51:
	lw $t0, global_20
	sw $t0, 172($sp)
	lw $t0, global_20
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_20
	b _ForLoop50
_OutOfFor3:
	b _continueFor49
_continueFor49:
	lw $t0, global_19
	sw $t0, 136($sp)
	lw $t0, global_19
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_19
	b _ForLoop48
_OutOfFor1:
	b _EndOfFunctionDecl39
_EndOfFunctionDecl39:
	lw $t2, 40($sp)
	lw $t3, 44($sp)
	add $sp, $sp, 200
	jr $ra
_getPrime:
	sub $sp, $sp, 252
	sw $t2, 40($sp)
	sw $t4, 48($sp)
	sw $t3, 44($sp)
_BeginOfFunctionDecl40:
	li $t0, 2
	sw $t0, 144($sp)
	li $t0, 2
	move $t4, $t0
_ForLoop52:
	lw $t1, 248($sp)
	sle $t2, $t4, $t1
	beqz $t2, _OutOfFor5
_ForBody4:
	li $t1, 4
	mul $t2, $t4, $t1
	lw $t0, global_23
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	li $t1, 1
	seq $t2, $t2, $t1
	beqz $t2, _alternative7
_consequence6:
	li $t0, 0
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_26
	add $t3, $t0, $t2
	li $t0, 0
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_26
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	li $t1, 1
	add $t2, $t2, $t1
	sw $t2, 0($t3)
	li $t0, 0
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_26
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	li $t1, 4
	mul $t2, $t2, $t1
	lw $t0, global_24
	add $t2, $t0, $t2
	sw $t4, 0($t2)
	li $t1, 4
	mul $t2, $t4, $t1
	lw $t0, global_25
	add $t3, $t0, $t2
	li $t0, 0
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_26
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	sw $t2, 0($t3)
	b _OutOfIf8
_alternative7:
	b _OutOfIf8
_OutOfIf8:
	b _WhileLoop54
_WhileLoop54:
	lw $t1, 144($sp)
	mul $t2, $t4, $t1
	lw $t1, 248($sp)
	sle $t2, $t2, $t1
	beqz $t2, _OutOfWhile10
_WhileBody9:
	lw $t1, 144($sp)
	mul $t2, $t4, $t1
	li $t1, 4
	mul $t2, $t2, $t1
	lw $t0, global_23
	add $t2, $t0, $t2
	li $t0, 0
	sw $t0, 0($t2)
	lw $t0, 144($sp)
	li $t1, 1
	add $t2, $t0, $t1
	sw $t2, 144($sp)
	b _WhileLoop54
_OutOfWhile10:
	li $t0, 2
	sw $t0, 144($sp)
_continueFor53:
	li $t1, 1
	add $t2, $t4, $t1
	move $t4, $t2
	b _ForLoop52
_OutOfFor5:
	b _EndOfFunctionDecl41
_EndOfFunctionDecl41:
	lw $t2, 40($sp)
	lw $t4, 48($sp)
	lw $t3, 44($sp)
	add $sp, $sp, 252
	jr $ra
_getResult:
	sub $sp, $sp, 404
	sw $t2, 40($sp)
	sw $t4, 48($sp)
	sw $t3, 44($sp)
	sw $ra, 120($sp)
_BeginOfFunctionDecl42:
	lw $t0, 396($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 384($sp)
	lw $t0, global_27
	lw $t1, 384($sp)
	add $t1, $t0, $t1
	sw $t1, 264($sp)
	lw $t1, 264($sp)
	lw $t2, 0($t1)
	lw $t0, 400($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 380($sp)
	lw $t1, 380($sp)
	add $t2, $t2, $t1
	li $t0, 1
	neg $t1, $t0
	sw $t1, 260($sp)
	lw $t2, 0($t2)
	lw $t1, 260($sp)
	seq $t1, $t2, $t1
	sw $t1, 252($sp)
	lw $t0, 252($sp)
	beqz $t0, _alternative12
_consequence11:
	lw $t0, 400($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 360($sp)
	lw $t0, global_24
	lw $t1, 360($sp)
	add $t1, $t0, $t1
	sw $t1, 240($sp)
	lw $t1, 240($sp)
	lw $t0, 0($t1)
	sw $t0, 208($sp)
	lw $t0, 208($sp)
	li $t1, 2
	mul $t2, $t0, $t1
	lw $t0, 396($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 344($sp)
	lw $t0, global_24
	lw $t1, 344($sp)
	add $t3, $t0, $t1
	lw $t3, 0($t3)
	sub $t1, $t2, $t3
	sw $t1, 268($sp)
	lw $t0, 268($sp)
	lw $t1, 392($sp)
	sle $t1, $t0, $t1
	sw $t1, 148($sp)
	lw $t0, 148($sp)
	beqz $t0, _alternative15
_consequence14:
	lw $t0, 400($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 280($sp)
	lw $t0, global_24
	lw $t1, 280($sp)
	add $t1, $t0, $t1
	sw $t1, 324($sp)
	lw $t1, 324($sp)
	lw $t0, 0($t1)
	sw $t0, 348($sp)
	lw $t0, 348($sp)
	li $t1, 2
	mul $t2, $t0, $t1
	lw $t0, 396($sp)
	li $t1, 4
	mul $t3, $t0, $t1
	lw $t0, global_24
	add $t3, $t0, $t3
	lw $t0, 0($t3)
	sw $t0, 212($sp)
	lw $t1, 212($sp)
	sub $t1, $t2, $t1
	sw $t1, 168($sp)
	lw $t0, 168($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 136($sp)
	lw $t0, global_23
	lw $t1, 136($sp)
	add $t1, $t0, $t1
	sw $t1, 352($sp)
	lw $t1, 352($sp)
	lw $t0, 0($t1)
	sw $t0, 188($sp)
	lw $t0, 188($sp)
	li $t1, 0
	sne $t1, $t0, $t1
	sw $t1, 244($sp)
	lw $t0, 244($sp)
	beqz $t0, _alternative18
_consequence17:
	lw $t0, 396($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 304($sp)
	lw $t0, global_27
	lw $t1, 304($sp)
	add $t1, $t0, $t1
	sw $t1, 316($sp)
	lw $t1, 316($sp)
	lw $t0, 0($t1)
	sw $t0, 364($sp)
	lw $t0, 400($sp)
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, 364($sp)
	add $t2, $t0, $t2
	lw $t0, 400($sp)
	li $t1, 4
	mul $t3, $t0, $t1
	lw $t0, global_24
	add $t1, $t0, $t3
	sw $t1, 248($sp)
	lw $t1, 248($sp)
	lw $t3, 0($t1)
	li $t1, 2
	mul $t4, $t3, $t1
	lw $t0, 396($sp)
	li $t1, 4
	mul $t3, $t0, $t1
	lw $t0, global_24
	add $t3, $t0, $t3
	lw $t3, 0($t3)
	sub $t3, $t4, $t3
	li $t1, 4
	mul $t3, $t3, $t1
	lw $t0, global_25
	add $t3, $t0, $t3
	lw $t0, 0($t3)
	sw $t0, 388($sp)
	lw $t0, 392($sp)
	sw $t0, -12($sp)
	lw $t0, 400($sp)
	sw $t0, -8($sp)
	lw $t0, 388($sp)
	sw $t0, -4($sp)
	jal _getResult
	move $t3, $v0
	li $t1, 1
	add $t1, $t3, $t1
	sw $t1, 256($sp)
	lw $t0, 256($sp)
	sw $t0, 0($t2)
	b _OutOfIf19
_alternative18:
	b _OutOfIf19
_OutOfIf19:
	b _OutOfIf16
_alternative15:
	b _OutOfIf16
_OutOfIf16:
	b _OutOfIf13
_alternative12:
	b _OutOfIf13
_OutOfIf13:
	lw $t0, 396($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 164($sp)
	lw $t0, global_27
	lw $t1, 164($sp)
	add $t1, $t0, $t1
	sw $t1, 288($sp)
	lw $t1, 288($sp)
	lw $t0, 0($t1)
	sw $t0, 236($sp)
	lw $t0, 400($sp)
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, 236($sp)
	add $t2, $t0, $t2
	li $t0, 1
	neg $t1, $t0
	sw $t1, 368($sp)
	lw $t2, 0($t2)
	lw $t1, 368($sp)
	seq $t1, $t2, $t1
	sw $t1, 144($sp)
	lw $t0, 144($sp)
	beqz $t0, _alternative21
_consequence20:
	lw $t0, 396($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 328($sp)
	lw $t0, global_27
	lw $t1, 328($sp)
	add $t1, $t0, $t1
	sw $t1, 216($sp)
	lw $t1, 216($sp)
	lw $t2, 0($t1)
	lw $t0, 400($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 196($sp)
	lw $t1, 196($sp)
	add $t1, $t2, $t1
	sw $t1, 172($sp)
	li $t0, 1
	lw $t1, 172($sp)
	sw $t0, 0($t1)
	b _OutOfIf22
_alternative21:
	b _OutOfIf22
_OutOfIf22:
	lw $t0, 396($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 356($sp)
	lw $t0, global_27
	lw $t1, 356($sp)
	add $t1, $t0, $t1
	sw $t1, 156($sp)
	lw $t1, 156($sp)
	lw $t0, 0($t1)
	sw $t0, 228($sp)
	lw $t0, 400($sp)
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, 228($sp)
	add $t1, $t0, $t2
	sw $t1, 296($sp)
	lw $t1, 296($sp)
	lw $t0, 0($t1)
	sw $t0, 372($sp)
	lw $v0, 372($sp)
	b _EndOfFunctionDecl43
_EndOfFunctionDecl43:
	lw $ra, 120($sp)
	lw $t2, 40($sp)
	lw $t4, 48($sp)
	lw $t3, 44($sp)
	add $sp, $sp, 404
	jr $ra
_printF:
	sub $sp, $sp, 188
	sw $ra, 120($sp)
_BeginOfFunctionDecl44:
	lw $a0, 176($sp)
	jal func__toString
	sw $v0, 148($sp)
	lw $a0, 148($sp)
	jal func__print
	sw $v0, 144($sp)
_WhileLoop55:
	lw $t0, 184($sp)
	li $t1, 0
	sgt $t1, $t0, $t1
	sw $t1, 128($sp)
	lw $t0, 128($sp)
	beqz $t0, _OutOfWhile24
_WhileBody23:
	la $a0, string_130
	jal func__print
	sw $v0, 164($sp)
	lw $a0, 180($sp)
	jal func__toString
	sw $v0, 140($sp)
	lw $a0, 140($sp)
	jal func__print
	sw $v0, 152($sp)
	lw $t0, 180($sp)
	li $t1, 2
	mul $t1, $t0, $t1
	sw $t1, 136($sp)
	lw $t0, 136($sp)
	lw $t1, 176($sp)
	sub $t1, $t0, $t1
	sw $t1, 168($sp)
	lw $t0, 168($sp)
	sw $t0, 180($sp)
	lw $t0, 176($sp)
	lw $t1, 180($sp)
	add $t1, $t0, $t1
	sw $t1, 156($sp)
	lw $t0, 156($sp)
	li $t1, 2
	div $t1, $t0, $t1
	sw $t1, 160($sp)
	lw $t0, 160($sp)
	sw $t0, 176($sp)
	lw $t0, 184($sp)
	li $t1, 1
	sub $t1, $t0, $t1
	sw $t1, 132($sp)
	lw $t0, 132($sp)
	sw $t0, 184($sp)
	b _WhileLoop55
_OutOfWhile24:
	la $a0, string_142
	jal func__print
	sw $v0, 172($sp)
_EndOfFunctionDecl45:
	lw $ra, 120($sp)
	add $sp, $sp, 188
	jr $ra
main:
	sub $sp, $sp, 468
	sw $t2, 40($sp)
	sw $t4, 48($sp)
	sw $t5, 52($sp)
	sw $t3, 44($sp)
	sw $ra, 120($sp)
_BeginOfFunctionDecl46:
	li $t0, 1001
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 212($sp)
	lw $t0, 212($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 212($sp)
	lw $a0, 212($sp)
	li $v0, 9
	syscall
	sw $v0, 408($sp)
	li $t0, 1001
	lw $t1, 408($sp)
	sw $t0, 0($t1)
	lw $t0, 408($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 408($sp)
	lw $t0, 408($sp)
	sw $t0, 216($sp)
	lw $t0, 216($sp)
	sw $t0, global_23
	li $t0, 170
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 264($sp)
	lw $t0, 264($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 264($sp)
	lw $a0, 264($sp)
	li $v0, 9
	syscall
	sw $v0, 272($sp)
	li $t0, 170
	lw $t1, 272($sp)
	sw $t0, 0($t1)
	lw $t0, 272($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 272($sp)
	lw $t0, 272($sp)
	sw $t0, 420($sp)
	lw $t0, 420($sp)
	sw $t0, global_24
	li $t0, 1001
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 416($sp)
	lw $t0, 416($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 416($sp)
	lw $a0, 416($sp)
	li $v0, 9
	syscall
	sw $v0, 316($sp)
	li $t0, 1001
	lw $t1, 316($sp)
	sw $t0, 0($t1)
	lw $t0, 316($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 316($sp)
	lw $t0, 316($sp)
	sw $t0, 396($sp)
	lw $t0, 396($sp)
	sw $t0, global_25
	li $t0, 1
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 164($sp)
	lw $t0, 164($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 164($sp)
	lw $a0, 164($sp)
	li $v0, 9
	syscall
	sw $v0, 224($sp)
	li $t0, 1
	lw $t1, 224($sp)
	sw $t0, 0($t1)
	lw $t0, 224($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 224($sp)
	lw $t0, 224($sp)
	sw $t0, 432($sp)
	lw $t0, 432($sp)
	sw $t0, global_26
	li $t0, 170
	sw $t0, -4($sp)
	jal _origin
	sw $v0, 404($sp)
	li $t0, 1000
	sw $t0, global_17
	jal func__getInt
	sw $v0, 220($sp)
	lw $t0, 220($sp)
	sw $t0, global_18
	li $t0, 0
	sw $t0, global_21
	li $t0, 0
	sw $t0, global_22
	li $t0, 0
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 176($sp)
	lw $t0, global_26
	lw $t1, 176($sp)
	add $t1, $t0, $t1
	sw $t1, 192($sp)
	li $t0, 0
	lw $t1, 192($sp)
	sw $t0, 0($t1)
	li $t0, 0
	sw $t0, global_19
_ForLoop56:
	lw $t0, global_17
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 308($sp)
	lw $t0, global_19
	lw $t1, 308($sp)
	slt $t1, $t0, $t1
	sw $t1, 248($sp)
	lw $t0, 248($sp)
	beqz $t0, _OutOfFor26
_ForBody25:
	lw $t0, global_19
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 372($sp)
	lw $t0, global_23
	lw $t1, 372($sp)
	add $t1, $t0, $t1
	sw $t1, 252($sp)
	li $t0, 1
	lw $t1, 252($sp)
	sw $t0, 0($t1)
	lw $t0, global_19
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 268($sp)
	lw $t0, global_25
	lw $t1, 268($sp)
	add $t1, $t0, $t1
	sw $t1, 296($sp)
	li $t0, 0
	lw $t1, 296($sp)
	sw $t0, 0($t1)
_continueFor57:
	lw $t0, global_19
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 348($sp)
	lw $t0, 348($sp)
	sw $t0, global_19
	b _ForLoop56
_OutOfFor26:
	li $t0, 0
	sw $t0, global_19
_ForLoop58:
	lw $t0, global_18
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 144($sp)
	lw $t0, global_19
	lw $t1, 144($sp)
	slt $t1, $t0, $t1
	sw $t1, 320($sp)
	lw $t0, 320($sp)
	beqz $t0, _OutOfFor28
_ForBody27:
	lw $t0, global_19
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 368($sp)
	lw $t0, global_24
	lw $t1, 368($sp)
	add $t1, $t0, $t1
	sw $t1, 400($sp)
	li $t0, 0
	lw $t1, 400($sp)
	sw $t0, 0($t1)
_continueFor59:
	lw $t0, global_19
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 196($sp)
	lw $t0, 196($sp)
	sw $t0, global_19
	b _ForLoop58
_OutOfFor28:
	li $t0, 0
	sw $t0, global_19
_ForLoop60:
	lw $t0, global_19
	lw $t1, global_18
	sle $t1, $t0, $t1
	sw $t1, 392($sp)
	lw $t0, 392($sp)
	beqz $t0, _OutOfFor30
_ForBody29:
	li $t0, 0
	sw $t0, global_20
_ForLoop62:
	lw $t0, global_20
	lw $t1, global_18
	sle $t1, $t0, $t1
	sw $t1, 428($sp)
	lw $t0, 428($sp)
	beqz $t0, _OutOfFor32
_ForBody31:
	lw $t0, global_19
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 464($sp)
	lw $t0, global_27
	lw $t1, 464($sp)
	add $t1, $t0, $t1
	sw $t1, 324($sp)
	lw $t1, 324($sp)
	lw $t0, 0($t1)
	sw $t0, 276($sp)
	lw $t0, global_20
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, 276($sp)
	add $t2, $t0, $t2
	li $t0, 1
	neg $t1, $t0
	sw $t1, 340($sp)
	lw $t0, 340($sp)
	sw $t0, 0($t2)
_continueFor63:
	lw $t0, global_20
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 284($sp)
	lw $t0, 284($sp)
	sw $t0, global_20
	b _ForLoop62
_OutOfFor32:
	b _continueFor61
_continueFor61:
	lw $t0, global_19
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 280($sp)
	lw $t0, 280($sp)
	sw $t0, global_19
	b _ForLoop60
_OutOfFor30:
	lw $t0, global_17
	sw $t0, -4($sp)
	jal _getPrime
	sw $v0, 152($sp)
	li $t0, 0
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 292($sp)
	lw $t0, global_26
	lw $t1, 292($sp)
	add $t1, $t0, $t1
	sw $t1, 188($sp)
	lw $t1, 188($sp)
	lw $t0, 0($t1)
	sw $t0, 356($sp)
	lw $t0, 356($sp)
	sw $t0, global_21
	li $t0, 1
	sw $t0, global_19
_ForLoop64:
	lw $t0, global_19
	lw $t1, global_21
	slt $t1, $t0, $t1
	sw $t1, 156($sp)
	lw $t0, 156($sp)
	beqz $t0, _OutOfFor34
_ForBody33:
	lw $t0, global_19
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 384($sp)
	lw $t0, 384($sp)
	sw $t0, global_20
_ForLoop66:
	lw $t0, global_20
	lw $t1, global_21
	sle $t1, $t0, $t1
	sw $t1, 136($sp)
	lw $t0, 136($sp)
	beqz $t0, _OutOfFor36
_ForBody35:
	lw $t0, global_19
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 244($sp)
	lw $t0, global_27
	lw $t1, 244($sp)
	add $t1, $t0, $t1
	sw $t1, 460($sp)
	lw $t1, 460($sp)
	lw $t0, 0($t1)
	sw $t0, 344($sp)
	lw $t0, global_20
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, 344($sp)
	add $t2, $t0, $t2
	li $t0, 1
	neg $t1, $t0
	sw $t1, 440($sp)
	lw $t2, 0($t2)
	lw $t1, 440($sp)
	seq $t1, $t2, $t1
	sw $t1, 376($sp)
	lw $t0, 376($sp)
	beqz $t0, _alternative38
_consequence37:
	lw $t0, global_19
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 328($sp)
	lw $t0, global_27
	lw $t1, 328($sp)
	add $t1, $t0, $t1
	sw $t1, 208($sp)
	lw $t1, 208($sp)
	lw $t0, 0($t1)
	sw $t0, 204($sp)
	lw $t0, global_20
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, 204($sp)
	add $t1, $t0, $t2
	sw $t1, 172($sp)
	lw $t0, global_17
	sw $t0, -12($sp)
	lw $t0, global_19
	sw $t0, -8($sp)
	lw $t0, global_20
	sw $t0, -4($sp)
	jal _getResult
	move $t2, $v0
	lw $t1, 172($sp)
	sw $t2, 0($t1)
	lw $t0, global_19
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 240($sp)
	lw $t0, global_27
	lw $t1, 240($sp)
	add $t1, $t0, $t1
	sw $t1, 128($sp)
	lw $t1, 128($sp)
	lw $t2, 0($t1)
	lw $t0, global_20
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 424($sp)
	lw $t1, 424($sp)
	add $t1, $t2, $t1
	sw $t1, 364($sp)
	lw $t1, 364($sp)
	lw $t0, 0($t1)
	sw $t0, 452($sp)
	lw $t0, 452($sp)
	li $t1, 1
	sgt $t1, $t0, $t1
	sw $t1, 180($sp)
	lw $t0, 180($sp)
	beqz $t0, _alternative41
_consequence40:
	lw $t0, global_19
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 132($sp)
	lw $t0, global_24
	lw $t1, 132($sp)
	add $t1, $t0, $t1
	sw $t1, 300($sp)
	lw $t1, 300($sp)
	lw $t2, 0($t1)
	lw $t0, global_20
	li $t1, 4
	mul $t3, $t0, $t1
	lw $t0, global_24
	add $t1, $t0, $t3
	sw $t1, 456($sp)
	lw $t1, 456($sp)
	lw $t5, 0($t1)
	lw $t0, global_19
	li $t1, 4
	mul $t3, $t0, $t1
	lw $t0, global_27
	add $t3, $t0, $t3
	lw $t4, 0($t3)
	lw $t0, global_20
	li $t1, 4
	mul $t3, $t0, $t1
	add $t3, $t4, $t3
	lw $t3, 0($t3)
	sw $t2, -12($sp)
	sw $t5, -8($sp)
	sw $t3, -4($sp)
	jal _printF
	sw $v0, 256($sp)
	lw $t0, global_22
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 312($sp)
	lw $t0, 312($sp)
	sw $t0, global_22
	b _OutOfIf42
_alternative41:
	b _OutOfIf42
_OutOfIf42:
	b _OutOfIf39
_alternative38:
	b _OutOfIf39
_OutOfIf39:
	b _continueFor67
_continueFor67:
	lw $t0, global_20
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 336($sp)
	lw $t0, 336($sp)
	sw $t0, global_20
	b _ForLoop66
_OutOfFor36:
	b _continueFor65
_continueFor65:
	lw $t0, global_19
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 160($sp)
	lw $t0, 160($sp)
	sw $t0, global_19
	b _ForLoop64
_OutOfFor34:
	la $a0, string_250
	jal func__print
	sw $v0, 412($sp)
	lw $a0, global_22
	jal func__toString
	sw $v0, 352($sp)
	lw $a0, 352($sp)
	jal func__println
	sw $v0, 304($sp)
	li $v0, 0
	b _EndOfFunctionDecl47
_EndOfFunctionDecl47:
	lw $ra, 120($sp)
	lw $t2, 40($sp)
	lw $t4, 48($sp)
	lw $t5, 52($sp)
	lw $t3, 44($sp)
	add $sp, $sp, 468
	jr $ra
.data
_end: .asciiz "\n"
	.align 2
_buffer: .space 256
	.align 2
global_17:
.space 4
.align 2
global_18:
.space 4
.align 2
global_19:
.space 4
.align 2
global_20:
.space 4
.align 2
global_21:
.space 4
.align 2
global_22:
.space 4
.align 2
global_23:
.space 4
.align 2
global_24:
.space 4
.align 2
global_25:
.space 4
.align 2
global_26:
.space 4
.align 2
global_27:
.space 4
.align 2
.word 1
string_130:
.asciiz " "
.align 2
.word 1
string_142:
.asciiz "\n"
.align 2
.word 7
string_250:
.asciiz "Total: "
.align 2
