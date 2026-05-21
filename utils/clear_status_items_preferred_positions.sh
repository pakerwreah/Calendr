#!/bin/sh

for prefix in "" "saved "; do
  for item in main event reminder; do
    key="${prefix}NSStatusItem Preferred Position ${item}_status_item"
    defaults delete br.paker.Calendr "$key" 2>/dev/null
  done
done
