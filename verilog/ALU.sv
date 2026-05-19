module ALU (
    input  logic [15:0] a,
    input  logic [15:0] b,
    input  logic [3:0]  op,
    output logic [15:0] out
);

always_comb begin
    out = 16'd0;

    unique case (op)
        4'b0000: out = a + b;
        4'b0001: out = a - b;
        4'b0010: out = a * b;
        4'b0011: out = (b == 0) ? 16'd0 : a / b;
        4'b0100: out = (b == 0) ? 16'd0 : a % b;

        4'b0101: out = a & b;
        4'b0110: out = a | b;
        4'b0111: out = a ^ b;

        4'b1000: out = ~a;

        4'b1001: out = a << b[3:0];
        4'b1010: out = a >> b[3:0];

        4'b1111: out = 16'hDEAD; // debug NOP marker

        default:  out = 16'd0;
    endcase
end

endmodule