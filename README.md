# narrative-gps
An attempt to read the GPS Snapshot files from the Narrative Camera.

*IMPORTANT: This project is NOT completed and currently does NOT work as it is.*

## .snap files GPS Snapshot file format

The Narrative Camera uses the Cellguide ACLYS GPS Frontend (ref: [CellGuide site](http://www.cell-guide.com) and [Narrative Clip Teardown](https://learn.adafruit.com/narrative-clip-teardown/inside-the-narrative-clip)) and takes a 512ms GPS snapshot every 30 seconds.

The .snap files are raw 1-bit I/Q GPS data, and have a size of 131,072 bytes, with a sampling frequency of 1024 Mhz (ref: [Off-Board Positioning Using an Efficient GNSS SNAP Processing Algorithm](http://www.cell-guide.com/images/stories/pdf/off-board%20positioning%20using%20an%20efficient%20gnss%20snap%20processing%20algorithm_ion%202010.pdf) and the help of the `aclys_snap` program on the Narrative indicates a default length of 512ms).
As a result, the .snap files contains 524,288 I/Q samples.

### Sample data

The data directory contains a few samples, the times are in UTC.

### Copyright

This repository includes work from the SoftGNSS v3.0 project, Copyright (C) Darius Plausinaitis.
