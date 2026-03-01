# Changelog

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

## (2025-08-06)

* Added Valid Country Codes that can be used
* Added `--mediaportal` option to use `<episode-num system="xmltv_ns">` before others so Media Portal will display Season/Episode properly


## (2025-08-05)

### Changes since previous release

These changes are currently on the [jesmannstl/zap2xml](https://github.com/jesmannstl/zap2xml) fork

* Added Category if available (Movie, Sports, News, Talk, Family etc)
* Added Category "Series" to all programs that did not return a category
* Added additional Season Episode formats for various players
* Added year as Season for programs that only list an episode number like daily cable news
* Added <date> tag to all programs without an aired date normalized to America/New York
* Added xmltv\_ns with the date aired as Season YYYY Episode MMYY to Non Movie or Sports with no other Season/Episode like local news so would have the ability to record as Series is most players.
* Added URL to program details from old Perl function.
* Added --appendAsterisk to add \* to title on programs that are New and/or Live
* Added <previously-shown /> tag to programs that are not <New> and/or <Live>
* Updated affiliateId after orbebb stopped working
* Updated Docker with these changes use APPEND\_ASTERISK: TRUE for the --appendAsterisk option



## [2.2.1](https://github.com/jesmannstl/zap2xml/compare/v2.2.0...v2.2.1) (2025-08-10)


### Bug Fixes

* series and episode info ([6e6fa26](https://github.com/jesmannstl/zap2xml/commit/6e6fa26b75c3b47f9e29f3131daabac0401144c0))

## [2.2.0](https://github.com/jef/zap2xml/compare/v2.1.1...v2.2.0) (2025-07-22)



### Features

* update rating, new, stereo, and cc ([e077f27](https://github.com/jef/zap2xml/commit/e077f2721c78d278db14037776ebdeb4cdee660d))



### Bug Fixes

* add thumbnails for programs ([3ab0370](https://github.com/jef/zap2xml/commit/3ab0370d725c029d64441febb981eeec04f2e1ef))
* args work now ([#54](https://github.com/jef/zap2xml/issues/54)) ([ad7aa8e](https://github.com/jef/zap2xml/commit/ad7aa8e5815b80f6fcb5ae118f29281d481e03d1))
* headendId when OTA, add tests ([1696b15](https://github.com/jef/zap2xml/commit/1696b15712753039d896a6fcbe3145331f9b5b76))



### Continuous Integration

* clean up and conventions ([#52](https://github.com/jef/zap2xml/issues/52)) ([60321a3](https://github.com/jef/zap2xml/commit/60321a37e6410f120be4c8198d39896b8ebea017))



### Documentation

* add FAQ ([4ac37de](https://github.com/jef/zap2xml/commit/4ac37de08e6e4adaeb060465a246558bdc6c2bb7))
* include so links to wiki, update SLEEP\_TIME default ([b5cec7c](https://github.com/jef/zap2xml/commit/b5cec7c951da794041820407860bcee8e0c5b24a))

## [2.1.1](https://github.com/jef/zap2xml/compare/v2.1.0...v2.1.1) (2025-07-19)



### Documentation

* fix defaults ([a655a3e](https://github.com/jef/zap2xml/commit/a655a3e84c2bc7191803d48d581c20b340f3c4e6))
* make ref to historical perl ([2756b07](https://github.com/jef/zap2xml/commit/2756b0766f9e62c85cd8b25178763819cfe8cc51))

## [2.1.0](https://github.com/jef/zap2xml/compare/v2.0.0...v2.1.0) (2025-07-19)



### Features

* support upto 15 days of listings ([ee8c32d](https://github.com/jef/zap2xml/commit/ee8c32dfbb319225b181e8c0d956a56e8473d8cd))

## [2.0.0](https://github.com/jef/zap2xml/compare/v1.0.3...v2.0.0) (2025-07-19)



### ⚠ BREAKING CHANGES

* uses TypeScript, better API usage ([#38](https://github.com/jef/zap2xml/issues/38))

### Features

* add country for customization ([801b3cf](https://github.com/jef/zap2xml/commit/801b3cf725a077c1f6136f1100c751d833d654f1))
* make user agent configurable ([9aae5cd](https://github.com/jef/zap2xml/commit/9aae5cd1e5575e12d56cf04bb550c20fc63e636d))



### Miscellaneous

* remove node-fetch, fix lint issues ([4c22bfa](https://github.com/jef/zap2xml/commit/4c22bfa9e22273893622f476b33319901bd1c810))
* update configs, signify version bump ([5e00aa2](https://github.com/jef/zap2xml/commit/5e00aa2dfc642d3c8a33fb2254178986bedd87a8))



### Continuous Integration

* add release-type ([f8549b0](https://github.com/jef/zap2xml/commit/f8549b00b63aefe3593188ef16e86bf0b06a00dc))
* fix closed quote ([#34](https://github.com/jef/zap2xml/issues/34)) ([81ae3ac](https://github.com/jef/zap2xml/commit/81ae3ac3f6a94c67f8fb908f75e4c120e8fbe08f))
* fix indent ([6fa9aee](https://github.com/jef/zap2xml/commit/6fa9aee5ee907e5b433cfb84c5b881c58247b7eb))
* fix release ([3e16649](https://github.com/jef/zap2xml/commit/3e166499360470c611a1d09d374cfe8cfd9db4e5))
* fixes nightly release ([2e32c0d](https://github.com/jef/zap2xml/commit/2e32c0d78e5b8f3bd2a7205b4706b615178432cb))
* use v3, update changelog-types ([19b49a0](https://github.com/jef/zap2xml/commit/19b49a0c4fb9d0f0a6e841055c888d558652dc86))



### Documentation

* add build for easier arg additions ([dada5b3](https://github.com/jef/zap2xml/commit/dada5b3154a2cb0ad7c4f3dcf2a71dcfc34c3705))
* better descriptions ([bc74ac6](https://github.com/jef/zap2xml/commit/bc74ac6f06664ce8df8db14e5d6a01c46c51b4be)), closes [#8](https://github.com/jef/zap2xml/issues/8)
* update lineup id info ([206be57](https://github.com/jef/zap2xml/commit/206be57e8fc44ca33de683dd8776a9e164ef404f))



### Refactoring

* uses TypeScript, better API usage ([#38](https://github.com/jef/zap2xml/issues/38)) ([fb28b7d](https://github.com/jef/zap2xml/commit/fb28b7d6e6b7316e76637005cc38bee1a44ec8b0))

### [1.0.3](https://www.github.com/jef/zap2xml/compare/v1.0.2...v1.0.3) (2025-07-15)



### Bug Fixes

* command line errors ([#11](https://www.github.com/jef/zap2xml/issues/11)) ([ac2fd43](https://www.github.com/jef/zap2xml/commit/ac2fd43215f474b051cfeb94d0845752aa4c5ced))
* update AffiliateID param ([2809b27](https://www.github.com/jef/zap2xml/commit/2809b27975c44717cd0c6f40bde6283dcb921a96))

### [1.0.2](https://www.github.com/jef/zap2xml/compare/v1.0.1...v1.0.2) (2025-04-02)



### Bug Fixes

* gracenote.com local URLs throughout code ([#17](https://www.github.com/jef/zap2xml/issues/17)) ([ec67964](https://www.github.com/jef/zap2xml/commit/ec67964282b3b1a391b7fe2190181c562701b89b))

### [1.0.1](https://www.github.com/jef/zap2xml/compare/v1.0.0...v1.0.1) (2025-04-02)



### Bug Fixes

* update zap2it URL ([#13](https://www.github.com/jef/zap2xml/issues/13)) ([a41eab9](https://www.github.com/jef/zap2xml/commit/a41eab9f222f1625c4e20a29068bf81562a38829))

## 1.0.0 (2021-04-24)



### Features

* update docker and pipeline ([e31071b](https://www.github.com/jef/zap2xml/commit/e31071bda880b57cabc174591e6b92a639735436))
