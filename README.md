# Neatly-Sorted Readme
Neatly-Sorted is a Shell-written EXIF-based media file processor with sort and deduplication features.

## Overview
The script processes media files (i.e. jpg, jpeg, mp4, mpg and mov) and it uses EXIFTOOL to extract "SubSecCreateDate", "CreateDate" and "Model" metadata. Depending on the selected options, the processed files are moved to "Destination" location with a chosen directory sturucture.

If EXIF attempts fail to read metadata, then the less reliable file attributes get extracted by swithing on the appropriate option.

In case file attribute extaction fails, the source filename gets amended by adding 'unverified' suffix in **"UVRFDXXX"** format, i.e. my-picture-UVRFD000.jpg.  
The unverified files are placed in "Unverified" folder within "Destination" path, i.e. ```/my-destination/Unverified/my-picture-UVRFD000.jpg```

## Compatibility  
**BASH:** v4+  
**CentOS/RHEL:** v7, v8  
**Ubuntu:** 18.04 LTS, 20.04.3 LTS  
**QNAP (Entware):** 4.2.6, opkg version 1bf042dd06751b693a8544d2317e5b969d666b69 (2021-06-13)  
**WSL (Windows Linux Subsystem):** Ubuntu (18.04 LTS, 20.04.3 LTS)  

## Filename format
Filename format depends on the chosen folder structure.  
&nbsp;&nbsp;--YMD = YEAR/MONTH/DAY, i.e. /2021/05/10/picture.jpg  
&nbsp;&nbsp;--YM = YEAR/MONTH, i.e. /2021/05/picture.jpg  
&nbsp;&nbsp;--Y (default) = YEAR, i.e. /2021/picture.jpg
&nbsp;&nbsp;--NOSORT = All, i.e. Destination/All/picture.jpg

The expected filename format: **MODEL-DATE-SECONDS-SUBSECONDS.EXTENSION**  
```Example: ONEPLUSA5000-20200613-125351-184775.jpg```

In case the files are produced by a camera that does not create **"SubSecCreateDate"** field in metadata, the expected filename format: **MODEL-DATE-SECONDS-000000.EXTENSION**  
```Example: E6533-20211205-001132-000000.jpg```

## Prerequisites 
Use the commands below to install exiftool  
**CentOS/RHEL:** ```sudo dnf update && sudo dnf install perl-Image-ExifTool```  
**Ubuntu:** ```sudo apt update && sudo apt upgrade && sudo apt install libimage-exiftool-perl```  
**Mac:** ```brew install exiftool```
**QNAP (Entware):** ```opkg install perl-image-exiftool```

## File Processing Overview

### Step 1. Confirm read-write access and create directories
**Notification file at Source:** ```/SourceDirectory/monitoried-by-Neatly-Sorted.info```  
**Work-In-Progress (WIP) folder at Source:** ```/SourceDirectory/WIP-YYYYMMDD-HHmmss```  
**Duplicates folder at Destination:** ```/DestinationDirectory/Duplicates```  
**Unverified folder at Destination:** ```/DestinationDirectory/Unverified```  
**Log file at Destination:** ```/DestinationDirectory/neatly-sorted-YYYYMMDD.log```  

### Step 2. Search media files (i.e. jpg, jpeg, mp4, mpg and mov) in Source Directory, include subfolders (3 levels deep) if Crawl is enabled.  
```Note! Hidden files and folders (prefixed with '.') are excluded from the search scope. Example: /my-location/.my-hidden-image.jpg```  
**/SourceDirectory/**  
├── subfolder01/  
│   └── file13.mov  
├── subfolder02/  
│   └── file23.mov  
├── file01.jpg  
├── file02.jpeg  
├── file03.mov  
├── file04.jpeg  
└── file05.mov

### Step 3. Move/copy the found files to temporary Work-In-Progress (WIP) directory in subfolders with names matching the Source's name and it's subfolders
**/SourceDirectory/WIP-YYYYMMDD-HHmmss/**  
├── subfolder01/  
│   └── file13.mov  
├── subfolder02/  
│   └── file23.mov  
└── SourceDirectoryName/  
        ├── file01.jpg  
        ├── file02.jpeg  
        ├── file03.mov  
        ├── file04.jpeg  
        └── file05.mov

### Step 4. Create directories at Destination location
**/DestinationDirectory/Duplicates**  
&nbsp;&nbsp;directory for duplicate files where **"DUPXXX"** suffix is added to the filenames, i.e.  
```/DestinationDirectory/Duplicates/MODEL-DATE-SECONDS-DUP000.jpg.```

**/DestinationDirectory/Unverified**  
&nbsp;&nbsp;directory for the files for which metadata could not be retrieved where the filenames get amended by adding 'unverified' suffix in **"UVRFDXXX"** format, i.e.  
```/DestinationDirectory/Unverified/my-picture-UVRFD000.jpg.```

### Step 5. Prepare (create) log file
**/DestinationDirectory/neatly-sorted-<YYYYMMDD>.log**

### Step 6. Prepare and move the WIP files to Destination location with the chosen folder structure
**Destination files sort-by options:**  
&nbsp;&nbsp;--YMD = /YEAR/MONTH/DAY/picture.jpg, i.e. /DestinationDirectory/2021/05/10/picture.jpg  
&nbsp;&nbsp;--YM = /YEAR/MONTH/picture.jpg, i.e. /DestinationDirectory/2021/05/picture.jpg  
&nbsp;&nbsp;--Y (default) = /YEAR, i.e. /DestinationDirectory/2021/picture.jpg
&nbsp;&nbsp;--NOSORT = /All, i.e. Destination/All/picture.jpg

An example with YM (/YEAR/MONTH/) folder structure
/DestinationDirectory/  
├── 2020/  
│   └── 05/  
│       └── file03.mov  
├── 2021/  
│   └── 11/  
│       └── file04.jpeg  
├── Duplicates/  
│   ├── E6533-20211205-001132-000000-DUP000.jpg  
│   ├── E6533-20211205-001132-000000-DUP001.jpg  
│   ├── ONEPLUSA5000-20200613-125351-184775-DUP000.jpg  
│   └── ONEPLUSA5000-20200613-125351-184775-DUP001.jpg  
├── Unverified/    
│   ├── my_image-UVRFD000.jpg  
│   └── my_image-UVRFD001.jpg  
└── neatly-sorted-20210513.log

### Step 7. WIP directory cleanup
**WIP subfolder removal:** deleting all empty subfolders location in Work-In-Progress directory if Crawl is enabled  
**WIP folder removal:** deleting empty Work-In-Progress directory  

### Step 8. Ending of programme
**Pre-exit maintenance:** reverting global parameters and variables back to the original state, like Internal Field Separator (IFS)  
**Logging and exiting:** writing the processing results (state) to the log file and exiting  

## Help menu
**Help:** for more parameters use '/bin/bash neatly-sorted.sh <-h|--help>'

**Usage:** '/bin/bash neatly-sorted.sh <source-path|.> <destination-path|.> <--Ext|--EXT|--ext> <--FSAttribute|--NoFSAttribute> <--YMD|--YM|--Y|--NOSORT> <--copy|--move>  <--timerON|--timerOFF> <--crawlON|--crawlOFF>  
    
&nbsp;&nbsp;Mandatory parameters: **source-path**, **destination-path**

**Source** absolute path is required with leading '/'. Alternatively use '.' for current directory.  
```Example: '/home/username/pictures/'```

**Destination** absolute path is required with leading '/'. Alternatively, use '.' for current directory.  
```Example: '/mystorage/sorted-pictures/'```

**Extension case switch options:**  
&nbsp;&nbsp;--ExT = unchanged, i.e. JPEG > JPEG, jpeg > jpeg  
&nbsp;&nbsp;--EXT = uppercase, i.e. jpeg > JPEG  
&nbsp;&nbsp;--ext = lowercase (recommended), i.e. JPEG > jpeg  

**File system attribute extraction** is somewhat unreliable and can be used as the last resort.  
&nbsp;&nbsp;--FSAttribute, can cause conflicts and affect file sorting  
&nbsp;&nbsp;--NoFSAttribute (default) is the recommended option  

**Destination files sort-by options:**  
&nbsp;&nbsp;--YMD = YEAR/MONTH/DAY/picture.jpg, i.e. /2021/05/10/picture.jpg  
&nbsp;&nbsp;--YM = YEAR/MONTH/picture.jpg, i.e. /2021/05/picture.jpg  
&nbsp;&nbsp;--Y (default) = YEAR, i.e. /2021/picture.jpg  
&nbsp;&nbsp;--NOSORT = All, i.e. Destination/All/picture.jpg

**Source to Work-In-Progress (WIP) file transfer mode:**  
&nbsp;&nbsp;--copy = copy files  
&nbsp;&nbsp;--move = move files (default)

**Operations timer (monitoring, debug):**  
&nbsp;&nbsp;--timerON = display and log operation timings  
&nbsp;&nbsp;--timerOFF = do not display and log operation timings (default)

**Crawl parameters:**  
&nbsp;&nbsp;--crawlON = process Source and its subfolders 3 levels deep (default)  
&nbsp;&nbsp;--crawlOFF = process Source directory only, i.e. Source files at root with no subfolders

## Usage and examples
The command below will search for files at Source Media Location including subfolders (3 levels deep) and **move** files from "upload" to Destination Media Location keeping all files under "archive" with sorting by Year. File renaming will be done using EXIF metadata only. File extension case will be changed to lowercase:  
```/bin/bash /Script-Location/neatly-sorted.sh /Source-Media-Location/upload/ /Destination-Media-Location/archive/```  
&nbsp;&nbsp;It would be equivalent to the command below:  
```/bin/bash /Script-Location/neatly-sorted.sh /Source-Media-Location/upload/ /Destination-Media-Location/archive/ --ext --NoFSAttribute --Y --move --timerOFF --crawlON```  

The command below will search for files in the root of Source Media Location only, i.e. no subfolders, and **copy** files from "upload" to Destination Media Location keeping all files under "archive" with no sorting by Year or Month or Day. File renaming will be done using EXIF metadata only. File extension case will be UnChanged:  
```/bin/bash /Script-Location/neatly-sorted.sh /Source-Media-Location/upload/ /Destination-Media-Location/archive/ --ExT --NoFSAttribute --NOSORT --copy --crawlOFF```  

The command below will search for files in the root of Source Media Location only, i.e. no subfolders, and **copy** files from "upload" to Destination Media Location keeping all files under "archive" with sorting by Year and Month. File renaming will be done using EXIF metadata and File System attributes. File extension case will be changed to UPPERCASE:  
```/bin/bash /Script-Location/neatly-sorted.sh /Source-Media-Location/upload/ /Destination-Media-Location/archive/ --EXT --YM --copy --FSAttribute --crawlOFF```  

The command below will search for files at Source Media Location including subfolders (3 levels deep) and **move** files from "upload" to Destination Media Location keeping all files under "archive/all" with no file sorting, i.e. the result will be a pile of deduplicated files in the "all" folder. File renaming will be done using EXIF metadata only. File extension case will be changed to lowercase:  
```/bin/bash /Script-Location/neatly-sorted.sh /Source-Media-Location/upload/ /Destination-Media-Location/archive/ --NOSORT```  
&nbsp;&nbsp;It would be equivalent to the command below:  
```/bin/bash /Script-Location/neatly-sorted.sh /Source-Media-Location/upload/ /Destination-Media-Location/archive/ --ext --NoFSAttribute --NOSORT --move --timerOFF```  

## Use cases
### Automated file processing with an out-of-support (EOL) NAS QNAP TS-210 or TS-212
#### Preamble
Let's assume there is a NAS QNAP TS-210 where all the media files are stored. There are two main folders: "Media Upload" and "Media Archive", however the media files can be scattered around.  
Since QNAP NAS is a Linux-based platform, we want to utilise its capabilities to process files in an automated way, i.e. once the media files are uploaded by a user or other process to the "Media Upload" folder, an automated processor will move the files to the "Media Archive" folder and sort them out to the appropriate subfolders. We also want to utilise the processor to run occasional jobs manually against some other locations with media files.  
QNAP used to officially support Optware (ipkg) and other 3rd-party package managers via the App Center, however they stopped it sometime in 2016.
On top of limited 3rd-party package manager support, QNAP TS-210/TS-212 is out of support as of 27 March 2021.  
The tutorial below describes how to prepare QNAP TS-210 to run the script in an automated way via task scheduler.

#### QNAP TS-210 prerequisites
The script utilizes exiftool, sha512sum and other packages that are not available in QNAP OS by default. In order to install the necessary tools, a 3rd-party package manager is required. For this use case we're going to use Entware.

**Important!** In order to use Entware, remove all the other package managers like Optware (ipkg), Qnapware, etc. Restart of QNAP NAS is required once all the package managers removed.  
##### Step 1. 3rd-party package manager removal  
```Web GUI > App Center > My Apps > remove obsolete 3rd-party managers like Optware (ipkg) v0.99, Qnapware, etc.```  
##### Step 2. Entware package manager installation  
**Download Entware Qpkg:** ```http://bin.entware.net/other/Entware_1.03std.qpkg or http://bin.entware.net/other/Entware_1.03alt.qpkg```  
**Deploy Entware Qpkg:** ```Web GUI > App Center > Settings > Install Manually > Browse > Select the downloaded Entware_1.03std.qpkg (Entware_1.03alt.qpkg) > Install```  
**Entware Qpkg deployment confirmation:** ```Web GUI > App Center > My Apps > Entware-std (Entware-alt) should be available```  
##### Step 3. QNAP NAS restart  
```Web GUI > Homepage > Click on the dropdown with username > Select "Restart" > Select "Yes" when "Are you sure you want to restart the server"```  
##### Step 4. Opkg confirmation  
Once NAS is restarted, log in to CLI via SSH, "opkg" command should be available. Default Opkg location is /opt/.  
**Command:** ```# opkg --version``` **Expected outcome (sample):** ```opkg version 1bf042dd06751b693a8544d2317e5b969d666b69 (2021-06-13)```  
##### Step 5. Package maintenance  
**Update and upgrade the apps (just in case):**  
```
# opkg list-installed
# opkg update
# opkg upgrade
```
##### Step 6. Requirement installation  
**Deploy the required packages:**  
```
# opkg install perl-image-exiftool
# opkg install coreutils-sha512sum
# opkg install bash
```
##### Step 7. Script deployment  
**Create directory (do not use /opt, it is reserved for package managers and other QNAP-specific stuff):** ```# mkdir /apps && cd /apps```  
**Download the script:** ```# wget https://github.com/ivang-coder/neatly-sorted/archive/refs/heads/master.zip --no-check-certificate```  
**Unpack the archive:** ```# unzip master.zip && mv neatly-sorted-master/ neatly-sorted```  
**Change permissions:** ```# chmod +x /apps/neatly-sorted/neatly-sorted.sh```  
**Script manual run:** ```# /opt/bin/bash /apps/neatly-sorted/neatly-sorted.sh /share/Media\ Upload/ /share/Media\ Archive/ --copy```  

##### Step 8. Script automation
The script run can be event-driven or scheduled. Due to TS-210/TS-212 platform hardware limitations, running a container for the event-driven approach does not sound reasonable. For simplicity the script will be scheduled to run daily at 23:23 via Cron.

**Important!** Due to the way the QNAP firmware updates crontab, do not use "crontab -e" as it will be overwritten on the next reboot. Use "vi /etc/config/crontab" instead.  
**Open crontab for editing:** ```# vi /etc/config/crontab```  
**Add crontab task:** ```23 23 * * * /opt/bin/bash /apps/neatly-sorted/neatly-sorted.sh /share/Media\ Upload/ /share/Media\ Archive/```  
**Apply new crontab:** ```# crontab /etc/config/crontab && /etc/init.d/crond.sh restart```  
**Verify crontab:** ```# crontab -l``` **Expected outcome:** ```23 23 * * * /opt/bin/bash /apps/neatly-sorted/neatly-sorted.sh /share/Media\ Upload/ /share/Media\ Archive/```  

## Credits, tips and source of inspiration  
**Photo processing** https://stackoverflow.com/questions/32062159/how-retrieve-the-creation-date-of-photos-with-a-script  
**Entware** https://github.com/Entware/entware/wiki/Install-on-QNAP-NAS  
**QNAP Crontab** https://wiki.qnap.com/wiki/Add_items_to_crontab  
