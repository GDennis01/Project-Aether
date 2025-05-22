extends Node

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

#particle properties
var albedo: float = 0.0
var particle_diameter: float = 0.0
var particle_density: float = 0.0

#constants
const AU: float = 1.496e11 ## AU. Astronomical Unit expressed in Meters
const GRAVITATIONAL_CONSTANT: float = 6.674e-11 ## G. Gravitational Constant expressed in MKS
const SUN_MASS: float = 1.98892e30 ## Ms. Sun mass expressed in Kg
const SUN_LUMINOSITY: float = 3.828e26 ## Ls. Sun Luminosity expressed in J/s
const LIGHT_SPEED: float = 2.99792458e8 ## c. Speed of light Expressed in m/s


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
