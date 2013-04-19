$ = jQuery

# List extracted from
# https://github.com/GoogleChrome/webplatform-samples/blob/master/webspeechdemo/webspeechdemo.html
languagesList = [
	['Afrikaans',       ['af-ZA']],
	['Bahasa Indonesia',['id-ID']],
	['Bahasa Melayu',   ['ms-MY']],
	['Català',          ['ca-ES']],
	['Čeština',         ['cs-CZ']],
	['Deutsch',         ['de-DE']],
	['English',         ['en-AU', 'Australia'],
	                 ['en-CA', 'Canada'],
	                 ['en-IN', 'India'],
	                 ['en-NZ', 'New Zealand'],
	                 ['en-ZA', 'South Africa'],
	                 ['en-GB', 'United Kingdom'],
	                 ['en-US', 'United States']],
	['Español',         ['es-AR', 'Argentina'],
	                 ['es-BO', 'Bolivia'],
	                 ['es-CL', 'Chile'],
	                 ['es-CO', 'Colombia'],
	                 ['es-CR', 'Costa Rica'],
	                 ['es-EC', 'Ecuador'],
	                 ['es-SV', 'El Salvador'],
	                 ['es-ES', 'España'],
	                 ['es-US', 'Estados Unidos'],
	                 ['es-GT', 'Guatemala'],
	                 ['es-HN', 'Honduras'],
	                 ['es-MX', 'México'],
	                 ['es-NI', 'Nicaragua'],
	                 ['es-PA', 'Panamá'],
	                 ['es-PY', 'Paraguay'],
	                 ['es-PE', 'Perú'],
	                 ['es-PR', 'Puerto Rico'],
	                 ['es-DO', 'República Dominicana'],
	                 ['es-UY', 'Uruguay'],
	                 ['es-VE', 'Venezuela']],
	['Euskara',         ['eu-ES']],
	['Français',        ['fr-FR']],
	['Galego',          ['gl-ES']],
	['Hrvatski',        ['hr_HR']],
	['IsiZulu',         ['zu-ZA']],
	['Íslenska',        ['is-IS']],
	['Italiano',        ['it-IT', 'Italia'],
	                 ['it-CH', 'Svizzera']],
	['Magyar',          ['hu-HU']],
	['Nederlands',      ['nl-NL']],
	['Norsk bokmål',    ['nb-NO']],
	['Polski',          ['pl-PL']],
	['Português',       ['pt-BR', 'Brasil'],
	                 ['pt-PT', 'Portugal']],
	['Română',          ['ro-RO']],
	['Slovenčina',      ['sk-SK']],
	['Suomi',           ['fi-FI']],
	['Svenska',         ['sv-SE']],
	['Türkçe',          ['tr-TR']],
	['български',       ['bg-BG']],
	['Pусский',         ['ru-RU']],
	['Српски',          ['sr-RS']],
	['한국어',            ['ko-KR']],
	['中文',             ['cmn-Hans-CN', '普通话 (中国大陆)'],
	                 ['cmn-Hans-HK', '普通话 (香港)'],
	                 ['cmn-Hant-TW', '中文 (台灣)'],
	                 ['yue-Hant-HK', '粵語 (香港)']],
	['日本語',           ['ja-JP']],
	['Lingua latīna',   ['la']]
];

@createLanguageList = (name, callback) ->
	languageSelect = $('#' + name + '-names')
	dialectSelect = $('#' + name + '-dialects').hide()
	languageIndex = null # currently selected language index
	populateLanguageSelect = ->
		languageSelect.empty()
		$('<option>').appendTo(languageSelect).text('≡')
		for language, index in languagesList
			$('<option>').appendTo(languageSelect)
				.val(index).text(language[0])
		return
	populateDialectSelect = (languageIndex) ->
		dialectSelect.empty()
		$('<option>').appendTo(dialectSelect).text('≡')
		for dialect in languagesList[languageIndex][1..]
			$('<option>').appendTo(dialectSelect)
				.val(dialect[0]).text(dialect[1])
		return
	languageSelect.on 'change', (event) ->
		languageOption = $(':selected', languageSelect)
		return unless languageIndex = languageOption.val()
		if languagesList[languageIndex][1].length is 1
			dialectSelect.hide()
			callback(languagesList[languageIndex][1][0], languagesList[languageIndex][0])
			languageOption.prop('selected', false)
		else
			dialectSelect.show()
			populateDialectSelect(languageIndex)
		return
	dialectSelect.on 'change', (event) ->
		dialectOption = $(':selected', dialectSelect)
		return unless languageCode = dialectOption.val()
		callback(languageCode, languagesList[languageIndex][0] + ' - ' + dialectOption.text())
		dialectOption.prop('selected', false)
		return
	populateLanguageSelect()
	return
