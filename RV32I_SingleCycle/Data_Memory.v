`include "ConstantDefine.v"
module Data_Memory
(
    clk_i,
    addr_i,
    data_wr_i,
    MemRead_i,
    MemWrite_i,
    data_type_i,
    data_rd_o,
    hit_o
);
//*****************************************************************************
    // I/O Port Declaration
    input        clk_i;      // Clock input
    input  [31:0]addr_i;     // Memory address
    input  [31:0]data_wr_i;  // 32 bits memory write data
    input        MemRead_i;  // Memory write control signal
    input        MemWrite_i; // Memory write control signal
    input  [ 2:0]data_type_i;
    output [31:0]data_rd_o;  // 32 bits memory read data
    output       hit_o;  // memory hit

    // Global variables Declaration
    // System
    reg     [ 7:0] mem_block [0:2047]; // Address: 0x00~0x80
    wire    [31:0] memory    [0:2044]; // For Testbench to debug
    integer idx;   // index
    genvar  block; // block num

    // System conection
    // Component Initializations
    generate
        for(block = 0; block < 2045; block = block + 1'b1)
            assign  memory[block] = {mem_block[3 + block], mem_block[2 + block], mem_block[1 + block], mem_block[0 + block]};
    endgenerate
    // Output
    assign data_rd_o = (MemRead_i) ?    (data_type_i==`MEM_TYPE_INT32)?  {mem_block[addr_i+3], mem_block[addr_i+2], mem_block[addr_i+1], mem_block[addr_i]} : 
                                        (data_type_i==`MEM_TYPE_INT16)?  {            {16{mem_block[addr_i+1][7]}}, mem_block[addr_i+1], mem_block[addr_i]} : 
                                        (data_type_i==`MEM_TYPE_INT8)?   {                                   {24{mem_block[addr_i][7]}}, mem_block[addr_i]} : 
                                        (data_type_i==`MEM_TYPE_UINT16)? {                                   16'h0, mem_block[addr_i+1], mem_block[addr_i]} : 
                                        (data_type_i==`MEM_TYPE_UINT8)?  {                                                        24'h0, mem_block[addr_i]} : 
                                        {mem_block[addr_i+3], mem_block[addr_i+2], mem_block[addr_i+1], mem_block[addr_i]} : 32'd0;
//*****************************************************************************
// Initial : For Testbench to debug
    initial begin
        for(idx = 0; idx < 128; idx = idx + 1'b1)
            mem_block[idx] = 8'd0;
    end
//*****************************************************************************
// Block : Memory Write
    always@(posedge clk_i) begin
        if(MemWrite_i) begin
            //{mem_block[addr_i+3], mem_block[addr_i+2], mem_block[addr_i+1], mem_block[addr_i]} <= data_wr_i;
            case(data_type_i)
                `MEM_TYPE_INT32  : {mem_block[addr_i+3], mem_block[addr_i+2], mem_block[addr_i+1], mem_block[addr_i]} <= data_wr_i[31:0];
                `MEM_TYPE_INT16  : {                                          mem_block[addr_i+1], mem_block[addr_i]} <= data_wr_i[15:0];
                `MEM_TYPE_INT8   : {                                                               mem_block[addr_i]} <= data_wr_i[ 7:0];
                `MEM_TYPE_UINT16 : {                                          mem_block[addr_i+1], mem_block[addr_i]} <= data_wr_i[15:0];
                `MEM_TYPE_UINT8  : {                                                               mem_block[addr_i]} <= data_wr_i[ 7:0];
                default          : {mem_block[addr_i+3], mem_block[addr_i+2], mem_block[addr_i+1], mem_block[addr_i]} <= data_wr_i[31:0];
            endcase
        end
    end
//*****************************************************************************
    assign hit_o = 1'b1;
endmodule