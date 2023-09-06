module ProgramCounter(
    clk_i,
    rst_n,

    en_i,

    next_pc_i,
    curr_pc_o
);
    // I/O Port Declaration
    input           clk_i;      // System clock
    input           rst_n;      // Reset

    input           en_i; // enable
    
    input    [ 31:0]next_pc_i;    // next pc inout
    output   [ 31:0]curr_pc_o;    // pc output

    //
    reg  [ 31:0] counter;
    // Behavior Declaration

    always @(negedge rst_n or posedge clk_i) begin
        if (~rst_n) begin // Initial
            counter <= 32'h0000_0000;
        end
        else if(en_i) begin
            counter <= next_pc_i;
        end
    end
    assign curr_pc_o = counter;

endmodule