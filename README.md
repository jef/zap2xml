# zap2xml

See [zap2xml](https://web.archive.org/web/20200426004001/zap2xml.awardspace.info/) for original Perl script and guidance for the configuration file.

## Docker

| Tag | Description |
|---|---|
| latest | Stable zap2xml releases |
| nightly | HEAD zap2xml release |

### Compose

```yaml
services:
  zap2xml:
    container_name: zap2xml
    image: ghcr.io/jef/zap2xml:latest
    environment:
      OPT_ARGS: >-
        -I -D -C /config/.zap2xmlrc -o /xmltv/xmltv.xml
      SLEEPTIME: 43200 # 12 hours in seconds
      TZ: America/New_York
      USER_AGENT: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" # Optional: customize user agent
    volumes:
      - /path/to/appdata/zap2xml:/config
      - /path/to/appdata/xmltv:/xmltv # nice for mapping other drives to this that may use xmltv.xml
    restart: unless-stopped
```
