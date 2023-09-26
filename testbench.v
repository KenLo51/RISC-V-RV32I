`timescale 1ns/1ps
`define CYCLE_TIME 10
`define END_COUNT  10000
`define INSTR_PATH "testAsm/fibonacci_number_recursion.hex"

//*****************************************************************************
module TestBench;
//*****************************************************************************

/*iverilog */
initial
begin            
    $dumpfile("wave.vcd");        //
    $dumpvars(0, TestBench);    //
end
/*iverilog */

    ///////////////////////////////////////////////////////////////////////////
    // Parameters Declaration
    ///////////////////////////////////////////////////////////////////////////
    // Operation codes
    localparam INST_RType = 0;
    localparam INST_IType = 1;
    localparam INST_SType = 2;
    localparam INST_BType = 3;
    localparam INST_UType = 4;
    localparam INST_JType = 5;

    // Operations
    //      R-Type
    localparam OP_ADD    =  0; // Addition / Subtration
    localparam OP_SUB    =  1; // Subtration
    localparam OP_SLL    =  2; // Logic shift left
    localparam OP_SRL    =  3; // Logic Shift right
    localparam OP_SRA    =  4; // Arithmetic Shift right
    localparam OP_SLT    =  5; // Set less than (signed)
    localparam OP_SLTU   =  6; // Set less than (unsigned)
    localparam OP_XOR    =  7; // Bit wise XOR
    localparam OP_OR     =  8; // Bit wise OR
    localparam OP_AND    =  9; // Bit wise AND
    //      I-Type
    localparam OP_ADDI   = 10; // Addition with immediate
    localparam OP_SLTI   = 11; // Set less than (signed) with immediate
    localparam OP_SLTIU  = 12; // Set less than (unsigned) with immediate
    localparam OP_XORI   = 13; // Bit wise XOR with immediate
    localparam OP_ORI    = 14; // Bit wise OR with immediate
    localparam OP_ANDI   = 15; // Bit wise AND with immediate
    localparam OP_SLLI   = 16; // Logic shift left
    localparam OP_SRLI   = 17; // Logic Shift right
    localparam OP_SRAI   = 18; // Arithmetic Shift right
    
    localparam OP_JALR   = 19; // Jump and link register

    localparam OP_FENCE  = 20; // Order memory accesses

    localparam OP_LW     = 21; // Load word (32 bit) 
    localparam OP_LH     = 22; // Load half (16 bit with sign-extend)
    localparam OP_LHU    = 23; // Load half unsigned (16 bit unsigned)
    localparam OP_LB     = 24; // Load byte (8 bit with sign-extend)
    localparam OP_LBU    = 25; // Load byte unsigned (8 bit unsigned)
    //      S-Type
    localparam OP_SW     = 26; // Store word (32 bit) 
    localparam OP_SH     = 27; // Store half (16 bit) 
    localparam OP_SB     = 28; // Store byte (8 bit) 
    //      B-Type
    localparam OP_BEQ    = 29; // Branch if equal
    localparam OP_BNE    = 30; // Branch if unequal
    localparam OP_BLT    = 31; // Branch if less than
    localparam OP_BLTU   = 32; // Branch if less than (unsigned)
    localparam OP_BGE    = 33; // Branch if greater than
    localparam OP_BGEU   = 34; // Branch if greater than (unsigned)
    //      U-Type
    localparam OP_LUI    = 35; // Load upper immediate
    localparam OP_AUIPC  = 36; // Add upper immediate to pc
    //      J-Type
    localparam OP_JAL    = 37; // Jump and link


    ///////////////////////////////////////////////////////////////////////////
    // Testbench I/O and signal definitions
    ///////////////////////////////////////////////////////////////////////////

    //Internal Signals
    reg         clk;
    reg         rst;
    integer     count;
    integer     nullInst_num;

    //Other register declaration
    reg     [31:0] instr_memory  [0:255];
    reg     [ 7:0] memory        [0:2047];
    wire    [31:0] memory_int32  [0:2044];
    reg     [31:0] register_file [0: 31];
	reg     [31:0] instr;
    reg     [31:0] pc, pc_tmp;
    reg     [31:0] memAddr;

    reg     [ 2:0] funct3;
    reg     [ 6:0] funct7;
    reg     [ 6:0] opcode;
    reg     [ 4:0] rs1, rs2, rd;
    reg     [31:0] imm_32;
    integer inst_type;

    integer idx;
    genvar  block;
    integer curr_op;
    reg break;

    // Generate tested module
    CPU_top cpu
    (
        .clk_i(clk),
        .rst_n(rst)
    );

    // Memory mapping
    generate
        for(block = 0; block < 2045; block = block + 1'b1)
            assign  memory_int32[block] = {memory[3 + block], memory[2 + block], memory[1 + block], memory[0 + block]};
    endgenerate

	///////////////////////////////////////////////////////////////////////////
    // Testbench behavior
    ///////////////////////////////////////////////////////////////////////////
    // Global clock generate
    always #(`CYCLE_TIME/2) clk = ~clk;	

    // Setting RegFile and Memory initial data
    initial begin
        // Update instruction and function field
        for(idx = 0;idx < 32; idx = idx + 1)
            register_file[idx] = 32'd0;
        register_file[2]= 32'd0; //Stack pointer
        for(idx=0; idx < 2048; idx = idx + 1)
            memory[idx] = 8'b0;
        for(idx=0; idx < 256; idx = idx + 1)begin
            instr_memory[idx] = 32'h0000_0000;
            cpu.instr_memory_u.memory[idx] = 32'h0000_0000;
        end
    end

    // Testbench begin
    initial
    begin
        // Read program
        $readmemh(`INSTR_PATH, instr_memory);
        $readmemh(`INSTR_PATH, cpu.instr_memory_u.memory);


        // check readed program
        /*for(idx=0; idx < 32; idx = idx + 1)
            $display("%b", instr_memory[idx]);
        #(`CYCLE_TIME*1);*/
        //$stop;

        // Initialize
        // System
        clk = 1'b0;
        rst = 1'b0;
        count = 0;
        
        // Module
        pc     = 32'd0;
        pc_tmp = 32'd0;
        instr  = 32'd0;
        rs1    =  5'd0;
        rs2    =  5'd0;
        rd     =  5'd0;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        imm_32 = 32'd0;
        memAddr= 32'd0;
        break  = 1'b0;

        // Reset done
        @(negedge clk);

        // Start normal mode
        rst = 1'b1;
        //pc = cpu.PC.count_o; // Get PC value
        // setting up a0 register
        register_file[10] = 32'd7;
        cpu.regfile_u.register[10] = 32'd7;

        $display("Init state Cpu Register==================================================");
        $display(" r0(zero)=%d,  r1(ra)=%d,   r2(sp)=%d,   r3(gp)=%d,\n\   r4(tp)=%d,  r5(t0)=%d,   r6(t1)=%d,   r7(t2)=%d,\n\r8(s0/fp)=%d,  r9(s1)=%d,  r10(a0)=%d,  r11(a1)=%d,\n\  r12(a2)=%d, r13(a3)=%d,  r14(a4)=%d,  r15(a5)=%d,\n\  r16(a6)=%d, r17(a7)=%d,  r18(s2)=%d,  r19(s3)=%d,\n\  r20(s4)=%d, r21(s5)=%d,  r22(s6)=%d,  r23(s7)=%d,\n\  r24(s8)=%d, r25(s9)=%d, r26(s10)=%d, r27(s11)=%d,\n\  r28(t3)=%d, r29(t4)=%d,  r30(t5)=%d,  r31(t6)=%d,\n",
        cpu.regfile_u.register[0], cpu.regfile_u.register[1], cpu.regfile_u.register[2], cpu.regfile_u.register[3], cpu.regfile_u.register[4], 
        cpu.regfile_u.register[5], cpu.regfile_u.register[6], cpu.regfile_u.register[7], cpu.regfile_u.register[8], cpu.regfile_u.register[9], 
        cpu.regfile_u.register[10], cpu.regfile_u.register[11], cpu.regfile_u.register[12], cpu.regfile_u.register[13], cpu.regfile_u.register[14],
        cpu.regfile_u.register[15], cpu.regfile_u.register[16], cpu.regfile_u.register[17], cpu.regfile_u.register[18], cpu.regfile_u.register[19], 
        cpu.regfile_u.register[20], cpu.regfile_u.register[21], cpu.regfile_u.register[22], cpu.regfile_u.register[23], cpu.regfile_u.register[24], 
        cpu.regfile_u.register[25], cpu.regfile_u.register[26], cpu.regfile_u.register[27], cpu.regfile_u.register[28], cpu.regfile_u.register[29],
        cpu.regfile_u.register[30], cpu.regfile_u.register[31]);
        $display("Init state Correct Register==============================================");
        $display(" r0(zero)=%d,  r1(ra)=%d,   r2(sp)=%d,   r3(gp)=%d,\n\   r4(tp)=%d,  r5(t0)=%d,   r6(t1)=%d,   r7(t2)=%d,\n\r8(s0/fp)=%d,  r9(s1)=%d,  r10(a0)=%d,  r11(a1)=%d,\n\  r12(a2)=%d, r13(a3)=%d,  r14(a4)=%d,  r15(a5)=%d,\n\  r16(a6)=%d, r17(a7)=%d,  r18(s2)=%d,  r19(s3)=%d,\n\  r20(s4)=%d, r21(s5)=%d,  r22(s6)=%d,  r23(s7)=%d,\n\  r24(s8)=%d, r25(s9)=%d, r26(s10)=%d, r27(s11)=%d,\n\  r28(t3)=%d, r29(t4)=%d,  r30(t5)=%d,  r31(t6)=%d,\n",
        register_file[0], register_file[1], register_file[2], register_file[3], register_file[4], 
        register_file[5], register_file[6], register_file[7], register_file[8], register_file[9], 
        register_file[10], register_file[11], register_file[12], register_file[13], register_file[14],
        register_file[15], register_file[16], register_file[17], register_file[18], register_file[19], 
        register_file[20], register_file[21], register_file[22], register_file[23], register_file[24], 
        register_file[25], register_file[26], register_file[27], register_file[28], register_file[29],
        register_file[30], register_file[31]);
        
        // Do until all instruction finished
        while(!break)begin

            //$display("Executing at pc = %h", pc);
            pc_tmp = pc;     // Present PC value
            instr = instr_memory[pc_tmp>>2];
            pc = pc + 32'd4; // Step PC for 4

            opcode = instr[6:0];
            //$display("    instr  = %b", instr);
            //$display("    opcode = %b", opcode);
            if (instr != 32'd0) begin

                // Check opcode
                case(opcode)
                    // R-Type
                    7'b0110011 : 
                        inst_type = INST_RType;
                    // I-Type
                    7'b0000011, 7'b0010011, 7'b1100111 : 
                        inst_type = INST_IType;
                    // S-Type
                    7'b0100011 : 
                        inst_type = INST_SType;
                    // B-Type
                    7'b1100011 : 
                        inst_type = INST_BType;
                    // U-Type
                    7'b0010111, 7'b0110111 : 
                        inst_type = INST_UType;
                    // J-type
                    7'b1101111 :
                        inst_type = INST_JType;
                    // Unknow opcode
                    default : begin
                        $display("ERROR::OPCODE Invalid op code!!(%b) Simulation stopped.\n", instr);
                        $display("              opcode = %b", instr[6:0]);
                        #(`CYCLE_TIME*1);
                        $stop;
                    end
                endcase
            end

            // Decode instruction to rs1, rs2, rd, imm, and type of operation
            case(inst_type)
                INST_RType : begin
                    funct7 = instr[31:25];
                    funct3 = instr[14:12];
                    rs1 = instr[19:15];
                    rs2 = instr[24:20];
                    rd = instr[11:7];
                    case({funct7, funct3, opcode})
                        17'b0000000_000_0110011 : curr_op = OP_ADD;
                        17'b0100000_000_0110011 : curr_op = OP_SUB;
                        17'b0000000_001_0110011 : curr_op = OP_SLL;
                        17'b0000000_101_0110011 : curr_op = OP_SRL;
                        17'b0100000_101_0110011 : curr_op = OP_SRA;
                        17'b0000000_010_0110011 : curr_op = OP_SLT;
                        17'b0000000_011_0110011 : curr_op = OP_SLTU;
                        17'b0000000_111_0110011 : curr_op = OP_AND;
                        17'b0000000_110_0110011 : curr_op = OP_OR;
                        17'b0000000_100_0110011 : curr_op = OP_XOR;

                        default : begin
                            $display("ERROR::INSTRUCTION Invalid R-Type instruction!!(%b) Simulation stopped.\n", instr);
                            #(`CYCLE_TIME*1);
                            $stop;
                        end
                    endcase
                    //$display("R-Type");
                    //$display("    rd=%d, rs1=%d, rs2=%d, imm=%d", rd, rs1, rs2, imm_32);
                end
                INST_IType : begin
                    funct3 = instr[14:12];
                    rs1 = instr[19:15];
                    imm_32 = {{20{instr[31]}}, {instr[31:20]}};
                    rd = instr[11:7];
                    memAddr = register_file[rs1] + imm_32;
                    case({funct3, opcode})
                        10'b010_0000011 : curr_op = OP_LW;
                        10'b001_0000011 : curr_op = OP_LH;
                        10'b101_0000011 : curr_op = OP_LHU;
                        10'b000_0000011 : curr_op = OP_LB;
                        10'b100_0000011 : curr_op = OP_LBU;

                        10'b000_0010011 : curr_op = OP_ADDI;
                        10'b010_0010011 : curr_op = OP_SLTI;
                        10'b011_0010011 : curr_op = OP_SLTIU;
                        10'b111_0010011 : curr_op = OP_ANDI;
                        10'b110_0010011 : curr_op = OP_ORI;
                        10'b100_0010011 : curr_op = OP_XORI;

                        10'b001_0010011 : begin
                            imm_32 = instr[24:20];
                            if(instr[31:20] == 7'b0000000) curr_op = OP_SLLI;
                            else begin
                                $display("ERROR::INSTRUCTION Invalid shifting instruction!!(%b) Simulation stopped.\n", instr);
                                #(`CYCLE_TIME*1);
                                $stop;
                            end
                        end
                        10'b101_0010011 : begin
                            imm_32 = instr[24:20];
                            if(instr[31:20] == 7'b0000000) curr_op = OP_SRLI;
                            else if(instr[31:20] == 7'b0100000) curr_op = OP_SRAI;
                            else begin
                                $display("ERROR::INSTRUCTION Invalid shifting instruction!!(%b) Simulation stopped.\n", instr);
                                #(`CYCLE_TIME*1);
                                $stop;
                            end
                        end 

                        10'b000_1100111 : curr_op = OP_JALR;
                        default : begin
                            $display("ERROR::INSTRUCTION Invalid I-Type instruction!!(%b) Simulation stopped.\n", instr);
                            #(`CYCLE_TIME*1);
                            $stop;
                        end
                    endcase
                    //$display("I-Type");
                    //$display("    rd=%d, rs1=%d, imm=%d", rd, rs1, imm_32);
                end
                INST_SType : begin
                    funct3 = instr[14:12];
                    rs1 = instr[19:15];
                    rs2 = instr[24:20];
                    imm_32 = {{20{instr[31]}}, {instr[31:25], instr[11:7]}};
                    memAddr = register_file[rs1] + imm_32;
                    case({funct3, opcode})
                        10'b010_0100011 : curr_op = OP_SW;
                        10'b000_0100011 : curr_op = OP_SB;
                        10'b001_0100011 : curr_op = OP_SH;
                        default : begin
                            $display("ERROR::INSTRUCTION Invalid S-Type instruction!!(%b) Simulation stopped.\n", instr);
                            #(`CYCLE_TIME*1);
                            $stop;
                        end
                    endcase
                    //$display("S-Type");
                    //$display("    rs1=%d, rs2=%d, imm=%d", rs1, rs2, imm_32);
                end
                INST_BType : begin
                    funct3 = instr[14:12];
                    rs1 = instr[19:15];
                    rs2 = instr[24:20];
                    imm_32 = {{19{instr[31]}}, {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}};
                    memAddr = register_file[rs1] + imm_32;
                    case({funct3, opcode})
                        10'b000_1100011 : curr_op = OP_BEQ;
                        10'b001_1100011 : curr_op = OP_BNE;
                        10'b100_1100011 : curr_op = OP_BLT;
                        10'b110_1100011 : curr_op = OP_BLTU;
                        10'b101_1100011 : curr_op = OP_BGE;
                        10'b111_1100011 : curr_op = OP_BGEU;
                        default : begin
                            $display("ERROR::INSTRUCTION Invalid B-Type instruction!!(%b) Simulation stopped.\n", instr);
                            #(`CYCLE_TIME*1);
                            $stop;
                        end
                    endcase
                    //$display("B-Type");
                    //$display("    rs1=%d, rs2=%d, imm=%d", rs1, rs2, imm_32);
                end
                INST_UType : begin
                    imm_32 = {instr[31:12], 12'h000};
                    rd = instr[11:7];
                    case({funct3, opcode})
                        7'b0010111 : curr_op = OP_AUIPC;
                        7'b0110111 : curr_op = OP_LUI;
                        default : begin
                            $display("ERROR::INSTRUCTION Invalid U-Type instruction!!(%b) Simulation stopped.\n", instr);
                            #(`CYCLE_TIME*1);
                            $stop;
                        end
                    endcase
                    //$display("U-Type");
                    //$display("    rd=%d, imm=%d", rd, imm_32);
                end
                INST_JType : begin
                    imm_32 = {{11{instr[31]}}, {instr[31], instr[19:12], instr[20], instr[30:21]}, 1'b0};
                    rd = instr[11:7];
                    case({opcode})
                        7'b1101111 : curr_op = OP_JAL;
                        default : begin
                            $display("ERROR::INSTRUCTION Invalid J-Type instruction!!(%b) Simulation stopped.\n", instr);
                            #(`CYCLE_TIME*1);
                            $stop;
                        end
                    endcase
                end
            endcase

            // Execute operation
            case(curr_op)
                OP_ADD   : register_file[rd] = register_file[rs1] + register_file[rs2];
                OP_SUB   : register_file[rd] = register_file[rs1] - register_file[rs2];
                OP_SLT   : register_file[rd] = (register_file[rs1]+32'h1000_0000 < register_file[rs2]+32'h1000_0000)? 1'b1 : 1'b0;
                OP_SLTU  : register_file[rd] = (register_file[rs1] < register_file[rs2])? 1'b1 : 1'b0;
                OP_AND   : register_file[rd] = register_file[rs1] & register_file[rs2];
                OP_OR    : register_file[rd] = register_file[rs1] | register_file[rs2];
                OP_XOR   : register_file[rd] = register_file[rs1] ^ register_file[rs2];
                OP_SLL   : register_file[rd] = register_file[rs1] << register_file[rs2][4:0];
                OP_SRL   : register_file[rd] = register_file[rs1] >> register_file[rs2][4:0];
                OP_SRA   : register_file[rd] = register_file[rs1] >>> register_file[rs2][4:0];

                OP_ADDI  : register_file[rd] = register_file[rs1] + imm_32;
                OP_SLTI  : register_file[rd] = (register_file[rs1]+32'h1000_0000 < imm_32+32'h1000_0000)? 1'b1 : 1'b0;
                OP_SLTIU : register_file[rd] = (register_file[rs1] < imm_32)? 1'b1 : 1'b0;
                OP_ANDI  : register_file[rd] = register_file[rs1] & imm_32;
                OP_ORI   : register_file[rd] = register_file[rs1] | imm_32;
                OP_XORI  : register_file[rd] = register_file[rs1] ^ imm_32;
                OP_SLLI  : register_file[rd] = register_file[rs1] << imm_32[4:0];
                OP_SRLI  : register_file[rd] = register_file[rs1] >> imm_32[4:0];
                OP_SRAI  : register_file[rd] = register_file[rs1] >>> imm_32[4:0];

                OP_LW    : register_file[rd] = {memory[3+memAddr], memory[2+memAddr], memory[1+memAddr], memory[0+memAddr]};
                OP_LH    : register_file[rd] = {{16{memory[1+memAddr][7]}}, memory[1+memAddr], memory[0+memAddr]};
                OP_LHU   : register_file[rd] = {            8'h00,             8'h00, memory[1+memAddr], memory[0+memAddr]};
                OP_LB    : register_file[rd] = {{24{memory[0+memAddr][7]}}, memory[0+memAddr]};
                OP_LBU   : register_file[rd] = {            8'h00,             8'h00,             8'h00, memory[0+memAddr]};
                OP_SW    : begin
                    //$display("Store data %d to address %d", register_file[rs2], memAddr);
                    {memory[3+memAddr], memory[2+memAddr], memory[1+memAddr], memory[0+memAddr]} = register_file[rs2];
                    //$display("Stored data mem[%d] = %d", memAddr, memory[memAddr]);
                    //$display("Stored data mem[%d] = %d\n", memAddr, memory_int32[memAddr]);
                end
                OP_SH    : {memory[1+memAddr], memory[0+memAddr]} = register_file[rs2][15:0];
                OP_SB    : {memory[0+memAddr]} = register_file[rs2][7:0];
                
                OP_BEQ   : pc = (register_file[rs1] == register_file[rs2])? pc_tmp+imm_32 : pc_tmp+4;
                OP_BNE   : pc = (register_file[rs1] != register_file[rs2])? pc_tmp+imm_32 : pc_tmp+4;
                OP_BLT   : pc = (register_file[rs1]+32'h1000_0000 < register_file[rs2]+32'h1000_0000)? pc_tmp+imm_32 : pc_tmp+4;
                OP_BLTU  : pc = (register_file[rs1]               < register_file[rs2]              )? pc_tmp+imm_32 : pc_tmp+4;
                OP_BGE   : pc = (register_file[rs1]+32'h1000_0000 > register_file[rs2]+32'h1000_0000)? pc_tmp+imm_32 : pc_tmp+4;
                OP_BGEU  : pc = (register_file[rs1]               > register_file[rs2]              )? pc_tmp+imm_32 : pc_tmp+4;

                OP_AUIPC : register_file[rd] = pc_tmp + imm_32;
                OP_LUI   : register_file[rd] = imm_32;

                OP_JAL   : begin
                    register_file[rd] = pc_tmp + 4;
                    pc = pc_tmp + imm_32;
                end
                OP_JALR  : begin
                    register_file[rd] = pc_tmp + 4;
                    pc = (imm_32 + register_file[rs1])&32'hffff_fffe;
                end
                default : begin
                    $display("ERROR::EXECUTION\n");
                    #(`CYCLE_TIME*1);
                    $stop;
                end
            endcase

            if(instr_memory[pc>>2] == 32'h0000_0000) begin
                $display("INFO::DONE Done with all instruction has been executed");
                break = 1'b1;
            end
            else if((count+1) == `END_COUNT) begin
                $display("INFO::DONE Done with executed `END_COUNT(%d) instructions", `END_COUNT);
                break = 1'b1;
            end
            else count = count + 1;

            register_file[0] = 32'h0000_0000;

            // wait clock
            @(posedge clk);

            // 
            // $display("Cpu Memory====================================================");
            // $display("m0=%d, m1=%d, m2=%d, m3=%d,\n\m4=%d, m5=%d, m6=%d, m7=%d,\n\m8=%d, m9=%d, m10=%d, m11=%d,\n\m12=%d, m13=%d, m14=%d, m15=%d,\n\m16=%d, m17=%d, m18=%d, m19=%d,\n\m20=%d, m21=%d, m22=%d, m23=%d,\n\m24=%d, m25=%d, m26=%d, m27=%d,\n\m28=%d, m29=%d, m30=%d, m31=%d,\n",
            // cpu.data_memory_u.memory[0], cpu.data_memory_u.memory[1], cpu.data_memory_u.memory[2], cpu.data_memory_u.memory[3], cpu.data_memory_u.memory[4], 
            // cpu.data_memory_u.memory[5], cpu.data_memory_u.memory[6], cpu.data_memory_u.memory[7], cpu.data_memory_u.memory[8], cpu.data_memory_u.memory[9], 
            // cpu.data_memory_u.memory[10], cpu.data_memory_u.memory[11], cpu.data_memory_u.memory[12], cpu.data_memory_u.memory[13], cpu.data_memory_u.memory[14],
            // cpu.data_memory_u.memory[15], cpu.data_memory_u.memory[16], cpu.data_memory_u.memory[17], cpu.data_memory_u.memory[18], cpu.data_memory_u.memory[19], 
            // cpu.data_memory_u.memory[20], cpu.data_memory_u.memory[21], cpu.data_memory_u.memory[22], cpu.data_memory_u.memory[23], cpu.data_memory_u.memory[24], 
            // cpu.data_memory_u.memory[25], cpu.data_memory_u.memory[26], cpu.data_memory_u.memory[27], cpu.data_memory_u.memory[28], cpu.data_memory_u.memory[29],
            // cpu.data_memory_u.memory[30], cpu.data_memory_u.memory[31]);  
            // $display("Correct Memory==============================================");
            // $display("m0=%d, m1=%d, m2=%d, m3=%d,\n\m4=%d, m5=%d, m6=%d, m7=%d,\n\m8=%d, m9=%d, m10=%d, m11=%d,\n\m12=%d, m13=%d, m14=%d, m15=%d,\n\m16=%d, m17=%d, m18=%d, m19=%d,\n\m20=%d, m21=%d, m22=%d, m23=%d,\n\m24=%d, m25=%d, m26=%d, m27=%d,\n\m28=%d, m29=%d, m30=%d, m31=%d,\n",
            // memory_int32[0], memory_int32[1], memory_int32[2], memory_int32[3], memory_int32[4], 
            // memory_int32[5], memory_int32[6], memory_int32[7], memory_int32[8], memory_int32[9], 
            // memory_int32[10], memory_int32[11], memory_int32[12], memory_int32[13], memory_int32[14],
            // memory_int32[15], memory_int32[16], memory_int32[17], memory_int32[18], memory_int32[19], 
            // memory_int32[20], memory_int32[21], memory_int32[22], memory_int32[23], memory_int32[24], 
            // memory_int32[25], memory_int32[26], memory_int32[27], memory_int32[28], memory_int32[29],
            // memory_int32[30], memory_int32[31]);
        
        end

        // wait for cpu
        nullInst_num = 0;
        while(nullInst_num <= 5) begin
            if(cpu.instr_memory_u.instr_o == 32'h0000_0000)
                nullInst_num = nullInst_num + 1;
            else
                nullInst_num = 0;

            @(posedge clk);
            count = count + 1;
        end

        $display("INFO::DONE Done at PC = %h, Num of cycles : %d", pc, count+1);
    
        $display("Cpu Register==================================================");
        $display(" r0(zero)=%d,  r1(ra)=%d,   r2(sp)=%d,   r3(gp)=%d,\n\   r4(tp)=%d,  r5(t0)=%d,   r6(t1)=%d,   r7(t2)=%d,\n\r8(s0/fp)=%d,  r9(s1)=%d,  r10(a0)=%d,  r11(a1)=%d,\n\  r12(a2)=%d, r13(a3)=%d,  r14(a4)=%d,  r15(a5)=%d,\n\  r16(a6)=%d, r17(a7)=%d,  r18(s2)=%d,  r19(s3)=%d,\n\  r20(s4)=%d, r21(s5)=%d,  r22(s6)=%d,  r23(s7)=%d,\n\  r24(s8)=%d, r25(s9)=%d, r26(s10)=%d, r27(s11)=%d,\n\  r28(t3)=%d, r29(t4)=%d,  r30(t5)=%d,  r31(t6)=%d,\n",
        cpu.regfile_u.register[0], cpu.regfile_u.register[1], cpu.regfile_u.register[2], cpu.regfile_u.register[3], cpu.regfile_u.register[4], 
        cpu.regfile_u.register[5], cpu.regfile_u.register[6], cpu.regfile_u.register[7], cpu.regfile_u.register[8], cpu.regfile_u.register[9], 
        cpu.regfile_u.register[10], cpu.regfile_u.register[11], cpu.regfile_u.register[12], cpu.regfile_u.register[13], cpu.regfile_u.register[14],
        cpu.regfile_u.register[15], cpu.regfile_u.register[16], cpu.regfile_u.register[17], cpu.regfile_u.register[18], cpu.regfile_u.register[19], 
        cpu.regfile_u.register[20], cpu.regfile_u.register[21], cpu.regfile_u.register[22], cpu.regfile_u.register[23], cpu.regfile_u.register[24], 
        cpu.regfile_u.register[25], cpu.regfile_u.register[26], cpu.regfile_u.register[27], cpu.regfile_u.register[28], cpu.regfile_u.register[29],
        cpu.regfile_u.register[30], cpu.regfile_u.register[31]);
        $display("Cpu Memory====================================================");
        $display("m0=%d, m1=%d, m2=%d, m3=%d,\n\m4=%d, m5=%d, m6=%d, m7=%d,\n\m8=%d, m9=%d, m10=%d, m11=%d,\n\m12=%d, m13=%d, m14=%d, m15=%d,\n\m16=%d, m17=%d, m18=%d, m19=%d,\n\m20=%d, m21=%d, m22=%d, m23=%d,\n\m24=%d, m25=%d, m26=%d, m27=%d,\n\m28=%d, m29=%d, m30=%d, m31=%d,\n",
        cpu.data_memory_u.memory[0], cpu.data_memory_u.memory[1], cpu.data_memory_u.memory[2], cpu.data_memory_u.memory[3], cpu.data_memory_u.memory[4], 
        cpu.data_memory_u.memory[5], cpu.data_memory_u.memory[6], cpu.data_memory_u.memory[7], cpu.data_memory_u.memory[8], cpu.data_memory_u.memory[9], 
        cpu.data_memory_u.memory[10], cpu.data_memory_u.memory[11], cpu.data_memory_u.memory[12], cpu.data_memory_u.memory[13], cpu.data_memory_u.memory[14],
        cpu.data_memory_u.memory[15], cpu.data_memory_u.memory[16], cpu.data_memory_u.memory[17], cpu.data_memory_u.memory[18], cpu.data_memory_u.memory[19], 
        cpu.data_memory_u.memory[20], cpu.data_memory_u.memory[21], cpu.data_memory_u.memory[22], cpu.data_memory_u.memory[23], cpu.data_memory_u.memory[24], 
        cpu.data_memory_u.memory[25], cpu.data_memory_u.memory[26], cpu.data_memory_u.memory[27], cpu.data_memory_u.memory[28], cpu.data_memory_u.memory[29],
        cpu.data_memory_u.memory[30], cpu.data_memory_u.memory[31]);  
    
        $display("Correct Register==============================================");
        $display(" r0(zero)=%d,  r1(ra)=%d,   r2(sp)=%d,   r3(gp)=%d,\n\   r4(tp)=%d,  r5(t0)=%d,   r6(t1)=%d,   r7(t2)=%d,\n\r8(s0/fp)=%d,  r9(s1)=%d,  r10(a0)=%d,  r11(a1)=%d,\n\  r12(a2)=%d, r13(a3)=%d,  r14(a4)=%d,  r15(a5)=%d,\n\  r16(a6)=%d, r17(a7)=%d,  r18(s2)=%d,  r19(s3)=%d,\n\  r20(s4)=%d, r21(s5)=%d,  r22(s6)=%d,  r23(s7)=%d,\n\  r24(s8)=%d, r25(s9)=%d, r26(s10)=%d, r27(s11)=%d,\n\  r28(t3)=%d, r29(t4)=%d,  r30(t5)=%d,  r31(t6)=%d,\n",
        register_file[0], register_file[1], register_file[2], register_file[3], register_file[4], 
        register_file[5], register_file[6], register_file[7], register_file[8], register_file[9], 
        register_file[10], register_file[11], register_file[12], register_file[13], register_file[14],
        register_file[15], register_file[16], register_file[17], register_file[18], register_file[19], 
        register_file[20], register_file[21], register_file[22], register_file[23], register_file[24], 
        register_file[25], register_file[26], register_file[27], register_file[28], register_file[29],
        register_file[30], register_file[31]);
        $display("Correct Memory==============================================");
        $display("m0=%d, m1=%d, m2=%d, m3=%d,\n\m4=%d, m5=%d, m6=%d, m7=%d,\n\m8=%d, m9=%d, m10=%d, m11=%d,\n\m12=%d, m13=%d, m14=%d, m15=%d,\n\m16=%d, m17=%d, m18=%d, m19=%d,\n\m20=%d, m21=%d, m22=%d, m23=%d,\n\m24=%d, m25=%d, m26=%d, m27=%d,\n\m28=%d, m29=%d, m30=%d, m31=%d,\n",
        memory_int32[0], memory_int32[1], memory_int32[2], memory_int32[3], memory_int32[4], 
        memory_int32[5], memory_int32[6], memory_int32[7], memory_int32[8], memory_int32[9], 
        memory_int32[10], memory_int32[11], memory_int32[12], memory_int32[13], memory_int32[14],
        memory_int32[15], memory_int32[16], memory_int32[17], memory_int32[18], memory_int32[19], 
        memory_int32[20], memory_int32[21], memory_int32[22], memory_int32[23], memory_int32[24], 
        memory_int32[25], memory_int32[26], memory_int32[27], memory_int32[28], memory_int32[29],
        memory_int32[30], memory_int32[31]);
        $stop;
    end
//*****************************************************************************
endmodule
