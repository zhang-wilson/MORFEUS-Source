!
!     (c) 2019-2020 Guide Star Engineering, LLC
!     This Software was developed for the US Nuclear Regulatory Commission (US NRC) under contract
!     "Multi-Dimensional Physics Implementation into Fuel Analysis under Steady-state and Transients (FAST)",
!     contract # NRC-HQ-60-17-C-0007
!
module surfaces_interface
  !! author: Damian Rouson
  !! date: 12/26/2019
  !!
  !! Encapsulate block boundary data for structured_grid halo exchanges
  use package_interface, only : package
  use kind_parameters, only : r8k
  use iso_c_binding, only : enumeration=>c_int
  implicit none

  private
  public :: surfaces, enumeration, face_normal, backward, forward

  enum, bind(C)
    enumerator :: backward=1, forward
  end enum

  integer(enumeration), parameter, dimension(*) :: face_normal = [backward, forward]
    !! surface outward-normal direction: 'forward' for the direction of increasing coordinate; 'backward' for decreasing

  type surfaces
    !! hexahedral structured_grid block surface data
    private
    class(package), allocatable, dimension(:,:,:) :: halo_outbox
      !! allocate to dimensions [my_blocks(first):my_blocks(last), space_dimension, size([forward, backward]))
      !! An appparent GCC 8 compiler bug necessitates the polymorphic (class) declaration.
  contains
    procedure, nopass :: is_external_boundary
    procedure, nopass :: set_halo_outbox
    procedure, nopass :: get_halo_outbox
    procedure, nopass :: set_normal_scalar_fluxes
    procedure, nopass :: get_block_image
    procedure, nopass :: set_num_scalars
  end type

  interface

    elemental module function is_external_boundary(block_id, coordinate_direction, face) result(is_external)
      !! result is .true. if the identified structured_grid block surface corresponds to a problem domain boundary
      implicit none
      integer, intent(in) :: block_id, coordinate_direction
      integer(enumeration), intent(in) :: face
      logical is_external
    end function

    module subroutine set_halo_outbox(my_halo_outbox, block_partitions)
      !! define halo_outbox component array
      implicit none
      type(package), intent(in), dimension(:,:,:), allocatable :: my_halo_outbox
      integer, intent(in), dimension(:) :: block_partitions
    end subroutine

    module subroutine get_halo_outbox(singleton_halo_outbox)
      !! output singleton_halo_outbox with the following bounds:
      !! lbounds=[my_blocks(first), 1, backward], ubounds=[my_blocks(last), space_dimension, forward]
      !! This cannot be a function because the function result would not preserve the desired bounds.
      implicit none
      type(package), dimension(:,:,:), allocatable, intent(out) :: singleton_halo_outbox
    end subroutine

    module subroutine set_normal_scalar_fluxes( block_id, coordinate_direction, face, s_flux_normal, scalar_id)
      !! define halo outbox for a specific surface
      implicit none
      integer, intent(in) :: block_id, coordinate_direction, scalar_id
      integer(enumeration), intent(in) :: face
      real(r8k), allocatable, intent(in), dimension(:,:,:) :: s_flux_normal
        !! surface-normal scalar flux components: shape = [Nx, Ny, Nz], where one of Nx|Ny|Nz is 1
    end subroutine

    pure module function get_block_image(block_id) result(image)
      !! result is the image that owns the given structured_grid block
      integer, intent(in) :: block_id
      integer image
    end function

    module subroutine set_num_scalars(num_scalars)
      !! allocate surface-normal scalar flux array
      implicit none
      integer, intent(in) :: num_scalars
    end subroutine

  end interface

end module