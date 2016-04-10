Scenario = require '../src/scenario'
Gunslinger = require '../src/gunslinger'

incorrect_selectors = [
	'd'
	'*'
	'#woo'
	'header, footer'
]
correct_selector = 'article'

module.exports = (gameSessionId) ->
	number_of_players = 3

	scenario = new Scenario

	scenario
		.repeat number_of_players, (index) ->
			@db_account "fake-player-#{index}"

		.use_game_session gameSessionId

		.repeat number_of_players, (index) ->
			@spawn \
				"fake-player-#{index}",
				gameSessionId

		.async ->
			@repeat number_of_players, (index) ->
				@as "fake-player-#{index}", ->
					@wait_cell 'round_phase', 'in_progress'
					@repeat 10, -> [
						@wait Gunslinger.any_in_range [50, 75]
						do @refresh
						@exchange
							send:
								cell: 'selector'
								value: Gunslinger.any_of incorrect_selectors
							assert:
								match: ({ result }) -> result is 'negative'
					]
					@wait Gunslinger.any_in_range [100, 500]

					@exchange
						send:
							cell: 'selector'
							value: correct_selector
						assert:
							match: ({ result }) -> result is 'positive'

		.repeat number_of_players, (index) ->
			@end "fake-player-#{index}"

	scenario
