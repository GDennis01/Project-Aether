extends Node

##Debug
const PRINT_UPDATE_METHOD = false

## current radius of the comet
var comet_radius: float = 0.0
## current inclination rotation angle of the sun
var sun_inclination: float = 0.0
## current direction angle of the sun
var sun_direction: float = 0.0
## current inclination rotation angle of the comet
var comet_inclination: float = 0.0
## current direction angle of the comet
var comet_direction: float = 0.0
## jet rate in minutes
var jet_rate: float = 0.0
## Sun-comet distance in AU
var sun_comet_distance: float = 0.0
## Sun direction vector in the 3D space
var sun_direction_vector: Vector3 = Vector3.ZERO
## Eart-comet delta in AU
var earth_comet_delta: float = 0.0

# Scale related properties
#region Scale
## Scale in meters/pixel
var scale: float = 0.0
## Telescope resolution in arcsec/pixel
var tel_resolution: float = 0.0
## Telescope resolution in km/pixel
var tel_res_km_pixel: float = 0.0
## Telescope image size in pixels
var tel_image_size: float = 0.0
## Window field of view in meters
var window_fov: float = 0.0
## Window size in pixels
var window_size: float = 900.0
## FOV in arcmin
var fov_arcmin: float = 0.0
## FOV in km
var fov_km: float = 0.0
## Starting distance of the rotating camera
var starting_distance: float = 0.0
## Visible area in meters at the starting distance of the rotating_camera
var starting_visible_area: float = 0.0
## Visible area in meters at the current distance of the rotating_camera
var visible_area: float = 0.0
#endregion Scale

## Orbital comet basis
var orbital_basis: Basis = Basis() ## Orbital basis of the comet in the 3D space

## Orbital transformation 
var orbital_transformation: Transform3D = Transform3D() ## Orbital transformation of the comet in the 3D space

## Equatorial transformation
var equatorial_transformation: Transform3D = Transform3D() ## Equatorial transformation of the comet in the 3D space
var equatorial_rotation: Quaternion ## Equatorial rotation of the comet in the 3D space

# Simulation related properties
var i: float = 0.0 ## angle between rotationa xis and the orbital plane in degrees
var phi: float = 0.0 ## angle between projection of axis direction and sun direction at perihelion in degrees
var true_anomaly: float = 0.0 ## angular position of the comet in its orbit in degrees
var n_points: int = 1 ## number of points in the orbit

#particle properties
var albedo: float = 0.0
var particle_diameter: float = 0.0
var particle_density: float = 0.0

#constants
const AU: float = 149597870707 ## AU. Astronomical Unit expressed in Meters
const GRAVITATIONAL_CONSTANT: float = 6.674e-11 ## G. Gravitational Constant expressed in MKS
const SUN_MASS: float = 1.98892e30 ## Ms. Sun mass expressed in Kg
const SUN_LUMINOSITY: float = 3.828e26 ## Ls. Sun Luminosity expressed in J/s
const LIGHT_SPEED: float = 2.99792458e8 ## c. Speed of light Expressed in m/s

var is_simulation: bool = true ## True: simulation enabled, False: instant simulation enabled


# Labels
@onready var current_camera_label: Label = $"/root/Hud/Viewport/SubViewportContainer/CurrCameraLabel"
@onready var current_fov_label: Label = $"/root/Hud/Viewport/SubViewportContainer/SubViewport/CenterContainer/ScaleLabel"

## Converts Latitude/Longitude (in degrees) to a local 3D position
## vector relative to the center of a sphere with the given radius.
## Assumes Y-Up, Latitude 0 = Equator, Longitude 0 = +X axis.
func latlon_to_vector3(latitude: float, longitude: float, radius: float) -> Vector3:
	# Ensure inputs are valid floats (optional, but good practice)
	if not (typeof(latitude) == TYPE_FLOAT and typeof(longitude) == TYPE_FLOAT and typeof(radius) == TYPE_FLOAT):
		printerr("Latitude, Longitude, and Radius must be floats.")
		return Vector3.ZERO # Or handle error appropriately

	# Convert degrees to radians
	var lat_rad: float = deg_to_rad(latitude)
	var lon_rad: float = deg_to_rad(longitude)

	# Calculate Cartesian coordinates
	# Y is determined by latitude (height above/below equator)
	var y: float = radius * sin(lat_rad)

	# Calculate the radius of the circle projected onto the XZ plane at this latitude
	var xz_radius: float = radius * cos(lat_rad)

	# X and Z are determined by longitude on that projected circle
	var x: float = xz_radius * cos(lon_rad) # cos for X as Lon 0 is on +X
	var z: float = xz_radius * sin(lon_rad) # sin for Z as Lon increases towards +Z

	return Vector3(x, y, z)
## Convert coordinate from equatorial plane to orbital plane by applying a transformation as following:
## This transformation is done by rotating the frame around the axis Y with an angle
## (90◦ − I) and around the axis Z with an angle −(Φ +ν).
func equatorial_to_orbital(coords: Vector3) -> Vector3:
	# switch y and z to match Godot's coordinate system
	var tmp := coords.y
	coords.y = coords.z
	coords.z = tmp

	var rot_mat1: Basis = Basis()
	rot_mat1.x = Vector3(cos(deg_to_rad(Util.phi + Util.true_anomaly)), sin(deg_to_rad(Util.phi + Util.true_anomaly)), 0)
	rot_mat1.y = Vector3(-sin(deg_to_rad(Util.phi + Util.true_anomaly)), cos(deg_to_rad(Util.phi + Util.true_anomaly)), 0)
	rot_mat1.z = Vector3(0, 0, 1)

	var rot_mat2: Basis = Basis()
	rot_mat2.x = Vector3(sin(deg_to_rad(Util.i)), 0, -cos(deg_to_rad(Util.i)))
	rot_mat2.y = Vector3(0, 1, 0)
	rot_mat2.z = Vector3(cos(deg_to_rad(Util.i)), 0, sin(deg_to_rad(Util.i)))


	var result := rot_mat1 * rot_mat2 * coords
	# print("Equatorial to Orbital: ", result)
	# swap y and z to match Godot's coordinate system
	# var tmp := result.y
	# result.y = result.z
	# result.z = tmp
	return result

## Convert coordinate from orbital plane to geocentric frame by applying rotations.
## TODO: figure out the correct rotation angles (5 which is PsAng and 7 which is theta)
func orbital_to_geocentric(coords: Vector3) -> Vector3:
	var rot_mat1: Basis = Basis()
	rot_mat1.x = Vector3(1, 0, 0)
	rot_mat1.y = Vector3(0, -sin(deg_to_rad(Util.sun_direction + 180)), cos(deg_to_rad(Util.sun_direction + 180)))
	rot_mat1.z = Vector3(0, -cos(deg_to_rad(Util.sun_direction + 180)), -sin(deg_to_rad(Util.sun_direction + 180)))


	var rot_mat2: Basis = Basis()
	rot_mat2.x = Vector3(cos(deg_to_rad(Util.sun_inclination)), sin(deg_to_rad(Util.sun_inclination)), 0)
	rot_mat2.y = Vector3(-sin(deg_to_rad(Util.sun_inclination)), cos(deg_to_rad(Util.sun_inclination)), 0)
	rot_mat2.z = Vector3(0, 0, 1)

	# var rot_mat3: Basis = Basis()
	# rot_mat3.x = Vector3(1, 0, 0)
	# rot_mat3.y = Vector3(0, cos(deg_to_rad(7)), sin(deg_to_rad(7)))
	# rot_mat3.z = Vector3(0, -sin(deg_to_rad(7)), cos(deg_to_rad(7)))
	var result := rot_mat1 * rot_mat2 * coords
	# var result := rot_mat1 * rot_mat2 * rot_mat3 * coords
	# swap y and z to match Godot's coordinate system
	# var tmp := result.y
	# result.y = result.z
	# result.z = tmp
	return result

func get_equatorial_to_orbital_basis() -> Basis:
	var rot_y := Basis(Vector3.FORWARD, deg_to_rad(90.0 - Util.i))
	var rot_z := Basis(Vector3.UP, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	return rot_z * rot_y

func get_orbital_to_equatorial_basis() -> Basis:
	return get_equatorial_to_orbital_basis().transposed()


func get_orbital_to_geocentric_basis() -> Basis:
	var theta := 1 # ??
	var psang := Util.sun_direction + 180 # PsAng is the angle between the Sun direction and the X axis in the orbital plane
	var rot_1 := Basis(Vector3.RIGHT, deg_to_rad(theta))
	var rot_2 := Basis(Vector3.FORWARD, deg_to_rad(Util.sun_direction))
	var rot_3 := Basis(Vector3.RIGHT, deg_to_rad(90 + psang)) # var rot_x := Basis(Vector3.RIGHT, deg_to_rad(7.0)) # TODO: figure out the correct rotation angle
	return rot_3 * rot_2

func convert_equatorial_to_orbital(coords: Vector3) -> Vector3:
	var result := get_equatorial_to_orbital_basis() * coords
	print("Equatorial to Orbital: ", result)
	# swap y and z to match Godot's coordinate system

	return result

func convert_orbital_to_equatorial(coords: Vector3) -> Vector3:
	var result := get_orbital_to_equatorial_basis() * coords
	# switch y and z to match Godot's coordinate system
	return result

func convert_orbital_to_geocentric(coords: Vector3) -> Vector3:
	var result := get_orbital_to_geocentric_basis() * coords
	return result


## Generates a random point inside a sphere with radius _radius from a Gaussian distribution with given mean and standard deviation.
## The point is uniformly distributed inside the sphere.
func generate_gaussian_vector(mean: float, stddev: float, _radius: float) -> Vector3:
	var x := randfn(mean, stddev)
	var y := randfn(mean, stddev)
	var z := randfn(mean, stddev)
	# direction normalize so that the point is on the surface of a sphere
	var direction := Vector3(x, y, z).normalized()
	# cuberoot to ensure uniform distribution in a sphere
	var length := _radius * randf() ** (1.0 / 3.0)
	# scale the direction by the length to get a point inside the sphere
	var point := direction * length
	return point
