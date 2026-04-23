extends Node
class_name TypesTools

static func is_vector2i(value) -> bool:
	return typeof(value) == TYPE_VECTOR2I

static func is_null(value) -> bool:
	return typeof(value) == TYPE_NIL
