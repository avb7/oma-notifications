#!/bin/bash
# Put demo popups on screen to try the stacks by hand.
#
#   - "notify-send" stack: 4 critical alerts from a trusted sender, so they stay
#     until you dismiss them (try: click to expand, Show less, Clear all, ×)
#   - "Omarchy" stack: 2 critical alerts, also stay
#   - "Grok Bot" stack: 3 critical alerts from an ordinary app, gone after 30s
#     unless the pointer is on them
#   - "Slack": one normal popup, gone after 30s
#
# Clear everything with: omarchy-shell notifications dismissAll

for i in 1 2 3 4; do
  notify-send -u critical "Demo alert $i" "Stays until you dismiss it. Click the stack to expand."
  sleep 0.15
done
for i in 1 2; do
  omarchy-notification-send -u critical "Omarchy demo $i" "Also stays until dismissed"
  sleep 0.15
done
for i in 1 2 3; do
  notify-send -a "Grok Bot" -u critical "Grok Bot is waiting for you" "Permission needed: demo command $i"
  sleep 0.15
done
notify-send -a "Slack" -t 30000 "Slack" "New message in #general"
