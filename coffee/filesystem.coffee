$ = jQuery

fsError = (e) ->
	if typeof(e.code) isnt 'number'
		return "Invalid fileSystem error object"
	for key, value of e
		if e.code is value and /_ERR$/.test(key)
			return key
	return "Unknown fileSystem error code: #{e.code}"

openFileSystem = do ->
	$fs = null
	return ->
		defer = $.Deferred()
		if $fs isnt null
			return defer.resolve($fs)
		success = (fs) => # fileSystem
			$fs = fs
			defer.resolve(fs)
			return
		error = (e) ->
			defer.reject("Cannot access filesystem: #{fsError(e)}", e)
			return
		webkitRequestFileSystem(PERSISTENT, 100*1024*1024, success, error)
		return defer

findFile = (name, opts) ->
	openFileSystem().then (fs) ->
		defer = $.Deferred()
		success = (fe) -> # fileEntry
			defer.resolve(fe)
			return
		error = (e) ->
			defer.reject("Cannot find #{name}: #{fsError(e)}", e)
			return
		fs.root.getFile(name, opts, success, error)
		return defer

@removeFile = (name) ->
	findFile(name, { create:false }).then (fe) ->
		defer = $.Deferred()
		success = ->
			defer.resolve()
			return
		error = (e) ->
			defer.reject("Cannot remove #{name}: #{fsError(e)}", e)
			return
		fe.remove(success, error)
		return defer

openFile = (name, opts) ->
	findFile(name, opts).then (fe) ->
		defer = $.Deferred()
		success = (fh) -> # fileHandle
			defer.resolve(fh)
			return
		error = (e) ->
			defer.reject("Cannot open #{name}: #{fsError(e)}", e)
			return
		fe.file(success, error)
		return defer

openFileWriter = (name, opts) ->
	findFile(name, opts).then (fe) ->
		defer = $.Deferred()
		success = (fw) -> # FileWriter
			defer.resolve(fw)
			return
		error = (e) ->
			defer.reject("Cannot open #{name} for writing: #{fsError(e)}", e)
			return
		fe.createWriter(success, error)
		return defer

@readFileHandle = (fh) ->
	defer = $.Deferred()
	reader = new FileReader()
	reader.onloadend = ->
		defer.resolve(reader.result)
		return
	reader.onerror = (e) ->
		defer.reject("Cannot read #{fh.name}: #{fsError(e)}", e)
		return
	reader.readAsText(fh)
	return defer

@readFile = (name, opts = { create:false }) ->
	openFile(name, opts).then (fh) ->
		readFileHandle(fh)
	# return openFile()'s chained defer

@writeFile = (name, data, opts = { create:true }) ->
	openFileWriter(name, opts).then (fw) ->
		defer = $.Deferred()
		fw.onwriteend = ->
			defer.resolve(data)
			return
		fw.onerror = (e) ->
			defer.reject("Cannot write #{name}: #{fsError(e)}", e)
			return
		blob = new Blob([data], { type:'text/plain' })
		fw.write(blob)
		return defer
