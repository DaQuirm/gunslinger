CSON     = require 'cson'
Scenario = require '../src/scenario'

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
		'test-game'

	.repeat number_of_players, (index) ->
		@spawn \
			"fake-player##{index}",
			'test-game',
			yes

	.as 'fake-game-master', ->
		@wait_cell 'round_phase', 'wait_screen'
		@send 'command',
			new GameSessionCommand GameSessionCommand.START_ROUND, puzzle_index: 1

	.async ->
		@repeat number_of_players, (index) ->
			@as "fake-player##{index}", ->
				@wait_cell 'round_phase', 'in_progress'
				@wait_random [100, 150]
				@repeat 10, -> [
					@send_any 'selector', incorrect_selectors
					@wait_random [100, 200]
					@check_cells 'match', ({ result }) ->
						result is 'negative'
				]
				@wait_random [100, 500]
				@send 'selector', correct_selector

	.repeat number_of_players, (index) ->
		@end "fake-player##{index}"

	.end 'fake-game-master'

	.kill_service()

	.db_cleanup 'users', 'gamesessions', 'puzzles'

module.exports = scenario
