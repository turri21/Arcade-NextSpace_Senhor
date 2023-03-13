///----------------------------------------------------------------------------
//
//  Copyright 2022 Darren Olafson
//
//  MiSTer Copyright (C) 2017 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//----------------------------------------------------------------------------


// simple read-only cache 
// specificly for 68k program rom.  todo - parameterize 
module tile_cache
(
    input reset,
    input clk,

    input cache_req,
    input [19:0] cache_addr,

    output reg cache_valid,
    output [31:0] cache_data,

    input  [31:0] rom_data,
    input  rom_valid,
    
    output reg rom_req,
    output reg [19:0] rom_addr
);


reg [19:9]   tag   [511:0];
reg [511:0]  valid ;
reg [1:0]    state = 0;

reg  [8:0]   idx_r;

wire [8:0]   idx = cache_addr[8:0];
wire hit;

// if tag value matches the upper bits of the address 
// and valid then no need to pass request to sdram 
assign hit = ( tag[idx] == cache_addr[19:9] && valid[idx] == 1 && state == 1 );


assign cache_data = ( hit == 1 ) ? cache_dout : rom_data;

always @ (posedge clk) begin
    cache_valid <= ( cache_req != 0 ) && ( hit == 1 || rom_valid == 1 );
    if ( reset == 1 ) begin
        state <= 0;
        // reset bits that indicate tag is valid
        valid <= 0;
    end else begin
        // if no read request then do nothing
        if ( cache_req == 0 ) begin
            rom_req <= 0;
            state <= 1;
        end else begin
            // if there is a hit then read from cache and say we are done
            if ( hit == 1 ) begin
                rom_req <= 0;
            end else if ( state == 1 ) begin
                // read from memory

                idx_r <= idx;
                
                // we need to read from sdram
                rom_req <= 1;
                rom_addr <= cache_addr;

                // next state is wait for rom ready
                state <= 2;
                
            end else if ( state == 2 && rom_valid == 1 ) begin

                // write updated tag
                tag[idx_r] <= rom_addr[19:9];
                // mark tag valid
                valid[idx_r] <= 1'b1;

                cache_din <= rom_data;
                
                state <= 3;
            end else if ( state == 3 ) begin
                state <= 0;
            end
        end
    end
end

reg  [31:0] cache_din;
wire [31:0] cache_dout;

dual_port_ram #(.LEN(512), .DATA_WIDTH(32)) cache_ram (
    .clock_a ( clk ),
    .address_a ( idx_r ),
    .wren_a ( state == 3 ),
    .data_a ( cache_din ),
    .q_a (  ),

    .clock_b ( clk ),
    .address_b ( idx ),
    .wren_b ( 0 ),
    .q_b ( cache_dout )
    );


endmodule


module sound_cache
(
    input reset,
    input clk,

    input cache_req,
    input [18:0] cache_addr,

    output reg cache_valid,
    output [7:0] cache_data,

    input  [7:0] rom_data,
    input  rom_valid,
    
    output reg rom_req,
    output reg [18:0] rom_addr
);


reg [18:9]   tag   [511:0];
reg [511:0]  valid ;
reg [1:0]    state = 0;

reg  [8:0]   idx_r;

wire [8:0]   idx = cache_addr[8:0];
wire hit;

// if tag value matches the upper bits of the address 
// and valid then no need to pass request to sdram 
assign hit = ( tag[idx] == cache_addr[18:9] && valid[idx] == 1 && state == 1 );


assign cache_data = ( hit == 1 ) ? cache_dout : rom_data;

always @ (posedge clk) begin
    cache_valid <= ( cache_req != 0 ) && ( hit == 1 || rom_valid == 1 );
    if ( reset == 1 ) begin
        state <= 0;
        // reset bits that indicate tag is valid
        valid <= 0;
    end else begin
        // if no read request then do nothing
        if ( cache_req == 0 ) begin
            rom_req <= 0;
            state <= 1;
        end else begin
            // if there is a hit then read from cache and say we are done
            if ( hit == 1 ) begin
                rom_req <= 0;
            end else if ( state == 1 ) begin
                // read from memory

                idx_r <= idx;
                
                // we need to read from sdram
                rom_req <= 1;
                rom_addr <= cache_addr;

                // next state is wait for rom ready
                state <= 2;
                
            end else if ( state == 2 && rom_valid == 1 ) begin

                // write updated tag
                tag[idx_r] <= rom_addr[18:9];
                // mark tag valid
                valid[idx_r] <= 1'b1;

                cache_din <= rom_data;
                
                state <= 3;
            end else if ( state == 3 ) begin
                state <= 0;
            end
        end
    end
end

reg  [7:0] cache_din;
wire [7:0] cache_dout;

dual_port_ram #(.LEN(512), .DATA_WIDTH(8)) cache_ram (
    .clock_a ( clk ),
    .address_a ( idx_r ),
    .wren_a ( state == 3 ),
    .data_a ( cache_din ),
    .q_a (  ),

    .clock_b ( clk ),
    .address_b ( idx ),
    .wren_b ( 0 ),
    .q_b ( cache_dout )
    );


endmodule

