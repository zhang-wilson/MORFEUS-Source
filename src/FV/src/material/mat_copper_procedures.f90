!
!     (c) 2019 Guide Star Engineering, LLC
!     This Software was developed for the US Nuclear Regulatory Commission (US NRC)
!     under contract "Multi-Dimensional Physics Implementation into Fuel Analysis under
!     Steady-state and Transients (FAST)", contract # NRC-HQ-60-17-C-0007
!
!
!    NEMO - Numerical Engine (for) Multiphysics Operators
! Copyright (c) 2007, Stefano Toninel
!                     Gian Marco Bianchi  University of Bologna
!              David P. Schmidt    University of Massachusetts - Amherst
!              Salvatore Filippone University of Rome Tor Vergata
! All rights reserved.
!
! Redistribution and use in source and binary forms, with or without modification,
! are permitted provided that the following conditions are met:
!
!     1. Redistributions of source code must retain the above copyright notice,
!        this list of conditions and the following disclaimer.
!     2. Redistributions in binary form must reproduce the above copyright notice,
!        this list of conditions and the following disclaimer in the documentation
!        and/or other materials provided with the distribution.
!     3. Neither the name of the NEMO project nor the names of its contributors
!        may be used to endorse or promote products derived from this software
!        without specific prior written permission.
!
! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
! ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
! WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
! DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
! ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
! (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
! LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
! ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
! (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
! SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
!
!---------------------------------------------------------------------------------
!
! $Id: mat_copper.f90 3093 2008-04-22 14:51:09Z sfilippo $
!
! Description:
!    Physical properties of copper and its alloys
!
SUBMODULE(mat_copper) mat_copper_procedures

    USE class_psblas

    IMPLICIT NONE

CONTAINS

    MODULE PROCEDURE load_copper
        INTEGER :: info

        ! Data source: Mills, A. F. - "Basic Heat and Mass Transfer"

        ! Material physical state
        state = 's'

        dtemp = 100.d0  ! Temperature delta [K]
        tmin  = 200.d0  ! Temperature minimum [K]
        tmax  = 1100.d0 ! Temperature maximum [K]

        ALLOCATE(rho(1),lambda(10),sh(1),stat=info)
        IF(info /= 0) THEN
            WRITE(*,100)
            CALL abort_psblas
        END IF

        rho(1) = 8933.d0
        lambda = (/ 413.d0, 401.d0, 393.d0, 386.d0, 379.d0, &
            &        373.d0, 366.d0, 359.d0, 352.d0, 346.d0 /)
        sh(1)  = 385.d0

100     FORMAT(' ERROR! Memory allocation failure in LOAD_COPPER')

    END PROCEDURE load_copper

END SUBMODULE mat_copper_procedures
