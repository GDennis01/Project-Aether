extends CanvasLayer

@onready var search_bar: LineEdit = $Control/SearchBar
@onready var start_date_ledit: LineEdit = $Control/StartDateLineEdit
@onready var end_date_ledit: LineEdit = $Control/EndDateLineEdit
@onready var scroll_container: ScrollContainer = $Control/EphemScroll
@onready var ephem_table: VBoxContainer = $Control/EphemScroll/EphemTable


var http_request: HTTPRequest
var start_date: Date
var end_date: Date
var step_size: float = 24.0
var alpha_p: float = 0.0
var delta_p: float = 0.0
# var target = "C/2013 R1"
var api_url := "https://ssd.jpl.nasa.gov/api/horizons.api"

# var quantities := "1,19,20,23"
var quantities := "1,16,19,20,24,28,41,47"

# Regex Related
var regex_params: Array[String] = [
		"(\\d{4}-\\w{3}-\\d{2})", # Matches the date, e.g., 1998-Jan-01
		"(\\d{2}:\\d{2}(?::\\d{2}(?:\\.\\d{3})?)?)", # Matches the time, e.g., 10:00 or 10:00:00.000
		"([+-]?\\d+\\.\\d+)", # Matches right ascension, e.g., 314.921234
		"([+-]?\\d+\\.\\d+)", # Matches declination, e.g., -18.556789

		# "([+-]?\\d{2}\\s\\d{2}\\s\\d{2}\\.\\d{2})", # Matches right ascension, e.g., 20 55 41.20
		# "([-+]?\\d{2}\\s\\d{2}\\s\\d{2}\\.\\d)", # Matches declination, e.g., -18 33 23.0
		"([+-]?\\d+\\.\\d+)", # Sun PA (single float value)
		"([+-]?\\d+\\.\\d+)", # SN.dist (single float value) --- IGNORE ---
		"([+-]?\\d+\\.\\d+)", # Sun Distance R (single float value)
		"([+-]?\\d+\\.\\d+)", # r.dot (single float value) --- IGNORE ---
		"([+-]?\\d+\\.\\d+)", # Delta (single float value)
		"([+-]?\\d+\\.\\d+)", # deldot (single float value) --- IGNORE ---
		"([+-]?\\d+\\.\\d+)", # STO (single float value)
		"([+-]?\\d+\\.\\d+)", # PlAngle (single float value)
		"([+-]?\\d+\\.\\d+)", # True anomaly (single float value)
		"([+-]?\\d+\\.\\d+)", # Sky motion (single float value) --- IGNORE ---
		"([+-]?\\d+\\.\\d+)", # Sky motion PA (single float value)
	]

var number_params := regex_params.size()
var full_pattern := "\\s+".join(PackedStringArray(regex_params))
var jpl_regex := RegEx.new()
var compiled := jpl_regex.compile(full_pattern)


var om_w_in_regex: RegEx = RegEx.new()
# Pattern to match " OM= 124.567, W= 123.456, IN= 78.910"
var om_w_in_compiled := om_w_in_regex.compile("\\s*OM=\\s*([-+]?\\d+\\.\\d+)\\s*W=\\s*([-+]?\\d+\\.\\d+)\\s*IN=\\s*([-+]?\\d+\\.\\d+)")

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)
	

func _on_search_btn_pressed() -> void:
	var query := search_bar.text
	if query == "":
		Util.create_popup("Error", "Please enter a valid target name or designation.")
		return
	if start_date == null:
		Util.create_popup("Error", "Please select a valid start date.")
		return
	if step_size <= 0:
		Util.create_popup("Error", "Please select a valid step size (greater than 0).")
		return
	var params := {
		"format": "json",
		"COMMAND": "'%s'" % query,
		"OBJ_DATA": "NO",
		"MAKE_EPHEM": "YES",
		"EPHEM_TYPE": "OBSERVER",
		"CENTER": "'500@399'", # Geocentric (Observatory at the center of Earth)
		
		"STEP_SIZE": "'%sh'" % int(step_size),
		"ANG_FORMAT": "DEG",
		"QUANTITIES": "'%s'" % quantities
	}
	if end_date == null:
		params["TLIST"] = "'%s 00:00'" % start_date.date("YYYY-MM-DD")
	else:
		params["START_TIME"] = "'%s 00:00'" % start_date.date("YYYY-MM-DD")
		params["STOP_TIME"] = "'%s 00:00'" % end_date.date("YYYY-MM-DD")
	# Construct the query string from the parameters
	var query_string := ""
	for key: String in params.keys():
		if query_string != "":
			query_string += "&"
		query_string += "%s=%s" % [key, params[key]]
	var url := "{api_url}?{query_string}".format({"api_url": api_url, "query_string": query_string})
	# print("API URL:")
	# print("Request URL: ", url)
	var tls_options := TLSOptions.client_unsafe()
	http_request.set_tls_options(tls_options)
	var error := http_request.request(url)
	var error_msg: String = ""
	match error:
		OK:
			error_msg = "HTTP request sent successfully."
		ERR_UNCONFIGURED:
			error_msg = "HTTPRequest node is not configured."
		ERR_BUSY:
			error_msg = "HTTPRequest node is busy with another request."
		ERR_INVALID_PARAMETER:
			error_msg = "Invalid parameter provided to HTTPRequest."
		ERR_CANT_CONNECT:
			error_msg = "Cannot connect to the server."
		_:
			error_msg = "Default error message."
	print("HTTP Request Status: ", error_msg)
	# Util.create_popup("Request Status", error_msg)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	print("----------")


func _http_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var json_parser := JSON.new()
	var body_string := body.get_string_from_utf8()
	json_parser.parse(body_string)
	# print("JSON\n")
	# print(body_string)
	# Util.create_popup("Data Loaded", body_string)
	if _response_code != 200 or json_parser.data.has("error"):
		push_error("Error: %s" % json_parser.data.error)
		Util.create_popup("Error", "Failed to retrieve ephemeris data:\n%s" % json_parser.data.error)
		return

	var data: Variant = json_parser.data
	var eph_tmp := parse_ephemeris(data.result)
	if eph_tmp == "":
		push_error("Failed to parse ephemeris data.")
		Util.create_popup("Error", "Failed to parse ephemeris data. One or more fields may be wrong.")
		return
	json_parser.parse(eph_tmp)
	print("Json:\n")
	print(json_parser.data)
	var ephemeris_data: Variant = json_parser.data
	# print(ephemeris_data)
	# $Control/JPLTablePanel.visible = true

	# $Control/WLabel.visible = true
	# $Control/OMLabel.visible = true
	# $Control/INLabel.visible = true
	# $Control/WLineEdit.visible = true
	# $Control/OMLineEdit.visible = true
	# $Control/INLineEdit.visible = true
	
	$Control/ECLineEdit.text = "N/A"
	$Control/QRLineEdit.text = "N/A"
	$Control/TPLineEdit.text = "N/A"
	$Control/OMLineEdit.text = str(ephemeris_data.om)
	$Control/WLineEdit.text = str(ephemeris_data.w)
	$Control/INLineEdit.text = str(ephemeris_data.inc)
	
	clear_container()
	populate_container(ephemeris_data.data)


func parse_ephemeris(data: String) -> String:
	var data_start_marker := "$$SOE"
	var data_end_marker := "$$EOE"
	var start_index := data.find(data_start_marker)
	var end_index := data.find(data_end_marker)

	if start_index == -1:
		push_error("Data start marker not found.")
		return ""
	if end_index == -1:
		push_error("Data end marker not found.")
		return ""

	# from the body, extract the line containing OM=.. , W=.. , IN=...
	# and extract the object name from it
	var om_index := data.find(" OM=")
	if om_index == -1:
		push_error("OM/W/IN line not found.")
		return ""

	var om_end_index := data.find("\n", om_index)
	var om_line := data.substr(om_index, om_end_index - om_index).strip_edges()
	var om_result := om_w_in_regex.search(om_line)
	if om_result == null:
		push_error("No matches found in the OM/W/IN line: %s" % om_line)
		return ""
	var om := om_result.get_string(1)
	var w := om_result.get_string(2)
	var inc := om_result.get_string(3)
	# print("OM: %s, W: %s, IN: %s" % [om, w, inc])
	# set the object name in the search bar
	# extracting only the ephemeris body (which is enclosed between the start and end markers)
	var eph_body := data.substr((start_index + data_start_marker.length()), (end_index - start_index - data_start_marker.length()))
	eph_body = eph_body.replace("/L", "")
	var _eph_lines := eph_body.split("\n")

	# from packedstringarray to array[string]
	var eph_lines: Array[String] = []
	for line in _eph_lines:
		if line.strip_edges() != "":
			eph_lines.append(line.strip_edges())

	# extracting each column, line by line, using regex
	var json_text := "{\"om\": %s, \"w\": %s, \"inc\": %s, \"data\": [" % [om, w, inc]
	Util.om = float(om)
	Util.w = float(w)
	Util.incl = float(inc)
	for index in range(len(eph_lines)):
		var line := eph_lines[index]
		# print(line)
		var result := jpl_regex.search(line)
		if result == null:
			push_error("No matches found in the ephemeris data line: %s" % line)
			continue
		var entry := {}
		# for i in range(1, result.get_group_count() + 1):
		entry = {
			"date": result.get_string(1),
			"time": result.get_string(2),
		"right_ascension": result.get_string(3),
		"declination": result.get_string(4),
		"sun_pa": result.get_string(5),
		"sun_distance_r": result.get_string(7),
		"delta": result.get_string(9),
		"sto": result.get_string(11),
		"pl_ang": result.get_string(12),
		"true_anomaly": result.get_string(13),
		"sky_motion_pa": result.get_string(15)
		}
		# print(entry)

		json_text += JSON.stringify(entry)
		if index < len(eph_lines) - 1:
			json_text += ","
	json_text += "]}"
	# print(json_text)
	return json_text

# Clear the container before populating it with new data.
func clear_container() -> void:
	for child in ephem_table.get_children():
		ephem_table.remove_child(child)
		child.queue_free()
	# adjust scroll to top
	scroll_container.custom_minimum_size.y = 0
	scroll_container.scroll_vertical = 0
# Populate the container with tabular data from the ephemeris, retrieved from Nasa JPL API.
func populate_container(data: Variant) -> void:
	var HEADER := {
		"date": "Date",
		"time": "Time",
		"right_ascension": "Right Ascension (Deg)",
		"declination": "Declination (Deg)",
		# "sun_pa": "Sun PA (Deg)",
		# "sun_distance_r": "Sun Distance R (AU)",
		# "delta": "Delta (AU)",
		# "sto": "STO (Deg)",
		"pl_ang": "Sky Plane Angle (Deg)",
		"true_anomaly": "True Anomaly (Deg)",
		"sky_motion_pa": "Sky Motion PA (Deg)"
	}
	Util.jpl_data = data
	var date_str: String = str(data[0]["date"])
	var time_str: String = str(data[0]["time"])
	# only the first 2 digits
	time_str = time_str.substr(0, 2)
	get_tree().call_group("switch_date", "switch_date_set_date", date_str + " " + time_str, true)
	# print(data)
	var header_string := ""
	for key: String in HEADER.keys():
		header_string += "%-30s" % HEADER[key]
	# print(header_string)
	var header_label := Label.new()
	header_label.text = header_string
	ephem_table.add_child(header_label)
	for entry: Dictionary in data:
		var hbox := HBoxContainer.new()
		for key: String in HEADER.keys():
			var label := Label.new()
			label.text = str(entry[key])
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(label)
		ephem_table.add_child(hbox)
	# scroll_container.scroll_vertical = scroll_container.get_v_scrollbar().max_value


func _on_start_calendar_btn_date_selected(date_obj: Date) -> void:
	# print(date_obj.date()) # Example of formatted date output
	# if end_date != null and date_obj.year() > end_date.year():
	# 	push_error("Start date cannot be later than end date.")
	# 	return
	# elif end_date != null and date_obj.year() == end_date.year() and date_obj.month() > end_date.month():
	# 	push_error("Start date cannot be later than end date.")
	# 	return
	# elif end_date != null and date_obj.year() == end_date.year() and date_obj.month() == end_date.month() and date_obj.day() > end_date.day():
	# 	push_error("Start date cannot be later than end date.")
	# 	return
	start_date = date_obj
	start_date_ledit.text = date_obj.date("YYYY-MM-DD")


func _on_end_calendar_btn_date_selected(date_obj: Date) -> void:
	# print(date_obj.date("YYYY-MM-DD")) # Example of formatted date output
	# if start_date != null and date_obj.year() < start_date.year():
	# 	push_error("End date cannot be earlier than start date.")
	# 	return
	# elif start_date != null and date_obj.year() == start_date.year() and date_obj.month() < start_date.month():
	# 	push_error("End date cannot be earlier than start date.")
	# 	return
	# elif start_date != null and date_obj.year() == start_date.year() and date_obj.month() == start_date.month() and date_obj.day() < start_date.day():
	# 	push_error("End date cannot be earlier than start date.")
	# 	return
	end_date = date_obj
	end_date_ledit.text = date_obj.date("YYYY-MM-DD")


func update_step_size(value: float) -> void:
	step_size = value
	# print("Step size updated to: ", step_size)


func _on_clear_start_date_btn_pressed() -> void:
	start_date = null
	start_date_ledit.text = ""
func _on_clear_end_date_btn_pressed() -> void:
	end_date = null
	end_date_ledit.text = ""
# func update_alpha_p(value: float) -> void:
# 	alpha_p = value
# 	update_i()
# 	update_phi()
# 	update_table()
# func update_delta_p(value: float) -> void:
# 	delta_p = value
# 	update_i()
# 	update_phi()
# 	update_table()

# func update_i() -> void:
# 	pass
# func update_phi() -> void:
# 	pass
# func update_table() -> void:
# 	pass
