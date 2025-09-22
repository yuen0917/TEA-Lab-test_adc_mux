`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2022/08/04 15:44:49
// Design Name:
// Module Name: adc
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

// module adc(sck,ws,sd,rst,start,data,flag_in,flag_out);
// input rst,sck,ws,sd,start,flag_in;
// output data,flag_out;


// wire flag_in;
// (* keep = "true" *) reg [31:0]      data;
// (* keep = "true" *) reg [31:0]      buffer = 32'b0;
// reg [4:0]       bit_count = 5'd0;
// reg [1:0]       delay;
// reg [0:0] state;
// reg flag_out;



// initial begin
//     bit_count <=  5'd0;
//     buffer  <=  32'b0;
//     delay   <=  1'b0;
//     flag_out <= 1'b0;
//     state <= 1'b0;
// end

// always @(posedge sck or posedge rst)begin
//     if(start)begin
//         state <= 1'b1;
//     end
//     if(state)begin
//         if(rst)begin
//             bit_count <=  5'd0;
//             buffer    <=  32'b0;
//             delay     <=  1'b0;
//             flag_out  <= 1'b0;
//         end
//         else begin
//            flag_out <= flag_in;
//            if(~ws && !flag_out)begin
//                 if(delay == 1'b0) begin
//                     delay <= 1'b1;
//                     buffer <= 32'b0;
//                     flag_out <= 1'b0;
//                 end
//                 else begin
//                     if(bit_count < 6'd24) begin
//                         buffer[6'd31-bit_count] <= sd; // put input serial data(24bit?) into buffer
//                         bit_count <=  bit_count + 5'b1;
//                     end
//                     else begin
//                         if(bit_count == 6'd24) begin
//                             data <= buffer; // if all data in one channel is loaded, buffer to output data(32bit)
//                             flag_out <= 1'b1; // tell mux the data is ready
//                             bit_count <=  bit_count + 5'b1;
//                         end
//                     end
//                 end
//            end
//            else begin
//                bit_count <= 5'd0;
//                delay   <=  1'b0;
//            end
//         end
//     end
// end

// endmodule

module adc(
    // input
    input  sck, // sck = ws*64
    input  ws,  // sample rate
    input  sd,
    input  rst,
    input  start,
    input  flag_in,

    // output
    output reg        flag_out,
    output reg [31:0] data
);

    // reg
    reg [31:0] buffer;
    reg  [4:0] bit_count;
    reg  [1:0] delay;
    reg        state;
    reg        ws_d; // ws delayed for edge detection


    // always
    always @(posedge sck or posedge rst)begin
        if(rst)begin
            state     <=  1'b0;
            delay     <=  1'b0;
            flag_out  <=  1'b0;
            bit_count <=  5'd0;
            buffer    <= 32'b0;
            data      <= 32'b0;
            ws_d      <=  1'b0;
        end else begin
            // ws edge detection
            ws_d <= ws;
            case(state)
                1'b0: begin
                    // Wait for start signal
                    state <= start ? 1'b1 : state;
                end
                1'b1: begin
                    // Ready/Valid handshake: if data is valid and ready signal received, clear valid
                    if(flag_out && flag_in) begin
                        flag_out  <= 1'b0;
                        bit_count <= 5'd0;
                        delay     <= 1'b0;
                    end
                    // Only collect new data when not holding valid data
                    else if(!flag_out) begin
                        if(!ws) begin
                            if(!delay) begin
                                // First cycle: setup delay and clear buffer
                                delay  <= 1'b1;
                                buffer <= 32'b0;
                            end else begin
                                // Collecting data (24 bits total into [31:8])
                                if(bit_count < 5'd24) begin
                                    buffer[5'd31 - bit_count] <= sd;
                                    bit_count                 <= bit_count + 5'b1;
                                end else begin
                                    // Hold at 24 until ws rises; don't assert valid here
                                    bit_count <= 5'd24;
                                end
                            end
                        end else begin
                            // ws is high: reset collection state
                            bit_count <= 5'd0;
                            delay     <= 1'b0;
                        end
                        // At ws rising edge, if 24 bits have been collected, latch and assert valid
                        if(ws && !ws_d && (bit_count >= 5'd24)) begin
                            data     <= buffer;
                            flag_out <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end
endmodule



