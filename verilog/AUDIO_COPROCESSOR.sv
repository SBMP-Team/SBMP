module AudioCoprocessor (
    input logic clk,
    input logic rst,

    input logic [7:0] freq,
    input logic [7:0] duration,

    input logic play,
    output logic audio_out,
    output logic busy
);

    logic [15:0] counter;
    logic [7:0]  dur_counter;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            dur_counter <= 0;
            audio_out <= 0;
            busy <= 0;
        end else begin

            if (play && !busy) begin
                busy <= 1;
                dur_counter <= duration;
            end

            if (busy) begin

                counter <= counter + freq;

                // square wave from MSB
                audio_out <= counter[15];

                // duration handling
                if (counter == 0) begin
                    if (dur_counter > 0)
                        dur_counter <= dur_counter - 1;
                    else
                        busy <= 0;
                end
            end

        end
    end

endmodule