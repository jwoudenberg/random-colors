function __change-colors --on-event fish_postexec --description 'Maybe change colorscheme'
    status --is-command-substitution
    and return
    random-colors &
end

# Configure fish to use standard terminal colors
set -U fish_color_autosuggestion cyan
set -U fish_color_command blue
set -U fish_color_comment magenta
set -U fish_color_cwd blue
set -U fish_color_cwd_root blue
set -U fish_color_end cyan
set -U fish_color_error red
set -U fish_color_escape 'bryellow' '--bold'
set -U fish_color_history_current --bold
set -U fish_color_host normal
set -U fish_color_match --background=brblue
set -U fish_color_normal normal
set -U fish_color_operator bryellow
set -U fish_color_param cyan
set -U fish_color_quote magenta
set -U fish_color_redirection cyan
set -U fish_color_search_match 'bryellow' '--background=brblack'
set -U fish_color_selection 'white' '--bold' '--background=brblack'
set -U fish_color_status red
set -U fish_color_user brgreen
set -U fish_color_valid_path --underline

__change-colors
