CSON     = require 'cson'
Scenario = require '../src/scenario'
Gunslinger = require '../src/gunslinger'

GameSessionCommand = require '../models/game-session-command'
RoundPhase = require '../models/round-phase'

incorrect_selectors = [
	'd'
	'*'
	'#woo'
	'header, footer'
]
correct_selector = 'article'

puzzles = CSON.load "#{__dirname}/../fixtures/puzzles.cson"

scenario = new Scenario

NUMBER_OF_PLAYERS = 3
NUMBER_OF_ITERATIONS = 10

scenario
	.db_cleanup 'users', 'gamesessions', 'puzzles'

	.db_account 'fake-game-master'

	.repeat NUMBER_OF_PLAYERS, (index) ->
		@db_account "fake-player-#{index}"

	.db_puzzles puzzles

	.db_game_session 'test-game', 'fake-game-master'

	.service()

	.spawn \
		'fake-game-master',
		'test-game'

	.repeat NUMBER_OF_PLAYERS, (index) ->
		@as 'fake-game-master', ->
			@exchange
				capture:
					'fake-game-master':
						players: ({ data: { items: [player] } }) ->
							player.display_name is "fake-player-#{index}"

				action: ->
					@spawn \
						"fake-player-#{index}",
						'test-game'

	.as 'fake-game-master', ->
		@wait_cell 'round_phase', RoundPhase.WAIT_SCREEN

		@send 'command',
			new GameSessionCommand GameSessionCommand.START_ROUND, puzzle_index: 0

	.async ->
		@repeat NUMBER_OF_PLAYERS, (index) ->
			@as "fake-player-#{index}", ->
				@wait_cell 'round_phase', RoundPhase.IN_PROGRESS
				@repeat NUMBER_OF_ITERATIONS, -> [
					@wait Gunslinger.any_in_range [50, 75]

					do @refresh

					@exchange
						capture:
							"fake-player-#{index}":
								match: ({ result }) -> result is 'negative'
						send:
							selector: Gunslinger.any_of incorrect_selectors
				]
				@wait Gunslinger.any_in_range [100, 500]

				@exchange
					capture:
						"fake-player-#{index}":
							match: ({ result }) -> result is 'positive'
					send:
						selector: correct_selector

	.repeat NUMBER_OF_PLAYERS, (index) ->
		@end "fake-player-#{index}"

	.end 'fake-game-master'

	.kill_service()

	.db_cleanup 'users', 'gamesessions', 'puzzles'

module.exports = scenario
