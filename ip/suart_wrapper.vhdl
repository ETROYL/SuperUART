----------------------------------------------------------------------------------
-- Company: SIA
-- Engineer: Dr. Ir. Siavash Ardekani
-- 
-- Create Date: 11/21/2023 10:08:00 AM
-- Design Name: 
-- Module Name: suart_wrapper - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity suart_wrapper is
    generic (
		soft_rst_enable : boolean := true;
	    soft_rst_pattern : std_logic_vector(31 downto 0) := X"76B19D08" -- MSB first
		);
    Port ( CLK : in  STD_LOGIC;
           rst_n : in  STD_LOGIC;
           RX : in  STD_LOGIC;
           TX : out  STD_LOGIC := '1';
           Transmit : in STD_LOGIC;  -- transmitting TX_DATA by means of rising edge of this signal, if RDY2Transmit is high
           RDY2Transmit : out STD_LOGIC;
           RX_DATA : out  STD_LOGIC_VECTOR (7 downto 0);
           TX_DATA : in  STD_LOGIC_VECTOR (7 downto 0);
           RX_Data_Valid : out STD_LOGIC; -- if this signal is asserted, you can read the RX_DATA using Read_RX
		   Read_RX : in STD_LOGIC; -- If RX_Data_Valid = '1', use the rising edge of this signal to read rx data
		   BUFF_FULL : out STD_LOGIC; -- indicating no more accepting RX inputs
		   BUFF_EMPTY : out std_logic;
           fifo_wr_ack : out std_logic
			  );
end suart_wrapper;

architecture Behavioral of suart_wrapper is

component SUART
	generic (
		soft_rst_enable : boolean;
	    soft_rst_pattern : std_logic_vector(31 downto 0) := X"76B19D08" -- MSB first
		);
    Port ( CLK : in  STD_LOGIC;
           rst_n : in  STD_LOGIC;
           RX : in  STD_LOGIC;
           TX : out  STD_LOGIC := '1';
           Transmit : in STD_LOGIC;  -- transmitting TX_DATA by means of rising edge of this signal, if RDY2Transmit is high
           RDY2Transmit : out STD_LOGIC;
           RX_DATA : out  STD_LOGIC_VECTOR (7 downto 0);
           TX_DATA : in  STD_LOGIC_VECTOR (7 downto 0);
           RX_Data_Valid : out STD_LOGIC; -- if this signal is asserted, you can read the RX_DATA using Read_RX
		   Read_RX : in STD_LOGIC; -- If RX_Data_Valid = '1', use the rising edge of this signal to read rx data
		   BUFF_FULL : out STD_LOGIC; -- indicating no more accepting RX inputs
		   BUFF_EMPTY : out std_logic;
           fifo_wr_ack : out std_logic
			  );
end component;

begin

suart_inst: SUART
	generic map(
		soft_rst_enable => soft_rst_enable,
	    soft_rst_pattern => soft_rst_pattern
		)
    Port map(
           CLK => CLK,
           rst_n => rst_n,
           RX => RX,
           TX => TX,
           Transmit => Transmit,
           RDY2Transmit => RDY2Transmit,
           RX_DATA => RX_DATA,
           TX_DATA => TX_DATA,
           RX_Data_Valid => RX_Data_Valid,
		   Read_RX => Read_RX,
		   BUFF_FULL => BUFF_FULL,
		   BUFF_EMPTY => BUFF_EMPTY,
           fifo_wr_ack => fifo_wr_ack
		);

end Behavioral;
