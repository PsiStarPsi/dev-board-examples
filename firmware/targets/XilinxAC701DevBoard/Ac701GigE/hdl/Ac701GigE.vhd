-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : Ac701GigE.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-02-02
-- Last update: 2016-05-11
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'Example Project Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'Example Project Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.EthMacPkg.all;

library unisim;
use unisim.vcomponents.all;

entity Ac701GigE is
   generic (
      TPD_G         : time    := 1 ns;
      SIM_SPEEDUP_G : boolean := false;
      SIMULATION_G  : boolean := false);
   port (
      -- LEDs and Reset button
      extRst  : in  sl;
      led     : out slv(3 downto 0);
      -- XADC Ports
      vPIn    : in  sl;
      vNIn    : in  sl;
      -- MGT Clock Select
      clkSelA : out slv(1 downto 0);
      clkSelB : out slv(1 downto 0);
      -- GT Pins
      gtClkP  : in  sl;
      gtClkN  : in  sl;
      gtRxP   : in  sl;
      gtRxN   : in  sl;
      gtTxP   : out sl;
      gtTxN   : out sl);      
end Ac701GigE;

architecture top_level of Ac701GigE is

   constant AXIS_SIZE_C : positive         := 1;
   constant IP_ADDR_C   : slv(31 downto 0) := x"40_01_A8_C0";        -- 192.168.1.64
   constant MAC_ADDR_C  : slv(47 downto 0) := x"63_45_00_56_00_08";  -- 08:00:56:00:45:63

   signal txMasters : AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0);
   signal txSlaves  : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);
   signal rxMasters : AxiStreamMasterArray(AXIS_SIZE_C-1 downto 0);
   signal rxSlaves  : AxiStreamSlaveArray(AXIS_SIZE_C-1 downto 0);

   signal clk      : sl;
   signal rst      : sl;
   signal phyReady : sl;

begin

   ------------------------
   -- GigE Core for ARTIX-7
   ------------------------
   U_ETH_PHY_MAC : entity work.GigEthGtp7Wrapper
      generic map (
         TPD_G              => TPD_G,
         NUM_LANE_G         => 1,
         -- Clocking Configurations
         USE_GTREFCLK_G     => false,
         CLKIN_PERIOD_G     => 8.0,
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => 8.0,
         CLKOUT0_DIVIDE_F_G => 8.0,
         -- AXI-Lite Configurations
         AXI_ERROR_RESP_G   => AXI_RESP_SLVERR_C,
         -- AXI Streaming Configurations
         AXIS_CONFIG_G      => (others => EMAC_AXIS_CONFIG_C))
      port map (
         -- Streaming DMA Interface 
         dmaClk       => (others => clk),
         dmaRst       => (others => rst),
         dmaIbMasters => rxMasters,
         dmaIbSlaves  => rxSlaves,
         dmaObMasters => txMasters,
         dmaObSlaves  => txSlaves,
         -- Misc. Signals
         extRst       => extRst,
         phyClk       => clk,
         phyRst       => rst,
         phyReady(0)  => phyReady,
         -- MGT Ports
         gtClkP       => gtClkP,
         gtClkN       => gtClkN,
         gtTxP(0)     => gtTxP,
         gtTxN(0)     => gtTxN,
         gtRxP(0)     => gtRxP,
         gtRxN(0)     => gtRxN);      

   -------------------
   -- Application Core
   -------------------
   U_App : entity work.AppCore
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "7SERIES",
         APP_TYPE_G   => "ETH",
         AXIS_SIZE_G  => AXIS_SIZE_C,
         MAC_ADDR_G   => MAC_ADDR_C,
         IP_ADDR_G    => IP_ADDR_C)         
      port map (
         -- Clock and Reset
         clk       => clk,
         rst       => rst,
         -- AXIS interface
         txMasters => txMasters,
         txSlaves  => txSlaves,
         rxMasters => rxMasters,
         rxSlaves  => rxSlaves,
         -- ADC Ports
         vPIn      => vPIn,
         vNIn      => vNIn);

   ----------------
   -- Misc. Signals
   ----------------
   clkSelA <= "00";
   clkSelB <= "00";
   led(3)  <= '1';
   led(2)  <= '0';
   led(1)  <= not(rst);
   led(0)  <= phyReady;

end top_level;