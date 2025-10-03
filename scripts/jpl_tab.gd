extends CanvasLayer

@onready var search_bar: LineEdit = $Control/SearchBar
@onready var start_date_ledit: LineEdit = $Control/StartDateLineEdit
@onready var end_date_ledit: LineEdit = $Control/EndDateLineEdit
@onready var scroll_container: ScrollContainer = $Control/EphemScroll
@onready var ephem_table: VBoxContainer = $Control/EphemScroll/EphemTable


var http_request: HTTPRequest
var start_date: Date
var end_date: Date
var step_size: float = 1.0
# var target = "C/2013 R1"
var api_url := "https://ssd.jpl.nasa.gov/api/horizons.api"

var quantities := "1,19,20,23"

# Regex Related
var regex_params: Array[String] = [
		"(\\d{4}-\\w{3}-\\d{2})", # Matches the date, e.g., 1998-Jan-01
		"(\\d{2}:\\d{2})", # Matches the time, e.g., 10:00
		"([+-]?\\d{2}\\s\\d{2}\\s\\d{2}\\.\\d{2})", # Matches right ascension, e.g., 20 55 41.20
		"([-+]?\\d{2}\\s\\d{2}\\s\\d{2}\\.\\d)", # Matches declination, e.g., -18 33 23.0
		"([+-]?\\d+\\.\\d+)", # Matches the first float value, e.g., 1.199
		"([+-]?\\d+\\.\\d+)", # Matches the second float value, e.g., 4.107
		"([+-]?\\d+\\.\\d+)", # Matches the third float value, e.g., 2.13799045474771
		"([+-]?\\d+\\.\\d+)" # Matches the fourth float value, e.g., 5.6049390
	]
var number_params := regex_params.size()
var full_pattern := "\\s+".join(PackedStringArray(regex_params))
var regex := RegEx.new()
var compiled := regex.compile(full_pattern)

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)
	

func _on_search_btn_pressed() -> void:
	var query := search_bar.text
	print(start_date.date("YYYY-MM-DD"))
	var params := {
		"format": "json",
		"COMMAND": "'%s'" % query,
		"OBJ_DATA": "NO",
		"MAKE_EPHEM": "YES",
		"EPHEM_TYPE": "OBSERVER",
		"CENTER": "'500@399'", # Geocentric (Observatory at the center of Earth)
		"START_TIME": "'%s 00:00'" % start_date.date("YYYY-MM-DD"),
		"STOP_TIME": "'%s 00:00'" % end_date.date("YYYY-MM-DD"),
		"STEP_SIZE": "'%sh'" % int(step_size),
		"QUANTITIES": "'%s'" % quantities
	}

	# Construct the query string from the parameters
	var query_string := ""
	for key: String in params.keys():
		if query_string != "":
			query_string += "&"
		query_string += "%s=%s" % [key, params[key]]
	var url := "{api_url}?{query_string}".format({"api_url": api_url, "query_string": query_string})
	print("Request URL: ", url)
	var error := http_request.request(url)
	
	if error != OK:
		push_error("An error occurred in the HTTP request.")

		print("Request sent successfully")
	# Implement search functionality here


func _http_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Image couldn't be downloaded. Try a different image.")

	var json_parser := JSON.new()
	var body_string := body.get_string_from_utf8()
	json_parser.parse(body_string)

	var data: Variant = json_parser.data
	json_parser.parse(parse_ephemeris(data.result))
	var ephemeris_data: Variant = json_parser.data
	print(ephemeris_data)
	clear_container()
	populate_container(ephemeris_data)
func clear_container() -> void:
	for child in ephem_table.get_children():
		ephem_table.remove_child(child)
		child.queue_free()
	# adjust scroll to top
	scroll_container.custom_minimum_size.y = 0
	scroll_container.scroll_vertical = 0
func populate_container(data: Variant) -> void:
	var HEADER := {
		"date": "Date",
		"time": "Time",
		"right_ascension": "Right Ascension (HH MM SS.SS)",
		"declination": "Declination (DD MM SS.S)",
		"heliocentric_distance": "Heliocentric Distance (AU)",
		"geocentric_distance": "Geocentric Distance (AU)",
		"heliocentric_distance_rate": "Heliocentric Distance Rate (km/s)",
		"geocentric_distance_rate": "Geocentric Distance Rate (km/s)"
	}
	var header_string := ""
	for key in HEADER.keys():
		header_string += "%-30s" % HEADER[key]
	print(header_string)
	var header_label := Label.new()
	header_label.text = header_string
	ephem_table.add_child(header_label)
	for entry in data:
		var hbox := HBoxContainer.new()
		for key in HEADER.keys():
			var label := Label.new()
			label.text = str(entry[key])
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(label)
		ephem_table.add_child(hbox)
	# scroll_container.scroll_vertical = scroll_container.get_v_scrollbar().max_value

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
	var json_text := "["
	for index in range(len(eph_lines)):
		var line := eph_lines[index]
		print(line)
		var result := regex.search(line)
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
		"heliocentric_distance": result.get_string(5),
		"geocentric_distance": result.get_string(6),
		"heliocentric_distance_rate": result.get_string(7),
		"geocentric_distance_rate": result.get_string(8)
		}
		# print(entry)

		json_text += JSON.stringify(entry)
		if index < len(eph_lines) - 1:
			json_text += ","
	json_text += "]"
	# print(json_text)
	return json_text

func _on_start_calendar_btn_date_selected(date_obj: Date) -> void:
	print(date_obj.date()) # Example of formatted date output
	if end_date != null and date_obj.year() > end_date.year():
		push_error("Start date cannot be later than end date.")
		return
	elif end_date != null and date_obj.year() == end_date.year() and date_obj.month() > end_date.month():
		push_error("Start date cannot be later than end date.")
		return
	elif end_date != null and date_obj.year() == end_date.year() and date_obj.month() == end_date.month() and date_obj.day() > end_date.day():
		push_error("Start date cannot be later than end date.")
		return
	start_date = date_obj
	start_date_ledit.text = date_obj.date("DD-MM-YYYY")


func _on_end_calendar_btn_date_selected(date_obj: Date) -> void:
	print(date_obj.date("DD-MM-YYYY")) # Example of formatted date output
	if start_date != null and date_obj.year() < start_date.year():
		push_error("End date cannot be earlier than start date.")
		return
	elif start_date != null and date_obj.year() == start_date.year() and date_obj.month() < start_date.month():
		push_error("End date cannot be earlier than start date.")
		return
	elif start_date != null and date_obj.year() == start_date.year() and date_obj.month() == start_date.month() and date_obj.day() < start_date.day():
		push_error("End date cannot be earlier than start date.")
		return
	end_date = date_obj
	end_date_ledit.text = date_obj.date("DD-MM-YYYY")


func update_step_size(value: float) -> void:
	step_size = value
	print("Step size updated to: ", step_size)
