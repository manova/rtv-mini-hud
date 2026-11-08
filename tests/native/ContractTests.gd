extends RefCounted
var host: Node
var verifier: Script
func validate(source: String, expected: bool, label: String) -> void:
	var script:=GDScript.new()
	script.source_code=source
	var compiled:=script.reload()==OK
	host.check(compiled,"contract mutation compiles: "+label)
	if compiled: host.check(verifier.verified(script)==expected,"contract outcome: "+label)
func span(source: String, method: String) -> Vector2i:
	var start:=source.find("\nfunc "+method+"(")+1
	var end:=source.find("\nfunc ",start)
	return Vector2i(start,source.length() if end<0 else end)
func append_to_method(source: String, method: String, extra: String) -> String:
	var bounds:=span(source,method)
	return source.substr(0,bounds.x)+source.substr(bounds.x,bounds.y-bounds.x).strip_edges()+"\n"+extra+"\n"+source.substr(bounds.y)
func run(root: Node, contract: Script) -> void:
	host=root;verifier=contract
	for layout in ["minimal","broad"]:
		var source:=FileAccess.get_file_as_string("res://captured-"+layout+".gd.txt")
		validate(source,true,layout+" captured generated source")
		validate(source.replace("\n","\r\n"),true,layout+" CRLF normalization")
		validate(append_to_method(source,"Death","# one trailing comment\n\n# second trailing comment"),true,layout+" only trailing column-zero comments")
		# Preserve exact fingerprints of every native body and wrapper.
		for method in contract.BLOCKS:
			validate(append_to_method(source,method,'\tset_meta("contract_mutation", true)'),false,layout+" extra executable statement in "+method)
		validate(source.replace("dead = true","dead = false"),false,layout+" changes dead state")
		validate(source.replace("health -= damage","health -= damage * 2.0"),false,layout+" changes damage arithmetic")
		validate(source.replace("Death(direction, 20.0)","Death(direction, 10.0)"),false,layout+" changes explosion death force")
		validate(source.replace('_lib._dispatch("ai-death-pre", [direction, force])','_lib._dispatch("ai-death-post", [direction, force])'),false,layout+" changes wrapper callback")
		validate(append_to_method(source,"Death",'var contract_mutation: bool = true\n# trailing comment'),false,layout+" module declaration is not discarded")
		validate(append_to_method(source,"Death",'\tset_meta("contract_mutation", "# looks like a comment")\n# trailing comment'),false,layout+" executable string with comment marker retained")
		# A column-zero comment in the middle of the body is still fingerprinted.
		validate(source.replace('func Death(direction, force):','func Death(direction, force):\n# interior comment'),false,layout+" interior comment does not become a method boundary")
		# Existing header check and reflective-method exclusions remain intact.
		var first:=source.find("\nfunc ")
		validate(source.substr(0,first)+"\nconst CONTRACT_MUTATION = true\n"+source.substr(first),false,layout+" header declaration rejected")
		validate(source.replace('func _rtv_ai_categories() -> Array:','func _get(property: StringName):\n\treturn null\n\nfunc _rtv_ai_categories() -> Array:'),false,layout+" reflective getter rejected")
