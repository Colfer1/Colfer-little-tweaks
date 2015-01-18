/*
 * Holds procs designed to change one type of value, into another.
 * Contains:
 *			hex2num & num2hex
 *			text2list & list2text
 *			file2list
 *			angle2dir
 *			angle2text
 *			worldtime2text
 */

// Returns an integer given a hexadecimal number string as input.
/proc/hex2num(hex)
	if (!istext(hex))
		return

	var/num   = 0
	var/power = 1
	var/i     = length(hex)

	while (i)
		var/char = text2ascii(hex, i)
		switch(char)
			if(48)                                  // 0 -- do nothing
			if(49 to 57) num += (char - 48) * power // 1-9
			if(97,  65)  num += power * 10          // A
			if(98,  66)  num += power * 11          // B
			if(99,  67)  num += power * 12          // C
			if(100, 68)  num += power * 13          // D
			if(101, 69)  num += power * 14          // E
			if(102, 70)  num += power * 15          // F
			else
				return
		power *= 16
		i--
	return num

// Returns the hex value of a number given a value assumed to be a base-ten value
/proc/num2hex(num, digits)
	if (digits == null)
		digits = 2

	if (!isnum(num))
		return

	// hex is our return value, to which each hex-digit of num is appended to.
	var/hex   = ""
	var/power = -4
	var/n     = 1

	// Figure out power. (power of 2)
	while (n < num)
		power += 4
		n     *= 16

	// Note that we have to start appending to hex with the most-significant digits.
	while (power >= 0)
		var/m  = (num >> power) & 15
		hex   += ascii2text(m + (m < 10 ? 48 : 87)) // Provided by the IconProcs library.
		power -= 4

	// Append zeroes to make sure that hex is atleast digits long.
	var/left = length(hex) - digits
	while (left-- > 0)
		hex = text("0[]", hex)

	return hex

// Concatenates a list of strings into a single string.  A seperator may optionally be provided.
/proc/list2text(list/ls, sep)
	if (ls.len <= 1) // Early-out code for empty or singleton lists.
		return ls.len ? ls[1] : ""

	var/l = ls.len // Made local for sanic speed.
	var/i = 0      // Incremented every time a list index is accessed.

	if (sep <> null)
		// Macros expand to long argument lists like so: sep, ls[++i], sep, ls[++i], sep, ls[++i], etc...
		#define S1  sep, ls[++i]
		#define S4  S1,  S1,  S1,  S1
		#define S16 S4,  S4,  S4,  S4
		#define S64 S16, S16, S16, S16

		. = "[ls[++i]]" // Make sure the initial element is converted to text.

		// Having the small concatenations come before the large ones boosted speed by an average of at least 5%.
		if (l-1 & 0x01) // 'i' will always be 1 here.
			. = text("[][][]", ., S1) // Append 1 element if the remaining elements are not a multiple of 2.
		if (l-i & 0x02)
			. = text("[][][][][]", ., S1, S1) // Append 2 elements if the remaining elements are not a multiple of 4.
		if (l-i & 0x04)
			. = text("[][][][][][][][][]", ., S4) // And so on....
		if (l-i & 0x08)
			. = text("[][][][][][][][][][][][][][][][][]", ., S4, S4)
		if (l-i & 0x10)
			. = text("[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]", ., S16)
		if (l-i & 0x20)
			. = text("[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]", ., S16, S16)
		if (l-i & 0x40)
			. = text("[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]", ., S64)
		while (l > i) // Chomp through the rest of the list, 128 elements at a time.
			. = text("[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]", ., S64, S64)

		#undef S64
		#undef S16
		#undef S4
		#undef S1
	else
		// Macros expand to long argument lists like so: ls[++i], ls[++i], ls[++i], etc...
		#define S1  ls[++i]
		#define S4  S1,  S1,  S1,  S1
		#define S16 S4,  S4,  S4,  S4
		#define S64 S16, S16, S16, S16

		. = "[ls[++i]]" // Make sure the initial element is converted to text.

		if (l-1 & 0x01) // 'i' will always be 1 here.
			. += S1 // Append 1 element if the remaining elements are not a multiple of 2.
		if (l-i & 0x02)
			. = text("[][][]", ., S1, S1) // Append 2 elements if the remaining elements are not a multiple of 4.
		if (l-i & 0x04)
			. = text("[][][][][]", ., S4) // And so on...
		if (l-i & 0x08)
			. = text("[][][][][][][][][]", ., S4, S4)
		if (l-i & 0x10)
			. = text("[][][][][][][][][][][][][][][][][]", ., S16)
		if (l-i & 0x20)
			. = text("[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]", ., S16, S16)
		if (l-i & 0x40)
			. = text("[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]", ., S64)
		while (l > i) // Chomp through the rest of the list, 128 elements at a time.
			. = text("[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]\
			          [][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]", ., S64, S64)

		#undef S64
		#undef S16
		#undef S4
		#undef S1

// Slower then list2text, but correctly processes associative lists.
proc/tg_list2text(list/list, glue=",")
	if (!istype(list) || !list.len)
		return
	var/output
	for(var/i=1 to list.len)
		output += (i!=1? glue : null)+(!isnull(list["[list[i]]"])?"[list["[list[i]]"]]":"[list[i]]")
	return output

// Converts a string into a list by splitting the string at each delimiter found. (discarding the seperator)
/proc/text2list(text, delimiter="\n")
	var/delim_len = length(delimiter)
	if (delim_len < 1) return list(text)
	. = list()
	var/last_found = 1
	var/found
	do
		found = findtext(text, delimiter, last_found, 0)
		. += copytext(text, last_found, found)
		last_found = found + delim_len
	while (found)

/proc/text2numlist(text, delimiter="\n")
	var/list/num_list = list()
	for(var/x in text2list(text, delimiter))
		num_list += text2num(x)
	return num_list

// Case Sensitive!
/proc/text2listEx(text, delimiter="\n")
	var/delim_len = length(delimiter)
	if (delim_len < 1) return list(text)
	. = list()
	var/last_found = 1
	var/found
	do
		found = findtextEx(text, delimiter, last_found, 0)
		. += copytext(text, last_found, found)
		last_found = found + delim_len
	while (found)

// Splits the text of a file at seperator and returns them in a list.
/proc/file2list(filename, seperator="\n")
	return text2list(return_file_text(filename),seperator)

// Turns a direction into text
/proc/num2dir(direction)
	switch (direction)
		if (1.0) return NORTH
		if (2.0) return SOUTH
		if (4.0) return EAST
		if (8.0) return WEST
		else
			world.log << "UNKNOWN DIRECTION: [direction]"

// Turns a direction into text
/proc/dir2text(direction)
	switch (direction)
		if (1.0)  return "north"
		if (2.0)  return "south"
		if (4.0)  return "east"
		if (8.0)  return "west"
		if (5.0)  return "northeast"
		if (6.0)  return "southeast"
		if (9.0)  return "northwest"
		if (10.0) return "southwest"

// Turns text into proper directions
/proc/text2dir(direction)
	switch (uppertext(direction))
		if ("NORTH")     return 1
		if ("SOUTH")     return 2
		if ("EAST")      return 4
		if ("WEST")      return 8
		if ("NORTHEAST") return 5
		if ("NORTHWEST") return 9
		if ("SOUTHEAST") return 6
		if ("SOUTHWEST") return 10

// Converts an angle (degrees) into an ss13 direction
/proc/angle2dir(var/degree)
	degree = (degree + 22.5) % 365 // 22.5 = 45 / 2
	if (degree < 45)  return NORTH
	if (degree < 90)  return NORTHEAST
	if (degree < 135) return EAST
	if (degree < 180) return SOUTHEAST
	if (degree < 225) return SOUTH
	if (degree < 270) return SOUTHWEST
	if (degree < 315) return WEST
	return NORTH|WEST

// Returns the north-zero clockwise angle in degrees, given a direction
/proc/dir2angle(var/D)
	switch (D)
		if (NORTH)     return 0
		if (SOUTH)     return 180
		if (EAST)      return 90
		if (WEST)      return 270
		if (NORTHEAST) return 45
		if (SOUTHEAST) return 135
		if (NORTHWEST) return 315
		if (SOUTHWEST) return 225

// Returns the angle in english
/proc/angle2text(var/degree)
	return dir2text(angle2dir(degree))

// Converts a blend_mode constant to one acceptable to icon.Blend()
/proc/blendMode2iconMode(blend_mode)
	switch (blend_mode)
		if (BLEND_MULTIPLY) return ICON_MULTIPLY
		if (BLEND_ADD)      return ICON_ADD
		if (BLEND_SUBTRACT) return ICON_SUBTRACT
		else                return ICON_OVERLAY

// Converts a rights bitfield into a string
/proc/rights2text(rights,seperator="")
	if (rights & R_BUILDMODE)   . += "[seperator]+BUILDMODE"
	if (rights & R_ADMIN)       . += "[seperator]+ADMIN"
	if (rights & R_BAN)         . += "[seperator]+BAN"
	if (rights & R_FUN)         . += "[seperator]+FUN"
	if (rights & R_SERVER)      . += "[seperator]+SERVER"
	if (rights & R_DEBUG)       . += "[seperator]+DEBUG"
	if (rights & R_POSSESS)     . += "[seperator]+POSSESS"
	if (rights & R_PERMISSIONS) . += "[seperator]+PERMISSIONS"
	if (rights & R_STEALTH)     . += "[seperator]+STEALTH"
	if (rights & R_REJUVINATE)  . += "[seperator]+REJUVINATE"
	if (rights & R_VAREDIT)     . += "[seperator]+VAREDIT"
	if (rights & R_SOUNDS)      . += "[seperator]+SOUND"
	if (rights & R_SPAWN)       . += "[seperator]+SPAWN"
	if (rights & R_MOD)         . += "[seperator]+MODERATOR"
	if (rights & R_MENTOR)      . += "[seperator]+MENTOR"
	return .

/proc/ui_style2icon(ui_style)
	switch (ui_style)
		if ("old")      return 'icons/mob/screen1_old.dmi'
		if ("Orange")   return 'icons/mob/screen1_Orange.dmi'
		if ("Midnight") return 'icons/mob/screen1_Midnight.dmi'
		else            return 'icons/mob/screen1_White.dmi'
