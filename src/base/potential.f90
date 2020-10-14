!-------------------------------------------------------------------------------------------------------------------------------------------
! Procedures related to potential
!-------------------------------------------------------------------------------------------------------------------------------------------
module potential_mod
  use formulas_mod
  use input_params_mod
  use iso_fortran_env, only: real64
  use general_vars
  use spectrumsdt_paths_mod
  implicit none

  ! Potentials on 3D grid
  real(real64), allocatable :: pottot(:, :, :)

contains
  
  !-----------------------------------------------------------------------
  !  Calculates rotational potential in symmetric top approximation.
  !-----------------------------------------------------------------------
  function calc_rotational_potential(rho, theta, J, K) result(res)
    real(real64), intent(in) :: rho, theta
    integer, intent(in) :: J, K
    real(real64) :: res
    real(real64) :: a, b, c

    a = get_rotational_a(mu, rho, theta)
    b = get_rotational_b(mu, rho, theta)
    c = get_rotational_c(mu, rho, theta)
    res = (a + b)/2 * J*(J + 1) + (c - (a + b)/2) * K**2
  end function

  !-----------------------------------------------------------------------
  !  Calculates extra potential term at a given point.
  !-----------------------------------------------------------------------
  function calc_extra_potential(rho, theta) result(res)
    real(real64), intent(in) :: rho, theta
    real(real64) :: res
    res = -(0.25d0 + 4/(sin(2*theta)**2)) / (2*mu*rho**2)
  end function

!-----------------------------------------------------------------------
! Initializes total potential. Grids have to be initialized first.
!-----------------------------------------------------------------------
  subroutine init_potential(params)
    class(input_params), intent(in) :: params
    integer :: file_unit, iostat, i1, i2, i3

    ! Load vibrational potential
    allocate(pottot(n3, n2, n1))
    open(newunit = file_unit, file = get_pes_path(params))
    read(file_unit, *, iostat = iostat) pottot
    close(file_unit)
    call assert(.not. is_iostat_end(iostat), 'Error: size of pes.out is not sufficient for the specified grids')

    ! Add rotational and extra potentials
    do i1 = 1, n1
      do i2 = 1, n2
        do i3 = 1, n3
          pottot(i3, i2, i1) = pottot(i3, i2, i1) + calc_rotational_potential(g1(i1), g2(i2), params % J, params % K(1)) + calc_extra_potential(g1(i1), g2(i2))
        end do
      end do
    end do
  end subroutine

end module