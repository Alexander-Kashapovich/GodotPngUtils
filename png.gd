@tool
extends Node2D
class_name PNGUtils

##Only Linux
## Requires pngquant in dir
## Requires oxipng in dir
## Requires ffmpeg in global env

@export_dir var dest:String

@export_category("quantors")
@export_tool_button("optimize_png") var __aasfasg = optimize_png
##[2-256]
@export var colors:int = 256
##Quality/Speed [1,11]
@export var speed:int = 4
##[0-6]
@export var oxi_level:int = 6
@export_category("ffmpeg")
@export_tool_button("rescale") var __aassasfasg = rescale
@export var scale_f:float = 0.5

func _pngquant() -> String:
	return ProjectSettings.globalize_path(
		scene_file_path.get_base_dir() + "/pngquant"
	)

func _oxipng() -> String:
	return ProjectSettings.globalize_path(
		scene_file_path.get_base_dir() + "/oxipng"
	)
	
func run(exe: String, args: PackedStringArray) -> bool:
	var out := []
	var code := OS.execute(exe, args, out, true)
	if code != 0:
		push_error("%s fall (code %d): %s" % [exe, code, out])
		return false
	return true

func optimize_png() -> void:
	var src := ProjectSettings.globalize_path(dest)

	for file in DirAccess.get_files_at(src):
		if file.get_extension().to_lower() != "png":
			continue
		var in_path := src.path_join(file)
		var out_path := in_path
		var init_size:int = FileAccess.get_size(in_path)
		
		## --nofs  no Floyd Dither
		## --strip - clear metadata
		## -- force - allow rewrite
		if not run(_pngquant(), 
		[colors, "--speed",speed, "--nofs", "--strip", in_path, "-o", out_path, "--force"]):
			continue
		
		## --zopfli ZopfLi compressor
		## -zi Zopfli iterarions
		## -- strip all clear chunks
		## -a Alpha clearing
		## -i clear intersailing
		if not run(_oxipng(), 
		["-o", oxi_level, "--zopfli", "--zi", "20", "--strip", "all", "-a", "-i", "0", out_path]):
			continue
		
		var diff:int = init_size - FileAccess.get_size(out_path)
		var res:float = Utils.b_to_kb(diff)
		print("pass %s, cut %.2fkb, %.2f%%" % [
			file,
			res,
			float(diff)/init_size * 100
			])

func rescale() -> void:
	var src := ProjectSettings.globalize_path(dest)

	for file in DirAccess.get_files_at(src):
		if file.get_extension() != "png":
			continue
		var in_path := src.path_join(file)
		var out_path := src.path_join("rescaled_" + file)

		var vf := "scale=iw/%s:ih/%s:flags=neighbor" % [scale_f, scale_f]
		run("ffmpeg", ["-y", "-i", in_path, "-vf", vf, out_path])
