$ = jQuery
recognition = null
listening = false
currentPage = 'main'
prettifier = null
emptyStringRe = /^\s*$/

escapeHTML = (text) -> text
	.replace(/&/g,'&amp;')
	.replace(/</g,'&lt;')
	.replace(/>/g,'&gt;')

alert = null
$ ->
	template = $('div.alert')
	alert = (html) ->
		page = template.clone().insertBefore(template).show()
		$('.message', page).html(html.replace("\n", "<br>"))
		$('.ok', page).on 'click', (event) ->
			page.fadeOut -> page.remove()
			return

bug = (html) ->
	alert "Program error! Please report to developer!\nError: #{html}\n\nYou may try to continue by pressing OK."
	return $.Deferred.reject(escapeHTML(html))

doing = null
$ ->
	template = $('div.doing')
	doing = (message, defer) ->
		page = template.clone().insertBefore(template).show()
		$('.message', page).text(message)
		defer.always ->
			page.remove()
			return
		defer.fail (message) ->
			alert(escapeHTML(message))
			return
		# return defer
	return

# Controls the big button on the top left corner of the page.
# It's an incredibly ugly button, but it does its job.  :-)
changeStatus = (message, clickable = false) ->
	$('#start')
		.text(message)
		.prop('disabled', !clickable)
	return

# Insert text into the main input text area.
# Add spaces around text when necessary.
addTranscription = do ->
	endWithSpace = new RegExp('(^|\n| )$')
	startWithSpace = new RegExp('^( |\n|$)')
	return (text) ->
		input = $('#text')
		elem = input[0]
		startPosition = elem.selectionStart
		endPosition = elem.selectionEnd
		oldText = input.val()
		beforeText = oldText.substr(0, startPosition)
		afterText = oldText.substr(endPosition)
		text = text.replace(/^ +| +$/, '')
		text = " " + text unless endWithSpace.test(beforeText)
		text = text + " " unless startWithSpace.test(afterText)
		newText = beforeText + text + afterText
		input.val(newText).triggerHandler('change')
		newPosition = startPosition + text.length
		elem.setSelectionRange(newPosition, newPosition)
		return

$ ->
	if startRecognizer() is false then return
	new TextAutoSaver('text', $('#text'))
	new LanguagesSelectionPage()
	prettifier = new PrettifyRulesPage()
	new SnippetsPage()
	attachEventHandlers()
	changeStatus("Start", true)
	$('#header .edit').fadeTo('slow', 0.5)
	$('#main-page').layoutPage()
	return

$ -> # Main menu
	button = $('#menu-button')
	list = $('#menu-list')
	button.on 'click', (event) ->
		list.slideDown('fast')
		return
	list.on 'mouseleave', (event) ->
		list.hide()
		return
	$('#menu-quit').on 'click', (event) ->
		window.close()
		return
	return

$.fn.sumHeights = ->
	height = 0
	for elem in @
		height += $(elem).outerHeight(true)
	return height

$.fn.layoutPage = ->
	return @each ->
		$this = $(@)
		textarea = $this.children('textarea')
		if textarea.length is 1
			prevHeights = textarea.prevAll('.layout:visible').sumHeights() +
				$('#titlebar').outerHeight(true)
			nextHeights = textarea.nextAll('.layout:visible').sumHeights()
			# <tag> margin+border+padding
			# <div#content> has border-top: 0
			# 20 = ( <div#content> 0+3+3 + <textarea> 0+1+2 <button> 0+1+2 )*2 + 1 (mystery pixel)
			textarea.height(document.documentElement.clientHeight - prevHeights - nextHeights - 21 + 1)
			# <tag> margin+border+padding
			# 20 = ( <div#content> 0+3+3 + <textarea> 0+1+2 )*2
			textarea.width($(window).width() - 18)

$ ->
	window.onresize = (event) ->
		$('#' + currentPage + '-page').layoutPage()
		return

switchToPage = (name) ->
	currentPage = name
	document.body.scrollTop = 0
	$('body [id$=-page]:visible').hide()
	$('#' + name + '-page').fadeIn().layoutPage()
	# return the page's <div>

reLayoutPage = ->
	$('#' + currentPage + '-page').layoutPage()
	return

prettifyText = ->
	input = $('#text')
	doing "Prettifying", prettifier.magic(input.val())
	.done (text) ->
		input.val(text)
		input[0].setSelectionRange(0, input.val().length)
		input.focus()
		return
	# return defer

textCommand = (command) ->
	prettifyText()
	.done ->
		document.execCommand(command)
		return
	if listening
		toggleListening()
	return

toggleHelp = null
$ ->
	help = $('#help')
	toggleHelp = ->
		help.children().toggle()
		reLayoutPage()
		return

attachEventHandlers = ->
	$('body').on 'keydown', (event) ->
		if currentPage is 'main'
			if event.which in [27] # Escape
				toggleListening()
			# Show/hide help message on Control-H or F1
			if (event.which is 72 and event.ctrlKey is true) or event.which is 112
				toggleHelp()
			# Before copying (Control-C) or cutting (Control-X),
			# run 'prettify' if nothing is selected,
			# and then stop listening.
			if event.which is 67 and event.ctrlKey is true
				event.preventDefault()
				textCommand('copy')
			if event.which is 88 and event.ctrlKey is true
				event.preventDefault()
				textCommand('cut')
		return
	do (button = $("#start")) ->
		button.on 'click', (event) ->
			toggleListening()
			return
		return
	do (input = $('#text')) ->
		input.on 'select', (event) ->
			document.execCommand('copy')
			return
		$('#prettify').on 'click', (event) ->
			prettifyText()
			return
		return
	do (select = $('#snippets')) ->
		select.on 'change', (event) ->
			addTranscription(select.val())
			select.val('')
			return
		return
	return

toggleListening = ->
	if $("#start").prop('disabled') is true
		return # already starting or stopping
	if listening
		changeStatus("Stopping")
		recognition.stop()
	else
		changeStatus("Starting")
		recognition.lang = $('#language').val()
		recognition.start()
	return

startRecognizer = ->
	recognition = new webkitSpeechRecognition()
	recognition.continuous = true
	recognition.interimResults = true

	recognition.onstart = (event) ->
		changeStatus("Stop", true)
		$("#start").addClass('on')
		listening = true
		return

	recognition.onend = (event) ->
		changeStatus("Start", true)
		$("#start").removeClass('on')
		listening = false
		$('#interim').text("...")
		return

	recognition.onerror = (event) ->
		console.log event
		alert("Speech recognition error: #{event.error}")
		return

	recognition.onresult = (event) ->
		interim = ""
		i = event.resultIndex
		while i < event.results.length
			result = event.results[i]; i += 1
			if result.isFinal then addTranscription(result[0].transcript)
			else interim += result[0].transcript
		$('#interim').text(interim || "...")
		return

	return true

class Page
	constructor: ->
		@page = $('#' + @name + '-page')
		# Restore data
		doing "Loading", @get().then (data) => @parse(data)
		# Attach event handlers
		$('#menu-' + @name).on 'click', =>
			doing "Loading", @load().then => @open()
		$('#save-' + @name).on 'click', =>
			doing "Saving", @save().then => @close()
		$('#reset-' + @name).on 'click', =>
			doing "Resetting", @reset().then => @load()
	get: -> # Load data from storage
		defer = $.Deferred()
		chrome.storage.sync.get @name, (data) =>
			if chrome.runtime.lastError
				defer.reject("Error loading #{@name}: #{chrome.runtime.lastError.message}")
				return
			defer.resolve(data[@name] || @default)
			return
		return defer
	set: (data) -> # Save data to storage (and to main page)
		if data is @default
			return @reset() # defer
		@parse(data).then =>
			defer = $.Deferred()
			if typeof(err = @validate?()) is 'string'
				return defer.reject("Validation error for #{@name}: #{err}")
			obj = {}
			obj[@name] = data
			chrome.storage.sync.set obj, =>
				if chrome.runtime.lastError
					defer.reject("Error saving #{@name}: #{chrome.runtime.lastError.message}")
					return
				defer.resolve()
				return
			return defer
		# return @parse()'s chained promise object
	open: -> # Show this page
		switchToPage(@name)
		return
	close: -> # Back to main page
		switchToPage('main')
		return
	load: -> # storage to DOM
		$.Deferred().resolve()
	save: -> # DOM to storage
		$.Deferred().resolve()
	parse: -> # data to main page
		$.Deferred().resolve()
	reset: ->
		defer = $.Deferred()
		chrome.storage.sync.remove @name, =>
			if chrome.runtime.lastError
				defer.reject("Error removing #{@name}: #{chrome.runtime.lastError.message}")
				return
			defer.resolve()
			return
		parsing = @parse(@default)
		defer.then => parsing
		# 'remove' and 'parse' together, but on 'remove' failure, ignore @parse()'s result.

class SingleTextboxPage extends Page
	constructor: ->
		super
		@textarea = $('textarea', @page)
	open: -> # Show this page
		super
		@textarea.focus()
		return
	load: -> # storage to DOM
		@get().done (data) =>
			@textarea.val(data)
			return
		# return defer
	save: -> # DOM to storage
		@set(@textarea.val())
		# return defer

class LanguagesSelectionPage extends SingleTextboxPage
	name: 'langs'
	constructor: ->
		@default = """
			# The first word is the language code, used by the speech recognition engine.
			# The rest of the line is just a label for the language selection box.
			pt-BR Portuguese
			en-US English

			# What language code should be used for Esperanto?
			eo Esperanto
			eo-EO Esperanto
			"""
		createLanguageList 'lang', (code, language) =>
			@textarea.val("#{code} #{language}\n\n#{@textarea.val()}")
			return
		super
	validate: ->
		if @count() is 0
			return "At least one language must be specified."
		return null # no error
	parse: (data) ->
		defer = $.Deferred()
		select = $('#language').empty()
		for line in data.split(/\r*\n+/)
			if /^\s*(#|$)/.test(line)
				# Comment or empty
			else if mo = line.match(/^\s*(\S+)\s+(\S.*)$/)
				$('<option>')
					.text(mo[2] + " (" + mo[1] + ")")
					.attr('value', mo[1])
					.appendTo(select)
			else
				return defer.reject("Invalid line:\n#{ line }")
		defer.resolve()
	count: ->
		$('#language > option').length

class PrettifyRulesPage extends SingleTextboxPage
	name: 'rules'
	pending: null
	constructor: ->
		@default = """
			# Capitalize these words anywhere.
			[ /\\b(google|microsoft|portuguese|english|fastville|esperanto|português|inglês)\\b/g, capitalize ]
			[ /(free|open|net|dragon)bsd\\b/gi, function(_, b) { return capitalize(b) + 'BSD' } ]

			# Capitalize the first letter of each line.
			[ /^\\w/gm, capitalize ]

			# Capitalize the first letter after .?!
			[ /([.?!] )(\\w)/g, function(_, b, a) { return b + capitalize(a) } ]

			# Commonly misrecognized words.
			[ /\\big\\b/gi, 'e' ]
			[ /\\buol\\b/gi, 'ou' ]
			"""
		@iframe = $.Deferred()
		addEventListener 'message', (event) =>
			if event.data.target is 'prettifyRules'
				@receive(event.data)
			return
		super
	send: (command, data = null) ->
		if @pending isnt null
			return bug("PrettifyRulesPage.pending is set") # defer
		@iframe.then (iframe) =>
			@pending = $.Deferred().always => @pending = null; return
			message = command: command, data: data
			iframe.contentWindow.postMessage(message, '*')
			return @pending
		# return @iframe's chained promise object
	receive: (data) ->
		switch data.command
			when 'load'
				@iframe.resolve($('#prettifier')[0])
			when 'parse'
				if data.return is null then @pending.resolve()
				else @pending.reject(data.return)
			when 'magic'
				@pending.resolve(data.return)
		return
	parse: (data) ->
		@send('parse', data)
		# return defer
	magic: (text) ->
		@send('magic', text)
		# return defer

class SnippetsPage extends SingleTextboxPage
	name: 'snippets'
	constructor: ->
		@default = """
			?
			!
			.
			,
			:-)
			:-(
			"""
		super
	parse: (data) ->
		defer = $.Deferred()
		select = $('#snippets').empty()
		$('<option>')
			.attr('value', "")
			.appendTo(select)
		for line in data.split(/\r*\n+/)
			if /^\s*(#|$)/.test(line)
				# Comment or empty
			else
				$('<option>')
					.text(line)
					.attr('value', line)
					.appendTo(select)
		defer.resolve()

class ValueAutoSaver
	timerId: null
	constructor: (@name, @input) ->
		@load()
		@timeoutHandler = => @timeout()
		@input.on 'change keyup', => @start(); return
	load: -> # fileSystem to DOM
		readFile(@name)
		.then null, (error, e) ->
			if e.code is e.NOT_FOUND_ERR
				return $.Deferred().resolve("")
			return arguments # no change
		.done (data) =>
			@input.val(data)
			return
		# return readFile()'s chained defer
	save: -> # DOM to fileSystem
		removeFile(@name)
		.then null, (error, e) ->
			if e.code is e.NOT_FOUND_ERR
				return $.Deferred().resolve()
			return arguments # no change
		.then =>
			if (data = @input.val()) is ""
				return "" # no data to save, resolve defer
			return writeFile(@name, data) # defer
		# return removeFile()'s chained defer
	start: ->
		if @timerId isnt null then clearTimeout(@timerId)
		@timerId = setTimeout(@timeoutHandler, 1000)
	timeout: do ->
		saving = null
		return ->
			@timerId = null
			if saving is null
 				saving = @save().always -> saving = null; return
 			else if saving isnt 'scheduled' # and isnt null
 				saving.always => @save(); return
 				saving = 'scheduled'
			return

class TextAutoSaver extends ValueAutoSaver
	constructor: ->
		super
		@div = $('#autosave')
	load: ->
		doing "Loading last value", super
		# return defer
	save: ->
		@div.text('Saving...')
		super.done =>
			now = new Date()
			@div.text('Last saved: ' + now.toLocaleTimeString())
			return
		.fail (message) =>
			@div.text(message)
			return
		# return defer
	start: ->
		@div.text('May contain unsaved work!')
		super

$ -> # Drag and drop files into any text area
	$('body').on 'dragenter', 'textarea', (event) ->
		$(event.target).addClass('dragover')
		return
	$('body').on 'dragleave drop', 'textarea', (event) ->
		$(event.target).removeClass('dragover')
		return
	$('body').on 'drop', 'textarea', (event) ->
		data = event.originalEvent.dataTransfer
		if typeof(data) isnt 'object'
			return # possible?
		if data.files?.length > 0 # dropping files
			event.stopPropagation()
			event.preventDefault()
			if data.files.length > 1
				alert("Only one file may be dropped here")
				return
			file = data.files[0]
			doing "Reading file #{file.name}", readFileHandle(file).done (data) ->
				$(event.target).val(data).triggerHandler('change')
				return
			return # file dropped successfully
		return
	return
