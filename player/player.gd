extends CharacterBody3D

# --- CONFIGURACIÓN ---
const SPEED = 5.0           # Velocidad al caminar
const JUMP_VELOCITY = 4.5   # Fuerza del salto (Altura)
const SENSITIVITY = 0.003   # Sensibilidad del mouse
const GRAVITY = 9.8         # Gravedad

# --- REFERENCIAS ---
@onready var camera = $Camera3D

func _ready():
	# Al iniciar, atrapamos el mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# --- SALVAVIDAS: ESC para mostrar el mouse ---
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# --- VOLVER AL JUEGO: Clic para atrapar el mouse ---
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# --- ROTACIÓN CÁMARA ---
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta):
	# 1. Aplicar Gravedad (si estás en el aire)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# 2. SALTAR (Nueva funcionalidad)
	# "ui_accept" es la tecla Espacio o Enter por defecto en Godot
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Leer movimiento (W, A, S, D)
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += transform.basis.x

	# 4. Normalizar dirección
	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()

	# 5. Aplicar movimiento horizontal
	velocity.x = input_dir.x * SPEED
	velocity.z = input_dir.z * SPEED

	# 6. Mover
	move_and_slide()
