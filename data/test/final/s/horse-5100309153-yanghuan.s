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
	sw $t4, 48($sp)
	sw $t5, 52($sp)
	sw $t6, 56($sp)
	sw $t7, 60($sp)
	sw $s0, 64($sp)
	sw $s1, 68($sp)
	sw $s2, 72($sp)
	sw $s3, 76($sp)
	sw $s4, 80($sp)
	sw $s5, 84($sp)
	sw $s6, 88($sp)
	sw $s7, 92($sp)
	sw $t8, 96($sp)
	sw $t9, 100($sp)
	sw $k0, 104($sp)
	sw $k1, 108($sp)
	sw $gp, 112($sp)
	sw $fp, 124($sp)
	sw $ra, 120($sp)
_BeginOfFunctionDecl801:
	lw $t0, 196($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 136($sp)
	lw $t0, 136($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 136($sp)
	lw $a0, 136($sp)
	li $v0, 9
	syscall
	sw $v0, 140($sp)
	lw $t0, 196($sp)
	lw $t1, 140($sp)
	sw $t0, 0($t1)
	lw $t0, 140($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 140($sp)
	lw $t0, 140($sp)
	sw $t0, 180($sp)
	lw $t0, 180($sp)
	sw $t0, global_176
	li $t0, 0
	sw $t0, global_177
_ForLoop809:
	lw $t0, global_177
	lw $t1, 196($sp)
	slt $t1, $t0, $t1
	sw $t1, 144($sp)
	lw $t0, 144($sp)
	beqz $t0, _OutOfFor819
_ForBody818:
	lw $t0, global_177
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 164($sp)
	lw $t0, global_176
	lw $t1, 164($sp)
	add $t2, $t0, $t1
	lw $t0, 196($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 184($sp)
	lw $t0, 184($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 184($sp)
	lw $a0, 184($sp)
	li $v0, 9
	syscall
	move $t3, $v0
	lw $t0, 196($sp)
	sw $t0, 0($t3)
	li $t1, 4
	add $t3, $t3, $t1
	move $t3, $t3
	sw $t3, 0($t2)
	li $t0, 0
	sw $t0, global_178
_ForLoop811:
	lw $t0, global_178
	lw $t1, 196($sp)
	slt $t1, $t0, $t1
	sw $t1, 188($sp)
	lw $t0, 188($sp)
	beqz $t0, _OutOfFor821
_ForBody820:
	lw $t0, global_177
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 176($sp)
	lw $t0, global_176
	lw $t1, 176($sp)
	add $t1, $t0, $t1
	sw $t1, 156($sp)
	lw $t1, 156($sp)
	lw $t2, 0($t1)
	lw $t0, global_178
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 192($sp)
	lw $t1, 192($sp)
	add $t1, $t2, $t1
	sw $t1, 160($sp)
	li $t0, 0
	lw $t1, 160($sp)
	sw $t0, 0($t1)
_continueFor812:
	lw $t0, global_178
	sw $t0, 152($sp)
	lw $t0, global_178
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_178
	b _ForLoop811
_OutOfFor821:
	b _continueFor810
_continueFor810:
	lw $t0, global_177
	sw $t0, 132($sp)
	lw $t0, global_177
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_177
	b _ForLoop809
_OutOfFor819:
	b _EndOfFunctionDecl802
_EndOfFunctionDecl802:
	lw $ra, 120($sp)
	lw $t2, 40($sp)
	lw $t3, 44($sp)
	lw $t4, 48($sp)
	lw $t5, 52($sp)
	lw $t6, 56($sp)
	lw $t7, 60($sp)
	lw $s0, 64($sp)
	lw $s1, 68($sp)
	lw $s2, 72($sp)
	lw $s3, 76($sp)
	lw $s4, 80($sp)
	lw $s5, 84($sp)
	lw $s6, 88($sp)
	lw $s7, 92($sp)
	lw $t8, 96($sp)
	lw $t9, 100($sp)
	lw $k0, 104($sp)
	lw $k1, 108($sp)
	lw $gp, 112($sp)
	lw $fp, 124($sp)
	add $sp, $sp, 200
	jr $ra
_check:
	sub $sp, $sp, 148
	sw $t2, 40($sp)
	sw $t3, 44($sp)
	sw $t4, 48($sp)
	sw $t5, 52($sp)
	sw $t6, 56($sp)
	sw $t7, 60($sp)
	sw $s0, 64($sp)
	sw $s1, 68($sp)
	sw $s2, 72($sp)
	sw $s3, 76($sp)
	sw $s4, 80($sp)
	sw $s5, 84($sp)
	sw $s6, 88($sp)
	sw $s7, 92($sp)
	sw $t8, 96($sp)
	sw $t9, 100($sp)
	sw $k0, 104($sp)
	sw $k1, 108($sp)
	sw $gp, 112($sp)
	sw $fp, 124($sp)
	sw $ra, 120($sp)
_BeginOfFunctionDecl803:
	lw $t0, 140($sp)
	lw $t1, 144($sp)
	slt $t1, $t0, $t1
	sw $t1, 136($sp)
	lw $t0, 136($sp)
	beqz $t0, _logicalFalse823
_logicalTrue822:
	lw $t0, 140($sp)
	li $t1, 0
	sge $t1, $t0, $t1
	sw $t1, 132($sp)
	lw $t0, 132($sp)
	sw $t0, 128($sp)
	b _logicalMerge824
_logicalFalse823:
	li $t0, 0
	sw $t0, 128($sp)
	b _logicalMerge824
_logicalMerge824:
	lw $v0, 128($sp)
	b _EndOfFunctionDecl804
_EndOfFunctionDecl804:
	lw $ra, 120($sp)
	lw $t2, 40($sp)
	lw $t3, 44($sp)
	lw $t4, 48($sp)
	lw $t5, 52($sp)
	lw $t6, 56($sp)
	lw $t7, 60($sp)
	lw $s0, 64($sp)
	lw $s1, 68($sp)
	lw $s2, 72($sp)
	lw $s3, 76($sp)
	lw $s4, 80($sp)
	lw $s5, 84($sp)
	lw $s6, 88($sp)
	lw $s7, 92($sp)
	lw $t8, 96($sp)
	lw $t9, 100($sp)
	lw $k0, 104($sp)
	lw $k1, 108($sp)
	lw $gp, 112($sp)
	lw $fp, 124($sp)
	add $sp, $sp, 148
	jr $ra
_addList:
	sub $sp, $sp, 240
	sw $t2, 40($sp)
	sw $t3, 44($sp)
	sw $t4, 48($sp)
	sw $t5, 52($sp)
	sw $t6, 56($sp)
	sw $t7, 60($sp)
	sw $s0, 64($sp)
	sw $s1, 68($sp)
	sw $s2, 72($sp)
	sw $s3, 76($sp)
	sw $s4, 80($sp)
	sw $s5, 84($sp)
	sw $s6, 88($sp)
	sw $s7, 92($sp)
	sw $t8, 96($sp)
	sw $t9, 100($sp)
	sw $k0, 104($sp)
	sw $k1, 108($sp)
	sw $gp, 112($sp)
	sw $fp, 124($sp)
	sw $ra, 120($sp)
_BeginOfFunctionDecl805:
	lw $t0, 232($sp)
	sw $t0, -8($sp)
	lw $t0, global_163
	sw $t0, -4($sp)
	jal _check
	sw $v0, 212($sp)
	lw $t0, 212($sp)
	beqz $t0, _logicalFalse829
_logicalTrue828:
	lw $t0, 236($sp)
	sw $t0, -8($sp)
	lw $t0, global_163
	sw $t0, -4($sp)
	jal _check
	sw $v0, 180($sp)
	lw $t0, 180($sp)
	move $t4, $t0
	b _logicalMerge830
_logicalFalse829:
	li $t0, 0
	move $t4, $t0
	b _logicalMerge830
_logicalMerge830:
	beqz $t4, _logicalFalse832
_logicalTrue831:
	lw $t0, 232($sp)
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_176
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	lw $t0, 236($sp)
	li $t1, 4
	mul $t3, $t0, $t1
	add $t3, $t2, $t3
	li $t0, 1
	neg $t2, $t0
	lw $t3, 0($t3)
	seq $t2, $t3, $t2
	move $t5, $t2
	b _logicalMerge833
_logicalFalse832:
	li $t0, 0
	move $t5, $t0
	b _logicalMerge833
_logicalMerge833:
	beqz $t5, _alternative826
_consequence825:
	lw $t0, global_173
	li $t1, 1
	add $t2, $t0, $t1
	sw $t2, global_173
	lw $t0, global_173
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_171
	add $t2, $t0, $t2
	lw $t0, 232($sp)
	sw $t0, 0($t2)
	lw $t0, global_173
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_172
	add $t2, $t0, $t2
	lw $t0, 236($sp)
	sw $t0, 0($t2)
	lw $t0, 232($sp)
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, global_176
	add $t2, $t0, $t2
	lw $t2, 0($t2)
	lw $t0, 236($sp)
	li $t1, 4
	mul $t3, $t0, $t1
	add $t2, $t2, $t3
	lw $t0, global_175
	li $t1, 1
	add $t3, $t0, $t1
	sw $t3, 0($t2)
	lw $t0, 232($sp)
	lw $t1, global_167
	seq $t2, $t0, $t1
	beqz $t2, _logicalFalse838
_logicalTrue837:
	lw $t0, 236($sp)
	lw $t1, global_168
	seq $t2, $t0, $t1
	move $t2, $t2
	b _logicalMerge839
_logicalFalse838:
	li $t0, 0
	move $t2, $t0
	b _logicalMerge839
_logicalMerge839:
	beqz $t2, _alternative835
_consequence834:
	li $t0, 1
	sw $t0, global_174
	b _OutOfIf836
_alternative835:
	b _OutOfIf836
_OutOfIf836:
	b _OutOfIf827
_alternative826:
	b _OutOfIf827
_OutOfIf827:
	b _EndOfFunctionDecl806
_EndOfFunctionDecl806:
	lw $ra, 120($sp)
	lw $t2, 40($sp)
	lw $t3, 44($sp)
	lw $t4, 48($sp)
	lw $t5, 52($sp)
	lw $t6, 56($sp)
	lw $t7, 60($sp)
	lw $s0, 64($sp)
	lw $s1, 68($sp)
	lw $s2, 72($sp)
	lw $s3, 76($sp)
	lw $s4, 80($sp)
	lw $s5, 84($sp)
	lw $s6, 88($sp)
	lw $s7, 92($sp)
	lw $t8, 96($sp)
	lw $t9, 100($sp)
	lw $k0, 104($sp)
	lw $k1, 108($sp)
	lw $gp, 112($sp)
	lw $fp, 124($sp)
	add $sp, $sp, 240
	jr $ra
main:
	sub $sp, $sp, 400
	sw $t2, 40($sp)
	sw $t3, 44($sp)
	sw $t4, 48($sp)
	sw $t5, 52($sp)
	sw $t6, 56($sp)
	sw $t7, 60($sp)
	sw $s0, 64($sp)
	sw $s1, 68($sp)
	sw $s2, 72($sp)
	sw $s3, 76($sp)
	sw $s4, 80($sp)
	sw $s5, 84($sp)
	sw $s6, 88($sp)
	sw $s7, 92($sp)
	sw $t8, 96($sp)
	sw $t9, 100($sp)
	sw $k0, 104($sp)
	sw $k1, 108($sp)
	sw $gp, 112($sp)
	sw $fp, 124($sp)
	sw $ra, 120($sp)
_BeginOfFunctionDecl807:
	li $t0, 12000
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 184($sp)
	lw $t0, 184($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 184($sp)
	lw $a0, 184($sp)
	li $v0, 9
	syscall
	sw $v0, 192($sp)
	li $t0, 12000
	lw $t1, 192($sp)
	sw $t0, 0($t1)
	lw $t0, 192($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 192($sp)
	lw $t0, 192($sp)
	sw $t0, 240($sp)
	lw $t0, 240($sp)
	sw $t0, global_171
	li $t0, 12000
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 300($sp)
	lw $t0, 300($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 300($sp)
	lw $a0, 300($sp)
	li $v0, 9
	syscall
	sw $v0, 364($sp)
	li $t0, 12000
	lw $t1, 364($sp)
	sw $t0, 0($t1)
	lw $t0, 364($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 364($sp)
	lw $t0, 364($sp)
	sw $t0, 332($sp)
	lw $t0, 332($sp)
	sw $t0, global_172
	li $t0, 106
	sw $t0, -4($sp)
	jal _origin
	sw $v0, 396($sp)
	jal func__getInt
	sw $v0, 296($sp)
	lw $t0, 296($sp)
	sw $t0, global_163
	lw $t0, global_163
	li $t1, 1
	sub $t1, $t0, $t1
	sw $t1, 208($sp)
	lw $t0, 208($sp)
	sw $t0, global_168
	lw $t0, global_168
	sw $t0, global_167
	li $t0, 0
	sw $t0, global_177
_ForLoop813:
	lw $t0, global_177
	lw $t1, global_163
	slt $t1, $t0, $t1
	sw $t1, 388($sp)
	lw $t0, 388($sp)
	beqz $t0, _OutOfFor841
_ForBody840:
	li $t0, 0
	sw $t0, global_178
_ForLoop815:
	lw $t0, global_178
	lw $t1, global_163
	slt $t1, $t0, $t1
	sw $t1, 312($sp)
	lw $t0, 312($sp)
	beqz $t0, _OutOfFor843
_ForBody842:
	lw $t0, global_177
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 256($sp)
	lw $t0, global_176
	lw $t1, 256($sp)
	add $t1, $t0, $t1
	sw $t1, 348($sp)
	lw $t1, 348($sp)
	lw $t0, 0($t1)
	sw $t0, 260($sp)
	lw $t0, global_178
	li $t1, 4
	mul $t2, $t0, $t1
	lw $t0, 260($sp)
	add $t1, $t0, $t2
	sw $t1, 188($sp)
	li $t0, 1
	neg $t2, $t0
	lw $t1, 188($sp)
	sw $t2, 0($t1)
_continueFor816:
	lw $t0, global_178
	sw $t0, 368($sp)
	lw $t0, global_178
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_178
	b _ForLoop815
_OutOfFor843:
	b _continueFor814
_continueFor814:
	lw $t0, global_177
	sw $t0, 280($sp)
	lw $t0, global_177
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, global_177
	b _ForLoop813
_OutOfFor841:
	b _WhileLoop817
_WhileLoop817:
	lw $t0, global_164
	lw $t1, global_173
	sle $t1, $t0, $t1
	sw $t1, 340($sp)
	lw $t0, 340($sp)
	beqz $t0, _OutOfWhile845
_WhileBody844:
	lw $t0, global_164
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 320($sp)
	lw $t0, global_171
	lw $t1, 320($sp)
	add $t1, $t0, $t1
	sw $t1, 196($sp)
	lw $t1, 196($sp)
	lw $t0, 0($t1)
	sw $t0, 132($sp)
	lw $t0, 132($sp)
	sw $t0, global_169
	lw $t0, global_164
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 148($sp)
	lw $t0, global_172
	lw $t1, 148($sp)
	add $t1, $t0, $t1
	sw $t1, 272($sp)
	lw $t1, 272($sp)
	lw $t0, 0($t1)
	sw $t0, 224($sp)
	lw $t0, 224($sp)
	sw $t0, global_170
	lw $t0, global_169
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 352($sp)
	lw $t0, global_176
	lw $t1, 352($sp)
	add $t1, $t0, $t1
	sw $t1, 328($sp)
	lw $t1, 328($sp)
	lw $t2, 0($t1)
	lw $t0, global_170
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 200($sp)
	lw $t1, 200($sp)
	add $t1, $t2, $t1
	sw $t1, 248($sp)
	lw $t1, 248($sp)
	lw $t0, 0($t1)
	sw $t0, 136($sp)
	lw $t0, 136($sp)
	sw $t0, global_175
	lw $t0, global_169
	li $t1, 1
	sub $t2, $t0, $t1
	lw $t0, global_170
	li $t1, 2
	sub $t1, $t0, $t1
	sw $t1, 292($sp)
	sw $t2, -8($sp)
	lw $t0, 292($sp)
	sw $t0, -4($sp)
	jal _addList
	sw $v0, 164($sp)
	lw $t0, global_169
	li $t1, 1
	sub $t1, $t0, $t1
	sw $t1, 376($sp)
	lw $t0, global_170
	li $t1, 2
	add $t2, $t0, $t1
	lw $t0, 376($sp)
	sw $t0, -8($sp)
	sw $t2, -4($sp)
	jal _addList
	sw $v0, 324($sp)
	lw $t0, global_169
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 284($sp)
	lw $t0, global_170
	li $t1, 2
	sub $t2, $t0, $t1
	lw $t0, 284($sp)
	sw $t0, -8($sp)
	sw $t2, -4($sp)
	jal _addList
	sw $v0, 152($sp)
	lw $t0, global_169
	li $t1, 1
	add $t2, $t0, $t1
	lw $t0, global_170
	li $t1, 2
	add $t3, $t0, $t1
	sw $t2, -8($sp)
	sw $t3, -4($sp)
	jal _addList
	sw $v0, 344($sp)
	lw $t0, global_169
	li $t1, 2
	sub $t1, $t0, $t1
	sw $t1, 356($sp)
	lw $t0, global_170
	li $t1, 1
	sub $t2, $t0, $t1
	lw $t0, 356($sp)
	sw $t0, -8($sp)
	sw $t2, -4($sp)
	jal _addList
	sw $v0, 276($sp)
	lw $t0, global_169
	li $t1, 2
	sub $t2, $t0, $t1
	lw $t0, global_170
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 232($sp)
	sw $t2, -8($sp)
	lw $t0, 232($sp)
	sw $t0, -4($sp)
	jal _addList
	sw $v0, 308($sp)
	lw $t0, global_169
	li $t1, 2
	add $t2, $t0, $t1
	lw $t0, global_170
	li $t1, 1
	sub $t1, $t0, $t1
	sw $t1, 176($sp)
	sw $t2, -8($sp)
	lw $t0, 176($sp)
	sw $t0, -4($sp)
	jal _addList
	sw $v0, 392($sp)
	lw $t0, global_169
	li $t1, 2
	add $t2, $t0, $t1
	lw $t0, global_170
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 252($sp)
	sw $t2, -8($sp)
	lw $t0, 252($sp)
	sw $t0, -4($sp)
	jal _addList
	sw $v0, 244($sp)
	lw $t0, global_174
	li $t1, 1
	seq $t1, $t0, $t1
	sw $t1, 204($sp)
	lw $t0, 204($sp)
	beqz $t0, _alternative847
_consequence846:
	b _OutOfWhile845
	b _OutOfIf848
_alternative847:
	b _OutOfIf848
_OutOfIf848:
	lw $t0, global_164
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 384($sp)
	lw $t0, 384($sp)
	sw $t0, global_164
	b _WhileLoop817
_OutOfWhile845:
	lw $t0, global_174
	li $t1, 1
	seq $t1, $t0, $t1
	sw $t1, 144($sp)
	lw $t0, 144($sp)
	beqz $t0, _alternative850
_consequence849:
	lw $t0, global_167
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 180($sp)
	lw $t0, global_176
	lw $t1, 180($sp)
	add $t1, $t0, $t1
	sw $t1, 360($sp)
	lw $t1, 360($sp)
	lw $t2, 0($t1)
	lw $t0, global_168
	li $t1, 4
	mul $t3, $t0, $t1
	add $t1, $t2, $t3
	sw $t1, 216($sp)
	lw $t1, 216($sp)
	lw $t0, 0($t1)
	sw $t0, 228($sp)
	lw $a0, 228($sp)
	jal func__toString
	sw $v0, 220($sp)
	lw $a0, 220($sp)
	jal func__println
	sw $v0, 372($sp)
	b _OutOfIf851
_alternative850:
	la $a0, string_133
	jal func__print
	sw $v0, 236($sp)
	b _OutOfIf851
_OutOfIf851:
	li $v0, 0
	b _EndOfFunctionDecl808
_EndOfFunctionDecl808:
	lw $ra, 120($sp)
	lw $t2, 40($sp)
	lw $t3, 44($sp)
	lw $t4, 48($sp)
	lw $t5, 52($sp)
	lw $t6, 56($sp)
	lw $t7, 60($sp)
	lw $s0, 64($sp)
	lw $s1, 68($sp)
	lw $s2, 72($sp)
	lw $s3, 76($sp)
	lw $s4, 80($sp)
	lw $s5, 84($sp)
	lw $s6, 88($sp)
	lw $s7, 92($sp)
	lw $t8, 96($sp)
	lw $t9, 100($sp)
	lw $k0, 104($sp)
	lw $k1, 108($sp)
	lw $gp, 112($sp)
	lw $fp, 124($sp)
	add $sp, $sp, 400
	jr $ra
.data
_end: .asciiz "\n"
	.align 2
_buffer: .space 256
	.align 2
global_163:
.space 4
.align 2
global_164:
.space 4
.align 2
global_165:
.space 4
.align 2
global_166:
.space 4
.align 2
global_167:
.space 4
.align 2
global_168:
.space 4
.align 2
global_169:
.space 4
.align 2
global_170:
.space 4
.align 2
global_171:
.space 4
.align 2
global_172:
.space 4
.align 2
global_173:
.space 4
.align 2
global_174:
.space 4
.align 2
global_175:
.space 4
.align 2
global_176:
.space 4
.align 2
global_177:
.space 4
.align 2
global_178:
.space 4
.align 2
.word 13
string_133:
.asciiz "no solution!\n"
.align 2
