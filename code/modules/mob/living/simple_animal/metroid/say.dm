/mob/living/simple_animal/metroid/Hear(message, atom/movable/speaker, message_langs, raw_message, radio_freq, spans)
	if(speaker != src && !radio_freq)
		if (speaker in Friends)
			speech_buffer = list()
			speech_buffer += speaker
			speech_buffer += lowertext(html_decode(message))
	..()
