/obj/machinery/power/thermal_gen
	name = "thermal generator"
	desc = "Thermoelectric generator"
	icon = 'icons/obj/power.dmi'
	icon_state = "portgen0"
	density = 1
	anchored = 0
	use_power = 0

	var/active = 0
	
	var/heat = 0
	var/heat_capacity = 1000
	var/min_heat_per_power_cycle = 1
	var/max_heat_per_power_cycle = 10

	var/heat_agent = 0
	var/heat_agent_capacity = 50000
	var/min_heat_agent_per_power_cycle = 1

	var/min_power_per_power_cycle = 500 //TODO: adjust it to better suitting value

/obj/machinery/power/thermal_gen/proc/handleInactive()
	return

//Handle heat generation
/obj/machinery/power/thermal_gen/proc/BurnCycle()
	return 1

//Handle heat to power conversion. Return generated power
/obj/machinery/power/thermal_gen/proc/PowerCycle()
	var/conv_coeff=0.1+3.9*heat/heat_capacity
	var/mod_max_heat_per_power_cycle=max_heat_per_power_cycle*conv_coeff
	if(heat<min_heat_per_power_cycle||heat_agent<min_heat_agent_per_power_cycle)
		return 0
	var/tmp_heat=min(heat,mod_max_heat_per_power_cycle)
	var/tmp_heat_agent=min(heat_agent,min_heat_agent_per_power_cycle*(tmp_heat/min_heat_per_power_cycle))
	tmp_heat=min_heat_per_power_cycle*(tmp_heat_agent/min_heat_agent_per_power_cycle)
	heat-=tmp_heat
	heat_agent-=tmp_heat_agent
	return min_power_per_power_cycle*(tmp_heat/min_heat_per_power_cycle)

//Handle overheat behaviour
/obj/machinery/power/thermal_gen/proc/Overheat()
	return 0
/obj/machinery/power/thermal_gen/proc/LoseHeat()
	heat-=20*heat/heat_capacity
	return
/obj/machinery/power/thermal_gen/process()
	if(active && anchored && BurnCycle())
		src.updateDialog()
	else
		active = 0
		icon_state = initial(icon_state)
		handleInactive()
	if(anchored && powernet)
		add_avail(PowerCycle())
	LoseHeat()
	if(heat>heat_capacity)
		Overheat()

/obj/machinery/power/thermal_gen/attack_hand(mob/user as mob)
	if(..())
		return
	if(!anchored)
		return

/obj/machinery/power/thermal_gen/attackby(var/obj/item/O as obj, var/mob/user as mob, params)
	if(O.is_open_container()&&O.reagents&&O.reagents.has_reagent("water"))
		var/amount = O.reagents.get_reagent_amount("water")
		O.reagents.clear_reagents()
		heat_agent=min(heat_agent_capacity,heat_agent+amount*100)
		user<<"You add water to [src]"

/obj/machinery/power/thermal_gen/examine(mob/user)
	..()
	user << "It is[!active?"n\'t":""] heating."

/obj/machinery/power/thermal_gen/plasma
	name = "\improper Portable PTEG"
	var/sheets = 0
	var/max_sheets = 100
	var/sheet_name = ""
	var/sheet_path = /obj/item/stack/sheet/mineral/plasma
	var/board_path = "/obj/item/weapon/circuitboard/pteg"
	var/sheet_left = 0 // How much is left of the sheet
	var/time_per_sheet = 5000
	var/burning_power = 10
	var/burning_regulator = 1

/obj/machinery/power/thermal_gen/plasma/initialize()
	..()
	if(anchored)
		connect_to_network()

/obj/machinery/power/thermal_gen/plasma/New()
	..()
	component_parts = list()
	component_parts += new /obj/item/weapon/stock_parts/matter_bin(src)
	component_parts += new /obj/item/weapon/stock_parts/micro_laser(src)
	component_parts += new /obj/item/stack/cable_coil(src, 1)
	component_parts += new /obj/item/stack/cable_coil(src, 1)
	component_parts += new /obj/item/weapon/stock_parts/manipulator(src)
	component_parts += new board_path(src)
	var/obj/sheet = new sheet_path(null)
	sheet_name = sheet.name
	RefreshParts()

/obj/machinery/power/thermal_gen/plasma/proc/DropFuel()
	if(sheets)
		var/fail_safe = 0
		while(sheets > 0 && fail_safe < 100)
			fail_safe += 1
			var/obj/item/stack/sheet/S = new sheet_path(loc)
			var/amount = min(sheets, S.max_amount)
			S.amount = amount
			sheets -= amount

/obj/machinery/power/thermal_gen/plasma/Destroy()
	DropFuel()
	..()

/obj/machinery/power/thermal_gen/plasma/RefreshParts()
	var/temp_rating = 0
	var/burn_coeff = 0
	max_sheets = 0
	for(var/obj/item/weapon/stock_parts/SP in component_parts)
		if(istype(SP, /obj/item/weapon/stock_parts/matter_bin))
			max_sheets += SP.rating * SP.rating * 50
		else if(istype(SP, /obj/item/weapon/stock_parts/manipulator))
			temp_rating += SP.rating
		else if(istype(SP, /obj/item/weapon/stock_parts/micro_laser))
			burn_coeff += SP.rating
	max_heat_per_power_cycle = round(initial(max_heat_per_power_cycle) * temp_rating * 2)
	burning_power=initial(burning_power)*burn_coeff*2

/obj/machinery/power/thermal_gen/plasma/examine(mob/user)
	..()
	user << "<span class='notice'>The generator has [sheets] units of [sheet_name] fuel left.</span>"
	if(crit_fail) user << "<span class='danger'>The generator seems to have broken down.</span>"

/obj/machinery/power/thermal_gen/plasma/BurnCycle()
	if(!(sheet_left>0||sheets>0)) //if no fuel left then we're not burning anymore. Tis's sad
		return 0
	var/burn_coeff = burning_regulator*burning_power
	var/burn_plan = burn_coeff/time_per_sheet //how much plasma we plan to burn
	var/failsafe = 5 //if we burn more than 5 plasma sheets per tick, then there's probally some shit going on
	while(burn_plan>0&&failsafe-->0)//just to be sure it wont loop forever
		if(!(sheet_left>0||sheets>0)) //we have burned all plasma we had
			return 1
		if(sheet_left<=0)
			sheet_left=1
			sheets-=1
		var/cur_sheet_usage=min(sheet_left,burn_plan)
		sheet_left-=cur_sheet_usage
		burn_plan-=cur_sheet_usage
		heat+=cur_sheet_usage*time_per_sheet
	return 1

/obj/machinery/power/thermal_gen/plasma/handleInactive()

	if (heat > 0)
		heat = max(heat - 2, 0)
		src.updateDialog()

/obj/machinery/power/thermal_gen/plasma/Overheat()
	if(heat_agent>0)
		var/tmp_amount=min(heat_agent,100)
		tmp_amount=min(heat-heat_capacity,tmp_amount)
		heat_agent-=tmp_amount
		heat-=tmp_amount
		//TODO: add smoke here
	if(heat>heat_capacity)
		heat=max(0,heat-2)
	if(heat>heat_capacity*1.5)
		if(sheets||sheet_left)
			explosion(src.loc, 2, 5, 2, 7)
		else
			explosion(src.loc,0,4,1,3)

/obj/machinery/power/thermal_gen/plasma/attackby(var/obj/item/O as obj, var/mob/user as mob, params)
	if(istype(O, sheet_path))
		var/obj/item/stack/addstack = O
		var/amount = min((max_sheets - sheets), addstack.amount)
		if(amount < 1)
			user << "<span class='notice'>The [src.name] is full!</span>"
			return
		user << "<span class='notice'>You add [amount] sheets to the [src.name].</span>"
		sheets += amount
		addstack.use(amount)
		updateUsrDialog()
		return
	else if(!active)

		if(exchange_parts(user, O))
			return

		if(istype(O, /obj/item/weapon/wrench))

			if(!anchored && !isinspace())
				connect_to_network()
				user << "<span class='notice'>You secure the generator to the floor.</span>"
				anchored = 1
			else if(anchored)
				disconnect_from_network()
				user << "<span class='notice'>You unsecure the generator from the floor.</span>"
				anchored = 0

			playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)

		else if(istype(O, /obj/item/weapon/screwdriver))
			panel_open = !panel_open
			playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
			if(panel_open)
				user << "<span class='notice'>You open the access panel.</span>"
			else
				user << "<span class='notice'>You close the access panel.</span>"
		else if(istype(O, /obj/item/weapon/crowbar) && panel_open)
			default_deconstruction_crowbar(O)
	..()



/obj/machinery/power/thermal_gen/plasma/attack_hand(mob/user as mob)
	..()
	if (!anchored)
		return

	interact(user)

/obj/machinery/power/thermal_gen/plasma/attack_ai(mob/user as mob)
	interact(user)

/obj/machinery/power/thermal_gen/plasma/attack_paw(mob/user as mob)
	interact(user)

/obj/machinery/power/thermal_gen/plasma/interact(mob/user)
	if (get_dist(src, user) > 1 )
		if (!istype(user, /mob/living/silicon/ai))
			user.unset_machine()
			user << browse(null, "window=thermal_gen")
			return

	user.set_machine(src)

	var/dat = text("<b>[name]</b><br>")
	if (active)
		dat += text("Burner: <A href='?src=\ref[src];action=disable'>On</A><br>")
	else
		dat += text("Burner: <A href='?src=\ref[src];action=enable'>Off</A><br>")
	dat += text("Burner regulator: <A href='?src=\ref[src];action=adjust_regulator'>[burning_regulator]</A><br>")
	dat += text("[capitalize(sheet_name)]: [sheets] - <A href='?src=\ref[src];action=eject'>Eject</A><br>")
	var/stack_percent = round(sheet_left * 100, 1)
	dat += text("Current stack: [stack_percent]% <br>")
	dat += text("Heat: [heat]<br>")
	dat += text("Heat agent: [heat_agent]<br>")
	dat += "<br><A href='?src=\ref[src];action=close'>Close</A>"
	user << browse("[dat]", "window=thermal_gen")
	onclose(user, "thermal_gen")

/obj/machinery/power/thermal_gen/plasma/Topic(href, href_list)
	if(..())
		return

	src.add_fingerprint(usr)
	if(href_list["action"])
		if(href_list["action"] == "enable")
			if(!active)
				active = 1
				icon_state = "portgen1"
				src.updateUsrDialog()
		if(href_list["action"] == "disable")
			if (active)
				active = 0
				icon_state = "portgen0"
				src.updateUsrDialog()
		if(href_list["action"] == "eject")
			if(!active)
				DropFuel()
				src.updateUsrDialog()
		if(href_list["action"]=="adjust_regulator")
			var/new_position = input("Please input new regulator position \[0-6\].", name, burning_regulator) as num
			if(..())
				return
			burning_regulator = Clamp(round(new_position, 0.01), 0, 6)
		if (href_list["action"] == "close")
			usr << browse(null, "window=thermal_gen")
			usr.unset_machine()