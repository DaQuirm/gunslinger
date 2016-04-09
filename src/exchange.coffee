window.WarpExchange =
	received: {}
	done: no

	capture: (ids) ->
		entities = window.app.warp_client.entities
		for id, entity of entities when id in ids
			do (id) =>
				entity.link.onvalue.add ((value) =>
					@received[id] = value
					entities[id].link.onvalue.remove 'capture'
					if Object.keys @received is ids.length
						@done = yes
					), 'capture'

	reset: ->
		@received = {}
		@done = no
