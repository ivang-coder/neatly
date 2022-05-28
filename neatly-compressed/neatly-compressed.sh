#!/usr/bin/env bash

# Author: Ivan Gladushko
Version="v2.0.0"
# Date: 2022-05-28

# Knowledge Base:
#   Bash functions, unlike functions in most programming languages do not allow you to return values to the caller, i.e. use another variable to keep the results of the function. Alternatively, use "echo", i.e. echo "1" to return the result or boolian value

#=======================================================================
# Key variables and Default parameters
#=======================================================================
# Getting the name of script, <name>.<ext>
InstanceName="$(basename "${0}")"
# Stripping out the extension leaving just <name>
InstanceNameBase="${InstanceName%.*}"
# Getting absolute path of the script, do not use <InstanceDirectoryPath="$(dirname "${0}")"> as it does not work with non-absolute paths
WorkDir="$PWD"; [ "$PWD" = "/" ] && WorkDir=""
case "$0" in
  /*) InstanceDirectoryPath="${0}";;
  *) InstanceDirectoryPath="$WorkDir/${0#./}";;
esac
InstanceDirectoryPath="${InstanceDirectoryPath%/*}"
# Getting parent path of the script directory
InstanceDirectoryParent="$(dirname "${InstanceDirectoryPath}")"
# Setting Internal Field Separator (IFS) to new-line character to process filenames with spaces and other special characters
IFS=$'\n'
# Setting notification filename
NotificationFile="monitored-by-${InstanceNameBase}.info"
# Setting FFMpeg encoder switch to "libx265", libx264|libx265, and associated FFMpeg Desired Constant Rate Factor (CRF) to 21 visual "lossless" and border CRF (acceptable quality) to 28
FFEncoder="libx265"
DefaultDesiredCRF=21
DefaultBorderCRF=28
# Setting informational FFMpeg EXIF model, FFx264|FFx265
FFModel="FFx265"
# Setting FFMpeg preset, medium|slow|slower|veryslow
FFPreset="medium"
# Setting threshold values. Change the values with caution!
ControlSpotWeightInBitsThreshold=1650 # Threshold 1650 is equivalent of 10264320 bps (10.264 Mbps) 1920x1080 30fps video
# Setting file size target in percent (%), fstarget=<integer>
DefaultFileSizeTarget=25
FileSizeTarget=0
# Setting Source to Work-In-Progress (WIP) file transfer mode: <cp> (default) | <mv>
CopyMove="cp"
# Setting CRF informational file, <--crffileON|--crffileOFF>
CRFInfoFile="ON"
# Resetting variables
LogOutput="##########################################\n"
FullHelpTip=""
# Setting directory name for original vide files, i.e. the non-recompressed files
OriginalVideosSubfolder=".Originals"
# Setting directory name for metadata files
MetadataSubfolder="Metadata"
# Setting operations timer: <ON>, <OFF> (default)
OperationsTimer="OFF"
OperationsTimerLog="Operations timing (ms) | "
# Setting crawl: <ON> depth level 3 (default), <OFF>
CrawlDepth="3"
# Setting variables
LogDate="$(date +%Y%m%d-%H%M%S)"
WIPDirectoryDate="${LogDate}"
LogFileDate="$(date +%Y%m%d%H%M)"
# Appending log variable
LogOutput+="${LogDate}\n"

#=======================================================================
# Help options
#=======================================================================
HelpTip="Help: for more parameters use '/bin/bash ${InstanceName} <-h|--help>'\n"
UsageTip="Usage: '/bin/bash ${InstanceName} <source-path|.> <destination-path|.> <--x264|--x265> <--medium|--slow|--slower|--veryslow> <--copy|--move> <--timerON|--timerOFF> <--crawlON|--crawlOFF> <--fstarget=<integer>> <--desiredCRF=<integer>> <--borderCRF=<integer>> <--crffileON|--crffileOFF>\n  Mandatory parameters: source-path\n"
SourcePathTip="Source absolute path is required with leading '/'. Alternatively use '.' for current directory.\n  Example: '/home/username/videos/'; '/home/username/videos/VID_20220226_135901.mp4'\n"
DestinationPathTip="Destination absolute path can be ommited or specified with leading '/'. Alternatively, use '.' for current directory.\n  Example: '/mystorage/sorted-videos/'\n"
FFEncoderTip="FFMpeg encoder switch: \n  --x264 = encoding with x264 using libx264 and ,\n  --x265 = encoding with x265 using libx265 (default)\n  For libx264, the Constant Rate Factor (CRF) of choice is 18 visual 'lossless';\n  For libx265, the Constant Rate Factor (CRF) of choice is 21 visual 'lossless';\n"
FFPresetTip="FFMpeg preset switch: \n  --medium = (default) the encoding time is about 350%%, i.e. it takes about 4 seconds with x265 to encode 1 second of the video,\n  --slow = going from medium to slow, the time needed increases by about 40%%,\n  --slower = going from medium to slower, the time needed increases by about 140%%,\n  --veryslow = going from medium to veryslow, the time needed increases by about 280%%, with only minimal improvements over slower in terms of quality\n"
CopyMoveTip="Source to Work-In-Progress (WIP) file transfer mode: \n  --copy = copy files (default),\n  --move = move files\n"
OperationsTimerTip="Operations timer (monitoring, debug): \n  --timerON = display and log operation timings,\n  --timerOFF = do not display and log operation timings (default)\n"
CrawlTip="Crawl parameters: \n  --crawlON = process Source and its subfolders 3 levels deep (default),\n  --crawlOFF = process Source directory only, i.e. Source files at root with no subfolders\n"
FileSizeTargetTip="File size target in percent: \n  --fstarget=<integer> where <integer> is >10..50<, 25 is default,\n  for example, with --fstarget=50 and source file of 80 MB, the target file size is 40 MB\n"
DesiredCRFTip="Desired CRF: \n  --desiredCRF=<integer> where <integer> is >0..50<, 21 is default,\n  Note: Desired CRF represents the best quality, --desiredCRF should be less or equal to --borderCRF\n"
BorderCRFTip="Border CRF: \n  --borderCRF=<integer> where <integer> is >0..50<, 28 is default,\n  Note: Border CRF represents the acceptable quality, --borderCRF should be greater or equal to --desiredCRF\n"
CRFFileTip="CRF file: \n  --crffileON = create informational file.crf<integer> file indicating the quality level (CRF) of the encoded file (default),\n  --crffileOFF = do not create informational file.crf<integer> file indicating the quality level (CRF) of the encoded file\n"
FullHelpTip+="${UsageTip}${SourcePathTip}${DestinationPathTip}${FFEncoderTip}${FFPresetTip}${CopyMoveTip}${OperationsTimerTip}${CrawlTip}${FileSizeTargetTip}${DesiredCRFTip}${BorderCRFTip}${CRFFileTip}\n"
FullHelpTip+="References:\n"
FullHelpTip+="  H.264 Video Encoding Guide https://trac.ffmpeg.org/wiki/Encode/H.264\n"
FullHelpTip+="  H.265/HEVC Video Encoding Guide https://trac.ffmpeg.org/wiki/Encode/H.265\n"
#=======================================================================
# Functions
#=======================================================================

# Process_Conflict_Avoidance <process_name> <max_count_threshold> <grace_period_in_seconds>
Process_Conflict_Avoidance(){
  ProcessName="${1}"
  CountThreshold="${2}"
  GracePeriodInSeconds="${3}"
  SleepTimer=15; GraceIntervals=$(( ${GracePeriodInSeconds} / ${SleepTimer} )); GraceInterval=0
  # In a common scenario "ps" command will be running in a child process (sub-shell) with the name matching the script name, hence we're checking if there are more than n+1 instances
  # Checking for absence of other running processes/instances, excluding the "grep" from the output and counting the number of lines
  InstanceCount="$(ps -ef | grep "${ProcessName}" | grep -v grep | wc -l)"
  if [[ "${InstanceCount}" -gt "${CountThreshold}" ]]; then
    printf "Prerequisite Critical Error! There are ${InstanceCount} instances of ${ProcessName} detected, the threshold is ${CountThreshold}. Grace period of ${GracePeriodInSeconds} seconds begins.\n"
    sleep ${SleepTimer}
    # Grace period
    until [[ "${InstanceCount}" -le "${CountThreshold}" ]]
      do
        if [[ ${GraceInterval} < ${GraceIntervals} ]] ; then
          InstanceCount="$(ps -ef | grep "${ProcessName}" | grep -v grep | wc -l)"
          printf "Prerequisite Critical Error! There are ${InstanceCount} instances of ${ProcessName} detected, the threshold is ${CountThreshold}. Grace period in progress, checking the status in ${SleepTimer} seconds\n"
          sleep ${SleepTimer}
          GraceInterval=$(( ${GraceInterval} + 1 ))
        else
          if [[ "${InstanceCount}" -gt "${CountThreshold}" ]] ; then
            printf "Prerequisite Critical Error! There are ${InstanceCount} instances of ${ProcessName} detected, the threshold is ${CountThreshold}. Grace period ends. Exiting now.\n  To veify, run 'ps -ef | grep "${ProcessName}" | grep -v grep | wc -l'\n"
            exit
          fi
        fi
      done
  fi
}

# Log_Dumping_and_Exiting makes an output to log file, and exists the programme
Log_Dumping_and_Exiting(){
  WIP_Directory_Cleanup "${WIPDirectoryPath}"
  # Passing parameters to variables
  AggregatedLogOuput="${1}"
  # Writing to log file
  printf "Writing to log file ${SourcePath}/${LogFileName}\n"
  printf "${AggregatedLogOuput}" >> "${SourcePath}/${LogFileName}"
  # Unsetting Internal Field Separator (IFS)
  unset IFS
  printf "Exiting now.\n"
  exit
}

# Log_Dumping makes an output to log file
Log_Dumping(){
  # Passing parameters to variables
  AggregatedLogOuput="${1}"
  # Writing to log file
  printf "Writing to log file ${SourcePath}/${LogFileName}\n"
  printf "${AggregatedLogOuput}" >> "${SourcePath}/${LogFileName}"
  AggregatedLogOuput=""
  LogOutput=""
}

 # Graceful_Termination_Request_Check locates "stop" file for graceful termination
 Graceful_Termination_Request_Check(){
  if [[ -f "${InstanceDirectoryPath}/${1}" ]] ; then 
    printf "Graceful termination request detected by locating '${1}' file in ${InstanceDirectoryPath} directory. Gracefully terminating now.\n"
    LogOutput+="Graceful termination request detected by locating '${1}' file in ${InstanceDirectoryPath} directory. Gracefully terminating now.\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
}

Operations_Performance_Logging(){
  if [[ "${OperationsTimer}" == "ON" ]] ; then
    ## Counting and registering operations timing
    OperationsTimerStop=$(date +%s%3N) ; OperationsTimerResult=$(( OperationsTimerStop - OperationsTimerStart ))
    OperationsTimerLog+="${1}: ${OperationsTimerResult}\n"
    # Display and log operation timings
    printf "${OperationsTimerLog}"
    LogOutput+="${OperationsTimerLog}"
    LogOutput+="#############################\n"
    # Reset operations timing variable
    OperationsTimerLog="Operations timing (ms) | "
  fi
}

Work_In_Progress_Preparation(){
  ## Operations_Performance_Logging: Taking operations timer snapshot
  OperationsTimerStart=$(date +%s%3N)
  #
  printf "Preparing Work-In-Progress ${1}/${2} directory\n"
  LogOutput+="Preparing Work-In-Progress ${1}/${2} directory\n"
  if ( ! mkdir -p "${1}/${2}" >/dev/null 2>&1 ) ; then
    printf "Critical Error! Could not write ${1}/${2}. Directory ${1} does not appear to be writable.\n"
    LogOutput+="Critical Error! Could not write ${1}/${2}. Directory ${1} does not appear to be writable.\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
  Operations_Performance_Logging ${FUNCNAME[0]}
}

Exiftool_Metadata_to_JSON_Exporting(){
  printf "Exporting metadata by invoking 'exiftool -json "${1}" > "${2}"'\n"
  LogOutput+="Exporting metadata by invoking 'exiftool -json "${1}" > "${2}"'\n"
  if ( ! exiftool -json "${1}" > "${2}" ) ; then
    printf "Something went wrong! ${2} could not be modified\n"
    LogOutput+="Something went wrong! ${2} could not be modified\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
}

FFProbe_Metadata_to_JSON_Exporting(){
  printf "Exporting metadata by invoking 'ffprobe -hide_banner -loglevel panic -show_streams -of json ${1} > ${2}'\n"
  LogOutput+="Exporting metadata by invoking 'ffprobe -hide_banner -loglevel panic -show_streams -of json ${1} > ${2}'\n"
  if ( ! ffprobe -hide_banner -loglevel panic -show_streams -of json "${1}" > "${2}" ) ; then
    printf "Something went wrong! ${2} could not be modified\n"
    LogOutput+="Something went wrong! ${2} could not be modified\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
}

Delimited_String_Parser(){
  # Define a variable and pass the arguments
  Input="${1}"
  Delimiter="${2}"
  # Concatenate the delimiter with the main string
  Concatenated_Input="${Input}${Delimiter}"
  # Split the text based on the delimiter
  Delimited_String_Parser_Output=()
  while [[ "${Concatenated_Input}" ]]; do
    Delimited_String_Parser_Output+=( "${Concatenated_Input%%${Delimiter}*}" )
    Concatenated_Input="${Concatenated_Input#*${Delimiter}}"
  done
}

String_to_Integer_Converter(){
  printf -v NormalizedElement '%d\n' "${1}"
  String_to_Integer_Converter_Output=$((10#${NormalizedElement}))
}

FFProbe_Attribute_Parser(){
  # Define a variable and pass the arguments as an array
  Input=("$@")
  FFProbe_Attribute_Parser_Failure=0
  # Processing array elements
  SourceFileWidth="${Input[0]}"; SourceFileWidth="${SourceFileWidth//width=/}"
  if [[ "${SourceFileWidth}" == "" ]] ; then FFProbe_Attribute_Parser_Failure=1 ; else String_to_Integer_Converter $SourceFileWidth; SourceFileWidth=$String_to_Integer_Converter_Output ; fi
  if [[ ! ${SourceFileWidth} =~ ^[0-9]+$ ]] ; then FFProbe_Attribute_Parser_Failure=1 ; fi
  SourceFileHeight="${Input[1]}"; SourceFileHeight="${SourceFileHeight//height=/}"
  if [[ "${SourceFileHeight}" == "" ]] ; then FFProbe_Attribute_Parser_Failure=1 ; else String_to_Integer_Converter $SourceFileHeight; SourceFileHeight=$String_to_Integer_Converter_Output ; fi
  if [[ ! ${SourceFileHeight} =~ ^[0-9]+$ ]] ; then FFProbe_Attribute_Parser_Failure=1 ; fi
  SourceFileFrameRateComposite="${Input[2]}"; SourceFileFrameRateComposite="${SourceFileFrameRateComposite//r_frame_rate=/}"
  ## Splitting strings by the delimiter, i.e. "30000/1001" or "30/1"
  if [[ "${SourceFileFrameRateComposite}" == "" ]] ; then 
    FFProbe_Attribute_Parser_Failure=1
  else 
    Delimited_String_Parser "${SourceFileFrameRateComposite}" "/"
    SourceFileFrameRate_Lead="${Delimited_String_Parser_Output[0]}"; SourceFileFrameRate_Trail="${Delimited_String_Parser_Output[1]}"
  fi
  # Processing array elements
  if [[ "${SourceFileFrameRate_Lead}" == "" ]] ; then FFProbe_Attribute_Parser_Failure=1 ; else String_to_Integer_Converter $SourceFileFrameRate_Lead; SourceFileFrameRate_Lead=$String_to_Integer_Converter_Output ; fi
  if [[ ! ${SourceFileFrameRate_Lead} =~ ^[0-9]+$ ]] ; then FFProbe_Attribute_Parser_Failure=1 ; fi
  if [[ "${SourceFileFrameRate_Trail}" == "" ]] ; then FFProbe_Attribute_Parser_Failure=1 ; else String_to_Integer_Converter $SourceFileFrameRate_Trail; SourceFileFrameRate_Trail=$String_to_Integer_Converter_Output ; fi
  if [[ ! ${SourceFileFrameRate_Trail} =~ ^[0-9]+$ ]] ; then FFProbe_Attribute_Parser_Failure=1 ; fi
  SourceFileBitRate="${Input[3]}"; SourceFileBitRate="${SourceFileBitRate//bit_rate=/}"
  if [[ "${SourceFileBitRate}" == "" ]] ; then FFProbe_Attribute_Parser_Failure=1 ; else String_to_Integer_Converter $SourceFileBitRate; SourceFileBitRate=$String_to_Integer_Converter_Output ; fi
  if [[ ! ${SourceFileBitRate} =~ ^[0-9]+$ ]] ; then FFProbe_Attribute_Parser_Failure=1 ; fi
  # Calculating Control Spot value
  if [[ ${FFProbe_Attribute_Parser_Failure} -eq 0 ]] ; then
    SourceFileFrameRate=$(( ( ${SourceFileFrameRate_Lead} / ${SourceFileFrameRate_Trail} ) + ( ${SourceFileFrameRate_Lead} % ${SourceFileFrameRate_Trail} > 0 ) ))
    PixelsPerFrame=$(( ${SourceFileWidth} * ${SourceFileHeight} )); BitRatePerFrame=$(( ( ${SourceFileBitRate} / ${SourceFileFrameRate} ) + ( ${SourceFileBitRate} % ${SourceFileFrameRate} > 0 ) ))
    # Calculating the weight (in bits) of 100x100 pixel spot (Control Spot)
    ControlSpotWeightInBits=$(( ( 10000 * ${BitRatePerFrame} / ${PixelsPerFrame} ) + ( ${BitRatePerFrame} % ${PixelsPerFrame} > 0 ) ))
#    echo "SourceFileWidth is $SourceFileWidth"
#    echo "SourceFileHeight is $SourceFileHeight"
#    echo "SourceFileFrameRateComposite is $SourceFileFrameRateComposite, SourceFileFrameRate_Lead is $SourceFileFrameRate_Lead, SourceFileFrameRate_Trail is $SourceFileFrameRate_Trail, SourceFileFrameRate is $SourceFileFrameRate"
#    echo "SourceFileBitRate is $SourceFileBitRate"
#    echo "PixelsPerFrame is $PixelsPerFrame, BitRatePerFrame is $BitRatePerFrame, ControlSpotWeightInBits is ${ControlSpotWeightInBits}"
  fi
  if [[ ${ControlSpotWeightInBits} == "" ]] ; then FFProbe_Attribute_Parser_Failure=1 ; fi
}

File_Extension_to_WIP_Renaming(){
  printf "Renaming source file from ${1} to ${2} to avoid double-processing\n"
  LogOutput+="Renaming source file from ${1} to ${2} to avoid double-processing\n"
  if ( ! mv "${1}" "${2}" >/dev/null 2>&1 ) ; then
    printf "Something went wrong! ${1} could not be renamed\n"
    LogOutput+="Something went wrong! ${1} could not be renamed\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  else
    wait
  fi
}

Source_to_WIP_Transfer(){
  ## Operations_Performance_Logging: Taking operations timer snapshot
  OperationsTimerStart=$(date +%s%3N)
  #
  GracePeriodInSeconds=600; SleepTimer=30; GraceIntervals=$(( ${GracePeriodInSeconds} / ${SleepTimer} )); GraceInterval=0
  printf "Transferring file from Source ${1}/${2} to Work-In-Progress ${3}/${4}/${5} directory for processing\n"
  LogOutput+="Transferring file from Source ${1}/${2} to Work-In-Progress ${3}/${4}/${5} directory for processing\n"
  if $( ! "${CopyMove}" "${1}/${2}" "${3}/${4}/${5}" >/dev/null 2>&1 ) ; then
    printf "Something went wrong! ${1}/${2} could not be transferred\n"
    LogOutput+="Something went wrong! ${1}/${2} could not be transferred\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
  # Waiting until the operation is complete
  until [[ -f "${3}/${4}/${5}" ]]
    do
      if [[ ${GraceInterval} < ${GraceIntervals} ]] ; then
        echo "File transfer is still in progress, checking the status in ${SleepTimer} seconds"
        sleep ${SleepTimer}
        GraceInterval=$(( ${GraceInterval} + 1 ))
      else
        if [[ ! -f "${3}/${4}/${5}" ]] ; then
          printf "Something went wrong! ${3}/${4}/${5} does not exist\n"
          LogOutput+="Something went wrong! ${3}/${4}/${5} does not exist\n"
          Log_Dumping_and_Exiting "${LogOutput}"
        fi
      fi
    done
  Operations_Performance_Logging ${FUNCNAME[0]}
}

Media_File_Encoding(){
  SourceFileSize=$(find "${1}" -exec ls -l {} \; | head -n1 | awk '{print $5}') #Not compatible with Mac: SourceFileSize=$(find "${1}" -printf "%s")
  if [[ "${SourceFileSize}" != "" ]] ; then String_to_Integer_Converter "${SourceFileSize}"; SourceFileSize=$String_to_Integer_Converter_Output ; fi
  EncodedFileSizeTarget=$(( ${SourceFileSize} / 100 * ${6} ))
  CRFValue=${4}
  RevisedCRF=${4}
  FFBorderCRFReached="no"
  ## Operations_Performance_Logging: Taking operations timer snapshot
  OperationsTimerStart=$(date +%s%3N)
  #
#  printf "Encoding file by invoking 'ffmpeg -n -hide_banner -i ${1} -c:v ${2} -pix_fmt + -color_range tv  -colorspace bt2020nc -color_primaries bt2020 -color_trc smpte2084 -vf scale=1920:1080 -preset ${3} -crf ${4} -c:a copy ${5} >/dev/null 2>&1'\n"
#  LogOutput+="Encoding file by invoking 'ffmpeg -n -hide_banner -i ${1} -c:v ${2} -pix_fmt + -color_range tv  -colorspace bt2020nc -color_primaries bt2020 -color_trc smpte2084 -vf scale=1920:1080 -preset ${3} -crf ${4} -c:a copy ${5} >/dev/null 2>&1'\n"
#  if ( ! ffmpeg -n -hide_banner -i "${1}" -c:v "${2}" -pix_fmt + -color_range tv  -colorspace bt2020nc -color_primaries bt2020 -color_trc smpte2084 -vf scale=1920:1080 -preset "${3}" -crf "${4}" -c:a copy "${5}" >/dev/null 2>&1 ) ; then
  printf "Encoding file by invoking 'ffmpeg -n -hide_banner -i ${1} -c:v ${2} -preset ${3} -crf ${4} -c:a copy ${5} >/dev/null 2>&1'\n"
  LogOutput+="Encoding file by invoking 'ffmpeg -n -hide_banner -i ${1} -c:v ${2} -preset ${3} -crf ${4} -c:a copy ${5} >/dev/null 2>&1'\n"
  if ( ! ffmpeg -n -hide_banner -i "${1}" -c:v "${2}" -preset "${3}" -crf "${4}" -c:a copy "${5}" >/dev/null 2>&1 ) ; then
    printf "Something went wrong! ${1} could not be encoded\n"
    LogOutput+="Something went wrong! ${1} could not be encoded\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
  EncodedFileSize=$(find "${5}" -exec ls -l {} \; | head -n1 | awk '{print $5}') #Not compatible with Mac: EncodedFileSize=$(find "${5}" -printf "%s")
  if [[ "${EncodedFileSize}" != "" ]] ; then String_to_Integer_Converter "${EncodedFileSize}"; EncodedFileSize=$String_to_Integer_Converter_Output ; fi
  if [[ ${EncodedFileSize} -le ${EncodedFileSizeTarget} ]] ; then
    EncodedCRF=${CRFValue}
    printf "Encoded CRF=${EncodedCRF} ${5} with file size ${EncodedFileSize} bytes reached the target ${EncodedFileSizeTarget} bytes, ${6}%% of ${1} source file with ${SourceFileSize} bytes. Proceeding to next step\n"
    LogOutput+="Encoded CRF=${EncodedCRF} ${5} with file size ${EncodedFileSize} bytes reached the target ${EncodedFileSizeTarget} bytes, ${6}%% of ${1} source file with ${SourceFileSize} bytes. Proceeding to next step\n"
  else
    CRFStepValuation=$(( 100 * ${EncodedFileSize} / ${EncodedFileSizeTarget} ))
    if [[ ${CRFStepValuation} -le 111 ]] ; then
      CRFStep=$(( ${EncodedFileSize} / ${EncodedFileSizeTarget} ))
    elif [[ ${CRFStepValuation} -gt 111 ]] && [[ ${CRFStepValuation} -lt 200 ]] ; then
      CRFStep=$(( ( ${EncodedFileSize} / ${EncodedFileSizeTarget} ) + ( ${EncodedFileSize} % ${EncodedFileSizeTarget} > 0 ) ))
    elif [[ ${CRFStepValuation} -ge 200 ]] ; then
      CRFStep=$(( ( ${EncodedFileSize} / ${EncodedFileSizeTarget} ) + ( ${EncodedFileSize} % ${EncodedFileSizeTarget} > 0 ) ))
      CRFStep=$(( ${CRFStep} * 3 / 2 ))
    fi
    EncodedCRF=${RevisedCRF}
    RevisedCRF=$(( ${RevisedCRF} + ${CRFStep} ))
    if [[ ${RevisedCRF} -gt ${FFBorderCRF} ]] ; then
      printf "CRF was revised with step ${CRFStep} from ${EncodedCRF} to ${RevisedCRF} beyond the factor ${FFBorderCRF}, downgrading the value to match CRF ${FFBorderCRF}\n"
      LogOutput+="CRF was revised with step ${CRFStep} from ${EncodedCRF} to ${RevisedCRF} beyond the factor ${FFBorderCRF}, downgrading the value to match CRF ${FFBorderCRF}\n"
      RevisedCRF=${FFBorderCRF}
    fi
    while [[ ${EncodedFileSize} -gt ${EncodedFileSizeTarget} ]] && [[ ${RevisedCRF} -le ${FFBorderCRF} ]] && [[ ${FFBorderCRFReached} == "no" ]] ; do
      printf "Encoded CRF=${EncodedCRF} ${5} with file size ${EncodedFileSize} bytes did not reach the target ${EncodedFileSizeTarget} bytes, ${6}%% of ${1} source file with ${SourceFileSize} bytes. Revising Constant Rate Factor (CRF) and proceeding to next round of encoding\n"
      LogOutput+="Encoded CRF=${EncodedCRF} ${5} with file size ${EncodedFileSize} bytes did not reach the target ${EncodedFileSizeTarget} bytes, ${6}%% of ${1} source file with ${SourceFileSize} bytes. Revising Constant Rate Factor (CRF) and proceeding to next round of encoding\n"
      if ( ! rm -f "${5}" >/dev/null 2>&1 ) ; then
        printf "Critical Error! Could not delete ${5} file\n"
        LogOutput+="Critical Error! Could not delete ${5} file\n"
        Log_Dumping_and_Exiting "${LogOutput}"
      fi
      printf "Encoding file by invoking 'ffmpeg -n -hide_banner -i ${1} -c:v ${2} -preset ${3} -crf ${RevisedCRF} -c:a copy ${5} >/dev/null 2>&1'\n"
      LogOutput+="Encoding file by invoking 'ffmpeg -n -hide_banner -i ${1} -c:v ${2} -preset ${3} -crf ${RevisedCRF} -c:a copy ${5} >/dev/null 2>&1'\n"
      if ( ! ffmpeg -n -hide_banner -i "${1}" -c:v "${2}" -preset "${3}" -crf "${RevisedCRF}" -c:a copy "${5}" >/dev/null 2>&1 ) ; then
        printf "Something went wrong! ${1} could not be encoded\n"
        LogOutput+="Something went wrong! ${1} could not be encoded\n"
        Log_Dumping_and_Exiting "${LogOutput}"
      fi
        EncodedFileSize=$(find "${5}" -exec ls -l {} \; | head -n1 | awk '{print $5}') #Not compatible with Mac: EncodedFileSize=$(find "${5}" -printf "%s"); 
        if [[ "${EncodedFileSize}" != "" ]] ; then String_to_Integer_Converter "${EncodedFileSize}"; EncodedFileSize=$String_to_Integer_Converter_Output ; fi
        # Multiplying by 100 to avoid mathematical operations with float
        CRFStepValuation=$(( 100 * ${EncodedFileSize} / ${EncodedFileSizeTarget} ))
        # Rounding down if the encoded file is 1.01 to 1.11 times the value of target size
        if [[ ${CRFStepValuation} -ge 100 ]] && [[ ${CRFStepValuation} -le 111 ]] ; then
          CRFStep=$(( ${EncodedFileSize} / ${EncodedFileSizeTarget} ))
        # Rounding up if the encoded file is 1.11 to 1.99 times the value of target size
        elif [[ ${CRFStepValuation} -gt 111 ]] && [[ ${CRFStepValuation} -lt 200 ]] ; then
          CRFStep=$(( ( ${EncodedFileSize} / ${EncodedFileSizeTarget} ) + ( ${EncodedFileSize} % ${EncodedFileSizeTarget} > 0 ) ))
        # Rounding up and multiplying by 1.5 if the encoded file is 2+ times the value of target size. Rounding down the result of multiplication by 1.5
        elif [[ ${CRFStepValuation} -ge 200 ]] ; then
          CRFStep=$(( ( ${EncodedFileSize} / ${EncodedFileSizeTarget} ) + ( ${EncodedFileSize} % ${EncodedFileSizeTarget} > 0 ) ))
          CRFStep=$(( ${CRFStep} * 3 / 2 ))
        fi
        EncodedCRF=${RevisedCRF}
        RevisedCRF=$(( ${RevisedCRF} + ${CRFStep} ))
        if [[ ${EncodedCRF} -lt ${FFBorderCRF} ]] && [[ ${RevisedCRF} -gt ${FFBorderCRF} ]] ; then
          printf "CRF was revised with step ${CRFStep} from ${EncodedCRF} to ${RevisedCRF} beyond the factor ${FFBorderCRF}, downgrading the value to match CRF ${FFBorderCRF}\n"
          LogOutput+="CRF was revised with step ${CRFStep} from ${EncodedCRF} to ${RevisedCRF} beyond the factor ${FFBorderCRF}, downgrading the value to match CRF ${FFBorderCRF}\n"
          RevisedCRF=${FFBorderCRF}
        elif [[ ${EncodedCRF} -eq ${FFBorderCRF} ]] && [[ ${RevisedCRF} -gt ${FFBorderCRF} ]] ; then 
          FFBorderCRFReached="yes"
          RevisedCRF=${EncodedCRF}
          printf "Border CRF of ${FFBorderCRF} is reached, exiting the encoding loop\n"
          LogOutput+="Border CRF of ${FFBorderCRF} is reached, exiting the encoding loop\n"
        fi
    done
    if [[ ${FFBorderCRFReached} == "yes" ]] ; then
      printf "Border CRF of ${FFBorderCRF} has been reached. Keeping encoded CRF=${RevisedCRF} ${5} with file size ${EncodedFileSize} bytes, the target was ${EncodedFileSizeTarget} bytes, ${6}%% of ${1} source file with ${SourceFileSize} bytes. Proceeding to next step\n"
      LogOutput+="Border CRF of ${FFBorderCRF} has been reached. Keeping encoded CRF=${RevisedCRF} ${5} with file size ${EncodedFileSize} bytes, the target was ${EncodedFileSizeTarget} bytes, ${6}%% of ${1} source file with ${SourceFileSize} bytes. Proceeding to next step\n"
    else
      printf "Encoded CRF=${EncodedCRF} ${5} with file size ${EncodedFileSize} bytes reached the target ${EncodedFileSizeTarget} bytes, ${6}%% of ${1} source file with ${SourceFileSize} bytes. Proceeding to next step\n"
      LogOutput+="Encoded CRF=${EncodedCRF} ${5} with file size ${EncodedFileSize} bytes reached the target ${EncodedFileSizeTarget} bytes, ${6}%% of ${1} source file with ${SourceFileSize} bytes. Proceeding to next step\n"
    fi
  fi
  Operations_Performance_Logging ${FUNCNAME[0]}
}

Metadata_Copying(){
  printf "Copying metadata by invoking 'exiftool -TagsFromFile ${1} -CreateDate -TrackCreateDate -MediaCreateDate -ModifyDate -TrackModifyDate -MediaModifyDate -Model=${2} ${3} >/dev/null 2>&1'\n"
  LogOutput+="Copying metadata by invoking 'exiftool -TagsFromFile ${1} -CreateDate -TrackCreateDate -MediaCreateDate -ModifyDate -TrackModifyDate -MediaModifyDate -Model=${2} ${3} >/dev/null 2>&1'\n"
  if ( ! exiftool -TagsFromFile "${1}" -CreateDate -TrackCreateDate -MediaCreateDate -ModifyDate -TrackModifyDate -MediaModifyDate -Model="${2}" "${3}" >/dev/null 2>&1) ; then
    printf "Something went wrong! ${3} could not be modified\n"
    LogOutput+="Something went wrong! ${3} could not be modified\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
}

FS_Attributes_Copying(){
  printf "Copying file system attributes by invoking 'touch -r ${1} ${2}'\n"
  LogOutput+="Copying file system attributes by invoking 'touch -r ${1} ${2}'\n"
  if ( ! touch -r "${1}" "${2}" ) ; then
    printf "Something went wrong! ${2} could not be modified\n"
    LogOutput+="Something went wrong! ${2} could not be modified\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
}

Encoded_File_to_Destination_Transfer_with_Duplicates_Detected(){
  ## Operations_Performance_Logging: Taking operations timer snapshot
  OperationsTimerStart=$(date +%s%3N)
  #
  printf "Passing the encoded ${2} file to Neatly-Sorted for filename normalisation and transferring from Work-In-Progress ${1} to Destination ${3} directory for storage\n"
  LogOutput+="Passing the encoded ${2} file to Neatly-Sorted for filename normalisation and transferring from Work-In-Progress ${1} to Destination ${3} directory for storage\n"
  # Checking for absence of other running neatly-compressed and other instances
  # Process_Conflict_Avoidance <process_name> <max_count_threshold> <grace_period_in_seconds>
  Process_Conflict_Avoidance "neatly-sorted.sh" "0" "60"
  if $( ! ${InstanceDirectoryParent}/neatly-sorted/neatly-sorted.sh "${1}/${2}" "${3}" >/dev/null 2>&1 ) ; then
    printf "Something went wrong! ${1}/${2} could not be transferred\n"
    LogOutput+="Something went wrong! ${1}/${2} could not be transferred\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  else
    wait
  fi
  Operations_Performance_Logging ${FUNCNAME[0]}
}

Encoded_File_to_Destination_Transfer_with_Duplicates_Undetected(){
  ## Operations_Performance_Logging: Taking operations timer snapshot
  OperationsTimerStart=$(date +%s%3N)
  #
  GracePeriodInSeconds=600; SleepTimer=30; GraceIntervals=$(( ${GracePeriodInSeconds} / ${SleepTimer} )); GraceInterval=0
  printf "Transferring the encoded ${2} file from Work-In-Progress ${1} to Destination ${3} directory for storage.\n"
  LogOutput+="Transferring the encoded ${2} file from Work-In-Progress ${1} to Destination ${3} directory for storage.\n"
  if ( ! mv "${1}/${2}" "${3}" >/dev/null 2>&1 ) ; then
    printf "Something went wrong! ${1}/${2} could not be transferred\n"
    LogOutput+="Something went wrong! ${1}/${2} could not be transferred\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
  # Waiting until the operation is complete
  until [[ -f "${3}/${2}" ]]
    do
      if [[ ${GraceInterval} < ${GraceIntervals} ]] ; then
        echo "File transfer is still in progress, checking the status in ${SleepTimer} seconds"
        sleep ${SleepTimer}
        GraceInterval=$(( ${GraceInterval} + 1 ))
      else
        if [[ ! -f "${3}/${2}" ]] ; then
          printf "Something went wrong! ${3}/${2} does not exist\n"
          LogOutput+="Something went wrong! ${3}/${2} does not exist\n"
          Log_Dumping_and_Exiting "${LogOutput}"
        fi
      fi
    done
  Operations_Performance_Logging ${FUNCNAME[0]}
}

Encoded_File_to_Destination_Transfer(){
  if [[ -f "${3}/${2}" ]] ; then
    printf "A duplicate ${3}/${2} file detected. Passing the encoded file to Neatly-Sorted for conflict handling\n"
    LogOutput+="A duplicate ${3}/${2} file detected. Passing the encoded file to Neatly-Sorted for conflict handling\n"
    Encoded_File_to_Destination_Transfer_with_Duplicates_Detected "${1}" "${2}" "${3}"
  else
    Encoded_File_to_Destination_Transfer_with_Duplicates_Undetected "${1}" "${2}" "${3}"
  fi
}

Encoded_Info_File_Generating(){
  if [[ ${CRFInfoFile} == "ON" ]] ; then
    printf "Generating info file by invoking 'touch ${1}/${2}'\n"
    LogOutput+="Generating info file by invoking 'touch ${1}/${2}'\n"
    if ( ! touch "${1}/${2}" ) ; then
      printf "Something went wrong! ${1}/${2} could not be modified\n"
      LogOutput+="Something went wrong! ${1}/${2} could not be modified\n"
      Log_Dumping_and_Exiting "${LogOutput}"
    fi
  fi
}

Original_File_to_Originals_Transfer(){
  ## Operations_Performance_Logging: Taking operations timer snapshot
  OperationsTimerStart=$(date +%s%3N)
  #
  printf "Transferring ${1} to Original Videos Subfolder ${2} directory for archiving\n"
  LogOutput+="Transferring ${1} to Original Videos Subfolder ${2} directory for archiving\n"
  if ( ! mv "${1}" "${2}" >/dev/null 2>&1 ) ; then
    printf "Something went wrong! ${1} could not be transferred\n"
    LogOutput+="Something went wrong! ${1} could not be transferred\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
  Operations_Performance_Logging ${FUNCNAME[0]}
}

WIP_Subdirectory_Cleanup(){
  printf "Cleaning up Work-In-Progress ${1}/ subdirectory\n"
  LogOutput+="Cleaning up Work-In-Progress ${1}/ subdirectory\n"
  if ( ! rm -rf "${1}/*.*" >/dev/null 2>&1 ) ; then
    printf "Critical Error! Could not delete files in ${1}/. Directory ${1} does not appear to be writable.\n"
    LogOutput+="Critical Error! Could not delete files in ${1}/. Directory ${1} does not appear to be writable.\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
}

WIP_Directory_Cleanup(){
  printf "Cleaning up Work-In-Progress ${1} directory\n"
  LogOutput+="Cleaning up Work-In-Progress ${1} directory\n"
  if ( ! rm -rf "${1}" >/dev/null 2>&1 ) ; then
    printf "Critical Error! Could not delete ${1}. Directory ${1} does not appear to be writable.\n"
    LogOutput+="Critical Error! Could not delete ${1}. Directory ${1} does not appear to be writable.\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  fi
}

#=======================================================================
# Script starts here
#=======================================================================

# Prerequisite Checks begins
#
# Checking for absence of other running neatly-compressed and other instances
# Process_Conflict_Avoidance <process_name> <max_count_threshold> <grace_period_in_seconds>
Process_Conflict_Avoidance "${InstanceNameBase}.sh" "2" "60"

# Checking for BASH version, v4+ is required
if [[ "${BASH_VERSINFO}" < 4 ]]; then
  printf "Prerequisite Critical Error! Non-supported BASH version ${BASH_VERSINFO} is identified. BASH version 4+ is required. Exiting now.\n"
  exit
else
  BASHVERSION="${BASH_VERSION}"
  LogOutput+="BASH version: ${BASHVERSION}\n"
fi

# Checking if application or service is installed, piping errors to NULL
if ( ! command -v ffmpeg &> /dev/null ) ; then
  printf "Prerequisite Critical Error! 'ffmpeg' is not installed or it could not be found. Use the commands below to install\n"
  printf " CentOS/RHEL: sudo dnf update && sudo dnf install ffmpeg\n"
  printf " Ubuntu: sudo apt update && sudo apt upgrade && sudo apt install ffmpeg\n"
  printf " Mac: brew install ffmpeg\n"
  printf " QNAP (Entware): opkg install ffmpeg\n"
  printf "Exiting now.\n"
  exit
else
  FFMPEGVERSION="$(ffmpeg -version | head -n1 | awk '{print $3}')"
  LogOutput+="ffmpeg version: ${FFMPEGVERSION}\n"
fi
if ( ! command -v ffprobe &> /dev/null ) ; then
  printf "Prerequisite Critical Error! 'ffprobe' is not installed or it could not be found. Use the commands below to install\n"
  printf " CentOS/RHEL: sudo dnf update && sudo dnf install ffprobe\n"
  printf " Ubuntu: sudo apt update && sudo apt upgrade && sudo apt install ffprobe\n"
  printf " Mac: brew install ffprobe\n"
  printf " QNAP (Entware): opkg install ffprobe\n"
  printf "Exiting now.\n"
  exit
else
  FFPROBEVERSION="$(ffprobe -version | head -n1 | awk '{print $3}')"
  LogOutput+="ffprobe version: ${FFPROBEVERSION}\n"
fi

# Checking for absence of other running ffmpeg instances
# Process_Conflict_Avoidance <process_name> <max_count_threshold> <grace_period_in_seconds>
Process_Conflict_Avoidance "ffmpeg" "0" "60"

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

if [[ ! -f "${InstanceDirectoryParent}/neatly-sorted/neatly-sorted.sh" ]] ; then
  printf "Prerequisite Critical Error! 'Neatly-Sorted' could not be found in common 'neatly/neatly-sorted/neatly-sorted.sh' location.\n"
  printf "Use https://github.com/ivang-coder/neatly to download or update Neatly-Sorted.\n"
  exit
elif [[ ! -x "${InstanceDirectoryParent}/neatly-sorted/neatly-sorted.sh" ]] ; then
  printf "Prerequisite Critical Error! 'Neatly-Sorted' does not appear to be executable.\n"
  printf "Run 'sudo chmod +x <neatly/neatly-sorted/neatly-sorted.sh>' to set the appropriate permissions.\n"
  exit
fi

# Checking for absence of other running neatly-sorted instances
# Process_Conflict_Avoidance <process_name> <max_count_threshold> <grace_period_in_seconds>
NeatlySortedVersion="$(${InstanceDirectoryParent}/neatly-sorted/neatly-sorted.sh --version)"
wait
if ! [[ "${NeatlySortedVersion}" =~ ^v* ]]; then
  Process_Conflict_Avoidance "neatly-sorted.sh" "0" "60"
  wait
  NeatlySortedVersion="$(${InstanceDirectoryParent}/neatly-sorted/neatly-sorted.sh --version)"
fi
LogOutput+="neatly-sorted version: ${NeatlySortedVersion}\n"


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
  # Checking if the first argument is a source path for file or directory and validating it
  /*|.) 
    # Exiting if there are issues with the source path
    # "-d directory" returns true if directory exists
    # "-e file" returns true if file exists
    # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
    if [[ -f "${1}" ]] ; then
      # Setting flag
      SourceType="file"
      CrawlDepth="1"
      # Extracting path from source absolute path
      SourcePath="$(dirname "${1}")"
      # Extracting file basename from source absolute path
      SourceFileBasename="$(basename "${1}")"
      # Substituting characters in file basename, the script chokes on "[" and "]" characters
      SourceFileBasename="${SourceFileBasename//[/(}"
      SourceFileBasename="${SourceFileBasename//]/)}"
      # Extracting file name
      SourceFileName="${SourceFileBasename%.*}"
      # Extracting file extension
      SourceFileExtension="${SourceFileBasename##*.}"
    elif [[ -d "${1}" ]] ; then
      # Setting flag
      SourceType="directory"
      # Passing the source path to a variable and continue
      SourcePath="${1}"
    else
      printf "Prerequisite Critical Error! Source path ${1} could not be found or does not exist. Exiting now.\n"
      printf "${SourcePathTip}\n"
      exit
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
  # Checking if the second argument is a destination path and validating it
  /*|.) 
    # Exiting if there are issues with the destination path
    # "-d directory" returns true if directory exists
    # "-e file" returns true if file exists
    # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
    if [[ ! -d "${2}" ]] ; then
      printf "Prerequisite Critical Error! Destination path ${2} could not be found or does not exist. Exiting now.\n"
      printf "${DestinationPathTip}\n"
      exit
    else
      # Passing the destination path to a variable and continue
      DestinationPath="${2}"
      DestinationPathSpecified=1
    fi
    ;;
  # Exiting if no expected parameter found
  *) 
    printf "Destination path has not been specified! Using ${SourcePath} as destination.\n"
    DestinationPath="${SourcePath}"
    DestinationPathSpecified=0
    ;;
esac

# Processing optional paramenters
#
# Checking if more arguments have been passed.
if [[ "${#}" -gt 1 ]] ; then
  # Validating optional parameters starting with the second parameter
  for Argument in "${@:2}" ; do
    case "${Argument}" in 
      # Checking if the argument is a encoder switch and validating it
      --x264)
        # Setting FFMpeg encoder to "libx264" and CRF to 18 visual "lossless"
        FFEncoder="libx264"
        FFDesiredCRF=18
        FFModel="FFx264"
        ;;
      # Checking if the argument is a encoder switch and validating it
      --x265)
        # Setting FFMpeg encoder to "libx265" and CRF to 21 visual "lossless"
        FFEncoder="libx265"
        FFDesiredCRF=21
        FFModel="FFx265"
        ;;
      # Checking if the argument is a preset switch and validating it
      --medium)
        # Setting FFMpeg preset to "medium"
        FFPreset="medium"
        ;;
      # Checking if the argument is a preset switch and validating it
      --slow)
        # Setting FFMpeg preset to "slow"
        FFPreset="slow"
        ;;
      # Checking if the argument is a preset switch and validating it
      --slower)
        # Setting FFMpeg preset to "slower"
        FFPreset="slower"
        ;;
      # Checking if the argument is a preset switch and validating it
      --veryslow)
        # Setting FFMpeg preset to "veryslow"
        FFPreset="veryslow"
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
      # Checking if the argument is file size target, --fstarget=<integer>, and validating it
      *"--fstarget"*)
        # Setting the file size target value as per the passed integer, --fstarget=<integer>
        FileSizeTarget="${Argument}"; FileSizeTarget="${FileSizeTarget//--fstarget=/}"
        ;;
      # Checking if the argument is file size target, --desiredCRF=<integer>, and validating it
      *"--desiredCRF"*)
        # Setting the file size target value as per the passed integer, --desiredCRF=<integer>
        FFDesiredCRF="${Argument}"; FFDesiredCRF="${FFDesiredCRF//--desiredCRF=/}"
        ;;
      # Checking if the argument is file size target, --borderCRF=<integer>, and validating it
      *"--borderCRF"*)
        # Setting the file size target value as per the passed integer, --borderCRF=<integer>
        FFBorderCRF="${Argument}"; FFBorderCRF="${FFBorderCRF//--borderCRF=/}"
        ;;
      # Checking if the argument is informational CRF file switch and validating it
      --crffileON)
        # Setting the informational CRF file ON, i.e. creating <filename.crf> file
        CRFInfoFile="ON"
        ;;
      # Checking if the argument is informational CRF file switch and validating it
      --crffileOFF)
        # Setting the informational CRF file OFF, i.e. not creating <filename.crf> file
        CRFInfoFile="OFF"
        ;;
      # Checking if the argument is a path to avoid "Prerequisite Critical Error! Unexpected parameter detected" message
      /*|.)
        # The paths processing and handling is done in the previous block
      ;;
      # Skipping if no expected parameter found
      *) 
        printf "Prerequisite Critical Error! Unexpected parameter detected: ${Argument}, ignoring it\n"
        ;;
    esac
  done
# Applying default parameters if the arguments have not been passed
else
  LogOutput+="No optional parameters have been passed. Applying the defaults.\n"
fi
# Validating parameters
String_to_Integer_Converter ${FileSizeTarget}; FileSizeTarget=$String_to_Integer_Converter_Output
if [[ ${FileSizeTarget} -lt 10 ]] || [[ ${FileSizeTarget} -gt 50 ]] || [[ ${FileSizeTarget} -eq 0 ]] ; then FileSizeTarget=${DefaultFileSizeTarget} ; fi
String_to_Integer_Converter ${FFDesiredCRF}; FFDesiredCRF=$String_to_Integer_Converter_Output
if [[ ${FFDesiredCRF} -lt 0 ]] || [[ ${FFDesiredCRF} -gt 50 ]] || [[ ${FFDesiredCRF} -eq 0 ]] ; then FFDesiredCRF=${DefaultDesiredCRF} ; fi
String_to_Integer_Converter ${FFBorderCRF}; FFBorderCRF=$String_to_Integer_Converter_Output
if [[ ${FFBorderCRF} -lt 0 ]] || [[ ${FFBorderCRF} -gt 50 ]] || [[ ${FFBorderCRF} -eq 0 ]] ; then FFBorderCRF=${DefaultBorderCRF} ; fi
if [[ ${FFDesiredCRF} -gt ${FFBorderCRF} ]] ; then FFDesiredCRF=${FFBorderCRF} ; fi
# Writing the aggregate of parameters to the log file
LogOutput+="Proceeding with parameters below.\n" 
LogOutput+="  Source type: ${SourceType}\n"
LogOutput+="  Control Spot Threshold in bits: ${ControlSpotWeightInBitsThreshold}\n"
LogOutput+="  FFMpeg EXIF model: ${FFModel}\n"
LogOutput+="  Mandatory parameters:\n"
LogOutput+="    Source path: ${SourcePath}\n"
LogOutput+="    Destination path: ${DestinationPath}\n"
LogOutput+="  Optional parameters:\n"
LogOutput+="    FFMpeg encoder: ${FFEncoder}\n"
LogOutput+="    FFMpeg preset: ${FFPreset}\n"
LogOutput+="    FFMpeg Desired Constant Rate Factor (CRF): ${FFDesiredCRF}\n"
LogOutput+="    FFMpeg Border Constant Rate Factor (CRF): ${FFBorderCRF}\n"
LogOutput+="    File size target in percent: ${FileSizeTarget}%%\n"
LogOutput+="    Informational CRF file: ${CRFInfoFile}\n"
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
    LogOutput+="ON, Source and ${CrawlDepth} levels deep\n"
    ;;
  1)
    LogOutput+="OFF, Source root files only\n"
    ;;
esac
# Printing the aggregate of parameters to the screen
printf "${LogOutput}\n"

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
# Getting hostname and replacing "-" and "_" characters
HostName=$(hostname)
HostName="${HostName//-/}"; HostName="${HostName//_/}"; HostName="${HostName//./}"
# Forming log filename name in <instance>-<hostname>-YYYYMMDD.log format
LogFileName="${InstanceNameBase}-${LogFileDate}.log"
# Forming Work-In-Progress directory name in WIP-YYYYMMDD-HHmmss format
WIPDirectoryName="WIP-${WIPDirectoryDate}"
# Defining temp folder and Forming WIP directory
WIPTempDirectory="/tmp"
WIPDirectoryPath="${WIPTempDirectory}/${WIPDirectoryName}"

## Operations_Performance_Logging: Taking operations timer snapshot
OperationsTimerStart=$(date +%s%3N)

## Checking if gnu date is installed for date-time output with milliseconds
if [[ "${OSTYPE}" == "darwin"* ]] && [[ "${OperationsTimer}" == "ON" ]] ; then
  if ( ! command -v gdate &> /dev/null ) ; then
    printf "Prerequisite Critical Error! 'gnu date' is not installed or it could not be found. Use the commands below to install\n"
    printf " Mac: brew install coreutils\n"
    printf "Exiting now.\n"
    exit
  else
    PrerequisitesOK=1
  fi
fi

## Checking if the source directory is writable by creating a notification file, piping errors to NULL
if ( ! touch "${SourcePath}/${NotificationFile}" >/dev/null 2>&1 ) ; then
  printf "Prerequisite Critical Error! Could not write ${SourcePath}/${NotificationFile}. Directory ${SourcePath} does not appear to be writable. Exiting now.\n"
  exit
else
  PrerequisitesOK=1
fi
## Checking if the directory is writable by creating Work-In-Progress folder, piping errors to NULL
if ( ! mkdir -p "${WIPDirectoryPath}" >/dev/null 2>&1 ) ; then
  printf "Prerequisite Critical Error! Could not write ${WIPDirectoryPath}. Directory ${WIPTempDirectory} does not appear to be writable. Exiting now.\n"
  exit
else
  PrerequisitesOK=1
fi
## Checking if the source directory is writable by creating hidden folder for original video files, piping errors to NULL
if ( ! mkdir -p "${SourcePath}/${OriginalVideosSubfolder}" >/dev/null 2>&1 ) ; then
  printf "Prerequisite Critical Error! Could not write ${OriginalVideosSubfolder}. Directory ${SourcenPath} does not appear to be writable. Exiting now.\n"
  exit
else
  PrerequisitesOK=1
fi
## Checking if the source directory is writable by creating Log file, piping errors to NULL
if ( ! touch "${SourcePath}/${LogFileName}" >/dev/null 2>&1 ) ; then
  printf "Prerequisite Critical Error! Could not write ${LogFileName}. Directory ${SourcePath} does not appear to be writable. Exiting now.\n"
  exit
else
  PrerequisitesOK=1
fi
## Checking if the destination directory is writable by creating Metadata folder, piping errors to NULL
if ( ! mkdir -p "${DestinationPath}/${MetadataSubfolder}" >/dev/null 2>&1 ) ; then
  printf "Prerequisite Critical Error! Could not write ${MetadataSubfolder}. Directory ${DestinationPath} does not appear to be writable. Exiting now.\n"
  exit
else
  PrerequisitesOK=1
fi
Operations_Performance_Logging "Prerequisites"
# End of Prerequisite Checks

# Checking files in source directory
# Taking operations timer snapshot
OperationsTimerStart=$(date +%s%3N)
### Single file mode. Confirming the file's media extension
if [[ "${SourceType}" == "file" ]] ; then
  NormalisedFileExtension="$(echo "${SourceFileExtension}" | awk '{print tolower($0)}')"
  if ! [[ "$NormalisedFileExtension" =~ ^(mov|mpg|mp4|mpv|)$ ]]; then
    FilesFetched=0
  else
    FilesFetched=1
  fi
fi
### Directory mode. Confirming files with specific media extensions in source directory and its subfolders, ingoring hidden folders, files with leading "." and files containing "FFx264" or "FFx265"
if [[ "${SourceType}" == "directory" ]] ; then
  printf "Confirming files potentially requiring processing by invoking 'find "${SourcePath}" -maxdepth "${CrawlDepth}" -not -path '*/\.*' -type f \( -iname "*.[Mm][PpOo][Gg4Vv]" -not -iname "*FFx26*" -not -path "*${OriginalVideosSubfolder}*" -not -path "*Duplicates*" -not -iname "*DUP*" -not -path "*Unverified*" -not -iname "*UVRFD*" \) -print | head -n1'\n"
  LogOutput+="Confirming files potentially requiring processing by invoking 'find "${SourcePath}" -maxdepth "${CrawlDepth}" -not -path '*/\.*' -type f \( -iname "*.[Mm][PpOo][Gg4Vv]" -not -iname "*FFx26*" -not -path "*${OriginalVideosSubfolder}*" -not -path "*Duplicates*" -not -iname "*DUP*" -not -path "*Unverified*" -not -iname "*UVRFD*" \) -print | head -n1'\n"
  SourceFileCheck="$(find "${SourcePath}" -maxdepth "${CrawlDepth}" -not -path '*/\.*' -type f \( -iname "*.[Mm][PpOo][Gg4Vv]" -not -iname "*FFx26*" -not -path "*${OriginalVideosSubfolder}*" -not -path "*Duplicates*" -not -iname "*DUP*" -not -path "*Unverified*" -not -iname "*UVRFD*" \) -print | head -n1)"
  wait
  ### Checking the number of fetched files before proceeding further
  if [[ "${SourceFileCheck[@]: -1}" == "" ]] ; then 
    FilesFetched=0
  else
    FilesFetched=1
  fi
fi
Operations_Performance_Logging "Search for files for processing"


# Verifying media file bitrate and transferring files from Source to Work-In-Progress directory
if [[ "${SourceType}" == "file" ]] && [[ ${PrerequisitesOK} -eq 1 ]] && [[ ${FilesFetched} -eq 1 ]] ; then
  # Passing Source folder name, i.e. no path
  SourcePathBasename="$(basename "${SourcePath}")"
  # Ensure the file exists, then proceed with processing
  # "-d directory" returns true if directory exists
  # "-e file" returns true if file exists
  # "-f file" returns true if file exists and is a regular file, i.e. something that is not a directory, symlink, socket, device, etc.
  # ${#VAR} calculates the number of characters in a variable
  if [[ ! -f "${SourcePath}/${SourceFileBasename}" ]] || [[ "${#SourceFileBasename}" -eq 0 ]] ; then
    printf "Something went wrong! File ${SourcePath}/${SourceFileBasename} could not be found!\n"
    LogOutput+="Something went wrong! File ${SourcePath}/${SourceFileBasename} could not be found!\n"
    Log_Dumping_and_Exiting "${LogOutput}"
  else
    # Retrieving media file attributes with ffprobe
    SourceFileFFProbeOutput=($(ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate,bit_rate -of default=noprint_wrappers=1 ${SourcePath}/${SourceFileBasename}))
    
    FFProbe_Attribute_Parser "${SourceFileFFProbeOutput[@]}"

    if [[ ${FFProbe_Attribute_Parser_Failure} -eq 1 ]] ; then
      printf "Could not retrieve ffprobe attributes from media file ${SourcePath}/${SourceFileBasename}. Exiting now.\n"
      LogOutput+="Could not retrieve ffprobe attributes from media file ${SourcePath}/${SourceFileBasename}. Exiting now.\n"
      printf "######### file operation complete ############\n"
      LogOutput+="######### file operation complete ############\n"
      Log_Dumping_and_Exiting "${LogOutput}"
    elif ([ ${FFProbe_Attribute_Parser_Failure} -eq 0 ] && [ ${ControlSpotWeightInBits} -gt ${ControlSpotWeightInBitsThreshold} ]) ; then
      printf "Media file ${SourcePath}/${SourceFileBasename} Control Spot: ${ControlSpotWeightInBits} bits, Control Spot Threshold: ${ControlSpotWeightInBitsThreshold} bits, preparing for processing\n"
      LogOutput+="Media file ${SourcePath}/${SourceFileBasename} Control Spot: ${ControlSpotWeightInBits} bits, Control Spot Threshold: ${ControlSpotWeightInBitsThreshold} bits, preparing for processing\n"

      Work_In_Progress_Preparation "${WIPDirectoryPath}" "${SourcePathBasename}"

      Exiftool_Metadata_to_JSON_Exporting "${SourcePath}/${SourceFileBasename}" "${DestinationPath}/${MetadataSubfolder}/${SourceFileName}_exiftool.json"

      FFProbe_Metadata_to_JSON_Exporting "${SourcePath}/${SourceFileBasename}" "${DestinationPath}/${MetadataSubfolder}/${SourceFileName}_ffprobe.json"

      File_Extension_to_WIP_Renaming "${SourcePath}/${SourceFileBasename}" "${SourcePath}/${SourceFileBasename}.wip"

      Source_to_WIP_Transfer "${SourcePath}" "${SourceFileBasename}.wip" "${WIPDirectoryPath}" "${SourcePathBasename}" "${SourceFileBasename}"

      # Substituting MODEL with FFx264/FFx265, or adding FFx264/FFx265
      if [[ ${SourceFileName} == *CAMERA* ]] ; then
        SourceFileNameEncoded="${SourceFileName//CAMERA/${FFModel}}"
      else
        SourceFileNameEncoded="${SourceFileName}-${FFModel}"
      fi

      Media_File_Encoding "${WIPDirectoryPath}/${SourcePathBasename}/${SourceFileBasename}" "${FFEncoder}" "${FFPreset}" ${FFDesiredCRF} "${WIPDirectoryPath}/${SourcePathBasename}/${SourceFileNameEncoded}.${SourceFileExtension}" ${FileSizeTarget}

      Metadata_Copying "${SourcePath}/${SourceFileBasename}.wip" "${FFModel}" "${WIPDirectoryPath}/${SourcePathBasename}/${SourceFileNameEncoded}.${SourceFileExtension}"

      FS_Attributes_Copying "${SourcePath}/${SourceFileBasename}.wip" "${WIPDirectoryPath}/${SourcePathBasename}/${SourceFileNameEncoded}.${SourceFileExtension}"

      Encoded_File_to_Destination_Transfer "${WIPDirectoryPath}/${SourcePathBasename}" "${SourceFileNameEncoded}.${SourceFileExtension}" "${DestinationPath}"

      Encoded_Info_File_Generating "${DestinationPath}/${MetadataSubfolder}" "${SourceFileNameEncoded}.crf${EncodedCRF}"

      Original_File_to_Originals_Transfer "${SourcePath}/${SourceFileBasename}.wip" "${SourcePath}/${OriginalVideosSubfolder}/${SourceFileBasename}"

      WIP_Subdirectory_Cleanup "${WIPDirectoryPath}/${SourcePathBasename}"

      printf "######### file operation complete ############\n"
      LogOutput+="######### file operation complete ############\n"
      Log_Dumping "${LogOutput}"
    elif ([ ${FFProbe_Attribute_Parser_Failure} -eq 0 ] && [ ${ControlSpotWeightInBits} -le ${ControlSpotWeightInBitsThreshold} ]) ; then
      printf "Media file ${SourcePath}/${SourceFileBasename} Control Spot: ${ControlSpotWeightInBits} bits, Control Spot Threshold: ${ControlSpotWeightInBitsThreshold} bits, no processing is required. Exiting now.\n"
      LogOutput+="Media file ${SourcePath}/${SourceFileBasename} Control Spot: ${ControlSpotWeightInBits} bits, Control Spot Threshold: ${ControlSpotWeightInBitsThreshold} bits, no processing is required. Exiting now.\n"
      printf "######### file operation complete ############\n"
      LogOutput+="######### file operation complete ############\n"
      Log_Dumping_and_Exiting "${LogOutput}"
    fi
  fi
elif [[ "${SourceType}" == "directory" ]] && [[ ${PrerequisitesOK} -eq 1 ]] && [[ ${FilesFetched} -eq 1 ]] ; then
  # Searching for files with specific video extensions in source directory
  printf "Forming a list of files for processing by invoking 'find "${SourcePath}" -maxdepth "${CrawlDepth}" -not -path '*/\.*' -type f \( -iname "*.[Mm][PpOo][Gg4Vv]" -not -iname "*FFx26*" -not -path "*${OriginalVideosSubfolder}*" -not -path "*Duplicates*" -not -iname "*DUP*" -not -path "*Unverified*" -not -iname "*UVRFD*" \) | sort -n'\n"
  LogOutput+="Forming a list of files for processing by invoking 'find "${SourcePath}" -maxdepth "${CrawlDepth}" -not -path '*/\.*' -type f \( -iname "*.[Mm][PpOo][Gg4Vv]" -not -iname "*FFx26*" -not -path "*${OriginalVideosSubfolder}*" -not -path "*Duplicates*" -not -iname "*DUP*" -not -path "*Unverified*" -not -iname "*UVRFD*" \) | sort -n'\n"
  SourceDirectoryFileList="$(find "${SourcePath}" -maxdepth "${CrawlDepth}" -not -path '*/\.*' -type f \( -iname "*.[Mm][PpOo][Gg4Vv]" -not -iname "*FFx26*" -not -path "*${OriginalVideosSubfolder}*" -not -path "*Duplicates*" -not -iname "*DUP*" -not -path "*Unverified*" -not -iname "*UVRFD*" \) | sort -n)"
  wait
  ### Checking the number of fetched files before proceeding further
  if [[ "${SourceDirectoryFileList[@]: -1}" != "" ]] ; then 
    # Taking one file at a time and processing it
    #
    # File path composition
    #   SourceFileAbsolutePath = SourceDirectoryPath + SourceFileBasename, where
    #     SourceFileBasename = SourceFileName + SourceFileExtension
    #
    for SourceFileAbsolutePath in ${SourceDirectoryFileList[@]}; do
      if [[ ! -f "${SourceFileAbsolutePath}" ]] || [[ "${#SourceFileAbsolutePath}" -eq 0 ]] ; then
        printf "Something went wrong! File ${SourceFileAbsolutePath} could not be found. Proceeding to the next file.\n"
        LogOutput+="Something went wrong! File ${SourceFileAbsolutePath} could not be found. Proceeding to the next file.\n"
      else
        # Extracting path from source absolute path
        SourceFileDirectoryPath="$(dirname "${SourceFileAbsolutePath}")"
        # Extracting file basename from source absolute path
        SourceFileBasename="$(basename "${SourceFileAbsolutePath}")"
        # Substituting characters in file basename, the script chokes on "[" and "]" characters
        SourceFileBasename="${SourceFileBasename//[/(}"
        SourceFileBasename="${SourceFileBasename//]/)}"
        # Extracting file name
        SourceFileName="${SourceFileBasename%.*}"
        # Extracting file extension
        SourceFileExtension="${SourceFileBasename##*.}"
        # Passing Source folder name, i.e. no path
        SourcePathBasename="$(basename "${SourceFileDirectoryPath}")"
        #

        # Retrieving media file attributes with ffprobe
        SourceFileFFProbeOutput=($(ffprobe -v quiet -select_streams v:0 -show_entries stream=width,height,r_frame_rate,bit_rate -of default=noprint_wrappers=1 ${SourceFileDirectoryPath}/${SourceFileBasename}))

        FFProbe_Attribute_Parser "${SourceFileFFProbeOutput[@]}"

        if [[ ${FFProbe_Attribute_Parser_Failure} -eq 1 ]] ; then
          printf "Could not retrieve ffprobe attributes from media file ${SourceFileDirectoryPath}/${SourceFileBasename}. Proceeding to the next file.\n"
          LogOutput+="Could not retrieve ffprobe attributes from media file ${SourceFileDirectoryPath}/${SourceFileBasename}. Proceeding to the next file.\n"
          printf "######### file operation complete ############\n"
          LogOutput+="######### file operation complete ############\n"
          Log_Dumping "${LogOutput}"
        elif ([ ${FFProbe_Attribute_Parser_Failure} -eq 0 ] && [ ${ControlSpotWeightInBits} -gt ${ControlSpotWeightInBitsThreshold} ]) ; then
          printf "Media file ${SourceFileDirectoryPath}/${SourceFileBasename} Control Spot: ${ControlSpotWeightInBits} bits, Control Spot Threshold: ${ControlSpotWeightInBitsThreshold} bits, preparing for processing\n"
          LogOutput+="Media file ${SourceFileDirectoryPath}/${SourceFileBasename} Control Spot: ${ControlSpotWeightInBits} bits, Control Spot Threshold: ${ControlSpotWeightInBitsThreshold} bits, preparing for processing\n"

          Work_In_Progress_Preparation "${WIPDirectoryPath}" "${SourcePathBasename}"

          Exiftool_Metadata_to_JSON_Exporting "${SourceFileDirectoryPath}/${SourceFileBasename}" "${DestinationPath}/${MetadataSubfolder}/${SourceFileName}_exiftool.json"

          FFProbe_Metadata_to_JSON_Exporting "${SourceFileDirectoryPath}/${SourceFileBasename}" "${DestinationPath}/${MetadataSubfolder}/${SourceFileName}_ffprobe.json"

          File_Extension_to_WIP_Renaming "${SourceFileDirectoryPath}/${SourceFileBasename}" "${SourceFileDirectoryPath}/${SourceFileBasename}.wip"

          Source_to_WIP_Transfer "${SourceFileDirectoryPath}" "${SourceFileBasename}.wip" "${WIPDirectoryPath}" "${SourcePathBasename}" "${SourceFileBasename}"

          # Substituting MODEL with FFx264/FFx265, or adding FFx264/FFx265
          if [[ ${SourceFileName} == *CAMERA* ]] ; then
            SourceFileNameEncoded="${SourceFileName//CAMERA/${FFModel}}"
          else
            SourceFileNameEncoded="${SourceFileName}-${FFModel}"
          fi

          Media_File_Encoding "${WIPDirectoryPath}/${SourcePathBasename}/${SourceFileBasename}" "${FFEncoder}" "${FFPreset}" ${FFDesiredCRF} "${WIPDirectoryPath}/${SourcePathBasename}/${SourceFileNameEncoded}.${SourceFileExtension}" ${FileSizeTarget}

          Metadata_Copying "${SourceFileDirectoryPath}/${SourceFileBasename}.wip" "${FFModel}" "${WIPDirectoryPath}/${SourcePathBasename}/${SourceFileNameEncoded}.${SourceFileExtension}"

          FS_Attributes_Copying "${SourceFileDirectoryPath}/${SourceFileBasename}.wip" "${WIPDirectoryPath}/${SourcePathBasename}/${SourceFileNameEncoded}.${SourceFileExtension}"

          if [[ ${DestinationPathSpecified} -eq 1 ]] ; then
            Encoded_File_to_Destination_Transfer "${WIPDirectoryPath}/${SourcePathBasename}" "${SourceFileNameEncoded}.${SourceFileExtension}" "${DestinationPath}"
          elif [[ ${DestinationPathSpecified} -eq 0 ]] ; then
            Encoded_File_to_Destination_Transfer "${WIPDirectoryPath}/${SourcePathBasename}" "${SourceFileNameEncoded}.${SourceFileExtension}" "${SourceFileDirectoryPath}"
          fi

          Encoded_Info_File_Generating "${DestinationPath}/${MetadataSubfolder}" "${SourceFileNameEncoded}.crf${EncodedCRF}"

          Original_File_to_Originals_Transfer "${SourceFileDirectoryPath}/${SourceFileBasename}.wip" "${SourcePath}/${OriginalVideosSubfolder}/${SourceFileBasename}"

          WIP_Subdirectory_Cleanup "${WIPDirectoryPath}/${SourcePathBasename}"

          printf "######### file operation complete ############\n"
          LogOutput+="######### file operation complete ############\n"
          Log_Dumping "${LogOutput}"
        elif ([ ${FFProbe_Attribute_Parser_Failure} -eq 0 ] && [ ${ControlSpotWeightInBits} -le ${ControlSpotWeightInBitsThreshold} ]) ; then
          printf "Media file ${SourceFileDirectoryPath}/${SourceFileBasename} Control Spot: ${ControlSpotWeightInBits} bits, Control Spot Threshold: ${ControlSpotWeightInBitsThreshold} bits, no processing is required. Proceeding to the next file.\n"
          LogOutput+="Media file ${SourceFileDirectoryPath}/${SourceFileBasename} Control Spot: ${ControlSpotWeightInBits} bits, Control Spot Threshold: ${ControlSpotWeightInBitsThreshold} bits, no processing is required. Proceeding to the next file.\n"
          printf "######### file operation complete ############\n"
          LogOutput+="######### file operation complete ############\n"
          Log_Dumping "${LogOutput}"
        fi

        Graceful_Termination_Request_Check "stop"
      fi
    done
  fi
else
  printf "No files have been identified for processing in ${SourcePath}.\n"
  LogOutput+="No files have been identified for processing in ${SourcePath}.\n"
fi

Log_Dumping_and_Exiting "${LogOutput}"
