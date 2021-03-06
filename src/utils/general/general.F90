module general_utils
  use general_integer_mod
  use general_real_mod
  use general_real_array_mod
  use general_char_str_mod
  use iso_fortran_env, only: real64
  implicit none

  interface arg_or_default
    module procedure :: arg_or_default_integer, arg_or_default_real, arg_or_default_real_array, arg_or_default_char_str
  end interface

  interface iff
    module procedure :: iff_integer, iff_real, iff_real_array, iff_char_str
  end interface

  interface swap
    module procedure :: swap_integer, swap_real, swap_char_str
  end interface

  interface num2str
    module procedure :: num2str_integer, num2str_real
  end interface

  interface operator (.means.)
    module procedure :: logical_consequence
  end interface

  interface operator (.aeq.)
    module procedure :: approximately_equal
  end interface

  interface operator (.ale.)
    module procedure :: approximately_less_equal
  end interface

  interface operator (.age.)
    module procedure :: approximately_greater_equal
  end interface

contains

!-------------------------------------------------------------------------------------------------------------------------------------------
! Converts real to integer, rounding up if within target accuracy of the next integer, otherwise down.
!-------------------------------------------------------------------------------------------------------------------------------------------
  function real2int(a, comp_precision) result(res)
    real(real64), intent(in) :: a
    real(real64), optional, intent(in) :: comp_precision
    integer :: res
    real(real64) :: precision_act

    precision_act = arg_or_default(comp_precision, 1d-10)
    if (ceiling(a) - a < precision_act) then
      res = ceiling(a)
    else
      res = int(a)
    end if
  end function

!-------------------------------------------------------------------------------------------------------------------------------------------
! Generates real grid using specified step.
!-------------------------------------------------------------------------------------------------------------------------------------------
  function generate_real_range(start, end, step) result(grid)
    real(real64), intent(in) :: start, end, step
    real(real64), allocatable :: grid(:)
    real(real64) :: npointsf
    integer :: npoints, i

    npointsf = (end - start) / step
    npoints = int(npointsf)
    ! If the last step is complete up to comparison accuracy
    if ((npointsf - npoints) .aeq. 1d0) then
      npoints = npoints + 1
    end if

    ! +1 because of an extra point at the beginning of interval
    allocate(grid(npoints + 1))
    grid = [(start + i * step, i = 0, npoints)]
  end function

!-------------------------------------------------------------------------------------------------------------------------------------------
! Generates equally spaced grid of points in the interval [start, end].
!-------------------------------------------------------------------------------------------------------------------------------------------
  function linspace(start, end, npoints) result(grid)
    real(real64), intent(in) :: start, end
    integer, intent(in) :: npoints
    real(real64) :: grid(npoints)
    integer :: i
    real(real64) :: step

    step = (end - start) / (npoints - 1)
    grid = [(start + i * step, i = 0, npoints - 1)]
  end function

!---------------------------------------------------------------------------------------------------------------------------------------------
! Prints progress %.
! progress: current progress of some process (a number from 0 to 1).
! progress_step: controls how often progress should be reported (default is every 10%).
!---------------------------------------------------------------------------------------------------------------------------------------------
  subroutine track_progress(progress, progress_step, reset)
    real(real64), intent(in) :: progress
    real(real64), optional, intent(in) :: progress_step
    integer, optional, intent(in) :: reset
    character, parameter :: carriage_return = achar(13)
    real(real64), save :: last_progress = 0
    real(real64) :: progress_step_act

    if (present(reset)) then
      if (reset == 1) then
        last_progress = 0
      end if
    end if

    progress_step_act = iff(present(progress_step), progress_step, 0.1d0)
    if (progress .age. (last_progress + progress_step_act)) then
      last_progress = real2int(progress / progress_step_act) * progress_step_act
      write(*, '(A,1x,F6.2,A)', advance = 'no') carriage_return, last_progress * 100, '% done'
      if (last_progress .aeq. 1d0) then
        print *
      end if
    end if
  end subroutine

!-------------------------------------------------------------------------------------------------------------------------------------------
! Prints stack trace and aborts the program.
!-------------------------------------------------------------------------------------------------------------------------------------------
  subroutine exit_abnormally()
    integer :: zero = 0
    print *, 1 / zero ! This is the only portable way to print stack trace that I'm aware of...
  end subroutine

!-------------------------------------------------------------------------------------------------------------------------------------------
! A one-liner to check various constraints.
!-------------------------------------------------------------------------------------------------------------------------------------------
  subroutine assert(logical_statemenet, error_message)
    logical, intent(in) :: logical_statemenet
    character(*), optional, intent(in) :: error_message

    if (.not. logical_statemenet) then
      if (present(error_message)) then
        print *, error_message
      else
        print *, 'Assertion error'
      end if
      call exit_abnormally()
    end if
  end subroutine

!-------------------------------------------------------------------------------------------------------------------------------------------
! Checks if a given strings starts with a given pattern.
!-------------------------------------------------------------------------------------------------------------------------------------------
  function str_starts_with(str, pattern) result(res)
    character(*), intent(in) :: str, pattern
    logical :: res
    res = str(1:len(pattern)) == pattern
  end function

!-------------------------------------------------------------------------------------------------------------------------------------------
! Removes characters in *char_set* from the right end of *str* until first occurence of a character not from *char_set*.
!-------------------------------------------------------------------------------------------------------------------------------------------
  function str_trim(str, char_set) result(res)
    character(*), intent(in) :: str
    character(*), optional, intent(in) :: char_set
    character(:), allocatable :: res
    integer :: pos
    character(:), allocatable :: char_set_act

    char_set_act = arg_or_default(char_set, ' ')
    pos = verify(str, char_set_act, .true.)
    res = str(1:pos)
  end function

!-------------------------------------------------------------------------------------------------------------------------------------------
! Returns identity matrix of specified size.
!-------------------------------------------------------------------------------------------------------------------------------------------
  function identity_matrix(size) result(matrix)
    integer, intent(in) :: size
    integer, allocatable :: matrix(:, :)
    integer :: i

    allocate(matrix(size, size))
    matrix = 0
    do i = 1, size
      matrix(i, i) = 1
    end do
  end function

!-------------------------------------------------------------------------------------------------------------------------------------------
! Compares leading digits of given integers.
!-------------------------------------------------------------------------------------------------------------------------------------------
  function compare_leading_digits(int1, int2) result(res)
    integer, intent(in) :: int1, int2
    logical :: res
    character(:), allocatable :: int1_str, int2_str

    int1_str = num2str(int1)
    int2_str = num2str(int2)
    res = str_starts_with(int1_str, int2_str)
  end function

!-------------------------------------------------------------------------------------------------------------------------------------------
! Evaluates logical consequence function.
!-------------------------------------------------------------------------------------------------------------------------------------------
  function logical_consequence(a, b) result(res)
    logical, intent(in) :: a, b
    logical :: res
    res = .not. (a .and. .not. b)
  end function

!-------------------------------------------------------------------------------------------------------------------------------------------
! Evaluates delta Kronecker function.
!-------------------------------------------------------------------------------------------------------------------------------------------
  function delta(a, b) result(res)
    integer, intent(in) :: a, b
    integer :: res
    res = merge(1, 0, a == b)
  end function

!-------------------------------------------------------------------------------------------------------------------------------------------
! Find *row* and *col* index of maximum element in the *matrix*.
!-------------------------------------------------------------------------------------------------------------------------------------------
  subroutine find_max_loc_matrix(matrix, row, col)
    real(real64), intent(in) :: matrix(:, :)
    integer, intent(out) :: row, col
    integer, allocatable :: max_loc_col(:) ! row of maximum in each column
    real(real64), allocatable :: max_val_col(:) ! value of maximum in each column

    max_loc_col = maxloc(matrix, 2)
    max_val_col = maxval(matrix, 2)
    col = maxloc(max_val_col, 1)
    row = max_loc_col(col)
  end subroutine

end module
