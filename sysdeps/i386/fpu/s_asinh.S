/* ix87 specific implementation of arcsinh.
   Copyright (C) 1996-1997, 2005, 2012 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>, 1996.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  */

#include <machine/asm.h>

	.section .rodata

	.align ALIGNARG(4)
	.type huge,@object
huge:	.double 1e+300
	ASM_SIZE_DIRECTIVE(huge)
	.type one,@object
one:	.double 1.0
	ASM_SIZE_DIRECTIVE(one)
	.type limit,@object
limit:	.double 0.29
	ASM_SIZE_DIRECTIVE(limit)

#ifdef PIC
#define MO(op) op##@GOTOFF(%edx)
#else
#define MO(op) op
#endif

	.text
ENTRY(__asinh)
	movl	8(%esp), %ecx
	movl	$0x7fffffff, %eax
	andl	%ecx, %eax
	andl	$0x80000000, %ecx
	movl	%eax, %edx
	orl	$0x800fffff, %edx
	incl	%edx
	jz	7f			// x in ?Inf or NaN
	xorl	%ecx, 8(%esp)
	fldl	4(%esp)			// |x|
	cmpl	$0x3e300000, %eax
	jb	2f			// |x| < 2^-28
	fldln2				// log(2) : |x|
	cmpl	$0x41b00000, %eax
	fxch				// |x| : log(2)
	ja	3f			// |x| > 2^28
#ifdef	PIC
	LOAD_PIC_REG (dx)
#endif
	cmpl	$0x40000000, %eax
	ja	5f			// |x| > 2

	// 2^-28 <= |x| <= 2 => y = sign(x)*log1p(|x|+|x|^2/(1+sqrt(1+|x|^2)))
	fld	%st			// |x| : |x| : log(2)
	fmul	%st(1)			// |x|^2 : |x| : log(2)
	fld	%st			// |x|^2 : |x|^2 : |x| : log(2)
	faddl	MO(one)			// 1+|x|^2 : |x|^2 : |x| : log(2)
	fsqrt				// sqrt(1+|x|^2) : |x|^2 : |x| : log(2)
	faddl	MO(one)			// 1+sqrt(1+|x|^2) : |x|^2 : |x| : log(2)
	fdivrp				// |x|^2/(1+sqrt(1+|x|^2)) : |x| : log(2)
	faddp				// |x|+|x|^2/(1+sqrt(1+|x|^2)) : log(2)
	fcoml	MO(limit)
	fnstsw
	sahf
	ja	6f
	fyl2xp1
	jecxz	4f
	fchs
4:	ret

7:	fldl	4(%esp)
	ret

6:	faddl	MO(one)
	fyl2x
	jecxz	4f
	fchs
4:	ret

	// |x| < 2^-28 => y = x (inexact iff |x| != 0.0)
	.align ALIGNARG(4)
2:
#ifdef	PIC
	LOAD_PIC_REG (dx)
#endif
	jecxz	4f
	fchs				// x
4:	fld	%st			// x : x
	faddl	MO(huge)		// huge+x : x
	fstp	%st(0)			// x
	ret

	// |x| > 2^28 => y = sign(x) * (log(|x|) + log(2))
	.align ALIGNARG(4)
3:	fyl2x				// log(|x|)
	fldln2				// log(2) : log(|x|)
	faddp				// log(|x|)+log(2)
	jecxz	4f
	fchs
4:	ret

	// |x| > 2 => y = sign(x) * log(2*|x| + 1/(|x|+sqrt(x*x+1)))
	.align ALIGNARG(4)
5:	fld	%st			// |x| : |x| : log(2)
	fadd	%st, %st(1)		// |x| : 2*|x| : log(2)
	fld	%st			// |x| : |x| : 2*|x| : log(2)
	fmul	%st(1)			// |x|^2 : |x| : 2*|x| : log(2)
	faddl	MO(one)			// 1+|x|^2 : |x| : 2*|x| : log(2)
	fsqrt				// sqrt(1+|x|^2) : |x| : 2*|x| : log(2)
	faddp				// |x|+sqrt(1+|x|^2) : 2*|x| : log(2)
	fdivrl	MO(one)			// 1/(|x|+sqrt(1+|x|^2)) : 2*|x| : log(2)
	faddp				// 2*|x|+1/(|x|+sqrt(1+|x|^2)) : log(2)
	fyl2x				// log(2*|x|+1/(|x|+sqrt(1+|x|^2)))
	jecxz	4f
	fchs
4:	ret
END(__asinh)
weak_alias (__asinh, asinh)
