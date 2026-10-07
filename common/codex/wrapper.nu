# Read Linux argv directly: Nushell's main argument parser rewrites quoted flags.
let args = (open --raw $"/proc/($nu.pid)/cmdline"
    | decode utf-8 | split row (char nul) | skip 3 | drop 1)
let options = ($args | take until {|arg| $arg == '--'})
let explicit_profile = ($options | any {|arg| $arg =~ '^(-p|--profile($|=))'})

# Find the command without mistaking option values for command names.
let value_flags = [
    '-c' '--config' '--enable' '--disable' '--remote' '--remote-auth-token-env'
    '-m' '--model' '--local-provider' '-s' '--sandbox'
    '-C' '--cd' '--add-dir' '-a' '--ask-for-approval'
]
mut remaining = $options
mut command = []
while not ($remaining | is-empty) {
    let arg = ($remaining | first)
    $remaining = ($remaining | skip 1)
    if $arg in $value_flags {
        $remaining = ($remaining | skip 1)
    } else if $arg in ['-i' '--image'] {
        $remaining = ($remaining | skip while {|value| not ($value | str starts-with '-')})
    } else if not ($arg | str starts-with '-') {
        $command = ($command | append $arg)
        if $arg != 'debug' or ($command | length) == 2 { break }
    }
}

# Codex rejects profiles on management commands.
let management_commands = [
    login logout plugin app-server remote-control app completion update doctor
    execpolicy apply a migrate-rollouts cloud cloud-tasks responses-api-proxy
    stdio-to-uds exec-server features tcp-tunnel help
]
let management = (
    $command.0? in $management_commands
    or ($command.0? == 'debug' and $command.1? != 'prompt-input')
)
let defaults = if $explicit_profile or $management { [] } else { ['--profile' 'hm'] }
exec @codex@ ...$defaults ...$args
