module Reg_File
(
    clk_i,
    rst_n,
    RegWrite_i,
    rs1_addr_i,
    rs2_addr_i,
    rd_addr_i,
    rd_data_i,
    rs1_data_o,
    rs2_data_o
);
//*****************************************************************************
    // I/O Port Declaration
    input        clk_i;      // System clock
    input        rst_n;      // All reset
    input        RegWrite_i; // Register write
    input  [ 4:0]rs1_addr_i; // rs1 index
    input  [ 4:0]rs2_addr_i; // rs2 index
    input  [ 4:0]rd_addr_i;  // rd  index
    input  [31:0]rd_data_i;  // rd  data
    output [31:0]rs1_data_o; // rs1 data
    output [31:0]rs2_data_o; // rs2 data

    // Global variables Declaration
    // System
    reg [31:0] register [0:31]; // 32 word registers
    wire [31:0] register_wire[0:31];

    // System conection
    // Output
    assign rs1_data_o = (rs1_addr_i == 5'h00)? 32'h0000_0000 : 
                        (RegWrite_i && (rd_addr_i==rs1_addr_i))? rd_data_i :
                        register[rs1_addr_i];
    assign rs2_data_o = (rs2_addr_i == 5'h00)? 32'h0000_0000 : 
                        (RegWrite_i && (rd_addr_i==rs2_addr_i))? rd_data_i :
                        register[rs2_addr_i];
//*****************************************************************************
//Writing data when postive edge clk_i and RegWrite_i was set.
    always @(negedge rst_n or posedge clk_i) 
    begin
        if (~rst_n) // Initial
        begin
            register[ 0] <= 0; register[ 1] <=   0; register[ 2] <=   0; register[ 3] <= 0;
            register[ 4] <= 0; register[ 5] <=   0; register[ 6] <=   0; register[ 7] <= 0;
            register[ 8] <= 0; register[ 9] <=   0; register[10] <=   0; register[11] <= 0;
            register[12] <= 0; register[13] <=   0; register[14] <=   0; register[15] <= 0;
            register[16] <= 0; register[17] <=   0; register[18] <=   0; register[19] <= 0;
            register[20] <= 0; register[21] <=   0; register[22] <=   0; register[23] <= 0;
            register[24] <= 0; register[25] <=   0; register[26] <=   0; register[27] <= 0;
            register[28] <= 0; register[29] <=   0; register[30] <=   0; register[31] <= 0;
        end
        else
        begin
            if (RegWrite_i) begin// Write
                if(rd_addr_i != 5'd0) // $0 cannot be write
                    register[rd_addr_i] <= rd_data_i;
            end
            else 
                register[rd_addr_i] <= register[rd_addr_i];
        end
    end
//*****************************************************************************
endmodule