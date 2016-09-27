/obj/machinery/atmospherics/binary/valve
	icon = 'icons/obj/atmospherics/binary_devices.dmi'
	icon_state = "mvalve_map"
	name = "manual valve"
	desc = "A pipe valve"
	can_unwrench = 1
	var/open = 0
	var/frequency = 0
	var/id = null

/obj/machinery/atmospherics/binary/valve/open
	open = 1

//Separate this because we don't need to update pipe icons if we just are going to crank the handle
/obj/machinery/atmospherics/binary/valve/update_icon_nopipes(animation = 0)
	normalize_dir()
	icon_state = "mvalve_off"
	overlays.Cut()
	if(animation)
		overlays += getpipeimage('icons/obj/atmospherics/binary_devices.dmi', "mvalve_[open][!open]")
	else if(open)
		overlays += getpipeimage('icons/obj/atmospherics/binary_devices.dmi', "mvalve_on")

/obj/machinery/atmospherics/binary/valve/update_icon()
	update_icon_nopipes()
	var/connected = 0
	underlays.Cut()
	//Add non-broken pieces
	if(node1)
		connected = icon_addintact(node1, connected)
	if(node2)
		connected = icon_addintact(node2, connected)
	//Add broken pieces
	icon_addbroken(connected)

/obj/machinery/atmospherics/binary/valve/proc/open()
	open = 1
	update_icon_nopipes()
	parent1.update = 0
	parent2.update = 0
	parent1.reconcile_air()
	investigate_log("was opened by [usr ? key_name(usr) : "a remote signal"]", "atmos")
	return

/obj/machinery/atmospherics/binary/valve/proc/close()
	open = 0
	update_icon_nopipes()
	investigate_log("was closed by [usr ? key_name(usr) : "a remote signal"]", "atmos")
	return

/obj/machinery/atmospherics/binary/valve/proc/normalize_dir()
	if(dir==2)
		dir = 1
	else if(dir==8)
		dir = 4

/obj/machinery/atmospherics/binary/valve/attack_ai(mob/user)
	return

/obj/machinery/atmospherics/binary/valve/attack_hand(mob/user)
	add_fingerprint(usr)
	update_icon_nopipes(1)
	sleep(10)
	if(open)
		close()
	else
		open()


/obj/machinery/atmospherics/binary/valve/digital		// can be controlled by AI
	name = "digital valve"
	desc = "A digitally controlled valve."
	icon_state = "dvalve_map"
	var/open_panel = 0
	var/datum/wires/activation/digital_valve/wires = null
	var/activateable = 1

/obj/machinery/atmospherics/binary/valve/digital/New()
	wires = new(src)
	..()

/obj/machinery/atmospherics/binary/valve/digital/Deconstruct()
	for(var/colour in wireColours)
		wires.Detach(colour)
	..()

/obj/machinery/atmospherics/binary/valve/digital/attackby(var/obj/item/weapon/I, var/mob/user, params)
	if(istype(I, /obj/item/weapon/screwdriver))
		open_panel = !open_panel
		user << "<span class='notice'>You [open_panel ? "open" : "close"] the wire panel.</span>"
	else if(istype(I, /obj/item/weapon/wirecutters) || istype(I, /obj/item/device/multitool) || istype(I, /obj/item/device/assembly/signaler))
		wires.Interact(user)
	else
		..()

/obj/machinery/atmospherics/binary/valve/digital/attack_hand(mob/user)
	if(open_panel)
		wires.Interact(user)
	else
		if(activateable)
			..()

/obj/machinery/atmospherics/binary/valve/digital/attack_ai(mob/user)
	if(activateable)
		return src.attack_hand(user)

/obj/machinery/atmospherics/binary/valve/digital/update_icon_nopipes(animation)
	normalize_dir()
	if(stat & NOPOWER)
		icon_state = "dvalve_nopower"
		overlays.Cut()
		return
	icon_state = "dvalve_off"
	overlays.Cut()
	if(animation)
		overlays += getpipeimage('icons/obj/atmospherics/binary_devices.dmi', "dvalve_[open][!open]")
	else if(open)
		overlays += getpipeimage('icons/obj/atmospherics/binary_devices.dmi', "dvalve_on")
