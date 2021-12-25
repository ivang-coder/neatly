# rEXIFier Readme
rEXIFier is a Shell-written EXIF-based media file processor with sort and deduplication features.

## Overview
The script processes media files (i.e. jpg, jpeg, mp4, mpg and mov) and it uses EXIFTOOL to extract "SubSecCreateDate", "CreateDate" and "Model" metadata. Depending on the selected options, the processed files are moved to "Destination" location with a chosen directory sturucture.

If EXIF attempts fail to read metadata, then the less reliable file attributes get extracted by swithing on the appropriate option.

In case file attribute extaction fails, the source filename gets amended by adding 'unverified' suffix in **"UVRFDXXX"** format, i.e. my-picture-UVRFD000.jpg.  
The unverified files are placed in "Unverified" folder within "Destination" path, i.e. ```/my-destination/Unverified/my-picture-UVRFD000.jpg```

## Filename format
Filename format depends on the chosen folder structure.  
&nbsp;&nbsp;--YMD = /YEAR/MONTH/DAY, i.e. /2021/05/10/picture.jpg  
&nbsp;&nbsp;--YM (default) = /YEAR/MONTH, i.e. /2021/05/picture.jpg  
&nbsp;&nbsp;--Y = /YEAR, i.e. /2021/picture.jpg
&nbsp;&nbsp;--DST = /All, i.e. Destination/All/picture.jpg

The expected filename format: **MODEL-DATE-SECONDS-SUBSECONDS.EXTENSION**  
```Example: ONEPLUSA5000-20200613-125351-184775.jpg```

In case the files are produced by a camera that does not create **"SubSecCreateDate"** field in metadata, the expected filename format: **MODEL-DATE-SECONDS-000000.EXTENSION**  
```Example: E6533-20211205-001132-000000.jpg```

## Prerequisites 
Use the commands below to install exiftool  
**CentOS/RHEL:** ```sudo dnf update && sudo dnf install perl-Image-ExifTool```  
**Ubuntu:** ```sudo apt update && sudo apt upgrade && sudo apt install libimage-exiftool-perl```  
**Mac:** ```brew install exiftool```

## File Processing Overview

### Step 1. Search media files (i.e. jpg, jpeg, mp4, mpg and mov) in Source Directory
**/SourceDirectory/**  
├── file01.jpg  
├── file02.jpeg  
├── file03.mov  
├── file04.jpeg  
└── file05.mov

### Step 2. Create temporary Work-In-Progress (WIP) directory
**/SourceDirectory/WIP-YYYYMMDD-HHmmss**  

### Step 3. Move/copy the found files to temporary Work-In-Progress (WIP) directory
**/SourceDirectory/WIP-YYYYMMDD-HHmmss/**  
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
**/DestinationDirectory/rEXIFier-<YYYYMMDD>.log**

### Step 6. Prepare and move the WIP files to Destination location with the chosen folder structure
**Destination folder structure options**  
&nbsp;&nbsp;--YMD = /YEAR/MONTH/DAY/picture.jpg, i.e. /DestinationDirectory/2021/05/10/picture.jpg  
&nbsp;&nbsp;--YM (default) = /YEAR/MONTH/picture.jpg, i.e. /DestinationDirectory/2021/05/picture.jpg  
&nbsp;&nbsp;--Y = /YEAR, i.e. /DestinationDirectory/2021/picture.jpg
&nbsp;&nbsp;--DST = /All, i.e. Destination/All/picture.jpg

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
└── rEXIFier-20210513.log

## Help menu
**Help:** for more parameters use '/bin/bash rEXIFier.sh <-h|--help>'

**Usage:** '/bin/bash rEXIFier.sh <source-path|.> <destination-path|.> <--Ext|--EXT|--ext> <--FSAttribute|--NoFSAttribute> <--YMD|--YM|--Y|--DST> <--copy|--move>  
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

**Destination folder structure:**  
&nbsp;&nbsp;--YMD = YEAR/MONTH/DAY/picture.jpg, i.e. /2021/05/10/picture.jpg  
&nbsp;&nbsp;--YM (default) = YEAR/MONTH/picture.jpg, i.e. /2021/05/picture.jpg  
&nbsp;&nbsp;--Y = YEAR, i.e. /2021/picture.jpg  
&nbsp;&nbsp;--DST = All, i.e. Destination/All/picture.jpg

**Source to Work-In-Progress (WIP) file transfer mode:**  
&nbsp;&nbsp;--copy = copy files  
&nbsp;&nbsp;--move = move files (default)

## Credits, tips and source of inspiration  
https://stackoverflow.com/questions/32062159/how-retrieve-the-creation-date-of-photos-with-a-script
