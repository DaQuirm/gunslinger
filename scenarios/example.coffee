CSON     = require 'cson'
Scenario = require '../src/scenario'
Gunslinger = require '../src/gunslinger'

GameSessionCommand = require '../models/game-session-command'

incorrect_selectors = [
	'd'
	'*'
	'#woo'
	'header, footer'
]
correct_selector = '.match'

puzzles = CSON.load "#{__dirname}/../fixtures/puzzles.cson"

scenario = new Scenario

number_of_players = 3

scenario
	.db_cleanup 'users', 'gamesessions', 'puzzles'

	.db_account 'fake-game-master'

	.repeat number_of_players, (index) ->
		@db_account "fake-player##{index}"

	.db_puzzles puzzles

	.db_game_session 'test-game', 'fake-game-master'

	.service()

	.spawn \
		'fake-game-master',
		'game-master',
		'test-game'

	.repeat number_of_players, (index) ->
		@spawn \
			"fake-player##{index}",
			'game',
			'test-game'

	.as 'fake-game-master', ->
		@wait_cell 'round_phase', 'wait_screen'
		@send 'command',
			new GameSessionCommand GameSessionCommand.START_ROUND, puzzle_index: 1

	.async ->
		@repeat number_of_players, (index) ->
			@as "fake-player##{index}", ->
				@wait_cell 'round_phase', 'in_progress'
				@wait Gunslinger.any_in_range [100, 150]
				@repeat 10, -> [
					@send 'selector', Gunslinger.any_of incorrect_selectors
					@wait Gunslinger.any_in_range [100, 200]
					@check_cells 'match', ({ result }) ->
						result is 'negative'
				]
				@wait Gunslinger.any_in_range [100, 500]
				@send 'selector', correct_selector

	.repeat number_of_players, (index) ->
		@end "fake-player##{index}"

	.end 'fake-game-master'

	.kill_service()

	.db_cleanup 'users', 'gamesessions', 'puzzles'

module.exports = scenario
