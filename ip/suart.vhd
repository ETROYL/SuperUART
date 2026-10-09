-- SPDX-License-Identifier: MIT
-- Copyright (c) 2023-2026 Dr. Ir. Siavash Ardekani and ETROYL
-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
-- Date        : Wed Nov 22 13:19:14 2023
-- Host        : jcd-HP-ZBook-17-G5 running 64-bit Ubuntu 20.04.6 LTS
-- Command     : write_vhdl -mode synth_stub suart.vhd
-- Design      : SUART
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu7ev-fbvb900-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SUART is
  Port ( 
    CLK : in STD_LOGIC;
    rst_n : in STD_LOGIC;
    RX : in STD_LOGIC;
    TX : out STD_LOGIC;
    Transmit : in STD_LOGIC;
    RDY2Transmit : out STD_LOGIC;
    RX_DATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    TX_DATA : in STD_LOGIC_VECTOR ( 7 downto 0 );
    RX_Data_Valid : out STD_LOGIC;
    Read_RX : in STD_LOGIC;
    BUFF_FULL : out STD_LOGIC;
    BUFF_EMPTY : out STD_LOGIC;
    fifo_wr_ack : out STD_LOGIC
  );

end SUART;

architecture stub of SUART is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "CLK,rst_n,RX,TX,Transmit,RDY2Transmit,RX_DATA[7:0],TX_DATA[7:0],RX_Data_Valid,Read_RX,BUFF_FULL,BUFF_EMPTY,fifo_wr_ack";
begin
end;
