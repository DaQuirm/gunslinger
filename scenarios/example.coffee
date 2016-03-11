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

scenario
	.db_cleanup 'users', 'gamesessions', 'puzzles'

	.db_account 'fake-game-master'
	.db_account 'fake-player'

	.db_puzzles puzzles

	.db_game_session 'test-game', 'fake-game-master'

	.service()

	.spawn \
		'fake-game-master',
		'game-master',
		'test-game'

	.spawn \
		'fake-player',
		'game',
		'test-game'

	.as 'fake-game-master'
	.wait_cell 'round_phase', 'wait_screen'
	.send 'command',
		new GameSessionCommand GameSessionCommand.START_ROUND, puzzle_index: 1

	.as 'fake-player'
	.wait_cell 'round_phase', 'in_progress'
	.wait_random [100, 300]
	.repeat 10, -> [
		@send_any 'selector', incorrect_selectors
		@wait_random [100, 500]
		@check_cells 'match', ({ result }) ->
			result is 'negative'
	]
	.wait_random [500, 750]
	.send 'selector', correct_selector

	.end 'fake-player'
	.end 'fake-game-master'

	.kill_service()

	.db_cleanup 'users', 'gamesessions', 'puzzles'

module.exports = scenario
