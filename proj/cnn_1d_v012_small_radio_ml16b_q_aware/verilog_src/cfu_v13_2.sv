// No write_at_once
// Uses quant 2
// Async writing to computation
`include "verilog_src/version.sv"
`ifdef CFU_VERSION_13_2
`include "verilog_src/quant_v2.sv"

module conv1d #(
    parameter BYTE_SIZE  = 8,
    parameter INT32_SIZE = 32
) (
    input                       clk,
    input                       en,
    input      [           6:0] cmd,
    input      [INT32_SIZE-1:0] inp0,
    input      [INT32_SIZE-1:0] inp1,
    output reg [INT32_SIZE-1:0] ret,
    output reg                  output_buffer_valid = 1
);
  localparam PADDING = 4;  // (8 / 2)
  localparam MAX_INPUT_SIZE = 1024;
  localparam MAX_INPUT_CHANNELS = 128;
  localparam KERNEL_LENGTH = 8;

  localparam SUM_AT_ONCE = 8;
  localparam BUFFERS_SIZE = KERNEL_LENGTH * MAX_INPUT_CHANNELS;

  wire [INT32_SIZE-1:0] address = inp0;
  wire [INT32_SIZE-1:0] value = inp1;
  wire [INT32_SIZE-1:0] cur_kernel_buffer_size = KERNEL_LENGTH * input_depth;
  wire [INT32_SIZE-1:0] cur_input_buffer_size = (input_depth == 2) ? cur_kernel_buffer_size : cur_kernel_buffer_size + input_depth;
  // wire [INT32_SIZE-1:0] cur_input_buffer_size = cur_kernel_buffer_size;

  // Buffers
  (* RAM_STYLE="BLOCK" *)
  reg signed [BYTE_SIZE-1:0] input_buffer[0:BUFFERS_SIZE + MAX_INPUT_CHANNELS - 1 + 4];

  (* RAM_STYLE="BLOCK" *)
  reg signed [BYTE_SIZE-1:0] filter_buffer[0:BUFFERS_SIZE - 1 + 3];

  // Parameters
  reg signed [INT32_SIZE-1:0] input_offset = 32'd0;
  // reg signed [INT32_SIZE-1:0] input_output_width = 32'd0;
  reg signed [INT32_SIZE-1:0] input_depth = 32'd0;

  // Quanting info
  reg signed [INT32_SIZE-1:0] bias;
  reg signed [INT32_SIZE-1:0] output_multiplier;
  reg signed [INT32_SIZE-1:0] output_shift;
  reg signed [INT32_SIZE-1:0] output_activation_min;
  reg signed [INT32_SIZE-1:0] output_activation_max;
  reg signed [INT32_SIZE-1:0] output_offset;

  wire signed [INT32_SIZE-1:0] quanted_acc;


  // Computation related registers
  reg signed [INT32_SIZE-1:0] start_filter_x = 0;
  reg finished_work = 1'b1;
  reg update_address = 1'b0;
  reg [INT32_SIZE-1:0] kernel_addr;
  reg [INT32_SIZE-1:0] input_addr;
  reg signed [INT32_SIZE-1:0] acc;

  reg waiting_for_quant = 0;
  reg start_quant = 0;
  wire quant_done;

  quant QUANT (
      .clk(clk),
      .acc(acc),

      .start(start_quant),
      .ret_valid(quant_done),

      .bias(bias),
      .output_multiplier(output_multiplier),
      .output_shift(output_shift),
      .output_activation_min(output_activation_min),
      .output_activation_max(output_activation_max),
      .output_offset(output_offset),

      .ret(quanted_acc)
  );



  always @(posedge clk) begin
    if (en) begin

      if (!finished_work) begin
        if (waiting_for_quant) begin
          start_quant <= 0;
          if (quant_done) begin
            // $display("<<<< acc after quant: %d, %d ", quanted_acc, acc);
            finished_work <= 1;
            waiting_for_quant <= 0;
          end
        end else begin
          if (update_address) begin
            kernel_addr <= kernel_addr + SUM_AT_ONCE;
            if ((input_addr + SUM_AT_ONCE) >= cur_input_buffer_size) begin
              input_addr <= input_addr + SUM_AT_ONCE - cur_input_buffer_size;
            end else begin
              input_addr <= input_addr + SUM_AT_ONCE;
            end
            update_address <= 0;
          end else begin
            if (kernel_addr >= cur_kernel_buffer_size) begin
              // $display(">>>> acc before quant: %d", acc);
              waiting_for_quant <= 1;
              start_quant <= 1;
              // finished_work <= 1;
            end else begin
              acc <= acc + 
                filter_buffer[kernel_addr     ] * (input_buffer[(input_addr     )] + input_offset) + 
                filter_buffer[kernel_addr +  1] * (input_buffer[(input_addr +  1)] + input_offset) +
                filter_buffer[kernel_addr +  2] * (input_buffer[(input_addr +  2)] + input_offset) + 
                filter_buffer[kernel_addr +  3] * (input_buffer[(input_addr +  3)] + input_offset) +
                filter_buffer[kernel_addr +  4] * (input_buffer[(input_addr +  4)] + input_offset) + 
                filter_buffer[kernel_addr +  5] * (input_buffer[(input_addr +  5)] + input_offset) + 
                filter_buffer[kernel_addr +  6] * (input_buffer[(input_addr +  6)] + input_offset) + 
                filter_buffer[kernel_addr +  7] * (input_buffer[(input_addr +  7)] + input_offset);

                // filter_buffer[kernel_addr +  8] * (input_buffer[(input_addr +  8)] + input_offset) + 
                // filter_buffer[kernel_addr +  9] * (input_buffer[(input_addr +  9)] + input_offset) +
                // filter_buffer[kernel_addr + 10] * (input_buffer[(input_addr + 10)] + input_offset) + 
                // filter_buffer[kernel_addr + 11] * (input_buffer[(input_addr + 11)] + input_offset) +
                // filter_buffer[kernel_addr + 12] * (input_buffer[(input_addr + 12)] + input_offset) + 
                // filter_buffer[kernel_addr + 13] * (input_buffer[(input_addr + 13)] + input_offset) + 
                // filter_buffer[kernel_addr + 14] * (input_buffer[(input_addr + 14)] + input_offset) + 
                // filter_buffer[kernel_addr + 15] * (input_buffer[(input_addr + 15)] + input_offset) +

                // filter_buffer[kernel_addr + 16] * (input_buffer[(input_addr + 16)] + input_offset) + 
                // filter_buffer[kernel_addr + 17] * (input_buffer[(input_addr + 17)] + input_offset) +
                // filter_buffer[kernel_addr + 18] * (input_buffer[(input_addr + 18)] + input_offset) + 
                // filter_buffer[kernel_addr + 19] * (input_buffer[(input_addr + 19)] + input_offset) +
                // filter_buffer[kernel_addr + 20] * (input_buffer[(input_addr + 20)] + input_offset) + 
                // filter_buffer[kernel_addr + 21] * (input_buffer[(input_addr + 21)] + input_offset) + 
                // filter_buffer[kernel_addr + 22] * (input_buffer[(input_addr + 22)] + input_offset) + 
                // filter_buffer[kernel_addr + 23] * (input_buffer[(input_addr + 23)] + input_offset) +

                // filter_buffer[kernel_addr + 24] * (input_buffer[(input_addr + 24)] + input_offset) + 
                // filter_buffer[kernel_addr + 25] * (input_buffer[(input_addr + 25)] + input_offset) +
                // filter_buffer[kernel_addr + 26] * (input_buffer[(input_addr + 26)] + input_offset) + 
                // filter_buffer[kernel_addr + 27] * (input_buffer[(input_addr + 27)] + input_offset) +
                // filter_buffer[kernel_addr + 28] * (input_buffer[(input_addr + 28)] + input_offset) + 
                // filter_buffer[kernel_addr + 29] * (input_buffer[(input_addr + 29)] + input_offset) + 
                // filter_buffer[kernel_addr + 30] * (input_buffer[(input_addr + 30)] + input_offset) + 
                // filter_buffer[kernel_addr + 31] * (input_buffer[(input_addr + 31)] + input_offset);
            end
            update_address <= 1;
          end
        end
      end

      case (cmd)
        // Initialize
        0: begin  // Reset module
          // Fill input with zeros
          ret <= BUFFERS_SIZE;
        end

        // Write buffers
        1: begin  // Write input buffer
          input_buffer[address]   <= value[7:0];
          input_buffer[address+1] <= value[15:8];
          input_buffer[address+2] <= value[23:16];
          input_buffer[address+3] <= value[31:24];
        end
        2: begin  // Write kernel weights buffer
          filter_buffer[address]   <= value[7:0];
          filter_buffer[address+1] <= value[15:8];
          filter_buffer[address+2] <= value[23:16];
          filter_buffer[address+3] <= value[31:24];
        end

        // Write parameters
        3: begin
          input_offset <= value;
        end

        4: begin
          // input_output_width <= value;
          ret <= 0;
        end
        5: begin
          input_depth <= value;
        end

        6: begin  // Start computation
          acc <= 0;
          finished_work <= 0;
          update_address <= 0;
          kernel_addr <= 0;
          input_addr <= start_filter_x * input_depth;

          // $display("cur_kernel_buffer_size: %d", cur_kernel_buffer_size);
          // $display("Start filter x: %d", start_filter_x);
          // $display("input buffer: \n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d",
          //          input_buffer[ 0], input_buffer[ 1], input_buffer[ 2], input_buffer[ 3], input_buffer[ 4], 
          //          input_buffer[ 5], input_buffer[ 6], input_buffer[ 7], input_buffer[ 8], input_buffer[ 9], 
          //          input_buffer[10], input_buffer[11], input_buffer[12], input_buffer[13], input_buffer[14], 
          //          input_buffer[15], input_buffer[16], input_buffer[17], input_buffer[18], input_buffer[19],
          //          input_buffer[20], input_buffer[21], input_buffer[22], input_buffer[23], input_buffer[24], 
          //          input_buffer[25], input_buffer[26], input_buffer[27], input_buffer[28], input_buffer[29], 
          //          input_buffer[30], input_buffer[31] 
          //          );
          // $display("filter buffer: \n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d\n%d - %d - %d - %d",
          //          filter_buffer[ 0], filter_buffer[ 1], filter_buffer[ 2], filter_buffer[ 3], filter_buffer[ 4], 
          //          filter_buffer[ 5], filter_buffer[ 6], filter_buffer[ 7], filter_buffer[ 8], filter_buffer[ 9], 
          //          filter_buffer[10], filter_buffer[11], filter_buffer[12], filter_buffer[13], filter_buffer[14], 
          //          filter_buffer[15], filter_buffer[16], filter_buffer[17], filter_buffer[18], filter_buffer[19],
          //          filter_buffer[20], filter_buffer[21], filter_buffer[22], filter_buffer[23], filter_buffer[24], 
          //          filter_buffer[25], filter_buffer[26], filter_buffer[27], filter_buffer[28], filter_buffer[29], 
          //          filter_buffer[30], filter_buffer[31] 
          //          );
          // $display("acc0=%d", 
          //       filter_buffer[0] * (input_buffer[0] + input_offset) + 
          //       filter_buffer[1] * (input_buffer[1] + input_offset) +
          //       filter_buffer[2] * (input_buffer[2] + input_offset) + 
          //       filter_buffer[3] * (input_buffer[3] + input_offset) +
          //       filter_buffer[4] * (input_buffer[4] + input_offset) + 
          //       filter_buffer[5] * (input_buffer[5] + input_offset) + 
          //       filter_buffer[6] * (input_buffer[6] + input_offset) + 
          //       filter_buffer[7] * (input_buffer[7] + input_offset));
        end

        7: begin  // get acumulator
          // ret <= acc;
          ret <= quanted_acc;
        end
        8: begin  // Write start x in input ring buffer 
          start_filter_x <= value;
        end
        9: begin  // Check if computation is done
          ret <= finished_work;
        end

        // Quant parameters
        10: begin
          bias <= inp1;
        end
        11: begin
          output_multiplier <= inp1;
        end
        12: begin
          output_shift <= inp1;
        end
        13: begin
          output_activation_min <= inp1;
        end
        14: begin
          output_activation_max <= inp1;
        end
        15: begin
          output_offset <= inp1;
        end

        default: begin
          // $display("!!! DEFAULT case ");
          ret <= 0;
        end
      endcase
    end
  end

endmodule

`endif
