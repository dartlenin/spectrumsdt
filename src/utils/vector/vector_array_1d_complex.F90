module vector_array_1d_complex_mod
  use array_1d_complex_mod
  use iso_fortran_env, only: real64
#include "type_list.macro"
#define TYPE_ID ARRAY_1D_COMPLEX_ID
#include "type_attributes.macro"
#include "vector_array_1d_template.F90"
end module
