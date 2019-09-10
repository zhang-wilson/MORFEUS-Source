!
!     (c) 2019 Guide Star Engineering, LLC
!     This Software was developed for the US Nuclear Regulatory Commission (US NRC)
!     under contract "Multi-Dimensional Physics Implementation into Fuel Analysis under
!     Steady-state and Transients (FAST)", contract # NRC-HQ-60-17-C-0007
!
module structured_grid_interface
  use block_metadata_interface, only : block_metadata
  use grid_interface, only : grid
  use Kinds, only : r8k
  implicit none

  private
  public :: structured_grid

  integer, parameter :: num_bounds=2, max_space_dims=3, undefined=-1

  type, extends(grid) :: structured_grid
    !! Morfeus structured grid class
    private
    real(r8k), allocatable :: nodal_values(:,:,:,:,:,:)
      !! 3 dims for indexing through 3D space
      !! 2 dims for tensor free indices to handle scalars, vectors, & dyads
      !! 1 dim for instances in time
    integer :: global_bounds(num_bounds,max_space_dims)=undefined
    type(block_metadata) metadata
  contains
    procedure num_cells
    procedure space_dimension
    procedure free_tensor_indices
    procedure num_time_stamps
    procedure set_metadata
    procedure get_tag
    procedure set_vector_components
    procedure vectors
    procedure write_formatted
#ifdef HAVE_UDDTIO
    generic :: write(formatted) => write_formatted
#endif
  end type

  real, allocatable :: vertices_inbox(:,:,:, :,:,:, :, :,:,:)[:]
    !! Communication buffer storing incoming planes of nodal_values from the neighboring halo image in each coordinate direction
    !! 6 dims corresponding to the nodal_values dimensions
    !! 1 dim for block identifier number; extent equals global maximum block_load (num_blocks/num_images+1)
    !! 3 dims for the direction of the block from which incoming data arrive; each with extent -h:h, h=halo halfwidth

    !! To avoid race conditions, each unique combination of block identifier and incoming directions denotes an array section
    !! that only one halo image accesses.  Assertions should be used to verify that each neighbor writes exclusively to its
    !! corresponding slice.

    !! For now, each type of data needs its own *_inbox coarray.  A proposed Fortran 202X feature will facilitate encapsulating
    !! the inbox coarray in the structured_grid derived type, which is currently precluded by the need to have allocatable arrays
    !! of structured_grid objects.

  interface

    module subroutine write_formatted (this,unit,iotype, v_list, iostat, iomsg)
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
      !! Set this structured_grid to a spatially constant value
      implicit none
      class(structured_grid), intent(inout) :: this
      real, intent(in), dimension(:,:,:) :: x_nodes, y_nodes, z_nodes
    end subroutine

  end interface

end module