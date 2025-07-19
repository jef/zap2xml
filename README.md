# zap2xml

See [zap2xml](https://web.archive.org/web/20200426004001/zap2xml.awardspace.info/) for original Perl script and guidance for the configuration file.

## Docker

### docker-compose (recommended)

```yaml
services:
  zap2xml:
    container_name: zap2xml
    image: ghcr.io/jef/zap2xml:latest
    environment:
      OPT_ARGS: >-
        -I -D -C /config/.zap2xmlrc -o /xmltv/xmltv.xml
      TZ: America/New_York # Consider using your timezone
    volumes:
      - /path/to/zap2xml/config:/config
      - /path/to/xmltv:/xmltv # nice for mapping other drives to this that may use xmltv.xml
    restart: unless-stopped
```

## Configuration

### Optional environment variables

| Variable     | Description                                                                        | Default                                                                                                           |
| ------------ | ---------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `USER_AGENT` | Custom user agent string for HTTP requests.                                        | `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36` |
| `SLEEPTIME`  | Number of seconds to sleep between runs (useful for scheduling in Docker or cron). | `43200`                                                                                                           |
| `TZ`         | Timezone for program times (affects output XML and Perl's time calculations).      | System default                                                                                                    |

### Optional run configurations

| Option           | Type      | Default     | Description                                            | Config File                   | Command Line |
| ---------------- | --------- | ----------- | ------------------------------------------------------ | ----------------------------- | ------------ |
| `start`          | Integer   | `0`         | Number of days to offset from today for the start date | `start=1`                     | `-s`         |
| `days`           | Integer   | `7`         | Number of days of program data to fetch                | `days=14`                     | `-d`         |
| `retries`        | Integer   | `3`         | Number of connection retries before failure (max 20)   | `retries=5`                   | `-r`         |
| `user`           | String    | (empty)     | Username/email for Zap2it account                      | `user=myemail@example.com`    | `-u`         |
| `pass`           | String    | (empty)     | Password for Zap2it account                            | `pass=mypassword`             | `-p`         |
| `cache`          | Directory | `cache`     | Directory to store cached data files                   | `cache=/config/cache`         | `-c`         |
| `ncdays`         | Integer   | `0`         | Number of days from the end to not cache               | `ncdays=2`                    | `-n`         |
| `ncsdays`        | Integer   | `0`         | Number of days from the start to not cache             | `ncsdays=1`                   | `-N`         |
| `ncmday`         | Integer   | `-1`        | Specific day number to not cache (1-based)             | `ncmday=3`                    | `-B`         |
| `outfile`        | File path | `xmltv.xml` | Output XML file path                                   | `outfile=/xmltv/xmltv.xml`    | `-o`         |
| `outformat`      | String    | `xmltv`     | Output format (xmltv/xtvd)                             | `outformat=xtvd`              | `-x`         |
| `lang`           | String    | `en`        | Language code for program data                         | `lang=es`                     | `-l`         |
| `icon`           | Directory | (disabled)  | Directory to store channel icons                       | `icon=/config/icons`          | `-i`         |
| `trailer`        | Directory | (disabled)  | Directory to store movie trailers                      | `trailer=/config/trailers`    | `-t`         |
| `proxy`          | URL       | (none)      | HTTP proxy server URL                                  | `proxy=http://localhost:8080` | `-P`         |
| `lineuptype`     | String    | (none)      | Type of lineup (XTVD only)                             | `lineuptype=Cable`            | -            |
| `lineupname`     | String    | (none)      | Name of the lineup (XTVD only)                         | `lineupname=My Provider`      | -            |
| `lineuplocation` | String    | (none)      | Location of the lineup (XTVD only)                     | `lineuplocation=New York, NY` | -            |
| `lineupid`       | String    | (none)      | Lineup ID for TV Guide                                 | `lineupid=X:80000`            | `-Y`         |
| `postalcode`     | String    | (none)      | Postal code for TV Guide                               | `postalcode=01010`            | `-Z`         |
| `shiftMinutes`   | Integer   | `0`         | Offset program times by minutes                        | -                             | `-m`         |
| `sleeptime`      | Integer   | `0`         | Sleep between requests (seconds)                       | -                             | `-S`         |
| `allChan`        | Boolean   | `false`     | Output all channels (not just favorites)               | -                             | `-a`         |
| `outputXTVD`     | Boolean   | `false`     | Force XTVD output format                               | -                             | `-x`         |
| `includeDetails` | Boolean   | `false`     | Include program details (extra requests)               | -                             | `-D`         |
| `includeIcons`   | Boolean   | `false`     | Include program icons (extra requests)                 | -                             | `-I`         |
| `retainOrder`    | Boolean   | `false`     | Retain website channel order                           | -                             | `-b`         |
| `quiet`          | Boolean   | `false`     | Quiet mode (no status output)                          | -                             | `-q`         |
| `wait`           | Boolean   | `false`     | Wait on exit (require keypress)                        | -                             | `-w`         |
| `hexEncode`      | Boolean   | `false`     | Hex encode HTML entities                               | -                             | `-e`         |
| `utf8`           | Boolean   | `false`     | UTF-8 encoding (default: ISO-8859-1)                   | -                             | `-U`         |
| `liveTag`        | Boolean   | `false`     | Output `<live />` tag                                  | -                             | `-L`         |
| `noTBA`          | Boolean   | `false`     | Don't cache files with "TBA" titles                    | -                             | `-T`         |
| `channelFirst`   | Boolean   | `false`     | Output channel names first                             | -                             | `-F`         |
| `oldStyle`       | Boolean   | `false`     | Use old tv_grab_na style channel IDs                   | -                             | `-O`         |
| `appendFlags`    | String    | (none)      | Append flags to program titles                         | -                             | `-A`         |
| `copyYear`       | Boolean   | `false`     | Copy movie_year to sub-title tags                      | -                             | `-M`         |
| `addSeries`      | Boolean   | `false`     | Add "series" category to non-movies                    | -                             | `-j`         |
| `includeXMLTV`   | File      | (none)      | Include XMLTV file in output                           | -                             | `-J`         |
| `useTVGuide`     | Boolean   | `false`     | Use tvguide.com instead of gracenote.com               | -                             | `-z`         |

### Notes

- Configuration file values can be overridden by command line options
- The configuration file supports comments (lines starting with `#`)
- Empty lines are ignored
- Values are trimmed of leading/trailing whitespace
- Boolean options (like `outformat=xtvd`) are case-insensitive
