$ = jQuery
prettifyRules = []

$ ->
	# Notify the parent that we have loaded!
	message =
		target: 'prettifyRules'
		command: 'load'
	parent.postMessage(message, '*')

commands =
	magic: (text) ->
		for rule in prettifyRules
			text = text.replace.apply(text, rule)
		return text
	parse: (data) ->
		prettifyRules = []
		capitalize = (w) ->
			w.substr(0,1).toUpperCase() + w.substr(1).toLowerCase()
		for line in data.split(/\r*\n+/)
			if /^\s*(#|$)/.test(line)
				# Comment or empty
			else if /^\s*\[.+\]\s*$/.test(line)
				try
					obj = eval(line)
				catch error
					return "Invalid JavaScript: #{error}:\n#{line}"
				if not $.isArray(obj) or obj.length isnt 2
					return "Not an array of length 2:\n#{line}"
				prettifyRules.push(obj)
			else
				return "Invalid line:\n#{line}"
		return null # no error

window.addEventListener 'message', (event) ->
	data = commands[event.data.command]?(event.data.data)
	message =
		target: 'prettifyRules'
		command: event.data.command
		return: data
	event.source.postMessage(message, event.origin)
	return
