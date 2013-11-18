#!/usr/bin/env python

##################################################################
# Script:       testbuild.py 
#
# Abstract:     Test the successfully built/wrapped py_bufrlib
#               
#
# Requirements: Successful build/wrap of BUFRLIB softwarwe by
#               setup_bufrlib2python.sh
#               
#
# Assumptions:  Successful build/wrap of BUFRLIB softwarwe by
#               setup_bufrlib2python.sh
#
# Peripherals:  gdas.adpsfc.t12z.20120603.bufr   :: "test file"
#               
# 
# Author:       K. Manross (NCAR/DSS) - <manross@ucar.edu>
# Revision:     29 August 2012 - Initial Version
#
##################################################################


import py_bufrlib
from optparse import OptionParser
import sys

class test_py_bufrlib:

    def __init__(self,args):

        # Set logical unit number to pass between subroutines
        lubfr = 11
        luprt = 51
        # Physical file to be opened
        f = args
        
        print '1'
        # Open file for READING using FORTRAN open call
        py_bufrlib.fortopen(lubfr,f,'R')
        # Open file for WRITING using FORTRAN open call
        py_bufrlib.fortopen(luprt,'dumpbufr.out','W')

        print '2'
        # Connect file to BUFRLIB library via openbf
        py_bufrlib.openbf(11,'IN',11)

        print '3'
        # Set date length
        py_bufrlib.datelen(10)
        
        print '4'
        # Attempt to read a subset from the BUFR file
        ctr = 0
        while True:
            subset,jdate,iret = py_bufrlib.readns(11)
            print 'SUBSET: ', subset, ', DATE: ', jdate, ', RET: ', iret, ' :: Count: ', ctr
            py_bufrlib.ufbdmp(lubfr,luprt)
            if iret == -1:
                break
            ctr=ctr+1
        
        
if __name__ == '__main__':
    usage = '\nusage: %prog [littleendian_ncepbufrfile]\n\n\
             \tEg.:\t%prog /tmp/gdas.adpsfc.t12z.20120603.bufr\n\n'
    argparse = OptionParser(usage=usage)

#    argparse.add_argument('bufrfile', nargs='?', type=argparse.FileType('r'),\
#                        default=sys.stdin,\
#                        help='Enter full path of LITTLE ENDIAN sample BUFR file')

    argparse.add_option('-d', default='gdas.adpsfc.t12z.20120603.bufr',\
                         dest='bufrfile',\
                         help='Use the supplied little_endian sample file for test')

    opts,args = argparse.parse_args()

    print opts, " :: ", args

    if len(args) > 0:
        test_py_bufrlib(args[0])
    else:
        test_py_bufrlib(opts.bufrfile)

    

