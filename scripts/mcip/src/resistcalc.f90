
!***********************************************************************
!   Portions of Models-3/CMAQ software were developed or based on      *
!   information from various groups: Federal Government employees,     *
!   contractors working on a United States Government contract, and    *
!   non-Federal sources (including research institutions).  These      *
!   research institutions have given the Government permission to      *
!   use, prepare derivative works, and distribute copies of their      *
!   work in Models-3/CMAQ to the public and to permit others to do     *
!   so.  EPA therefore grants similar permissions for use of the       *
!   Models-3/CMAQ software, but users are requested to provide copies  *
!   of derivative works to the Government without restrictions as to   *
!   use by others.  Users are responsible for acquiring their own      *
!   copies of commercial software associated with Models-3/CMAQ and    *
!   for complying with vendor requirements.  Software copyrights by    *
!   the MCNC Environmental Modeling Center are used with their         *
!   permissions subject to the above restrictions.                     *
!***********************************************************************

! RCS file, release, date & time of last delta, author, state, [and locker]
! $Header: /project/work/rep/MCIP2/src/mcip2/resistcalc.F,v 1.6 2007/08/03 20:49:50 tlotte Exp $ 


SUBROUTINE resistcalc

!-------------------------------------------------------------------------------
! Name:     Resistance Calculation
! Purpose:  Calculates aerodynamic and stomatal resistances required
!           to compute dry deposition velocities.
! Notes:    Does not include effects of seasons.  Assumed maximum leaf area
!           index for each land use category.
! Revised:  18 Sep 2001  Original version.  (J. Pleim and T. Otte)
!           21 Dec 2001  Added IMPLICIT NONE and missing variable
!                        declarations.  (S. Howard and T. Otte)
!           23 Jan 2002  Changed missing value on XRADYN and XRSTOM to
!                        BADVAL3.  (T. Otte)
!           07 Feb 2002  Changed logic to define water point using dominant
!                        land use category.  (T. Otte)
!           10 Jun 2003  Changed definition of F2 to be based on land use
!                        category.  Changed variable name GS to GSFC to avoid
!                        confusion with (future) variable GS in MCIPPARM.
!                        Added snow condition to calculation of saturation
!                        vapor pressure.  (J. Pleim and T. Otte)
!           07 Jul 2004  Removed XFLAGS.  (T. Otte)
!           09 Mar 2005  Removed unused variable W2AVAIL.  (T. Otte)
!           14 Jul 2006  Removed unused variables W2MXAV and WSAT.  Use
!                        land-water mask instead of dominant land use category
!                        to determine water points.  (T. Otte)
!           10 Apr 2007  Changed USTAR and RADYN to 2D arrays without a
!                        dimension for fractional land use that was required
!                        for RADMdry.  Removed dependency on module LRADMDAT.
!                        Added condition to set RADYN and RSTOM to BADVAL3 if
!                        USTAR is 0.0 (presumably at the beginning of a
!                        meteorology run) to prevent division by zero.  Moved
!                        land-use-based filling of F2 and RSTMIN from subroutine
!                        METVARS2CTM.  (T. Otte)
!                        Changed Schmidt number for water from 0.599 to 0.606
!                        to be consistent with m3dry.  (J. Bash and T. Otte)
!           28 Apr 2008  Expanded lookup tables for stomatal resistance and F2
!                        to accommodate 33-category USGS in WRF.  (T. Otte)
!           23 Sep 2009  Added lookup tables for stomatal resistance and F2 to
!                        accommodate MODIS-NOAH and NLCD-MODIS land use
!                        classification systems.  (T. Otte)
!-------------------------------------------------------------------------------

  USE mcipparm
  USE const
  USE const_pbl
  USE xvars
  USE parms3, ONLY: badval3

  IMPLICIT NONE

  REAL                         :: alogz1z0
  INTEGER                      :: c
  REAL                         :: es
  REAL                         :: f1
  REAL                         :: f2
  REAL                         :: f2defmod   (33)
  REAL                         :: f2defnlc   (50)
  REAL                         :: f2defold   (13)
  REAL                         :: f2defusgs  (33)
  REAL                         :: f3
  REAL,          PARAMETER     :: f3min      = 0.25
  REAL                         :: f4
  REAL,          PARAMETER     :: ftmin      = 0.0000001 ! [m/s]
  REAL                         :: ftot
  REAL                         :: ga
  REAL                         :: gsfc
  INTEGER                      :: i
  INTEGER                      :: lu
  CHARACTER*16,  PARAMETER     :: pname      = 'RESISTCALC'
  REAL                         :: psih
  REAL                         :: psih0
  REAL                         :: q1
  REAL                         :: qss
  INTEGER                      :: r
  REAL                         :: radf
  REAL                         :: radl
  REAL                         :: raw
  REAL,          PARAMETER     :: rsmax      = 5000.0   ! [s/m]
  REAL                         :: rstmin
  REAL                         :: rstmod     (33)
  REAL                         :: rstnlc     (50)
  REAL                         :: rstold     (13)
  REAL                         :: rstusgs    (33)
  REAL,          PARAMETER     :: svp2       = 17.67    ! from MM5
  REAL,          PARAMETER     :: svp3       = 29.65    ! from MM5
  REAL                         :: t1
  REAL,          PARAMETER     :: wfc        = 0.240
  REAL,          PARAMETER     :: wwlt       = 0.155
  REAL                         :: z1
  REAL                         :: z1ol
  REAL                         :: zntol

  DATA (f2defmod(i),i=1,33)  /   0.90,   0.90,   0.90,   0.90,   0.90,   0.50,  &
                                 0.50,   0.60,   0.60,   0.70,   0.99,   0.93,  &
                                 0.80,   0.85,   0.99,   0.30,   1.00,   0.50,  &
                                 0.60,   0.20,   0.00,   0.00,   0.00,   0.00,  &
                                 0.00,   0.00,   0.00,   0.00,   0.00,   0.00,  &
                                 0.84,   0.82,   0.80 /

  DATA (rstmod(i),i=1,33)    / 175.0,  120.0,  175.0,  200.0,  200.0,  200.0,   &
                               200.0,  150.0,  120.0,  100.0,  160.0,   70.0,   &
                               150.0,  100.0, 9999.0,  100.0, 9999.0,  175.0,   &
                               120.0,  100.0, 9999.0, 9999.0, 9999.0, 9999.0,   &
                              9999.0, 9999.0, 9999.0, 9999.0, 9999.0, 9999.0,   &
                               150.0,  140.0,  125.0 /

  DATA (f2defnlc(i),i=1,50)  /   1.00,   0.99,   0.85,   0.84,   0.83,   0.82,  &
                                 0.30,   0.50,   0.90,   0.90,   0.90,   0.50,  &
                                 0.50,   0.70,   0.60,   0.60,   0.60,   0.50,  &
                                 0.80,   0.95,   0.99,   0.99,   0.99,   0.99,  &
                                 0.99,   0.99,   0.99,   0.99,   0.99,   0.99,  &
                                 1.00,   0.90,   0.90,   0.90,   0.90,   0.90,  &
                                 0.50,   0.50,   0.60,   0.60,   0.70,   0.99,  &
                                 0.85,   0.80,   0.85,   0.99,   0.30,   1.00,  &
                                 0.00,   0.00 /

  DATA (rstnlc(i),i=1,50)    /9999.0, 9999.0,  120.0,  120.0,  140.0,  160.0,   &
                               100.0,  100.0,  200.0,  175.0,  200.0,  200.0,   &
                               200.0,  100.0,  100.0,  100.0,  100.0,  100.0,   &
                                80.0,   70.0,  200.0,  200.0,  164.0,  200.0,   &
                               164.0,  120.0,  120.0,  120.0,  100.0,  100.0,   &
                              9999.0,  175.0,  120.0,  175.0,  200.0,  200.0,   &
                               200.0,  200.0,  150.0,  120.0,  100.0,  160.0,   &
                                70.0,  150.0,  100.0, 9999.0,  100.0, 9999.0,   &
                              9999.0, 9999.0 /

  DATA (f2defold(i),i=1,13)  /   0.80,   0.90,   0.70,   0.90,   0.90,   0.90,  &
                                 1.00,   0.99,   0.30,   0.60,   0.99,   0.99,  &
                                 0.60 /

  DATA (rstold(i),i=1,13)    / 150.0,   70.0,   83.0,  183.0,  150.0,  200.0,   &
                              9999.0,  164.0,  100.0,  150.0, 9999.0,  200.0,   &
                               120.0 /

  DATA (f2defusgs(i),i=1,33) /   0.80,   0.85,   0.98,   0.90,   0.80,   0.90,  &
                                 0.70,   0.50,   0.60,   0.60,   0.90,   0.90,  &
                                 0.90,   0.90,   0.90,   1.00,   0.99,   0.99,  &
                                 0.30,   0.40,   0.50,   0.60,   0.20,   0.99,  &
                                 0.20,   0.20,   0.20,   0.00,   0.00,   0.00,  &
                                 0.84,   0.82,   0.80 /

  DATA (rstusgs(i),i=1,33)   / 150.0,   70.0,   60.0,   70.0,   80.0,  180.0,   &
                               100.0,  200.0,  150.0,  120.0,  200.0,  175.0,   &
                               120.0,  175.0,  200.0, 9999.0,  164.0,  200.0,   &
                               100.0,  150.0,  200.0,  150.0,  100.0,  300.0,   &
                               100.0,  100.0,  100.0, 9999.0, 9999.0, 9999.0,   &
                               150.0,  140.0,  125.0 /

!-------------------------------------------------------------------------------
! Loop over grid cells to calculate aerodynamic and stomatal resistances.
!-------------------------------------------------------------------------------

  DO c = 1, ncols_x
    DO r = 1, nrows_x

      IF ( xustar(c,r) /= 0.0 ) THEN  ! ustar undefined or 0.0 at init met time

        t1       = xtempm (c,r,1)
        q1       = xwvapor(c,r,1)
        lu       = NINT( xdluse (c,r) )
        z1       = x3htm  (c,r,1)
        z1ol     = z1 / xmol(c,r)
        zntol    = xzruf(c,r) / xmol(c,r)
        alogz1z0 = ALOG(z1/xzruf(c,r))

        ! Fill in land-use-based parameters:

        ! Effects of soil moisture are contained in F2.
        ! When not using LSM, soil moisture is estimated by moisture
        ! availability as a function of dominant land use category.
        ! Soil parameters here are based on loam.  This formulation
        ! does not include effects of precipitation.

        IF ( xlusrc(1:3) == 'USG' ) THEN
          f2     = f2defusgs(lu)
          rstmin = rstusgs(lu)
        ELSE IF ( xlusrc(1:3) == 'MM5' ) THEN
          f2     = f2defold(lu)
          rstmin = rstold(lu)
        ELSE IF ( xlusrc(1:3) == 'MOD' ) THEN
          f2     = f2defmod(lu)
          rstmin = rstmod(lu)
        ELSE IF ( xlusrc(1:3) == 'NLC' ) THEN
          f2     = f2defnlc(lu)
          rstmin = rstnlc(lu)
        ELSE
          WRITE (6,9000) TRIM(xlusrc)
          GOTO 1001
        ENDIF

!-------------------------------------------------------------------------------
! Calculate aerodynamic resistance XRADYN.
!-------------------------------------------------------------------------------

        IF ( z1ol >= 0.0 ) THEN 

          IF ( z1ol > 1.0 ) THEN
            psih0 = 1.0 - betah - z1ol
          ELSE
            psih0 = -betah * z1ol
          ENDIF

          IF ( zntol > 1.0 ) THEN
            psih = psih0 - (1.0 - betah - zntol)
          ELSE
            psih = psih0 + betah * zntol
          ENDIF

        ELSE

          psih = 2.0 * ALOG( (1.0 + SQRT(1.0 - gamah*z1ol)) /  &
                             (1.0 + SQRT(1.0 - gamah*zntol)) )

        ENDIF

        xradyn(c,r) = pro * ( alogz1z0 - psih ) / ( vkar * xustar(c,r) )

!-------------------------------------------------------------------------------
! Calculate stomatal resistance XRSTOM.
!-------------------------------------------------------------------------------

        ! Effects of transpiration.

        IF ( NINT(xlwmask(c,r)) == 0 ) THEN  ! water

          xrstom(c,r) = badval3   ! inverse taken in metcro.F

        ELSE

          ! Effects of radiation.

          IF ( rstmin > 130.0 ) THEN
            radl = 30.0   ! [W/m**2]
          ELSE
            radl = 100.0  ! [W/m**2]
          ENDIF

          radf = 1.1 * xrgrnd(c,r) / ( radl * xlai(c,r) )  ! NP89 - EQN34
          f1   = (rstmin / rsmax + radf) / (1.0 + radf)

          ! Effects of air temperature following Avissar (1985) and Xiu (7/95).

          IF ( t1 <= 302.15 ) THEN
            f4 = 1.0 / (1.0 + EXP(-0.41 * (t1 - 282.05)))
          ELSE
            f4 = 1.0 / (1.0 + EXP( 0.50 * (t1 - 314.00)))
          ENDIF

          ftot = MAX( (xlai(c,r) * f1 * f2 * f4), ftmin )
          gsfc = ftot / rstmin

          ! rb(water) = 2/(k*ust) (Scw/Pran)^2/3
          !           = 5/ust (0.606/0.709)^2/3
          !           = 4.503/ust

          raw = xradyn(c,r) + 4.503 / xustar(c,r)    ! 4.503 = (Scw/Pran)^2/3
          ga  = 1.0 / raw

          ! Compute the saturated mixing ratio at surface temperature (XTEMPG).
          ! Saturation vapor pressure [mb] of water.

          IF ( ( xsnocov(c,r) > 0.0 ) .OR. ( xtempg(c,r) <= stdtemp ) ) THEN
            es = vp0 * EXP(22.514 - 6.15e3/xtempg(c,r))
          ELSE        
            es = vp0 * EXP(svp2 * (xtempg(c,r) - stdtemp) / (xtempg(c,r) - svp3))
          ENDIF

          qss  = es * 0.622 / (xprsfc(c,r) - es)

          ! Compute humidity effect according to RH at leaf surface.

          f3 = 0.5 * (gsfc - ga + SQRT(ga * ga + ga * gsfc * (4.0 * q1 /   &
                                     qss - 2.0) + gsfc * gsfc)) / gsfc
          f3 = MIN( MAX(f3,f3min), 1.0 ) 

          xrstom(c,r) = 1.0 / (gsfc * f3)

        ENDIF

      ELSE  ! ustar = 0.0

        xradyn(c,r) = badval3  ! inverse taken in metcro.F
        xrstom(c,r) = badval3  ! inverse taken in metcro.F

      ENDIF

    ENDDO
  ENDDO

  RETURN

!-------------------------------------------------------------------------------! Error-handling section.
!-------------------------------------------------------------------------------
 9000 FORMAT (/, 1x, 70('*'),                                              &
              /, 1x, '*** SUBROUTINE: RESISTCALC',                         &
              /, 1x, '***   UNKNOWN LAND USE INPUT DATA SOURCE: ', a,      &
              /, 1x, 70('*'))

 1001 CALL graceful_stop (pname)
      RETURN

END SUBROUTINE resistcalc