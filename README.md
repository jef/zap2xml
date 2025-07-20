# zap2xml

Automate TV guides to XMLTV format. Easy to use, up-to-date. See below for getting started.

I also _somewhat_ maintain a version of the original in the [historical-perl branch](https://github.com/jef/zap2xml/tree/historical-perl) if you're interested in that.

## How to use

### Node.js

```bash
npm i && npm run build && node dist/index.js
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

| Variable      | Description                                                                                                     | Default                          |
| ------------- | --------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| `LINEUP_ID`   | Lineup ID; Read more in the [Wiki](https://github.com/jef/zap2xml/wiki/Retrieving-Lineup-ID)                    | `USA-lineupId-DEFAULT` (Attenna) |
| `TIMESPAN`    | Timespan in hours (up to 360 = 15 days, default: 6)                                                             | 6                                |
| `PREF`        | User Preferences, comma separated list. `m` for showing music, `p` for showing pay-per-view, `h` for showing HD | (empty)                          |
| `COUNTRY`     | Country code (default: `USA`)                                                                                   | USA                              |
| `POSTAL_CODE` | Postal code of where shows are available.                                                                       | 30309                            |
| `USER_AGENT`  | Custom user agent string for HTTP requests.                                                                     | Uses random if not specified     |
| `TZ`          | Timezone                                                                                                        | System default                   |
| `SLEEP_TIME`  | Sleep time before next run in seconds (default: 21600, Only used with Docker.)                                  | 21600                            |
| `OUTPUT_FILE` | Output file name (default: xmltv.xml)                                                                           | xmltv.xml                        |

### Command line arguments

| Argument       | Description                                                                                                     | Default                          |
| -------------- | --------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| `--lineupId`   | Lineup ID; Read more in the [Wiki](https://github.com/jef/zap2xml/wiki/Retrieving-Lineup-ID)                    | `USA-lineupId-DEFAULT` (Attenna) |
| `--timespan`   | Timespan in hours (up to 360 = 15 days, default: 6)                                                             | 6                                |
| `--pref`       | User Preferences, comma separated list. `m` for showing music, `p` for showing pay-per-view, `h` for showing HD | (empty)                          |
| `--country`    | Country code (default: `USA`)                                                                                   | USA                              |
| `--postalCode` | Postal code of where shows are available.                                                                       | 30309                            |
| `--userAgent`  | Custom user agent string for HTTP requests.                                                                     | Uses random if not specified     |
| `--timezone`   | Timezone                                                                                                        | System default                   |
| `--outputFile` | Output file name (default: xmltv.xml)                                                                           | xmltv.xml                        |

## Setup and running in intervals

### Running natively

You can run zap2xml natively on your system. It is recommended to use a task scheduler to run it in intervals.

Here are some links to get you started on your machine:

- Linux and Raspberry Pi: https://github.com/jef/zap2xml/wiki/Running-on-Linux-and-Raspberry-Pi
- macOS: https://github.com/jef/zap2xml/wiki/Running-on-macOS
- Windows: https://github.com/jef/zap2xml/wiki/Running-on-Windows

If you want to run zap2xml in intervals, you can use a task scheduler like `cron` on Linux or the Task Scheduler on Windows. Each of the wiki pages above has a section on how to set up zap2xml to run in intervals.

### Running in Docker

You can run zap2xml in a Docker container. The `SLEEP_TIME` environment variable can be used to set the interval between runs. The default is 21600 seconds (6 hours).

## FAQ

### How do I get my Lineup ID?

Visit https://github.com/jef/zap2xml/wiki/Retrieving-Lineup-ID
