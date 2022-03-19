# Description
Neatly is a Shell-written suite for media file organizing, sorting and compressing.
The suite contains the following modules:
- Neatly-Sorted is a Shell-written EXIF-based media file processor with sort and deduplication features.
- Neatly-Compressed is a Shell-written FF-based media file compressor.

## Intro
What if your NAS/JBOD has a pile of photos and videos made with a variety of cameras and dumped to various folders with no or limited structure around sorting, naming convention, etc. Or maybe you just have a folder with a bunch of pictures collected over the years that you'd like to organize a bit better.

Your collection might contain files with name dupliates (i.e. if a camera uses non-date-based filename format, like "DSC_XXXXXX") as well as files with content duplicates (i.e. files that have been renamed by someone for convenience or by a system during file replication where "(01)" suffix is added).

Neatly might be a solution you're looking for. The suite is designed to be executed in manual as well as automated way.

- Neatly-Sorted has been tested and used on various systems, however it is designed with "older systems" in mind, i.e. ARM-based QNAP NAS TS-210.
- Neatly-Compressed being a CPU-intensive module (due to the nature of FF) is designed to be executed primarily on systems with high-performance CPUs, i.e. Intel Core i3/i5/i7/i9, AMD Athlon/Opteron, etc. The project can also run on devices with low-performance CPUs, i.e. Intel Pentium/Celeron-based NAS systems and old PCs. Expect a lot longer encoding time on systems with low-performance CPUs, especially when x265 mode is selected.

## More details
For more info, see below
- Neatly-Sorted Readme: neatly-sorted/README.md or https://github.com/ivang-coder/neatly/blob/main/neatly-sorted/README.md  
- Neatly-Compressed Readme: neatly-compressed/README.md or https://github.com/ivang-coder/neatly/blob/main/neatly-compressed/README.md  

