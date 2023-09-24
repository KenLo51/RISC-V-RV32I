module Pipe_Reg
	#(parameter size = 5)
	(
	 // Input  Declaration
	 input  rst_i,
	 input  clk_i,
     input  stall, // keep status
     input  clear, // clear and set 0s
	 input  [size-1:0]data_i,
	 // Output Declaration
	 output [size-1:0]data_o
	);
//*****************************************************************************
	// Global variables Declaration
	// System
	reg [size-1:0]data;
	// System conection
	// Output
	assign data_o = data;
//*****************************************************************************
	always @(posedge clk_i or negedge rst_i) begin
		if(!rst_i) data <= 0;
		else begin
            case({stall, clear})
                2'b00 : data <= data_i;
                2'b01 : data <= 0;
                2'b10 : data <= data;
                2'b11 : data <= 0;
            endcase
        end
	end
//*****************************************************************************
endmodule
