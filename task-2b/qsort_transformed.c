#include <stdio.h>

//-----------------------------------------------------------------------------
// RISC-V Register set
const size_t zero = 0;
size_t a0, a1;                      // fn args or return args
size_t a2, a3, a4, a5, a6, a7;      // fn args
size_t t0, t1, t2, t3, t4, t5, t6;  // temporaries
// Callee saved registers, must be stacked befor using it in a function!
size_t s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11;
//-----------------------------------------------------------------------------

void qsort() // void qsort(int* A, int l, int r)
{
}

void input(void)
{
    // Read size
    t0 = a0; // Save a0
    a0 = fscanf(stdin, "%08x\n", (int*)&t1);
    t4 = 1;
    if (a0 == t4) goto input_continue;
    // Early exit
    a0 = 0;
    return;

input_continue:
    t4 = 1;
    t5 = 10;
input_loop_begin:
    if(t5 == 0) goto after_input_loop;
    a0 = fscanf(stdin, "%08x\n", (int*)&t2);
    if(a0 == t4) goto continue_read;
    // Exit, because read was not successful
    a0 = t1;
    return;
continue_read:
    *(int*)t0 = t2;
    // Pointer increment for next iteration
    t0 = t0 + 4;
    // Loop counter decrement
    t5 = t5 - 1;
    goto input_loop_begin;

after_input_loop:
    a0 = t1;
    return;
}


void output(void)
{
before_output_loop:
    if (a0 == 0) goto after_output_loop;

    fprintf(stdout, "%08x\n", (unsigned int)*(int*)a1);

    // Pointer increment for next iteration
    a1 = a1 + 4;
    // Decrement loop counter
    a0 = a0 - 1;
    goto before_output_loop;

after_output_loop:
    return;
}


int main(void)
{
  int A[10];
  int size;

  a0 = (size_t) A;
  input();
  size = a0;

  a0 = (size_t) A;
  a1 = 0;
  a2 = size - 1;
  qsort();

  a0 = size;
  a1 = (size_t) A;
  output();

  return 0;
}
