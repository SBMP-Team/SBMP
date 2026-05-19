module tb_cpu;

    logic clk = 0;
    logic rst;

    // inputs
    logic btnA, btnB, btnUp, btnDown, btnLeft, btnRight, btnStart;

    // clock
    always #5 clk = ~clk;

    CPU dut (
        .clk(clk),
        .rst(rst),
        .btnA(btnA),
        .btnB(btnB),
        .btnUp(btnUp),
        .btnDown(btnDown),
        .btnLeft(btnLeft),
        .btnRight(btnRight),
        .btnStart(btnStart)
    );

    initial begin
        integer fd;

        $dumpfile("wave.vcd");
        $dumpvars(0, tb_cpu);
        for (int i = 0; i < 512; i++) begin
            $dumpvars(0, dut.memory[i]);
        end



        fd = $fopen("../tests/test.sbmp", "rb");


        if (fd == 0) begin
            $display("failed to open file");
            $finish;
        end 
        $display("Loading memory");

        #1;  // small delay ensures elaboration is stable
        void'($fread(dut.memory, fd));


        $fclose(fd);     
        // init inputs
        btnA = 0;
        btnB = 0;
        btnUp = 0;
        btnDown = 0;
        btnLeft = 0;
        btnRight = 0;
        btnStart = 0;

        rst = 1;
        #20;
        rst = 0;

        // run simulation
        #5000;

        $display("Complete, value of A register at end is ", dut.memory[3]);
        
        
        
        $finish;

    end

endmodule