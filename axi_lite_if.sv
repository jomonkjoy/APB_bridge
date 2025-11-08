// AXI4-Lite Interface
// Simplified protocol for register access (no bursts, no IDs)

interface axi_lite_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input logic aclk,
    input logic aresetn
);

    // Calculate byte lanes
    localparam int STRB_WIDTH = DATA_WIDTH / 8;

    // Write Address Channel (AW)
    logic [ADDR_WIDTH-1:0]  awaddr;
    logic [2:0]             awprot;     // Protection attributes
    logic                   awvalid;
    logic                   awready;

    // Write Data Channel (W)
    logic [DATA_WIDTH-1:0]  wdata;
    logic [STRB_WIDTH-1:0]  wstrb;      // Byte write strobes
    logic                   wvalid;
    logic                   wready;

    // Write Response Channel (B)
    logic [1:0]             bresp;      // Write response (OKAY=00, EXOKAY=01, SLVERR=10, DECERR=11)
    logic                   bvalid;
    logic                   bready;

    // Read Address Channel (AR)
    logic [ADDR_WIDTH-1:0]  araddr;
    logic [2:0]             arprot;     // Protection attributes
    logic                   arvalid;
    logic                   arready;

    // Read Data Channel (R)
    logic [DATA_WIDTH-1:0]  rdata;
    logic [1:0]             rresp;      // Read response
    logic                   rvalid;
    logic                   rready;

    // Master Modport
    modport master (
        input  aclk, aresetn,
        // Write Address Channel
        output awaddr, awprot, awvalid,
        input  awready,
        // Write Data Channel
        output wdata, wstrb, wvalid,
        input  wready,
        // Write Response Channel
        input  bresp, bvalid,
        output bready,
        // Read Address Channel
        output araddr, arprot, arvalid,
        input  arready,
        // Read Data Channel
        input  rdata, rresp, rvalid,
        output rready
    );

    // Slave Modport
    modport slave (
        input  aclk, aresetn,
        // Write Address Channel
        input  awaddr, awprot, awvalid,
        output awready,
        // Write Data Channel
        input  wdata, wstrb, wvalid,
        output wready,
        // Write Response Channel
        output bresp, bvalid,
        input  bready,
        // Read Address Channel
        input  araddr, arprot, arvalid,
        output arready,
        // Read Data Channel
        output rdata, rresp, rvalid,
        input  rready
    );

    // Monitor Modport (for verification)
    modport monitor (
        input aclk, aresetn,
        input awaddr, awprot, awvalid, awready,
        input wdata, wstrb, wvalid, wready,
        input bresp, bvalid, bready,
        input araddr, arprot, arvalid, arready,
        input rdata, rresp, rvalid, rready
    );

    // Helper tasks for master-side operations
    task automatic write(
        input  logic [ADDR_WIDTH-1:0] addr,
        input  logic [DATA_WIDTH-1:0] data,
        input  logic [STRB_WIDTH-1:0] strb = '1,
        output logic [1:0]            resp
    );
        // Write address phase
        @(posedge aclk);
        awaddr  <= addr;
        awprot  <= 3'b000;
        awvalid <= 1'b1;
        wdata   <= data;
        wstrb   <= strb;
        wvalid  <= 1'b1;
        
        fork
            begin // Wait for address acceptance
                while (!awready) @(posedge aclk);
                awvalid <= 1'b0;
            end
            begin // Wait for data acceptance
                while (!wready) @(posedge aclk);
                wvalid <= 1'b0;
            end
        join
        
        // Wait for response
        bready <= 1'b1;
        while (!bvalid) @(posedge aclk);
        resp = bresp;
        @(posedge aclk);
        bready <= 1'b0;
    endtask

    task automatic read(
        input  logic [ADDR_WIDTH-1:0] addr,
        output logic [DATA_WIDTH-1:0] data,
        output logic [1:0]            resp
    );
        // Read address phase
        @(posedge aclk);
        araddr  <= addr;
        arprot  <= 3'b000;
        arvalid <= 1'b1;
        
        while (!arready) @(posedge aclk);
        arvalid <= 1'b0;
        
        // Wait for read data
        rready <= 1'b1;
        while (!rvalid) @(posedge aclk);
        data = rdata;
        resp = rresp;
        @(posedge aclk);
        rready <= 1'b0;
    endtask

endinterface : axi_lite_if
