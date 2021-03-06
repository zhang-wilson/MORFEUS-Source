!
!     (c) 2019-2020 Guide Star Engineering, LLC
!     This Software was developed for the US Nuclear Regulatory Commission (US NRC) under contract
!     "Multi-Dimensional Physics Implementation into Fuel Analysis under Steady-state and Transients (FAST)",
!     contract # NRC-HQ-60-17-C-0007
!
module structured_grid_interface
  !! author: Damian Rouson
  !! date: 9/9/2019
  !!
  !! Hexahedral, structured-grid block encapsulating nodal data and deferring coordinate-specific procedures to child classes
  use block_metadata_interface, only : block_metadata
  use grid_interface, only : grid
  use kind_parameters, only : r8k
  use differentiable_field_interface, only : differentiable_field
  use geometry_interface, only : geometry
  use surfaces_interface, only : surfaces
  implicit none

  private
  public :: structured_grid

  integer, parameter :: num_bounds=2, max_space_dims=3, undefined=-1

  type, extends(grid), abstract :: structured_grid
    !! Morfeus structured grid class
    private
    real(r8k), allocatable :: nodal_values(:,:,:,:,:,:)
      !! 3 dims for indexing through 3D space
      !! 2 dims for tensor free indices to handle scalars, vectors, & dyads
      !! 1 dim for instances in time
    integer :: global_bounds(num_bounds,max_space_dims) = undefined
    integer :: block_id = undefined
    integer :: scalar_id = undefined
    type(block_metadata) metadata
  contains
    procedure(set_up_div_scalar_flux_interface), deferred :: set_up_div_scalar_flux
    procedure(div_scalar_flux_interface), deferred :: div_scalar_flux
    procedure(block_indices_interface), deferred :: block_indicial_coordinates
    procedure(block_identifier_interface), deferred :: block_identifier
    procedure(build_surfaces_interface), deferred :: build_surfaces
    procedure(block_id_in_bounds_interface), deferred :: block_identifier_in_bounds
    procedure(block_ijk_in_bounds_interface), deferred :: block_coordinates_in_bounds
    generic :: block_in_bounds => block_identifier_in_bounds, block_coordinates_in_bounds
    procedure :: set_global_block_shape
    procedure :: get_global_block_shape
    procedure :: clone
    procedure :: diffusion_coefficient
    procedure :: write_formatted
    procedure :: space_dimension
    procedure :: free_tensor_indices
    procedure :: num_cells
    procedure :: num_time_stamps
    procedure :: vectors
    procedure :: get_scalar
    procedure :: set_metadata
    procedure :: get_tag
    procedure :: set_vector_components
    procedure :: set_scalar
    procedure :: increment_scalar
    procedure :: subtract
#ifndef FORD
    generic :: operator(-) => subtract
#endif
    procedure :: compare
#ifdef HAVE_UDDTIO
    generic :: write(formatted) => write_formatted
#endif
    procedure set_block_identifier
    procedure get_block_identifier
    procedure set_scalar_identifier
    procedure get_scalar_identifier
  end type

  abstract interface

    subroutine set_up_div_scalar_flux_interface(this, vertices, block_surfaces, div_flux_internal_points)
      import structured_grid, differentiable_field, surfaces
      implicit none
      class(structured_grid), intent(in) :: this
      class(structured_grid), intent(in) :: vertices
      type(surfaces), intent(inout) :: block_surfaces
      class(structured_grid), intent(inout) :: div_flux_internal_points
    end subroutine

    pure subroutine div_scalar_flux_interface(this, vertices, block_surfaces, div_flux)
      import structured_grid, differentiable_field, surfaces
      implicit none
      class(structured_grid), intent(in) :: this
      class(structured_grid), intent(in) :: vertices
      type(surfaces), intent(in) :: block_surfaces
      class(structured_grid), intent(inout) :: div_flux
    end subroutine

    pure function block_indices_interface(this,n) result(ijk)
      !! calculate the 3D location of the block that has the provided 1D block identifier
      import structured_grid
      implicit none
      class(structured_grid), intent(in) :: this
      integer, intent(in) :: n
      integer, dimension(:), allocatable :: ijk
    end function

    pure function block_identifier_interface(this, ijk) result(n)
      !! calculate the 1D block identifier associated with the provided 3D block location
      import structured_grid
      implicit none
      class(structured_grid), intent(in) :: this
      integer, intent(in), dimension(:) :: ijk
      integer :: n
    end function

    subroutine build_surfaces_interface(this, problem_geometry, vertices, block_faces, block_partitions, num_scalars)
      !! allocate coarray for communicating across structured_grid blocks
      import structured_grid, geometry, surfaces
      class(structured_grid), intent(in) :: this
      class(geometry), intent(in) :: problem_geometry
      class(structured_grid), intent(in), dimension(:), allocatable :: vertices
      type(surfaces), intent(inout) :: block_faces
      integer, intent(in), dimension(:) :: block_partitions
      integer, intent(in) :: num_scalars
    end subroutine

    pure function block_id_in_bounds_interface(this, id) result(in_bounds)
      !! verify block identifier
      import structured_grid
      implicit none
      class(structured_grid), intent(in) :: this
      integer, intent(in) :: id
      logical in_bounds
    end function

    pure function block_ijk_in_bounds_interface(this, ijk) result(in_bounds)
      !! verify block indicial coordinates
      import structured_grid
      implicit none
      class(structured_grid), intent(in) :: this
      integer, intent(in), dimension(:) :: ijk
      logical in_bounds
    end function

  end interface

  interface

    module subroutine set_global_block_shape(this, shape_array)
      implicit none
      class(structured_grid), intent(inout) :: this
      integer, dimension(:), intent(in) :: shape_array
    end subroutine

    pure module function get_global_block_shape(this) result(shape_array)
      implicit none
      class(structured_grid), intent(in) :: this
      integer, dimension(:), allocatable :: shape_array
    end function

    pure module subroutine clone(this,original)
      implicit none
      class(structured_grid), intent(inout) :: this
      class(structured_grid), intent(in) :: original
    end subroutine

    pure module function diffusion_coefficient(this, temperature) result(coefficient)
      implicit none
      class(structured_grid), intent(in) :: this
      real(r8k), intent(in) :: temperature
      real(r8k) coefficient
    end function

    module subroutine write_formatted (this,unit,iotype, v_list, iostat, iomsg)
      implicit none
      class(structured_grid), intent(in) ::this
      integer, intent(in) :: unit, v_list(:)
      character (len=*), intent(in) :: iotype
      integer, intent(out) :: iostat
      character(len=*), intent(inout) :: iomsg
    end subroutine

    pure module function space_dimension(this) result(num_dimensions)
      !! result is the number of independent spatial dimensions in the structured grid (e.g., 2 for axisymmetric grid)
      implicit none
      class(structured_grid), intent(in) :: this
      integer :: num_dimensions
    end function

    pure module function free_tensor_indices(this) result(num_free_indices)
      !! result is number of free tensor indices for quantity stored on a structured grid (e.g., 3 for vector quantity)
      implicit none
      class(structured_grid), intent(in) :: this
      integer num_free_indices
    end function

    pure module function num_time_stamps(this) result(num_times)
      !! result is number of instances of time stored for a given quantity on a structured grid
      implicit none
      class(structured_grid), intent(in) :: this
      integer :: num_times
    end function

    elemental module function num_cells(this) result(cell_count)
      !! result is number of 3D grid points stored for a given quantity on a structured grid
      implicit none
      class(structured_grid), intent(in) :: this
      integer  :: cell_count
    end function

    pure module function vectors(this) result(vectors3D)
      !! result is an array of 3D vectors
      implicit none
      class(structured_grid), intent(in) :: this
      real(r8k), dimension(:,:,:,:), allocatable :: vectors3D
    end function

    pure module function get_scalar(this) result(scalar_values)
      !! result is an array of scalar values at grid vertices
      implicit none
      class(structured_grid), intent(in) :: this
      real(r8k), dimension(:,:,:), allocatable :: scalar_values
    end function

    pure module subroutine set_metadata(this,metadata)
      implicit none
      class(structured_grid), intent(inout) :: this
      type(block_metadata), intent(in) :: metadata
    end subroutine

    pure module function get_tag(this) result(this_tag)
      use block_metadata_interface, only : tag_kind
      implicit none
      class(structured_grid), intent(in) :: this
      integer(tag_kind) this_tag
    end function

    pure module subroutine set_vector_components(this,x_nodes,y_nodes,z_nodes)
      !! set this%nodal_values to provided vector field components
      implicit none
      class(structured_grid), intent(inout) :: this
      real(r8k), intent(in), dimension(:,:,:) :: x_nodes, y_nodes, z_nodes
    end subroutine

    pure module subroutine set_scalar(this, scalar)
      !! set this%nodal_values to the provided array
      implicit none
      class(structured_grid), intent(inout) :: this
      real(r8k), intent(in), dimension(:,:,:) :: scalar
    end subroutine

    pure module subroutine increment_scalar(this, scalar)
      !! increment this%nodal_values by the provided array
      implicit none
      class(structured_grid), intent(inout) :: this
      real(r8k), intent(in), dimension(:,:,:) :: scalar
    end subroutine

    module function subtract(this, rhs) result(difference)
      !! result contains the difference between this and rhs nodal_values components
      implicit none
      class(structured_grid), intent(in) :: this, rhs
      class(structured_grid), allocatable :: difference
    end function

    pure module subroutine compare(this, reference, tolerance)
      !! verify
      implicit none
      class(structured_grid), intent(in) :: this, reference
      real(r8k), intent(in) :: tolerance
    end subroutine

    module subroutine set_block_identifier(this, id)
      !! set block identification tag
      implicit none
      class(structured_grid), intent(inout) :: this
      integer, intent(in) :: id
    end subroutine

    pure module function get_block_identifier(this) result(this_block_id)
      !! result is the block identification tag
      class(structured_grid), intent(in) :: this
      integer this_block_id
    end function

    module subroutine set_scalar_identifier(this, id)
      !! set block identification tag
      implicit none
      class(structured_grid), intent(inout) :: this
      integer, intent(in) :: id
    end subroutine

    pure module function get_scalar_identifier(this) result(this_scalar_id)
      !! result is the block identification tag
      class(structured_grid), intent(in) :: this
      integer this_scalar_id
    end function

  end interface

end module
