#Test all instructions of rv32i isa for RISC-V processor:
#Instructions                                   #Calculation                    #PC         #Note

# I type instruction related to register file
main:       addi    x1, x0, 1                   # x1 = 1                        0           #initialized reg 1
            addi    x2, x0, 16                  # x2 = 16                       4           #initialized reg 2
            addi    x3, x0, -3                  # x3 = -3                       8           #initialized reg 3
            addi    x4, x0, 0                   # x4 = 0                        C           #reg for status

            addi    x5, x3, 12                  # x5 = (-3+12) = 9              10
            slli    x6, x2, 2                   # x6 = (16 << 2) = 64           14
            slti    x7, x2, -16                 # x7 = (16 > -16) = 0           18
            sltiu   x8, x2, -16                 # x8 = (u(16) < u(-16))= 1      1C
            xori    x9, x2, 18                  # x9 = (16 XOR 18) = 2          20
            srli    x10,x3, 3                   # x10= (-3 >>3) = 536870911     24          #sign changed
            srai    x11,x3, 3                   # x11= (-3 >>> 3) = -1          28          #sign not changed
            ori     x12,x3, 3                   # x12= (-3 | 3) = -1            2c
            andi    x13,x3, 3                   # x13= (-3 & 3) = 1             30

            # R type instructions
            add     x14, x2, x1                 # x14= (16 + 1) = 17            34
            sub     x15, x2, x1                 # x15= (16 - 1) = 15            38
            sll     x16, x2, x1                 # x16= (16 << 1) = 32           3c
            slt     x17, x2, x3                 # x17= (16 > -3) = 0            40
            sltu    x18, x2, x3                 # x18= (u(16) < u(-3)) = 1      44
            xor     x19, x2, x1                 # x19= (16 XOR 1) = 17          48
            srl     x20, x2, x1                 # x20= (16 >> 1) = 8            4C
            sra     x21, x2, x1                 # x21= (16 >>> 1) = 8           50
            or      x22, x2, x1                 # x22= (16 OR 1) = 17           54
            and     x23, x2, x1                 # x23= (16 AND 1) = 0           58

            # U type instruction
            lui     x24, 0x2000                 # x24= 0x02000_000              5C
            auipc   x25, 0x2000                 # x25= 0x02000_060              60

            #S type instruction
            sb      x1,  17(x2)                 # (17 + 16) = [33] = 1          64
            sh      x3,  22(x2)                 # (22 + 16) = [38] = -3         68
            sw      x2,  24(x2)                 # (24 + 16) = [40] = 16         6C

            # I type instruction for load
            lb      x26, 36(x3)                 # x26 =[36 - 3]= 1              70
            lh      x27, 41(x3)                 # x27 =[41 - 3]= -3             74
            lw      x28, 43(x3)                 # x28 =[43 - 3]= 16             78
            lbu     x29, 36(x3)                 # x29 =[36 - 3]= 1              7C
            lhu     x30, 41(x3)                 # x30 =[41 - 3]= 0x0000FFFD     80

            # Branch instructions
            addi    x4,  x0, 0                  #                               84
            addi    x6,  x0, -5                 #                               88
            addi    x7,  x0, 5                  #                               8C
target_1:   addi    x4,  x4, 1                  # x4 = A                        90
            addi    x6,  x6, 1                  # blt t0, t1, target            94
            blt     x6,  x7, target_1           # if t0 < t1 then target        98
            add     x6,  x0, x6                 # x6 = 5                        9C

            addi    x4,  x0, 0                  #                               A0
            addi    x8,  x0, -5                 #                               A4
            addi    x9,  x0, 5                  #                               A8
target_2:   addi    x4,  x4, 1                  # x4 = B                        AC
            addi    x9,  x9, -1                 # bge t0, t1, target            B0
            bge     x9,  x8, target_2           # if t0 >= t1 then target       B4
            add     x9,  x0, x9                 # x9 = -6                       B8

            addi    x4,  x0, 0                  #                               BC
            addi    x10, x0, 1                  #                               C0
            addi    x11, x0, 5                  #                               C4
target_3:   addi    x4,  x4, 1                  # x4 = 4                        C8
            addi    x10, x10, 1                 #                               CC
            bltu    x10, x11, target_3          #                               D0
            add     x10, x0, x10                # x10 = 5                       D4

            addi    x4,  x0, 0                  #                               D8
            addi    x12, x0, 1                  #                               DC
            addi    x13, x0, 5                  #                               E0
target_4:   addi    x4,  x4, 1                  # x4 = 5                        E4
            addi    x13, x13, -1                #                               E8
            bgeu    x13, x12, target_4          #                               EC
            add     x13, x0, x13                # x13 = 0                       F0

            addi    x4,  x0, 0                  #                               F4
            addi    x14, x0, 5                  #                               F8
            addi    x15, x0, 0                  #                               FC
target_5:   addi    x4,  x4, 1                  # x4 = 5                        100
            addi    x15, x15, 1                 # bne t0, t1, target            104
            bne     x15, x14, target_5          # if t0 != t1 then target       108
            add     x15, x0 , x15               # x15 = 5                       10C

            addi    x4,  x0, 0                  #                               110
            addi    x16, x0, 2                  #                               114
            addi    x17, x0, 3                  #                               118
target_6:   addi    x4,  x4, 1                  # x4 = 2                        11C
            addi    x16, x16, 1                 # x16 = 3                       120
            beq     x16, x17, target_6          # beq t0, t1, target            124
            add     x16, x0, x16                # x16 = 4                       128


            # J type instruction
            jalr    x31, x0, 308                # x31 = 130                     12C
            addi    x4 , x0, -1                 # shouldn't execute          130
            add     x31, x0, x31                # x31 = 130                     134

            # I type jump instruction
target_7:   jal     x4,  target_7               # x4 = 13C                      138
