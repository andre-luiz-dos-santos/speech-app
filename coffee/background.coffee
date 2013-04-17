chrome.app.runtime.onLaunched.addListener ->
	chrome.app.window.create 'speech.html',
		id: 'speech'
		frame: 'none'
		width: 700
		height: 400
	return
