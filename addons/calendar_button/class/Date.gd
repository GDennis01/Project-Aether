class_name Date

var _day : set = set_day
var _month : set = set_month
var _year : set = set_year

func _init(day : int = Time.get_datetime_dict_from_system()["day"], 
		month : int = Time.get_datetime_dict_from_system()["month"], 
		year : int = Time.get_datetime_dict_from_system()["year"]):
	self._day = day
	self._month = month
	self._year = year

# Supported Date Formats:
# DD : Two digit day of month
# MM : Two digit month
# YY : Two digit year
# YYYY : Four digit year
func date(date_format = "DD-MM-YY") -> String:
	if("DD".is_subsequence_of(date_format)):
		date_format = date_format.replace("DD", str(day()).pad_zeros(2))
	if("MM".is_subsequence_of(date_format)):
		date_format = date_format.replace("MM", str(month()).pad_zeros(2))
	if("YYYY".is_subsequence_of(date_format)):
		date_format = date_format.replace("YYYY", str(year()))
	elif("YY".is_subsequence_of(date_format)):
		date_format = date_format.replace("YY", str(year()).substr(2,3))
	return date_format

func day() -> int:
	return _day

func month() -> int:
	return _month

func year() -> int:
	return _year

func set_day(value):
	_day = value

func set_month(value):
	_month = value

func set_year(value):
	_year = value

func change_to_prev_month():
	var selected_month = month()
	selected_month -= 1
	if(selected_month < 1):
		set_month(12)
		set_year(year() - 1)
	else:
		set_month(selected_month)

func change_to_next_month():
	var selected_month = month()
	selected_month += 1
	if(selected_month > 12):
		set_month(1)
		set_year(year() + 1)
	else:
		set_month(selected_month)

func change_to_prev_year():
	set_year(year() - 1)

func change_to_next_year():
	set_year(year() + 1)
