-- SPDX-License-Identifier: MIT
-- Copyright (c) 2023-2026 Dr. Ir. Siavash Ardekani and ETROYL
----------------------------------------------------------------------------------
-- Company: ETROYL
-- Engineer: Dr. Ir. ARDEKANI
-- 
-- Create Date: 26/11/2023 10:25:25 AM
-- Design Name: 
-- Module Name: I2C_MASTER - Behavioral
-- Project Name: Private
-- Target Devices: Generic
-- Tool Versions: Vivado
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

entity I2C_MASTER is
	GENERIC(
			Input_CLK_Freq: integer range 1_000_000 to 300_000_000 := 100_000_000;
			I2C_Bus_CLK_Freq: integer range 100_000 to 3_500_000 := 100_000
			);
    PORT ( 
           CLK : in STD_LOGIC; -- main input clock to drive the core
		   Rst_n : in STD_LOGIC; -- Global core active_low reset
		   R_Wn : in STD_LOGIC; -- if '1' master wants to read data from the slave, if '0' master wants to write into the slave
		   Exe: in STD_LOGIC; -- Execute the command (rising edge)
		   -- outputs --
		   SCL : out STD_LOGIC;
		   SDA_i : in STD_LOGIC; -- tristate input data
		   SDA_o : out STD_LOGIC; -- tristate output data
		   SDA_t : out STD_LOGIC; -- tristate output towards tri-state buffer
		   I2C_Done : out STD_LOGIC;
           -- extra information --
		   Slave_Address : in STD_LOGIC_VECTOR(6 downto 0);
		   Data2slave : in STD_LOGIC_VECTOR(7 downto 0);
		   Reg_add : in STD_LOGIC_VECTOR(7 downto 0);
		   Data_from_slave : out STD_LOGIC_VECTOR(7 downto 0);
		   I2C_Error : out STD_LOGIC; -- if no ACK receive
		   I2C_Busy : out STD_LOGIC -- on operation
		   );

end I2C_MASTER;

architecture Behavioral of I2C_MASTER is
-------------------------------------------------
-----------------COMPONENTS----------------------
-------------------------------------------------

-------------------------------------------------
-------------------------------------------------
-----------------SIGNALS-------------------------
-------------------------------------------------
SIGNAL SCL_tmp : STD_LOGIC;
SIGNAL SCL_shifted : STD_LOGIC;
SIGNAL SCL_shifted_counter : integer range 1 to 3000;
SIGNAL SCL_counter : integer range 1 to 3000;
TYPE FSM is (phase_2, phase_1, phase0, phase1, phase2, phase3, phase4, phase5, phase6, phase7, phase8, phase9);
SIGNAL SDA_state : FSM := phase_2;
SIGNAL devidor : integer range 1 to 3000;
SIGNAL devidor_2 : integer range 1 to 1500;
SIGNAL devidor_4 : integer range 1 to 750;
SIGNAL Enable : STD_LOGIC;
SIGNAL Data2slave_tmp : STD_LOGIC_VECTOR(7 downto 0);
SIGNAL bit_counter : integer range 0 to 15;
SIGNAL I2C_ACK_tmp : STD_LOGIC;
SIGNAL Data_from_slave_tmp : STD_LOGIC_VECTOR(7 downto 0);
SIGNAL Sync : STD_LOGIC;
SIGNAL sync_state : FSM := phase_2;
SIGNAL Sync_hand_shake : STD_LOGIC;

begin
devidor <= Input_CLK_Freq/I2C_Bus_CLK_Freq;
devidor_2 <= devidor/2;
devidor_4 <= devidor_2/2;
I2C_Busy <= Enable;

---------------------PROCESSes-------------------
-------------------------------------------------
-------------------------------------------------
process(CLK, Sync, Rst_n)
begin
	if Rst_n = '0' or Sync = '1' then
		SCL_counter <= 1;
		SCL_tmp <= '1';
	elsif RISING_EDGE(CLK) then
		if SCL_counter >= devidor then
			SCL_counter <= 1;
			SCL_tmp <= '1';
		elsif SCL_counter >= devidor_2 then
			SCL_counter <= SCL_counter + 1;
			SCL_tmp <= '0';
		else
			SCL_counter <= SCL_counter + 1;
			SCL_tmp <= '1';
		end if;
	end if;
end process;
-------------------------------------------------
process(CLK, Exe, Sync_hand_shake)
begin
	if RISING_EDGE(CLK) then
		case sync_state is
			when phase_2 =>
				Sync <= '0';
				if Exe = '1' then
					sync_state <= phase_1;
				end if;
			when phase_1 =>
				Sync <= '1';
				if Sync_hand_shake = '1' then
					sync_state <= phase0;
				end if;
			when phase0 =>
				Sync <= '0';
				if Exe = '0' then
					sync_state <= phase_2;
				end if;
			when others => null;
		end case;
	end if;
end process;

-- This shifted SCL is used for its rising edge to drive the SDA 
process(CLK, Sync)
begin
	if Sync = '1' then
		SCL_shifted_counter <= 1;
		SCL_shifted <= '0';
		Sync_hand_shake <= '1';
	elsif RISING_EDGE(CLK) then
		Sync_hand_shake <= '0';
		if SCL_shifted_counter >= devidor then
			SCL_shifted_counter <= 1;
			SCL_shifted <= '0';
		elsif SCL_shifted_counter >= (devidor_2+devidor_4+5) then
			SCL_shifted_counter <= SCL_shifted_counter + 1;
			SCL_shifted <= '0';
		elsif SCL_shifted_counter >= (devidor_2+devidor_4) then
			SCL_shifted_counter <= SCL_shifted_counter + 1;
			SCL_shifted <= '1';
		elsif SCL_shifted_counter >= (devidor_4+5) then
			SCL_shifted_counter <= SCL_shifted_counter + 1;
			SCL_shifted <= '0';
		elsif SCL_shifted_counter >= devidor_4 then
			SCL_shifted_counter <= SCL_shifted_counter + 1;
			SCL_shifted <= '1';
		else
			SCL_shifted_counter <= SCL_shifted_counter + 1;
			SCL_shifted <= '0';
		end if;
	end if;
end process;
-------------------------------------------------
-------------------------------------------------
SCL <= SCL_tmp when Enable = '1' else '1';

process(SCL_shifted, Rst_n, Exe, SCL_tmp)
begin
	if (Rst_n = '0') then
		SDA_state <= phase_2;
		Enable <= '0';
	elsif RISING_EDGE(SCL_shifted) then
		CASE SDA_state is
		WHEN phase_2 =>
			Enable <= '0';
			SDA_t <= '0';
			I2C_ACK_tmp <= '1';
			I2C_Error <= '0';
			if (Exe = '1') then
				SDA_state <= phase_1;
				I2C_Done <= '0';
			end if;
		WHEN phase_1 =>
			SDA_state <= phase0;
		WHEN phase0 =>
			Enable <= '1';
			-- start condition
			if SCL_tmp /= '0' then
				SDA_o <= '0';
				SDA_state <= phase1;
				Data2slave_tmp <= Slave_Address&R_Wn;
				bit_counter <= 0;
				SDA_t <= '0';
			end if;
		WHEN phase1 =>
			-- transmitting bits (MSB first)
			if SCL_tmp = '0' then
				if bit_counter < 8 then
					SDA_o <= Data2slave_tmp(7);
					Data2slave_tmp(7 downto 1) <= Data2slave_tmp(6 downto 0);
					bit_counter <= bit_counter + 1;
				else
					SDA_t <= '1';
					SDA_o <= 'Z';
					SDA_state <= phase2;
				end if;
			end if;
		WHEN phase2 =>
			bit_counter <= 0;
			if SCL_tmp = '1' then
				I2C_ACK_tmp <= SDA_i;
				Data2slave_tmp <= Reg_add;
				SDA_state <= phase3;
			end if;
		WHEN phase3 =>
			if I2C_ACK_tmp /= '0' then
				I2C_Error <= '1';
				SDA_state <= phase8;
			else
				if SCL_tmp = '0' then
					if bit_counter < 8 then
						SDA_t <= '0';
						SDA_o <= Data2slave_tmp(7);
						Data2slave_tmp(7 downto 1) <= Data2slave_tmp(6 downto 0);
						bit_counter <= bit_counter + 1;
					else
						SDA_t <= '1';
						SDA_o <= 'Z';
						SDA_state <= phase4;
					end if;
				end if;
			end if;
		WHEN phase4 =>
			bit_counter <= 0;
			if SCL_tmp = '1' then
				I2C_ACK_tmp <= SDA_i;
				Data2slave_tmp <= Data2slave;
				if R_Wn = '0' then -- Write mode
					SDA_t <= '0';
					Data2slave_tmp <= Data2slave;
					SDA_state <= phase5;
				else -- Read mode
					SDA_t <= '1';
					SDA_state <= phase6;
				end if;
			end if;
		WHEN phase5 => -- Write mode
			if I2C_ACK_tmp /= '0' then
				I2C_Error <= '1';
				SDA_state <= phase8;
			else
				if SCL_tmp = '0' then
					if bit_counter < 8 then
						SDA_o <= Data2slave_tmp(7);
						Data2slave_tmp(7 downto 1) <= Data2slave_tmp(6 downto 0);
						bit_counter <= bit_counter + 1;
					else
						SDA_t <= '1';
						SDA_o <= 'Z';
						SDA_state <= phase7;-- stop conditions
					end if;
				end if;
			end if;
		WHEN phase6 => -- Read mode
			if I2C_ACK_tmp /= '0' then
				I2C_Error <= '1';
				SDA_state <= phase8;
			else
				if SCL_tmp = '0' then
					if bit_counter < 8 then
						Data_from_slave_tmp (0) <= SDA_i;
						Data_from_slave_tmp(7 downto 1) <= Data_from_slave_tmp(6 downto 0);
						bit_counter <= bit_counter + 1;
					else
						Data_from_slave <= Data_from_slave_tmp;
						SDA_t <= '0';
						SDA_o <= '0'; -- Ack from master
						SDA_state <= phase7; -- stop conditions
					end if;
				end if;
			end if;
		WHEN phase7 =>
			I2C_ACK_tmp <= SDA_i;
			SDA_state <= phase8;
		WHEN phase8 =>
			SDA_o <= '0';
			SDA_t <= '0';
			SDA_state <= phase9;
		WHEN phase9 =>
			if SCL_tmp = '1' then
				SDA_o <= '1';
				Enable <= '0';
				SDA_state <= phase_2;
				if (I2C_ACK_tmp /= '0' and R_Wn = '0') then
					I2C_Error <= '1';
				else
					I2C_Error <= '0';
					I2C_Done <= '1';
				end if;
			end if;
		WHEN others =>
		END CASE;
	end if;
end process;
end Behavioral;
