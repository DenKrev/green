/datum/wires/activation
	wire_count = 1

var/const/WIRE_ACTIVATION_ACTIVATE = 1

/datum/wires/activation/proc/activate()
	return

/datum/wires/activation/UpdatePulsed(var/index)
	switch(index)
		if(WIRE_ACTIVATION_ACTIVATE)
			activate()

/datum/wires/activation/UpdateCut(var/index, var/mended)
	return

/datum/wires/activation/digital_valve
	holder_type = /obj/machinery/atmospherics/binary/valve/digital

/datum/wires/activation/digital_valve/CanUse(var/mob/living/L)
	var/obj/machinery/atmospherics/binary/valve/digital/P = holder
	if(P.open_panel)
		return 1
	return 0

/datum/wires/activation/digital_valve/UpdateCut(var/index, var/mended)
	switch(index)
		if(WIRE_ACTIVATION_ACTIVATE)
			var/obj/machinery/atmospherics/binary/valve/digital/P = holder
			P.activateable=mended

/datum/wires/activation/digital_valve/activate()
	var/obj/machinery/atmospherics/binary/valve/digital/P = holder
	if(P.open)
		P.close()
	else
		P.open()
