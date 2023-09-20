# RISC-V-RV32I
計算機組織與結構練習

## RV32I Instructions  
R-type  
| [31:25] | [24:20] | [19:15] | [14:12] |  [11:7] |  [6:0] | | | 
| :-: | :-: | :-: | :-: | :-: | :-: | :- | :- |
| funct7 | rs1 | rs2 | funct3 |  opcode | opcode | Mnemonic | Description | 
| 0000000 | rs2 | rs1 | 000 | rd | 0110011 | ADD  | rd=rs1+rs2 |
| 0100000 | rs2 | rs1 | 000 | rd | 0110011 | SUB  | rd=rs1-rs2 |
| 0000000 | rs2 | rs1 | 001 | rd | 0110011 | SLL  | rd=rs1<<rs2[4:0] |
| 0000000 | rs2 | rs1 | 010 | rd | 0110011 | SLT  | rd=(rs1<sub>s</sub><rs2<sub>s</sub>)? 1:0 |
| 0000000 | rs2 | rs1 | 011 | rd | 0110011 | SLTU | rd=(rs1<sub>u</sub><rs2<sub>u</sub>)? 1:0 |
| 0000000 | rs2 | rs1 | 100 | rd | 0110011 | XOR  | rd=rs1^rs2 |
| 0000000 | rs2 | rs1 | 101 | rd | 0110011 | SRL  | rd=rs1>>rs2 |
| 0100000 | rs2 | rs1 | 101 | rd | 0110011 | SRA  | rd=rs1>>>rs2 |
| 0000000 | rs2 | rs1 | 100 | rd | 0110011 | OR   | rd=rs1|rs2 |
| 0000000 | rs2 | rs1 | 111 | rd | 0110011 | AND  | rd=rs1&rs2 |

I-type  
| [31:20] | [19:15] | [14:12] | [11:7] | [6:0] |  |  |
| :-: | :-: | :-: | :-: | :-: | :- | :- |
| imm[11:0] | rs1 | funct3 | rd | opcode | Mnemonic | Description |
| imm[11:0] | rs1 | 000 | rd | 0010011 | ADDI | rd=rs1+imm |
| imm[11:0] | rs1 | 010 | rd | 0010011 | SLTI | rd=(rs1<sub>s</sub><imm<sub>s</sub>)? 1:0 |
| imm[11:0] | rs1 | 011 | rd | 0010011 | SLTIU | rd=(rs1<sub>u</sub><imm<sub>u</sub>)? 1:0 |
| imm[11:0] | rs1 | 100 | rd | 0010011 | XORI | rd=rs1^imm |
| imm[11:0] | rs1 | 110 | rd | 0010011 | ORI | rd=rs1|imm |
| imm[11:0] | rs1 | 111 | rd | 0010011 | ANDI | rd=rs1&imm |
| imm[11:0] | rs1 | 010 | rd | 0000011 | LW | rd=M[rs1+imm] |
| imm[11:0] | rs1 | 001 | rd | 0000011 | LH | rd=M[rs1+imm]<sub>hs</sub> |
| imm[11:0] | rs1 | 101 | rd | 0000011 | LHU | rd=M[rs1+imm]<sub>hu</sub> |
| imm[11:0] | rs1 | 000 | rd | 0000011 | LB | rd=M[rs1+imm]<sub>bs</sub> |
| imm[11:0] | rs1 | 100 | rd | 0000011 | LBU | rd=M[rs1+imm]<sub>bu</sub> |
| imm[11:0] | rs1 | 000 | rd | 1100111 | JALR | rd=PC+4<br>PC=imm+rs1<br>(Set LSB of PC to 0)  |
| {0000000,shamt} | rs1 | 001 | rd | 0010011 | SLLI | rd=rs1<<shamt |
| {0000000,shamt} | rs1 | 101 | rd | 0010011 | SRLI | rd=rs1>>shamt |
| {0100000,shamt} | rs1 | 101 | rd | 0010011 | SRAI | rd=rs1>>>shamt |

S-type  
| [31:25] | [24:20] | [19:15] | [14:12] | [11:7] | [6:0] |  |  |
| :-: | :-: | :-: | :-: | :-: | :-: | :- | :- |
| imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode | Mnemonic | Description |
| imm[11:5] | rs2 | rs1 | 010 | imm[4:0] | 0100011 | SW | M[rs1+imm]=rs2 |
| imm[11:5] | rs2 | rs1 | 001 | imm[4:0] | 0100011 | SH | M[rs1+imm]<sub>h<sub>=rs2<sub>h<sub> |
| imm[11:5] | rs2 | rs1 | 000 | imm[4:0] | 0100011 | SB | M[rs1+imm]<sub>b<sub>=rs2<sub>b<sub> |

B-type  
| [31:25] | [24:20] | [19:15] | [14:12] | [11:7] | [6:0] |  |  |
| :-: | :-: | :-: | :-: | :-: | :-: | :- | :- |
| imm[12\|10:5] | rs2 | rs1 | funct3 | imm[4:1\|11] | opcode | Mnemonic |
| imm[12\|10:5] | rs2 | rs1 | 000 | imm[4:1\|11] | 1100011 | BEQ | PC=(rs1==rs2)?<br>PC+imm:PC+4 |
| imm[12\|10:5] | rs2 | rs1 | 001 | imm[4:1\|11] | 1100011 | BNE | PC=(rs1!=rs2)?<br>PC+imm:PC+4 |
| imm[12\|10:5] | rs2 | rs1 | 100 | imm[4:1\|11] | 1100011 | BLT | PC=(rs1<sub>s</sub><rs2<sub>s</sub>)?<br>PC+imm:PC+4 |
| imm[12\|10:5] | rs2 | rs1 | 101 | imm[4:1\|11] | 1100011 | BGE | PC=(rs1<sub>s</sub>≥rs2<sub>s</sub>)?<br>PC+imm:PC+4 |
| imm[12\|10:5] | rs2 | rs1 | 110 | imm[4:1\|11] | 1100011 | BLTU | PC=(rs1<sub>u</sub><rs2<sub>u</sub>)?<br>PC+imm:PC+4 |
| imm[12\|10:5] | rs2 | rs1 | 111 | imm[4:1\|11] | 1100011 | BGEU | PC=(rs1<sub>u</sub>≥rs2<sub>u</sub>)?<br>PC+imm:PC+4 |

U-type  
| [31:12] | [11:7] | [6:0] |  |  |
| :-: | :-: | :-: | :- | :- |
| imm[31:12] | rd | opcode | Mnemonic | Description |
| imm[31:12] | rd | 0010111 | AUIPC | rd=PC+imm |
| imm[31:12] | rd | 0110111 | LUI | rd=imm |

J-type  
| [31:12] | [11:7] | [6:0] |  |  |
| :-: | :-: | :-: | :- | :- |
| imm[20\|10:1\|11\|19:12] | rd | opcode | Mnemonic | Description |
| imm[20\|10:1\|11\|19:12] | rd | 1101111 | JAL | rd=PC+4<br>PC=PC+imm |


## 進度
1. Single cycle
    - 2023/08/14
    - <img src="https://i.imgur.com/XOOqGEV.jpg" width="637" height="241" />
2. Pipelined
    - 60% 剩forwarding
    - <img src="https://i.imgur.com/2GGB5rR.jpg" width="637" height="251" />
3. Scoreboarding
    - 0%
4. Tomasulo
    - 0%
