#!/bin/bash

#    Shell script to install and uninstall the MTPro2 fonts on a Linux/BSD/Max OS X TexLive system.
#    Copyright James Fennell 2016.

#    March 2016: v1.1
#        Bug fixes. Thanks to Russell Lyons and David Brailsford for feedback.
#        Licence change GNU GPL -> Apache 2
#    2014: v1.0. 
#        Original script based on valuable instructions given by Tex.StackExchange users egreg and synaptik.



#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.





#######################################
# SET UP SYSTEM CONSTANTS AND LOGFILE #
#######################################

LOGFILE=./mtpro2-texlive.sh.log
echo "mtpro2-texlive.sh log file." > $LOGFILE
echo "$(date)" >> $LOGFILE
echo "TeX information:" >> $LOGFILE
echo "$(tex --version)" >> $LOGFILE
UPDCFG=`kpsewhich updmap.cfg`
echo "updmap.cfg is at $UPDCFG" >> $LOGFILE
TEXMF=`kpsewhich --var-value TEXMFLOCAL`
# get first element if TEXMF is colon-seperated list
TEXMF=${TEXMF%%:*}
echo "The texmf directory for fonts is $TEXMF" >> $LOGFILE


#########################
# CUSTOM BASH FUNCTIONS #
#########################


# test_compile() 
# Checks that MTPro2 is working properly by running pdflatex on a simple LaTeX file
test_compile() {
	# Set up directory to work in
	TEMPFILE=$(mktemp ./mtpro2-texlive_tmptex_XXXXXXXX.tex)
	chmod 777 $TEMPFILE
	echo "Temporary file at $TEMPFILE." >> $LOGFILE

	# Write sample LaTeX file to $TEMPFILE
	STRING=$(cat <<TEXCODE
		\documentclass[11pt,oneside,a4paper]{article}
		\usepackage[varg]{txfonts}
		\usepackage[lite,subscriptcorrection,slantedGreek,nofontinfo]{mtpro2}
		\selectfont
		\begin{document}
		\section{New LaTeX document}
		Your new LaTeX document is ready to edit.
		\$\$x=\frac{-b \pm \sqrt{b^2-4ac}}{2a}\$\$
		\end{document}

TEXCODE
)
	echo "$STRING" >> $TEMPFILE

	# Run pdflatex
	echo "Running pdflatex on the following code in $TEMPFILE:" >> $LOGFILE
	echo "$STRING" >> $LOGFILE
	local PDFOUT=$(pdflatex -shell-escape -interaction=nonstopmode -file-line-error "$TEMPFILE" | grep ".*:[0-9]*:.*")
	echo $PDFOUT >> $LOGFILE

	# If there were errors
	if [ -n "$PDFOUT" ]; then
		echo "Error in compilation; outputting now" >> $LOGFILE
		# Output pdflatex to logfile
		pdflatex -shell-escape -interaction=nonstopmode -file-line-error "$TEMPFILE" >> $LOGFILE
		rm -r "${TEMPFILE:0:32}"*
		echo "1"
		return 1
	fi

	#No errors then...
	echo "Compiled succesfully" >> $LOGFILE
	rm -r "${TEMPFILE:0:32}"*

	echo "0"
}


#remove_mtpro2_files () 
#Deletes the MTPro2 files from the TEXMF directory
remove_mtpro2_files () { 
	echo "Removing MTPro2 files from ${TEXMF}." >> $LOGFILE
	for FILE in `sudo find ${TEXMF}/ -type d -name mtpro2`
	do
		echo "   removing: ${FILE}." >> $LOGFILE
		sudo rm -R $FILE
	done

	for FILE in `sudo find ${TEXMF}/ -name "mtp2*.tpm"`
	do
		echo "   removing: ${FILE}." >> $LOGFILE
		sudo rm $FILE
	done

}

#uninstall_mtpro2 () 
#Removes the MTPro2 files and then updates the Tex Live system
uninstall_mtpro2 () {
	echo "Uninstalling MathTime Professional 2."
	echo "Uninstalling MTPro2." >> $LOGFILE
	remove_mtpro2_files
	echo "Files deleted; updating texlive."
	echo "------------------------[ OUTPUT OF: \`updmap-sys --nohash --disable mtpro2.map\` ]--------" >> $LOGFILE
	sudo updmap-sys --nohash --disable mtpro2.map >> $LOGFILE 2>&1
	echo "-----------------------------------------------------------------------------------------" >> $LOGFILE
	echo "Removing 'Map mtpro2.map' from ${UPDCFG}."  >> $LOGFILE
	sudo sed -e "s/Map mtpro2.map//g" -i ${UPDCFG}
	echo "------------------------[ OUTPUT OF: \`updmap-sys\` ]--------------------------------------" >> $LOGFILE
	sudo updmap-sys >> $LOGFILE 2>&1
	echo "-----------------------------------------------------------------------------------------" >> $LOGFILE
	echo "Uninstall complete."  >> $LOGFILE
	echo "Uninstall complete."
}


#confirm_input ()
#Checks that the inputted file exists and is a zip file
confirm_input () {
	FILE=$1
	echo "confirm_input(): Checking $FILE." >> $LOGFILE

	#3# Check that the file exits
	if [ ! -f $FILE ];
	then
		echo "File does not exist." >> $LOGFILE
		echo "1"
		return;
	fi

	#4# Check that file is a zip archive
	DESCRIPTION=$(file "$FILE");
	if ! echo $DESCRIPTION | grep -q "Zip archive data"; then
		echo "File is not a zip file." >> $LOGFILE
		echo "2"
		return;
	fi

	echo "File exists and is a zip file." >> $LOGFILE
	echo "0"
}



#require_command ()
#Checks that a given command is installed
require_command () {
	echo "require_comment(): testing to see if $1 is installed" >> $LOGFILE
	TEST=$(command -v $1)
	echo "Output of command -v: $TEST" >> $LOGFILE
	if [ ! -n "$TEST" ]; then
		echo "Command not found" >> $LOGFILE
		echo "1"
		return
	fi;
	echo "Command found" >> $LOGFILE
	echo "0"
}

#unzip_and_copy ()
#Unzips a file and copies it to the desired location
unzip_and_copy () {
	FILE=$1
	echo "Unpacking $FILE."
	#Create a temporary directory into which to unzip
	TEMPDIR=$(mktemp -d ./mtpro2-texlive_tmpdir_XXXXXXXX)
	echo "Temporary directory at $TEMPDIR." >> $LOGFILE

	echo "Running command \`unzip ${FILE} -d ${TEMPDIR}\`." >> $LOGFILE
	echo "------------------------[ OUTPUT OF: unzip ]---------------------------------------------" >> $LOGFILE
	unzip ${FILE} -d ${TEMPDIR} >> $LOGFILE
	echo "-----------------------------------------------------------------------------------------" >> $LOGFILE

	# First, remove any possible old files.
	echo "Removing previous MTPro2 files, as a precaution." >> $LOGFILE
	remove_mtpro2_files

	# Then, copy over the new files
	echo "Copying files."
	echo "Coping all files in ${TEMPDIR}/texmf/ to ${TEXMF}/." >> $LOGFILE
        sudo mkdir -p ${TEXMF}
	sudo cp -r ${TEMPDIR}/texmf/* ${TEXMF}/

	#Remove the temporary directory
	echo "Removing the temporary directory." >> $LOGFILE
	rm -d -r $TEMPDIR
}


#install_mtpro2 ()
#Installs MTPro2 AFTER the font files have been put in the right place
install_mtpro2 () {
	echo "Installing MathTime Professional 2."
	# Run a few commands to add MTPro2 (these can really be cleaned up I think)
	echo "Updating TeX Live" >> $LOGFILE

	echo "------------------------[ OUTPUT OF: texhash ]---------------------------------------------" >> $LOGFILE
	echo "  > running texhash"
	sudo texhash >> $LOGFILE 2>&1
	echo "------------------------[ OUTPUT OF: updmap-sys --disable mt-belleek.map --nomkmap ]-------" >> $LOGFILE
	echo "  > updating map references"
	sudo updmap-sys --disable mt-belleek.map --nomkmap >> $LOGFILE 2>&1
	echo "------------------------[ OUTPUT OF: updmap-sys --disable mt-belleek.map --nomkmap ]-------" >> $LOGFILE
	sudo updmap-sys --disable belleek.map --nomkmap >> $LOGFILE 2>&1
	echo "------------------------[ OUTPUT OF: updmap-sys --disable mt-yy.map --nomkmap ]------------" >> $LOGFILE
	sudo updmap-sys --disable mt-yy.map --nomkmap >> $LOGFILE 2>&1
	echo "------------------------[ OUTPUT OF: updmap-sys --disable mt-plus.map --nomkmap ]----------" >> $LOGFILE
	sudo updmap-sys --disable mt-plus.map --nomkmap >> $LOGFILE 2>&1
	echo "------------------------[ OUTPUT OF: updmap-sys --enable Map mtpro2.map ]------------------" >> $LOGFILE
	sudo updmap-sys --enable Map mtpro2.map >> $LOGFILE 2>&1
	echo "-------------------------------------------------------------------------------------------" >> $LOGFILE
	sudo chmod -R a+r+x ${TEXMF}/
	#OLD: sudo chmod -R a+r+x /usr/local/share/texmf/

	# Now there's a possible bug that the updmap config file won't have a Map reference in it. Add the reference if it doesn't exist
	echo "  > editing updmap.cfg"
	#See if that map reference is in there
	TEST=`grep "Map mtpro2.map" $UPDCFG`;
	if [ -n  "$TEST" ]; then
		echo "Map mtpro2 present in updcfg file." >> $LOGFILE
	else
		echo "Map mtpro2 not present in updcfg file, writing it." >> $LOGFILE
		echo "Map mtpro2.map" | sudo tee -a $UPDCFG;
	fi

	echo "  > updating TeX Live databases"
	echo "------------------------[ OUTPUT OF: updmap-sys ]------------------------------------------" >> $LOGFILE
	sudo updmap-sys >> $LOGFILE 2>&1
	echo "-------------------------------------------------------------------------------------------" >> $LOGFILE
	echo "Installed." >> $LOGFILE
}


###############
# PARSE INPUT #
###############

#Cycles through the inputs and does the appropriate thing.
while getopts ":i:hut" o; do
	case "${o}" in
		#INSTALL MTPRO2 WITH GIVEN FILENAME
        i)
			echo "Installing MathTime Professional 2 from ${OPTARG}."

			#Check that the provided file is a Zip of MTPro2 files.
			TEST=$(confirm_input ${OPTARG})
			case $TEST in
			1)
  				echo "File ${OPTARG} does not exist!"
				exit
  				;;
			2)
				echo "File ${OPTARG} is not a zip file."
				echo "You must provide the original zip file from PCTex containing the font files."
				exit
  				;;
			esac

			#Check that unzip is installed
			TEST=$(require_command unzip)
			if [ "$TEST" = "1" ]; then
				echo "Error: installation requires zip to be installed."
				exit;			
			fi

			#Run the unzip and copy routine
			unzip_and_copy ${OPTARG}

			#Install
			install_mtpro2
			echo "TeX Live updated; checking that MTPro2 works..."

			#Check it worked
			RESULT=$(test_compile)
			if [ "$RESULT" = "1" ];
			then
				echo "There appears to have been an error in installation."
				echo "Consult the log file for more information."
				exit;
			fi;

			echo "Succesfully compiled LaTeX file with MTPro2 included."
			echo "MathTime Professional 2 installed."
			echo "Documentation available at ${TEXMF}/docs/"

			exit;
			;;

		#UNINSTALL MTPRO2
        u)
            echo "This option will uninstall MathTime Professional 2 and remove all MTPro2 files from the TeX Live directories."
			read -p "Continue [N/Y]? " -n 1 -r
			echo    # (optional) move to a new line
			if [[ $REPLY =~ ^[Yy\ ]$ ]]
			then
   				uninstall_mtpro2
			fi
			exit;
            ;;

		#TEST TO SEE IF INSTALLED
        t)
			echo "Testing to see if MTPro2 is working."
			OUTPUT=$(test_compile)
			if [ "$OUTPUT" = "1" ];
			then
				echo "There was an error compiling the document so MTPro2 is not installed (or incorrectly installed)."
				echo "See the logfile for more information."
			else
				echo "Succesfully compiled LaTeX file with MTPro2 included."
			fi;
			exit;
			;;

		#PROVIDE USAGE INSTRUCTIONS
		h)

cat <<END


This is a program for installing and uninstalling the MathTime Profesional 2 fonts in Tex Live on Linux/BSD/Mac OS X systems.2
In order to install the MTPro2 fonts you will need to aquire a copy of the font files from the distributor PCTex here:
	
	http://www.pctex.com/mtpro2.html

The full font set must be purchased, but there is also a free "Lite" version available. This installer works with either.

1. INSTALLING
Simply run the command 

	$0 -i [PATH TO FONT FILES.zip.tpm]

You can then use MTPro2 in a LaTeX file by including

	\usepackage[lite,subscriptcorrection,slantedGreek,nofontinfo]{mtpro2}

2. TESTING
Running

	$0 -t

tests whether MTPro2 is installed by compiling a sample LaTeX document.

3. UNINSTALLING
Should you wish to remove MTPro2 run

	$0 -u

Note that this will remove all of the MTPro2 font files from your LaTeX directories.


END

			exit;
			;;

		#INVALID OPTION PASSED
        \?)
            echo "Invalid option ${OPTARG}."
			echo "Run \`$0 -h\` for instructions on using this program."
			exit;
            ;;

		#ARGUMENT NOT PASSED
		*)
			echo "The installation option requires providing the location of a set of MathTime Professional 2 font files."
			echo "Run \`$0 -h\` for instructions on using this program."
			exit;
			;;
    esac
done

echo "Run \`$0 -h\` for instructions on using this program."

exit;
