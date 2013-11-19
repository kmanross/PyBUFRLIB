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

    ta_dict = {}
    tb_dict = {}
    td_dict = {}

    def makedict(self,arr):
        mydict = {}
        for x in arr:
            k,v = x.split('::')
            mydict[k.strip()] = [x.strip() for x in v.split(',') if x.strip() != ""]
        return mydict

    def getbs(self, nemo, blist):
        if nemo in self.tb_dict:
            blist.append(nemo)
        elif nemo in self.td_dict:
            for x in self.td_dict[nemo]:
                self.getbs(x,blist)
        return blist


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
        #py_bufrlib.fortopen(luprt,'dumpbufr.out','W')

        print '2'
        # Connect file to BUFRLIB library via openbf
        py_bufrlib.openbf(11,'IN',11)

        print '3'
        # Set date length
        py_bufrlib.datelen(10)
        
        print '4'
        # Attempt to read a subset from the BUFR file
        ctr = 0

        tableas = py_bufrlib.mytableas(11)
        tableds = py_bufrlib.mytableds(11)
        tablebs = py_bufrlib.mytablebs(11)


        #jtab,tab = py_bufrlib.getabdb(11)
        tabs = py_bufrlib.mygetabdb(11)
        for i in range(len(tabs)):
            myline = tabs[i].tostring().replace('\0','')
            if len(myline) > 0:
                print myline.strip()


        tab = py_bufrlib.mytabledict(11)
        tbldict = {}
        for i in range(len(tab)):
            myline = tab[i].tostring().replace('\0','')
            if len(myline) > 0:
                #print myline.strip()
                k,v = myline.strip().split('::')
                tbldict[k.strip()] = v

        print tbldict

        print tabs.tolist()
        print tabs[:].tostring()

        for s in tabs[:]:
            print s.tostring()
            print '------'



        vals = [tabs[x].tostring().replace('\0','').strip() for x in range(len(tabs)) if len(tabs[x].tostring().replace('\0','')) > 0]

        ta = [tableas[x].tostring().replace('\0','').strip() for x in range(len(tableas)) if len(tableas[x].tostring().replace('\0','')) > 0]
        td = [tableds[x].tostring().replace('\0','').strip() for x in range(len(tableds)) if len(tableds[x].tostring().replace('\0','')) > 0]
        tb = [tablebs[x].tostring().replace('\0','').strip() for x in range(len(tablebs)) if len(tablebs[x].tostring().replace('\0','')) > 0]
        print '=== Ds =====', td
        print '=== Bs =====', tb
        print '=== As =====', ta

        self.ta_dict = self.makedict(ta)
        self.td_dict = self.makedict(td)
        self.tb_dict = self.makedict(tb)

#        print '=== td_dict =====', self.td_dict
#        for x in self.ta_dict['NC000002']:
#            if x in self.td_dict:
#              print x + ' Children: ' , self.td_dict[x]
#            elif x in self.tb_dict:
#              print x + ' Bs: ' , self.tb_dict[x]
#            else:
#              print 'Error: ' + x + ' not found in Table D or B'
               
        print '+++++++++++++++++++++'
        
        for a in sorted(self.ta_dict):
            print a + ':'
            for tln in self.ta_dict[a]:
                bs = self.getbs(tln,[])
                print '\t' + tln + ': ', bs
                


if __name__ == '__main__':
    usage = '\nusage: %prog [littleendian_ncepbufrfile]\n\n\
             \tEg.:\t%prog /tmp/gdas.adpsfc.t12z.20120603.bufr\n\n'
    argparse = OptionParser(usage=usage)

#    argparse.add_argument('bufrfile', nargs='?', type=argparse.FileType('r'),\
#                        default=sys.stdin,\
#                        help='Enter full path of LITTLE ENDIAN sample BUFR file')

    argparse.add_option('-d', default='gdas.adpupa.t12z.20120603.bufr',\
                         dest='bufrfile',\
                         help='Use the supplied little_endian sample file for test')

    opts,args = argparse.parse_args()

    print opts, " :: ", args

    if len(args) > 0:
        test_py_bufrlib(args[0])
    else:
        test_py_bufrlib(opts.bufrfile)

    

