# zap2xml

Automate TV guides to XMLTV format. Easy to use, up-to-date. See below for getting started.

I also *somewhat* maintain a version of the original in the [historical-perl branch](https://github.com/jesmannstl/zap2xml/tree/historical-perl) if you're interested in that.

## First Time [Installation in node.js](https://github.com/jesmannstl/zap2xml/wiki/Installation), [How to Run](https://github.com/jesmannstl/zap2xml/wiki/How-to-Run), [Scheduling](https://github.com/jesmannstl/zap2xml/wiki/Scheduling) or [using Docker](https://github.com/jesmannstl/zap2xml/wiki/Using-Docker) see [Wiki](https://github.com/jesmannstl/zap2xml/wiki) for instructions 

### Need help? [Finding a lineup](https://github.com/jesmannstl/zap2xml/wiki/Finding-a-Lineup-ID) or for [Dish and DirecTV lineups](https://github.com/jesmannstl/zap2xml/wiki/US-Dish-Directv-Lineups).  Other help? Drop a line in the [Discussions](https://github.com/jesmannstl/zap2xml/discussions)

# Recent updates

# (2025-08-20)

* Changed default Sort option to the Channel Number in Lineup if available
* Added '--stationid' to sort the previous way by StationID
* Added `--sortname` to sort by the Call Sign

# (2025-08-18)

* Changed URL pull to match output from page when stopped working
* Added Display Name with Channel Number and Call Sign to mirror previous Perl Script
* Added `--nextpvr` option to list Channel Number Call Sign first

# (2025-08-09)

* Restored `<episode-num system="dd_progid">` tag that Plex uses that was missing.
* Fixed Sorting so output is listed by Channel ID (common station/gracenote id) then by date/time.

# (2025-08-07)

* Reordered Program fields to match original Perl script output
* `--postalCode` not required as long as Country and lineup Id correct except Over the Air
* Moved `<date>` above `<category>` to match original Perl output.  Corrected where Movie Release Year is properly displayed.
* Added `<length>` tag.
* Updated channel logo no longer has fixed width so can display in better quality

# (2025-08-06)

* Added Valid Country Codes that can be used
* Added `--mediaportal` option to use `<episode-num system="xmltv_ns">` before others so Media Portal will display Season/Episode properly

# (2025-08-05)

# Changes since previous release

These changes are currently on the [jesmannstl/zap2xml](https://github.com/jesmannstl/zap2xml) fork

* Added Category if available (Movie, Sports, News, Talk, Family etc)
* Added Category "Series" to all programs that did not return a category
* Added additional Season Episode formats for various players
* Added year as Season for programs that only list an episode number like daily cable news
* Added <date> tag to all programs without an aired date normalized to America/New York
* Added xmltv_ns with the date aired as Season YYYY Episode MMYY to Non Movie or Sports with no other Season/Episode like local news so would have the ability to record as Series is most players.
* Added URL to program details from old Perl function.
* Added --appendAsterisk to add * to title on programs that are New and/or Live
* Added <previously-shown /> tag to programs that are not <New> and/or <Live>
* Updated affiliateId after orbebb stopped working

Updated Docker with these changes use APPEND_ASTERISK: TRUE for the --appendAsterisk option



