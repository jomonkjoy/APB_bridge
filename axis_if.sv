// ============================================================================
// AXI4-Stream Interface
// For high-speed streaming data with flow control
// ============================================================================

interface axis_if #(
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 1,
    parameter int DEST_WIDTH = 1,
    parameter int USER_WIDTH = 1
)(
    input logic aclk,
    input logic aresetn
);

    // Calculate byte lanes
    localparam int STRB_WIDTH = DATA_WIDTH / 8;
    localparam int KEEP_WIDTH = DATA_WIDTH / 8;

    // AXI-Stream Signals
    logic [DATA_WIDTH-1:0]  tdata;      // Data payload
    logic [STRB_WIDTH-1:0]  tstrb;      // Byte qualifier (data vs position)
    logic [KEEP_WIDTH-1:0]  tkeep;      // Byte qualifier (valid vs null)
    logic                   tlast;      // End of packet/frame
    logic [ID_WIDTH-1:0]    tid;        // Stream identifier
    logic [DEST_WIDTH-1:0]  tdest;      // Routing destination
    logic [USER_WIDTH-1:0]  tuser;      // User-defined sideband
    logic                   tvalid;     // Valid signal
    logic                   tready;     // Ready signal (backpressure)

    // Master Modport (Source)
    modport master (
        input  aclk, aresetn,
        output tdata, tstrb, tkeep, tlast, tid, tdest, tuser, tvalid,
        input  tready
    );

    // Slave Modport (Sink)
    modport slave (
        input  aclk, aresetn,
        input  tdata, tstrb, tkeep, tlast, tid, tdest, tuser, tvalid,
        output tready
    );

    // Monitor Modport (for verification)
    modport monitor (
        input aclk, aresetn,
        input tdata, tstrb, tkeep, tlast, tid, tdest, tuser, tvalid, tready
    );

    // Helper task for master to send data
    task automatic send(
        input logic [DATA_WIDTH-1:0] data,
        input logic [KEEP_WIDTH-1:0] keep = '1,
        input logic [STRB_WIDTH-1:0] strb = '1,
        input logic                  last = 1'b0,
        input logic [ID_WIDTH-1:0]   id   = '0,
        input logic [DEST_WIDTH-1:0] dest = '0,
        input logic [USER_WIDTH-1:0] user = '0
    );
        @(posedge aclk);
        tdata  <= data;
        tkeep  <= keep;
        tstrb  <= strb;
        tlast  <= last;
        tid    <= id;
        tdest  <= dest;
        tuser  <= user;
        tvalid <= 1'b1;
        
        while (!tready) @(posedge aclk);
        @(posedge aclk);
        tvalid <= 1'b0;
    endtask

    // Helper task for slave to receive data
    task automatic receive(
        output logic [DATA_WIDTH-1:0] data,
        output logic [KEEP_WIDTH-1:0] keep,
        output logic [STRB_WIDTH-1:0] strb,
        output logic                  last,
        output logic [ID_WIDTH-1:0]   id,
        output logic [DEST_WIDTH-1:0] dest,
        output logic [USER_WIDTH-1:0] user
    );
        tready <= 1'b1;
        while (!tvalid) @(posedge aclk);
        
        data = tdata;
        keep = tkeep;
        strb = tstrb;
        last = tlast;
        id   = tid;
        dest = tdest;
        user = tuser;
        
        @(posedge aclk);
        tready <= 1'b0;
    endtask

endinterface : axis_if