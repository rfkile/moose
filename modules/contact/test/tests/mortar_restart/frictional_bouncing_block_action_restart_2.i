starting_point = 2e-1
offset = 1e-2

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Mesh]
  [file]
    type = FileMeshGenerator
    file = frictional_bouncing_block_action_restart_1_checkpoint_cp/0021-mesh.cpa.gz
    skip_partitioning = true
    allow_renumbering = false
  []
  uniform_refine = 0 # 1,2
  patch_update_strategy = always
[]

[Problem]
  #Note that the suffix is left off in the parameter below.
  restart_file_base = frictional_bouncing_block_action_restart_1_checkpoint_cp/LATEST # You may also use a specific number here
  kernel_coverage_check = false
  material_coverage_check = false
  # disp_y has an initial condition despite the checkpoint restart
  allow_initial_conditions_with_restart = true
[]

[Variables]
  [disp_x]
    block = '1 2'
  []
  [disp_y]
    block = '1 2'
  []
[]

[ICs]
  [disp_y]
    block = 2
    variable = disp_y
    value = '${fparse starting_point + offset}'
    type = ConstantIC
  []
[]

[Physics/SolidMechanics/QuasiStatic]
  [all]
    strain = FINITE
    generate_output = 'stress_xx stress_yy'
    block = '1 2'
  []
[]

[Materials]
  [elasticity_2]
    type = ComputeIsotropicElasticityTensor
    block = '2'
    youngs_modulus = 1e3
    poissons_ratio = 0.3
  []
  [elasticity_1]
    type = ComputeIsotropicElasticityTensor
    block = '1'
    youngs_modulus = 1e6
    poissons_ratio = 0.3
  []
  [stress]
    type = ComputeFiniteStrainElasticStress
    block = '1 2'
  []
[]

[Contact]
  [frictional]
    primary = 20
    secondary = 10
    formulation = mortar
    model = coulomb
    friction_coefficient = 0.4
    c_normal = 1.0e1
    c_tangential = 1.0e6
    generate_mortar_mesh = false
  []
[]

[BCs]
  [botx]
    type = DirichletBC
    variable = disp_x
    boundary = '40'
    value = 0.0
  []
  [boty]
    type = DirichletBC
    variable = disp_y
    boundary = '40'
    value = 0.0
  []
  [topy]
    type = ADFunctionDirichletBC
    variable = disp_y
    boundary = 30
    function = '${starting_point} * cos(2 * pi / 20 * t) + ${offset}'
    preset = false
  []
  [leftx]
    type = ADFunctionDirichletBC
    variable = disp_x
    boundary = 30
    function = '2e-2 * t'
    # function = '0'
    preset = false
  []
[]

[Executioner]
  type = Transient
  end_time = 6 # 70
  start_time = 5.25
  dt = 0.25 # 0.1 for finer meshes (uniform_refine)
  dtmin = .01
  solve_type = 'PJFNK'

  petsc_options = '-snes_converged_reason -ksp_converged_reason -pc_svd_monitor -snes_linesearch_monitor -snes_ksp_ew'
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type -pc_factor_shift_type -pc_factor_shift_amount -mat_mffd_err'
  petsc_options_value = 'lu       superlu_dist                  NONZERO               1e-13                   1e-5'
  l_max_its = 30
  nl_max_its = 40
  line_search = 'basic'
  snesmf_reuse_base = false
  nl_abs_tol = 1e-9
  nl_rel_tol = 1e-9
  l_tol = 1e-07 # Tightening l_tol can help with friction
[]

[Debug]
  show_var_residual_norms = true
[]

[VectorPostprocessors]
  [cont_press]
    type = NodalValueSampler
    variable = frictional_normal_lm
    boundary = '10'
    sort_by = x
    execute_on = FINAL
  []
  [friction]
    type = NodalValueSampler
    variable = frictional_tangential_lm
    boundary = '10'
    sort_by = x
    execute_on = FINAL
  []
[]

[Outputs]
  exodus = true
  [checkfile]
    type = CSV
    show = 'cont_press friction'
    start_time = 0.0
    execute_vector_postprocessors_on = FINAL
  []
[]

[Preconditioning]
  [smp]
    type = SMP
    full = true
  []
[]

[Postprocessors]
  active = 'num_nl cumulative_nli contact cumulative_li num_l'
  [num_nl]
    type = NumNonlinearIterations
  []
  [num_l]
    type = NumLinearIterations
  []
  [cumulative_nli]
    type = CumulativeValuePostprocessor
    postprocessor = num_nl
  []
  [cumulative_li]
    type = CumulativeValuePostprocessor
    postprocessor = num_l
  []
  [contact]
    type = ContactDOFSetSize
    variable = frictional_normal_lm
    subdomain = 'frictional_secondary_subdomain'
    execute_on = 'nonlinear timestep_end'
  []
[]
