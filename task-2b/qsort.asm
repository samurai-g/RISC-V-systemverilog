###############################################################################
# Startup code
#
# Initializes the stack pointer, calls main, and stops simulation.
#
# Memory layout:
#   0 ... ~0x300  program
#   0x7EC       Top of stack, growing down
#   0x7FC       stdin/stdout
#
###############################################################################

.org 0x00
_start:
  ADDI sp, zero, 0x7EC
  ADDI fp, sp, 0

  # set saved registers to unique default values
  # to make checking for correct preservation easier
  LUI  s1, 0x11111
  ADDI s1, s1, 0x111
  ADD  s2, s1, s1
  ADD  s3, s2, s1
  ADD  s4, s3, s1
  ADD  s5, s4, s1
  ADD  s6, s5, s1
  ADD  s7, s6, s1
  ADD  s8, s7, s1
  ADD  s9, s8, s1
  ADD  s10, s9, s1
  ADD  s11, s10, s1

  JAL  ra, main
  EBREAK

###############################################################################
# Function: void qsort(int* A, int l, int r)
#
# Quicksort selects an element as pivot and partitions the other elements into two sub-arrays
# The sub-arrays are then sorted recursively
#
###############################################################################
qsort:
  JALR zero, 0(ra)

###############################################################################
# Function: int input(int *A)
#
# Reads at most 10 values from stdin to the input array.
#
# Input args:
# a0: address for array A
# Return value:
# a0: Number of read elements
#
###############################################################################
input:
  ADDI t0, a0, 0                  # Save a0
  LW   a0, 0x7fc(zero)            # Load size
  ADDI t1, zero, 10               # Maximum
  ADDI t2, zero, 0                # Loop counter
.before_input_loop:
  BGE  t2, t1, .after_input_loop  # Maximum values reached
  BGE  t2, a0, .after_input_loop  # All values read

  # Read from stdin in store in array A
  LW   t3, 0x7fc(zero)
  SW   t3, 0(t0)
  # Pointer increments
  ADDI t0, t0, 4

  ADDI t2, t2, 1                  # Increment loop counter
  JAL  zero, .before_input_loop   # Jump to loop begin

.after_input_loop:
  JALR zero, 0(ra)

###############################################################################
# Function: void output(int size, int* A)
#
# Prints input and output values to stdout
#
# Input args:
# a0: Number of elements
# a1: address for array A
#
###############################################################################
output:
.before_output_loop:
  BEQ  a0, zero, .after_output_loop
  # Load values
  LW   t0, 0(a1)
  # Output Values to stdout
  SW   t0, 0x7fc(zero)
  # Pointer increments
  ADDI a1, a1, 4
  # Decrement loop counter
  ADDI a0, a0, -1
  # jump to beginning
  JAL  zero, .before_output_loop

.after_output_loop:
  JALR zero, 0(ra)

###############################################################################
# Function: main
#
# Calls input, qsort, and output
#
###############################################################################
main:
  ADDI sp, sp, -64
  SW   ra, 60(sp)
  SW   s0, 56(sp)
  ADDI s0, sp, 64

  ADDI a0, s0, -52                # array A
  JAL  ra, input
  SW   a0, -56(s0)                # size

  ADDI a2, a0, -1                 # size - 1
  ADDI a1, zero, 0                # 0
  ADDI a0, s0, -52                # array A
  JAL  ra, qsort

  LW   a0, -56(s0)                # size
  ADDI a1, s0, -52                # array A
  JAL  ra, output

  ADDI a0, zero, 0                # return 0;

  LW   s0, 56(sp)
  LW   ra, 60(sp)
  ADDI sp, sp, 64
  JALR zero, 0(ra)
