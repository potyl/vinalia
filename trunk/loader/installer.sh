#!/bin/bash

# List of debian packages to install

declare -a pacakges=(
	postgresql-8.0
	liblingua-en-inflect-perl
	libdbd-pgsql
	libtemplate-perl
	liblog-log4perl-perl
	libclass-accessor-perl
)


sudo apt-get install "${pacakges[@]}"
