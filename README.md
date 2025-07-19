# zap2xml

See [zap2xml](https://web.archive.org/web/20200426004001/zap2xml.awardspace.info/) for original Perl script and guidance
for the configuration file.

## How to use

### Retrieving your Lineup ID

Visit the [Retrieving Lineup ID](https://github.com/jef/zap2xml/wiki/Retrieving-Lineup-ID) in the Wiki.

### Node.js

```bash
npm i && npm run dev
```

See [Command line arguments](#command-line-arguments) for configuration options.

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
      OUTPUT_FILE: /xmltv/xmltv.xml
    volumes:
      - ./xmltv:/xmltv
    restart: unless-stopped
```

See [Environment variables](#environment-variables) for configuration options.

## Configuration

### Environment variables

| Variable      | Description                                                                                                     | Type    | Default                          |
| ------------- | --------------------------------------------------------------------------------------------------------------- | ------- | -------------------------------- |
| `LINEUP_ID`   | Lineup ID; Read more in the [Wiki](https://github.com/jef/zap2xml/wiki/Retrieving-Lineup-ID)                    | String  | `USA-lineupId-DEFAULT` (Attenna) |
| `TIMESPAN`    | Either 3 or 6 hours of shows                                                                                    | Integer | 3                                |
| `PREF`        | User Preferences, comma separated list. `m` for showing music, `p` for showing pay-per-view, `h` for showing HD | String  | (empty)                          |
| `COUNTRY`     | Country code (default: `US`)                                                                                    | String  | US                               |
| `POSTAL_CODE` | Postal code of where shows are available.                                                                       | Integer | 30309                            |
| `USER_AGENT`  | Custom user agent string for HTTP requests.                                                                     | String  | Uses random if not specified     |
| `TZ`          | Timezone                                                                                                        | String  | System default                   |
| `SLEEP_TIME`  | Sleep time before next run in seconds (default: 10800, Only used with Docker.)                                  | Integer | 10800                            |
| `OUTPUT_FILE` | Output file name (default: xmltv.xml)                                                                           | String  | xmltv.xml                        |

### Command line arguments

| Argument       | Description                                                                                                     | Type    | Default                          |
| -------------- | --------------------------------------------------------------------------------------------------------------- | ------- | -------------------------------- |
| `--lineupId`   | Lineup ID; Read more in the [Wiki](https://github.com/jef/zap2xml/wiki/Retrieving-Lineup-ID)                    | String  | `USA-lineupId-DEFAULT` (Attenna) |
| `--timespan`   | Either 3 or 6 hours of shows                                                                                    | Integer | 3                                |
| `--pref`       | User Preferences, comma separated list. `m` for showing music, `p` for showing pay-per-view, `h` for showing HD | String  | (empty)                          |
| `--country`    | Country code (default: `US`)                                                                                    | String  | US                               |
| `--postalCode` | Postal code of where shows are available.                                                                       | Integer | 30309                            |
| `--userAgent`  | Custom user agent string for HTTP requests.                                                                     | String  | Uses random if not specified     |
| `--timezone`   | Timezone                                                                                                        | String  | System default                   |
| `--outputFile` | Output file name (default: xmltv.xml)                                                                           | String  | xmltv.xml                        |
