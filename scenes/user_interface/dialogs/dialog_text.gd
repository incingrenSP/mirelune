extends RichTextLabel

signal page_shown(page_text: String)

const CHARACTERS_PER_SECOND := 80.0

var pages: Array[String] = []
var current_page := 0
var revealing := false
var reveal_tween : Tween

func show_text(full_text: String) -> void:
	bbcode_enabled = true
	scroll_active = false
	fit_content = false
	
	pages = _paginate(full_text)
	current_page = 0
	_show_page(0)
	
func _paginate(full_text: String) -> Array[String]:
	var words := full_text.split(" ", false)
	var result: Array[String] = []
	var start := 0
	
	while start < words.size():
		var fit_count := _find_fit_length(words, start)
		var page_words := words.slice(start, start + fit_count)
		result.append(" ".join(page_words))
		start += fit_count
		
	return result
	
func _find_fit_length(words: Array, start: int) -> int:
	var remaining_count := words.size() - start
	
	text = words[start]
	if get_content_height() > size.y:
		return 1
		
	var lo := 1
	var hi := remaining_count
	
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		var candidate := " ".join(words.slice(start, start + mid))
		text = candidate
		if get_content_height() <= size.y:
			lo = mid
		else:
			hi = mid - 1
			
	return max(lo, 1)
	
func _show_page(index: int) -> void:
	text = pages[index]
	visible_ratio = 0.0
	revealing = true
	
	if reveal_tween:
		reveal_tween.kill()
	
	var char_count := get_total_character_count()
	var duration := char_count / CHARACTERS_PER_SECOND
	
	reveal_tween = create_tween()
	reveal_tween.tween_property(self, "visible_ratio", 1.0, duration)
	reveal_tween.finished.connect(func(): revealing = false)
	
	page_shown.emit(pages[index])
	
func skip_reveal() -> void:
	if reveal_tween:
		reveal_tween.kill()
	visible_ratio = 1.0
	revealing = false
	
func advance_page() -> bool:
	current_page += 1
	if current_page < pages.size():
		_show_page(current_page)
		return true
		
	return false
	
