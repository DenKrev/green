/obj/item/weapon/picket_sign
	icon_state = "picket"
	name = "blank picket sign"
	desc = "It's blank"
	force = 5
	w_class = 4.0
	attack_verb = list("bashed","smacked")
	burn_state = 0


	var/label = ""
	var/last_wave = 0

/obj/item/weapon/picket_sign/attackby(obj/item/weapon/W, mob/user, params)
	if(istype(W, /obj/item/weapon/pen) || istype(W, /obj/item/toy/crayon))
		var/txt = sanitize_russian(stripped_input(user, "What would you like to write on the sign?", "Sign Label", null , 30))
		if(txt)
			label = txt
			src.name = "[label] sign"
			desc =	"It reads: [label]"

	else if(istype(W, /obj/item/weapon/wrench))
		user << "<span class='notice'>You start disassembling [src]...</span>"
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
		if(do_after(user, 10))
			playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
			qdel(src)
			return
	..()

/obj/item/weapon/picket_sign/attack_self(mob/living/carbon/human/user)
	if( last_wave + 20 < world.time )
		last_wave = world.time
		if(label)
			user.visible_message("<span class='warning'>[user] ����������� ��������� � �������� \"[label]\".</span>")
		else
			user.visible_message("<span class='warning'>[user] ����������� ������ ���������.</span>")
		user.changeNext_move(CLICK_CD_MELEE)

/datum/table_recipe/picket_sign
	name = "Picket Sign"
	result = /obj/item/weapon/picket_sign
	reqs = list(/obj/item/stack/rods = 1,
				/obj/item/stack/sheet/cardboard = 2)
	time = 80