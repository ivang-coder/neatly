#! /bin/bash

# Author: Ivan Gladushko
# Version: v1.0
# Date: 2020/08/16

# To Do
# "Unverified" file deduplication
# 

#=======================================================================
# Default parameters
#=======================================================================
# Setting extension case switch to "ext", i.e. changing file extension case to lowercase
ExtensionCaseSwitch="ext"
# 0 = Disable less reliable file attribute extraction
FileSystemAttributeProcessingFlag=0
# 0 = Disable debugging
DEBUG=0
# 1 = Enable dry run, do everything including file move and preparation in Work-In-Progress but 
# do not do renaming and moving the files to Destination
DRYRUN=0
# Empty the notes
NOTE=""


#=======================================================================
# Help options
#=======================================================================
HelpTip="Help: for more parameters use 'sh rEXIFier.sh <-h|--help>'\n"

UsageTip01="Usage: 'sh rEXIFier.sh <source-path|.> <destination-path|.> <--Ext|--EXT|--ext> "
UsageTip02="<--FSAttribute|--NoFSAttribute> <--Debug|--NoDebug> <--DryRun|--NoDryRun>\n\n"
UsageTip=${UsageTip01}${UsageTip02}

SourcePathTip01="Source absolute path is required with leading '/'. Alternatively use '.' for current directory.\n"
SourcePathTip02="Example: '/home/username/pictures/'\n"
SourcePathTip=${SourcePathTip01}${SourcePathTip02}

DestinationPathTip01="Destination absolute path is required with leading '/'. Alternatively use '.' for current directory.\n"
DestinationPathTip02="Example: '/mystorage/sorted-pictures/'\n"
DestinationPathTip=${DestinationPathTip01}${DestinationPathTip02}

ExtensionTip01="Extension case switch options: \n--ExT=unchanged, i.e. JPEG > JPEG, jpeg > jpeg\n"
ExtensionTip02="--EXT=uppercase, i.e. jpeg > JPEG \n--ext=lowercase (recommended), i.e. JPEG > jpeg\n"
ExtensionTip=${ExtensionTip01}${ExtensionTip02}

FSAttributeTip01="File system attribute extraction is quite unreliable and can be used as the last resort.\n"
FSAttributeTip02="If enabled with '--FSAttribute', it can cause conflicts and affect file sorting. '--NoFSAttribute' is the recommended option.\n"
FSAttributeTip=${FSAttributeTip01}${FSAttributeTip02}

DebugTip="Enabling debug with '--Debug' will output to terminal and log file. '--NoDebug' will output to log file only\n"

DryRunTip="Enabling dry run with '--DryRun' will do everything including file move and preparation in Work-In-Progress but do not do renaming and moving the files to Destination. '--NoDryRun' is Production state\n"
# End of Forming help menu options

# Colour Codes (ANSI) for coloured output, useful for debug output
CRE="$(echo -e '\r\033[K')"
RED="$(echo -e '\033[1;31m')"
GRN="$(echo -e '\033[1;32m')"
YEL="$(echo -e '\033[1;33m')"
BLU="$(echo -e '\033[1;34m')"
MAG="$(echo -e '\033[1;35m')"
CYN="$(echo -e '\033[1;36m')"
WHT="$(echo -e '\033[1;37m')"
NML="$(echo -e '\033[0;39m')"

#=======================================================================
# Functions
#=======================================================================
# IsValidDate verifies the Year, Month and Day variables contain values
#   within the expected range, i.e. it catches potential rubbish.
#   Returns: 0 = invalid date, 1 = valid date
IsValidDate() {
  # Define variables and pass the arguments for ${YEAR} ${MONTH} ${DAY}
  Year=$1
  Month=$2
  Day=$3
  # Confirm the variables within ranges
  if ([ "$Year" -ge "1950" ] && [ "$Year" -le "2050" ]) || \
    ([ "$Month" -ge "01" ] && [ "$Month" -le "12" ]) || \
    ([ "$Day" -ge "01" ] && [ "$Day" -le "31" ]) ; then
    # Return 1 for valid date
    echo "1"
  else
    # Return 0 for invalid date
    echo "0"
  fi
}

# Dump debugging info
# EX: $(DumpDebug ${WIPSortedFileAbsolutePath} $FormatedFileName $NormalisedFileExtension $DATE ${YEAR} ${MONTH} ${DAY} $HOUR $MINUTE $SECOND $SUBSECOND "$NOTE")
DumpDebug() {
  #echo "1=${#WIPSortedFileAbsolutePath}, 2=${#FormatedFileName}, 3=${#NormalisedFileExtension}, 4=${#DATE}, 5=${#YEAR}, 6=${#MONTH}, 7=${#DAY}, 8=${#HOUR}, 9=${#MINUTE}, 10=${#SECOND}, 11=${#SUBSECOND}, 12=${#MODEL}, 13=${#NOTE}" >/dev/stderr
  echo "================================"
  echo "WIPSortedFileAbsolutePath  = ${1}"
  echo "FormatedFileName      = ${2}"
  echo "NormalisedFileExtension       = ${3}"
  echo "DATE      = ${4}"
  echo "YEAR      = ${5}"
  echo "MONTH     = ${6}"
  echo "DAY       = ${7}"
  echo "HOUR      = ${8}"
  echo "MINUTE    = ${9}"
  echo "SECOND    = ${10}"
  echo "SUBSECOND = ${11}"
  echo "Model     = ${12}"
  echo "ValidDate = $(IsValidDate ${6} ${7} ${8})"
  echo "NOTE      = ${13}"
  echo "================================"
}

# EXIFSubSecCreateDateParser extracts EXIF metadata: the year, month, day, hour, minute, second, subsecond,
# and generates date and note
EXIFSubSecCreateDateParser() {
  # Define a variable and pass the arguments
  EXIF_OUTPUT=$1
  # Substitute dots with a common colon delimiter
  EXIF_OUTPUT_SUBSTITUTE=${EXIF_OUTPUT//./:}
  # Define delimiter
  DELIMITER=":"
  # Concatenate the delimiter with the main string
  DELIMITED_EXIF_OUTPUT=$EXIF_OUTPUT_SUBSTITUTE$DELIMITER
  # Split the text based on the delimiter
  EXIF_OUTPUT_ARRAY=()
  while [[ $DELIMITED_EXIF_OUTPUT ]]; do
    EXIF_OUTPUT_ARRAY+=( "${DELIMITED_EXIF_OUTPUT%%"$DELIMITER"*}" )
    DELIMITED_EXIF_OUTPUT=${DELIMITED_EXIF_OUTPUT#*"$DELIMITER"}
  done
  # Assign the array values to the corresponding variables
  YEAR=${EXIF_OUTPUT_ARRAY[0]}
  MONTH=${EXIF_OUTPUT_ARRAY[1]}
  DAY=${EXIF_OUTPUT_ARRAY[2]}
  HOUR=${EXIF_OUTPUT_ARRAY[3]}
  MINUTE=${EXIF_OUTPUT_ARRAY[4]}
  SECOND=${EXIF_OUTPUT_ARRAY[5]}
  SUBSECOND=${EXIF_OUTPUT_ARRAY[6]}
  DATE="${YEAR}:${MONTH}:${DAY}"
  NOTE="(by EXIFSubSecCreateDate)"
}

# EXIFCreateDateParser extracts EXIF metadata: the year, month, day, hour, minute, second,
# and generates subsecond, date and note
EXIFCreateDateParser() {
  # Define a variable and pass the arguments
  EXIF_OUTPUT=$1
  # Substitute dots with a common colon delimiter
  EXIF_OUTPUT_SUBSTITUTE=${EXIF_OUTPUT//./:}
  # Define delimiter
  DELIMITER=":"
  # Concatenate the delimiter with the main string
  DELIMITED_EXIF_OUTPUT=$EXIF_OUTPUT_SUBSTITUTE$DELIMITER
  # Split the text based on the delimiter
  EXIF_OUTPUT_ARRAY=()
  while [[ $DELIMITED_EXIF_OUTPUT ]]; do
    EXIF_OUTPUT_ARRAY+=( "${DELIMITED_EXIF_OUTPUT%%"$DELIMITER"*}" )
    DELIMITED_EXIF_OUTPUT=${DELIMITED_EXIF_OUTPUT#*"$DELIMITER"}
  done
  # Assign the array values to the corresponding variables
  YEAR=${EXIF_OUTPUT_ARRAY[0]}
  MONTH=${EXIF_OUTPUT_ARRAY[1]}
  DAY=${EXIF_OUTPUT_ARRAY[2]}
  HOUR=${EXIF_OUTPUT_ARRAY[3]}
  MINUTE=${EXIF_OUTPUT_ARRAY[4]}
  SECOND=${EXIF_OUTPUT_ARRAY[5]}
  SUBSECOND="000000"
  DATE="${YEAR}:${MONTH}:${DAY}"
  NOTE="(by EXIFCreateDate)"
}

# FSModifyTimeParser extracts File System attributes: the year, month, day, hour, minute, second, subsecond
# and generates date and note
FSModifyTimeParser() {
  # Define a variable and pass the arguments
  MTIME_OUTPUT=$1
  # Substitute dots with a common colon delimiter
  MTIME_OUTPUT_SUBSTITUTE=${MTIME_OUTPUT//-/:}
  MTIME_OUTPUT_SUBSTITUTE=${MTIME_OUTPUT_SUBSTITUTE//./:}
  # Define delimiter
  DELIMITER=":"
  # Concatenate the delimiter with the main string
  DELIMITED_MTIME_OUTPUT=$MTIME_OUTPUT_SUBSTITUTE$DELIMITER
  # Split the text based on the delimiter
  MTIME_OUTPUT_ARRAY=()
  while [[ $DELIMITED_MTIME_OUTPUT ]]; do
    MTIME_OUTPUT_ARRAY+=( "${DELIMITED_MTIME_OUTPUT%%"$DELIMITER"*}" )
    DELIMITED_MTIME_OUTPUT=${DELIMITED_MTIME_OUTPUT#*"$DELIMITER"}
  done
  # Assign the array values to the corresponding variables
  YEAR=${MTIME_OUTPUT_ARRAY[0]}
  MONTH=${MTIME_OUTPUT_ARRAY[1]}
  DAY=${MTIME_OUTPUT_ARRAY[2]}
  HOUR=${MTIME_OUTPUT_ARRAY[3]}
  MINUTE=${MTIME_OUTPUT_ARRAY[4]}
  SECOND=${MTIME_OUTPUT_ARRAY[5]}
  LONGSUBSECOND=${MTIME_OUTPUT_ARRAY[6]}
  SUBSECOND=${LONGSUBSECOND:0:6}
  DATE="${YEAR}:${MONTH}:${DAY}"
  NOTE="(by FSModifyTime)"
}

# EXIFModelParser extracts EXIF metadata: the model 
# and manupulates characters
EXIFModelParser() {
  # Define a variable and pass the arguments
  EXIF_OUTPUT=$1
  # Remove the dashes by substituting characters with nothing
  EXIF_OUTPUT_SUBSTITUTE=${EXIF_OUTPUT//-/}
  MODEL=$EXIF_OUTPUT_SUBSTITUTE
}

# FileListSorter sorts the items in array alphabetically
# LC_ALL=C to get the traditional sort order that uses native byte values
FileListSorter(){
  SortedFileList=$(printf '%s\n' "$@" | LC_ALL=C sort)
}

#=======================================================================
# Script starts here
#=======================================================================

# Checking for absence of other running rEXIFier instances
InstanceName=$(basename ${0}) # Getting the name of script, <name>.<ext>
InstanceNameBase=${InstanceName%.*} # Stripping out the extension leaving just <name>
# Excluding the "grep" from the output and counting the number of lines
InstanceCount=$(ps -ef | grep $InstanceNameBase | grep -v grep | wc -l)
# In a common scenario "ps" command will be running in a child process (sub-shell) 
# with the name matching the script name, hence we're checking if there are
# more than 2 instances
if [[ ${InstanceCount} > 2 ]]; then
  printf "It appears more than one $InstanceName instance is running. Exiting now.\n"
  exit
fi

# Checking if application or service is installed, piping errors to NULL
if ( ! command -v exiftool &> /dev/null ) ; then
  printf "It appears 'exiftool' is not installed or it could not be found. Exiting now.\n"
  exit
else
  EXIFTOOLVER=$(exiftool -ver)
fi

# Checking minimal requirements for the arguments, expecting at least one argument
if [[ ${#} -lt 1 ]] ; then
  printf "At least one argument is expected. Exiting now.\n"
  printf "${HelpTip}"
  exit
fi

# Checking if the first argument exists and processing it
case "${1}" in 
  # Checking if the first argument is a call for help
  -h|--help)
    printf "${HelpTip}${UsageTip}\n"
    exit
    ;;
  # Checking if the first argument is a file source path and validating it
  /*|.) 
    # Exiting if there are issues with the source path
    if [[ ! -e ${1} ]] ; then
      printf "Source path ${1} could not be found or does not exist. Exiting now.\n"
      printf "${SourcePathTip}\n"
      exit
    else
      # Passing the source path to a variable and continue
      SourcePath=${1}
    fi
    ;;
  # Exiting if no expected parameter found
  *) 
    echo "Mandatory source path is invalid or could not be identified: ${1}. Exiting now.\n"
    printf "${UsageTip}${SourcePathTip}"
    exit
    ;;
esac

# Checking if the second argument exists and processing it
case "${2}" in 
  # Checking if the second argument is a file destination path and validating it
  /*|.) 
    # Exiting if there are issues with the destination path
    if [[ ! -e ${2} ]] ; then
      printf "Destination path ${2} could not be found or does not exist. Exiting now.\n"
      printf "${DestinationPathTip}\n"
      exit
    else
      # Passing the destination path to a variable and continue
      DestinationPath=${2}
    fi
    ;;
  # Exiting if no expected parameter found
  *) 
    echo "Mandatory destination path is invalid or could not be identified: ${2}. Exiting now.\n"
    printf "${UsageTip}${DestinationPathTip}"
    exit
    ;;
esac
#
# Processing optional paramenters
#
# Checking if more than 2 arguments have been passed and processing them.
if [[ ${#} -gt 2 ]] ; then
  # Validating optional parameters starting with the third parameter
  for Argument in "${@:2}" ; do
    case "${Argument}" in 
      # Checking if the argument is an extension case switch and validating it
      --ExT)
        # Setting extension case switch to "ExT", i.e. leaving file extension case unchanged
        ExtensionCaseSwitch="ExT"
        ;;
      # Checking if the argument is an extension case switch and validating it
      --EXT)
        # Setting extension case switch to "EXT", i.e. changing file extension case to uppercase
        ExtensionCaseSwitch="EXT"
        ;;
      # Checking if the argument is an extension case switch and validating it
      --ext)
        # Setting extension case switch to "ext", i.e. changing file extension case to lowercase
        ExtensionCaseSwitch="ext"
        ;;
      # Checking if the argument is a file system attribute extraction flag and validating it
      --NoFSAttribute)
        # 0 = Disable less reliable file attribute extraction
        FileSystemAttributeProcessingFlag=0
        ;;
      # Checking if the argument is a file system attribute extraction flag and validating it
      --FSAttribute)
        # 1 = Enable less reliable file attribute extraction
        FileSystemAttributeProcessingFlag=1
        ;;
      # Checking if the argument is a debugging flag and validating it
      --NoDebug)
        # 0 = Disable debugging
        DEBUG=0
        ;;
      # Checking if the argument is a debugging flag and validating it
      --Debug)
        # 1 = Enable debugging
        DEBUG=1
        ;;
      # Checking if the argument is a dry run flag and validating it
      --NoDryRun)
        # 0 = Disable dry run, do everything
        DRYRUN=0
        ;;
      # Checking if the argument is a dry run flag and validating it
      --DryRun)
        # 1 = Enable dry run, do everything including file move and preparation in Work-In-Progress but 
        # do not do renaming and moving the files to Destination
        DRYRUN=1
        ;;
      # Skipping if no expected parameter found
      *) 
        printf "Unexpected parameter detected: ${Argument}, ignoring it\n"
        ;;
    esac
  done
# Applying default parameters if the required arguments have not been passed
else
  printf "No optional parameters have been passed. Applying the defaults.\n"
fi

printf "Proceeding with parameters below.\n" 
printf "  Mandatory parameters:\n"
printf "    Source path ${SourcePath}\n"
printf "    Destination path ${DestinationPath}\n"
printf "  Optional parameters:\n"
printf "    File extension case "
case "${ExtensionCaseSwitch}" in 
  ExT)
    printf "UNCHANGED\n"
    ;;
  EXT)
    printf "UPPERCASE\n"
    ;;
  ext)
    printf "LOWERCASE\n"
    ;;
esac
printf "    File attribute extraction "
if [ ${FileSystemAttributeProcessingFlag} -eq 1 ]; then 
  printf "ENABLED\n" 
else 
  printf "DISABLED\n";
fi
printf "    Debug mode "
if [[ ${DEBUG} -eq 1 ]]; then 
  printf "ENABLED\n" 
else 
  printf "DISABLED\n";
fi
printf "    Dry run mode "
if [[ ${DRYRUN} -eq 1 ]]; then 
  printf "ENABLED\n" 
else 
  printf "DISABLED\n";
fi
#
# Path normilisation
#
# Checking if trailing "/" has been passed with the source path
# The space after the colon ":" is REQUIRED. This approach will not work without the space.
if [[ ${SourcePath: -1} == '/' ]] ; then
  # Removing trailing "/" if it has been passed with the source path
  # For bash 4.2 and above, can do ${var::-1}, otherwise ${var: : -1}
  SourcePath=${SourcePath: : -1}
fi
# Checking if trailing "/" has been passed with the destination path
# The space after the colon ":" is REQUIRED. This approach will not work without the space.
if [[ ${DestinationPath: -1} == '/' ]] ; then
  # Removing trailing "/" if it has been passed with the destination path
  # For bash 4.2 and above, can do ${var::-1}, otherwise ${var: : -1}
  DestinationPath=${DestinationPath: : -1}
fi

#
# Creating Work-In-Progress directory in Source Folder for file processing
#
# Forming Work-In-Progress directory composite name in WIP-YYYYMMDD-HHmmss format
WIPDirectoryDate=$(date +%Y%m%d-%H%M%S)
WIPDirectoryName="WIP-""$WIPDirectoryDate"
#WIPDirectoryName="WIP-20200801"
WIPDirectoryPath=${SourcePath}/${WIPDirectoryName}
# Checking if the source directory is writable by creating Work-In-Progress directory, piping errors to NULL
if ( ! mkdir -p $WIPDirectoryPath >/dev/null 2>&1 ) ; then
  printf "Error! Directory $SourcePath does not appear to be writable, exiting\n"
  exit
else
  # Searching for files with specific video and image extensions in source directory
  SourceFileList=$(find $SourcePath -maxdepth 1 -type f -iname "*.[JjGg][PpIi][GgFf]" -or \
  -iname "*.[Jj][Pp][Ee][Gg]" -or \
  -iname "*.[Mm][PpOo][Gg4Vv]")
  # Moving files from source to Work-In-Progress directory
  SourceFileMoveSuccessCount=0
  SourceFileMoveFailureCount=0
  SourceFileNotFoundCount=0
  echo "Moving files to $WIPDirectoryPath Work-In-Progress directory for processing"
  # Taking one file at a time and processing it
  #
  # File path composition
  #   SourceFileAbsolutePath = SourceDirectoryPath + SourceFileBasename, where
  #     SourceFileBasename = SourceFileName + SourceFileExtension
  #
  for SourceFileAbsolutePath in ${SourceFileList[@]}; do
    # Ensure the file exists, then proceed with processing
    # "-e" returns true if the target exists, ${#VAR} calculates the number of characters in a variable
    if [ -e $SourceFileAbsolutePath ] && [ ${#SourceFileAbsolutePath} != 0 ] ; then
      # Extracting path from source absolute path
      SourceDirectoryPath=$(dirname $SourceFileAbsolutePath)
      # Extracting file basename from source absolute path
      SourceFileBasename=$(basename $SourceFileAbsolutePath)
      # Extracting file name
      SourceFileName=${SourceFileBasename%.*} 
      # Extracting file extension
      SourceFileExtension=${SourceFileBasename##*.}
      # Forming Work-In-Progress file path
      WIPFileAbsolutePath=$WIPDirectoryPath/$SourceFileBasename
        # Moving file from source to Work-In-Progress directory, piping errors to NULL
        if ( ! mv $SourceFileAbsolutePath $WIPFileAbsolutePath >/dev/null 2>&1 ) ; then
          echo "Something's wrong! $SourceFileAbsolutePath could not be moved"
          # Counting failed operations with files
          ((SourceFileMoveFailureCount+=1))
        else
          # Counting successful operations with files
          ((SourceFileMoveSuccessCount+=1))
        fi
    else
      echo "File $SourceFileAbsolutePath not found!"
      # Counting files that could not be found
      ((SourceFileNotFoundCount+=1))

    fi
  done
  printf "$SourceFileMoveSuccessCount files have been moved to $WIPDirectoryPath\n"
  printf "$SourceFileMoveFailureCount files could not be moved\n"
  printf "$SourceFileNotFoundCount files could not be found\n"
fi

# Searching for files with specific video and image extensions in Work-In-Progress directory
WIPFileList=$(find ${WIPDirectoryPath} -maxdepth 1 -type f -iname "*.[JjGg][PpIi][GgFf]" -or \
-iname "*.[Jj][Pp][Ee][Gg]" -or \
-iname "*.[Mm][PpOo][Gg4Vv]")
# Older cameras create images/videos with DSC_XXXX.* file name format and
# usually without SubSecond metadata. 
#
# Sorting file names in this case is the only option to keep images in the original sequence, 
# especially when multiple pictures being taken in one second
FileListSorter ${WIPFileList}
# Returning the value from FileListSorter function by assigning the value of output (SortedFileList) to an array
# Bash functions, unlike functions in most programming languages do not allow you to return values to the caller
WIPSortedFileAbsolutePaths=${SortedFileList}
# Resetting SortedFileList array for sanity
SortedFileList=""
# Taking one file at a time and processing it
#
# Work-In-Progress file path composition:
#   WIPFileAbsolutePath = WIPDirectoryPath + WIPFileBasename, where
#     WIPFileBasename = WIPFileName + WIPFileExtension
#
for WIPSortedFileAbsolutePath in ${WIPSortedFileAbsolutePaths[@]}; do
  # Ensure the file exists, then proceed with processing
  # "-e" returns true if the target exists, ${#VAR} calculates the number of characters in a variable
  if [ -e ${WIPSortedFileAbsolutePath} ] && [ ${#WIPSortedFileAbsolutePath} != 0 ] ; then
    # Extracting path from Work-In-Progress absolute path
    WIPDirectoryPath=$(dirname ${WIPSortedFileAbsolutePath})
    # Extracting file basename from Work-In-Progress absolute path
    WIPFileBasename=$(basename ${WIPSortedFileAbsolutePath})
    # Extracting file name base
    WIPFileName=${WIPFileBasename%.*}
    # Extracting file extension
    WIPFileExtension=${WIPFileBasename##*.}
    # Make extension lowercase if ExtensionCaseSwitch  is set to "ext"
    if [[ ${ExtensionCaseSwitch} == 'ext' ]] ; then
      NormalisedFileExtension=$(echo $WIPFileExtension | awk '{print tolower($0)}')
    else
    # Make extension uppercase if ExtensionCaseSwitch  is set to "EXT"
      if [[ ${ExtensionCaseSwitch} == 'EXT' ]] ; then
        NormalisedFileExtension=$(echo $WIPFileExtension | awk '{print toupper($0)}')
      fi
    fi

    # Attempt to find an EXIF SubSecCreateDate from the file, if it exists.
    EXIF_SubSecCreateDate_OUTPUT=$(exiftool -s -f -SubSecCreateDate ${WIPSortedFileAbsolutePath} | awk '{print $3":"$4}')
    # Perform sanity check on correctly extracted EXIF SubSecCreateDate
    if [[ "${EXIF_SubSecCreateDate_OUTPUT}" != -* ]] && [[ "${EXIF_SubSecCreateDate_OUTPUT}" != 0* ]] ; then
      # Good data extracted, pass it to EXIFSubSecCreateDateParser to extract fields
      # from the EXIF info
      EXIFSubSecCreateDateParser $EXIF_SubSecCreateDate_OUTPUT
      # Check the extracted date for validity
      if [ $(IsValidDate ${YEAR} ${MONTH} ${DAY}) == 1 ]  ; then
        echo "A valid ${WHT}EXIFSubSecCreateDate${NML} was found, using it."
      else
        echo "Invalid ${WHT}EXIFSubSecCreateDate${NML} was found"
        DATE="InvalidDate"
      fi
      # Attempting to find an EXIF Model from the file, if it exists.
      EXIF_Model_OUTPUT=$(exiftool -s -f -Model ${WIPSortedFileAbsolutePath} | awk '{print $3"-"$4}')
      # Perform sanity check on correctly extracted EXIF Model
      if [[ "${EXIF_Model_OUTPUT}" != -* ]] ; then
        # Good data extracted, pass it to EXIFModelParser to extract fields
        # from the EXIF info
        EXIFModelParser $EXIF_Model_OUTPUT
      else
        # Fill Model manually if tag extraction fails
        MODEL="CAMERA"
      fi
    else
      # Attempt to find an EXIF CreateDate from the file, if it exists.
      EXIF_CreateDate_OUTPUT=$(exiftool -s -f -CreateDate ${WIPSortedFileAbsolutePath} | awk '{print $3":"$4}')
      echo "EXIF_CreateDate_OUTPUT is $EXIF_CreateDate_OUTPUT"
      # Perform sanity check on correctly extracted EXIF CreateDate
      if [[ "${EXIF_CreateDate_OUTPUT}" != -* ]] && [[ "${EXIF_CreateDate_OUTPUT}" != 0* ]] ; then
        # Good data extracted, pass it to EXIFCreateDateParser to extract fields
        # from the EXIF info
        EXIFCreateDateParser $EXIF_CreateDate_OUTPUT
        # Check the extracted date for validity
        if [ $(IsValidDate ${YEAR} ${MONTH} ${DAY}) == 1 ]  ; then
          echo "A valid ${WHT}EXIFCreateDate${NML} was found, using it."
        else
          echo "Invalid ${WHT}EXIFCreateDate${NML} was found"
          DATE="InvalidDate"
        fi
        # Attempting to find an EXIF Model from the file, if it exists.
        EXIF_Model_OUTPUT=$(exiftool -s -f -Model ${WIPSortedFileAbsolutePath} | awk '{print $3"-"$4}')
        # Perform sanity check on correctly extracted EXIF Model
        if [[ "${EXIF_Model_OUTPUT}" != -* ]] ; then
          # Good data extracted, pass it to EXIFModelParser to extract fields
          # from the EXIF info
          EXIFModelParser $EXIF_Model_OUTPUT
        else
          # Fill Model manually if tag extraction fails
          MODEL="CAMERA"
        fi
      else
        # Proceed to file attribute extraction if it is enabled
        if [[ ${FileSystemAttributeProcessingFlag} ]] ; then
          # If EXIF tag extracion failed, the last resort is file system file attributes
          #
          # Attempt to find a File System Modify Time mtime attribute from the file.
          FS_ModifyTime_OUTPUT=$(stat -c "%y" ${WIPSortedFileAbsolutePath} | awk '{print $1":"$2}')
          # Perform sanity check on correctly extracted File System mtime attribute
          if [[ "${FS_ModifyTime_OUTPUT}" != "" ]] && [[ "${FS_ModifyTime_OUTPUT}" != -* ]] && [[ "${FS_ModifyTime_OUTPUT}" != 0* ]] ; then
            # Good data extracted, pass it to FSModifyTimeParser to extract components
            FSModifyTimeParser $FS_ModifyTime_OUTPUT
            # Check the extracted date for validity
            if [ $(IsValidDate ${YEAR} ${MONTH} ${DAY}) == 1 ]  ; then
              echo "A valid ${WHT}FSModifyTime${NML} was found, using it."
            else
              echo "Invalid ${WHT}FSModifyTime${NML} was found"
              DATE="InvalidDate"
            fi
            # Fill Model manually, this attribute does not exist in File System
            MODEL="CAMERA" 
          fi
        # Proceed with "unverified" file name forming flag if file attribute extraction is disabled
        # or all previous attempts failed
        else
          UNVERIFIED=1
        fi
      fi
    fi
    # Add UNVERIFIED without changing the rest of filename if tag/attribute extraction failed.
    if [[ ${UNVERIFIED} -eq 1 ]] ; then
      UNVERIFIED="UNVERIFIED"
      FormatedFileName=${UNVERIFIED}-${WIPFileBasename}
    # Modify filename as per format if tag/attribute extraction is successful
    else
      FormatedFileName=${MODEL}-${YEAR}${MONTH}${DAY}-${HOUR}${MINUTE}${SECOND}-${SUBSECOND}.${NormalisedFileExtension}
      FormatedShortenFileName=${MODEL}-${YEAR}${MONTH}${DAY}-${HOUR}${MINUTE}${SECOND}-
    fi

    # Debug output
    if [[ ${DEBUG} -eq 1 ]] ; then DumpDebug ${WIPSortedFileAbsolutePath} $FormatedFileName $NormalisedFileExtension $DATE ${YEAR} ${MONTH} ${DAY} $HOUR $MINUTE $SECOND $SUBSECOND $MODEL "$NOTE" ; fi

    # Checking for Dry Run flag and moving the files from Work-In-Progress to Destination directory
    if [[ ${DRYRUN} -eq 0 ]] ; then
      # Checking if the destination is writable by creating Desination File Path, piping errors to NULL
      if ( ! mkdir -p ${DestinationPath}/${YEAR}/${MONTH}/${DAY} >/dev/null 2>&1 ) ; then
        printf "Error! Directory ${DestinationPath} does not appear to be writable, exiting\n"
        exit
      else
        # Checking if Destination FileName exists
        if [[ ! -f ${DestinationPath}/${YEAR}/${MONTH}/${DAY}/${FormatedFileName} ]] ; then        
          # Moving the file to the Desination File Path
          if ( ! mv ${WIPSortedFileAbsolutePath} ${DestinationPath}/${YEAR}/${MONTH}/${DAY}/${FormatedFileName} ) ; then
            printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${YEAR}/${MONTH}/${DAY}/${FormatedFileName} FAILED\n"
          else
            printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${YEAR}/${MONTH}/${DAY}/${FormatedFileName} ${NOTE} SUCCESSFUL\n"
          fi
        # If Destination FileName does exist, get all the names in the 
        #   Destination Directory matching the shortened file basename and process them to avoid duplicates
        else
          # Search for shortened file basename match
          MatchedFileNames=$(find ${DestinationPath}/${YEAR}/${MONTH}/${DAY} -maxdepth 1 -type f -iname "${FormatedShortenFileName}*.${NormalisedFileExtension}" )
          # Sorting file names to process them sequentially
          FileListSorter ${MatchedFileNames}
          # Returning the value from FileListSorter function by assigning the value of output (SortedFileList) to an array
          # Bash functions, unlike functions in most programming languages do not allow you to return values to the caller
          SortedMatchedFileNames=${SortedFileList}
          # Resetting SortedFileList array for sanity
          SortedFileList=""
          # Getting sha512sum message digest of the file
          WIPFileCheckSum=$(sha512sum ${WIPSortedFileAbsolutePath} | awk '{print $1}')
          # Defining checksum match variable for counting file duplicates
          CheckSumMatchCount=0
          # Defining an array for duplicate file paths in Destination directory
          DestinationDuplicateFiles=""
          # Compare the file's message digest with all matched files 
          for SortedMatchedFileName in ${SortedMatchedFileNames[@]} ; do
            # Getting sha512sum message digest of the file in the sorted array
            SortedMatchedFileNameCheckSum=$(sha512sum ${SortedMatchedFileName} | awk '{print $1}')
            # Checking if message digest match found
            if [[ ${WIPFileCheckSum} == ${SortedMatchedFileNameCheckSum} ]] ; then
              # Counting file duplicates
              ((CheckSumMatchCount+=1))
              # Collecting duplicate file paths
              DestinationDuplicateFiles+=(${SortedMatchedFileName})
            fi
          done
          # If message digest match was not found,  it means the Destination Directory contains 
          # files with the same file name and difference content, i.e. by-filename duplicates
          # Changing the SUBSECOND part by 000001 increment to make the filename unique
          if [[ CheckSumMatchCount -eq 0 ]] ; then
            # Getting the last member with highest SUBSECOND number in the sorted array of matched filenames
            LastSortedMatchedFileName=${SortedMatchedFileNames[@]: -1}
            # Extracting file basename
            LastSortedMatchedFileBasename=$(basename ${LastSortedMatchedFileName})
            # Extracting file name
            LastSortedMatchedFileName=${LastSortedMatchedFileName%.*} 
            # Extracting the SUBSECOND part
            LastSortedMatchedFileSubsecond=$(echo ${LastSortedMatchedFileName} | awk -F "-" '{print $4}')
            # Incrementing the SUBSECOND part so that we can form a new File Name
            printf -v IncrementedLastSortedMatchedFileSubsecond %06d "$((10#$LastSortedMatchedFileSubsecond + 1))"
            # Passing the incremented SUBSECOND to IncrementedSubsecond
            IncrementedSubsecond=${IncrementedLastSortedMatchedFileSubsecond}
            # Re-forming the File Name with the incremented SUBSECOND
            FormatedFileName=${MODEL}-${YEAR}${MONTH}${DAY}-${HOUR}${MINUTE}${SECOND}-${IncrementedSubsecond}.${NormalisedFileExtension}
            # Moving the file to the Desination File Path
            if ( ! mv ${WIPSortedFileAbsolutePath} ${DestinationPath}/${YEAR}/${MONTH}/${DAY}/${FormatedFileName} ) ; then
              printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${YEAR}/${MONTH}/${DAY}/${FormatedFileName} FAILED\n"
            else
              printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${YEAR}/${MONTH}/${DAY}/${FormatedFileName} ${NOTE} SUCCESSFUL\n"
            fi
          fi
          # Processing the WIP file if message digest match found in one file
          # Confirming the destination is writable by creating FileNameDuplicates file path, piping errors to NULL
          FileNameDuplicates="FileNameDuplicates"
          if [[ CheckSumMatchCount -eq 1 ]] ; then
            if ( ! mkdir -p ${DestinationPath}/${FileNameDuplicates}/${WIPDirectoryName} >/dev/null 2>&1 ) ; then
              printf "Error! Directory ${DestinationPath} does not appear to be writable, exiting\n"
              exit
            else
              # Moving the file to the FileNameDuplicates directory for review
              if ( ! mv ${WIPSortedFileAbsolutePath} ${DestinationPath}/${FileNameDuplicates}/${WIPDirectoryName}/${FormatedFileName} ) ; then
                printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${WIPDirectoryName}/${FormatedFileName} FAILED\n"
              else
                printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${WIPDirectoryName}/${FormatedFileName} ${NOTE} SUCCESSFUL\n"
              fi
            fi              
          fi
          # If the message digest match was more than once, it means the Destination Directory contains 
          # files with the same content and difference file names, i.e. by-content duplicates
          FileContentDuplicates="FileContentDuplicates"
          if [[ CheckSumMatchCount -gt 1 ]] ; then
            if ( ! mkdir -p ${DestinationPath}/${FileContentDuplicates}/${WIPDirectoryName} >/dev/null 2>&1 ) ; then
              printf "Error! Directory ${DestinationPath} does not appear to be writable, exiting\n"
              exit
            else
              # Since the array of duplicate file paths is already sorted, moving all but the first duplicate files 
              # from Destination Directory to the FileContentDuplicates directory for review.
              # That first file is treated as the original file
              for DestinationDuplicateFile in ${DestinationDuplicateFiles[@]:1} ; do 
                if ( ! mv ${DestinationDuplicateFile} "${DestinationPath}/${FileContentDuplicates}/${WIPDirectoryName}/" ) ; then
                  printf "Moving ${DestinationDuplicateFile} to '${DestinationPath}/${FileContentDuplicates}/${WIPDirectoryName}/' FAILED\n"
                else
                  printf "Moving ${DestinationDuplicateFile} to '${DestinationPath}/${FileContentDuplicates}/${WIPDirectoryName}/' ${NOTE} SUCCESSFUL\n"
                fi
              done
            fi              
          fi
        fi
      fi
    else
      echo "Dryrun: Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${YEAR}/${MONTH}/${DAY}/$FormatedFileName"
      echo
    fi
    # Clear the variables
    WIPSortedFileAbsolutePath=""; WIPFileBasename="";
    WIPFileName=""; WIPFileExtension=""; NormalisedFileExtension=""; FormatedFileName="";
    DATE=""; YEAR=""; MONTH=""; 
    DAY=""; HOUR=""; MINUTE=""; 
    SECOND=""; SUBSECOND=""; LONGSUBSECOND=""; 
    MODEL=""; NOTE=""; UNVERIFIED=""
  else
    echo
    echo "File ${WIPSortedFileAbsolutePath} not found!"
    echo
  fi
done
# At this stage all the files in the Work-In-Progress directory have been processed and move to other locations
# Removing empty Work-In-Progress directory, piping errors to NULL
if ( ! rmdir $WIPDirectoryPath >/dev/null 2>&1 ) ; then
  printf "Error while removing directory! Directory $WIPDirectoryPath does not appear to be empty or lock is in place, exiting\n"
  exit
else
  printf "Directory $WIPDirectoryPath has been removed successfully, exiting\n"
  exit
fi