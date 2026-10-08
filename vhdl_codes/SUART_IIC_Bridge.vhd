----------------------------------------------------------------------------------
-- Company: ETROYL
-- Engineer: Dr. Ir. Siavash Ardekani
-- 
-- Create Date: 11/10/2023 12:05:31 PM
-- Design Name: 
-- Module Name: SUART_IIC_Bridge - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SUART_IIC_Bridge is
    Generic (
           IIC_READ_PATTERN : STD_LOGIC_VECTOR(31 downto 0) := X"A0B0C0D0";
           IIC_WRITE_PATTERN : STD_LOGIC_VECTOR(31 downto 0) := X"A5B5C5D5"
    );
    Port ( CLK : in STD_LOGIC;
           SUART_DATA_RDY : in STD_LOGIC;
           SUART_TX_RDY : in STD_LOGIC;
           SUART_DATA : in STD_LOGIC_VECTOR (7 downto 0);
           SUART_READ : out STD_LOGIC;
           SUART_TRANSMIT : out STD_LOGIC;
           IIC_ERROR : in STD_LOGIC;
           IIC_Busy : in STD_LOGIC;
           IIC_DONE : in STD_LOGIC;
           SUART_BUFF_EMPTY : in STD_LOGIC;
           IIC_R_Wn : out STD_LOGIC;
           IIC_Exe : OUT STD_LOGIC;
           IIC_Slave_Addr : OUT STD_LOGIC_VECTOR(6 downto 0);
           IIC_Reg_addr : OUT STD_LOGIC_VECTOR(7 downto 0);
           IIC_Reg_val_to_write : OUT STD_LOGIC_VECTOR(7 downto 0)
           );
end SUART_IIC_Bridge;

architecture Behavioral of SUART_IIC_Bridge is

type FSM is (phase0, phase1, phase2, phase3, phase4, phase5, phase6, phase7, phase8, phase9, phase10, phase11, phase12, phase13, phase14,
 phase15, phase16, phase17, phase18, phase19, phase20, phase21, phase22, phase23, phase24, phase25, phase26, phase27, phase28, phase29, phase30, phase31, phase32, phase33, phase34, phase35, phase36, phase37);
signal MAIN_STATE: FSM := phase0;
signal IIC_R_Wn_tmp : std_logic;
signal IIC_Slave_Addr_tmp : STD_LOGIC_VECTOR(6 downto 0);
signal IIC_Reg_addr_tmp : STD_LOGIC_VECTOR(7 downto 0);
signal IIC_Reg_val_to_write_tmp : STD_LOGIC_VECTOR(7 downto 0);
begin


IIC_R_Wn <= IIC_R_Wn_tmp;
IIC_Slave_Addr <= IIC_Slave_Addr_tmp;
IIC_Reg_addr <= IIC_Reg_addr_tmp;
IIC_Reg_val_to_write <= IIC_Reg_val_to_write_tmp;
---------------------------------------------
Main_State_Pro1: process(CLK, SUART_BUFF_EMPTY, IIC_Busy, SUART_TX_RDY, IIC_ERROR, SUART_DATA, IIC_DONE, IIC_R_Wn_tmp)
begin
--if (timeout_flag = '1') then
--    MAIN_STATE <= phase0;
if rising_edge(CLK) then
    case MAIN_STATE is
        when phase0 =>
            if SUART_BUFF_EMPTY = '0' then -- some data is arrived and stock in the fifo of suart
                MAIN_STATE <= phase1;
            end if;
        when phase1 => -- assert Read data
            if SUART_DATA_RDY = '1' then
                MAIN_STATE <= phase2;
            end if;
        when phase2 => -- now read data
            MAIN_STATE <= phase3;
        when phase3 => -- release Read data
            if (SUART_DATA = IIC_READ_PATTERN(31 downto 24) or SUART_DATA = IIC_WRITE_PATTERN(31 downto 24)) then
                if SUART_BUFF_EMPTY = '0' then
                    MAIN_STATE <= phase4;
                end if;
            else
                MAIN_STATE <= phase0;
            end if;
        when phase4 => -- assert Read data
            if SUART_DATA_RDY = '1' then
                MAIN_STATE <= phase5;
            end if;
        when phase5 => -- now read data
            MAIN_STATE <= phase6;
        when phase6 => -- release Read data
            MAIN_STATE <= phase7;
        when phase7 =>
            if (SUART_DATA = IIC_READ_PATTERN(23 downto 16) or SUART_DATA = IIC_WRITE_PATTERN(23 downto 16)) then
                if SUART_BUFF_EMPTY = '0' then
                    MAIN_STATE <= phase8;
                end if;
            else
                MAIN_STATE <= phase0;
            end if;
        when phase8 => -- assert Read data
            if SUART_DATA_RDY = '1' then
                MAIN_STATE <= phase9;
            end if;
        when phase9 => -- now read data
            MAIN_STATE <= phase10;
        when phase10 => -- release Read data
            MAIN_STATE <= phase11;
        when phase11 =>
            if (SUART_DATA = IIC_READ_PATTERN(15 downto 8) or SUART_DATA = IIC_WRITE_PATTERN(15 downto 8)) then            
                if SUART_BUFF_EMPTY = '0' then
                    MAIN_STATE <= phase12;
                end if;
            else
                MAIN_STATE <= phase0;
            end if;
        when phase12 => -- assert Read data
            if SUART_DATA_RDY = '1' then
                MAIN_STATE <= phase13;
            end if;
        when phase13 => -- now read data
            MAIN_STATE <= phase14;
        when phase14 => -- release Read data
            MAIN_STATE <= phase15;
        when phase15 => -- ckeck the pattern
            if (SUART_DATA = IIC_READ_PATTERN(7 downto 0)) then
                IIC_R_Wn_tmp <= '1';
                MAIN_STATE <= phase16;
            elsif (SUART_DATA = IIC_WRITE_PATTERN(7 downto 0)) then
                IIC_R_Wn_tmp <= '0';
                MAIN_STATE <= phase16;
            else
                MAIN_STATE <= phase0;
            end if;
        when phase16 => -- (to read from or Write to IIC starts from here)
            if SUART_BUFF_EMPTY = '0' then
                MAIN_STATE <= phase17;
            end if;
        when phase17 => --assert Read data
            if SUART_DATA_RDY = '1' then
                MAIN_STATE <= phase18;
            end if;
        when phase18 => --  to read Slave Addr.
            MAIN_STATE <= phase19;
        when phase19 => -- release Read data
            if SUART_BUFF_EMPTY = '0' then
                MAIN_STATE <= phase20;
            end if;
        when phase20 => -- assert Read
            if SUART_DATA_RDY = '1' then
                MAIN_STATE <= phase21;
            end if;
        when phase21 => -- read Reg. Addr.
                MAIN_STATE <= phase22;
        when phase22 => --release Read data
            MAIN_STATE <= phase23;
        when phase23 => -- check if go for IIC_Read or IIC_WRITE
            case IIC_R_Wn_tmp is
                when '1' =>
                    MAIN_STATE <= phase24;
                when others => -- normally write
                    MAIN_STATE <= phase30;
            end case;
        when phase24 => -- assert IIC READ (only Read from IIC)
            MAIN_STATE <= phase25;
        when phase25 => -- wait for IIC to respond
            if IIC_Busy = '1' then
                MAIN_STATE <= phase26;
            elsif IIC_ERROR = '1' then
                MAIN_STATE <= phase36;
            end if;
        when phase26 => -- release IIC Read
            if (SUART_TX_RDY = '1' and IIC_DONE = '1') then 
                MAIN_STATE <= phase27;
            elsif (IIC_ERROR = '1') then
                MAIN_STATE <= phase36;
            end if;
        when phase27 => -- assert SUART_TRANSMIT
            if SUART_TX_RDY = '0' then 
                MAIN_STATE <= phase28;
            end if;
        when phase28 => -- wait for SUART to finish the transfer
            if SUART_TX_RDY = '1' then 
                MAIN_STATE <= phase29;
            end if;
        when phase29 => -- release SUART_TRANSMIT
            MAIN_STATE <= phase0;
        when phase30 => --to read Reg. value (only write to IIC)
            if SUART_BUFF_EMPTY = '0' then
                MAIN_STATE <= phase31;
            end if;
		when phase31 => -- assert Read data
		  if SUART_DATA_RDY = '1' then
		      MAIN_STATE <= phase32;
		  end if;
		when phase32 => -- read Reg. Value
			MAIN_STATE <= phase33;							   
        when phase33 => -- Release Read data and assert IIC write
            MAIN_STATE <= phase34;
        when phase34 => -- wait for IIC to respond
            if IIC_Busy = '1' then
                MAIN_STATE <= phase35;
            elsif IIC_ERROR = '1' then
                MAIN_STATE <= phase36;
            end if;
        when phase35 => --release IIC write and start over
            if (IIC_DONE = '1') then
                MAIN_STATE <= phase0;
            elsif (IIC_ERROR = '1') then
                MAIN_STATE <= phase36;
            end if;
        when phase36 => -- IIC_ERROR is occurded then assert IIC reset_n
            MAIN_STATE <= phase37;
        when others =>
            MAIN_STATE <= phase0;  
    end case;
end if;
end process;
--------------------------------------------------------------
Main_State_Pro2: process(MAIN_STATE)
begin
    case MAIN_STATE is
        when phase0 =>
            SUART_READ <= '0';
            IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase1 =>
            SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
		when phase2 =>
			SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase3 =>
            SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase4 =>
            SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase5 =>
            SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase6 =>
            SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase7 =>
            SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase8 =>
            SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase9 =>
            SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase10 =>
            SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase11 =>
            SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase12 =>
            SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase13 =>
            SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase14 =>
            SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase15 =>
            SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase16 =>
            SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase17 =>
            SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <= (others => '0');
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase18 =>
			SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  SUART_DATA(7 downto 1);
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase19 =>
            SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase20 =>
            SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= (others => '0');
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase21 =>
			SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= SUART_DATA;
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase22 =>
            SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase23 =>
            SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase24 =>
			SUART_READ <= '0';
			IIC_Exe <= '1';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase25 =>
			SUART_READ <= '0';
			IIC_Exe <= '1';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase26 =>
			SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase27 =>
			SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '1';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase28 =>
			SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '1';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase29 =>
			SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase30 =>
			SUART_READ <= '0';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase31 =>
            SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
			IIC_Reg_val_to_write_tmp <= (others => '0');
        when phase32 =>
			SUART_READ <= '1';
			IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
            IIC_Reg_val_to_write_tmp <= SUART_DATA;
        when phase33 =>
            SUART_READ <= '0';
            IIC_Exe <= '1';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
            IIC_Reg_val_to_write_tmp <= IIC_Reg_val_to_write_tmp;
        when phase34 =>
            SUART_READ <= '0';
            IIC_Exe <= '1';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
            IIC_Reg_val_to_write_tmp <= IIC_Reg_val_to_write_tmp;
        when phase35 =>
            SUART_READ <= '0';
            IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
            IIC_Reg_val_to_write_tmp <= IIC_Reg_val_to_write_tmp;
        when phase36 =>
            SUART_READ <= '0';
            IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
            IIC_Reg_val_to_write_tmp <= IIC_Reg_val_to_write_tmp;
        when phase37 =>
            SUART_READ <= '0';
            IIC_Exe <= '0';
            SUART_TRANSMIT <= '0';
			IIC_Slave_Addr_tmp <=  IIC_Slave_Addr_tmp;
			IIC_Reg_addr_tmp <= IIC_Reg_addr_tmp;
            IIC_Reg_val_to_write_tmp <= IIC_Reg_val_to_write_tmp;
        when others => NULL;
    end case;
end process;
end Behavioral;
