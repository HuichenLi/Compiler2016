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
main:
	sub $sp, $sp, 540
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
_BeginOfFunctionDecl56:
	li $t0, 99
	sw $t0, global_50
	li $t0, 100
	sw $t0, global_51
	li $t0, 101
	sw $t0, global_52
	li $t0, 102
	sw $t0, global_53
	li $t0, 0
	sw $t0, global_54
	jal func__getInt
	move $t2, $v0
	sw $t2, global_49
	li $t0, 1
	move $t4, $t0
_ForLoop58:
	lw $t1, global_49
	sle $t2, $t4, $t1
	beqz $t2, _OutOfFor1
_ForBody0:
	li $t0, 1
	move $s5, $t0
_ForLoop60:
	lw $t1, global_49
	sle $t2, $s5, $t1
	beqz $t2, _OutOfFor3
_ForBody2:
	li $t0, 1
	move $t3, $t0
_ForLoop62:
	lw $t1, global_49
	sle $t2, $t3, $t1
	beqz $t2, _OutOfFor5
_ForBody4:
	li $t0, 1
	move $t5, $t0
_ForLoop64:
	lw $t1, global_49
	sle $t2, $t5, $t1
	beqz $t2, _OutOfFor7
_ForBody6:
	li $t0, 1
	move $t6, $t0
_ForLoop66:
	lw $t1, global_49
	sle $t2, $t6, $t1
	beqz $t2, _OutOfFor9
_ForBody8:
	li $t0, 1
	move $t7, $t0
_ForLoop68:
	lw $t1, global_49
	sle $t2, $t7, $t1
	beqz $t2, _OutOfFor11
_ForBody10:
	sne $t2, $t4, $s5
	beqz $t2, _logicalFalse16
_logicalTrue15:
	sne $t2, $t4, $t3
	move $s0, $t2
	b _logicalMerge17
_logicalFalse16:
	li $t0, 0
	move $s0, $t0
	b _logicalMerge17
_logicalMerge17:
	beqz $s0, _logicalFalse19
_logicalTrue18:
	sne $t2, $t4, $t5
	move $s1, $t2
	b _logicalMerge20
_logicalFalse19:
	li $t0, 0
	move $s1, $t0
	b _logicalMerge20
_logicalMerge20:
	beqz $s1, _logicalFalse22
_logicalTrue21:
	sne $t2, $t4, $t6
	move $s2, $t2
	b _logicalMerge23
_logicalFalse22:
	li $t0, 0
	move $s2, $t0
	b _logicalMerge23
_logicalMerge23:
	beqz $s2, _logicalFalse25
_logicalTrue24:
	sne $t2, $t4, $t7
	move $s3, $t2
	b _logicalMerge26
_logicalFalse25:
	li $t0, 0
	move $s3, $t0
	b _logicalMerge26
_logicalMerge26:
	beqz $s3, _logicalFalse28
_logicalTrue27:
	lw $t1, global_50
	sne $t2, $t4, $t1
	move $s4, $t2
	b _logicalMerge29
_logicalFalse28:
	li $t0, 0
	move $s4, $t0
	b _logicalMerge29
_logicalMerge29:
	beqz $s4, _logicalFalse31
_logicalTrue30:
	lw $t1, global_51
	sne $t2, $t4, $t1
	b _logicalMerge32
_logicalFalse31:
	li $t0, 0
	move $t2, $t0
	b _logicalMerge32
_logicalMerge32:
	beqz $t2, _logicalFalse34
_logicalTrue33:
	lw $t1, global_52
	sne $s6, $t4, $t1
	move $s7, $s6
	b _logicalMerge35
_logicalFalse34:
	li $t0, 0
	move $s7, $t0
	b _logicalMerge35
_logicalMerge35:
	beqz $s7, _logicalFalse37
_logicalTrue36:
	lw $t1, global_53
	sne $s6, $t4, $t1
	move $t8, $s6
	b _logicalMerge38
_logicalFalse37:
	li $t0, 0
	move $t8, $t0
	b _logicalMerge38
_logicalMerge38:
	beqz $t8, _logicalFalse40
_logicalTrue39:
	sne $s6, $s5, $t3
	b _logicalMerge41
_logicalFalse40:
	li $t0, 0
	move $s6, $t0
	b _logicalMerge41
_logicalMerge41:
	beqz $s6, _logicalFalse43
_logicalTrue42:
	sne $t9, $s5, $t5
	b _logicalMerge44
_logicalFalse43:
	li $t0, 0
	move $t9, $t0
	b _logicalMerge44
_logicalMerge44:
	beqz $t9, _logicalFalse46
_logicalTrue45:
	sne $k0, $s5, $t6
	move $k1, $k0
	b _logicalMerge47
_logicalFalse46:
	li $t0, 0
	move $k1, $t0
	b _logicalMerge47
_logicalMerge47:
	beqz $k1, _logicalFalse49
_logicalTrue48:
	sne $k0, $s5, $t7
	move $gp, $k0
	b _logicalMerge50
_logicalFalse49:
	li $t0, 0
	move $gp, $t0
	b _logicalMerge50
_logicalMerge50:
	beqz $gp, _logicalFalse52
_logicalTrue51:
	lw $t1, global_50
	sne $k0, $s5, $t1
	move $fp, $k0
	b _logicalMerge53
_logicalFalse52:
	li $t0, 0
	move $fp, $t0
	b _logicalMerge53
_logicalMerge53:
	beqz $fp, _logicalFalse55
_logicalTrue54:
	lw $t1, global_51
	sne $k0, $s5, $t1
	b _logicalMerge56
_logicalFalse55:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge56
_logicalMerge56:
	beqz $k0, _logicalFalse58
_logicalTrue57:
	lw $t1, global_52
	sne $k0, $s5, $t1
	b _logicalMerge59
_logicalFalse58:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge59
_logicalMerge59:
	beqz $k0, _logicalFalse61
_logicalTrue60:
	lw $t1, global_53
	sne $k0, $s5, $t1
	b _logicalMerge62
_logicalFalse61:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge62
_logicalMerge62:
	beqz $k0, _logicalFalse64
_logicalTrue63:
	sne $k0, $t3, $t5
	b _logicalMerge65
_logicalFalse64:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge65
_logicalMerge65:
	beqz $k0, _logicalFalse67
_logicalTrue66:
	sne $k0, $t3, $t6
	b _logicalMerge68
_logicalFalse67:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge68
_logicalMerge68:
	beqz $k0, _logicalFalse70
_logicalTrue69:
	sne $k0, $t3, $t7
	b _logicalMerge71
_logicalFalse70:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge71
_logicalMerge71:
	beqz $k0, _logicalFalse73
_logicalTrue72:
	lw $t1, global_50
	sne $k0, $t3, $t1
	b _logicalMerge74
_logicalFalse73:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge74
_logicalMerge74:
	beqz $k0, _logicalFalse76
_logicalTrue75:
	lw $t1, global_51
	sne $k0, $t3, $t1
	b _logicalMerge77
_logicalFalse76:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge77
_logicalMerge77:
	beqz $k0, _logicalFalse79
_logicalTrue78:
	lw $t1, global_52
	sne $k0, $t3, $t1
	b _logicalMerge80
_logicalFalse79:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge80
_logicalMerge80:
	beqz $k0, _logicalFalse82
_logicalTrue81:
	lw $t1, global_53
	sne $k0, $t3, $t1
	b _logicalMerge83
_logicalFalse82:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge83
_logicalMerge83:
	beqz $k0, _logicalFalse85
_logicalTrue84:
	sne $k0, $t5, $t6
	b _logicalMerge86
_logicalFalse85:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge86
_logicalMerge86:
	beqz $k0, _logicalFalse88
_logicalTrue87:
	sne $k0, $t5, $t7
	b _logicalMerge89
_logicalFalse88:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge89
_logicalMerge89:
	beqz $k0, _logicalFalse91
_logicalTrue90:
	lw $t1, global_50
	sne $k0, $t5, $t1
	b _logicalMerge92
_logicalFalse91:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge92
_logicalMerge92:
	beqz $k0, _logicalFalse94
_logicalTrue93:
	lw $t1, global_51
	sne $k0, $t5, $t1
	b _logicalMerge95
_logicalFalse94:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge95
_logicalMerge95:
	beqz $k0, _logicalFalse97
_logicalTrue96:
	lw $t1, global_52
	sne $k0, $t5, $t1
	b _logicalMerge98
_logicalFalse97:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge98
_logicalMerge98:
	beqz $k0, _logicalFalse100
_logicalTrue99:
	lw $t1, global_53
	sne $k0, $t5, $t1
	b _logicalMerge101
_logicalFalse100:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge101
_logicalMerge101:
	beqz $k0, _logicalFalse103
_logicalTrue102:
	sne $k0, $t6, $t7
	b _logicalMerge104
_logicalFalse103:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge104
_logicalMerge104:
	beqz $k0, _logicalFalse106
_logicalTrue105:
	lw $t1, global_50
	sne $k0, $t6, $t1
	b _logicalMerge107
_logicalFalse106:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge107
_logicalMerge107:
	beqz $k0, _logicalFalse109
_logicalTrue108:
	lw $t1, global_51
	sne $k0, $t6, $t1
	b _logicalMerge110
_logicalFalse109:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge110
_logicalMerge110:
	beqz $k0, _logicalFalse112
_logicalTrue111:
	lw $t1, global_52
	sne $k0, $t6, $t1
	b _logicalMerge113
_logicalFalse112:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge113
_logicalMerge113:
	beqz $k0, _logicalFalse115
_logicalTrue114:
	lw $t1, global_53
	sne $k0, $t6, $t1
	b _logicalMerge116
_logicalFalse115:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge116
_logicalMerge116:
	beqz $k0, _logicalFalse118
_logicalTrue117:
	lw $t1, global_50
	sne $k0, $t7, $t1
	b _logicalMerge119
_logicalFalse118:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge119
_logicalMerge119:
	beqz $k0, _logicalFalse121
_logicalTrue120:
	lw $t1, global_51
	sne $k0, $t7, $t1
	b _logicalMerge122
_logicalFalse121:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge122
_logicalMerge122:
	beqz $k0, _logicalFalse124
_logicalTrue123:
	lw $t1, global_52
	sne $k0, $t7, $t1
	b _logicalMerge125
_logicalFalse124:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge125
_logicalMerge125:
	beqz $k0, _logicalFalse127
_logicalTrue126:
	lw $t1, global_53
	sne $k0, $t7, $t1
	b _logicalMerge128
_logicalFalse127:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge128
_logicalMerge128:
	beqz $k0, _logicalFalse130
_logicalTrue129:
	lw $t0, global_51
	lw $t1, global_52
	sne $k0, $t0, $t1
	b _logicalMerge131
_logicalFalse130:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge131
_logicalMerge131:
	beqz $k0, _logicalFalse133
_logicalTrue132:
	lw $t0, global_50
	lw $t1, global_53
	sne $k0, $t0, $t1
	b _logicalMerge134
_logicalFalse133:
	li $t0, 0
	move $k0, $t0
	b _logicalMerge134
_logicalMerge134:
	beqz $k0, _alternative13
_consequence12:
	lw $t0, global_54
	move $k0, $t0
	lw $t0, global_54
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_54
	b _OutOfIf14
_alternative13:
	b _OutOfIf14
_OutOfIf14:
	b _continueFor69
_continueFor69:
	move $k0, $t7
	li $t1, 1
	add $t7, $t7, $t1
	b _ForLoop68
_OutOfFor11:
	b _continueFor67
_continueFor67:
	move $k0, $t6
	li $t1, 1
	add $t6, $t6, $t1
	b _ForLoop66
_OutOfFor9:
	b _continueFor65
_continueFor65:
	move $k0, $t5
	li $t1, 1
	add $t5, $t5, $t1
	b _ForLoop64
_OutOfFor7:
	b _continueFor63
_continueFor63:
	move $k0, $t3
	li $t1, 1
	add $t3, $t3, $t1
	b _ForLoop62
_OutOfFor5:
	b _continueFor61
_continueFor61:
	move $k0, $s5
	li $t1, 1
	add $s5, $s5, $t1
	b _ForLoop60
_OutOfFor3:
	b _continueFor59
_continueFor59:
	move $k0, $t4
	li $t1, 1
	add $t4, $t4, $t1
	b _ForLoop58
_OutOfFor1:
	lw $a0, global_54
	jal func__toString
	move $k0, $v0
	move $a0, $k0
	jal func__println
	move $k0, $v0
	li $v0, 0
	b _EndOfFunctionDecl57
_EndOfFunctionDecl57:
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
	add $sp, $sp, 540
	jr $ra
.data
_end: .asciiz "\n"
	.align 2
_buffer: .space 256
	.align 2
global_49:
.space 4
.align 2
global_50:
.space 4
.align 2
global_51:
.space 4
.align 2
global_52:
.space 4
.align 2
global_53:
.space 4
.align 2
global_54:
.space 4
.align 2
