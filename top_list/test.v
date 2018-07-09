`timescale  1ns/10ps
/*
module counter (
        reset_n,
        clk,
        cnt
        );

input   reset_n;
input   clk;
output  [7:0] cnt;

reg     [7:0] cnt;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
        cnt <= 8'h00;
    else
        cnt <= cnt + 8'h01;
end

endmodule
*/
module tb_cnt;  //top layer
reg     clk;
reg     reset_n;
wire [7:0]  cnt;
/*
initial begin
    #0 reset_n = 1'b0;
    #1000 reset_n = 1'b1;
end*/

//initial clk = 1'b0;
//always clk = #100 ~clk;

counter u_counter (
        .clk        (clk),
        .reset_n    (reset_n),
        .cnt        (cnt)
        );
/*
initial begin
    $display("Test for Verilog.");
    $dumpfile("test.vcd");
    $dumpvars(0, tb_cnt);
    #10000;
    $finish;
end*/

endmodule

