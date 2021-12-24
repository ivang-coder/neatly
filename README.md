# rEXIFier Readme
rEXIFier is a Shell-written EXIF-based media file processor with sort and deduplication features

The script processes media files (i.e. jpg, jpeg, mp4, mpg and mov) and it uses EXIFTOOL to extract "SubSecCreateDate", "CreateDate" and "Model" metadata. Depending on the selected options, the processed files are moved to "Destination" with a chosen directory sturucture.

If EXIF attempts fail, then the less reliable file attributes get extracted. 
In case the file attribute extaction fails, the source filename gets amended by adding 'unverified' suffix in "UVRFDXXX" format, i.e. my-picture-UVRFD000.jpg. The unverified files are placed in "Unverified" folder within "Destination" path, i.e. /my-destination/Unverified/my-picture-UVRFD000.jpg

## Prerequisites 
Use the commands below to install exiftool
&nbsp;&nbsp;**CentOS/RHEL:** sudo dnf update && sudo dnf install perl-Image-ExifTool
&nbsp;&nbsp;**Ubuntu:** sudo apt update && sudo apt upgrade && sudo apt install libimage-exiftool-perl
&nbsp;&nbsp;**Mac:** brew install exiftool\n"

## File Processing Overview

### Step 1. Search media files (i.e. jpg, jpeg, mp4, mpg and mov) in Source Directory
**/SourceDirectory/**
&nbsp;&nbsp;file01.jpg
&nbsp;&nbsp;file02.jpeg
&nbsp;&nbsp;file03.mov
&nbsp;&nbsp;file04.jpeg
&nbsp;&nbsp;file05.mov

### Step 2. Create temporary Work-In-Progress (WIP) directory
**/SourceDirectory/WIP-YYYYMMDD-HHmmss**

### Step 3. Move the found files to temporary Work-In-Progress (WIP) directory

**/SourceDirectory/WIP-YYYYMMDD-HHmmss/**
&nbsp;&nbsp;file01.jpg
&nbsp;&nbsp;file02.jpeg
&nbsp;&nbsp;file03.mov
&nbsp;&nbsp;file04.jpeg
&nbsp;&nbsp;file05.mov

### Step 4. Create directories at Destination location
**/DestinationDirectory/Duplicates**
&nbsp;&nbsp;directory for duplicate files where "DUPXXX" suffix is added to the filenames, i.e. /DestinationDirectory/Duplicates/MODEL-DATE-SECONDS-DUP000.jpg.
**/DestinationDirectory/Unverified**
&nbsp;&nbsp;directory for the files for which metadata could not be retrieved where the filenames get amended by adding 'unverified' suffix in "UVRFDXXX" format, i.e. /DestinationDirectory/Unverified/my-picture-UVRFD000.jpg.

### Step 5. Prepare (create) log file
**/DestinationDirectory/rEXIFier-<YYYYMMDD>.log**

### Step 6. Prepare and move the WIP files to Destination location with the chosed folder structure
**Destination folder structure options**
--YMD = /YEAR/MONTH/DAY/picture.jpg, i.e. /DestinationDirectory/2021/05/10/picture.jpg
--YM = /YEAR/MONTH/picture.jpg, i.e. /DestinationDirectory/2021/05/picture.jpg
--Y = /YEAR, i.e. /DestinationDirectory/2021/picture.jpg

An example with YM (/YEAR/MONTH/) folder structure
/DestinationDirectory/
&nbsp;&nbsp;2020/
&nbsp;&nbsp;&nbsp;05/
&nbsp;&nbsp;&nbsp;&nbsp;file03.mov
&nbsp;&nbsp;2021/
&nbsp;&nbsp;&nbsp;11/
&nbsp;&nbsp;&nbsp;&nbsp;file04.jpeg
&nbsp;&nbsp;Duplicates/
&nbsp;&nbsp;&nbsp;E6533-20211205-001132-000000-DUP000.jpg
&nbsp;&nbsp;&nbsp;E6533-20211205-001132-000000-DUP001.jpg
&nbsp;&nbsp;&nbsp;ONEPLUSA5000-20200613-125351-184775-DUP000.jpg
&nbsp;&nbsp;&nbsp;ONEPLUSA5000-20200613-125351-184775-DUP001.jpg
&nbsp;&nbsp;Duplicates/
&nbsp;&nbsp;&nbsp;my_image-UVRFD000.jpg
&nbsp;&nbsp;&nbsp;my_image-UVRFD001.jpg
&nbsp;&nbsp;rEXIFier-20210513.log

## Help menu
**Help:** for more parameters use '/bin/bash rEXIFier.sh <-h|--help>'

**Usage:** '/bin/bash rEXIFier.sh <source-path|.> <destination-path|.> <--Ext|--EXT|--ext> <--FSAttribute|--NoFSAttribute> <--YMD|--YM|--Y>

**Source** absolute path is required with leading '/'. Alternatively use '.' for current directory.
&nbsp;&nbsp;Example: '/home/username/pictures/'

**Destination** absolute path is required with leading '/'. Alternatively, use '.' for current directory.
&nbsp;&nbsp;Example: '/mystorage/sorted-pictures/'

**Extension case switch options:**
&nbsp;&nbsp;--ExT = unchanged, i.e. JPEG > JPEG, jpeg > jpeg
&nbsp;&nbsp;--EXT = uppercase, i.e. jpeg > JPEG
&nbsp;&nbsp;--ext = lowercase (recommended), i.e. JPEG > jpeg

**File system attribute extraction** is somewhat unreliable and can be used as the last resort.
&nbsp;&nbsp;--FSAttribute, can cause conflicts and affect file sorting
&nbsp;&nbsp;--NoFSAttribute (default) is the recommended option

**Destination folder structure:**
&nbsp;&nbsp;--YMD = YEAR/MONTH/DAY/picture.jpg, i.e. /2021/05/10/picture.jpg
&nbsp;&nbsp;--YM = YEAR/MONTH/picture.jpg, i.e. /2021/05/picture.jpg
&nbsp;&nbsp;--Y = YEAR, i.e. /2021/picture.jpg

## Credits, tips and source of inspiration
https://stackoverflow.com/questions/32062159/how-retrieve-the-creation-date-of-photos-with-a-script
