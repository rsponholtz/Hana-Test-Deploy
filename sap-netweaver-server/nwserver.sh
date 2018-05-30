#!/bin/bash

function log()
{
	message=$1
	echo "message: $message"
	echo "$message" >> /var/log/sapconfigcreate
}

log "nwserver sh"