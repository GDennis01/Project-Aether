extends Node


# Converts Latitude/Longitude (in degrees) to a local 3D position
# vector relative to the center of a sphere with the given radius.
# Assumes Y-Up, Latitude 0 = Equator, Longitude 0 = +X axis.
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
