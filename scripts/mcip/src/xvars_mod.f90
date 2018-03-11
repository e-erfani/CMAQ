
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
! $Header: /project/work/rep/MCIP2/src/mcip2/xvars_mod.F,v 1.8 2007/08/03 20:52:02 tlotte Exp $ 


MODULE xvars

!-------------------------------------------------------------------------------
! Name:     X-Variables
! Purpose:  Contains X-variables (CTM arrays plus boundary in horizontal).
! Revised:  25 Jan 1997  Original version.  (D. Byun)
!           20 May 1997  For Models-3 Beta Version.  (???)
!           05 Nov 1997  Added nonhydrostatic/hydrostatic output fnc.  (???)
!           05 Jan 1998  Added mass consistency error, XMCONERR.  (???)
!           30 Apr 1999  Replaced PSTAR with PRSFC.  (???)
!           19 Sep 2001  Converted to free-form f90 and changed name from
!                        MCIPCOM.EXT to module_xvars.f90.  Added XQICE
!                        and XQSNOW.  Removed user-definable control parameters
!                        LWINDMOD, LNOMAPS, LNOTOPO, LM3DDEP, LSANITY, and
!                        LMASSOP.  Changed arrays to allocatable.  Removed
!                        COMMON blocks.  Moved METCOL, METROW, and METLAY to
!                        MCIPPARM.  Removed MET1, MET2, LUSE, and KFFILE since
!                        they are not used.  Changed input date variables.
!                        Moved user input variables to MCIPPARM.  Changed
!                        routine to XVARS.  Added PX variables.  Removed unused
!                        arrays for LAMDA and MCONERR.  (T. Otte)
!           14 Jan 2002  Added new dry deposition species, methanol.
!                        (Y. Wu and T. Otte)
!           27 Feb 2002  Renamed XSURF1 as XTEMP1P5 and XSURF2 as XWIND10.
!                        (T. Otte)
!           18 Mar 2003  Removed XJDRATE.  (T. Otte)
!           09 Jun 2003  Added XF2DEF, XSNOCOV, XDELTA, XLSTWET, and XRH.
!                        Added new dry deposition species:  N2O5, NO3, and
!                        generic aldehyde.  Removed dry deposition species,
!                        ATRA and ATRAP, from output.  (T. Otte, J. Pleim,
!                        and D. Schwede)
!           10 Aug 2004  Added XQGRAUP, XWSPD10, XWDIR10, and XT2.  Removed
!                        XFLAGS, XINDEX, XNAMES, the pointers to XNAMES, and
!                        XLUSNAME.  (T. Otte and D. Schwede)
!           29 Nov 2004  Added XPURB.  (T. Otte)
!           04 Apr 2005  Removed unused variables XREGIME, XRTOLD, XPRSOLD,
!                        XENTRP, and XDENSAM_REF.  Moved XDFLUX and XPSRATE
!                        as local variables in VERTHYD.  Added XMU and XGEOF
!                        for WRF.  Changed XUU and XVV to XUU_D and XVV_D, and
!                        changed XUHAT and XVHAT to XUU_S and XVV_T.  Added
!                        pointers for optional chlorine and mercury species.
!                        Added XU10 and XV10.  (T. Otte, S.-B. Kim, G. Sarwar,
!                        and R. Bullock)
!           19 Aug 2005  Removed XDEPIDX and pointers to XDEPIDX.  Moved
!                        XDEPSPC and XVD to DEPVVARS_MOD.  Removed unused
!                        variables XCAPG, XMMPASS, XFSOIL, and X_RESOL.  Removed
!                        XRH and made it a local scalar in M3DRY.  (T. Otte and
!                        W. Hutzell)
!           14 Jul 2006  Removed XDELTA and XLSTWET to be local variables in
!                        M3DRY.  Added XLWMASK.  (T. Otte)
!           30 Jul 2007  Added IMPLICIT NONE.  Changed XUSTAR and XRADYN to 2D
!                        arrays without a dimension for fractional land use
!                        that was required for RADMdry.  Removed XRBNDY.
!                        Added comments for variables.  Removed low, middle,
!                        and high cloud arrays, and 1.5-m and 10-m temperature
!                        arrays.  Changed 2-m temperature from XT2 to XTEMP2.
!                        Removed internal variables for emissivity and net
!                        radiation.  Added scalar XLUSRC.  Removed XF2DEF and
!                        XRSTMIN to be local variables in RESISTCALC.  Added
!                        XPSTAR0.  (T. Otte)
!           21 Apr 2008  Added 2-m mixing ratio (XQ2) and turbulent kinetic
!                        energy (XTKE) arrays.  (T. Otte)
!           17 Aug 2009  Added land-use category description, XLUDESC.  Added
!                        3D potential vorticity (XPVC), Coriolis (XCORL), and
!                        potential temperature (XTHETA).  Added map-scale
!                        factor squared (on cross points, XMAPC2).  Added
!                        XLATU, XLONU, XMAPU, XLATV, XLONV, and XMAPV. (T. Otte)
!-------------------------------------------------------------------------------

  IMPLICIT NONE

!-------------------------------------------------------------------------------
! Scalars and One-Dimensional Arrays.
!-------------------------------------------------------------------------------

  REAL              :: x3top             ! top of X-array data
  CHARACTER*10      :: xlusrc            ! source of land use classification

  REAL, ALLOCATABLE :: xx3face ( : )     ! layer face of X-array data
  REAL, ALLOCATABLE :: xx3midl ( : )     ! layer middle of X-array data
  REAL, ALLOCATABLE :: xdx3    ( : )     ! layer thickness (positive always)

  CHARACTER*80, ALLOCATABLE :: xludesc ( : )  ! land-use category description

!-------------------------------------------------------------------------------
! Dot-Point and Face 2D Arrays.
!-------------------------------------------------------------------------------

  REAL, ALLOCATABLE :: xlatd   ( : , : )   ! latitude at dot pts [degrees]
  REAL, ALLOCATABLE :: xlatu   ( : , : )   ! latitude at U faces [degrees]
  REAL, ALLOCATABLE :: xlatv   ( : , : )   ! latitude at V faces [degrees]
  REAL, ALLOCATABLE :: xlond   ( : , : )   ! longitude at dot pts [degrees]
  REAL, ALLOCATABLE :: xlonu   ( : , : )   ! longitude at U faces [degrees]
  REAL, ALLOCATABLE :: xlonv   ( : , : )   ! longitude at V faces [degrees]
  REAL, ALLOCATABLE :: xmapd   ( : , : )   ! map scale at dot pts [dim'less]
  REAL, ALLOCATABLE :: xmapu   ( : , : )   ! map scale at U faces [dim'less]
  REAL, ALLOCATABLE :: xmapv   ( : , : )   ! map scale at V faces [dim'less]

!-------------------------------------------------------------------------------
! Cross-Point 2D Arrays.
!-------------------------------------------------------------------------------

  REAL, ALLOCATABLE :: xcorl   ( : , : )  ! Coriolis at cross pts [s-1]
  REAL, ALLOCATABLE :: xlatc   ( : , : )  ! latitude at cross pts [degree]
  REAL, ALLOCATABLE :: xlonc   ( : , : )  ! longitude at cross pts [degree]
  REAL, ALLOCATABLE :: xmapc   ( : , : )  ! map scale at cross pts [dim'less]
  REAL, ALLOCATABLE :: xmapc2  ( : , : )  ! XMAPC**2 at cross pts [dim'less]
  REAL, ALLOCATABLE :: xtopo   ( : , : )  ! topographic height (MSL) [m]

  REAL, ALLOCATABLE :: xprsfc  ( : , : )  ! sfc pressure at cross [Pa]
  REAL, ALLOCATABLE :: xdenss  ( : , : )  ! surface air density [kg/m3]
  REAL, ALLOCATABLE :: xtempg  ( : , : )  ! ground surface temperature [K]
  REAL, ALLOCATABLE :: xrainn  ( : , : )  ! nonconvective rain (cumulative)
  REAL, ALLOCATABLE :: xrainc  ( : , : )  ! convective rain (cumulative)
  REAL, ALLOCATABLE :: xdluse  ( : , : )  ! dominant land use category
  REAL, ALLOCATABLE :: xlwmask ( : , : )  ! land-water mask (1=land, 0=water)
  REAL, ALLOCATABLE :: xpurb   ( : , : )  ! percentage of urban area [%]

  REAL, ALLOCATABLE :: xglw    ( : , : )  ! l/w rad at grnd [W/m2]
  REAL, ALLOCATABLE :: xgsw    ( : , : )  ! s/w rad absorbed at grnd [W/m2]
  REAL, ALLOCATABLE :: xhfx    ( : , : )  ! sensible heat flux [W/m2]
  REAL, ALLOCATABLE :: xqfx    ( : , : )  ! latent heat flux [W/m2]
  REAL, ALLOCATABLE :: xustar  ( : , : )  ! friction velocity [m]
  REAL, ALLOCATABLE :: xpbl    ( : , : )  ! PBL height [m]
  REAL, ALLOCATABLE :: xzruf   ( : , : )  ! surface roughness [m]
  REAL, ALLOCATABLE :: xmol    ( : , : )  ! Monin-Obukhov length [m] 
  REAL, ALLOCATABLE :: xrgrnd  ( : , : )  ! s/w rad reaching grnd [W/m2]

  REAL, ALLOCATABLE :: xwstar  ( : , : )  ! convective velocity scale [m/s]
  REAL, ALLOCATABLE :: xrib    ( : , : )  ! bulk Richardson number
  REAL, ALLOCATABLE :: xradyn  ( : , : )  ! aerodynamic resistance [s/m]
  REAL, ALLOCATABLE :: xrstom  ( : , : )  ! stomatal resistance [s/m]
  REAL, ALLOCATABLE :: xtemp2  ( : , : )  ! 2-m temperature [K]
  REAL, ALLOCATABLE :: xq2     ( : , : )  ! 2-m mixing ratio [kg/kg]
  REAL, ALLOCATABLE :: xwspd10 ( : , : )  ! 10-m wind speed at crs [m/s]
  REAL, ALLOCATABLE :: xwdir10 ( : , : )  ! 10-m wind direction at crs [degrees]
  REAL, ALLOCATABLE :: xalbedo ( : , : )  ! albedo [dim'less]
  REAL, ALLOCATABLE :: xmavail ( : , : )  ! moisture availability
  REAL, ALLOCATABLE :: xcfract ( : , : )  ! cloud fraction [fraction]
  REAL, ALLOCATABLE :: xcldtop ( : , : )  ! cloud top height [m]
  REAL, ALLOCATABLE :: xcldbot ( : , : )  ! cloud bottom height [m]
  REAL, ALLOCATABLE :: xwbar   ( : , : )  ! avg liq water content of cld [g/m3]
  REAL, ALLOCATABLE :: xsnocov ( : , : )  ! snow cover [1=yes, 0=no]

  REAL, ALLOCATABLE :: xu10    ( : , : )  ! 10-m u-component wind at crs [m/s]
  REAL, ALLOCATABLE :: xv10    ( : , : )  ! 10-m v-component wind at crs [m/s]

  REAL, ALLOCATABLE :: xtga    ( : , : )  ! ground temperature [K]
  REAL, ALLOCATABLE :: xt2a    ( : , : )  ! deep layer soil temperature [K]
  REAL, ALLOCATABLE :: xwga    ( : , : )  ! ground sfc soil moisture [m3/m3]
  REAL, ALLOCATABLE :: xw2a    ( : , : )  ! deep layer soil moisture [m3/m3]
  REAL, ALLOCATABLE :: xwr     ( : , : )  ! precip intercepted by canopy [m]
  REAL, ALLOCATABLE :: xlai    ( : , : )  ! leaf area index [area/area]
  REAL, ALLOCATABLE :: xveg    ( : , : )  ! vegetation coverage [decimal]
  REAL, ALLOCATABLE :: xsltyp  ( : , : )  ! soil texture type [category]

  REAL, ALLOCATABLE :: xluse   ( : , : , : ) ! landuse fractions [0-1]

!-------------------------------------------------------------------------------
! Cross-Point 3D arrays.
!-------------------------------------------------------------------------------

  REAL, ALLOCATABLE :: xtempm  ( : , : , : )  ! temp. at layer middle [K]
  REAL, ALLOCATABLE :: xpresm  ( : , : , : )  ! pressure at layer middle [Pa]
  REAL, ALLOCATABLE :: xdensam ( : , : , : )  ! air density at middle [kg/m^3]
  REAL, ALLOCATABLE :: xdenswm ( : , : , : )  ! vapor density at middle [kg/m^3]
  REAL, ALLOCATABLE :: x3jacobf( : , : , : )  ! Jacobian at layer face [m]
  REAL, ALLOCATABLE :: x3jacobm( : , : , : )  ! Jacobian at layer middle [m]
  REAL, ALLOCATABLE :: x3htf   ( : , : , : )  ! AGL height at layer face [m]
  REAL, ALLOCATABLE :: x3htm   ( : , : , : )  ! AGL height at layer middle [m]
  REAL, ALLOCATABLE :: xwhat   ( : , : , : )  ! contra-w wind at face [m/s]
  REAL, ALLOCATABLE :: xwvapor ( : , : , : )  ! water vapor mixing ratio [kg/kg]
  REAL, ALLOCATABLE :: xwwind  ( : , : , : )  ! vertical wind at face [m/s]
  REAL, ALLOCATABLE :: xcldwtr ( : , : , : )  ! cloud water mixing ratio [kg/kg]
  REAL, ALLOCATABLE :: xranwtr ( : , : , : )  ! rain water mixing ratio [kg/kg]
  REAL, ALLOCATABLE :: xqice   ( : , : , : )  ! ice mixing ratio [kg/kg]
  REAL, ALLOCATABLE :: xqsnow  ( : , : , : )  ! snow mixing ratio [kg/kg]
  REAL, ALLOCATABLE :: xqgraup ( : , : , : )  ! graupel mixing ratio [kg/kg]
  REAL, ALLOCATABLE :: xtke    ( : , : , : )  ! turbulent kinetic energy [J/kg]
  REAL, ALLOCATABLE :: xpvc    ( : , : , : )  ! potential vorticity [m^2-K/kg-s]
  REAL, ALLOCATABLE :: xtheta  ( : , : , : )  ! potential temperature [K]

!-------------------------------------------------------------------------------
! Dot-Point (and Face-Point) 3D Arrays.
!-------------------------------------------------------------------------------

  REAL, ALLOCATABLE :: xuu_d   ( : , : , : )  ! u comp. wind on dot pts [m/s]
  REAL, ALLOCATABLE :: xvv_d   ( : , : , : )  ! v comp. wind on dot pts [m/s]
  REAL, ALLOCATABLE :: xuu_s   ( : , : , : )  ! u comp. wind on flux pts [m/s]
  REAL, ALLOCATABLE :: xvv_t   ( : , : , : )  ! v comp. wind on flux pts [m/s]

!-------------------------------------------------------------------------------
! Arrays for WRF only.
!-------------------------------------------------------------------------------

  REAL, ALLOCATABLE :: xmu     ( : , : )      ! Mu at cross points
  REAL, ALLOCATABLE :: xgeof   ( : , : , : )  ! geopotential at face points

!-------------------------------------------------------------------------------
! Reference state variables for non-hydrostatic MM5.
!-------------------------------------------------------------------------------

  REAL, ALLOCATABLE :: xpstar0     ( : , : )      ! reference Pstar [Pa]
  REAL, ALLOCATABLE :: xdensaf_ref ( : , : , : )  ! full-lvl ref dens  [Kg/m^3]

!-------------------------------------------------------------------------------
! Internal Arrays.
!-------------------------------------------------------------------------------

  REAL, ALLOCATABLE :: xdx3htf ( : , : , : )  ! layer thickness [m]
  REAL, ALLOCATABLE :: xdensaf ( : , : , : )  ! total air density at interface
  REAL, ALLOCATABLE :: xpresf  ( : , : , : )  ! total air pressure at face

END MODULE xvars