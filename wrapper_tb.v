// `timescale 1ns/1ps

// module wrapper_tb;

//     // Clock / reset
//     reg  sck;
//     reg  rst;
//     reg  start;

//     // I2S-like framing
//     reg  ws;
//     // 8 serial data lines (one per channel) – all zeros per request
//     reg  [7:0] sd;
//     // AXIS sink ready
//     reg  S_AXIS_tready;
//     // DUT outputs
//     wire [127:0] S_AXIS_tdata;
//     wire         S_AXIS_tvalid;
//     wire         S_AXIS_tlast;
//     wire [7:0]   flag_mux_to_adc;
//     wire [7:0]   flag_adc_to_mux;

//     // --- Modified clock generation for 1.024 MHz ---
//     localparam real SCK_PERIOD_NS = 976.5625; // 1 / 1.024MHz in ns
//     localparam real SCK_HALF_NS   = SCK_PERIOD_NS / 2.0;

//     // Instantiate DUT
//     wrapper dut (
//         .sck(sck),
//         .ws(ws),
//         .rst(rst),
//         .start(start),
//         .S_AXIS_tready(S_AXIS_tready),
//         .sd(sd),
//         .S_AXIS_tdata(S_AXIS_tdata),
//         .S_AXIS_tvalid(S_AXIS_tvalid),
//         .S_AXIS_tlast(S_AXIS_tlast),
//         .flag_mux_to_adc_fuck(flag_mux_to_adc),
//         .flag_adc_to_mux_fuck(flag_adc_to_mux)
//     );
//     always #(SCK_HALF_NS) sck = ~sck;

//     // --- Generate ws = 16 kHz (sck / 64) ---
//     always #(31250) ws = ~ws; // unit: ns (timescale 1ns/1ps)
//      // Simplified stimulus
//      initial begin
//          sck=0;
//          S_AXIS_tready=0;
//          ws=0;
//          $display("Start simulation");
//          rst   = 0;
//          start = 0;
//          sd = 8'h00;
//          #2929.687;

//          start = 1;
//          rst   = 1;
//          sd = 8'b11111111;  // simple test value
//          S_AXIS_tready=1;
//          #2929.687;

//          start = 1;
//          rst   = 0;
//          sd = 8'b11111111;  // keep the same value
//          S_AXIS_tready=1;
//        #292968.7;

//          $display("Done");
//          $finish;
//      end

//      // Observe data stream
//      initial begin
//          $display("=== Data stream ===");
//          forever begin
//              @(posedge sck);
//              if(S_AXIS_tvalid) begin
//                  $display("time=%8t ws=%b sd=%02h tdata[127:0]=%032h",
//                          $time, ws, sd, S_AXIS_tdata[127:0]);
//                  $display("  data1=%08h data2=%08h data3=%08h data4=%08h",
//                          dut.data[0], dut.data[1], dut.data[2], dut.data[3]);
//                  $display("  data5=%08h data6=%08h data7=%08h data8=%08h",
//                          dut.data[4], dut.data[5], dut.data[6], dut.data[7]);
//                  $display("  flag_mux_to_adc=%02h flag_adc_to_mux=%02h",
//                          flag_mux_to_adc, flag_adc_to_mux);
//              end
//          end
//      end

//      // Observe flag signal changes
//      initial begin
//          $display("=== Flag signal ===");
//          forever begin
//              @(posedge sck);
//              if(flag_mux_to_adc != 8'h00 || flag_adc_to_mux != 8'h00) begin
//                  $display("time=%8t flag_mux_to_adc=%02h flag_adc_to_mux=%02h",
//                          $time, flag_mux_to_adc, flag_adc_to_mux);
//              end
//          end
//      end

// endmodule

`timescale 1ns/1ps

module wrapper_tb;

  // =======================
  // Parameters: 1.024 MHz sck
  // =======================
  localparam real SCK_PERIOD_NS = 976.5625;   // 1 / 1.024MHz
  localparam real SCK_HALF_NS   = SCK_PERIOD_NS / 2.0;

  // I/O to DUT
  reg         sck   = 1'b0;
  reg         ws    = 1'b0;
  reg         rst   = 1'b0;   // Assume rst is active high
  reg         start = 1'b0;
  reg         S_AXIS_tready = 1'b0;
  reg  [7:0]  sd    = 8'h00;

  wire [127:0] S_AXIS_tdata;
  wire         S_AXIS_tvalid;
  wire         S_AXIS_tlast;
  wire  [7:0]  flag_mux_to_adc;
  wire  [7:0]  flag_adc_to_mux;
  wire [255:0] data_debug;

  // =======================
  // DUT
  // =======================
  wrapper dut (
    .sck(sck),
    .ws(ws),
    .rst(rst),
    .start(start),
    .S_AXIS_tready(S_AXIS_tready),
    .sd(sd),
    .S_AXIS_tdata(S_AXIS_tdata),
    .S_AXIS_tvalid(S_AXIS_tvalid),
    .S_AXIS_tlast(S_AXIS_tlast),
    .flag_mux_to_adc_debug(flag_mux_to_adc),
    .flag_adc_to_mux_debug(flag_adc_to_mux),
    .data_debug(data_debug)
  );

  // =======================
  // sck: 1.024 MHz
  // =======================
  always #(SCK_HALF_NS) sck = ~sck;

  // =======================
  // ws: sck/64 = 16 kHz (synchronous divide)
  // =======================
  reg [6:0] ws_div = 7'd0;
  always @(posedge sck) begin
    if (ws_div == 7'd63) begin
      ws_div <= 7'd0;
      ws     <= ~ws;
    end else begin
      ws_div <= ws_div + 7'd1;
    end
  end

  // =======================
  // Helper: wait for n sck rising edges
  // =======================
  task wait_sck;
    input integer n;
    integer k;
    begin
      for (k = 0; k < n; k = k + 1) @(posedge sck);
    end
  endtask

   // =======================
   // Generate simulated ADC input bitstream
   // =======================
   reg [191:0] sd_pattern;  // 8x24-bit words = 192 bits
   reg [4:0] bit_counter = 5'd0;  // bit counter (0-23)

   // Update sd on every sck cycle
   always @(posedge sck or posedge rst) begin
     if (rst) begin
       sd_pattern <= {24'haaaaaa, 24'hbbbbbb, 24'hcccccc, 24'hdddddd, 24'heeeeee, 24'hffffff, 24'h111111, 24'h222222};
       sd <= 8'h00;
       bit_counter <= 5'd0;
     end else begin
       // Transmit data only when ws=0
       if (!ws) begin
        // Each ADC receives the current bit of its 24-bit word
        sd[0] <= sd_pattern[ 23 - bit_counter];      // ADC0: bits of 0xaaaaaa
        sd[1] <= sd_pattern[ 47 - bit_counter];      // ADC1: bits of 0xbbbbbb
        sd[2] <= sd_pattern[ 71 - bit_counter];      // ADC2: bits of 0xcccccc
        sd[3] <= sd_pattern[ 95 - bit_counter];      // ADC3: bits of 0xdddddd
        sd[4] <= sd_pattern[119 - bit_counter];     // ADC4: bits of 0xeeeeee
        sd[5] <= sd_pattern[143 - bit_counter];     // ADC5: bits of 0xffffff
        sd[6] <= sd_pattern[167 - bit_counter];     // ADC6: bits of 0x111111
        sd[7] <= sd_pattern[191 - bit_counter];     // ADC7: bits of 0x222222

        // Count bits, but only when ws=0
         if (bit_counter < 5'd23) begin
           bit_counter <= bit_counter + 5'd1;
         end else begin
          // After 24 bits are done, hold bit_counter=23 and wait for ws=1 to reset
           bit_counter <= 5'd23;
         end
       end else begin
        // When ws=1, reset counter to prepare next transfer
         bit_counter <= 5'd0;
        sd <= 8'h00;  // optional: clear sd when ws=1
       end
     end
   end

  // =======================
  // Test sequence
  // =======================
  initial begin
    $display("[%0t] TB start", $time);

    // Assert reset for 32 sck cycles to ensure all registers initialize
    rst = 1'b1; start = 1'b0; S_AXIS_tready = 1'b0; sd = 8'h00;
    wait_sck(32);
    rst = 1'b0;
    wait_sck(16);

    // Start DUT
    start = 1'b1;
    S_AXIS_tready = 1'b1;

    // Run 300 cycles and observe normal output
    wait_sck(300);

    // Simulate AXI backpressure: pause 20 cycles, then resume
    S_AXIS_tready = 1'b0;
    wait_sck(20);
    S_AXIS_tready = 1'b1;
    wait_sck(300);

    $display("[%0t] TB done", $time);
    $finish;
  end

  // =======================
  // Observe data stream
  // =======================
   reg [127:0] pased_data = 128'd0;
   initial begin
     $display("=== Data stream ===");
     forever begin
       @(posedge sck);
       if(S_AXIS_tvalid && pased_data != S_AXIS_tdata) begin
         pased_data <= S_AXIS_tdata;
         $display("time = %t ws = %b sd = %02h tdata[127:0] = %032h",
                 $time, ws, sd, S_AXIS_tdata[127:0]);
        $display("  data1 = %08h data2 = %08h data3 = %08h data4 = %08h",
                data_debug[ 31:  0], data_debug[ 63: 32], data_debug[ 95: 64], data_debug[127: 96]);
        $display("  data5 = %08h data6 = %08h data7 = %08h data8 = %08h",
                data_debug[159:128], data_debug[191:160], data_debug[223:192], data_debug[255:224]);
         $display("  flag_mux_to_adc = %02h flag_adc_to_mux = %02h",
                 flag_mux_to_adc, flag_adc_to_mux);
         $display("  ADC inputs: sd[0] = %b sd[1] = %b sd[2] = %b sd[3] = %b sd[4] = %b sd[5] = %b sd[6] = %b sd[7] = %b",
                 sd[0], sd[1], sd[2], sd[3], sd[4], sd[5], sd[6], sd[7]);
       end
     end
   end



  // Vivado will automatically generate a .wdb waveform; no manual dump needed
  // initial begin
  //   $dumpfile("wrapper_tb.vcd");
  //   $dumpvars(0, wrapper_tb);
  // end

endmodule
