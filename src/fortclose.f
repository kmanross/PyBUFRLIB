      SUBROUTINE FORTCLOSE(RDUNIT)

C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM:    FORTCLOSE
C   PRGMMR: MANROSS          ORG: NCAR/CISL/DSS       DATE: 2012-08-23
C
C ABSTRACT: Extremely simple, but necessary subroutine to simply close
C a file in the FORTRAN framework with the given logical unit number.
C this is solely for the project BUFRLIB2PY where we are wrapping
C the BUFRLIB FORTRAN library to be usd in python. Unless a way can be made
C to pass the filehandle from python to the BUFRLIB subroutine CLOSBF directly,
C this subroutine is needed. (As well as companion FORTOPEN.F)
C
C PROGRAM HISTORY LOG:
C 2012-08-23 K. Manross   -- Original author
C
C USAGE:    CALL FORTCLOSE(RDUNIT,FNAME)
C   INPUT ARGUMENT LIST:
C     RDUNIT   - INTEGER: FORTRAN LOGICAL UNIT NUMBER FOR BUFR FILE
C
C REMARKS:
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C   MACHINE:  PORTABLE TO ALL PLATFORMS
C
C$$$


      integer, intent(in) :: RDUNIT    ! input file name

      close(RDUNIT)
      return
      end
