set -g CMD_DURATION 0

_load_sushi

function fish_greeting
	echo (dim)(uname -mnprs)(off)
end
