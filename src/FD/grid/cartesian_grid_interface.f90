!
!     (c) 2019 Guide Star Engineering, LLC
!     This Software was developed for the US Nuclear Regulatory Commission (US NRC)
!     under contract "Multi-Dimensional Physics Implementation into Fuel Analysis under
!     Steady-state and Transients (FAST)", contract # NRC-HQ-60-17-C-0007
!
module cartesian_grid_interface
  !! author: Damian Rouson and Karla Morris
  !! date: 9/9/2019
  !! subject: perform coordinate-specific tasks on cartesian structured_grid objects
  use structured_grid_interface, only : structured_grid
  use differentiable_field_interface, only : differentiable_field
  use geometry_interface, only : geometry
  implicit none

  private
  public :: cartesian_grid

  type, extends(structured_grid) :: cartesian_grid
  contains
    procedure div_scalar_flux
    procedure assign_structured_grid
    procedure block_indicial_coordinates
    procedure block_identifier
    procedure build_surfaces
  end type

  interface

    module subroutine build_surfaces(this, problem_geometry, my_blocks, space_dimension)
      !! allocate the surfaces array for use in halo exchanges and boundary conditions
      implicit none
      class(cartesian_grid), intent(in) :: this
      class(geometry), intent(in) :: problem_geometry
      integer, intent(in), dimension(:) :: my_blocks
      integer, intent(in) :: space_dimension
    end subroutine

    module function div_scalar_flux(this, vertices, exact_result) result(div_flux)
     !! compute the divergance of a gradient-diffusion scalar flux
     implicit none
     class(cartesian_grid), intent(in) :: this
     class(structured_grid), intent(in) :: vertices
     class(differentiable_field), intent(in), optional :: exact_result
     class(structured_grid), allocatable :: div_flux
    end function

    module subroutine assign_structured_grid(this, rhs)
     !! copy the rhs into this structured_grid
     implicit none
     class(cartesian_grid), intent(inout) :: this
     class(structured_grid), intent(in) :: rhs
    end subroutine

    pure module function block_indicial_coordinates(this,n) result(ijk)
      !! calculate the 3D location of the block that has the provided 1D block identifer
      implicit none
      class(cartesian_grid), intent(in) :: this
      integer, intent(in) :: n
      integer, dimension(:), allocatable :: ijk(:)
    end function

    pure module function block_identifier(this,ijk) result(n)
      !! calculate the 1D block identifer associated with the provided 3D block location
      implicit none
      class(cartesian_grid), intent(in) :: this
      integer, intent(in), dimension(:) :: ijk
      integer :: n
    end function

  end interface

end module
