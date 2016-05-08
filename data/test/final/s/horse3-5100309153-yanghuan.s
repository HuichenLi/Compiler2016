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
_BeginOfFunctionDecl177:
	li $t0, 0
	sw $t0, global_449
	li $t0, 0
	sw $t0, global_458
	lw $t0, 196($sp)
	li $t1, 4
	mul $t2, $t0, $t1
	li $t1, 4
	add $t2, $t2, $t1
	move $a0, $t2
	li $v0, 9
	syscall
	move $t2, $v0
	lw $t0, 196($sp)
	sw $t0, 0($t2)
	li $t1, 4
	add $t2, $t2, $t1
	sw $t2, global_463
	li $t0, 0
	sw $t0, global_464
_ForLoop185:
	lw $t0, global_464
	lw $t1, 196($sp)
	slt $t2, $t0, $t1
	beqz $t2, _OutOfFor1
_ForBody0:
	lw $t0, global_464
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_463
	add $t1, $t0, $t2
	sw $t1, 184($sp)
	lw $t0, 196($sp)
	li $t1, 4
	mul $t2, $t0, $t1
	li $t1, 4
	add $t2, $t2, $t1
	move $a0, $t2
	li $v0, 9
	syscall
	move $t2, $v0
	lw $t0, 196($sp)
	sw $t0, 0($t2)
	li $t1, 4
	add $t2, $t2, $t1
	lw $t1, 184($sp)
	sw $t2, 0($t1)
	li $t0, 0
	sw $t0, global_465
_ForLoop187:
	lw $t0, global_465
	lw $t1, 196($sp)
	slt $t2, $t0, $t1
	beqz $t2, _OutOfFor3
_ForBody2:
	lw $t0, global_464
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_463
	add $t2, $t0, $t2
	lw $t0, 0($t2)
	sw $t0, 188($sp)
	lw $t0, global_465
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, 188($sp)
	add $t2, $t0, $t2
	li $t0, 0
	sw $t0, 0($t2)
_continueFor188:
	lw $t0, global_465
	move $t2, $t0
	lw $t0, global_465
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_465
	b _ForLoop187
_OutOfFor3:
	b _continueFor186
_continueFor186:
	lw $t0, global_464
	move $t2, $t0
	lw $t0, global_464
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_464
	b _ForLoop185
_OutOfFor1:
	b _EndOfFunctionDecl178
_EndOfFunctionDecl178:
	lw $t2, 40($sp)
	add $sp, $sp, 200
	jr $ra
_check:
	sub $sp, $sp, 144
	sw $t2, 40($sp)
_BeginOfFunctionDecl179:
	lw $t0, 140($sp)
	lw $t1, global_448
	slt $t2, $t0, $t1
	beqz $t2, _logicalFalse5
_logicalTrue4:
	lw $t0, 140($sp)
	li $t1, 0
	sge $t2, $t0, $t1
	b _logicalMerge6
_logicalFalse5:
	li $t0, 0
	move $t2, $t0
	b _logicalMerge6
_logicalMerge6:
	move $v0, $t2
	b _EndOfFunctionDecl180
_EndOfFunctionDecl180:
	lw $t2, 40($sp)
	add $sp, $sp, 144
	jr $ra
_addList:
	sub $sp, $sp, 240
	sw $t4, 48($sp)
	sw $t2, 40($sp)
	sw $t5, 52($sp)
	sw $t3, 44($sp)
	sw $ra, 120($sp)
_BeginOfFunctionDecl181:
	lw $t0, 232($sp)
	sw $t0, -4($sp)
	jal _check
	move $t2, $v0
	beqz $t2, _logicalFalse11
_logicalTrue10:
	lw $t0, 236($sp)
	sw $t0, -4($sp)
	jal _check
	move $t2, $v0
	move $t3, $t2
	b _logicalMerge12
_logicalFalse11:
	li $t0, 0
	move $t3, $t0
	b _logicalMerge12
_logicalMerge12:
	beqz $t3, _logicalFalse14
_logicalTrue13:
	lw $t0, 232($sp)
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_463
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	lw $t0, 236($sp)
	li $t1, 4
	mul $t4, $t0, $t1
	add $t2, $t2, $t4
	li $t0, 1
	neg $t4, $t0
	lw $t2, 0($t2)
	seq $t2, $t2, $t4
	move $t5, $t2
	b _logicalMerge15
_logicalFalse14:
	li $t0, 0
	move $t5, $t0
	b _logicalMerge15
_logicalMerge15:
	beqz $t5, _alternative8
_consequence7:
	lw $t0, global_458
	move $t2, $t0
	lw $t0, global_458
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_458
	lw $t0, global_458
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_456
	add $t2, $t0, $t2
	lw $t0, 232($sp)
	sw $t0, 0($t2)
	lw $t0, global_458
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_457
	add $t2, $t0, $t2
	lw $t0, 236($sp)
	sw $t0, 0($t2)
	lw $t0, 232($sp)
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_463
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	lw $t0, 236($sp)
	li $t1, 4
	mul $t4, $t0, $t1
	add $t4, $t2, $t4
	lw $t0, global_460
	li $t1, 1
	add $t2, $t0, $t1
	sw $t2, 0($t4)
	lw $t0, 232($sp)
	lw $t1, global_452
	seq $t2, $t0, $t1
	beqz $t2, _logicalFalse20
_logicalTrue19:
	lw $t0, 236($sp)
	lw $t1, global_453
	seq $t2, $t0, $t1
	b _logicalMerge21
_logicalFalse20:
	li $t0, 0
	move $t2, $t0
	b _logicalMerge21
_logicalMerge21:
	beqz $t2, _alternative17
_consequence16:
	li $t0, 1
	sw $t0, global_459
	b _OutOfIf18
_alternative17:
	b _OutOfIf18
_OutOfIf18:
	b _OutOfIf9
_alternative8:
	b _OutOfIf9
_OutOfIf9:
	b _EndOfFunctionDecl182
_EndOfFunctionDecl182:
	lw $ra, 120($sp)
	lw $t4, 48($sp)
	lw $t2, 40($sp)
	lw $t5, 52($sp)
	lw $t3, 44($sp)
	add $sp, $sp, 240
	jr $ra
main:
	sub $sp, $sp, 532
	sw $t2, 40($sp)
	sw $ra, 120($sp)
_BeginOfFunctionDecl183:
	li $t0, 12000
	li $t1, 4
	mul $t2, $t0, $t1
	li $t1, 4
	add $t2, $t2, $t1
	move $a0, $t2
	li $v0, 9
	syscall
	move $t2, $v0
	li $t0, 12000
	sw $t0, 0($t2)
	li $t1, 4
	add $t2, $t2, $t1
	sw $t2, global_456
	li $t0, 12000
	li $t1, 4
	mul $t2, $t0, $t1
	li $t1, 4
	add $t2, $t2, $t1
	move $a0, $t2
	li $v0, 9
	syscall
	move $t2, $v0
	li $t0, 12000
	sw $t0, 0($t2)
	li $t1, 4
	add $t2, $t2, $t1
	sw $t2, global_457
	li $t0, 8
	li $t1, 4
	mul $t2, $t0, $t1
	li $t1, 4
	add $t2, $t2, $t1
	move $a0, $t2
	li $v0, 9
	syscall
	move $t2, $v0
	li $t0, 8
	sw $t0, 0($t2)
	li $t1, 4
	add $t2, $t2, $t1
	sw $t2, global_461
	li $t0, 9
	li $t1, 4
	mul $t2, $t0, $t1
	li $t1, 4
	add $t2, $t2, $t1
	move $a0, $t2
	li $v0, 9
	syscall
	move $t2, $v0
	li $t0, 9
	sw $t0, 0($t2)
	li $t1, 4
	add $t2, $t2, $t1
	sw $t2, global_462
	li $t0, 106
	sw $t0, -4($sp)
	jal _origin
	move $t2, $v0
	jal func__getInt
	move $t2, $v0
	sw $t2, global_448
	lw $t0, global_448
	li $t1, 1
	sub $t2, $t0, $t1
	sw $t2, global_453
	lw $t0, global_453
	sw $t0, global_452
	li $t0, 0
	sw $t0, global_464
_ForLoop189:
	lw $t0, global_464
	lw $t1, global_448
	slt $t2, $t0, $t1
	beqz $t2, _OutOfFor23
_ForBody22:
	li $t0, 0
	sw $t0, global_465
_ForLoop191:
	lw $t0, global_465
	lw $t1, global_448
	slt $t2, $t0, $t1
	beqz $t2, _OutOfFor25
_ForBody24:
	lw $t0, global_464
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_463
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	lw $t0, global_465
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 512($sp)
	lw $t1, 512($sp)
	add $t1, $t2, $t1
	sw $t1, 428($sp)
	li $t0, 1
	neg $t2, $t0
	lw $t1, 428($sp)
	sw $t2, 0($t1)
_continueFor192:
	lw $t0, global_465
	move $t2, $t0
	lw $t0, global_465
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_465
	b _ForLoop191
_OutOfFor25:
	b _continueFor190
_continueFor190:
	lw $t0, global_464
	move $t2, $t0
	lw $t0, global_464
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_464
	b _ForLoop189
_OutOfFor23:
	li $t0, 0
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_461
	add $t2, $t0, $t2
	li $t0, 2
	neg $t1, $t0
	sw $t1, 380($sp)
	lw $t0, 380($sp)
	sw $t0, 0($t2)
	li $t0, 0
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_462
	add $t2, $t0, $t2
	li $t0, 1
	neg $t1, $t0
	sw $t1, 348($sp)
	lw $t0, 348($sp)
	sw $t0, 0($t2)
	li $t0, 1
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_461
	add $t1, $t0, $t2
	sw $t1, 452($sp)
	li $t0, 2
	neg $t2, $t0
	lw $t1, 452($sp)
	sw $t2, 0($t1)
	li $t0, 1
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_462
	add $t2, $t0, $t2
	li $t0, 1
	sw $t0, 0($t2)
	li $t0, 2
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_461
	add $t2, $t0, $t2
	li $t0, 2
	sw $t0, 0($t2)
	li $t0, 2
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_462
	add $t1, $t0, $t2
	sw $t1, 440($sp)
	li $t0, 1
	neg $t2, $t0
	lw $t1, 440($sp)
	sw $t2, 0($t1)
	li $t0, 3
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_461
	add $t2, $t0, $t2
	li $t0, 2
	sw $t0, 0($t2)
	li $t0, 3
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_462
	add $t2, $t0, $t2
	li $t0, 1
	sw $t0, 0($t2)
	li $t0, 4
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_461
	add $t2, $t0, $t2
	li $t0, 1
	neg $t1, $t0
	sw $t1, 468($sp)
	lw $t0, 468($sp)
	sw $t0, 0($t2)
	li $t0, 4
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_462
	add $t1, $t0, $t2
	sw $t1, 508($sp)
	li $t0, 2
	neg $t2, $t0
	lw $t1, 508($sp)
	sw $t2, 0($t1)
	li $t0, 5
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_461
	add $t1, $t0, $t2
	sw $t1, 524($sp)
	li $t0, 1
	neg $t2, $t0
	lw $t1, 524($sp)
	sw $t2, 0($t1)
	li $t0, 5
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_462
	add $t2, $t0, $t2
	li $t0, 2
	sw $t0, 0($t2)
	li $t0, 6
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_461
	add $t2, $t0, $t2
	li $t0, 1
	sw $t0, 0($t2)
	li $t0, 6
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_462
	add $t1, $t0, $t2
	sw $t1, 292($sp)
	li $t0, 2
	neg $t2, $t0
	lw $t1, 292($sp)
	sw $t2, 0($t1)
	li $t0, 7
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_461
	add $t2, $t0, $t2
	li $t0, 1
	sw $t0, 0($t2)
	li $t0, 7
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_462
	add $t2, $t0, $t2
	li $t0, 2
	sw $t0, 0($t2)
_WhileLoop193:
	lw $t0, global_449
	lw $t1, global_458
	sle $t2, $t0, $t1
	beqz $t2, _OutOfWhile27
_WhileBody26:
	lw $t0, global_449
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_456
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	sw $t2, global_454
	lw $t0, global_449
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_457
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	sw $t2, global_455
	lw $t0, global_454
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_463
	add $t2, $t0, $t2
	lw $t0, 0($t2)
	sw $t0, 288($sp)
	lw $t0, global_455
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, 288($sp)
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	sw $t2, global_460
	li $t0, 0
	sw $t0, global_465
_ForLoop194:
	lw $t0, global_465
	li $t1, 8
	slt $t2, $t0, $t1
	beqz $t2, _OutOfFor29
_ForBody28:
	lw $t0, global_465
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_461
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	lw $t0, global_454
	add $t2, $t0, $t2
	lw $t0, global_465
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 244($sp)
	lw $t0, global_462
	lw $t1, 244($sp)
	add $t1, $t0, $t1
	sw $t1, 320($sp)
	lw $t1, 320($sp)
	lw $t0, 0($t1)
	sw $t0, 460($sp)
	lw $t0, global_455
	lw $t1, 460($sp)
	add $t1, $t0, $t1
	sw $t1, 228($sp)
	sw $t2, -8($sp)
	lw $t0, 228($sp)
	sw $t0, -4($sp)
	jal _addList
	move $t2, $v0
_continueFor195:
	lw $t0, global_465
	move $t2, $t0
	lw $t0, global_465
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_465
	b _ForLoop194
_OutOfFor29:
	lw $t0, global_459
	li $t1, 1
	seq $t2, $t0, $t1
	beqz $t2, _alternative31
_consequence30:
	b _OutOfWhile27
	b _OutOfIf32
_alternative31:
	b _OutOfIf32
_OutOfIf32:
	lw $t0, global_449
	move $t2, $t0
	lw $t0, global_449
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_449
	b _WhileLoop193
_OutOfWhile27:
	lw $t0, global_459
	li $t1, 1
	seq $t2, $t0, $t1
	beqz $t2, _alternative34
_consequence33:
	lw $t0, global_452
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_463
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	lw $t0, global_453
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 296($sp)
	lw $t1, 296($sp)
	add $t2, $t2, $t1
	lw $t2, 0($t2)
	move $a0, $t2
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	jal func__println
	move $t2, $v0
	b _OutOfIf35
_alternative34:
	la $a0, string_183
	jal func__print
	move $t2, $v0
	b _OutOfIf35
_OutOfIf35:
	li $v0, 0
	b _EndOfFunctionDecl184
_EndOfFunctionDecl184:
	lw $ra, 120($sp)
	lw $t2, 40($sp)
	add $sp, $sp, 532
	jr $ra
.data
_end: .asciiz "\n"
	.align 2
_buffer: .space 256
	.align 2
global_448:
.space 4
.align 2
global_449:
.space 4
.align 2
global_450:
.space 4
.align 2
global_451:
.space 4
.align 2
global_452:
.space 4
.align 2
global_453:
.space 4
.align 2
global_454:
.space 4
.align 2
global_455:
.space 4
.align 2
global_456:
.space 4
.align 2
global_457:
.space 4
.align 2
global_458:
.space 4
.align 2
global_459:
.space 4
.align 2
global_460:
.space 4
.align 2
global_461:
.space 4
.align 2
global_462:
.space 4
.align 2
global_463:
.space 4
.align 2
global_464:
.space 4
.align 2
global_465:
.space 4
.align 2
.word 13
string_183:
.asciiz "no solution!\n"
.align 2
