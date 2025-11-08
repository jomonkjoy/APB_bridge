// AXI4 Memory-Mapped Interface
// Full implementation with all five channels: AW, W, B, AR, R

interface axi_mm_if #(
parameter int ADDR_WIDTH = 32,
parameter int DATA_WIDTH = 32,
parameter int ID_WIDTH   = 4,
parameter int USER_WIDTH = 1
)(
input logic aclk,
input logic aresetn
);

```
// Calculate byte lanes
localparam int STRB_WIDTH = DATA_WIDTH / 8;

// Write Address Channel (AW)
logic [ID_WIDTH-1:0]    awid;
logic [ADDR_WIDTH-1:0]  awaddr;
logic [7:0]             awlen;      // Burst length (0-255)
logic [2:0]             awsize;     // Burst size (bytes per beat)
logic [1:0]             awburst;    // Burst type (FIXED=00, INCR=01, WRAP=10)
logic                   awlock;     // Lock type
logic [3:0]             awcache;    // Cache attributes
logic [2:0]             awprot;     // Protection attributes
logic [3:0]             awqos;      // QoS identifier
logic [3:0]             awregion;   // Region identifier
logic [USER_WIDTH-1:0]  awuser;     // User-defined
logic                   awvalid;
logic                   awready;

// Write Data Channel (W)
logic [DATA_WIDTH-1:0]  wdata;
logic [STRB_WIDTH-1:0]  wstrb;      // Byte write strobes
logic                   wlast;      // Last beat in burst
logic [USER_WIDTH-1:0]  wuser;      // User-defined
logic                   wvalid;
logic                   wready;

// Write Response Channel (B)
logic [ID_WIDTH-1:0]    bid;
logic [1:0]             bresp;      // Write response (OKAY=00, EXOKAY=01, SLVERR=10, DECERR=11)
logic [USER_WIDTH-1:0]  buser;      // User-defined
logic                   bvalid;
logic                   bready;

// Read Address Channel (AR)
logic [ID_WIDTH-1:0]    arid;
logic [ADDR_WIDTH-1:0]  araddr;
logic [7:0]             arlen;      // Burst length (0-255)
logic [2:0]             arsize;     // Burst size (bytes per beat)
logic [1:0]             arburst;    // Burst type
logic                   arlock;     // Lock type
logic [3:0]             arcache;    // Cache attributes
logic [2:0]             arprot;     // Protection attributes
logic [3:0]             arqos;      // QoS identifier
logic [3:0]             arregion;   // Region identifier
logic [USER_WIDTH-1:0]  aruser;     // User-defined
logic                   arvalid;
logic                   arready;

// Read Data Channel (R)
logic [ID_WIDTH-1:0]    rid;
logic [DATA_WIDTH-1:0]  rdata;
logic [1:0]             rresp;      // Read response
logic                   rlast;      // Last beat in burst
logic [USER_WIDTH-1:0]  ruser;      // User-defined
logic                   rvalid;
logic                   rready;

// Master Modport
modport master (
    input  aclk, aresetn,
    // Write Address Channel
    output awid, awaddr, awlen, awsize, awburst, awlock, awcache, 
           awprot, awqos, awregion, awuser, awvalid,
    input  awready,
    // Write Data Channel
    output wdata, wstrb, wlast, wuser, wvalid,
    input  wready,
    // Write Response Channel
    input  bid, bresp, buser, bvalid,
    output bready,
    // Read Address Channel
    output arid, araddr, arlen, arsize, arburst, arlock, arcache,
           arprot, arqos, arregion, aruser, arvalid,
    input  arready,
    // Read Data Channel
    input  rid, rdata, rresp, rlast, ruser, rvalid,
    output rready
);

// Slave Modport
modport slave (
    input  aclk, aresetn,
    // Write Address Channel
    input  awid, awaddr, awlen, awsize, awburst, awlock, awcache,
           awprot, awqos, awregion, awuser, awvalid,
    output awready,
    // Write Data Channel
    input  wdata, wstrb, wlast, wuser, wvalid,
    output wready,
    // Write Response Channel
    output bid, bresp, buser, bvalid,
    input  bready,
    // Read Address Channel
    input  arid, araddr, arlen, arsize, arburst, arlock, arcache,
           arprot, arqos, arregion, aruser, arvalid,
    output arready,
    // Read Data Channel
    output rid, rdata, rresp, rlast, ruser, rvalid,
    input  rready
);

// Monitor Modport (for verification)
modport monitor (
    input aclk, aresetn,
    input awid, awaddr, awlen, awsize, awburst, awlock, awcache,
          awprot, awqos, awregion, awuser, awvalid, awready,
    input wdata, wstrb, wlast, wuser, wvalid, wready,
    input bid, bresp, buser, bvalid, bready,
    input arid, araddr, arlen, arsize, arburst, arlock, arcache,
          arprot, arqos, arregion, aruser, arvalid, arready,
    input rid, rdata, rresp, rlast, ruser, rvalid, rready
);
```

endinterface : axi_mm_if