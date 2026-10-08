----------------------------------------------------------------------------------
-- Company: ETROYL
-- Engineer: Dr. Ir. Siavash Ardekani
-- 
-- Create Date:    10:48:22 05/11/2023 
-- Design Name: 
-- Module Name:    SUART - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

entity SUART is
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
end SUART;

architecture Behavioral of SUART is

------------------------COMPONENTS---------------------------------

COMPONENT fifo_generator_0
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    wr_ack : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC;
    wr_rst_busy : OUT STD_LOGIC;
    rd_rst_busy : OUT STD_LOGIC 
  );
END COMPONENT;

------------------------TYPES--------------------------------------
TYPE FSM is (phase0, phase1_0, phase1, phase2, phase3, phase4, phase5, phase6, phase7, phase8, phase9, phase10, phase11);

-----------------------SIGNALS and CONSTANTS------------------------------------
signal Counter_L: integer range 0 to 100_000_000;
signal Counter_H: integer range 0 to 100_000_000;
signal Period: integer range 0 to 100_000_000;
signal uart_clk: std_logic;
signal count_clk: integer range 0 to 100_000_000;
signal RX_STATE : FSM;
signal TX_STATE : FSM;
signal BRD_STATE : FSM; -- baud rate detection
signal RX_DATA2FIFO : STD_LOGIC_VECTOR (7 downto 0);
signal WR2FIFO : STD_LOGIC;
signal BR_Locked : STD_LOGIC;
signal rst : STD_LOGIC;
signal soft_rst : STD_LOGIC;
signal soft_rst_state : FSM := phase0;
signal reset_uart_clk : std_logic;
signal Read_RX_state : FSM;
signal RX_RD : std_logic;
signal FULL : std_logic;
signal bit_counter : integer range 0 to 15;
signal Period_div2 : integer range 0 to 50_000_000;
signal TX_uart_clk: std_logic;
signal TX_count_clk: integer range 0 to 100_000_000;
signal TX_bit_counter : integer range 0 to 15;
signal TX_DATA_tmp : STD_LOGIC_VECTOR (7 downto 0);
signal TX_StartBit_Sent : std_logic;
signal TX_StopBit_Sent : std_logic;

begin
------------------Instantiation--------------------

RX_BUFF : fifo_generator_0
  PORT MAP (
    clk => CLK,
    srst => rst,
    din => RX_DATA2FIFO,
    wr_en => WR2FIFO,
    rd_en => RX_RD,
    dout => RX_DATA,
    full => BUFF_FULL,
    wr_ack => fifo_wr_ack,
    empty => BUFF_EMPTY,
    valid => RX_Data_Valid,
    wr_rst_busy => open,
    rd_rst_busy => open
  );
----------------------------------------------------
rst <= not(rst_n) or soft_rst;
Period_div2 <= Period/2;
----------------------------------------------------
soft_rst_pro1: process(CLK, BR_Locked, WR2FIFO, RX_DATA2FIFO)
begin
if (BR_Locked = '0') then
    soft_rst_state <= phase0;
elsif (WR2FIFO = '1' and falling_edge(CLK)) then
    case soft_rst_state is
        when phase0 =>
            if (RX_DATA2FIFO = soft_rst_pattern(31 downto 24)) then
               soft_rst_state <= phase1;
            else
               soft_rst_state <= phase0;
            end if;
        when phase1 =>
            if (RX_DATA2FIFO = soft_rst_pattern(23 downto 16)) then
               soft_rst_state <= phase2;
            else
               soft_rst_state <= phase0;
            end if;
        when phase2 =>
            if (RX_DATA2FIFO = soft_rst_pattern(15 downto 8)) then
               soft_rst_state <= phase3;
            else
               soft_rst_state <= phase0;
            end if;
        when phase3 =>
            if (RX_DATA2FIFO = soft_rst_pattern(7 downto 0)) then
               soft_rst_state <= phase4;
            else
               soft_rst_state <= phase0;
            end if;
        when phase4 =>
            soft_rst_state <= phase5;
        when phase5 =>
            soft_rst_state <= phase6;
        when phase6 =>
            soft_rst_state <= phase7;
        when phase7 =>
            soft_rst_state <= phase8;
        when phase8 =>
            soft_rst_state <= phase9;
        when phase9 =>
            soft_rst_state <= phase0; -- just to hold it active for some clock cycles
        when others =>
            null;
    end case;
end if;
end process;
----------------------------------------------------
soft_rst_pro2: process(soft_rst_state)
begin
case soft_rst_state is
    when phase0 =>
       soft_rst <= '0';
    when phase4 =>
		if soft_rst_enable then
       		soft_rst <= '1'; 
		else
			soft_rst <= '0';
		end if;
    when others =>
        null;
end case;
end process;
----------------------------------------------------
Read_RX_pro: process(CLK, Read_RX)
begin
if rising_edge(CLK) then
    case Read_RX_state is
        when phase0 =>
            RX_RD <= '0';
            if (Read_RX = '0') then
                Read_RX_state <= phase1;
            end if;
        when phase1 =>
            if (Read_RX = '1') then
                Read_RX_state <= phase2;
            end if;
        when phase2 =>
            RX_RD <= '1';
            Read_RX_state <= phase3;
        when phase3 => 
            RX_RD <= '0'; 
            Read_RX_state <= phase0;  
        when others => null;
    end case;
end if;
end process;
----------------------------------------------------
BaudRateDetection_Pro0: process(CLK, rst_n, RX, BR_Locked)
begin
if (rst_n = '0') then
    BRD_STATE <= phase0;
elsif rising_edge(CLK) then
    case BRD_STATE is
        when phase0 =>
            if (RX = '1' and BR_Locked = '0') then
                BRD_STATE <= phase1;
            end if;
        when phase1 =>
            if (RX = '0') then
                BRD_STATE <= phase2;
            end if;
        when phase2 =>
            if (RX = '1') then
                BRD_STATE <= phase3;
            end if;
        when phase3 =>
            if (RX = '0') then
                BRD_STATE <= phase4;
            end if;
        when phase4 =>
            if (RX = '1') then
                BRD_STATE <= phase5;
            end if;
        when phase5 =>
            if (RX = '0') then
                BRD_STATE <= phase6;
            end if;
        when phase6 =>
            if (RX = '1') then
                BRD_STATE <= phase7;
            end if;
        when phase7 =>
            if (RX = '0') then
                BRD_STATE <= phase8;
            end if;
        when phase8 =>
            if (RX = '1') then
                BRD_STATE <= phase9;
            end if;
        when phase9 =>
            if (RX = '0') then
                BRD_STATE <= phase10;
            end if;
        when phase10 =>
            if (RX = '1') then
                BRD_STATE <= phase11;
            end if;
        when phase11 =>
            if (rst = '1') then
                BRD_STATE <= phase0;
            end if;
        when others => NULL;
    end case;
end if;
end process;
--------------------------------------------------
BaudRateDetection_Pro1: process(CLK)
begin
if rising_edge(CLK) then
    case BRD_STATE is
        when phase0 =>
            BR_Locked <= '0';
            Counter_L <= 0;
            Counter_H <= 0;
            Period <= 100000000;
        when phase2 =>
            Counter_L <= Counter_L + 1;           
        when phase3 =>
            if (Counter_L < Period and Counter_L > 0) then
                Period <= Counter_L;
            end if;
            Counter_H <= Counter_H + 1;
        when phase5 =>
            if (Counter_H < Period and Counter_H > 0) then
                Period <= Counter_H;
            end if;
        when phase11 =>
            BR_Locked <= '1';
        when others => NULL;
    end case;
end if;
end process;
--------------------------------------------------
--------------------------------------------------
uart_clk_pro: process(CLK, BR_Locked)
begin
if (BR_Locked = '0') then
     null;
elsif falling_edge(CLK) then
    case reset_uart_clk is
        when '1' =>
            count_clk <= 2;
            uart_clk <= '0';
        when '0' =>
            if (count_clk >= Period) then
                uart_clk <= '0';
                count_clk <= 1;
            elsif (count_clk >= Period_div2) then
                uart_clk <= '1';
                count_clk <= count_clk + 1;
            else
                count_clk <= count_clk + 1;
            end if;
        when others => null;
    end case;
end if;
end process;
--------------------------------------------------
--------------------------------------------------
RX_STATE_pro1: process(CLK, BR_Locked, RX, uart_clk, bit_counter)
begin
if (BR_Locked = '0') then
     RX_STATE <= phase0;
elsif rising_edge(CLK) then
    case RX_STATE is
        when phase0 => -- idle
            WR2FIFO <= '0';
            reset_uart_clk <= '1';
            if (RX = '0') then
                RX_STATE <= phase1;
            end if;
        when phase1 =>
            reset_uart_clk <= '0';
            if (uart_clk = '0') then -- start bit
                RX_STATE <= phase2;
            end if;
        when phase2 =>
            if (uart_clk = '1') then -- start bit
                RX_STATE <= phase3;
            end if;
        when phase3 =>
            if (bit_counter >= 8) then
                RX_STATE <= phase4;
            end if;
        when phase4 =>
            if (RX = '1') then -- stop bit
                WR2FIFO <= '1';
                RX_STATE <= phase0;
            end if;
        when others => null;
    end case;
end if;
end process;

RX_STATE_pro2: process(uart_clk)
begin
if rising_edge(uart_clk) then
    case RX_STATE is
        when phase3 => -- data bits
            RX_DATA2FIFO(6 downto 0) <= RX_DATA2FIFO(7 downto 1);
            RX_DATA2FIFO(7) <= RX;
            bit_counter <= bit_counter + 1;
        when others =>
            bit_counter <= 0;
            
    end case;
end if;
end process;
--------------------------------------------------
--------------------------------------------------
TX_uart_clk_pro: process(CLK, BR_Locked)
begin
if (BR_Locked = '0') then
     null;
elsif falling_edge(CLK) then
    if (TX_count_clk >= Period) then
        TX_uart_clk <= '0';
        TX_count_clk <= 1;
    elsif (TX_count_clk >= Period_div2) then
        TX_uart_clk <= '1';
        TX_count_clk <= TX_count_clk + 1;
    else
        TX_count_clk <= TX_count_clk + 1;
    end if;
end if;
end process;
--------------------------------------------------
--------------------------------------------------
TX_STATE_pro1: process(CLk, BR_Locked, Transmit, TX_StartBit_Sent, TX_bit_counter, TX_StopBit_Sent)
begin
if (BR_Locked = '0') then
     TX_STATE <= phase0;
elsif falling_edge(CLK) then
    case TX_STATE is
        when phase0 => -- idle
            if (Transmit = '0') then
                TX_STATE <= phase1;
            end if;
        when phase1 => -- still idle but waiting to detect rising edge of Transmit
            if (Transmit = '1') then
                TX_STATE <= phase2;
            end if;
        when phase2 => -- transmit start bit
            if (TX_StartBit_Sent = '1') then
                TX_STATE <= phase3;
            end if;
        when phase3 => -- transmit 8 bits data 
            if (TX_bit_counter >= 8) then
                TX_STATE <= phase4;
            end if;
        when phase4 => -- send stop bit
            if (TX_StopBit_Sent = '1') then
                TX_STATE <= phase0;
            end if;
        when others =>
            NULL;            
    end case;
end if;
end process;
--------------------------------------------------
--------------------------------------------------
TX_STATE_pro2: process(TX_uart_clk)
begin
if falling_edge(TX_uart_clk) then
    case TX_STATE is
        when phase0 =>
            TX <= '1';
            RDY2Transmit <= '1';
        when phase1 => -- idle idle
            TX_bit_counter <= 0;
            TX <= '1';
            TX_StartBit_Sent <= '0';
            TX_StopBit_Sent <= '0';
            RDY2Transmit <= '1';
        when phase2 =>
            TX_DATA_tmp <= TX_DATA;
            TX <= '0'; -- transmitting the start bit
            TX_StartBit_Sent <= '1';
            RDY2Transmit <= '0';
        when phase3 =>
            TX <= TX_DATA_tmp(0); -- LSB first
            TX_DATA_tmp(6 downto 0) <= TX_DATA_tmp(7 downto 1);
            TX_bit_counter <= TX_bit_counter + 1;
            RDY2Transmit <= '0';
        when phase4 =>
            TX <= '1'; -- send stop bit
            TX_StopBit_Sent <= '1';
            RDY2Transmit <= '0';
        when others =>
            NULL;            
    end case;
end if;
end process;

end Behavioral;
