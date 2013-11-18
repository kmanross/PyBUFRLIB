#!/usr/bin/env python


import py_bufrlib
from optparse import OptionParser
import sys
#from scipy import *
import numpy as np
from numpy.lib import stride_tricks


class test_py_bufrlib:


    def __init__(self,args):

        # Set logical unit number to pass between subroutines
        lubfr = 11
        luprt = 51
        # Physical file to be opened
        f = args
        
        # Open file for READING using FORTRAN open call
        py_bufrlib.fortopen(lubfr,f,'R')
        # Open file for WRITING using FORTRAN open call
        py_bufrlib.fortopen(luprt,'dumpbufr.out','W')
        
        # Connect file to BUFRLIB library via openbf
        py_bufrlib.openbf(lubfr,'IN',lubfr)

        py_bufrlib.datelen(10)
        
        # Attempt to read a subset from the BUFR file

        iret = 0
        while iret != -1:
            subset,jdate,iret = py_bufrlib.readns(lubfr)
            print ' MESSAGE TYPE ' + subset + '\n\n'
            lun,il,im = py_bufrlib.status(lubfr)


            lunidx = lun-1
            ptag = stride_tricks.as_strided(py_bufrlib.tables.tag,\
                                    strides=(py_bufrlib.tables.tag.shape[1],1))
            ptyp = stride_tricks.as_strided(py_bufrlib.tables.typ,\
                                    strides=(py_bufrlib.tables.typ.shape[1],1))

            ###########################################
            #  OK, in order to get character arrays FROM the BUFRLIB common block data
            #  we need to reorganize the arrays. Typically the N-dimensional character
            #  array returns from FORTRAN as 
            #
            #  ([dimenson length,]dimension length, character length)
            #
            #  This, combined with FORTRAN ordering creates a messy way to get 
            #  characters back into the expected string order
            #  See http://cens.ioc.ee/pipermail/f2py-users/2012-September/002320.html
            #  for an example.
            #
            #  Fortunately, after stumbling around with Numpy strides and the help of this
            #  site: http://scipy-lectures.github.com/advanced/advanced_numpy/index.html#indexing-scheme-strides
            #  there seems to be a standardized way to reorder the array such that 
            #  the resulting array is indexed as is expected when examining the FORTRAN code.
            #
            #  So, for a "simple" character array like TYP(MAXJL) found in the BUFRLIB common
            #  block /TABLES/ where TYP is CHARACTER*3, it returns from BUFRLIB to python
            #  in the dimension (MAXJL,3).  (Refer back to the first link for the example).
            #
            #  We can rerder the array by using the following convention (essentially feeding
            #  the shape of the N+1 D array in reverse order so that the first stride element
            #  is the length of the character length):
            #
            #  a = stride_tricks.as_strided(py_bufrlib."COMMONBLOCK"."VARIABLE",
            #                      strides=(py_bufrlib."COMMONBLOCK"."VARIABLE".shape[N],\
            #                               ...
            #                      strides=(py_bufrlib."COMMONBLOCK"."VARIABLE".shape[1],1))
            #
            #  We then access 'a' as we would a N-dimensional array, returning a
            #  numpy array with the characters in order. (use the .tostring() method to
            #  "string-ize" it if desired.)
            #
            #  This has worked on a 1D character array (TAG, TYP in the above code) and a
            #  2D character array (TABB, below).  I have not tried this on anything greater
            #  than a 2D character array, though the logic is extensible, I assume.
            #
            ###########################################
             
            for nv in range(0,py_bufrlib.usrint.nval[lunidx]):
                node = py_bufrlib.usrint.inv[nv,lunidx] -1
                nemo = ptag[node].tostring()
                ityp = py_bufrlib.tables.itp[node]
                type = ptyp[node].tostring()
                numb = ''
                desc = ''
                unit = ''
                rval = ''
#                print '\tNODE: ', node
#                print '\tNEMO: ' + nemo
#                print '\tITYP: ', ityp
#                print '\tTYPE: ', type

                if ityp >= 1 and ityp <= 3:
                    idn,tab,nemtab_iret = py_bufrlib.nemtab(lun,nemo)
#                    print '\t\tIDN: ', idn
#                    print '\t\tTAB: >>' + tab + '<<'
#                    print '\t\tN: ', nemtab_iret
                    
                    tabb = stride_tricks.as_strided(py_bufrlib.tababd.tabb,\
                            strides=(py_bufrlib.tababd.tabb.shape[2],\
                                     py_bufrlib.tababd.tabb.shape[1],1))

                    numb = tabb[nemtab_iret-1,lunidx][0:6].tostring()
                    desc = tabb[nemtab_iret-1,lunidx][15:69].tostring().rstrip()
                    unit = tabb[nemtab_iret-1,lunidx][70:93].tostring().rstrip()
                    rval = py_bufrlib.usrint.val[nv,lunidx]
#
#                print '\t\tNUMB: ', numb
#                print '\t\tDESC: ', desc
#                print '\t\tUNIT: ', unit
#                print '\t\tRVAL: >>>', rval, '<<<'

                if ityp == 0 or ityp == 1:
                    continue #print 'SKIPPING DUE TO TYPE: ', type
                elif ityp == 2:
                    if py_bufrlib.ibfms(float(rval)) != 0:
                        rval = 'MISSING'
                        print '{0:6s}  {1:10s}  {2:>20s}  {3:24s}      {4:48s}'.format(\
                                                            numb,nemo,rval,unit,desc)
                    else:
#                        if isinstance(rval, basestring):
                            print '{0:6s}  {1:10s}  {2:>20s}  {3:24s}      {4:48s}'.format(\
                                                                numb,nemo,str(rval),unit,desc)
#                        else:
#                            print '{0:6s}  {1:10s}  {2:20.2f}  {3:24s}      {4:48s}'.format(\
#                                                                numb,nemo,rval,unit,desc)
                else:
                    continue










        
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

#    print opts, " :: ", args

    if len(args) > 0:
        test_py_bufrlib(args[0])
    else:
        test_py_bufrlib(opts.bufrfile)

    

