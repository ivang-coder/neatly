#! /bin/bash

# Author: Ivan Gladushko
# Version: v1.7.2
# Date: 2022-01-02

# Knowledge Base:
#   Bash functions, unlike functions in most programming languages do not allow you to return values to the caller, i.e. use another variable to keep the results of the function. Alternatively, use "echo", i.e. echo "1" to return the result or boolian value

#=======================================================================
# Key variables and Default parameters
#=======================================================================
# Getting the name of script, <name>.<ext>
InstanceName="$(basename "${0}")"
# Stripping out the extension leaving just <name>
InstanceNameBase="${InstanceName%.*}"
# Setting Internal Field Separator (IFS) to new-line character to process filenames with spaces and other special characters
IFS=$'\n'
# Setting notification filename
NotificationFile="monitored-by-${InstanceNameBase}.info"
# Setting extension case switch to "ext" with ExtensionCaseSwitch, i.e. changing file extension case to lowercase
ExtensionCaseSwitch="ext"
# 1 = Enable and 0 = Disable less reliable file attribute extraction with FileSystemAttributeProcessingFlag
FileSystemAttributeProcessingFlag=0
# Resetting variables
LogOutput="##########################################\n"
FullHelpTip=""
# Setting Target Directory structure with TargetDirectoryStructure, i.e. YMD = YEAR/MONTH/DAY, YM = YEAR/MONTH, Y = YEAR, NOSORT = All
TargetDirectoryStructure="Y"
CUSTOM="All"
# Setting Source to Work-In-Progress (WIP) file transfer mode: <cp>, <mv> (default)
CopyMove="mv"
# Setting operations timer: <ON>, <OFF> (default)
OperationsTimer="OFF"
OperationsTimerLog="Operations timing (ms):\n"
# Setting crawl: <ON> depth level 3 (default), <OFF>
CrawlDepth="3"
# Setting variables
LogDate="$(date +%Y%m%d-%H%M%S)"
WIPDirectoryDate="${LogDate}"
LogFileDate="$(date +%Y%m%d)"
# Appending log variable
LogOutput+="${LogDate}\n"

#=======================================================================
# Help options
#=======================================================================
HelpTip="Help: for more parameters use '/bin/bash ${InstanceName} <-h|--help>'\n"
UsageTip="Usage: '/bin/bash ${InstanceName} <source-path|.> <destination-path|.> <--Ext|--EXT|--ext> <--FSAttribute|--NoFSAttribute> <--YMD|--YM|--Y|--NOSORT> <--copy|--move> <--timerON|--timerOFF> <--crawlON|--crawlOFF>\n  Mandatory parameters: source-path, destination-path\n"
SourcePathTip="Source absolute path is required with leading '/'. Alternatively use '.' for current directory.\n  Example: '/home/username/pictures/'\n"
DestinationPathTip="Destination absolute path is required with leading '/'. Alternatively, use '.' for current directory.\n  Example: '/mystorage/sorted-pictures/'\n"
ExtensionTip="Extension case switch options: \n  --ExT = unchanged, i.e. JPEG > JPEG, jpeg > jpeg\n  --EXT = uppercase, i.e. jpeg > JPEG \n  --ext (default) = lowercase, i.e. JPEG > jpeg\n"
FSAttributeTip="File system attribute extraction is quite unreliable and can be used as the last resort.\n  If enabled with --FSAttribute, it can cause conflicts and affect file sorting.\n  --NoFSAttribute (default) is the recommended option.\n"
YMDTip="Destination files sort-by options:\n  --YMD = YEAR/MONTH/DAY/picture.jpg, i.e. 2021/05/10/picture.jpg\n  --YM (default) = YEAR/MONTH/picture.jpg, i.e. 2021/05/picture.jpg\n  --Y = YEAR, i.e. 2021/picture.jpg\n  --NOSORT = All (Custom), i.e. Destination/All\n"
CopyMoveTip="Source to Work-In-Progress (WIP) file transfer mode: \n  --copy = copy files,\n  --move = move files (default)\n"
OperationsTimerTip="Operations timer (monitoring, debug): \n  --timerON = display and log operation timings,\n  --timerOFF = do not display and log operation timings (default)\n"
CrawlTip="Crawl parameters: \n  --crawlON = process Source and its subfolders 3 levels deep (default),\n  --crawlOFF = process Source directory only, i.e. Source files at root with no subfolders\n"
FullHelpTip+="${UsageTip}${SourcePathTip}${DestinationPathTip}${ExtensionTip}${FSAttributeTip}${YMDTip}${CopyMoveTip}${OperationsTimerTip}${CrawlTip}\n"

# End of Forming help menu options

#=======================================================================
# Functions
#=======================================================================
# IsValidDate verifies the Year, Month and Day variables contain values
#   within the expected range, i.e. it catches potential rubbish.
#   Returns: 0 = invalid date, 1 = valid date
IsValidDate() {
  # Define variables and pass the arguments for ${YEAR} ${MONTH} ${DAY}
  Year="$1"
  Month="$2"
  Day="$3"
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

# EXIFSubSecCreateDateParser extracts EXIF metadata: the year, month, day, hour, minute, second, subsecond,
# and generates date and note
EXIFSubSecCreateDateParser() {
  # Define a variable and pass the arguments
  EXIF_OUTPUT="${1}"
  # Substitute dots with a common colon delimiter
  EXIF_OUTPUT_SUBSTITUTE="${EXIF_OUTPUT//./:}"
  # Define delimiter
  DELIMITER=":"
  # Concatenate the delimiter with the main string
  DELIMITED_EXIF_OUTPUT="${EXIF_OUTPUT_SUBSTITUTE}${DELIMITER}"
  # Split the text based on the delimiter
  EXIF_OUTPUT_ARRAY=()
  while [[ "${DELIMITED_EXIF_OUTPUT}" ]]; do
    EXIF_OUTPUT_ARRAY+=( "${DELIMITED_EXIF_OUTPUT%%${DELIMITER}*}" )
    DELIMITED_EXIF_OUTPUT="${DELIMITED_EXIF_OUTPUT#*${DELIMITER}}"
  done
  # Assign the array values to the corresponding variables
  YEAR="${EXIF_OUTPUT_ARRAY[0]}"
  MONTH="${EXIF_OUTPUT_ARRAY[1]}"
  DAY="${EXIF_OUTPUT_ARRAY[2]}"
  HOUR="${EXIF_OUTPUT_ARRAY[3]}"
  MINUTE="${EXIF_OUTPUT_ARRAY[4]}"
  SECOND="${EXIF_OUTPUT_ARRAY[5]}"
  SUBSECOND="${EXIF_OUTPUT_ARRAY[6]}"
  DATE="${YEAR}:${MONTH}:${DAY}"
}

# EXIFCreateDateParser extracts EXIF metadata: the year, month, day, hour, minute, second,
# and generates subsecond, date and note
EXIFCreateDateParser() {
  # Define a variable and pass the arguments
  EXIF_OUTPUT="${1}"
  # Substitute dots with a common colon delimiter
  EXIF_OUTPUT_SUBSTITUTE="${EXIF_OUTPUT//./:}"
  # Define delimiter
  DELIMITER=":"
  # Concatenate the delimiter with the main string
  DELIMITED_EXIF_OUTPUT="${EXIF_OUTPUT_SUBSTITUTE}${DELIMITER}"
  # Split the text based on the delimiter
  EXIF_OUTPUT_ARRAY=()
  while [[ "${DELIMITED_EXIF_OUTPUT}" ]]; do
    EXIF_OUTPUT_ARRAY+=( "${DELIMITED_EXIF_OUTPUT%%${DELIMITER}*}" )
    DELIMITED_EXIF_OUTPUT="${DELIMITED_EXIF_OUTPUT#*${DELIMITER}}"
  done
  # Assign the array values to the corresponding variables
  YEAR="${EXIF_OUTPUT_ARRAY[0]}"
  MONTH="${EXIF_OUTPUT_ARRAY[1]}"
  DAY="${EXIF_OUTPUT_ARRAY[2]}"
  HOUR="${EXIF_OUTPUT_ARRAY[3]}"
  MINUTE="${EXIF_OUTPUT_ARRAY[4]}"
  SECOND="${EXIF_OUTPUT_ARRAY[5]}"
  SUBSECOND="000000"
  DATE="${YEAR}:${MONTH}:${DAY}"
}

# FSModifyTimeParser extracts File System attributes: the year, month, day, hour, minute, second, subsecond
# and generates date and note
FSModifyTimeParser() {
  # Define a variable and pass the arguments
  MTIME_OUTPUT="${1}"
  # Substitute dots with a common colon delimiter
  MTIME_OUTPUT_SUBSTITUTE="${MTIME_OUTPUT//-/:}"
  MTIME_OUTPUT_SUBSTITUTE="${MTIME_OUTPUT_SUBSTITUTE//./:}"
  # Define delimiter
  DELIMITER=":"
  # Concatenate the delimiter with the main string
  DELIMITED_MTIME_OUTPUT="${MTIME_OUTPUT_SUBSTITUTE}${DELIMITER}"
  # Split the text based on the delimiter
  MTIME_OUTPUT_ARRAY=()
  while [[ "${DELIMITED_MTIME_OUTPUT}" ]]; do
    MTIME_OUTPUT_ARRAY+=( "${DELIMITED_MTIME_OUTPUT%%${DELIMITER}*}" )
    DELIMITED_MTIME_OUTPUT="${DELIMITED_MTIME_OUTPUT#*${DELIMITER}}"
  done
  # Assign the array values to the corresponding variables
  YEAR="${MTIME_OUTPUT_ARRAY[0]}"
  MONTH="${MTIME_OUTPUT_ARRAY[1]}"
  DAY="${MTIME_OUTPUT_ARRAY[2]}"
  HOUR="${MTIME_OUTPUT_ARRAY[3]}"
  MINUTE="${MTIME_OUTPUT_ARRAY[4]}"
  SECOND="${MTIME_OUTPUT_ARRAY[5]}"
  LONGSUBSECOND="${MTIME_OUTPUT_ARRAY[6]}"
  SUBSECOND="${LONGSUBSECOND:0:6}"
  DATE="${YEAR}:${MONTH}:${DAY}"
}

# EXIFModelParser extracts EXIF metadata: the model 
# and manupulates characters
EXIFModelParser() {
  # Define a variable and pass the arguments
  EXIF_OUTPUT="${1}"
  # Remove colons by substituting characters with nothing
  EXIF_OUTPUT_SUBSTITUTE="${EXIF_OUTPUT//:/}"
  MODEL="${EXIF_OUTPUT_SUBSTITUTE}"
}

# FileListSorter sorts the items in array alphabetically
# LC_ALL=C to get the traditional sort order that uses native byte values
FileListSorter(){
  #ListToSort="$1"
  FileListSorterResult="$(printf '%s\n' "$@" | LC_ALL=C sort)"
  #FileListSorterResult=$(printf '%s\n' "${ListToSort}" | LC_ALL=C sort)
  LogOutput+="Exiting FileListSorter with Result:\n${FileListSorterResult}\n"
  LogOutput+="#####################\n"
}

# DigestComparison compares the file's message digest with all matched files 
DigestComparison(){
  # Defining a variable and passing the argument for source checksum
  DigestComparisonSource="${1}"
    # Defining a variable and passing the argument for the list of files as DigestComparisonDestinationFileList
  DigestComparisonDestinationFileList="${2}"
    # Getting sha512sum message digest of the file
  DigestComparisonSourceCheckSum="$(sha512sum "${DigestComparisonSource}" | awk '{print $1}')"
  for DigestComparisonFileName in ${DigestComparisonDestinationFileList[@]} ; do
    # Getting sha512sum message digest of the file in the array
    DigestComparisonFileNameCheckSum="$(sha512sum "${DigestComparisonFileName}" | awk '{print $1}')"
    LogOutput+="Comparing SourceCheckSum ${DigestComparisonSourceCheckSum} with FileNameCheckSum ${DigestComparisonFileNameCheckSum}\n"
    # Checking if message digest match found
    if [[ "${DigestComparisonSourceCheckSum}" == "${DigestComparisonFileNameCheckSum}" ]] ; then
      # Counting file duplicates
      ((DigestComparisonCheckSumMatchCount+=1))
      # Collecting duplicate file paths
      DestinationDuplicateFiles+=("${DigestComparisonFileName}")
    fi
  done
  DigestComparisonFileList="${DestinationDuplicateFiles}"
}

# FileNameIncrementer increments the SUBSECOND part to form a unique filename suffix
FileNameIncrementer(){
  # Resetting variables
  FileNameToIncrement=""
  FileNameToIncrementBasename=""
  FileNameToIncrementFileName=""
  FileNameToIncrementElement=""
  IncrementedElement=""
  FileNameIncrementerResult=""
  # Passing the last member with highest SUBSECOND number in the sorted array of filenames
  FileNameToIncrement="${1}"
  # Extracting file basename
  FileNameToIncrementBasename="$(basename "${FileNameToIncrement}")"
  # Extracting file name
  FileNameToIncrementFileName="${FileNameToIncrementBasename%.*}"
  # Extracting the Element, i.e. SUBSECOND part
  FileNameToIncrementElement="$(echo "${FileNameToIncrementFileName}" | awk -F "-" '{print $4}')"
  # Incrementing the Element so that we can form a new File Name
  printf -v IncrementedElement %06d "$((10#${FileNameToIncrementElement} + 1))"
  # Passing the incremented Element to FileNameIncrementerResult
  FileNameIncrementerResult="${IncrementedElement}"
}

# FileNameDuplicateIncrementer increments the DUP*** part to form a unique filename suffix
FileNameDuplicateIncrementer(){
  # Resetting variables
  FileNameDuplicateToIncrement=""
  FileNameDuplicateToIncrementBasename=""
  FileNameDuplicateToIncrementFileName=""
  FileNameDuplicateToIncrementElement=""
  DuplicateIncrementedElement=""
  FileNameDuplicateIncrementerResult=""
  # Passing the last member with highest DUP*** number in the sorted array of filenames
  FileNameDuplicateToIncrement="${1}"
  # Extracting file basename
  FileNameDuplicateToIncrementBasename="$(basename "${FileNameDuplicateToIncrement}")"
  # Extracting file name
  FileNameDuplicateToIncrementFileName="${FileNameDuplicateToIncrementBasename%.*}"
  # Extracting the Element, i.e. DUP*** part
  FileNameDuplicateToIncrementElement="$(echo "${FileNameDuplicateToIncrementFileName}" | awk -F "-" '{print $5}')"
  # Extracting the numerical part of Element, i.e. *** part
  FileNameDuplicateToIncrementElement="${FileNameDuplicateToIncrementFileName: -3}"
  # Checking if DUP*** is extracted
  if [[ ! "${FileNameDuplicateToIncrementElement}" ]]; then
    # Changing the Element to 000 if nothing was extracted
    DuplicateIncrementedElement="000"
  else
    # Incrementing the Element so that we can form a new File Name
    printf -v DuplicateIncrementedElement %03d "$((10#$FileNameDuplicateToIncrementElement + 1))"
  fi
  # Passing the incremented Element to FileNameDuplicateIncrementerResult
  FileNameDuplicateIncrementerResult="${DuplicateIncrementedElement}"
}

# FileNameUnverifiedIncrementer increments the UVRFD*** part to form a unique filename suffix
FileNameUnverifiedIncrementer(){
  # Resetting variables
  FileNameUnverifiedToIncrement=""
  FileNameUnverifiedToIncrementBasename=""
  FileNameUnverifiedToIncrementFileName=""
  FileNameUnverifiedToIncrementElement=""
  UnverifiedIncrementedElement=""
  FileNameUnverifiedIncrementerResult=""
  # Passing the last member with highest UVRFD*** number in the sorted array of filenames
  FileNameUnverifiedToIncrement="${1}"
  # Extracting file basename
  FileNameUnverifiedToIncrementBasename="$(basename "${FileNameUnverifiedToIncrement}")"
  # Extracting file name
  FileNameUnverifiedToIncrementFileName="${FileNameUnverifiedToIncrementBasename%.*}"
  # Extracting the Element, i.e. UVRFD*** part
  FileNameUnverifiedToIncrementElement="$(echo "${FileNameUnverifiedToIncrementFileName}" | awk -F "-" '{print $NF}')"
  # Extracting the numerical part of Element, i.e. *** part
  FileNameUnverifiedToIncrementElement="${FileNameUnverifiedToIncrementFileName: -3}"
  # Checking if DUP*** is extracted
  if [[ ! "${FileNameUnverifiedToIncrementElement}" ]]; then
    # Changing the Element to 000 if nothing was extracted
    UnverifiedIncrementedElement="000"
  else
    # Incrementing the Element so that we can form a new File Name
    printf -v UnverifiedIncrementedElement %03d "$((10#$FileNameUnverifiedToIncrementElement + 1))"
  fi
  # Passing the incremented Element to FileNameUnverifiedIncrementerResult
  FileNameUnverifiedIncrementerResult="${UnverifiedIncrementedElement}"
}


# FileListToArray converts string to array and outputs the array, count of elements and the last element
FileListToArray(){
  # Resetting variables
  SortedMatchedFileNames=""
  TempArray=()
  FileListToArrayResult=()
  FileListToArrayCount=0
  FileListToArrayLastElement=""
  # Passing the list of filenames
  SortedMatchedFileNames="${1}"
  # Taking each element and adding to the array
  TempArray=("${TempArray[@]}" "${SortedMatchedFileNames[@]}")
  # Passing the resulted array to FileListToArrayResult
  FileListToArrayResult="${TempArray[@]}"
#  LogOutput+="FileListToArrayResult is \n${FileListToArrayResult}\n"
  # Counting the length of array and passing it to FileListToArrayCount
  FileListToArrayCount="${#TempArray[@]}"
#  LogOutput+="FileListToArrayCount is ${FileListToArrayCount}\n"
  # Passing the last element of array to FileListToArrayLastElement
  FileListToArrayLastElement="${TempArray[@]: -1}"
#  LogOutput+="FileListToArrayLastElement is ${FileListToArrayLastElement}\n"
}

# DuplicateSearch searches for filenames with matching basename
DuplicateSearch(){
  # Resetting variables
  DuplicateSearchResult=""
  # Passing parameters to variables
  PathToSearch="${1}"
  FileNameToSearch="${2}"
  FileExtensionToSearch="${3}"
  # Search for file basename match
  DuplicateSearchResult="$(find "${PathToSearch}" -maxdepth 1 -type f -iname "${FileNameToSearch}*.${FileExtensionToSearch}" | sort -n)"
  LogOutput+="Search for duplicate file basename match ${FileNameToSearch}*.${FileExtensionToSearch} reveals: \n${DuplicateSearchResult}\n"
}

# LogDumper makes an output to log file, and exists the programme
LogDumper(){
  # Passing parameters to variables
  LogDumperLogOuput="${1}"
  # Writing to log file
  printf "Writing to log file ${DestinationPath}/${LogFileName}\n"
  printf "${LogDumperLogOuput}" >> "${DestinationPath}/${LogFileName}"
  printf "Exiting now.\n"
  exit
}

#=======================================================================
# Script starts here
#=======================================================================

# Prerequisite Checks begins
#
# Checking for absence of other running neatly-sorted instances and excluding the "grep" from the output and counting the number of lines
InstanceCount="$(ps -ef | grep "${InstanceNameBase}" | grep -v grep | wc -l)"
# In a common scenario "ps" command will be running in a child process (sub-shell) 
# with the name matching the script name, hence we're checking if there are
# more than 2 instances
if [[ "${InstanceCount}" > 2 ]]; then
  printf "Prerequisite Critical Error! It appears more than one ${InstanceName} instance is running. Exiting now.\n"
  exit
fi

# Checking for BASH version, v4+ is required
if [[ "${BASH_VERSINFO}" < 4 ]]; then
  printf "Prerequisite Critical Error! Non-supported BASH version ${BASH_VERSINFO} is identified. BASH version 4+ is required. Exiting now.\n"
  exit
else
  BASHVERSION="${BASH_VERSION}"
  LogOutput+="BASH version: ${BASHVERSION}\n"
fi

# Checking if application or service is installed, piping errors to NULL
if ( ! command -v sha512sum &> /dev/null ) ; then
  printf "Prerequisite Critical Error! 'sha512sum' is not installed or it could not be found. Use the commands below to install\n"
  printf " CentOS/RHEL: sudo dnf update && sudo dnf install coreutils\n"
  printf " Ubuntu: sudo apt update && sudo apt upgrade && sudo apt install coreutils\n"
  printf " Mac: brew install coreutils\n"
  printf " QNAP (Entware): opkg install coreutils-sha512sum\n"
  printf "Exiting now.\n"
  exit
else
  SHA512SUMUTIL="$(sha512sum --version | head -n1 | awk '{print $4}')"
  LogOutput+="sha512sum version: ${SHA512SUMUTIL}\n"
fi
if ( ! command -v exiftool &> /dev/null ) ; then
  printf "Prerequisite Critical Error! 'exiftool' is not installed or it could not be found. Use the commands below to install\n"
  printf " CentOS/RHEL: sudo dnf update && sudo dnf install perl-Image-ExifTool\n"
  printf " Ubuntu: sudo apt update && sudo apt upgrade && sudo apt install libimage-exiftool-perl\n"
  printf " Mac: brew install exiftool\n"
  printf " QNAP (Entware): opkg install perl-image-exiftool\n"
  printf "Exiting now.\n"
  exit
else
  EXIFTOOLVER="$(exiftool -ver)"
  LogOutput+="exiftool version: ${EXIFTOOLVER}\n"
fi

# Checking minimal requirements for the arguments, expecting at least one argument
if [[ "${#}" -lt 1 ]] ; then
  printf "Prerequisite Critical Error! At least one argument is expected. Exiting now.\n"
  printf "${HelpTip}"
  exit
fi

# Checking if the first argument exists and processing it
case "${1}" in 
  # Checking if the first argument is a call for help
  -h|--help)
    printf "${FullHelpTip}\n"
    exit
    ;;
  # Checking if the first argument is a file source path and validating it
  /*|.) 
    # Exiting if there are issues with the source path
    # "-e file" returns true if file exists
    # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
    if [[ ! -e "${1}" ]] ; then
      printf "Prerequisite Critical Error! Source path ${1} could not be found or does not exist. Exiting now.\n"
      printf "${SourcePathTip}\n"
      exit
    else
      # Passing the source path to a variable and continue
      SourcePath="${1}"
    fi
    ;;
  # Exiting if no expected parameter found
  *) 
    printf "Prerequisite Critical Error! Mandatory source path is invalid or could not be identified: ${1}. Exiting now.\n"
    printf "${UsageTip}${SourcePathTip}"
    exit
    ;;
esac

# Checking if the second argument exists and processing it
case "${2}" in 
  # Checking if the second argument is a file destination path and validating it
  /*|.) 
    # Exiting if there are issues with the destination path
    # "-e file" returns true if file exists
    # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
    if [[ ! -e "${2}" ]] ; then
      printf "Prerequisite Critical Error! Destination path ${2} could not be found or does not exist. Exiting now.\n"
      printf "${DestinationPathTip}\n"
      exit
    else
      # Passing the destination path to a variable and continue
      DestinationPath="${2}"
    fi
    ;;
  # Exiting if no expected parameter found
  *) 
    printf "Prerequisite Critical Error! Mandatory destination path is invalid or could not be identified: ${2}. Exiting now.\n"
    printf "${UsageTip}${DestinationPathTip}"
    exit
    ;;
esac

# Processing optional paramenters
#
# Checking if more than 2 arguments have been passed and processing them.
if [[ "${#}" -gt 2 ]] ; then
  # Validating optional parameters starting with the third parameter
  for Argument in "${@:3}" ; do
    case "${Argument}" in 
      # Checking if the argument is an extension case switch and validating it
      --ExT)
        # Setting extension case switch to "ExT" with ExtensionCaseSwitch, i.e. changing file extension case to UnChanged
        ExtensionCaseSwitch="ExT"
        ;;
      # Checking if the argument is an extension case switch and validating it
      --EXT)
        # Setting extension case switch to "EXT" with ExtensionCaseSwitch, i.e. changing file extension case to UPPERCASE
        ExtensionCaseSwitch="EXT"
        ;;
      # Checking if the argument is an extension case switch and validating it
      --ext)
        # Setting extension case switch to "ext" with ExtensionCaseSwitch, i.e. changing file extension case to lowercase
        ExtensionCaseSwitch="ext"
        ;;
      # Checking if the argument is a file system attribute extraction flag and validating it
      --NoFSAttribute)
        # 0 = Disable less reliable file attribute extraction
        FileSystemAttributeProcessingFlag=0
        ;;
      # Checking if the argument is a file system attribute extraction flag and validating it
      --FSAttribute)
        # 1 = Enable and 0 = Disable less reliable file attribute extraction with FileSystemAttributeProcessingFlag
        FileSystemAttributeProcessingFlag=1
        ;;
      # Checking if the argument is a directory structure switch and validating it
      --YMD)
        # Setting Target Directory structure with TargetDirectoryStructure to YMD = YEAR/MONTH/DAY
        TargetDirectoryStructure="YMD"
        ;;
      # Checking if the argument is a directory structure switch and validating it
      --YM)
        # Setting Target Directory structure with TargetDirectoryStructure to YM = YEAR/MONTH
        TargetDirectoryStructure="YM"
        ;;
      # Checking if the argument is a directory structure switch and validating it
      --Y)
        # Setting Target Directory structure with TargetDirectoryStructure to Y = YEAR
        TargetDirectoryStructure="Y"
        ;;
      # Checking if the argument is a directory structure switch and validating it
      --NOSORT)
        # Setting Target Directory structure with TargetDirectoryStructure to NOSORT = All file in the root of Destination
        TargetDirectoryStructure="NOSORT"
        ;;
      # Checking if the argument is a copy-move switch and validating it
      --copy)
        # Setting the operation for transferring files from Source to Work-In-Progress (WIP) folder as "copy"
        CopyMove="cp"
        ;;
      # Checking if the argument is a copy-move switch and validating it
      --move)
        # Setting the operation for transferring files from Source to Work-In-Progress (WIP) folder as "move"
        CopyMove="mv"
        ;;
      # Checking if the argument is operations timer switch and validating it
      --timerON)
        # Setting the operations timer ON, i.e. display and log operation timings
        OperationsTimer="ON"
        ;;
      # Checking if the argument is operations timer switch and validating it
      --timerOFF)
        # Setting the operations timer OFF, i.e. do not display and log operation timings
        OperationsTimer="OFF"
        ;;
      # Checking if the argument is crawl switch and validating it
      --crawlON)
        # Setting the crawl ON, i.e. process Source and its subfolders 3 levels deep
        CrawlDepth="3"
        ;;
      # Checking if the argument is crawl switch and validating it
      --crawlOFF)
        # Setting the crawl ON, i.e. process Source directory only, i.e. Source files at root with no subfolders
        CrawlDepth="1"
        ;;
      # Skipping if no expected parameter found
      *) 
        printf "Prerequisite Critical Error! Unexpected parameter detected: ${Argument}, ignoring it\n"
        ;;
    esac
  done
# Applying default parameters if the required arguments have not been passed
else
  LogOutput+="No optional parameters have been passed. Applying the defaults.\n"
fi
# Writing the aggregate of parameters to the log file
LogOutput+="Proceeding with parameters below.\n" 
LogOutput+="  Mandatory parameters:\n"
LogOutput+="    Source path: ${SourcePath}\n"
LogOutput+="    Destination path: ${DestinationPath}\n"
LogOutput+="  Optional parameters:\n"
LogOutput+="    File extension case: "
case "${ExtensionCaseSwitch}" in 
  ExT)
    LogOutput+="UnChanged\n"
    ;;
  EXT)
    LogOutput+="UPPERCASE\n"
    ;;
  ext)
    LogOutput+="lowercase\n"
    ;;
esac
LogOutput+="    File attribute extraction: "
if [[ "${FileSystemAttributeProcessingFlag}" -eq 1 ]]; then 
  LogOutput+="ENABLED\n" 
else 
  LogOutput+="DISABLED\n";
fi
LogOutput+="    Destination files sorted by: "
case "${TargetDirectoryStructure}" in 
  YMD)
    LogOutput+="YEAR/MONTH/DAY/\n"
    ;;
  YM)
    LogOutput+="YEAR/MONTH/\n"
    ;;
  Y)
    LogOutput+="YEAR/\n"
    ;;
  NOSORT)
    LogOutput+="/${CUSTOM}/\n"
    ;;
esac
LogOutput+="    Source to Work-In-Progress (WIP) file transfer mode: "
case "${CopyMove}" in 
  cp)
    LogOutput+="COPY\n"
    ;;
  mv)
    LogOutput+="MOVE\n"
    ;;
esac
LogOutput+="    Operations timer (monitoring, debug): "
case "${OperationsTimer}" in 
  ON)
    LogOutput+="ON\n"
    ;;
  OFF)
    LogOutput+="OFF\n"
    ;;
esac
LogOutput+="    Crawl mode: "
case "${CrawlDepth}" in 
  3)
    LogOutput+="ON, Source and ${CrawlDepth} level deep\n"
    ;;
  1)
    LogOutput+="OFF, Source root files only\n"
    ;;
esac

# Printing the aggregate of parameters to the screen
printf "${LogOutput}\n"
#
# Path normalisation
#
# Checking if trailing "/" has been passed with the source path
# The space after the colon ":" is REQUIRED. This approach will not work without the space.
if [[ "${SourcePath: -1}" == '/' ]] ; then
  # Removing trailing "/" if it has been passed with the source path
  # For bash 4.2 and above, can do ${var::-1}, otherwise ${var: : -1}
  SourcePath="${SourcePath: : -1}"
fi
# Checking if trailing "/" has been passed with the destination path
# The space after the colon ":" is REQUIRED. This approach will not work without the space.
if [[ "${DestinationPath: -1}" == '/' ]] ; then
  # Removing trailing "/" if it has been passed with the destination path
  # For bash 4.2 and above, can do ${var::-1}, otherwise ${var: : -1}
  DestinationPath="${DestinationPath: : -1}"
fi

# Forming various names
#
# Forming log filename name in neatly-sorted-YYYYMMDD.log format
LogFileName="${InstanceNameBase}-${LogFileDate}.log"
# Forming Work-In-Progress directory name in WIP-YYYYMMDD-HHmmss format
WIPDirectoryName="WIP-${WIPDirectoryDate}"
WIPDirectoryPath="${SourcePath}/${WIPDirectoryName}"
# Forming directory name for file duplicates
FileNameDuplicates="Duplicates"
# Forming directory name for unverified files
UnverifiedFiles="Unverified"

# Prerequisite check for r+w permissions
## Taking operations timer snapshot
OperationsTimerStart=$(date +%s%3N)
## Checking if the source directory is writable by creating a notification file, piping errors to NULL
if ( ! touch "${SourcePath}/${NotificationFile}" >/dev/null 2>&1 ) ; then
  printf "Prerequisite Critical Error! Could not write ${SourcePath}/${NotificationFile}. Directory ${SourcePath} does not appear to be writable. Exiting now.\n"
  exit
else
  PrerequisitesOK=1
fi
## Checking if the source directory is writable by creating Work-In-Progress folder, piping errors to NULL
if ( ! mkdir -p "${WIPDirectoryPath}" >/dev/null 2>&1 ) ; then
  printf "Prerequisite Critical Error! Could not write ${WIPDirectoryPath}. Directory ${SourcePath} does not appear to be writable. Exiting now.\n"
  exit
else
  PrerequisitesOK=1
fi
## Cheking if the destination directory is writable by creating Duplicates folder, piping errors to NULL
if ( ! mkdir -p "${DestinationPath}/${FileNameDuplicates}" >/dev/null 2>&1 ) ; then
  printf "Prerequisite Critical Error! Could not write ${FileNameDuplicates}. Directory ${DestinationPath} does not appear to be writable. Exiting now.\n"
  exit
else
  PrerequisitesOK=1
fi
## Cheking if the destination directory is writable by creating UnverifiedFiles folder, piping errors to NULL
if ( ! mkdir -p "${DestinationPath}/${UnverifiedFiles}" >/dev/null 2>&1 ) ; then
  printf "Prerequisite Critical Error! Could not write ${UnverifiedFiles}. Directory ${DestinationPath} does not appear to be writable. Exiting now.\n"
  exit
else
  PrerequisitesOK=1
fi
## Cheking if the destination directory is writable by creating Log file, piping errors to NULL
if ( ! touch "${DestinationPath}/${LogFileName}" >/dev/null 2>&1 ) ; then
  printf "Prerequisite Critical Error! Could not write ${LogFileName}. Directory ${DestinationPath} does not appear to be writable. Exiting now.\n"
  exit
else
  PrerequisitesOK=1
fi
## Taking operations timer snapshot, counting and registering operations timing
OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Prerequisites: ${OperationsTimerResult}\n"
# End of Prerequisite Checks

# Checking files in source directory
# Taking operations timer snapshot
OperationsTimerStart=$(date +%s%3N)
### Confirming files with specific video and image extensions in source directory and its subfolders, ingoring hidden folders and files with leading "."
SourceFileCheck="$(find "${SourcePath}" -maxdepth "${CrawlDepth}" -not -path '*/\.*' -type f -iname "*.[JjGg][PpIi][GgFf]" -or \
-iname "*.[Jj][Pp][Ee][Gg]" -or \
-iname "*.[Mm][PpOo][Gg4Vv]" | sort -n)"
### Checking the number of fetched files before proceeding further
if [[ "${SourceFileCheck[@]: -1}" == "" ]] ; then 
  FilesFetched=0
else
  FilesFetched=1
fi
## Taking operations timer snapshot, counting and registering operations timing
OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Source file check search: ${OperationsTimerResult}\n"
# Display operation timings
printf "${OperationsTimerLog}"
# Log operation timings
LogOutput+="${OperationsTimerLog}"
# Reset operations timing variable
OperationsTimerLog="Operations timing (ms):\n"

# Seaching and moving files from source to Work-In-Progress directory
if [[ ${PrerequisitesOK} -eq 1 ]] && [[ ${FilesFetched} -eq 1 ]] ; then
  ## Taking operations timer snapshot
  OperationsTimerStart=$(date +%s%3N)
  # Passing Source folder name, i.e. no path
  SourcePathBasename="$(basename "${SourcePath}")"
  # Resetting variables
  SourceFileMoveSuccessCount=0
  SourceFileMoveFailureCount=0
  SourceFileNotFoundCount=0
  ## Descending to the Source to get the list of subfolders with relative paths
  cd "${SourcePath}"
  ## Changing CrawlDepth (maxdepth) due to the descend to Source if Crawl is enabled
  CrawlDepth=$(( CrawlDepth - 1))
  ## Searching for folders in source directory
  SourceFolderList="$(find . -maxdepth "${CrawlDepth}" -not -path '*/\.*' -type d | sort -n)"
  ## Confirming the folder list is not empty, ${#VAR} calculates the number of characters in a variable
  if [ "${#SourceFolderList}" != 0 ] ; then
    for SourceSubFolder in ${SourceFolderList[@]} ; do
      # Ensure the file exists, then proceed with processing
      # "-e file" returns true if file exists
      # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
      # ${#VAR} calculates the number of characters in a variable
      if [ -e "${SourceSubFolder}" ] && [ "${#SourceSubFolder}" != 0 ] ; then
        ### Searching for files with specific video and image extensions in source directory
        SourceSubfolderFileList="$(find "${SourceSubFolder}" -maxdepth 1 -not -path '*/\.*' -type f -iname "*.[JjGg][PpIi][GgFf]" -or \
        -iname "*.[Jj][Pp][Ee][Gg]" -or \
        -iname "*.[Mm][PpOo][Gg4Vv]" | sort -n)"
        ### Checking the number of fetched files before proceeding further
        if [[ "${SourceSubfolderFileList[@]: -1}" != "" ]] ; then 
          # Stripping out leading "./"
          if [[ "${SourceSubFolder}" != "." ]] ; then SourceSubFolder="${SourceSubFolder#./}" ; fi
          #### Displaying and logging the actions for the root of Source
          if [[ "${SourceSubFolder}" == "." ]] ; then
            printf "Transferring files from ${SourceSubFolder} in Source to Work-In-Progress ${WIPDirectoryPath}/${SourcePathBasename} directory for processing\n"
            LogOutput+="Transferring files from ${SourceSubFolder} in Source to Work-In-Progress ${WIPDirectoryPath}/${SourcePathBasename} directory for processing\n"
          #### Displaying and logging the actions for Source subfolders
          else
            printf "Transferring files from ${SourceSubFolder} in Source to Work-In-Progress ${WIPDirectoryPath}/${SourceSubFolder} directory for processing\n"
            LogOutput+="Transferring files from ${SourceSubFolder} in Source to Work-In-Progress ${WIPDirectoryPath}/${SourceSubFolder} directory for processing\n"
          fi
          #### Creating subfolder in Work-In-Progress directory for file processing, piping errors to NULL
          if [[ "${SourceSubFolder}" == "." ]] ; then
            if ( ! mkdir -p "${WIPDirectoryPath}/${SourcePathBasename}" >/dev/null 2>&1 ) ; then
              printf "Critical Error! Could not write ${SourceSubFolder}. Directory ${WIPDirectoryPath}/${SourcePathBasename} does not appear to be writable.\n"
              LogOutput+="Critical Error! Could not write ${SourceSubFolder}. Directory ${WIPDirectoryPath}/${SourcePathBasename} does not appear to be writable.\n"
              LogDumper "${LogOutput}"
            fi
          else
            if ( ! mkdir -p "${WIPDirectoryPath}/${SourceSubFolder}" >/dev/null 2>&1 ) ; then
              printf "Critical Error! Could not write ${SourceSubFolder}. Directory ${WIPDirectoryPath}/${SourceSubFolder} does not appear to be writable.\n"
              LogOutput+="Critical Error! Could not write ${SourceSubFolder}. Directory ${WIPDirectoryPath}/${SourceSubFolder} does not appear to be writable.\n"
              LogDumper "${LogOutput}"
            fi
          fi
          # Taking one file at a time and processing it
          #
          # File path composition
          #   SourceFileAbsolutePath = SourceDirectoryPath + SourceFileBasename, where
          #     SourceFileBasename = SourceFileName + SourceFileExtension
          #
          for SourceSubfolderFile in ${SourceSubfolderFileList[@]}; do
            #### Note, each file is in ./SubFolder/SubFolerFile format
            ####
            #### Stripping out leading "./" from each file, i.e. converting to SubFolder/SubFolerFile
            SourceSubfolderFile="${SourceSubfolderFile#./}"
            # Extracting file basename, i.e. converting to SubFolerFile
            SourceSubfolderFile="$(basename "${SourceSubfolderFile}")"

            SourceFileAbsolutePath="${SourcePath}/${SourceSubFolder}/${SourceSubfolderFile}"
            # Ensure the file exists, then proceed with processing
            # "-e file" returns true if file exists
            # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
            # ${#VAR} calculates the number of characters in a variable
            if [ -f "${SourceFileAbsolutePath}" ] && [ "${#SourceFileAbsolutePath}" != 0 ] ; then
              # Extracting path from source absolute path
              SourceDirectoryPath="$(dirname "${SourceFileAbsolutePath}")"
              # Extracting file basename from source absolute path
              SourceFileBasename="$(basename "${SourceFileAbsolutePath}")"
              # Substituting characters in file basename, the script chokes on "[" and "]" characters
              SourceFileBasename="${SourceFileBasename//[/(}"
              SourceFileBasename="${SourceFileBasename//]/)}"
              # Extracting file name
              SourceFileName="${SourceFileBasename%.*}"
              # Extracting file extension
              SourceFileExtension="${SourceFileBasename##*.}"
              # Forming Work-In-Progress file path
              if [[ "${SourceSubFolder}" == "." ]] ; then
                WIPFileAbsolutePath="${WIPDirectoryPath}/${SourcePathBasename}/${SourceFileBasename}"
              else
                WIPFileAbsolutePath="${WIPDirectoryPath}/${SourceSubFolder}/${SourceFileBasename}"
              fi
              # Transferring file from source to Work-In-Progress directory, piping errors to NULL
              if ( ! "${CopyMove}" "${SourceFileAbsolutePath}" "${WIPFileAbsolutePath}" >/dev/null 2>&1 ) ; then
                printf "Something went wrong! ${SourceFileAbsolutePath} could not be transferred\n"
                LogOutput+="Something went wrong! ${SourceFileAbsolutePath} could not be transferred\n"
                # Counting failed operations with files
                ((SourceFileMoveFailureCount+=1))
              else
                # Counting successful operations with files
                ((SourceFileMoveSuccessCount+=1))
              fi
            else
              printf "Something went wrong! File ${SourceFileAbsolutePath} could not be found!\n"
              LogOutput+="Something went wrong! File ${SourceFileAbsolutePath} could not be found!\n"
              # Counting files that could not be found
              ((SourceFileNotFoundCount+=1))
            fi
          done
        fi
      fi
    done
  fi
  printf "${SourceFileMoveSuccessCount} files have been transferred from Source ${SourcePath} to Work-In-Progress $WIPDirectoryPath\n"
  printf "${SourceFileMoveFailureCount} files could not be transferred from Source ${SourcePath} to Work-In-Progress $WIPDirectoryPath\n"
  printf "${SourceFileNotFoundCount} files could not be found in Source ${SourcePath} folder\n"
  LogOutput+="${SourceFileMoveSuccessCount} files have been transferred from Source ${SourcePath} to Work-In-Progress $WIPDirectoryPath\n"
  LogOutput+="${SourceFileMoveFailureCount} files could not be transferred from Source ${SourcePath} to Work-In-Progress $WIPDirectoryPath\n"
  LogOutput+="${SourceFileNotFoundCount} files could not be found in Source ${SourcePath} folder\n"
  ## Taking operations timer snapshot, counting and registering operations timing
  OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Source-to-WIP transfer: ${OperationsTimerResult}\n"
  # Display operation timings
  printf "${OperationsTimerLog}"
  # Log operation timings
  LogOutput+="${OperationsTimerLog}"
  LogOutput+="#############################\n"
  # Reset operations timing variable
  OperationsTimerLog="Operations timing (ms):\n"
else
  printf "No files have been identified for processing in ${SourcePath}.\n"
  LogOutput+="No files have been identified for processing in ${SourcePath}.\n"
fi

# Begin file processing in Work-In-Progress directory
if [[ ${PrerequisitesOK} -eq 1 ]] && [[ ${FilesFetched} -eq 1 ]] ; then
  printf "Begin file processing in Work-In-Progress ${WIPDirectoryPath} directory\n"
  LogOutput+="Begin file processing in Work-In-Progress ${WIPDirectoryPath} directory\n"
  ## Taking operations timer snapshot
  OperationsTimerStart=$(date +%s%3N)
  # Searching for files with specific video and image extensions in Work-In-Progress directory
  WIPFileList="$(find "${WIPDirectoryPath}" -type f -iname "*.[JjGg][PpIi][GgFf]" -or \
  -iname "*.[Jj][Pp][Ee][Gg]" -or \
  -iname "*.[Mm][PpOo][Gg4Vv]" | sort -n)"
  ## Taking operations timer snapshot, counting and registering operations timing
  OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP file search: ${OperationsTimerResult}\n"
  ## Taking operations timer snapshot
  OperationsTimerStart=$(date +%s%3N)
  # Older cameras create images/videos with non-unique file name format, like DSC_XXXX.*, and usually without SubSecond metadata. 
  #
  # Sorting file names in this case is the only option to keep images in the original sequence, 
  # especially when multiple pictures being taken in one second
  FileListSorter "${WIPFileList}"
  ## Taking operations timer snapshot, counting and registering operations timing
  OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP file sorting: ${OperationsTimerResult}\n"
  # Display operation timings
  printf "${OperationsTimerLog}"
  printf "########\n"
  # Log operation timings
  LogOutput+="${OperationsTimerLog}"
  LogOutput+="########\n"
  # Reset operations timing variable
  OperationsTimerLog="Operations timing (ms):\n"
  # Returning the value from FileListSorter function by assigning the value of output (FileListSorterResult) to an array
  # Bash functions, unlike functions in most programming languages do not allow you to return values to the caller
  WIPSortedFileAbsolutePaths="${FileListSorterResult}"
  # Resetting FileListSorterResult array
  FileListSorterResult=""
  # Taking one file at a time and processing it
  #
  # Work-In-Progress file path composition:
  #   WIPFileAbsolutePath = WIPDirectoryPath + WIPFileBasename, where
  #     WIPFileBasename = WIPFileName + WIPFileExtension
  #
  for WIPSortedFileAbsolutePath in ${WIPSortedFileAbsolutePaths[@]}; do
    # Ensure the file exists, then proceed with processing
    # "-e file" returns true if file exists
    # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
    # ${#VAR} calculates the number of characters in a variable
    if [ -e "${WIPSortedFileAbsolutePath}" ] && [ "${#WIPSortedFileAbsolutePath}" != 0 ] ; then
      # Resetting variables
      SubSecCreateDateExtraction=0
      CreateDateExtraction=0
      FileSystemAttributeExtraction=0
      # Extracting file basename from Work-In-Progress absolute path
      WIPFileBasename="$(basename "${WIPSortedFileAbsolutePath}")"
      # Extracting file name base
      WIPFileName="${WIPFileBasename%.*}"
      # Extracting file extension
      WIPFileExtension="${WIPFileBasename##*.}"
      # Change extension lowercase if ExtensionCaseSwitch is set to "ext"
      if [[ "${ExtensionCaseSwitch}" == 'ext' ]] ; then
        NormalisedFileExtension="$(echo "${WIPFileExtension}" | awk '{print tolower($0)}')"
      else
      # Change extension uppercase if ExtensionCaseSwitch is set to "EXT"
        if [[ "${ExtensionCaseSwitch}" == 'EXT' ]] ; then
          NormalisedFileExtension="$(echo "${WIPFileExtension}" | awk '{print toupper($0)}')"
        fi
      fi
      ## Taking operations timer snapshot
      OperationsTimerStart=$(date +%s%3N)
      # Attempting to extract EXIF metadata from the file to an array.
      EXIF_EXTRACT=( $(exiftool -s -f -SubSecCreateDate -CreateDate -Model "${WIPSortedFileAbsolutePath}" | awk '{print $3":"$4}') )
      # Assigning the array values to variables
      EXIF_SubSecCreateDate_OUTPUT="${EXIF_EXTRACT[0]}"
      EXIF_CreateDate_OUTPUT="${EXIF_EXTRACT[1]}"
      EXIF_Model_OUTPUT="${EXIF_EXTRACT[2]}"
      ## Taking operations timer snapshot, counting and registering operations timing
      OperationsTimerStop=$(date +%s%3N)
      OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart ))
      OperationsTimerLog+="  EXIF extraction: ${OperationsTimerResult}\n"

      # Perform sanity check on correctly extracted EXIF SubSecCreateDate
      if [[ "${EXIF_SubSecCreateDate_OUTPUT}" != -* ]] && [[ "${EXIF_SubSecCreateDate_OUTPUT}" != 0* ]] ; then
        ## Taking operations timer snapshot
        OperationsTimerStart=$(date +%s%3N)
        # Setting flag
        SubSecCreateDateExtraction=1
        # Good data extracted, pass it to EXIFSubSecCreateDateParser to extract the fields from EXIF info
        EXIFSubSecCreateDateParser "${EXIF_SubSecCreateDate_OUTPUT}"
        # Check the extracted date for validity
        if [ "$(IsValidDate "${YEAR}" "${MONTH}" "${DAY}")" == 1 ]  ; then
          LogOutput+="A valid date with subseconds was found, using it.\n"
        else
          DATE="InvalidDate"
          LogOutput+="No valid date was found, using ${DATE}.\n"
        fi
        # Perform sanity check on correctly extracted EXIF Model
        if [[ "${EXIF_Model_OUTPUT}" != -* ]] ; then
          # Good data extracted, pass it to EXIFModelParser to extract fields
          # from the EXIF info
          EXIFModelParser "${EXIF_Model_OUTPUT}"
        else
          # Fill Model manually if tag extraction fails
          MODEL="CAMERA"
        fi
        ## Taking operations timer snapshot, counting and registering operations timing
        OperationsTimerStop=$(date +%s%3N)
        OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart ))
        OperationsTimerLog+="  EXIF SubSecCreateDate and Model verification: ${OperationsTimerResult}\n"
      fi
      # Proceed with CreateDate if SubSecCreateDate extraction failed
      if [[ ${SubSecCreateDateExtraction} -eq 0 ]] ; then
        ## Taking operations timer snapshot
        OperationsTimerStart=$(date +%s%3N)
        # Perform sanity check on correctly extracted EXIF CreateDate
        if [[ "${EXIF_CreateDate_OUTPUT}" != -* ]] && [[ "${EXIF_CreateDate_OUTPUT}" != 0* ]] ; then
          # Setting flag
          CreateDateExtraction=1
          # Good data extracted, pass it to EXIFCreateDateParser to extract fields
          # from the EXIF info
          EXIFCreateDateParser "${EXIF_CreateDate_OUTPUT}"
          # Check the extracted date for validity
          if [ "$(IsValidDate "${YEAR}" "${MONTH}" "${DAY}")" == 1 ]  ; then
            LogOutput+="A valid date without subseconds was found, using it.\n"
          else
            DATE="InvalidDate"
            LogOutput+="No valid date was found, using ${DATE}.\n"
          fi
          # Perform sanity check on correctly extracted EXIF Model
          if [[ "${EXIF_Model_OUTPUT}" != -* ]] ; then
            # Good data extracted, pass it to EXIFModelParser to extract fields
            # from the EXIF info
            EXIFModelParser "${EXIF_Model_OUTPUT}"
          else
            # Fill Model manually if tag extraction fails
            MODEL="CAMERA"
          fi
          ## Taking operations timer snapshot, counting and registering operations timing
          OperationsTimerStop=$(date +%s%3N)
          OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart ))
          OperationsTimerLog+="  EXIF CreateDate and Model verification: ${OperationsTimerResult}\n"
        fi
      fi
      # Proceed with file attribute extraction if it is enabled and if all other attempts failed (SubSecCreateDate and CreateDate)
      if [[ ${FileSystemAttributeProcessingFlag} -eq 1 ]] && [[ ${SubSecCreateDateExtraction} -eq 0 ]] && [[ ${CreateDateExtraction} -eq 0 ]] ; then
        ## Taking operations timer snapshot
        OperationsTimerStart=$(date +%s%3N)
        # If EXIF tag extracion failed, the last resort is file system file attributes
        #
        # Attempt to find a File System Modify Time mtime attribute from the file.
        FS_ModifyTime_OUTPUT="$(stat -c "%y" "${WIPSortedFileAbsolutePath}" | awk '{print $1":"$2}')"
        ## Taking operations timer snapshot, counting and registering operations timing
        OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  File stat extraction: ${OperationsTimerResult}\n"
        # Perform sanity check on correctly extracted File System mtime attribute
        if [[ "${FS_ModifyTime_OUTPUT}" != "" ]] && [[ "${FS_ModifyTime_OUTPUT}" != -* ]] && [[ "${FS_ModifyTime_OUTPUT}" != 0* ]] ; then
          ## Taking operations timer snapshot
          OperationsTimerStart=$(date +%s%3N)
          # Good data extracted, pass it to FSModifyTimeParser to extract components
          FSModifyTimeParser "${FS_ModifyTime_OUTPUT}"
          # Check the extracted date for validity
          if [ "$(IsValidDate "${YEAR}" "${MONTH}" "${DAY}")" == 1 ]  ; then
            LogOutput+="A valid File System date was found, using it.\n"
            # Setting flag
            FileSystemAttributeExtraction=1
          else
            DATE="InvalidDate"
            LogOutput+="No valid date was found, using ${DATE}.\n"
          fi
          # Fill Model manually, this attribute does not exist in File System
          MODEL="CAMERA" 
          ## Taking operations timer snapshot, counting and registering operations timing
          OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  File stat date validation: ${OperationsTimerResult}\n"
        fi
      fi
      # Proceed with "unverified" file name and forming flag if all extraction methods failed
      if [[ ${SubSecCreateDateExtraction} -eq 0 ]] && [[ ${CreateDateExtraction} -eq 0 ]] && [[ ${FileSystemAttributeExtraction} -eq 0 ]] ; then
        UNVERIFIED=1
      fi

      # Append UNVERIFIED to the filename if tag/attribute extraction failed.
      if [[ "${UNVERIFIED}" -eq 1 ]] ; then
        FormatedFileName="${WIPFileName}-UVRFD000.${WIPFileExtension}"
      # Modify filename as per format if tag/attribute extraction is successful
      else
        FormatedFileName="${MODEL}-${YEAR}${MONTH}${DAY}-${HOUR}${MINUTE}${SECOND}-${SUBSECOND}.${NormalisedFileExtension}"
        FormatedShortenFileName="${MODEL}-${YEAR}${MONTH}${DAY}-${HOUR}${MINUTE}${SECOND}-"
      fi

      # Setting Target Directory structure with TargetDirectoryStructure
      case "${TargetDirectoryStructure}" in 
        # YMD = YEAR/MONTH/DAY
        YMD)
          DestinationStructure="${YEAR}/${MONTH}/${DAY}"
          ;;
        # YM = YEAR/MONTH
        YM)
          DestinationStructure="${YEAR}/${MONTH}"
          ;;
        # Y = YEAR
        Y)
          DestinationStructure="${YEAR}"
          ;;
        # NOSORT = All, Destination/All
        NOSORT)
          DestinationStructure="${CUSTOM}"
          ;;
      esac

      if [[ "${UNVERIFIED}" -eq 1 ]] ; then
        # Re-forming the File Name by appending UVRFD000 was done before
        # Just a reminder what Formated File Name is FormatedFileName=${WIPFileName}-UVRFD000.${WIPFileExtension}
        #
        # Checking if Destination FileName exists
        # "-e file" returns true if file exists
        # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
        if [[ ! -f "${DestinationPath}/${UnverifiedFiles}/${FormatedFileName}" ]] ; then
          ## Taking operations timer snapshot
          OperationsTimerStart=$(date +%s%3N)
          # Attempting to move the file to the UnverifiedFiles directory for review
          if ( ! mv "${WIPSortedFileAbsolutePath}" "${DestinationPath}/${UnverifiedFiles}/${FormatedFileName}" ) ; then
            ## Taking operations timer snapshot, counting and registering operations timing
            OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP-to-Unverified move: ${OperationsTimerResult}\n"
            printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${UnverifiedFiles}/${FormatedFileName} FAILED\n"
            if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
            printf "########\n"
            LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${UnverifiedFiles}/${FormatedFileName} FAILED\n"
            if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
            LogOutput+="########\n"
          else
            ## Taking operations timer snapshot, counting and registering operations timing
            OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP-to-Unverified move: ${OperationsTimerResult}\n"
            printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${UnverifiedFiles}/${FormatedFileName} SUCCESSFUL\n"
            if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
            printf "########\n"
            LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${UnverifiedFiles}/${FormatedFileName} SUCCESSFUL\n"
            if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
            LogOutput+="########\n"
          fi
        # If Destination FileName does exist, get all the names in the Destination Directory 
        # matching the shortened file basename and process them to avoid duplicates
        else
          ## Taking operations timer snapshot
          OperationsTimerStart=$(date +%s%3N)
          FormatedShortenUnverifiedFileName="${WIPFileName}-"
          # Calling DuplicateSearch when a duplicate is identified
          DuplicateSearch "${DestinationPath}/${UnverifiedFiles}" "${FormatedShortenUnverifiedFileName}" "${NormalisedFileExtension}"
          ## Taking operations timer snapshot, counting and registering operations timing
          OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Unverified duplicate search: ${OperationsTimerResult}\n"
          ## Taking operations timer snapshot
          OperationsTimerStart=$(date +%s%3N)
          # Returning value from DuplicateSearch as DuplicateSearchResult and passing it to FileListSorter
          FileListSorter "${DuplicateSearchResult}"
          ## Taking operations timer snapshot, counting and registering operations timing
          OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Unverified duplicate file sorting: ${OperationsTimerResult}\n"
          ## Taking operations timer snapshot
          OperationsTimerStart=$(date +%s%3N)
          # Returning value from FileListSorter as FileListSorterResult and passing it to FileListToArray function to convert string to array
          FileListToArray "${FileListSorterResult}"
          OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Unverified list-to-array: ${OperationsTimerResult}\n"
          ## Taking operations timer snapshot
          OperationsTimerStart=$(date +%s%3N)
          # Calling FileNameUnverifiedIncrementer against the Element of matched filenames to change the filename suffix
          FileNameUnverifiedIncrementer "${FileListToArrayLastElement}"
          # Returning the incremented element from FileNameUnverifiedIncrementer function
          FileNameIncrementedElement="${FileNameUnverifiedIncrementerResult}"
          # Re-forming the File Name with the incremented Element
          FormatedFileName="${WIPFileName}-UVRFD${FileNameIncrementedElement}.${NormalisedFileExtension}"
          ## Taking operations timer snapshot, counting and registering operations timing
          OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Unverified duplicate increment: ${OperationsTimerResult}\n"
          # Checking if Destination FileName exists
          # "-e file" returns true if file exists
          # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
          if [[ ! -f "${DestinationPath}/${UnverifiedFiles}/${FormatedFileName}" ]] ; then
            ## Taking operations timer snapshot
            OperationsTimerStart=$(date +%s%3N)
            # Moving the file to the UnverifiedFiles directory for review
            if ( ! mv "${WIPSortedFileAbsolutePath}" "${DestinationPath}/${UnverifiedFiles}/${FormatedFileName}" ) ; then
              ## Taking operations timer snapshot, counting and registering operations timing
              OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP-to-Unverified dedup move: ${OperationsTimerResult}\n"
              printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${UnverifiedFiles}/${FormatedFileName} FAILED\n"
              if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
              printf "########\n"
              LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${UnverifiedFiles}/${FormatedFileName} FAILED\n"
              if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
              LogOutput+="########\n"
            else
              ## Taking operations timer snapshot, counting and registering operations timing
              OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP-to-Unverified dedup move: ${OperationsTimerResult}\n"
              printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${UnverifiedFiles}/${FormatedFileName} SUCCESSFUL\n"
              if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
              printf "########\n"
              LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${UnverifiedFiles}/${FormatedFileName} SUCCESSFUL\n"
              if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
              LogOutput+="########\n"
            fi
          else
            printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${UnverifiedFiles}/${FormatedFileName} is stopped to avoid overriding the existing file. Check duplicate avoidance functions\n"
            printf "########\n"
            LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${UnverifiedFiles}/${FormatedFileName}  is stopped to avoid overriding the existing file. Check duplicate avoidance functions\n"
            LogOutput+="########\n"
          fi
        fi
      else
        # Checking if the destination is writable by creating Desination File Path, piping errors to NULL
        if ( ! mkdir -p "${DestinationPath}/${DestinationStructure}" >/dev/null 2>&1 ) ; then
          printf "Post-Prerequisite Critical Error! Could not write ${DestinationStructure}. Directory ${DestinationPath} does not appear to be writable.\n"
          exit
        else
          # Checking if Destination FileName exists
          # "-e file" returns true if file exists
          # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
          if [[ ! -f "${DestinationPath}/${DestinationStructure}/${FormatedFileName}" ]] ; then        
            ## Taking operations timer snapshot
            OperationsTimerStart=$(date +%s%3N)
            # Moving the file to the Desination File Path
            if ( ! mv "${WIPSortedFileAbsolutePath}" "${DestinationPath}/${DestinationStructure}/${FormatedFileName}" ) ; then
              ## Taking operations timer snapshot, counting and registering operations timing
              OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP-to-Destination move: ${OperationsTimerResult}\n"
              printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${DestinationStructure}/${FormatedFileName} FAILED\n"
              if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
              printf "########\n"
              LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${DestinationStructure}/${FormatedFileName} FAILED\n"
              if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
              LogOutput+="########\n"
            else
              ## Taking operations timer snapshot, counting and registering operations timing
              OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP-to-Destination move: ${OperationsTimerResult}\n"
              printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${DestinationStructure}/${FormatedFileName} SUCCESSFUL\n"
              if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
              printf "########\n"
              LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${DestinationStructure}/${FormatedFileName} SUCCESSFUL\n"
              if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
              LogOutput+="########\n"
            fi
          # If Destination FileName does exist, get all the names in the Destination Directory 
          # matching the shortened file basename and process them to avoid duplicates
          else
            ## Taking operations timer snapshot
            OperationsTimerStart=$(date +%s%3N)
            # Calling DuplicateSearch when a duplicate is identified
            LogOutput+="Calling DuplicateSearch with FormatedShortenFileName: ${FormatedShortenFileName}\n"
            DuplicateSearch "${DestinationPath}/${DestinationStructure}" "${FormatedShortenFileName}" "${NormalisedFileExtension}"
            ## Taking operations timer snapshot, counting and registering operations timing
            OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Destination duplicate search: ${OperationsTimerResult}\n"
            ## Taking operations timer snapshot
            OperationsTimerStart=$(date +%s%3N)
            # Returning value from DuplicateSearch as DuplicateSearchResult and passing it to FileListSorter
            LogOutput+="Calling FileListSorter function against {DuplicateSearchResult} ${DuplicateSearchResult}\n"
            FileListSorter "${DuplicateSearchResult}"
            ## Taking operations timer snapshot, counting and registering operations timing
            OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Destination duplicate file sorting: ${OperationsTimerResult}\n"
            ## Taking operations timer snapshot
            OperationsTimerStart=$(date +%s%3N)
            # Returning value from FileListSorter as FileListSorterResult and passing it to FileListToArray function to convert string to array
            LogOutput+="Calling FileListToArray function against {FileListSorterResult} ${FileListSorterResult}\n"
            FileListToArray "${FileListSorterResult}"
            ## Taking operations timer snapshot, counting and registering operations timing
            OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Destination list-to-array: ${OperationsTimerResult}\n"
            ## Taking operations timer snapshot
            OperationsTimerStart=$(date +%s%3N)
            LogOutput+="Receiving FileListToArray function results FileListToArrayResult ${FileListToArrayResult}\n"
            # Defining/resetting checksum match variable for counting file duplicates
            CheckSumMatchCount=0
            # Calling DigestComparison to compare the file's message digest with all matched files in FileListToArrayResult
            LogOutput+="Calling DigestComparison function against {WIPSortedFileAbsolutePath} ${WIPSortedFileAbsolutePath} and {FileListToArrayResult} ${FileListToArrayResult}\n"
            DigestComparison "${WIPSortedFileAbsolutePath}" "${FileListToArrayResult}"
            ## Taking operations timer snapshot, counting and registering operations timing
            OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Destination duplicate digest comparison: ${OperationsTimerResult}\n"
            # Returning checksum match count from DigestComparison function
            LogOutput+="Calling CheckSumMatchCount function against {DigestComparisonCheckSumMatchCount} ${DigestComparisonCheckSumMatchCount}\n"
            CheckSumMatchCount="${DigestComparisonCheckSumMatchCount}"
            # Returning duplicate file list from DigestComparison function
            DestinationDuplicateFiles="${DigestComparisonFileList}"
            # If message digest match was not found, it means the Destination Directory contains 
            # files with the same file name and difference content, i.e. by-filename duplicates
            # Example: pictures created simultaneously by two cameras of the same Make/Model
            # Changing the SUBSECOND part by 000001 increment to make the filename unique
            if [[ "CheckSumMatchCount" -eq 0 ]] ; then
              ## Taking operations timer snapshot
              OperationsTimerStart=$(date +%s%3N)
              # Calling FileNameIncrementer against the last member with highest SUBSECOND number in the sorted array of matched filenames to change the filename suffix
              FileNameIncrementer "${FileListToArrayLastElement}"
              ## Taking operations timer snapshot, counting and registering operations timing
              OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Destination duplicate increment: ${OperationsTimerResult}\n"
              # Returning the incremented element from FileNameIncrementer function
              IncrementedSubsecond="${FileNameIncrementerResult}"
              # Re-forming the File Name with the incremented SUBSECOND
              FormatedFileName="${MODEL}-${YEAR}${MONTH}${DAY}-${HOUR}${MINUTE}${SECOND}-${IncrementedSubsecond}.${NormalisedFileExtension}"
              # Checking if Destination FileName exists
              # "-e file" returns true if file exists
              # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
              if [[ ! -f "${DestinationPath}/${DestinationStructure}/${FormatedFileName}" ]] ; then
                ## Taking operations timer snapshot
                OperationsTimerStart=$(date +%s%3N)
                # Attempting to move the file to the Desination File Path
                if ( ! mv "${WIPSortedFileAbsolutePath}" "${DestinationPath}/${DestinationStructure}/${FormatedFileName}" ) ; then
                  ## Taking operations timer snapshot, counting and registering operations timing
                  OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Destination dedup move: ${OperationsTimerResult}\n"
                  printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${DestinationStructure}/${FormatedFileName} FAILED\n"
                  if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
                  printf "########\n"
                  LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${DestinationStructure}/${FormatedFileName} FAILED\n"
                  if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
                  LogOutput+="########\n"
                else
                  ## Taking operations timer snapshot, counting and registering operations timing
                  OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Destination dedup move: ${OperationsTimerResult}\n"
                  printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${DestinationStructure}/${FormatedFileName} SUCCESSFUL\n"
                  if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
                  printf "########\n"
                  LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${DestinationStructure}/${FormatedFileName} SUCCESSFUL\n"
                  if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
                  LogOutput+="########\n"
                fi
              else
                printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${DestinationStructure}/${FormatedFileName} is stopped to avoid overriding the existing file. Check duplicate avoidance functions\n"
                printf "########\n"
                LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${DestinationStructure}/${FormatedFileName}  is stopped to avoid overriding the existing file. Check duplicate avoidance functions\n"
                LogOutput+="########\n"
              fi
            fi
            # Processing the WIP file if message digest match was found
            # Cheking if the destination directory is writable by creating Duplicates folder, piping errors to NULL
            if [[ "CheckSumMatchCount" -ge 1 ]] ; then
              if ( ! mkdir -p "${DestinationPath}/${FileNameDuplicates}" >/dev/null 2>&1 ) ; then
                printf "Post-Prerequisite Critical Error! Could not write ${FileNameDuplicates}. Directory ${DestinationPath} does not appear to be writable.\n"
                exit
              else
                # Re-forming the File Name by appending DUP000
                FormatedFileName="${MODEL}-${YEAR}${MONTH}${DAY}-${HOUR}${MINUTE}${SECOND}-${SUBSECOND}-DUP000.${NormalisedFileExtension}"
                # Checking if Destination FileName exists
                # "-e file" returns true if file exists
                # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
                if [[ ! -f "${DestinationPath}/${FileNameDuplicates}/${FormatedFileName}" ]] ; then
                  ## Taking operations timer snapshot
                  OperationsTimerStart=$(date +%s%3N)
                  # Attempting to move the file to the FileNameDuplicates directory for review
                  if ( ! mv "${WIPSortedFileAbsolutePath}" "${DestinationPath}/${FileNameDuplicates}/${FormatedFileName}" ) ; then
                    ## Taking operations timer snapshot, counting and registering operations timing
                    OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP-to-Duplicates move: ${OperationsTimerResult}\n"
                    printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${FormatedFileName} FAILED\n"
                    if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
                    printf "########\n"
                    LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${FormatedFileName} FAILED\n"
                    if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
                    LogOutput+="########\n"
                  else
                    ## Taking operations timer snapshot, counting and registering operations timing
                    OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP-to-Duplicates move: ${OperationsTimerResult}\n"
                    printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${FormatedFileName} SUCCESSFUL\n"
                    if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
                    printf "########\n"
                    LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${FormatedFileName} SUCCESSFUL\n"
                    if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
                    LogOutput+="########\n"
                  fi
                # If Destination FileName does exist, get all the names in the Destination Directory 
                # matching the shortened file basename and process them to avoid duplicates
                else
                  ## Taking operations timer snapshot
                  OperationsTimerStart=$(date +%s%3N)
                  FormatedShortenDuplicateFileName="${MODEL}-${YEAR}${MONTH}${DAY}-${HOUR}${MINUTE}${SECOND}-${SUBSECOND}-"
                  # Calling DuplicateSearch when a duplicate is identified
                  DuplicateSearch "${DestinationPath}/${FileNameDuplicates}" "${FormatedShortenDuplicateFileName}" "${NormalisedFileExtension}"
                  ## Taking operations timer snapshot, counting and registering operations timing
                  OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Duplicates duplicate search: ${OperationsTimerResult}\n"
                  ## Taking operations timer snapshot
                  OperationsTimerStart=$(date +%s%3N)
                  # Returning value from DuplicateSearch as DuplicateSearchResult and passing it to FileListSorter
                  FileListSorter "${DuplicateSearchResult}"
                  ## Taking operations timer snapshot, counting and registering operations timing
                  OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Duplicates file sorting: ${OperationsTimerResult}\n"
                  ## Taking operations timer snapshot
                  OperationsTimerStart=$(date +%s%3N)
                  # Returning value from FileListSorter as FileListSorterResult and passing it to FileListToArray function to convert string to array
                  FileListToArray "${FileListSorterResult}"
                  ## Taking operations timer snapshot, counting and registering operations timing
                  OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Duplicates list-to-array: ${OperationsTimerResult}\n"
                  ## Taking operations timer snapshot
                  OperationsTimerStart=$(date +%s%3N)
                  # Calling FileNameDuplicateIncrementer against the Element of matched filenames to change the filename suffix
                  FileNameDuplicateIncrementer "${FileListToArrayLastElement}"
                  ## Taking operations timer snapshot, counting and registering operations timing
                  OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  Duplicates duplicate increment: ${OperationsTimerResult}\n"
                  # Returning the incremented element from FileNameIncrementer function
                  FileNameIncrementedElement="${FileNameDuplicateIncrementerResult}"
                  # Re-forming the File Name with the incremented Element
                  #FormatedFileName=${MODEL}-${YEAR}${MONTH}${DAY}-${HOUR}${MINUTE}${SECOND}-${SUBSECOND}-DUP${RANDOM}.${NormalisedFileExtension}
                  FormatedFileName="${MODEL}-${YEAR}${MONTH}${DAY}-${HOUR}${MINUTE}${SECOND}-${SUBSECOND}-DUP${FileNameIncrementedElement}.${NormalisedFileExtension}"
                  # Checking if Destination FileName exists
                  # "-e file" returns true if file exists
                  # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
                  if [[ ! -f "${DestinationPath}/${FileNameDuplicates}/${FormatedFileName}" ]] ; then
                    ## Taking operations timer snapshot
                    OperationsTimerStart=$(date +%s%3N)
                    # Moving the file to the FileNameDuplicates directory for review
                    if ( ! mv "${WIPSortedFileAbsolutePath}" "${DestinationPath}/${FileNameDuplicates}/${FormatedFileName}" ) ; then
                      ## Taking operations timer snapshot, counting and registering operations timing
                      OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP-to-Duplicated dedup move: ${OperationsTimerResult}\n"
                      printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${FormatedFileName} FAILED\n"
                      if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
                      printf "########\n"
                      LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${FormatedFileName} FAILED\n"
                      if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
                      LogOutput+="########\n"
                    else
                      ## Taking operations timer snapshot, counting and registering operations timing
                      OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart )) ; OperationsTimerLog+="  WIP-to-Duplicated dedup move: ${OperationsTimerResult}\n"
                      printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${FormatedFileName} SUCCESSFUL\n"
                      if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
                      printf "########\n"
                      LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${FormatedFileName} SUCCESSFUL\n"
                      if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
                      LogOutput+="########\n"
                    fi
                  else
                    printf "Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${FormatedFileName} is stopped to avoid overriding the existing file. Check duplicate avoidance functions\n"
                    if [[ "${OperationsTimer}" == "ON" ]] ; then printf "${OperationsTimerLog}" ; fi
                    printf "########\n"
                    LogOutput+="Moving ${WIPSortedFileAbsolutePath} to ${DestinationPath}/${FileNameDuplicates}/${FormatedFileName}  is stopped to avoid overriding the existing file. Check duplicate avoidance functions\n"
                    if [[ "${OperationsTimer}" == "ON" ]] ; then LogOutput+="${OperationsTimerLog}" ; fi
                    LogOutput+="########\n"
                  fi
                fi
              fi              
            fi
          fi
        fi
      fi
      # Resetting variables
      WIPSortedFileAbsolutePath=""; WIPFileBasename=""; WIPFileName=""; WIPFileExtension=""; NormalisedFileExtension=""; FormatedFileName="";
      DATE=""; YEAR=""; MONTH=""; DAY=""; HOUR=""; MINUTE=""; SECOND=""; SUBSECOND=""; LONGSUBSECOND=""; 
      MODEL=""; UNVERIFIED=""
      OperationsTimerLog="Operations timing (ms):\n"
    else
      LogOutput+="File ${WIPSortedFileAbsolutePath} not found!\n"
    fi
  done
else
  printf "No files have been moved to WIP $WIPDirectoryPath.\n"
  LogOutput+="No files have been moved to WIP $WIPDirectoryPath.\n"
fi
# At this stage all the files in the Work-In-Progress directory and its subfolders have been processed and moved to other locations

# Removing empty Work-In-Progress subfolders followed by WIP directory removal, piping errors to NULL
printf "Cleaning up Work-In-Progress '${WIPDirectoryPath}'\n"
LogOutput+="Cleaning up Work-In-Progress '${WIPDirectoryPath}'\n"
WIPFolderList="$(find "${WIPDirectoryPath}" -type d | sort -rn)"
## Confirming the folder list is not empty, ${#VAR} calculates the number of characters in a variable
WIPSubFolderRemovalFailed=0
if [ "${#WIPFolderList}" != 0 ] ; then
  for WIPSubFolder in ${WIPFolderList[@]} ; do
    printf "Attempting to remove '${WIPSubFolder}'\n"
    LogOutput+="Attempting to remove '${WIPSubFolder}'\n"
    if ( ! rmdir "${WIPSubFolder}" >/dev/null 2>&1 ) ; then
      printf "Error while removing directory! Directory ${WIPSubFolder} does not appear to be empty or lock is in place. Exiting now.\n"
      LogOutput+="Error while removing directory! Directory ${WIPSubFolder} does not appear to be empty or lock is in place.\n"
      WIPSubFolderRemovalFailed=1
    fi
  done
fi

if [[ ${WIPSubFolderRemovalFailed} -eq 1 ]] ; then
  printf "Error while removing directory! Directory ${WIPDirectoryPath} or its subfolder does not appear to be empty or lock is in place. Exiting now.\n"
  LogOutput+="Error while removing directory! Directory ${WIPDirectoryPath} or its subfolder does not appear to be empty or lock is in place.\n"
else
  printf "Directory '${WIPDirectoryPath}' and all its subfolders have been removed successfully. End of programme.\n"
  LogOutput+="Directory '${WIPDirectoryPath}' and all its subfolders have been removed successfully. End of programme.\n"
fi
# Unsetting Internal Field Separator (IFS)
unset IFS
# Exiting now
LogDumper "${LogOutput}"
