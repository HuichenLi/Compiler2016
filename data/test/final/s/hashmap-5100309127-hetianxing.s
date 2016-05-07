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
_getHash:
	sub $sp, $sp, 140
	sw $ra, 120($sp)
_BeginOfFunctionDecl647:
	lw $t0, 136($sp)
	li $t1, 237
	mul $t1, $t0, $t1
	sw $t1, 132($sp)
	lw $t0, 132($sp)
	lw $t1, global_1606
	rem $t1, $t0, $t1
	sw $t1, 128($sp)
	lw $v0, 128($sp)
	b _EndOfFunctionDecl648
_EndOfFunctionDecl648:
	lw $ra, 120($sp)
	add $sp, $sp, 140
	jr $ra
_put:
	sub $sp, $sp, 272
	sw $ra, 120($sp)
_BeginOfFunctionDecl649:
	li $t0, 0
	sw $t0, 200($sp)
	lw $t0, 264($sp)
	sw $t0, -4($sp)
	jal _getHash
	sw $v0, 144($sp)
	lw $t0, 144($sp)
	sw $t0, 228($sp)
	lw $t0, 228($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 248($sp)
	lw $t0, global_1607
	lw $t1, 248($sp)
	add $t1, $t0, $t1
	sw $t1, 156($sp)
	lw $t1, 156($sp)
	lw $t0, 0($t1)
	sw $t0, 184($sp)
	lw $t0, 184($sp)
	li $t1, 0
	seq $t1, $t0, $t1
	sw $t1, 188($sp)
	lw $t0, 188($sp)
	beqz $t0, _alternative664
	b _consequence663
_consequence663:
	lw $t0, 228($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 240($sp)
	lw $t0, global_1607
	lw $t1, 240($sp)
	add $t1, $t0, $t1
	sw $t1, 204($sp)
	li $t0, 3
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 196($sp)
	lw $a0, 196($sp)
	li $v0, 9
	syscall
	sw $v0, 208($sp)
	lw $t0, 208($sp)
	sw $t0, 168($sp)
	lw $t0, 168($sp)
	lw $t1, 204($sp)
	sw $t0, 0($t1)
	lw $t0, 228($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 164($sp)
	lw $t0, global_1607
	lw $t1, 164($sp)
	add $t1, $t0, $t1
	sw $t1, 148($sp)
	lw $t1, 148($sp)
	lw $t0, 0($t1)
	sw $t0, 152($sp)
	lw $t0, 264($sp)
	lw $t1, 152($sp)
	sw $t0, 0($t1)
	lw $t0, 228($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 140($sp)
	lw $t0, global_1607
	lw $t1, 140($sp)
	add $t1, $t0, $t1
	sw $t1, 256($sp)
	lw $t1, 256($sp)
	lw $t0, 0($t1)
	sw $t0, 160($sp)
	lw $t0, 268($sp)
	lw $t1, 160($sp)
	sw $t0, 4($t1)
	lw $t0, 228($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 136($sp)
	lw $t0, global_1607
	lw $t1, 136($sp)
	add $t1, $t0, $t1
	sw $t1, 220($sp)
	lw $t1, 220($sp)
	lw $t0, 0($t1)
	sw $t0, 172($sp)
	li $t0, 0
	lw $t1, 172($sp)
	sw $t0, 8($t1)
	b _EndOfFunctionDecl650
	b _OutOfIf665
_alternative664:
	b _OutOfIf665
_OutOfIf665:
	lw $t0, 228($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 224($sp)
	lw $t0, global_1607
	lw $t1, 224($sp)
	add $t1, $t0, $t1
	sw $t1, 232($sp)
	lw $t1, 232($sp)
	lw $t0, 0($t1)
	sw $t0, 244($sp)
	lw $t0, 244($sp)
	sw $t0, 200($sp)
_WhileLoop655:
	lw $t1, 200($sp)
	lw $t0, 0($t1)
	sw $t0, 236($sp)
	lw $t0, 236($sp)
	lw $t1, 264($sp)
	sne $t1, $t0, $t1
	sw $t1, 212($sp)
	lw $t0, 212($sp)
	beqz $t0, _OutOfWhile667
	b _WhileBody666
_WhileBody666:
	lw $t1, 200($sp)
	lw $t0, 8($t1)
	sw $t0, 192($sp)
	lw $t0, 192($sp)
	li $t1, 0
	seq $t1, $t0, $t1
	sw $t1, 216($sp)
	lw $t0, 216($sp)
	beqz $t0, _alternative669
	b _consequence668
_consequence668:
	li $t0, 3
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 176($sp)
	lw $a0, 176($sp)
	li $v0, 9
	syscall
	sw $v0, 260($sp)
	lw $t0, 260($sp)
	sw $t0, 132($sp)
	lw $t0, 132($sp)
	lw $t1, 200($sp)
	sw $t0, 8($t1)
	lw $t1, 200($sp)
	lw $t0, 8($t1)
	sw $t0, 128($sp)
	lw $t0, 264($sp)
	lw $t1, 128($sp)
	sw $t0, 0($t1)
	lw $t1, 200($sp)
	lw $t0, 8($t1)
	sw $t0, 252($sp)
	li $t0, 0
	lw $t1, 252($sp)
	sw $t0, 8($t1)
	b _OutOfIf670
_alternative669:
	b _OutOfIf670
_OutOfIf670:
	lw $t1, 200($sp)
	lw $t0, 8($t1)
	sw $t0, 180($sp)
	lw $t0, 180($sp)
	sw $t0, 200($sp)
	b _WhileLoop655
_OutOfWhile667:
	lw $t0, 268($sp)
	lw $t1, 200($sp)
	sw $t0, 4($t1)
_EndOfFunctionDecl650:
	lw $ra, 120($sp)
	add $sp, $sp, 272
	jr $ra
_get:
	sub $sp, $sp, 168
	sw $ra, 120($sp)
_BeginOfFunctionDecl651:
	li $t0, 0
	sw $t0, 136($sp)
	lw $t0, 164($sp)
	sw $t0, -4($sp)
	jal _getHash
	sw $v0, 152($sp)
	lw $t0, 152($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 132($sp)
	lw $t0, global_1607
	lw $t1, 132($sp)
	add $t1, $t0, $t1
	sw $t1, 140($sp)
	lw $t1, 140($sp)
	lw $t0, 0($t1)
	sw $t0, 144($sp)
	lw $t0, 144($sp)
	sw $t0, 136($sp)
_WhileLoop656:
	lw $t1, 136($sp)
	lw $t0, 0($t1)
	sw $t0, 156($sp)
	lw $t0, 156($sp)
	lw $t1, 164($sp)
	sne $t1, $t0, $t1
	sw $t1, 160($sp)
	lw $t0, 160($sp)
	beqz $t0, _OutOfWhile672
	b _WhileBody671
_WhileBody671:
	lw $t1, 136($sp)
	lw $t0, 8($t1)
	sw $t0, 128($sp)
	lw $t0, 128($sp)
	sw $t0, 136($sp)
	b _WhileLoop656
_OutOfWhile672:
	lw $t1, 136($sp)
	lw $t0, 4($t1)
	sw $t0, 148($sp)
	lw $v0, 148($sp)
	b _EndOfFunctionDecl652
_EndOfFunctionDecl652:
	lw $ra, 120($sp)
	add $sp, $sp, 168
	jr $ra
main:
	sub $sp, $sp, 208
	sw $ra, 120($sp)
_BeginOfFunctionDecl653:
	li $t0, 100
	sw $t0, global_1606
	li $t0, 100
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 160($sp)
	lw $t0, 160($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 160($sp)
	lw $a0, 160($sp)
	li $v0, 9
	syscall
	sw $v0, 204($sp)
	li $t0, 100
	lw $t1, 204($sp)
	sw $t0, 0($t1)
	lw $t0, 204($sp)
	li $t1, 4
	add $t1, $t0, $t1
	sw $t1, 204($sp)
	lw $t0, 204($sp)
	sw $t0, 152($sp)
	lw $t0, 152($sp)
	sw $t0, global_1607
	li $t0, 0
	sw $t0, 196($sp)
_ForLoop657:
	lw $t0, 196($sp)
	lw $t1, global_1606
	slt $t1, $t0, $t1
	sw $t1, 180($sp)
	lw $t0, 180($sp)
	beqz $t0, _OutOfFor674
	b _ForBody673
_ForBody673:
	lw $t0, 196($sp)
	li $t1, 4
	mul $t1, $t0, $t1
	sw $t1, 140($sp)
	lw $t0, global_1607
	lw $t1, 140($sp)
	add $t1, $t0, $t1
	sw $t1, 188($sp)
	li $t0, 0
	lw $t1, 188($sp)
	sw $t0, 0($t1)
_continueFor658:
	lw $t0, 196($sp)
	sw $t0, 192($sp)
	lw $t0, 196($sp)
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 196($sp)
	b _ForLoop657
_OutOfFor674:
	li $t0, 0
	sw $t0, 196($sp)
_ForLoop659:
	lw $t0, 196($sp)
	li $t1, 1000
	slt $t1, $t0, $t1
	sw $t1, 176($sp)
	lw $t0, 176($sp)
	beqz $t0, _OutOfFor676
	b _ForBody675
_ForBody675:
	lw $t0, 196($sp)
	sw $t0, -8($sp)
	lw $t0, 196($sp)
	sw $t0, -4($sp)
	jal _put
	sw $v0, 132($sp)
_continueFor660:
	lw $t0, 196($sp)
	sw $t0, 136($sp)
	lw $t0, 196($sp)
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 196($sp)
	b _ForLoop659
_OutOfFor676:
	li $t0, 0
	sw $t0, 196($sp)
_ForLoop661:
	lw $t0, 196($sp)
	li $t1, 1000
	slt $t1, $t0, $t1
	sw $t1, 156($sp)
	lw $t0, 156($sp)
	beqz $t0, _OutOfFor678
	b _ForBody677
_ForBody677:
	lw $a0, 196($sp)
	jal func__toString
	sw $v0, 184($sp)
	lw $a0, 184($sp)
	la $a1, string_1688
	jal func__stringConcatenate
	sw $v0, 200($sp)
	lw $t0, 196($sp)
	sw $t0, -4($sp)
	jal _get
	sw $v0, 148($sp)
	lw $a0, 148($sp)
	jal func__toString
	sw $v0, 168($sp)
	lw $a0, 200($sp)
	lw $a1, 168($sp)
	jal func__stringConcatenate
	sw $v0, 164($sp)
	lw $a0, 164($sp)
	jal func__println
	sw $v0, 172($sp)
_continueFor662:
	lw $t0, 196($sp)
	sw $t0, 144($sp)
	lw $t0, 196($sp)
	li $t1, 1
	add $t1, $t0, $t1
	sw $t1, 196($sp)
	b _ForLoop661
_OutOfFor678:
	li $v0, 0
	b _EndOfFunctionDecl654
_EndOfFunctionDecl654:
	lw $ra, 120($sp)
	add $sp, $sp, 208
	jr $ra
.data
_end: .asciiz "\n"
	.align 2
_buffer: .space 256
	.align 2
global_1606:
.space 4
.align 2
global_1607:
.space 4
.align 2
.word 1
string_1688:
.asciiz " "
.align 2
