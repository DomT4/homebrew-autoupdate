on run arguments
	if (count of arguments) is less than 3 then return

	set notificationTitle to item 1 of arguments
	set notificationSubtitle to item 2 of arguments
	set notificationMessage to item 3 of arguments

	-- Raw event codes keep this source compilable when Standard Additions
	-- terminology is unavailable in a non-interactive CI session.
	«event sysonotf» notificationMessage given «class appr»:notificationTitle, «class subt»:notificationSubtitle
	delay 2
end run
