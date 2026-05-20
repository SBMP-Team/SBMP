module CPU
(
    input logic btnA,
    input logic btnB,
    input logic btnUp,
    input logic btnDown,
    input logic btnLeft,
    input logic btnRight,
    input logic btnStart,
    input logic rst,
    input logic clk
);

    logic [15:0] memory [0:65535]; // 64KB of memory

    logic [15:0] pc = 16'd0;

    //JUST test ALU right now
    logic [15:0] alu_out;
    logic [15:0] alu_a = 16'd1;
    logic [15:0] alu_b = 16'd1;
    logic [3:0] alu_op = 3'd0;
    ALU alu (
        .a(alu_a),
        .b(alu_b),
        .op(alu_op),
        .out(alu_out)
    );

    logic[15:0] packed_opcode = 16'd0;
    logic[15:0] operand = 16'd0;
    logic[5:0] opcode;
    logic register_flag;
    logic jump_flag;
    // assign opcode = packed_opcode[7:2];
    // assign register_flag = packed_opcode[0];
    // assign jump_flag = packed_opcode[1];

    logic writeback_enable = 1'b1;

    logic [15:0] writeback_target = 16'd500;
    logic [15:0] writeback_value = 16'd0;


    typedef enum logic [2:0] {
        FETCH,
        READ,
        EXECUTE,
        WRITEBACK
    } cpu_phase_t;

    cpu_phase_t cpu_phase;

    always_ff @( posedge clk or posedge rst ) begin : CPU
        if (rst) begin
            cpu_phase <= FETCH;
            pc <= memory[0]; //memory address 0x0 stores the ROM offset, aka where the program starts
        end else begin
            case(cpu_phase)
                FETCH:begin
                    packed_opcode <= memory[pc];
                    operand <= memory[pc+1];
                    pc <= pc +2;
                    cpu_phase <= READ;
                end
                READ:begin
                    opcode <= packed_opcode[7:2];
                    cpu_phase <= EXECUTE;
                end
                EXECUTE:begin

                    cpu_phase <= WRITEBACK;
                end
                WRITEBACK:begin
                    if (writeback_enable) begin
                        memory[writeback_target] <=writeback_value;
                    end
                    cpu_phase <=FETCH;
                end
            endcase
        end
    end

endmodule