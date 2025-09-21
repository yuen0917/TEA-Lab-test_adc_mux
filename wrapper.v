module wrapper(
  // input
  input sck,
  input ws,
  input rst,
  input start,
  input S_AXIS_tready,
  input [7:0]sd,

  // output
  output   [7:0] flag_mux_to_adc_debug,
  output   [7:0] flag_adc_to_mux_debug,
  output [127:0] S_AXIS_tdata,
  output         S_AXIS_tvalid,
  output         S_AXIS_tlast
);

  // wire
  wire [31:0] data [0:7];
  wire  [7:0] flag_adc_to_mux;
  wire  [7:0] flag_mux_to_adc;

  // assign
  assign flag_mux_to_adc_debug = flag_mux_to_adc;
  assign flag_adc_to_mux_debug = flag_adc_to_mux;

  // generate
  genvar i;

  generate
    for (i=0; i<8; i=i+1) begin : adc_inst
      adc u_adc (
        .sck(sck),
        .ws(ws),
        .sd(sd[i]),
        .rst(rst),
        .start(start),
        .data(data[i]),
        .flag_in(flag_mux_to_adc[i]),
        .flag_out(flag_adc_to_mux[i])
      );
    end
  endgenerate

  // mux
  mux m0(
    .clk(sck),
    .rst(rst),
    .start(start),
    .data1(data[0]),
    .data2(data[1]),
    .data3(data[2]),
    .data4(data[3]),
    .data5(data[4]),
    .data6(data[5]),
    .data7(data[6]),
    .data8(data[7]),
    .flag1_in(flag_adc_to_mux[0]),
    .flag2_in(flag_adc_to_mux[1]),
    .flag3_in(flag_adc_to_mux[2]),
    .flag4_in(flag_adc_to_mux[3]),
    .flag5_in(flag_adc_to_mux[4]),
    .flag6_in(flag_adc_to_mux[5]),
    .flag7_in(flag_adc_to_mux[6]),
    .flag8_in(flag_adc_to_mux[7]),
    .S_AXIS_tdata(S_AXIS_tdata),
    .S_AXIS_tvalid(S_AXIS_tvalid),
    .S_AXIS_tlast(S_AXIS_tlast),
    .S_AXIS_tready(S_AXIS_tready),
    .flag1_out(flag_mux_to_adc[0]),
    .flag2_out(flag_mux_to_adc[1]),
    .flag3_out(flag_mux_to_adc[2]),
    .flag4_out(flag_mux_to_adc[3]),
    .flag5_out(flag_mux_to_adc[4]),
    .flag6_out(flag_mux_to_adc[5]),
    .flag7_out(flag_mux_to_adc[6]),
    .flag8_out(flag_mux_to_adc[7])
);

endmodule
