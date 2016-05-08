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
_getcount:
	sub $sp, $sp, 144
	sw $t2, 40($sp)
_BeginOfFunctionDecl61:
	li $t0, 0
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, 140($sp)
	add $t1, $t0, $t2
	sw $t1, 136($sp)
	lw $t1, 136($sp)
	lw $t2, 0($t1)
	li $t1, 1
	add $t2, $t2, $t1
	lw $t1, 136($sp)
	sw $t2, 0($t1)
	move $v0, $t2
	b _EndOfFunctionDecl62
_EndOfFunctionDecl62:
	lw $t2, 40($sp)
	add $sp, $sp, 144
	jr $ra
main:
	sub $sp, $sp, 8348
	sw $s0, 64($sp)
	sw $t8, 96($sp)
	sw $fp, 124($sp)
	sw $t6, 56($sp)
	sw $s7, 92($sp)
	sw $t2, 40($sp)
	sw $t7, 60($sp)
	sw $t9, 100($sp)
	sw $s5, 84($sp)
	sw $s6, 88($sp)
	sw $t4, 48($sp)
	sw $gp, 112($sp)
	sw $k1, 108($sp)
	sw $s1, 68($sp)
	sw $s2, 72($sp)
	sw $s3, 76($sp)
	sw $k0, 104($sp)
	sw $t5, 52($sp)
	sw $s4, 80($sp)
	sw $t3, 44($sp)
	sw $ra, 120($sp)
_BeginOfFunctionDecl63:
	li $t0, 1
	li $t1, 4
	mul $t2, $t0, $t1
	li $t1, 4
	add $t2, $t2, $t1
	move $a0, $t2
	li $v0, 9
	syscall
	move $t2, $v0
	li $t0, 1
	sw $t0, 0($t2)
	li $t1, 4
	add $t2, $t2, $t1
	sw $t2, global_129
	li $t0, 0
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_129
	add $t2, $t0, $t2
	li $t0, 0
	sw $t0, 0($t2)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7500($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1268($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3352($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5928($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5976($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7324($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $t8, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6660($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $t3, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2708($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2760($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2652($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2672($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3912($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $t4, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6488($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5308($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6080($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7548($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $t6, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3268($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1696($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5080($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6856($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1776($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1220($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5276($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6448($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7608($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6636($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1664($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2944($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5304($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2552($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 704($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4196($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7520($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6748($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2692($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3984($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4416($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 800($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6020($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 760($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6164($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7480($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7284($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $t9, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4548($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4216($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4048($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6188($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6848($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3996($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $s4, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4276($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1072($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6380($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4072($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3144($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4984($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2956($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5756($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3496($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $k1, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7032($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7336($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1860($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1900($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1464($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3860($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $t5, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2608($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6220($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3260($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2856($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6416($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2900($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4280($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2584($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6840($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $s7, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7740($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6532($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $s6, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4032($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4020($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7788($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5156($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6768($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 840($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4444($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2432($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6232($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5264($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7496($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5892($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3988($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1076($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5124($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4680($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5804($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1060($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $fp, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7088($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1064($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $s3, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2384($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $t7, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 500($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3184($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7428($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5164($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3760($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7524($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5708($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5744($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2684($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6300($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1904($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 156($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2272($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5952($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3484($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3196($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6876($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2688($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 580($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 864($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5844($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6832($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2428($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4348($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2928($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3304($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1108($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 152($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 636($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 988($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3408($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5620($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5560($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6668($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2344($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5624($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1100($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3232($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 620($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4564($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $k0, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2408($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2680($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 340($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1848($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6508($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 836($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6356($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6724($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3620($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $s1, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2264($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2988($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7400($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2456($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 196($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7404($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4272($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 404($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5452($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6560($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2032($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2276($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7596($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5824($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3436($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $s2, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 164($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4512($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4380($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4476($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5000($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $gp, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 948($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4924($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7752($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1916($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3328($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6612($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4436($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $s5, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3632($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6192($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3772($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 356($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7380($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7612($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1304($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7540($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3112($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7628($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4292($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4964($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2244($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2304($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5924($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3372($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7508($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6948($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3208($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2036($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6520($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1232($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 976($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5476($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7108($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4056($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 240($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5436($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5880($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7472($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6648($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3200($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 312($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7016($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4284($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 8344($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	move $s0, $t2
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 488($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2556($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5316($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 304($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6740($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7580($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3432($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4008($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5536($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2884($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4084($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1172($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5244($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 2080($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6644($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 3464($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7592($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6212($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4076($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6360($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 1736($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6544($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 668($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7216($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 7408($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 5084($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 4432($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 6888($sp)
	lw $t0, global_129
	sw $t0, -4($sp)
	jal _getcount
	move $t2, $v0
	sw $t2, 772($sp)
	lw $a0, 7500($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_523
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1268($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_527
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3352($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_531
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5928($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_535
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5976($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_539
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7324($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_543
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t8
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_547
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6660($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_551
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t3
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_555
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2708($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_559
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2760($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_563
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2652($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_567
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2672($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_571
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3912($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_575
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t4
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_579
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6488($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_583
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5308($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_587
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6080($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_591
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7548($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_595
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t6
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_599
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3268($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_603
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1696($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_607
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5080($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_611
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6856($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_615
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1776($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_619
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1220($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_623
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5276($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_627
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6448($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_631
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7608($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_635
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6636($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_639
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1664($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_643
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2944($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_647
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5304($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_651
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2552($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_655
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 704($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_659
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4196($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_663
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7520($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_667
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6748($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_671
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2692($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_675
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3984($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_679
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4416($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_683
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 800($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_687
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6020($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_691
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 760($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_695
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6164($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_699
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7480($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_703
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7284($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_707
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t9
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_711
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4548($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_715
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4216($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_719
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4048($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_723
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6188($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_727
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6848($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_731
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3996($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_735
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s4
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_739
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4276($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_743
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1072($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_747
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6380($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_751
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4072($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_755
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3144($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_759
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4984($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_763
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2956($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_767
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5756($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_771
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3496($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_775
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $k1
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_779
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7032($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_783
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7336($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_787
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1860($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_791
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1900($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_795
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1464($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_799
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3860($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_803
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t5
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_807
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2608($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_811
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6220($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_815
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3260($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_819
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2856($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_823
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6416($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_827
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2900($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_831
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4280($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_835
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2584($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_839
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6840($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_843
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s7
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_847
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7740($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_851
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6532($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_855
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s6
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_859
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4032($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_863
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4020($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_867
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7788($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_871
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5156($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_875
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6768($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_879
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 840($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_883
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4444($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_887
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2432($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_891
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6232($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_895
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5264($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_899
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7496($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_903
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5892($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_907
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3988($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_911
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1076($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_915
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5124($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_919
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4680($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_923
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5804($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_927
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1060($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_931
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $fp
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_935
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7088($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_939
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1064($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_943
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s3
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_947
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2384($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_951
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t7
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_955
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 500($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_959
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3184($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_963
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7428($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_967
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5164($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_971
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3760($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_975
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7524($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_979
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5708($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_983
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5744($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_987
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2684($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_991
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6300($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_995
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1904($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_999
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 156($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1003
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2272($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1007
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5952($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1011
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3484($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1015
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3196($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1019
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6876($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1023
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2688($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1027
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 580($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1031
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 864($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1035
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5844($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1039
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6832($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1043
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2428($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1047
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4348($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1051
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2928($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1055
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3304($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1059
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1108($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1063
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 152($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1067
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 636($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1071
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 988($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1075
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3408($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1079
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5620($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1083
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5560($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1087
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6668($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1091
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2344($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1095
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5624($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1099
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1100($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1103
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3232($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1107
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 620($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1111
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4564($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1115
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $k0
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1119
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2408($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1123
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2680($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1127
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 340($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1131
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1848($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1135
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6508($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1139
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 836($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1143
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6356($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1147
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6724($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1151
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3620($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1155
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s1
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1159
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2264($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1163
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2988($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1167
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7400($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1171
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2456($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1175
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 196($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1179
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7404($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1183
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4272($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1187
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 404($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1191
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5452($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1195
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6560($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1199
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2032($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1203
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2276($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1207
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7596($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1211
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5824($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1215
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3436($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1219
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s2
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1223
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 164($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1227
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4512($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1231
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4380($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1235
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4476($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1239
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5000($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1243
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $gp
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1247
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 948($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1251
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4924($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1255
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7752($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1259
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1916($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1263
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3328($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1267
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6612($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1271
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4436($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1275
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s5
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1279
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3632($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1283
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6192($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1287
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3772($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1291
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 356($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1295
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7380($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1299
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7612($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1303
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1304($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1307
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7540($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1311
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3112($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1315
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7628($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1319
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4292($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1323
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4964($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1327
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2244($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1331
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2304($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1335
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5924($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1339
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3372($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1343
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7508($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1347
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6948($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1351
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3208($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1355
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2036($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1359
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6520($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1363
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1232($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1367
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 976($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1371
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5476($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1375
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7108($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1379
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4056($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1383
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 240($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1387
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5436($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1391
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5880($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1395
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7472($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1399
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6648($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1403
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3200($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1407
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 312($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1411
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7016($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1415
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4284($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1419
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 8344($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1423
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s0
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1427
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 488($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1431
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2556($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1435
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5316($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1439
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 304($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1443
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6740($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1447
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7580($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1451
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3432($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1455
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4008($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1459
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5536($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1463
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2884($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1467
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4084($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1471
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1172($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1475
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5244($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1479
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2080($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1483
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6644($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1487
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3464($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1491
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7592($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1495
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6212($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1499
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4076($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1503
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6360($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1507
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1736($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1511
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6544($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1515
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 668($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1519
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7216($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1523
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7408($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1527
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5084($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1531
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4432($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1535
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6888($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1539
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 772($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1543
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	la $a0, string_1546
	jal func__println
	move $t2, $v0
	lw $a0, 7500($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1549
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1268($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1553
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3352($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1557
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5928($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1561
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5976($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1565
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7324($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1569
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t8
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1573
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6660($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1577
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t3
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1581
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2708($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1585
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2760($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1589
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2652($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1593
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2672($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1597
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3912($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1601
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t4
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1605
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6488($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1609
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5308($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1613
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6080($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1617
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7548($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1621
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t6
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1625
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3268($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1629
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1696($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1633
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5080($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1637
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6856($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1641
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1776($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1645
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1220($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1649
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5276($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1653
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6448($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1657
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7608($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1661
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6636($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1665
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1664($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1669
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2944($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1673
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5304($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1677
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2552($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1681
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 704($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1685
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4196($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1689
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7520($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1693
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6748($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1697
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2692($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1701
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3984($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1705
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4416($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1709
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 800($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1713
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6020($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1717
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 760($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1721
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6164($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1725
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7480($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1729
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7284($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1733
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t9
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1737
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4548($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1741
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4216($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1745
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4048($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1749
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6188($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1753
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6848($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1757
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3996($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1761
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s4
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1765
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4276($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1769
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1072($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1773
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6380($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1777
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4072($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1781
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3144($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1785
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4984($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1789
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2956($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1793
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5756($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1797
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3496($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1801
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $k1
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1805
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7032($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1809
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7336($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1813
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1860($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1817
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1900($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1821
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1464($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1825
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3860($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1829
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t5
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1833
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2608($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1837
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6220($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1841
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3260($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1845
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2856($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1849
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6416($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1853
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2900($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1857
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4280($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1861
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2584($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1865
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6840($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1869
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s7
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1873
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7740($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1877
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6532($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1881
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s6
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1885
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4032($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1889
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4020($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1893
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7788($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1897
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5156($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1901
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6768($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1905
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 840($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1909
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4444($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1913
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2432($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1917
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6232($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1921
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5264($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1925
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7496($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1929
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5892($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1933
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3988($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1937
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1076($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1941
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5124($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1945
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4680($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1949
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5804($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1953
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1060($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1957
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $fp
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1961
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7088($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1965
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1064($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1969
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s3
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1973
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2384($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1977
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $t7
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1981
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 500($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1985
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3184($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1989
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7428($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1993
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5164($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_1997
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3760($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2001
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7524($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2005
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5708($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2009
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5744($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2013
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2684($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2017
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6300($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2021
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1904($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2025
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 156($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2029
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2272($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2033
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5952($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2037
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3484($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2041
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3196($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2045
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6876($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2049
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2688($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2053
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 580($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2057
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 864($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2061
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5844($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2065
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6832($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2069
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2428($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2073
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4348($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2077
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2928($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2081
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3304($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2085
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1108($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2089
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 152($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2093
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 636($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2097
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 988($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2101
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3408($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2105
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5620($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2109
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5560($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2113
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6668($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2117
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2344($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2121
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5624($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2125
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1100($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2129
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3232($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2133
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 620($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2137
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4564($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2141
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $k0
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2145
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2408($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2149
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2680($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2153
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 340($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2157
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1848($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2161
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6508($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2165
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 836($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2169
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6356($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2173
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6724($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2177
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3620($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2181
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s1
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2185
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2264($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2189
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2988($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2193
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7400($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2197
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2456($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2201
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 196($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2205
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7404($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2209
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4272($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2213
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 404($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2217
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5452($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2221
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6560($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2225
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2032($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2229
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2276($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2233
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7596($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2237
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5824($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2241
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3436($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2245
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s2
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2249
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 164($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2253
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4512($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2257
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4380($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2261
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4476($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2265
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5000($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2269
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $gp
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2273
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 948($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2277
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4924($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2281
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7752($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2285
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1916($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2289
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3328($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2293
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6612($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2297
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4436($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2301
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	move $a0, $s5
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2305
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3632($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2309
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6192($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2313
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3772($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2317
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 356($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2321
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7380($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2325
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7612($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2329
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1304($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2333
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7540($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2337
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3112($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2341
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7628($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2345
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4292($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2349
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4964($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2353
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2244($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2357
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2304($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2361
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5924($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2365
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3372($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2369
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7508($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2373
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6948($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2377
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3208($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2381
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2036($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2385
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6520($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2389
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1232($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2393
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 976($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2397
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5476($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2401
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7108($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2405
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4056($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2409
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 240($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2413
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5436($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2417
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5880($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2421
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7472($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2425
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6648($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2429
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3200($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2433
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 312($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2437
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7016($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2441
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4284($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2445
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 8344($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2449
	jal func__stringConcatenate
	sw $v0, 8224($sp)
	lw $a0, 8224($sp)
	jal func__print
	move $t2, $v0
	move $a0, $s0
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2453
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 488($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2457
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2556($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2461
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5316($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2465
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 304($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2469
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6740($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2473
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7580($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2477
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3432($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2481
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4008($sp)
	jal func__toString
	sw $v0, 7648($sp)
	lw $a0, 7648($sp)
	la $a1, string_2485
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5536($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2489
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2884($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2493
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4084($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2497
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1172($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2501
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5244($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2505
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 2080($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2509
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6644($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2513
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 3464($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2517
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7592($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2521
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6212($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2525
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4076($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2529
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6360($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2533
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 1736($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2537
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6544($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2541
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 668($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2545
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7216($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2549
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 7408($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2553
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 5084($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2557
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 4432($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2561
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 6888($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2565
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	lw $a0, 772($sp)
	jal func__toString
	move $t2, $v0
	move $a0, $t2
	la $a1, string_2569
	jal func__stringConcatenate
	move $t2, $v0
	move $a0, $t2
	jal func__print
	move $t2, $v0
	la $a0, string_2572
	jal func__println
	move $t2, $v0
	li $v0, 0
	b _EndOfFunctionDecl64
_EndOfFunctionDecl64:
	lw $ra, 120($sp)
	lw $s0, 64($sp)
	lw $t8, 96($sp)
	lw $fp, 124($sp)
	lw $t6, 56($sp)
	lw $s7, 92($sp)
	lw $t2, 40($sp)
	lw $t7, 60($sp)
	lw $t9, 100($sp)
	lw $s5, 84($sp)
	lw $s6, 88($sp)
	lw $t4, 48($sp)
	lw $gp, 112($sp)
	lw $k1, 108($sp)
	lw $s1, 68($sp)
	lw $s2, 72($sp)
	lw $s3, 76($sp)
	lw $k0, 104($sp)
	lw $t5, 52($sp)
	lw $s4, 80($sp)
	lw $t3, 44($sp)
	add $sp, $sp, 8348
	jr $ra
.data
_end: .asciiz "\n"
	.align 2
_buffer: .space 256
	.align 2
global_129:
.space 4
.align 2
.word 1
string_523:
.asciiz " "
.align 2
.word 1
string_527:
.asciiz " "
.align 2
.word 1
string_531:
.asciiz " "
.align 2
.word 1
string_535:
.asciiz " "
.align 2
.word 1
string_539:
.asciiz " "
.align 2
.word 1
string_543:
.asciiz " "
.align 2
.word 1
string_547:
.asciiz " "
.align 2
.word 1
string_551:
.asciiz " "
.align 2
.word 1
string_555:
.asciiz " "
.align 2
.word 1
string_559:
.asciiz " "
.align 2
.word 1
string_563:
.asciiz " "
.align 2
.word 1
string_567:
.asciiz " "
.align 2
.word 1
string_571:
.asciiz " "
.align 2
.word 1
string_575:
.asciiz " "
.align 2
.word 1
string_579:
.asciiz " "
.align 2
.word 1
string_583:
.asciiz " "
.align 2
.word 1
string_587:
.asciiz " "
.align 2
.word 1
string_591:
.asciiz " "
.align 2
.word 1
string_595:
.asciiz " "
.align 2
.word 1
string_599:
.asciiz " "
.align 2
.word 1
string_603:
.asciiz " "
.align 2
.word 1
string_607:
.asciiz " "
.align 2
.word 1
string_611:
.asciiz " "
.align 2
.word 1
string_615:
.asciiz " "
.align 2
.word 1
string_619:
.asciiz " "
.align 2
.word 1
string_623:
.asciiz " "
.align 2
.word 1
string_627:
.asciiz " "
.align 2
.word 1
string_631:
.asciiz " "
.align 2
.word 1
string_635:
.asciiz " "
.align 2
.word 1
string_639:
.asciiz " "
.align 2
.word 1
string_643:
.asciiz " "
.align 2
.word 1
string_647:
.asciiz " "
.align 2
.word 1
string_651:
.asciiz " "
.align 2
.word 1
string_655:
.asciiz " "
.align 2
.word 1
string_659:
.asciiz " "
.align 2
.word 1
string_663:
.asciiz " "
.align 2
.word 1
string_667:
.asciiz " "
.align 2
.word 1
string_671:
.asciiz " "
.align 2
.word 1
string_675:
.asciiz " "
.align 2
.word 1
string_679:
.asciiz " "
.align 2
.word 1
string_683:
.asciiz " "
.align 2
.word 1
string_687:
.asciiz " "
.align 2
.word 1
string_691:
.asciiz " "
.align 2
.word 1
string_695:
.asciiz " "
.align 2
.word 1
string_699:
.asciiz " "
.align 2
.word 1
string_703:
.asciiz " "
.align 2
.word 1
string_707:
.asciiz " "
.align 2
.word 1
string_711:
.asciiz " "
.align 2
.word 1
string_715:
.asciiz " "
.align 2
.word 1
string_719:
.asciiz " "
.align 2
.word 1
string_723:
.asciiz " "
.align 2
.word 1
string_727:
.asciiz " "
.align 2
.word 1
string_731:
.asciiz " "
.align 2
.word 1
string_735:
.asciiz " "
.align 2
.word 1
string_739:
.asciiz " "
.align 2
.word 1
string_743:
.asciiz " "
.align 2
.word 1
string_747:
.asciiz " "
.align 2
.word 1
string_751:
.asciiz " "
.align 2
.word 1
string_755:
.asciiz " "
.align 2
.word 1
string_759:
.asciiz " "
.align 2
.word 1
string_763:
.asciiz " "
.align 2
.word 1
string_767:
.asciiz " "
.align 2
.word 1
string_771:
.asciiz " "
.align 2
.word 1
string_775:
.asciiz " "
.align 2
.word 1
string_779:
.asciiz " "
.align 2
.word 1
string_783:
.asciiz " "
.align 2
.word 1
string_787:
.asciiz " "
.align 2
.word 1
string_791:
.asciiz " "
.align 2
.word 1
string_795:
.asciiz " "
.align 2
.word 1
string_799:
.asciiz " "
.align 2
.word 1
string_803:
.asciiz " "
.align 2
.word 1
string_807:
.asciiz " "
.align 2
.word 1
string_811:
.asciiz " "
.align 2
.word 1
string_815:
.asciiz " "
.align 2
.word 1
string_819:
.asciiz " "
.align 2
.word 1
string_823:
.asciiz " "
.align 2
.word 1
string_827:
.asciiz " "
.align 2
.word 1
string_831:
.asciiz " "
.align 2
.word 1
string_835:
.asciiz " "
.align 2
.word 1
string_839:
.asciiz " "
.align 2
.word 1
string_843:
.asciiz " "
.align 2
.word 1
string_847:
.asciiz " "
.align 2
.word 1
string_851:
.asciiz " "
.align 2
.word 1
string_855:
.asciiz " "
.align 2
.word 1
string_859:
.asciiz " "
.align 2
.word 1
string_863:
.asciiz " "
.align 2
.word 1
string_867:
.asciiz " "
.align 2
.word 1
string_871:
.asciiz " "
.align 2
.word 1
string_875:
.asciiz " "
.align 2
.word 1
string_879:
.asciiz " "
.align 2
.word 1
string_883:
.asciiz " "
.align 2
.word 1
string_887:
.asciiz " "
.align 2
.word 1
string_891:
.asciiz " "
.align 2
.word 1
string_895:
.asciiz " "
.align 2
.word 1
string_899:
.asciiz " "
.align 2
.word 1
string_903:
.asciiz " "
.align 2
.word 1
string_907:
.asciiz " "
.align 2
.word 1
string_911:
.asciiz " "
.align 2
.word 1
string_915:
.asciiz " "
.align 2
.word 1
string_919:
.asciiz " "
.align 2
.word 1
string_923:
.asciiz " "
.align 2
.word 1
string_927:
.asciiz " "
.align 2
.word 1
string_931:
.asciiz " "
.align 2
.word 1
string_935:
.asciiz " "
.align 2
.word 1
string_939:
.asciiz " "
.align 2
.word 1
string_943:
.asciiz " "
.align 2
.word 1
string_947:
.asciiz " "
.align 2
.word 1
string_951:
.asciiz " "
.align 2
.word 1
string_955:
.asciiz " "
.align 2
.word 1
string_959:
.asciiz " "
.align 2
.word 1
string_963:
.asciiz " "
.align 2
.word 1
string_967:
.asciiz " "
.align 2
.word 1
string_971:
.asciiz " "
.align 2
.word 1
string_975:
.asciiz " "
.align 2
.word 1
string_979:
.asciiz " "
.align 2
.word 1
string_983:
.asciiz " "
.align 2
.word 1
string_987:
.asciiz " "
.align 2
.word 1
string_991:
.asciiz " "
.align 2
.word 1
string_995:
.asciiz " "
.align 2
.word 1
string_999:
.asciiz " "
.align 2
.word 1
string_1003:
.asciiz " "
.align 2
.word 1
string_1007:
.asciiz " "
.align 2
.word 1
string_1011:
.asciiz " "
.align 2
.word 1
string_1015:
.asciiz " "
.align 2
.word 1
string_1019:
.asciiz " "
.align 2
.word 1
string_1023:
.asciiz " "
.align 2
.word 1
string_1027:
.asciiz " "
.align 2
.word 1
string_1031:
.asciiz " "
.align 2
.word 1
string_1035:
.asciiz " "
.align 2
.word 1
string_1039:
.asciiz " "
.align 2
.word 1
string_1043:
.asciiz " "
.align 2
.word 1
string_1047:
.asciiz " "
.align 2
.word 1
string_1051:
.asciiz " "
.align 2
.word 1
string_1055:
.asciiz " "
.align 2
.word 1
string_1059:
.asciiz " "
.align 2
.word 1
string_1063:
.asciiz " "
.align 2
.word 1
string_1067:
.asciiz " "
.align 2
.word 1
string_1071:
.asciiz " "
.align 2
.word 1
string_1075:
.asciiz " "
.align 2
.word 1
string_1079:
.asciiz " "
.align 2
.word 1
string_1083:
.asciiz " "
.align 2
.word 1
string_1087:
.asciiz " "
.align 2
.word 1
string_1091:
.asciiz " "
.align 2
.word 1
string_1095:
.asciiz " "
.align 2
.word 1
string_1099:
.asciiz " "
.align 2
.word 1
string_1103:
.asciiz " "
.align 2
.word 1
string_1107:
.asciiz " "
.align 2
.word 1
string_1111:
.asciiz " "
.align 2
.word 1
string_1115:
.asciiz " "
.align 2
.word 1
string_1119:
.asciiz " "
.align 2
.word 1
string_1123:
.asciiz " "
.align 2
.word 1
string_1127:
.asciiz " "
.align 2
.word 1
string_1131:
.asciiz " "
.align 2
.word 1
string_1135:
.asciiz " "
.align 2
.word 1
string_1139:
.asciiz " "
.align 2
.word 1
string_1143:
.asciiz " "
.align 2
.word 1
string_1147:
.asciiz " "
.align 2
.word 1
string_1151:
.asciiz " "
.align 2
.word 1
string_1155:
.asciiz " "
.align 2
.word 1
string_1159:
.asciiz " "
.align 2
.word 1
string_1163:
.asciiz " "
.align 2
.word 1
string_1167:
.asciiz " "
.align 2
.word 1
string_1171:
.asciiz " "
.align 2
.word 1
string_1175:
.asciiz " "
.align 2
.word 1
string_1179:
.asciiz " "
.align 2
.word 1
string_1183:
.asciiz " "
.align 2
.word 1
string_1187:
.asciiz " "
.align 2
.word 1
string_1191:
.asciiz " "
.align 2
.word 1
string_1195:
.asciiz " "
.align 2
.word 1
string_1199:
.asciiz " "
.align 2
.word 1
string_1203:
.asciiz " "
.align 2
.word 1
string_1207:
.asciiz " "
.align 2
.word 1
string_1211:
.asciiz " "
.align 2
.word 1
string_1215:
.asciiz " "
.align 2
.word 1
string_1219:
.asciiz " "
.align 2
.word 1
string_1223:
.asciiz " "
.align 2
.word 1
string_1227:
.asciiz " "
.align 2
.word 1
string_1231:
.asciiz " "
.align 2
.word 1
string_1235:
.asciiz " "
.align 2
.word 1
string_1239:
.asciiz " "
.align 2
.word 1
string_1243:
.asciiz " "
.align 2
.word 1
string_1247:
.asciiz " "
.align 2
.word 1
string_1251:
.asciiz " "
.align 2
.word 1
string_1255:
.asciiz " "
.align 2
.word 1
string_1259:
.asciiz " "
.align 2
.word 1
string_1263:
.asciiz " "
.align 2
.word 1
string_1267:
.asciiz " "
.align 2
.word 1
string_1271:
.asciiz " "
.align 2
.word 1
string_1275:
.asciiz " "
.align 2
.word 1
string_1279:
.asciiz " "
.align 2
.word 1
string_1283:
.asciiz " "
.align 2
.word 1
string_1287:
.asciiz " "
.align 2
.word 1
string_1291:
.asciiz " "
.align 2
.word 1
string_1295:
.asciiz " "
.align 2
.word 1
string_1299:
.asciiz " "
.align 2
.word 1
string_1303:
.asciiz " "
.align 2
.word 1
string_1307:
.asciiz " "
.align 2
.word 1
string_1311:
.asciiz " "
.align 2
.word 1
string_1315:
.asciiz " "
.align 2
.word 1
string_1319:
.asciiz " "
.align 2
.word 1
string_1323:
.asciiz " "
.align 2
.word 1
string_1327:
.asciiz " "
.align 2
.word 1
string_1331:
.asciiz " "
.align 2
.word 1
string_1335:
.asciiz " "
.align 2
.word 1
string_1339:
.asciiz " "
.align 2
.word 1
string_1343:
.asciiz " "
.align 2
.word 1
string_1347:
.asciiz " "
.align 2
.word 1
string_1351:
.asciiz " "
.align 2
.word 1
string_1355:
.asciiz " "
.align 2
.word 1
string_1359:
.asciiz " "
.align 2
.word 1
string_1363:
.asciiz " "
.align 2
.word 1
string_1367:
.asciiz " "
.align 2
.word 1
string_1371:
.asciiz " "
.align 2
.word 1
string_1375:
.asciiz " "
.align 2
.word 1
string_1379:
.asciiz " "
.align 2
.word 1
string_1383:
.asciiz " "
.align 2
.word 1
string_1387:
.asciiz " "
.align 2
.word 1
string_1391:
.asciiz " "
.align 2
.word 1
string_1395:
.asciiz " "
.align 2
.word 1
string_1399:
.asciiz " "
.align 2
.word 1
string_1403:
.asciiz " "
.align 2
.word 1
string_1407:
.asciiz " "
.align 2
.word 1
string_1411:
.asciiz " "
.align 2
.word 1
string_1415:
.asciiz " "
.align 2
.word 1
string_1419:
.asciiz " "
.align 2
.word 1
string_1423:
.asciiz " "
.align 2
.word 1
string_1427:
.asciiz " "
.align 2
.word 1
string_1431:
.asciiz " "
.align 2
.word 1
string_1435:
.asciiz " "
.align 2
.word 1
string_1439:
.asciiz " "
.align 2
.word 1
string_1443:
.asciiz " "
.align 2
.word 1
string_1447:
.asciiz " "
.align 2
.word 1
string_1451:
.asciiz " "
.align 2
.word 1
string_1455:
.asciiz " "
.align 2
.word 1
string_1459:
.asciiz " "
.align 2
.word 1
string_1463:
.asciiz " "
.align 2
.word 1
string_1467:
.asciiz " "
.align 2
.word 1
string_1471:
.asciiz " "
.align 2
.word 1
string_1475:
.asciiz " "
.align 2
.word 1
string_1479:
.asciiz " "
.align 2
.word 1
string_1483:
.asciiz " "
.align 2
.word 1
string_1487:
.asciiz " "
.align 2
.word 1
string_1491:
.asciiz " "
.align 2
.word 1
string_1495:
.asciiz " "
.align 2
.word 1
string_1499:
.asciiz " "
.align 2
.word 1
string_1503:
.asciiz " "
.align 2
.word 1
string_1507:
.asciiz " "
.align 2
.word 1
string_1511:
.asciiz " "
.align 2
.word 1
string_1515:
.asciiz " "
.align 2
.word 1
string_1519:
.asciiz " "
.align 2
.word 1
string_1523:
.asciiz " "
.align 2
.word 1
string_1527:
.asciiz " "
.align 2
.word 1
string_1531:
.asciiz " "
.align 2
.word 1
string_1535:
.asciiz " "
.align 2
.word 1
string_1539:
.asciiz " "
.align 2
.word 1
string_1543:
.asciiz " "
.align 2
.word 0
string_1546:
.asciiz ""
.align 2
.word 1
string_1549:
.asciiz " "
.align 2
.word 1
string_1553:
.asciiz " "
.align 2
.word 1
string_1557:
.asciiz " "
.align 2
.word 1
string_1561:
.asciiz " "
.align 2
.word 1
string_1565:
.asciiz " "
.align 2
.word 1
string_1569:
.asciiz " "
.align 2
.word 1
string_1573:
.asciiz " "
.align 2
.word 1
string_1577:
.asciiz " "
.align 2
.word 1
string_1581:
.asciiz " "
.align 2
.word 1
string_1585:
.asciiz " "
.align 2
.word 1
string_1589:
.asciiz " "
.align 2
.word 1
string_1593:
.asciiz " "
.align 2
.word 1
string_1597:
.asciiz " "
.align 2
.word 1
string_1601:
.asciiz " "
.align 2
.word 1
string_1605:
.asciiz " "
.align 2
.word 1
string_1609:
.asciiz " "
.align 2
.word 1
string_1613:
.asciiz " "
.align 2
.word 1
string_1617:
.asciiz " "
.align 2
.word 1
string_1621:
.asciiz " "
.align 2
.word 1
string_1625:
.asciiz " "
.align 2
.word 1
string_1629:
.asciiz " "
.align 2
.word 1
string_1633:
.asciiz " "
.align 2
.word 1
string_1637:
.asciiz " "
.align 2
.word 1
string_1641:
.asciiz " "
.align 2
.word 1
string_1645:
.asciiz " "
.align 2
.word 1
string_1649:
.asciiz " "
.align 2
.word 1
string_1653:
.asciiz " "
.align 2
.word 1
string_1657:
.asciiz " "
.align 2
.word 1
string_1661:
.asciiz " "
.align 2
.word 1
string_1665:
.asciiz " "
.align 2
.word 1
string_1669:
.asciiz " "
.align 2
.word 1
string_1673:
.asciiz " "
.align 2
.word 1
string_1677:
.asciiz " "
.align 2
.word 1
string_1681:
.asciiz " "
.align 2
.word 1
string_1685:
.asciiz " "
.align 2
.word 1
string_1689:
.asciiz " "
.align 2
.word 1
string_1693:
.asciiz " "
.align 2
.word 1
string_1697:
.asciiz " "
.align 2
.word 1
string_1701:
.asciiz " "
.align 2
.word 1
string_1705:
.asciiz " "
.align 2
.word 1
string_1709:
.asciiz " "
.align 2
.word 1
string_1713:
.asciiz " "
.align 2
.word 1
string_1717:
.asciiz " "
.align 2
.word 1
string_1721:
.asciiz " "
.align 2
.word 1
string_1725:
.asciiz " "
.align 2
.word 1
string_1729:
.asciiz " "
.align 2
.word 1
string_1733:
.asciiz " "
.align 2
.word 1
string_1737:
.asciiz " "
.align 2
.word 1
string_1741:
.asciiz " "
.align 2
.word 1
string_1745:
.asciiz " "
.align 2
.word 1
string_1749:
.asciiz " "
.align 2
.word 1
string_1753:
.asciiz " "
.align 2
.word 1
string_1757:
.asciiz " "
.align 2
.word 1
string_1761:
.asciiz " "
.align 2
.word 1
string_1765:
.asciiz " "
.align 2
.word 1
string_1769:
.asciiz " "
.align 2
.word 1
string_1773:
.asciiz " "
.align 2
.word 1
string_1777:
.asciiz " "
.align 2
.word 1
string_1781:
.asciiz " "
.align 2
.word 1
string_1785:
.asciiz " "
.align 2
.word 1
string_1789:
.asciiz " "
.align 2
.word 1
string_1793:
.asciiz " "
.align 2
.word 1
string_1797:
.asciiz " "
.align 2
.word 1
string_1801:
.asciiz " "
.align 2
.word 1
string_1805:
.asciiz " "
.align 2
.word 1
string_1809:
.asciiz " "
.align 2
.word 1
string_1813:
.asciiz " "
.align 2
.word 1
string_1817:
.asciiz " "
.align 2
.word 1
string_1821:
.asciiz " "
.align 2
.word 1
string_1825:
.asciiz " "
.align 2
.word 1
string_1829:
.asciiz " "
.align 2
.word 1
string_1833:
.asciiz " "
.align 2
.word 1
string_1837:
.asciiz " "
.align 2
.word 1
string_1841:
.asciiz " "
.align 2
.word 1
string_1845:
.asciiz " "
.align 2
.word 1
string_1849:
.asciiz " "
.align 2
.word 1
string_1853:
.asciiz " "
.align 2
.word 1
string_1857:
.asciiz " "
.align 2
.word 1
string_1861:
.asciiz " "
.align 2
.word 1
string_1865:
.asciiz " "
.align 2
.word 1
string_1869:
.asciiz " "
.align 2
.word 1
string_1873:
.asciiz " "
.align 2
.word 1
string_1877:
.asciiz " "
.align 2
.word 1
string_1881:
.asciiz " "
.align 2
.word 1
string_1885:
.asciiz " "
.align 2
.word 1
string_1889:
.asciiz " "
.align 2
.word 1
string_1893:
.asciiz " "
.align 2
.word 1
string_1897:
.asciiz " "
.align 2
.word 1
string_1901:
.asciiz " "
.align 2
.word 1
string_1905:
.asciiz " "
.align 2
.word 1
string_1909:
.asciiz " "
.align 2
.word 1
string_1913:
.asciiz " "
.align 2
.word 1
string_1917:
.asciiz " "
.align 2
.word 1
string_1921:
.asciiz " "
.align 2
.word 1
string_1925:
.asciiz " "
.align 2
.word 1
string_1929:
.asciiz " "
.align 2
.word 1
string_1933:
.asciiz " "
.align 2
.word 1
string_1937:
.asciiz " "
.align 2
.word 1
string_1941:
.asciiz " "
.align 2
.word 1
string_1945:
.asciiz " "
.align 2
.word 1
string_1949:
.asciiz " "
.align 2
.word 1
string_1953:
.asciiz " "
.align 2
.word 1
string_1957:
.asciiz " "
.align 2
.word 1
string_1961:
.asciiz " "
.align 2
.word 1
string_1965:
.asciiz " "
.align 2
.word 1
string_1969:
.asciiz " "
.align 2
.word 1
string_1973:
.asciiz " "
.align 2
.word 1
string_1977:
.asciiz " "
.align 2
.word 1
string_1981:
.asciiz " "
.align 2
.word 1
string_1985:
.asciiz " "
.align 2
.word 1
string_1989:
.asciiz " "
.align 2
.word 1
string_1993:
.asciiz " "
.align 2
.word 1
string_1997:
.asciiz " "
.align 2
.word 1
string_2001:
.asciiz " "
.align 2
.word 1
string_2005:
.asciiz " "
.align 2
.word 1
string_2009:
.asciiz " "
.align 2
.word 1
string_2013:
.asciiz " "
.align 2
.word 1
string_2017:
.asciiz " "
.align 2
.word 1
string_2021:
.asciiz " "
.align 2
.word 1
string_2025:
.asciiz " "
.align 2
.word 1
string_2029:
.asciiz " "
.align 2
.word 1
string_2033:
.asciiz " "
.align 2
.word 1
string_2037:
.asciiz " "
.align 2
.word 1
string_2041:
.asciiz " "
.align 2
.word 1
string_2045:
.asciiz " "
.align 2
.word 1
string_2049:
.asciiz " "
.align 2
.word 1
string_2053:
.asciiz " "
.align 2
.word 1
string_2057:
.asciiz " "
.align 2
.word 1
string_2061:
.asciiz " "
.align 2
.word 1
string_2065:
.asciiz " "
.align 2
.word 1
string_2069:
.asciiz " "
.align 2
.word 1
string_2073:
.asciiz " "
.align 2
.word 1
string_2077:
.asciiz " "
.align 2
.word 1
string_2081:
.asciiz " "
.align 2
.word 1
string_2085:
.asciiz " "
.align 2
.word 1
string_2089:
.asciiz " "
.align 2
.word 1
string_2093:
.asciiz " "
.align 2
.word 1
string_2097:
.asciiz " "
.align 2
.word 1
string_2101:
.asciiz " "
.align 2
.word 1
string_2105:
.asciiz " "
.align 2
.word 1
string_2109:
.asciiz " "
.align 2
.word 1
string_2113:
.asciiz " "
.align 2
.word 1
string_2117:
.asciiz " "
.align 2
.word 1
string_2121:
.asciiz " "
.align 2
.word 1
string_2125:
.asciiz " "
.align 2
.word 1
string_2129:
.asciiz " "
.align 2
.word 1
string_2133:
.asciiz " "
.align 2
.word 1
string_2137:
.asciiz " "
.align 2
.word 1
string_2141:
.asciiz " "
.align 2
.word 1
string_2145:
.asciiz " "
.align 2
.word 1
string_2149:
.asciiz " "
.align 2
.word 1
string_2153:
.asciiz " "
.align 2
.word 1
string_2157:
.asciiz " "
.align 2
.word 1
string_2161:
.asciiz " "
.align 2
.word 1
string_2165:
.asciiz " "
.align 2
.word 1
string_2169:
.asciiz " "
.align 2
.word 1
string_2173:
.asciiz " "
.align 2
.word 1
string_2177:
.asciiz " "
.align 2
.word 1
string_2181:
.asciiz " "
.align 2
.word 1
string_2185:
.asciiz " "
.align 2
.word 1
string_2189:
.asciiz " "
.align 2
.word 1
string_2193:
.asciiz " "
.align 2
.word 1
string_2197:
.asciiz " "
.align 2
.word 1
string_2201:
.asciiz " "
.align 2
.word 1
string_2205:
.asciiz " "
.align 2
.word 1
string_2209:
.asciiz " "
.align 2
.word 1
string_2213:
.asciiz " "
.align 2
.word 1
string_2217:
.asciiz " "
.align 2
.word 1
string_2221:
.asciiz " "
.align 2
.word 1
string_2225:
.asciiz " "
.align 2
.word 1
string_2229:
.asciiz " "
.align 2
.word 1
string_2233:
.asciiz " "
.align 2
.word 1
string_2237:
.asciiz " "
.align 2
.word 1
string_2241:
.asciiz " "
.align 2
.word 1
string_2245:
.asciiz " "
.align 2
.word 1
string_2249:
.asciiz " "
.align 2
.word 1
string_2253:
.asciiz " "
.align 2
.word 1
string_2257:
.asciiz " "
.align 2
.word 1
string_2261:
.asciiz " "
.align 2
.word 1
string_2265:
.asciiz " "
.align 2
.word 1
string_2269:
.asciiz " "
.align 2
.word 1
string_2273:
.asciiz " "
.align 2
.word 1
string_2277:
.asciiz " "
.align 2
.word 1
string_2281:
.asciiz " "
.align 2
.word 1
string_2285:
.asciiz " "
.align 2
.word 1
string_2289:
.asciiz " "
.align 2
.word 1
string_2293:
.asciiz " "
.align 2
.word 1
string_2297:
.asciiz " "
.align 2
.word 1
string_2301:
.asciiz " "
.align 2
.word 1
string_2305:
.asciiz " "
.align 2
.word 1
string_2309:
.asciiz " "
.align 2
.word 1
string_2313:
.asciiz " "
.align 2
.word 1
string_2317:
.asciiz " "
.align 2
.word 1
string_2321:
.asciiz " "
.align 2
.word 1
string_2325:
.asciiz " "
.align 2
.word 1
string_2329:
.asciiz " "
.align 2
.word 1
string_2333:
.asciiz " "
.align 2
.word 1
string_2337:
.asciiz " "
.align 2
.word 1
string_2341:
.asciiz " "
.align 2
.word 1
string_2345:
.asciiz " "
.align 2
.word 1
string_2349:
.asciiz " "
.align 2
.word 1
string_2353:
.asciiz " "
.align 2
.word 1
string_2357:
.asciiz " "
.align 2
.word 1
string_2361:
.asciiz " "
.align 2
.word 1
string_2365:
.asciiz " "
.align 2
.word 1
string_2369:
.asciiz " "
.align 2
.word 1
string_2373:
.asciiz " "
.align 2
.word 1
string_2377:
.asciiz " "
.align 2
.word 1
string_2381:
.asciiz " "
.align 2
.word 1
string_2385:
.asciiz " "
.align 2
.word 1
string_2389:
.asciiz " "
.align 2
.word 1
string_2393:
.asciiz " "
.align 2
.word 1
string_2397:
.asciiz " "
.align 2
.word 1
string_2401:
.asciiz " "
.align 2
.word 1
string_2405:
.asciiz " "
.align 2
.word 1
string_2409:
.asciiz " "
.align 2
.word 1
string_2413:
.asciiz " "
.align 2
.word 1
string_2417:
.asciiz " "
.align 2
.word 1
string_2421:
.asciiz " "
.align 2
.word 1
string_2425:
.asciiz " "
.align 2
.word 1
string_2429:
.asciiz " "
.align 2
.word 1
string_2433:
.asciiz " "
.align 2
.word 1
string_2437:
.asciiz " "
.align 2
.word 1
string_2441:
.asciiz " "
.align 2
.word 1
string_2445:
.asciiz " "
.align 2
.word 1
string_2449:
.asciiz " "
.align 2
.word 1
string_2453:
.asciiz " "
.align 2
.word 1
string_2457:
.asciiz " "
.align 2
.word 1
string_2461:
.asciiz " "
.align 2
.word 1
string_2465:
.asciiz " "
.align 2
.word 1
string_2469:
.asciiz " "
.align 2
.word 1
string_2473:
.asciiz " "
.align 2
.word 1
string_2477:
.asciiz " "
.align 2
.word 1
string_2481:
.asciiz " "
.align 2
.word 1
string_2485:
.asciiz " "
.align 2
.word 1
string_2489:
.asciiz " "
.align 2
.word 1
string_2493:
.asciiz " "
.align 2
.word 1
string_2497:
.asciiz " "
.align 2
.word 1
string_2501:
.asciiz " "
.align 2
.word 1
string_2505:
.asciiz " "
.align 2
.word 1
string_2509:
.asciiz " "
.align 2
.word 1
string_2513:
.asciiz " "
.align 2
.word 1
string_2517:
.asciiz " "
.align 2
.word 1
string_2521:
.asciiz " "
.align 2
.word 1
string_2525:
.asciiz " "
.align 2
.word 1
string_2529:
.asciiz " "
.align 2
.word 1
string_2533:
.asciiz " "
.align 2
.word 1
string_2537:
.asciiz " "
.align 2
.word 1
string_2541:
.asciiz " "
.align 2
.word 1
string_2545:
.asciiz " "
.align 2
.word 1
string_2549:
.asciiz " "
.align 2
.word 1
string_2553:
.asciiz " "
.align 2
.word 1
string_2557:
.asciiz " "
.align 2
.word 1
string_2561:
.asciiz " "
.align 2
.word 1
string_2565:
.asciiz " "
.align 2
.word 1
string_2569:
.asciiz " "
.align 2
.word 0
string_2572:
.asciiz ""
.align 2
