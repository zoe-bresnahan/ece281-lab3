--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
	  port(
		 i_clk, i_reset  : in    std_logic;
         i_left, i_right : in    std_logic;
         o_lights_L      : out   std_logic_vector(2 downto 0);
         o_lights_R      : out   std_logic_vector(2 downto 0)
	  );
	end component thunderbird_fsm;

	-- test I/O signals
	 --Inputs
       signal w_left : std_logic := '0';
       signal w_right : std_logic := '0';
       signal w_clk : std_logic := '0';
       signal w_reset : std_logic := '0';
     
       --Outputs
       signal w_lights_L : std_logic_vector(2 downto 0) := "000";
       signal w_lights_R : std_logic_vector(2 downto 0) := "000";
       --constants
       --Clock period definition
       constant k_clk_period : time := 10 ns;
	
	
begin
	-- PORT MAPS ----------------------------------------
	--instantiate the unit under test (uut)
        uut: thunderbird_fsm port map(
             i_clk => w_clk,
             i_reset => w_reset,
             i_left => w_left,
             i_right => w_right,
             o_lights_L => w_lights_L,
             o_lights_R => w_lights_R
        );

	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_proc : process
    begin
        w_clk <= '0';
        wait for k_clk_period/2;
        w_clk <= '1';
        wait for k_clk_period/2;
    end process;
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	sim_proc: process
    begin
      --test reset
      w_reset <= '1';
      wait for k_clk_period*1;
          assert w_lights_L = "000" and w_lights_R = "000" report "bad reset" severity failure;
           
      --undo reset
      w_reset <= '0';
      wait for k_clk_period*1;
           
      --test hazard lights (L=1 and R=1)
      w_left <= '1';
      w_right <= '1';
      wait for k_clk_period;
          assert w_lights_L = "111" and w_lights_R = "111" report "bad hazard lights" severity failure;
      
      --reset to OFF state before next test
      w_reset <= '1';
      wait for k_clk_period;
      w_reset <= '0';
      
      --test left turn signal (L=1)
      w_left <= '1';
      wait for k_clk_period;
          assert w_lights_L = "001" report "bad left turn signal 1" severity failure;
      wait for k_clk_period; --wait a clock cycle before moving to next phase
          assert w_lights_L = "011" report "bad left turn signal 2" severity failure;
      wait for k_clk_period; --wait a clock cycle to enter last phase
          assert w_lights_L = "111" report "bad left turn signal 3" severity failure;
      wait for k_clk_period; --wait before restarting pattern if L=1 still
          assert w_lights_L = "001" report "bad left turn signal repeat" severity failure; 
               
      --reset to OFF state before next test
      w_reset <= '1';
      wait for k_clk_period;
      w_reset <= '0';
      
      --test right turn signal (R=1)
      w_right <= '1';
      wait for k_clk_period;
          assert w_lights_R = "001" report "bad right turn signal 1" severity failure;
      wait for k_clk_period; --wait a clock cycle before moving to next phase
          assert w_lights_R = "011" report "bad right turn signal 2" severity failure;
      wait for k_clk_period; --wait a clock cycle to enter last phase
          assert w_lights_R = "111" report "bad right turn signal 3" severity failure;
      wait for k_clk_period; --wait before restarting pattern if R=1 still
          assert w_lights_R = "001" report "bad right turn signal repeat" severity failure;
          
      --reset to OFF state before next test
      w_reset <= '1';
      wait for k_clk_period;
      w_reset <= '0';
      
      --test changing input in the middle of the cycle
      w_left <= '1';
      wait for k_clk_period;
          assert w_lights_R = "001" report "bad right turn signal 1" severity failure;
      w_left <= '0'; --changing input back to off but the turn signal cycle should still finish
      wait for k_clk_period; --wait a clock cycle before moving to next phase
          assert w_lights_R = "011" report "bad right turn signal 2" severity failure;
      wait for k_clk_period; --wait a clock cycle to enter last phase
          assert w_lights_R = "111" report "bad right turn signal 3" severity failure;
          
          
      end process;
	-----------------------------------------------------	
	
end test_bench;
