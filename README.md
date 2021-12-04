# rexifier
rEXIFier is a Shell-written EXIF-based media file processor with sort, dedup and other features

# This script is used to sort media files (jpg, jpeg, mp4, mpg and mov ). 
#  It uses EXIFTOOL to extract "SubSecCreateDate", "CreateDate" and 
#  "Model" metadata. If EXIF attempts fail, then less reliable file attributes get
#  extracted as the last resort. In case the file attribute 
#  extaction fails, the source filename gets amended by adding
#  "UNVERIFIED-" prefix
#
# File Processing Overview
#
# Step 1. Search media files in Source Directory and 
# SourceDirectory/
#   file01.jpg
#   file02.jpeg
#   file03.mov
#   file04.jpeg
#   file05.mov
#
# Step 2. Create temporary Work-In-Progress (WIP) directory
# SourceDirectory/WIP-YYYYMMDD-HHmmss
#
# Step 3. Move the found files to temporary Work-In-Progress (WIP) directory
#
# SourceDirectory/WIP-YYYYMMDD-HHmmss
#   file01.jpg
#   file02.jpeg
#   file03.mov
#   file04.jpeg
#   file05.mov
#
# Step 4. Create directories:
#         FileUnverified directory for files with corrupted/unreadable metadata
#         FileNameDuplicates directory for by-name duplicates between Work-In-Progress and Destination Directory, i.e. 
#           files with matching names and non-matching content
#         FileContentDuplicates directory for by-content duplicates in the Destination Directory, i.e. 
#           files with non-matching names and matching content
#
# DestinationDirectory/FileUnverified
# DestinationDirectory/FileNameDuplicates
# DestinationDirectory/FileContentDuplicates
#
# Step 5. Prepare and move the WIP files to DestinationDirectory with YYYY/MM/DD structure
#
# DestinationDirectory/
#   FileUnverified/
#     file01.jpg
#   FileNameDuplicates/
#     file02.jpeg
#   FileContentDuplicates/
#   2007/
#       05/
#         01/
#           file03.mov
#   2009/
#       12/
#         29/
#           file04.jpeg
#   2015/
#       01/
#         17/
#           file05.mov
#
# Credits for tips and inspiration
# https://stackoverflow.com/questions/32062159/how-retrieve-the-creation-date-of-photos-with-a-script