#!/bin/sh



INSTALL=`pwd`
BASE="$INSTALL/.."
BUFRLIBVER="BUFRLIB_v10-2-3.tar"
XTRAFILES="$BASE/src"
TMPFILE="$BASE/Files"

if [ ! -d $TMPFILE ]; then
    mkdir $TMPFILE
fi

hash wget 2>/dev/null || { echo >&2 "I require wget but it's not installed.  Aborting."; exit 1; }

echo "wget -P $TMPFILE http://www.nco.ncep.noaa.gov/sib/decoders/BUFRLIB/$BUFRLIBVER"
wget -P $TMPFILE "http://www.nco.ncep.noaa.gov/sib/decoders/BUFRLIB/$BUFRLIBVER"

echo "Copy needed Files..."

cp $XTRAFILES/*.f $TMPFILE
cp $INSTALL/makebufrlib.sh $TMPFILE
cp $INSTALL/bufrlib_ioparser.pl $BASE
cd $TMPFILE

echo "keeping bufrlib.prm arounmd and linking compiled lib"
echo "Compile BUFRLIB..."
tar -xvf $BUFRLIBVER

### Since 'string' is a reserved word in Python, f2py automatically appends
### a '_bn' to the end of 'string' in the signature file. The makes importing
### the wrapped library fail since BUFRLIB has no subroutine 'string_bn'
### so we rename the subroutine here and in all calls to 'bfrstring'
sed -i 's/\(SUBROUTINE\|CALL\) STRING *(/\1 BFRSTRING(/' *.f

### Don't know how many of these there are, but the OUTPUTS section
### of readns.f has a paramater that doesn't match those in the parameter list
sed -i 's/\(.*\)\(IREADNS\)\( *-.*\)/\1IRET\3/' readns.f

./makebufrlib.sh
cd $BASE

echo "Make list..."
list=`ls $TMPFILE/*.[f]`


echo "Initial f2py call..."
f2py $list --include-paths $TMPFILE -m py_bufrlib -h bufrlib.pyf #--overwrite-signature

echo "Getting val"
mxlcc=$(sed -n 's/.*MXLCC = \([0-9]\{1,\}\).*/\1/p' $TMPFILE/bufrlib.prm)
echo "Val: $mxlcc"
TMP_FILE=`mktemp /tmp/bufrlib.XXXXXXXXXX`
sed -e "s/mxlcc/$mxlcc/" bufrlib.pyf > $TMP_FILE
mv $TMP_FILE bufrlib.pyf
#sed -i "s/mxlcc/$mxlcc/" bufrlib.pyf
echo "Replaced"




echo "Calling bufrlib_ioparser.pl..."
bufrlib_ioparser.pl "bufrlib.pyf" $list

"Calling f2py for final time..."
#f2py --lower --include-paths $TMPFILE --f77exec=/glade/apps/opt/modulefiles/../cmpwrappers/ifort --compiler=intel --f77flags="-fPIC -DUNDERSCORE" -c -DUNDERSCORE_G77 bufrlib.pyf $list -L$TMPFILE -lbufr -I$TMPFILE
f2py --lower --include-paths $TMPFILE --fcompiler=gnu95 --f77flags="-fPIC -DUNDERSCORE" -c -DUNDERSCORE_G77 bufrlib.pyf $list -L$TMPFILE -lbufr -I$TMPFILE

