# Colors
function orange
    set_color -o ee5819
end

function yellow
    set_color -o b58900
end

function red
    set_color -o d30102
end

function cyan
    set_color -o 2aa198
end

function white
    set_color -o fdf6e3
end

function dim
    set_color -o 4f4f4f
end

function off
    set_color -o normal
end

# Git
function git::is_repo
	test -d .git; or command git rev-parse --git-dir >/dev/null ^/dev/null
end

function git::ahead -a ahead behind diverged none
	not git::is_repo; and return

	set -l commit_count (command git rev-list --count --left-right "@{upstream}...HEAD" ^/dev/null)

	switch "$commit_count"
  case ""
	  # no upstream
  case "0"\t"0"
	  test -n "$none"; and echo "$none"; or echo ""
  case "*"\t"0"
	  test -n "$behind"; and echo "$behind"; or echo "-"
  case "0"\t"*"
	  test -n "$ahead"; and echo "$ahead"; or echo "+"
  case "*"
	  test -n "$diverged"; and echo "$diverged"; or echo "±"
	end
end

function git::branch_name
	git::is_repo; and begin
		command git symbolic-ref --short HEAD ^/dev/null;
		or command git show-ref --head -s --abbrev | head -n1 ^/dev/null
	end
end

function git::is_dirty
	git::is_repo; and not command git diff --no-ext-diff --quiet --exit-code
end

function git::is_staged
	git::is_repo; and begin
		not command git diff --cached --no-ext-diff --quiet --exit-code
	end
end

function git::is_stashed
	git::is_repo; and begin
		command git rev-parse --verify --quiet refs/stash >/dev/null
	end
end

function git::is_touched
	git::is_repo; and begin
		test -n (echo (command git status --porcelain))
	end
end

function git::untracked
	git::is_repo; and begin
		command git ls-files --other --exclude-standard
	end
end

# Kubernetes

function k8s::current_context
    command kubectl config current-context
end

function k8s::current_namespace
    command kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}'
end

# Terraform

# Test whether this is a terraform directory by finding .tf files
function terraform::directory
	command find . -name '*.tf' >/dev/null ^/dev/null -maxdepth 0
end

function terraform::workspace
	terraform::directory; and begin
		test -e .terraform/environment
	end
end

function fish_prompt
	set -l symbol "λ "
	set -l code $status

	if test -n "$ssh_client"
		set -l host (hostname -s)
		set -l who (whoami)
		echo -n -s (red)"("(cyan)"$who"(red)":"(cyan)"$host"(red)") "(off)
	end

	if git::is_repo
		set -l branch (git::branch_name ^/dev/null)
		set -l ref (git show-ref --head --abbrev | awk '{print substr($0,0,7)}' | sed -n 1p)

		if git::is_stashed
			echo -n -s (white)"^"(off)
		end

		echo -n -s (red)"("(off)

		if git::is_dirty
			printf (white)"*"(off)
		end

		if command git symbolic-ref HEAD > /dev/null ^/dev/null
			if git::is_staged
				printf (cyan)"$branch"(off)
			else
				printf (yellow)"$branch"(off)
			end
		else
			printf (dim)"$ref"(off)
		end

		for remote in (git remote)
			set -l behind_count (echo (command git rev-list $branch..$remote/$branch ^/dev/null | wc -l | tr -d " "))
			set -l ahead_count (echo (command git rev-list $remote/$branch..$branch ^/dev/null | wc -l | tr -d " "))

			if test $ahead_count -ne 0; or test $behind_count -ne 0; and test (git remote | wc -l) -gt 1
				echo -n -s " "(orange)$remote(off)
			end

			if test $ahead_count -ne 0
				echo -n -s (white)" +"$ahead_count(off)
			end

			if test $behind_count -ne 0
				echo -n -s (white)" -"$behind_count(off)
			end
		end

		echo -n -s (red)") "(off)
	end

	if test "$code" = 0
		echo -n -s (red)"$symbol"(off)
	else
		echo -n -s (dim)"$symbol"(off)
	end

end
