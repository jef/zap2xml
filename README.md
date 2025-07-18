# zap2xml

See [zap2xml](https://web.archive.org/web/20200426004001/zap2xml.awardspace.info/) for original Perl script and guidance
for the configuration file.

## How to use

### Node.js

```bash
npm i && npm run dev
```

See below for configuration options.

### Docker

| Tag     | Description             |
| ------- | ----------------------- |
| latest  | Stable zap2xml releases |
| nightly | HEAD zap2xml release    |

#### docker-compose

```yaml
services:
  zap2xml:
    container_name: zap2xml
    image: ghcr.io/jef/zap2xml:latest
    environment:
      LINEUP_ID: USA-lineupId-DEFAULT # Lineup ID (default: USA-lineupId-DEFAULT)
      TIMESPAN: 3 # Timespan in hours (default: 3)
      PREF: # User preferences, comma separated. Can be m, p, and h (default: empty)
      POSTAL_CODE: 30309 # Postal code (default: 30309)
      USER_AGENT: # Custom user agent string (default: Uses random if not specified)
      TZ: America/New_York # Use your timezone
      OUTPUT_FILE: /xmltv/xmltv.xml # Output file name (default: xmltv.xml)
      SLEEP_TIME: 10800 # Sleep time before next run in seconds (default: 10800)
    volumes:
      - ./xmltv:/xmltv
    restart: unless-stopped
```

## Configuration

### Environment variables

| Variable      | Description                                                                                                     | Type    | Default                          |
| ------------- | --------------------------------------------------------------------------------------------------------------- | ------- | -------------------------------- |
| `LINEUP_ID`   | Lineup ID; You can find this at https://tvlistings.gracenote.com/grid-affiliates.html?aid=orbebb                | String  | `USA-lineupId-DEFAULT` (Attenna) |
| `TIMESPAN`    | Either 3 or 6 hours of shows                                                                                    | Integer | 3                                |
| `PREF`        | User Preferences, comma separated list. `m` for showing music, `p` for showing pay-per-view, `h` for showing HD | String  | (empty)                          |
| `POSTAL_CODE` | Postal code of where shows are available.                                                                       | Integer | 30309                            |
| `USER_AGENT`  | Custom user agent string for HTTP requests.                                                                     | String  | Uses random if not specified     |
| `TZ`          | Timezone                                                                                                        | String  | System default                   |
| `SLEEP_TIME`  | Sleep time before next run in seconds (default: 10800, Only used with Docker.)                                  | Integer | 10800                            |
| `OUTPUT_FILE` | Output file name (default: xmltv.xml)                                                                           | String  | xmltv.xml                        |

### Command line arguments

| Argument       | Description                                                                                                     | Type    | Default                          |
| -------------- | --------------------------------------------------------------------------------------------------------------- | ------- | -------------------------------- |
| `--lineupId`   | Lineup ID; You can find this at https://tvlistings.gracenote.com/grid-affiliates.html?aid=orbebb                | String  | `USA-lineupId-DEFAULT` (Attenna) |
| `--timespan`   | Either 3 or 6 hours of shows                                                                                    | Integer | 3                                |
| `--pref`       | User Preferences, comma separated list. `m` for showing music, `p` for showing pay-per-view, `h` for showing HD | String  | (empty)                          |
| `--postalCode` | Postal code of where shows are available.                                                                       | Integer | 30309                            |
| `--userAgent`  | Custom user agent string for HTTP requests.                                                                     | String  | Uses random if not specified     |
| `--timezone`   | Timezone                                                                                                        | String  | System default                   |
| `--outputFile` | Output file name (default: xmltv.xml)                                                                           | String  | xmltv.xml                        |
