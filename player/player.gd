extends CharacterBody3D

# --- CONFIGURACIÓN ---
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
const GRAVITY = 9.8

# --- REFERENCIAS ---
@onready var camera_fps = $CameraFPS
@onready var camera_tps = $SpringArm3D/CameraTPS
@onready var spring_arm = $SpringArm3D
@onready var model = $XBot
@onready var anim_tree = $AnimationTree
# Obtenemos el controlador de la máquina de estados
@onready var anim_state = anim_tree.get("parameters/playback")

# --- VARIABLE DE ESTADO ---
var is_fps = true # Por defecto empezamos en primera persona

func _ready():
	# Al iniciar, atrapamos el mouse y configuramos la vista inicial
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	actualizar_vistas()

func _input(event):
	# --- GESTIÓN DEL MOUSE ---
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# --- CAMBIO DE VISTA (Tecla V) ---
	if event.is_action_pressed("change_view"):
		is_fps = !is_fps
		actualizar_vistas()

	# --- ROTACIÓN DE CÁMARA ---
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Girar el cuerpo siempre de izquierda a derecha
		rotate_y(-event.relative.x * SENSITIVITY)
		
		# Rotación vertical según la cámara activa
		if is_fps:
			camera_fps.rotate_x(-event.relative.y * SENSITIVITY)
			camera_fps.rotation.x = clamp(camera_fps.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		else:
			spring_arm.rotate_x(-event.relative.y * SENSITIVITY)
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-90), deg_to_rad(90))

# --- LÓGICA DE VISIBILIDAD ---
func actualizar_vistas():
	if is_fps:
		camera_fps.current = true
		model.visible = false # Ocultamos el modelo en FPS para evitar obstrucciones
	else:
		camera_tps.current = true
		model.visible = true

func _physics_process(delta):
	# 1. Aplicar Gravedad
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# 2. Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Leer movimiento (WASD)
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

	# Aplicar velocidad horizontal
	velocity.x = input_dir.x * SPEED
	velocity.z = input_dir.z * SPEED

	# 4. Rotación del Modelo
	# Obtenemos el vector "puro" de las teclas para la rotación
	var raw_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	if not is_fps and raw_input != Vector2.ZERO:
		# Calculamos el ángulo y añadimos PI para corregir el frente del XBot
		var target_rotation = atan2(-raw_input.x, -raw_input.y) + PI
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation, delta * 10.0)
	elif is_fps:
		# En primera persona mantenemos el desfase para mirar al frente correctamente
		model.rotation.y = PI

	# 5. Ejecutar Movimiento
	move_and_slide()

	# 6. Control de Animaciones
	# Verificamos movimiento en el plano XZ para decidir la animación
	var velocity_2d = Vector2(velocity.x, velocity.z)
		
		# --- CONTROL DE ANIMACIÓN (NOMBRES CORREGIDOS) ---
	if velocity_2d.length() > 0.1:
		# Debe coincidir exactamente con el texto del cuadro en el grafo
		anim_state.travel("Walking_mixamo_com")
	else:
		# Debe coincidir exactamente con el texto del cuadro en el grafo
		anim_state.travel("Idle_mixamo_com")
