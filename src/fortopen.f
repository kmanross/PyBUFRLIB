      SUBROUTINE FORTOPEN(RDUNIT,FNAME,RW)

C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM:    FORTOPEN
C   PRGMMR: MANROSS          ORG: NCAR/CISL/DSS       DATE: 2012-08-23
C
C ABSTRACT: Extremely simple, but necessary subroutine to simply open
C a file in the FORTRAN framework with the given logical unit number.
C this is solely for the project BUFRLIB2PY where we are wrapping
C the BUFRLIB FORTRAN library to be usd in python. Unless a way can be made
C to pass the filehandle from python to the BUFRLIB subroutine OPENBF directly,
C this subroutine is needed. (As well as companion FORTCLOSE.F)
C
C PROGRAM HISTORY LOG:
C 2012-08-23 K. Manross   -- Original author
C
C USAGE:    CALL FORTOPEN(RDUNIT,FNAME)
C   INPUT ARGUMENT LIST:
C     RDUNIT   - INTEGER: FORTRAN LOGICAL UNIT NUMBER FOR BUFR FILE
C     FNAME    - CHARACTER*(*): File name
C     RW       - Read or Write?
C   INPUT FILES:
C     UNIT "LUNIT" - BUFR FILE
C
C REMARKS:
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C   MACHINE:  PORTABLE TO ALL PLATFORMS
C
C$$$


      character(*), intent(in) :: FNAME    ! input file name
      character, intent(in) ::RW   ! Read or Write
      integer, intent(in) :: RDUNIT    ! input file name

      if ( (RW .eq. 'W') .or. (RW .eq. 'w') ) then 
         open(unit=RDUNIT,file=FNAME)
      else
         open(unit=RDUNIT,file=FNAME,form='unformatted')
      endif
      rewind(RDUNIT)
      return
      end
