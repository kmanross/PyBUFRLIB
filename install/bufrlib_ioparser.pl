#!/usr/bin/perl

##################################################################
# Script:       bufrlib_ioparser.pl
#
# Abstract:     Helper file for setup_bufrlib2python.sh that reads
#               the BUFRLIB FORTRAN src files to get the inputs/
#               outputs and then modifies the f2py signature with
#               the proper intent() call
#
# Requirements: f2py (see either http://cens.ioc.ee/projects/f2py2e/ or
#                     http://www.scipy.org/F2py)
#               
#               
#
# Assumptions:  
#               
#
# Peripherals:  BUFRLIB src files
#               
#               
#             
#               
# 
# Author:       K. Manross (NCAR/DSS) - <manross@ucar.edu>
# Revision:     29 August 2012 - Initial Version
#
##################################################################


use Class::Struct;

### Get files
#@filelist = `ls -1 /tmp/KManTest/BUFTemp_Test/*.f`;
@filelist = @ARGV[1..$#ARGV];
$PYBLIB = $ARGV[0];

$test = 0;

### For each file, we need a bunch of info. We'll store them in a struct
struct Funcs =>
[
  type => '$',
  name => '$',
  intent => '%'
];

### %funchash is a hash of 'sub/func name' => Struct{type, name, args}
### storing the struct into a hash allows us to search based of name
%funchash = ();

### Loop through all the source files in BUFRLIB to get what we need
foreach $file (@filelist) {

    ### Get & parse header into a csv string of type,name
    $funcsub = header($file);

    ### Occasionally run into files that don't have what we need.
    if ($funcsub eq '') {  next; }

    @typename = split(/,/,lc($funcsub));

    ### Capture inputs and outputs. See subroutine names below for details
    $inputs = lc(rawin($file));
    $outputs = lc(rawout($file));

    ### check for args that are used as both inputs and outputs, adjust lists
    $inouts = checkinouts(\$inputs, \$outputs);
    
    ### Intitialize a struct for this file
    my $funcs = Funcs->new();
    $funcs->type($typename[0]);
    $funcs->name($typename[1]);

    ### This is how we store hashes in a struct. This is the 'intent' hash
    ### that is part of the struct (not to be confused with the hash of structs
    ### which is 'funchash'.
    foreach $i (split(/,/,$inputs)) {
      $funcs->intent($i, "in");
    }
    foreach $o (split(/,/,$outputs)) {
      $funcs->intent($o, "out");
    }
    foreach $io (split(/,/,$inouts)) {
      $funcs->intent($io, "inout");
    }

    ### Now store the whole struct into the hash funcsub with the key of the 
    ### func/sub name
    $funchash{$typename[1]} = $funcs;

}

### We only want to test things, not actually write anything out
if ($test) {
  testhash(%funchash);
  exit();
}

open(IN,$PYBLIB) or die "\n\n\tCannot open $PYBLIB. Exitting...\n\n";
@pyblib_file = <IN>;
close(IN);

### Back up original signature file
`cp $PYBLIB $PYBLIB.BAK`;

### Open new file for output
open(NEW,">$PYBLIB");

### Initialize flags
$namelock = '';
$end = '';

### Run through original file, adding 'intent(?)' to input/output lines
foreach $line (@pyblib_file) {

  ### If we are in a valid sub/func block, grab variable, search struct for
  ### variable (if i/o var) and add ", intent(in|out|inout)" to line 
  if ($namelock ne '') {
    ($param) = $line =~ m/ :: (\w+)/;
    if ($funchash{$namelock}->intent($param) ne '') {
      $intent = ", intent(" . $funchash{$namelock}->intent($param) . ")";
      $line =~ s/ :: /$intent :: /;
      print NEW "$line";
      next;
    }
  }
  

  ### End of subroutine/function call found in the combined F2PY signature file
  ### for this particular subroutine. Reset flags
  if ($line =~ /^ +$end/ && $end ne '') {
    $namelock = '';
    $end = '';
  }

  ### Found valid subroutine/function call found in the combined F2PY signature file
  ### set flag to say we are in a valid block util we hit proper 'end' call
  if ($line =~ /^ +(function|subroutine) \w+/) {
     ($type,$name, @args) = split(/,/,parsesub($line));

     # No args to modify, skip (see 'bfrini.f')
     if ($name eq '') { 
         print NEW "$line";
         next; 
     }

     $namelock = $name;
     $func = $funchash{$name}->name;
     if ($func ne '') {
       $end = "end $type $name";
     }
  }
  print NEW "$line";

}

close(NEW);

### Parse the subroutine/function call found in the combined F2PY signature file
sub parsesub() {
  my $line = shift;
  (my $dummy, my $type, my $nameargs, my @rest) = split(/ +/,$line);
  return "$type," . parseargs($nameargs);
}

### probably no longer needed, but parse the args found in 
### subroutine/function call found in the combined F2PY signature file
sub parseargs {
  #likely in the form of "name(arg1,arg2,...,argn)
  my $string = shift;
  (my $name, my $args) = $string =~ m/(\w+)\((.*)\)/;
  return "$name,$args";
}

### Test output for reach file's struct
sub testhash() {
  my (%fh) = @_;
  foreach $key (sort(keys(%fh))){
    print ">>" . $key . "<<\n";
    print "\t(type): " . $fh{$key}->type . "\n";
    print "\t(name): " . $fh{$key}->name . "\n";
    foreach $k (keys %{$fh{$key}->intent}){
       print "\t(intent): $k :: " . $fh{$key}->intent($k) ."\n";
    }
    print "=====================\n\n";
  }

}

### If a particular arg is used for both input and output, remove from inputs list
### and outputs list and put into 'inouts' list
sub checkinouts () {
  my ($inputs, $outputs) = @_;
  my @inout = ();

  my @ins = split(/,/,$$inputs);
  my @outs = split(/,/,$$outputs);

 foreach $in (@ins) {
   # Get index of in element - FOUND THIS ON PERLMONKS, need url
   my( $in_index )= grep { $ins[$_] eq $in } 0..$#ins;
   #get index of out element if matches $in
   # TODO :: this assumes that in size > out size. Make smarter!!
   my( $out_index )= grep { $outs[$_] eq $in } 0..$#outs;

   if ($in_index  ne '' && $out_index ne '') {
     #delete $ins[$in_index];
     #delete $outs[$out_index];
     splice(@ins,$in_index,1);
     splice(@outs,$out_index,1);
     push(@inout,$in);
   }

 }
 
 $$inputs = join(",",@ins);
 $$outputs = join(",",@outs);
 return join(",",@inout);
}

### Capture the first several lines of the file which
### includes the declaration and the parameters which can be multiline
### ship those lines to fs() & return a csv string of tyope & name
sub header() {
  my $f = shift;
  # capture all lines prior to first comment
  my $head = `sed '/^C/,\$d' $f`;
  # strip off leading and ending whitespace
  $head =~ s/^\s+//;
  $head =~ s/\s+$//;
  # For parameter lists that extend across multiple lines, contract
  $head =~ s/\n +[^a-zA-Z0-9 ]//g;
  # remove any excess unneeded whitespace
  $head =~ s/\s{2,}//g;
  # Next two lines eliminate whictespace in parameter list
  $head =~ s/(\W) +/$1/g;
  $head =~ s/ (\(|\))/$1/g;
  return fs($head);
}

### take the header lines and return type & name.
### Initially wanted to grab args, but not now
sub fs() {
  my $string = shift;
  my @parts = split(/ /,$string);
  my $type = $parts[-2];
  my $surname = $parts[-1];
  (my $name, my $dummy) = split(/\(/,$surname);
  return "$type,$name";
}


### Capture the INPUT lines using 'sed' to collect the lines between REMARKS & USAGE
### Then find the lines between INPUT & OUTPUT, then grep for the individual args
sub rawin() {
    my $f = $_[0];

    my $ret = `sed -n /USAGE:/,/REMARKS:/p $f  | sed -n '/INPUT ARGUMENT LIST/,/OUTPUT ARGUMENT LIST/p'`;
    @arr = grep(/^C +\w+ +-/,split(/\n/,$ret));
    return parseline(@arr);
}

### Similar to rawin() but looking for the OUTPUTS
sub rawout() {
    my $f = $_[0];
    my $ret = `sed -n /USAGE:/,/REMARKS:/p $f  | sed -n '/OUTPUT ARGUMENT LIST/,/REMARKS/p'`;
    @arr = grep(/^C +\w+ +-/,split(/\n/,$ret));
    return parseline(@arr);
}

### take the captured INPUTS/OUTPUYTS lines, captures just the args, returns csv string
sub parseline () {
  my @vars = ();
  foreach my $line (@_) {
    if ($line =~ m/(^C +\w+ +-)/) {
        push(@vars,(split(/\s+/,$1))[1]);
    }
  }
  return join(",",@vars);
}
