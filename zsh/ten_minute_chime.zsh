_TEN_MINUTE_CHIME_SCRIPT_PATH="${HOME}/.dotfiles/bin/ten_minute_chime.sh"
_TEN_MINUTE_CHIME_CRON_COMMENT="ten_minute_chime"
_TEN_MINUTE_CHIME_CRON_JOB="0,10,20,30,40,50 * * * * ${_TEN_MINUTE_CHIME_SCRIPT_PATH} # ${_TEN_MINUTE_CHIME_CRON_COMMENT}"

enable-ten-minute-chime() {
  if ! crontab -l 2>/dev/null | grep -qF "${_TEN_MINUTE_CHIME_CRON_COMMENT}"; then
    (crontab -l 2>/dev/null; echo "${_TEN_MINUTE_CHIME_CRON_JOB}") | crontab -
    if [[ $? -eq 0 ]]; then
      echo "Ten-minute chime enabled."
    else
      echo "Error enabling ten-minute chime. Could not modify crontab."
      return 1
    fi
  else
    echo "Ten-minute chime is already enabled."
  fi
}

disable-ten-minute-chime() {
  if crontab -l 2>/dev/null | grep -qF "${_TEN_MINUTE_CHIME_CRON_COMMENT}"; then
    crontab -l 2>/dev/null | grep -vF "${_TEN_MINUTE_CHIME_CRON_COMMENT}" | crontab -
    if [[ $? -eq 0 ]]; then
      echo "Ten-minute chime disabled."
    else
      echo "Error disabling ten-minute chime. Could not modify crontab."
      return 1
    fi
  else
    echo "Ten-minute chime is not currently enabled."
  fi
}

status-ten-minute-chime() {
  if crontab -l 2>/dev/null | grep -qF "${_TEN_MINUTE_CHIME_CRON_COMMENT}"; then
    echo "Ten-minute chime is currently ENABLED."
    echo "Cron job details:"
    crontab -l | grep --color=always -F "${_TEN_MINUTE_CHIME_CRON_COMMENT}"
  else
    echo "Ten-minute chime is currently DISABLED."
  fi
}

# To use these functions, source this file in your .zshrc or equivalent:
# source "${HOME}/.dotfiles/zsh/ten_minute_chime.zsh"
