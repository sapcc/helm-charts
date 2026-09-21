package restrictedsu2

# allow only elevated groups (allowedGroups) or listed automation users (allowedUsers)
violation contains {"msg": msg} if {
	not user_allowed
	username := object.get(input.review, ["userInfo", "username"], "<unknown>")
	msg := sprintf("changes to restricted-su2 resources require elevated permissions, user %q is not authorized", [username])
}

user_allowed if {
	input.review.userInfo.groups[_] == input.parameters.allowedGroups[_]
}

user_allowed if {
	input.review.userInfo.username == input.parameters.allowedUsers[_]
}
