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
! $Id: vector_pde_ddt.f90 8157 2014-10-09 13:02:44Z sfilippo $
!
! Description:
!    Adds to PDE the contribution of the time derivative of FLD * PHI.
!    Remark: FLD is optional.
!
SUBMODULE (op_ddt) vector_pde_ddt_implementation
    IMPLICIT NONE

    CONTAINS

    MODULE PROCEDURE vector_pde_ddt
    USE class_psblas
    USE class_dimensions
    USE class_mesh
    USE class_scalar_field
    USE class_vector_field
    USE class_vector_pde
    USE class_vector
    USE tools_operators

    IMPLICIT NONE
    !
    CHARACTER(len=20) :: op_name = 'VECTOR_PDE_DDT'
    INTEGER :: i, ic, ic_glob, ifirst, info, ncells, nel, nmax
    INTEGER, ALLOCATABLE :: ia(:), ja(:)
    INTEGER, ALLOCATABLE :: iloc_to_glob(:)
    REAL(psb_dpk_), ALLOCATABLE :: A(:)
    REAL(psb_dpk_), ALLOCATABLE :: fld_x_old(:)
    REAL(psb_dpk_) :: dtinv, fact, fsign, side_
    TYPE(dimensions) :: dim
    TYPE(mesh), POINTER :: msh => NULL()
    TYPE(mesh), POINTER :: msh_phi => NULL(), msh_fld => NULL()
    TYPE(vector), ALLOCATABLE :: phi_x_old(:), b(:)


    CALL sw_pde%tic()

    IF(mypnum_() == 0) THEN
        WRITE(*,*) '* ', TRIM(pde%name_()), ': applying the Time Derivative ',&
            & ' operator to the ', TRIM(phi%name_()), ' field'
    END IF

    ! Possible reinit of PDE
    CALL pde%reinit_pde()

    ! Is PHI cell-centered?
    IF(phi%on_faces_()) THEN
        WRITE(*,100) TRIM(op_name)
        CALL abort_psblas
    END IF

    ! Is FLD cell-centered?
    IF(PRESENT(fld)) THEN
        IF(fld%on_faces_()) THEN
            WRITE(*,100) TRIM(op_name)
            CALL abort_psblas
        END IF
    END IF

    ! Checks mesh consistency PDE vs. PHI
    CALL pde%get_mesh(msh)
    CALL phi%get_mesh(msh_phi)
    CALL check_mesh_consistency(msh,msh_phi,TRIM(op_name))

    ! Checks mesh consistency PHI vs. FLD
    IF(PRESENT(fld)) THEN
        CALL fld%get_mesh(msh_fld)
        CALL check_mesh_consistency(msh_phi,msh_fld,TRIM(op_name))
    END IF

    NULLIFY(msh_fld)
    NULLIFY(msh_phi)

    ! Equation dimensional check
    dim = phi%dim_() * volume_ / time_
    IF(PRESENT(fld)) dim = fld%dim_() * dim
    IF(dim /= pde%dim_()) THEN
        WRITE(*,200) TRIM(op_name)
        CALL abort_psblas
    END IF

    ! Computes sign factor
    IF(PRESENT(side)) THEN
        side_ = side
    ELSE
        side_ = lhs_ ! Default = LHS
    END IF
    fsign = pde_sign(sign,side_)


    ! Gets PHI "x" internal values
    CALL phi%get_x(phi_x_old)

    ! Gets FLD "x" internal values
    IF(PRESENT(fld)) THEN
        CALL fld%get_x(fld_x_old)
    ELSE
        ncells = SIZE(phi_x_old)
        ALLOCATE(fld_x_old(ncells),stat=info)
        IF(info /= 0) THEN
            WRITE(*,300) TRIM(op_name)
            CALL abort_psblas
        END IF
        fld_x_old(:) = 1.d0
    END IF

    ! Number of strictly local cells
    ncells = psb_cd_get_local_rows(msh%desc_c)

    ! Gets local to global list for cell indices
    CALL psb_get_loc_to_glob(msh%desc_c,iloc_to_glob)

    ! Computes maximum size of blocks to be inserted
    nmax = size_blk(1,ncells)

    ! Checks timestep size
    IF(dt <= 0.d0) THEN
        WRITE(*,400)
        CALL abort_psblas
    END IF

    dtinv = 1.d0 / dt

    ALLOCATE(A(nmax),b(nmax),ia(nmax),ja(nmax),stat=info)
    IF(info /= 0 ) THEN
        WRITE(*,300)
        CALL abort_psblas
    END IF

    ifirst = 1; ic = 0
    insert: DO
        IF(ifirst > ncells) EXIT insert
        nel = size_blk(ifirst,ncells)

        BLOCK: DO i = 1, nel
            ! Local indices
            ic = ic + 1

            fact = fsign * msh%vol(ic) * dtinv * fld_x_old(ic)

            A(i) = fact
            b(i) = fact * phi_x_old(ic)

            ! Global indices in COO format
            ic_glob = iloc_to_glob(ic)
            ia(i)= ic_glob
            ja(i)= ic_glob
!!$        write(0,*) 'From vector_pde_ddt:  A',i,ic_glob,&
!!$             & a(i),dtinv, x_(b(i)),&
!!$             & y_(b(i)),z_(b(i))
        END DO BLOCK

        CALL pde%spins_pde(nel,ia,ja,A)
        CALL pde%geins_pde(nel,ia,b)
        IF (debug_mat_bld) THEN
            WRITE(0,*) 'From vector_pde_ddt : SPINS ',nel
            DO i=1,nel
                WRITE(0,*) ia(i),ja(i),a(i)
            END DO
            WRITE(0,*) 'From vector_pde_ddt : GEINS ',nel
            DO i=1,nel
                WRITE(0,*) ia(i),b(i)%x_(), b(i)%y_(),b(i)%z_()
            END DO
        ENDIF
        ifirst = ifirst +  nel

    END DO insert

    DEALLOCATE(A,b,ia,ja)
    DEALLOCATE(iloc_to_glob)

    DEALLOCATE(phi_x_old)
    DEALLOCATE(fld_x_old)
    NULLIFY(msh)

    CALL sw_pde%toc()

100 FORMAT(' ERROR! Operands in ',a,' are not cell centered')
200 FORMAT(' ERROR! Dimensional check failure in ',a)
300 FORMAT(' ERROR! Memory allocation failure in ',a)
400 FORMAT(' ERROR! Missing or illegal time advancing parameters')

    END PROCEDURE vector_pde_ddt

END SUBMODULE vector_pde_ddt_implementation
