
# Data hazard 2
    .org 0x00

    ADDI x1, x0, 0x0000147
    ADDI x3, x0, 0x0000017
    ADDI x5, x0, 0x00004D2
    ADDI x6, x0, 0x00007C2

    SUB x2, x1, x3     # Register 2 written by sub
    AND x12, x2, x5    # 1st operand(x2) depends on sub
    OR  x13, x6, x2    # 2nd operand(x2) depends on sub

    # Write results to stdout
    SW x12, 0x7fc(x0)
    SW x13, 0x7fc(x0)

    EBREAK
