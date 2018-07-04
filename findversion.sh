#!/bin/sh

# $Id$

# This file is part of OpenTTD.
# OpenTTD is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 2.
# OpenTTD is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with OpenTTD. If not, see <http://www.gnu.org/licenses/>.


# Arguments given? Show help text.
if [ "$#" != "0" ]; then
	cat <<EOF
Usage: ./findversion.sh
Finds the current revision and if the code is modified.

Output: <REV>\t<REV_NR>\t<MODIFIED>\t<CLEAN_REV>
REV
    a string describing what version of the code the current checkout is
    based on. The exact format of this string depends on the version
    control system in use, but it tries to identify the revision used as
    close as possible (using the svn revision number or hg/git hash).
    This also includes an indication of whether the checkout was
    modified and which branch was checked out. This value is not
    guaranteed to be sortable, but is mainly meant for identifying the
    revision and user display.

    If no revision identifier could be found, this is left empty.
REV_NR
    the revision number of the svn revision this checkout is based on.
    This can be used to determine which functionality is present in this
    checkout. For trunk svn checkouts and hg/git branches based upon it,
    this number should be accurate. For svn branch checkouts, this
    number is mostly meaningless, at least when comparing with the
    REV_NR from other branches or trunk.

    This number should be sortable. Within a given branch or trunk, a
    higher number means a newer version. However, when using git or hg,
    this number will not increase on new commits.

    If no revision number could be found, this is left empty.
MODIFIED
    Whether (the src directory of) this checkout is modified or not. A
    value of 0 means not modified, a value of 2 means it was modified.
    Modification is determined in relation to the commit identified by
    REV, so not in relation to the svn revision identified by REV_NR.

    A value of 1 means that the modified status is unknown, because this
    is not an svn/git/hg checkout for example.

CLEAN_REV
    the same as REV but without branch name

By setting the AWK environment variable, a caller can determine which
version of "awk" is used. If nothing is set, this script defaults to
"awk".
EOF
exit 1;
fi

# Allow awk to be provided by the caller.
if [ -z "$AWK" ]; then
	AWK=awk
fi

# Find out some dirs
cd `dirname "$0"`
ROOT_DIR=`pwd`

# Determine if we are using a modified version
# Assume the dir is not modified
MODIFIED="0"
if [ -d "$ROOT_DIR/.git" ]; then
	# We are a git checkout
	# Refresh the index to make sure file stat info is in sync, then look for modifications
	git update-index --refresh >/dev/null
	if [ -n "`git diff-index HEAD`" ]; then
		MODIFIED="2"
	fi
	HASH=`LC_ALL=C git rev-parse --verify HEAD 2>/dev/null`
	REV="g`echo $HASH | cut -c1-8`"
	BRANCH="`git symbolic-ref -q HEAD 2>/dev/null | sed 's@.*/@@;s@^master$@@'`"
	REV_NR=`git log | grep commit | wc -l`
	TAG=`git describe --abbrev=0 --tags`
	if [ -n "$TAG" ]; then
		BRANCH=""
		REV="$TAG[$REV]"
	fi
	REV="$REV-tlg"
elif [ -f "$ROOT_DIR/.ottdrev" ]; then
	# We are an exported source bundle
	cat $ROOT_DIR/.ottdrev
	exit
else
	# We don't know
	MODIFIED="1"
	BRANCH=""
	REV=`find * | md5sum | cut -d' ' -f1 | fold -w8 | sed '1q'`
	REV="$REV-tlg (UNOFFICIAL)"
	REV_NR=""
fi

if [ "$MODIFIED" -eq "2" ]; then
	REV="${REV} (modified)"
fi

CLEAN_REV=${REV}

if [ -n "$BRANCH" ]; then
	REV="${REV}-$BRANCH"
fi

echo "$REV	$REV_NR	$MODIFIED	$CLEAN_REV"
