module vector_vector_real_mod
  use iso_fortran_env, only: real64
  use vector_real_mod
#include "type_list.macro"
#define TYPE_ID VECTOR_REAL_ID
#include "type_attributes.macro"
#include "vector_template.F90"
end module
