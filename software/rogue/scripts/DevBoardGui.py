#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# Title      : PyRogue DevBoardGui Module
#-----------------------------------------------------------------------------
# File       : DevBoardGui.py
# Author     : Larry Ruckman <ruckman@slac.stanford.edu>
# Created    : 2017-02-15
# Last update: 2017-02-15
#-----------------------------------------------------------------------------
# Description:
# Rogue interface to DEV board
#-----------------------------------------------------------------------------
# This file is part of the 'Development Board Examples'. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the 'Development Board Examples', including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr
import DevBoard as devBoard
import pyrogue.gui
import pyrogue.protocols
import pyrogue.utilities.prbs
import PyQt4.QtGui
import rogue.hardware.pgp
import rogue.hardware.data
import sys
import argparse

#################################################################

# Set the argument parser
parser = argparse.ArgumentParser()

# Add arguments
parser.add_argument(
    "--type", 
    type     = str,
    required = True,
    help     = "define the type of interface",
)  

parser.add_argument(
    "--dev", 
    type     = str,
    required = False,
    default  = '/dev/datadev_0',
    help     = "true to show gui",
)

parser.add_argument(
    "--ip", 
    type     = str,
    required = False,
    default  = '192.168.2.10',
    help     = "IP address",
) 

parser.add_argument(
    "--lane", 
    type     = int,
    required = False,
    default  = 0,
    help     = "PGP Lane",
) 

# Get the arguments
args = parser.parse_args()

#################################################################

# DataDev PCIe Card
if ( args.type == 'datadev' ):

    vc0Srp  = rogue.hardware.data.DataCard(args.dev,(args.lane*32)+0)
    vc1Prbs = rogue.hardware.data.DataCard(args.dev,(args.lane*32)+1)
    
# RUDP Ethernet
elif ( args.type == 'eth' ):

    # Create the ETH interface @ IP Address = args.dev
    ethLink = pr.protocols.UdpRssiPack(
        host    = args.ip,
        port    = 8192,
        size    = 1400,
        packVer = 2, # Version2 is Interleaving support
        )    

    # Map the AxiStream.TDEST
    vc0Srp  = ethLink.application(0); # AxiStream.tDest = 0x0
    vc1Prbs = ethLink.application(1); # AxiStream.tDest = 0x1
    
# Legacy PGP PCIe Card
elif ( args.type == 'pgp' ):

    vc0Srp  = rogue.hardware.pgp.PgpCard(args.dev,args.lane,0) # Registers
    vc1Prbs = rogue.hardware.pgp.PgpCard(args.dev,args.lane,1) # Data

# Undefined device type
else:
    raise ValueError("Invalid type (%s)" % (args.type) )
    
#################################################################    

# Set base
rootTop = pr.Root(name='System',description='Front End Board')
    
# Connect VC0 to SRPv3
srp = rogue.protocols.srp.SrpV3()
pr.streamConnectBiDir(vc0Srp,srp)  

# Connect VC1 to PRBS
prbsRx = pyrogue.utilities.prbs.PrbsRx(name='PrbsRx')
pyrogue.streamConnect(vc1Prbs,prbsRx)
rootTop.add(prbsRx)  
    
# Add registers
rootTop.add(devBoard.Fpga(memBase=srp))

#################################################################    

# Start the system
rootTop.start(pollEn=True)    
rootTop.ReadAll()

# Create GUI
appTop = PyQt4.QtGui.QApplication(sys.argv)
guiTop = pr.gui.GuiTop(group='PyRogueGui')
guiTop.resize(800, 1000)
guiTop.addTree(rootTop)

print("Starting GUI...\n");

# Run gui
appTop.exec_()

#################################################################    

# Stop mesh after gui exits
rootTop.stop()
exit()

#################################################################
