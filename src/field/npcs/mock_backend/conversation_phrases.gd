class_name ConversationPhrases extends RefCounted

# Conversation starters
const GREETINGS = [
	"Well hello there, friend!",
	"What a pleasant surprise to see you!",
	"Fancy meeting you here!",
	"Oh, it's you! How delightful!",
	"I was just thinking about you!"
]

# General conversation responses
const RESPONSES = [
	"That's absolutely fascinating!",
	"I couldn't agree more!",
	"You don't say!",
	"How remarkable!",
	"Tell me more about that!",
	"Indeed, indeed!",
	"What an interesting perspective!",
	"I never thought of it that way!",
	"You make an excellent point!",
	"That reminds me of a story..."
]

# Conversation enders
const FAREWELLS = [
	"Well, this has been lovely!",
	"I should be going now.",
	"Until we meet again!",
	"It's been a pleasure chatting!",
	"Take care, my friend!"
]

static func get_random_greeting() -> String:
	return GREETINGS.pick_random()

static func get_random_response() -> String:
	return RESPONSES.pick_random()

static func get_random_farewell() -> String:
	return FAREWELLS.pick_random()