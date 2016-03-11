mongoose = require 'mongoose'

Gunslinger = require './src/gunslinger'
scenario = require './scenarios/example'

{connection} = mongoose.connect 'mongodb://localhost/cssqd-test'
connection.once 'open', ->

	Gunslinger.configure
		service_path: "#{__dirname}/../css-quickdraw-redux"

	Gunslinger.run scenario
		.then ->
			console.log 'all done!'
			do process.exit
			do done

	# .nightmare, ->
	# .refresh
