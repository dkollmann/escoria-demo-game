# A statement in an ESC file
extends RefCounted
class_name ESCStatement


# Emitted when the event did finish running
signal finished(event: ESCStatement, return_code: int)

# Emitted when the event was interrupted
signal interrupted(event: ESCStatement, return_code: int)


# The list of ESC commands
var statements: Array[ESCStatement] = []

# The source of this statement, e.g. an ESC script or a class.
var source: String = ""

# Indicates whether this event was interrupted.
var _is_interrupted: bool = false


# Check whether the statement should be run based on its conditions
func is_valid() -> bool:
	for condition in self.conditions:
		if not (condition as ESCCondition).run():
			return false
	return true


# Execute this statement and return its return code
func run() -> int:
	var final_rc = ESCExecution.RC_OK
	var current_statement: ESCStatement

	for statement in statements:
		current_statement = statement

		if _is_interrupted:
			final_rc = ESCExecution.RC_INTERRUPTED
			statement.interrupt()
			emit_signal("interrupted", self, statement, final_rc)
			return final_rc

		if statement.is_valid():
			var rc := await statement.run()
			escoria.logger.debug(
				self,
				"Statement (%s) was completed." % statement
			)
			if rc == ESCExecution.RC_REPEAT:
				return await self.run()
			elif rc != ESCExecution.RC_OK:
				final_rc = rc
				break

	finished.emit(current_statement, final_rc)
	return final_rc


# Interrupt the statement in the middle of its execution.
func interrupt():
	escoria.logger.info(
		self,
		"Interrupting event %s (%s)."
				% [self.name if "name" in self else "group", str(self)]
	)
	_is_interrupted = true
	for statement in statements:
		if statement.has_method("interrupt"):
			statement.interrupt()


# Resets an interrupted event
func reset_interrupt():
	_is_interrupted = false
	for statement in statements:
		statement.reset_interrupt()
