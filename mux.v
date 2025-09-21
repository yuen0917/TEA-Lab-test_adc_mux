`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2022/08/04 15:45:21
// Design Name:
// Module Name: mux
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


// module mux(clk,rst,start,S_AXIS_tdata,S_AXIS_tready,S_AXIS_tvalid,S_AXIS_tlast,data1,data2,data3,data4,data5,data6,data7,data8,flag1_in,flag2_in,flag3_in,flag4_in,flag5_in,flag6_in,flag7_in,flag8_in,flag1_out,flag2_out,flag3_out,flag4_out,flag5_out,flag6_out,flag7_out,flag8_out);
// input rst,clk,start,S_AXIS_tready;
// input data1,data2,data3,data4,data5,data6,data7,data8;
// input flag1_in,flag2_in,flag3_in,flag4_in,flag5_in,flag6_in,flag7_in,flag8_in;
// output flag1_out,flag2_out,flag3_out,flag4_out,flag5_out,flag6_out,flag7_out,flag8_out;
// output S_AXIS_tdata,S_AXIS_tvalid,S_AXIS_tlast;

// wire [31:0] data1;
// wire [31:0] data2;
// wire [31:0] data3;
// wire [31:0] data4;
// wire [31:0] data5;
// wire [31:0] data6;
// wire [31:0] data7;
// wire [31:0] data8;

// wire flag1_in,flag2_in,flag3_in,flag4_in,flag5_in,flag6_in,flag7_in,flag8_in;

// reg [127:0]     S_AXIS_tdata;
// reg [5:0]       count = 6'd0;
// reg S_AXIS_tvalid;
// reg S_AXIS_tlast;
// reg [0:0] state;
// reg flag1_out,flag2_out,flag3_out,flag4_out,flag5_out,flag6_out,flag7_out,flag8_out;
// reg init1,init2,init3,init4,init5,init6,init7,init8;
// reg init;

// initial begin
//     count <=  5'd0;
//     state <= 1'b0;
//     S_AXIS_tvalid <= 1'b0;
//     S_AXIS_tlast <= 1'b0;
//     init <= 1'b0;
// end

// always @(posedge clk or posedge rst)begin
//     if(start)begin
//         state <= 1'b1;
//     end
//     if(state)begin
//         if(rst)begin
//             count <=  5'd0;
//             S_AXIS_tvalid <= 1'b0;
//             S_AXIS_tlast <= 1'b0;
//         end
//         else begin
//             case(count)
//                 0:  begin
//                         if(S_AXIS_tready && flag1_in)begin
//                             count <=  count + 5'b1;
//                             flag1_out <= 1'b1;
//                             flag2_out <= 1'b1;
//                             flag3_out <= 1'b1;
//                             flag4_out <= 1'b1;
//                             flag5_out <= 1'b1;
//                             flag6_out <= 1'b1;
//                             flag7_out <= 1'b1;
//                             flag8_out <= 1'b1;
//                         end
//                     end
//                 1:  begin
//                         if(S_AXIS_tready && flag1_in && flag2_in && flag3_in && flag4_in)begin // flag refer to act_data_valid
//                             S_AXIS_tvalid <= 1'b1;
//                             S_AXIS_tdata <= {data4, data3, data2, data1};
//                             count <=  count + 5'b1;
//                             flag1_out <= 1'b0;
//                             flag2_out <= 1'b0;
//                             flag3_out <= 1'b0;
//                             flag4_out <= 1'b0;
//                         end
//                     end
//                 2:  begin
//                         if(S_AXIS_tready && flag5_in && flag6_in && flag7_in && flag8_in)begin
//                             S_AXIS_tdata <= {data8, data7, data6, data5};
//                             S_AXIS_tlast <= 1'b1;
//                             count <=  count + 5'b1;
//                             flag5_out <= 1'b0;
//                             flag6_out <= 1'b0;
//                             flag7_out <= 1'b0;
//                             flag8_out <= 1'b0;
//                         end
//                     end
//                 3:  begin
//                         S_AXIS_tvalid <= 1'b0;
//                         S_AXIS_tlast <= 1'b0;
//                         count <=  5'b0;
//                     end
//                 default:    count <= 5'd0;
//             endcase
//         end
//     end
// end

// endmodule

module mux(
    // regular input
    input clk,
    input rst,
    input start,
    input S_AXIS_tready,

    // data input
    input [31:0] data1,
    input [31:0] data2,
    input [31:0] data3,
    input [31:0] data4,
    input [31:0] data5,
    input [31:0] data6,
    input [31:0] data7,
    input [31:0] data8,

    // flag input
    input flag1_in,
    input flag2_in,
    input flag3_in,
    input flag4_in,
    input flag5_in,
    input flag6_in,
    input flag7_in,
    input flag8_in,

    // regular output
    output reg [127:0] S_AXIS_tdata,
    output reg S_AXIS_tvalid,
    output reg S_AXIS_tlast,

    // flag output
    output reg flag1_out,
    output reg flag2_out,
    output reg flag3_out,
    output reg flag4_out,
    output reg flag5_out,
    output reg flag6_out,
    output reg flag7_out,
    output reg flag8_out
);

    // internal reg
    reg [2:0] state;

    // state
    localparam S_IDLE   = 3'd0;
    localparam S_CHECK  = 3'd1;
    localparam S_TRANS1 = 3'd2;
    localparam S_TRANS2 = 3'd3;

    // state transition logic
    always @(posedge clk or posedge rst)begin
        if(rst)begin
            state <= S_IDLE;
        end else begin
            case(state)
                S_IDLE: begin
                    state <= start ? S_CHECK : S_IDLE;
                end
                S_CHECK: begin
                    state <= (S_AXIS_tready && {flag1_in, flag2_in, flag3_in, flag4_in} == 4'hf) ? S_TRANS1 : S_CHECK;
                end
                S_TRANS1: begin
                    state <= (S_AXIS_tready && {flag5_in, flag6_in, flag7_in, flag8_in} == 4'hf) ? S_TRANS2 : S_TRANS1;
                end
                S_TRANS2: begin
                    state <= S_IDLE;
                end
                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    // state action
    always @(posedge clk or posedge rst)begin
        if(rst)begin
            S_AXIS_tvalid <=   1'b0;
            S_AXIS_tlast  <=   1'b0;
            S_AXIS_tdata  <= 128'd0;
            {flag1_out, flag2_out, flag3_out, flag4_out, flag5_out, flag6_out, flag7_out, flag8_out} <= 8'h00;
        end else begin
            case(state)
                S_IDLE: begin
                    S_AXIS_tvalid <=   1'b0;
                    S_AXIS_tlast  <=   1'b0;
                end
                S_CHECK: begin
                    S_AXIS_tvalid <= 1'b0;
                    S_AXIS_tlast  <= 1'b0;
                    {flag1_out, flag2_out, flag3_out, flag4_out, flag5_out, flag6_out, flag7_out, flag8_out} <= 8'hff;
                end
                S_TRANS1: begin
                    S_AXIS_tdata  <= {data4, data3, data2, data1};
                    S_AXIS_tvalid <= 1'b1;
                    S_AXIS_tlast  <= 1'b0;
                    {flag1_out, flag2_out, flag3_out, flag4_out} <= 4'h0;
                end
                S_TRANS2: begin
                    S_AXIS_tdata  <= {data8, data7, data6, data5};
                    S_AXIS_tvalid <= 1'b1;
                    S_AXIS_tlast  <= 1'b1;
                    {flag5_out, flag6_out, flag7_out, flag8_out} <= 4'h0;
                end
                default: begin
                    S_AXIS_tvalid <=   1'b0;
                    S_AXIS_tlast  <=   1'b0;
                    S_AXIS_tdata  <= 128'd0;
                    {flag1_out, flag2_out, flag3_out, flag4_out, flag5_out, flag6_out, flag7_out, flag8_out} <= 8'h00;
                end
            endcase
        end
    end

endmodule
