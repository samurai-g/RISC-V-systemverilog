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

void swap()
{
    //*x = a0, *y = a1

    //prolouge
    size_t stack_s1 = s1; //tmp

    *(int*)s1 = *(int*)a0;
    *(int*)a0 = *(int*)a1;
    *(int*)a1 = *(int*)s1;

    //epilouge
    s1 = stack_s1;
    return;
}

void partition ()
{
    //*A = a0, l = a1, r = a2  

    //prolouge
    size_t stack_s1 = s1; //pivot
    size_t stack_s2 = s2; //i
    size_t stack_s3 = s3; //j

    t0 = a2 << 2; //*4 
    t0 = a0 + t0; //A[r] element in array
    t1 = s3 << 2; //*4 
    t1 = a0 + t1; //A[j] element in array

    //t2 = *(int*)(t0); //Value of r element
    //t3 = *(int*)(t1); //Value of j element
    
    s1 = t0; //pivot = A[r]
    s2 = a1 - 1; //i = l-1
    s3 = a1; //j = l

    before_partition_loop:
      if ((int)s3 >= (int)a2) //for j<r
        goto after_partition_loop;

      s3 = s3 + 1; //j++
      
      if ((int)t0 >= (int)s1) //if A[j] < pivot
        goto after_partition_if;
       
      s2 = s2 + 1; // i = i+1

      //Prepare for swap function 
      t0 = s2 << 2; //*4 
      a0 = a0 + t0; //A[i]
      t0 = s3 << 2; //*4
      a1 = a0 + t0; //A[j]
      swap();
         
    after_partition_if:
      goto before_partition_loop;
    after_partition_loop:

      s2 = s2 + 1; //i+1

      //Prepare for swap function
      t2 = s2 << 2; //*4
      a0 = a0 + t2; //A[i]
      t2 = a2 << 2; //
      a1 = a0 + t2; //A[r]
      swap();

      a0 = s2; //Return i 

      //epilogue
      s1 = stack_s1;
      s2 = stack_s2;
      s3 = stack_s3;
      return;
}

void qsort()
{
   //*A = a0; l = a1, r = a2 

   //epil
   size_t stack_s1 = s1; //k

   if (a2 >= a1)
     goto after_qsort_if;

   partition();
   s1 = a0; //k = partition() = i
   a2 = s1 - 1; //k-1
   qsort();
   a1 = s1 + 1; //k+1
   qsort();

   after_qsort_if:

   //prol
   s1 = stack_s1;
   return;   
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
