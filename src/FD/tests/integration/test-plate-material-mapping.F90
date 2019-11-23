!
!     (c) 2019 Guide Star Engineering, LLC
!     This Software was developed for the US Nuclear Regulatory Commission (US NRC)
!     under contract "Multi-Dimensional Physics Implementation into Fuel Analysis under
!     Steady-state and Transients (FAST)", contract # NRC-HQ-60-17-C-0007
!
program main
  !! author: Damian Rouson and Karla Morris
  !! date: 9/9/2019
  !! Test the initialization of a problem_discretization from json_file input

  use assertions_interface, only : assert
  use string_functions_interface, only : csv_format
  use plate_3D_interface, only : plate_3D
  use problem_discretization_interface, only : problem_discretization
  use block_metadata_interface, only : block_metadata, max_name_length
  implicit none

  type(plate_3D) plate_geometry
  type(problem_discretization) global_grid
  integer file_unit, open_status
  integer, parameter :: success=0
  character(len=*), parameter :: output_file="3Dplate-low-resolution-layers-material-map.vtk"
  character(len=*), parameter :: input_file="3Dplate-low-resolution-layers-material-map.json"

  call plate_geometry%build( input_file )
  call global_grid%initialize_from_geometry( plate_geometry ) !! partition block-structured grid & define grid vertex locations

  open(newunit=file_unit, file=output_file, iostat=open_status)
  call assert(open_status==success, output_file//" opened succesfully")

  check_metadata: block
    character(len=max_name_length), allocatable :: map(:,:,:)
    type(block_metadata), dimension(:,:,:), allocatable :: metadata
    character(len=33) ixyz
    integer ix, iy, iz

    map = expected_map()
    metadata = plate_geometry%get_block_metadata()
    call assert( all(shape(metadata)==shape(map)), "all(shape(metadata)==shape(map))" )

    do iz=1,size(map,3)
      do iy=1,size(map,2)
        do ix=1,size(map,1)
          write(ixyz,csv_format) ix, iy, iz
          call assert( metadata(ix,iy,iz)%get_label()==map(ix,iy,iz), "metadata(ix,iy,iz)%get_label()==map(ix,iy,iz) ", trim(ixyz) )
        end do
      end do
    end do
  end block check_metadata

  call output_grid( global_grid, file_unit )

  print *,"Test passed."

contains

  subroutine output_grid( mesh, file_unit )
    type(problem_discretization) :: mesh
    integer file_unit

#ifdef HAVE_UDDTIO
    write(file_unit,*) mesh
#else
    block
      integer, dimension(0) :: v_list
      character(len=132) io_message
      integer io_status
      call mesh%write_formatted (file_unit, 'DT', v_list, io_status, io_message)
    end block
#endif
  end subroutine

  function expected_map() result(material_map)
    character(len=max_name_length), allocatable :: material_map(:,:,:)
    character(len=*), parameter :: lower_z(13,14,1)= reshape( [ character(len=max_name_length) :: &
      "bag","bag","bag","bag","bag","bag ","bag    ","bag ","bag","bag","bag","bag","bag",&
      "bag","bag","bag","air","air","air ","air    ","air ","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","air ","air    ","air ","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil   ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil   ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil   ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","burrito","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","burrito","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil   ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil   ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil   ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","air ","air    ","air ","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","air ","air    ","air ","air","air","bag","bag","bag",&
      "bag","bag","bag","bag","bag","bag ","bag    ","bag ","bag","bag","bag","bag","bag" &
      ], [13,14,1] )
    character(len=*), parameter :: upper_z(13,14,1)= reshape( [ character(len=max_name_length) :: &
      "bag","bag","bag","bag","bag","bag ","bag   ","bag ","bag","bag","bag","bag","bag",&
      "bag","bag","bag","air","air","air ","air   ","air ","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","air ","air   ","air ","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil  ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil  ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil  ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","cavity","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","cavity","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil  ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil  ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","foil","foil  ","foil","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","air ","air   ","air ","air","air","bag","bag","bag",&
      "bag","bag","bag","air","air","air ","air   ","air ","air","air","bag","bag","bag",&
      "bag","bag","bag","bag","bag","bag ","bag   ","bag ","bag","bag","bag","bag","bag" &
      ], [13,14,1] )
    allocate( character(len=len(lower_z)) :: material_map(size(lower_z,1), size(lower_z,2), size(lower_z,3)+size(upper_z,3)) )
    material_map(:,:,1) = lower_z(:,:,1)
    material_map(:,:,2) = upper_z(:,:,1)
  end function

end program