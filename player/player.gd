extends CharacterBody3D

# --- CONFIGURACIÓN ---
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
const GRAVITY = 9.8

# --- REFERENCIAS (ACTUALIZADAS) ---
@onready var camera_fps = $CameraFPS      # Referencia a la cámara de primera persona
@onready var camera_tps = $SpringArm3D/CameraTPS # Referencia a la cámara de tercera persona
@onready var spring_arm = $SpringArm3D    # El brazo que sujeta la cámara TPS
@onready var model = $MeshInstance3D      # El modelo (la cápsula)

# --- VARIABLE DE ESTADO ---
var is_fps = true # Por defecto empezamos en primera persona

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Al arrancar, nos aseguramos de que la cámara FPS sea la activa
	actualizar_vistas()

func _input(event):
	# --- SALVAVIDAS: ESC para mostrar el mouse ---
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# --- NUEVO: CAMBIO DE VISTA (Tecla V) ---
	if event.is_action_pressed("change_view"):
		is_fps = !is_fps # Cambia el valor (si es true pasa a false y viceversa)
		actualizar_vistas()

	# --- ROTACIÓN CÁMARA (MODIFICADA) ---
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Girar el cuerpo siempre de izquierda a derecha
		rotate_y(-event.relative.x * SENSITIVITY)
		
		# Dependiendo de la vista, giramos verticalmente la cámara FPS o el brazo TPS
		if is_fps:
			camera_fps.rotate_x(-event.relative.y * SENSITIVITY)
			camera_fps.rotation.x = clamp(camera_fps.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		else:
			spring_arm.rotate_x(-event.relative.y * SENSITIVITY)
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-90), deg_to_rad(90))

# --- NUEVA FUNCIÓN: Lógica para cambiar cámaras y modelo ---
func actualizar_vistas():
	if is_fps:
		camera_fps.current = true
		model.visible = false # Ocultamos el cuerpo en FPS para que no estorbe la vista
	else:
		camera_tps.current = true
		model.visible = true  # Mostramos el cuerpo en TPS para vernos caminar

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += transform.basis.x

	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()

	velocity.x = input_dir.x * SPEED
	velocity.z = input_dir.z * SPEED

	move_and_slide()
