# Neatly-Compressed Readme
Neatly-Compressed is a Shell-written FFMpeg-based media file compressor.

## Intro
What if your NAS/JBOD has a pile of videos made with a variety of cameras where the files are inefficiently compressed resulting in bloated file size.

Your collection of video files might be spread across a tiered folder structure mixed with raw video as well as efficiently compressed (hevc, heic) and inefficiently compressed video.

Neatly-Compressed might be a solution you're looking for. The suite is designed to be executed in manual as well as automated way.

- Neatly-Compressed being a CPU-intensive module (due to the nature of FFMpeg) is designed to be executed primarily on systems with high-performance CPUs, i.e. Intel Core i3/i5/i7/i9, AMD Athlon/Opteron, etc. The project can also run on devices with low-performance CPUs, i.e. Intel Pentium/Celeron-based NAS systems and old PCs. Expect a lot longer encoding time on systems with low-performance CPUs, especially when x265 mode is selected.

## Overview  
Neatly-Compressed uses a video-quality-driven approach taking into account the desired file size. Neatly-Compressed utilizes FFMpeg, however unlike FFMpeg that has single-pass (quality-driven by Constant Rate Factor "CRF") and double-pass (file-size-driven) modes, Neatly-Compressed uses a hybrid mode with 3 main parameters: desired quality, acceptable quality, and desired file size in percent.  

Neatly-Compressed also uses a technique to identify relative bit rate-to-size ratio, it's called Control Spot, that triggers the encoding process if the bit rate is higher than selected threshold. The Control Spot is a universal metric that takes into account video resolution and FPS (Frames Per Second), i.e. 1080p (30/60/++ fps), 720p (30/60/++ fps), etc.  
The Control Spot is an arbitrary frame the size of 100 px x 100 px (10000 pixels total). The Contol Spot is selected with the size that fits virtually all video resolutions, starting with 320 x 240 px and up to 4K. It is also sufficient to support relatively simple integer-based calculations (BASH and other shells have limitations when it comes to mathematical operations with floating numbers).  
This is how it's calculated:  
```
"Source File Bit Rate" = 12,345,678 bits per second  
"Source File Frame Rate" = 25/29/30/60+ frames per second  
"Control Spot" = 100 x 100 = 10000 pixels  
"Pixels Per Frame" = "Source File Width" x "Source File Height" pixels  
"Bit Rate Per Frame" = "Source File Bit Rate" / "Source File Frame Rate" bits per frame  
```
**"Control Spot Weight In Bits" = "Control Spot" x "Bit Rate Per Frame" / "Pixels Per Frame"**  
The value of **1650** is selected as Control Spot, i.e. the threshold equivalent to a video file with bit rate of 10,264,320 bps (10.264 Mbps), resolution of 1920x1080 pixels and 30 fps.  
### Setting file size target in percent (%), fstarget=<integer>
Neatly-Compressed can work in "file" (single file processing) and "directory" (all files in the specified directory and 3-level deep if selected) modes.  
"Source" and "Destination" directory need to be selected if the encoded files need to be placed in a separate (Destination) folder. Alternatively, only "Source" directory can be selected where the encoded files will be placed at the same location as the source files.  

## Compatibility  
**BASH:** v4+  
**CentOS/RHEL:** v7, v8  
**Ubuntu:** 18.04 LTS, 20.04.3 LTS  
**QNAP (Entware):** 4.2.6, opkg version 1bf042dd06751b693a8544d2317e5b969d666b69 (2021-06-13)  
**WSL (Windows Linux Subsystem):** Ubuntu (18.04 LTS, 20.04.3 LTS)  

## Help menu 
**Usage:** #/bin/bash /neatly/neatly-compressed/neatly-compressed.sh <source-path|.> <destination-path|.> <--x264|--x265> <--medium|--slow|--slower|--veryslow> <--copy|--move> <--timerON|--timerOFF> <--crawlON|--crawlOFF> <--fstarget=<integer>> <--desiredCRF=<integer>> <--borderCRF=<integer>> <--crffileON|--crffileOFF>  
&nbsp;&nbsp;&nbsp;&nbsp;Mandatory parameters: source-path  
**Help: for more parameters use** ```#/bin/bash neatly-compressed.sh <-h|--help>```  
**Source absolute path is required with leading '/'. Alternatively use '.' for current directory.** ```Example: '/home/username/videos/'; '/home/username/videos/VID_20220226_135901.mp4'```  
***Destination absolute path can be ommited or specified with leading '/'. Alternatively, use '.' for current directory.** ```Example: '/mystorage/sorted-videos/'```  
**FFMpeg encoder switch:** ```--x264 = encoding with x264 using libx264 and, --x265 = encoding with x265 using libx265 (default)```
- For libx264, the Constant Rate Factor (CRF) of choice is 18 visual 'lossless'. 
- For libx265, the Constant Rate Factor (CRF) of choice is 21 visual 'lossless'.  

**FFMpeg preset switch:**  
```
--medium = (default) the encoding time is about 350%%, i.e. it takes about 4 seconds with x265 to encode 1 second of the video  
--slow = going from medium to slow, the time needed increases by about 40%,  
--slower = going from medium to slower, the time needed increases by about 140%,  
--veryslow = going from medium to veryslow, the time needed increases by about 280%, with only minimal improvements over slower in terms of quality  
```
**Source to Work-In-Progress (WIP) file transfer mode:**  
```
--copy = copy files (default),
--move = move files
```  
**Operations timer (monitoring, debug):**  
```
--timerON = display and log operation timings,
--timerOFF = do not display and log operation timings (default)
```  
**Crawl parameters:**  
```
--crawlON = process Source and its subfolders 3 levels deep (default),
--crawlOFF = process Source directory only, i.e. Source files at root with no subfolders
```  
**File size target in percent:** --fstarget=<integer> where <integer> is >10..50<, 25 is default, for example, with --fstarget=50 and source file of 80 MB, the target file size is 40 MB  
**Desired CRF:** --desiredCRF=<integer> where <integer> is >0..50<, 21 is default,  Note: Desired CRF represents the best quality, --desiredCRF should be less or equal to --borderCRF  
**Border CRF:** --borderCRF=<integer> where <integer> is >0..50<, 28 is default,  Note: Border CRF represents the acceptable quality, --borderCRF should be greater or equal to --desiredCRF  
**CRF file:** --crffileON = create informational file.crf<integer> file indicating the quality level (CRF) of the encoded file (default),  --crffileOFF = do not create informational filename.crf<integer> file indicating the quality level (CRF) of the encoded file (default)  

## Usage and examples
### Directory mode
The command below will search for video files at Source Location including subfolders (3 levels deep) and evaluate them against Control Spot threshold. The files get encoded using x265 (default) or x264 codec suite with best effort to achieve highest quality of CRF 21 and to fit the size to the selected value 25% (default). If the encoded file cannot fit the selected size, then another round of encoding with adjusted CRF is performed with a cut-off CRF of 28, i.e. the "worst" border quality. The encoded files then **moved** to Destination Location and the Source files get **moved** to hidden "Originals" folder in the Source Location. For quality assurance and review purposes, a .crf<integer> file created in Destination Location with <integer> matching the CRF value of the encoded file.  
```/bin/bash /neatly/neatly-compressed/neatly-compressed.sh /source/ /destination/```  
&nbsp;&nbsp;It would be equivalent to the command below:  
```/bin/bash /neatly/neatly-compressed/neatly-compressed.sh /source/ /destination/ --x265 --medium --move --timerOFF --crawlON --fstarget=25 --desiredCRF=21 --borderCRF=28 --crffileON```  

The command below will search for video files at Source Location including subfolders (3 levels deep) and evaluate them against Control Spot threshold. The files get encoded using x265 (default) or x264 codec suite with best effort to achieve highest quality of CRF 21 and to fit the size to the selected value 25% (default). If the encoded file cannot fit the selected size, then another round of encoding with adjusted CRF is performed with a cut-off CRF of 28, i.e. the "worst" border quality. The encoded files then **moved** to Destination Location and the Source files get **moved** to hidden "Originals" folder in the Source Location. For quality assurance and review purposes, a .crf<integer> file created in Destination Location with <integer> matching the CRF value of the encoded file. Along with regular output, the log file is populated with execution timings of each block of the process.
```/bin/bash /neatly/neatly-compressed/neatly-compressed.sh /source/ /destination/ --timerON --crffileON```  

**Graceful termination:** In order to stop Neatly-Compressed gracefully when running in "directory", a "stop" file needs to be created in the root of Neatly-Compressed. Upon locating "stop" file, the script will finish processing the current file and then exit without proceeding to the other files in the directory.  
```touch /neatly/neatly-compressed/stop```  
**Note:** the "stop" file needs to be removed prior to running Neatly-Compressed, otherwise only the first found file will be processed and then the script will gracefully exit.
```rm /neatly/neatly-compressed/stop```  

### Single file mode
The command below will process the selected video file at Source Location and evaluate it against Control Spot threshold. The file gets encoded using x265 (default) or x264 codec suite with best effort to achieve highest quality of CRF 21 and to fit the size to the selected value 25% (default). If the encoded file cannot fit the selected size, then another round of encoding with adjusted CRF is performed with a cut-off CRF of 28, i.e. the "worst" border quality. The encoded file then **moved** to Destination Location and the Source file get **moved** to hidden "Originals" folder in the Source Location. For quality assurance and review purposes, a .crf<integer> file created in Destination Location with <integer> matching the CRF value of the encoded file.  
```/bin/bash /neatly/neatly-compressed/neatly-compressed.sh /source/VID_20220226_135901.mp4 /destination/```  
&nbsp;&nbsp;It would be equivalent to the command below:  
```/bin/bash /neatly/neatly-compressed/neatly-compressed.sh /source/VID_20220226_135901.mp4 /destination/ --x265 --medium --move --timerOFF --crawlON --fstarget=25 --desiredCRF=21 --borderCRF=28 --crffileON```  

## References, credits, tips and source of inspiration  
**FFMpeg H.264 Video Encoding Guide** https://trac.ffmpeg.org/wiki/Encode/H.264"
**FFMpeg H.265/HEVC Video Encoding Guide** https://trac.ffmpeg.org/wiki/Encode/H.265"
