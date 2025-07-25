import type { GridApiResponse } from "./tvlistings.js";

export function escapeXml(unsafe: string): string {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

export function formatDate(dateStr: string): string {
  // Input: "2025-07-18T19:00:00Z"
  // Output: "20250718190000 +0000"
  const d = new Date(dateStr);
  const pad = (n: number) => n.toString().padStart(2, "0");
  const YYYY = d.getUTCFullYear();
  const MM = pad(d.getUTCMonth() + 1);
  const DD = pad(d.getUTCDate());
  const hh = pad(d.getUTCHours());
  const mm = pad(d.getUTCMinutes());
  const ss = pad(d.getUTCSeconds());
  return `${YYYY}${MM}${DD}${hh}${mm}${ss} +0000`;
}

export function buildChannelsXml(data: GridApiResponse): string {
  let xml = "";

  for (const channel of data.channels) {
    xml += `  <channel id="${escapeXml(channel.channelId)}">\n`;
    xml += `    <display-name>${escapeXml(channel.callSign)}</display-name>\n`;

    if (channel.affiliateName) {
      xml += `    <display-name>${escapeXml(
        channel.affiliateName,
      )}</display-name>\n`;
    }

    if (channel.channelNo) {
      xml += `    <display-name>${escapeXml(
        channel.channelNo,
      )}</display-name>\n`;
    }

    if (channel.thumbnail) {
      xml += `    <icon src="${escapeXml(
        channel.thumbnail.startsWith("http")
          ? channel.thumbnail
          : "https:" + channel.thumbnail,
      )}" />\n`;
    }

    xml += "  </channel>\n";
  }
  return xml;
}

export function buildProgramsXml(data: GridApiResponse): string {
  let xml = "";

  const matchesPreviouslyShownPattern = (programId: string): boolean => {
    return /^EP|^SH|^\d/.test(programId);
  };

  const convOAD = (originalAirDate: string): string => {
    return originalAirDate.replace(/-/g, "");
  };

  for (const channel of data.channels) {
    for (const event of channel.events) {
      xml += `  <programme start="${formatDate(
        event.startTime,
      )}" stop="${formatDate(event.endTime)}" channel="${escapeXml(
        channel.channelId,
      )}">\n`;

      xml += `    <title>${escapeXml(event.program.title)}</title>\n`;

      if (event.program.episodeTitle) {
        xml += `    <sub-title>${escapeXml(
          event.program.episodeTitle,
        )}</sub-title>\n`;
      }

      if (event.program.shortDesc) {
        xml += `    <desc>${escapeXml(event.program.shortDesc)}</desc>\n`;
      }

      if (event.rating) {
        xml += `    <rating system="MPAA"><value>${escapeXml(
          event.rating,
        )}</value></rating>\n`;
      }

      const isNew = event.flag?.includes("New");
      const isLive = event.flag?.includes("Live");

      if (isNew) {
        xml += `    <new />\n`;
      }
      if (isLive) {
        xml += `    <live />\n`;
      }
      if (event.flag?.includes("Premiere")) {
        xml += `    <premiere />\n`;
      }
      if (event.flag?.includes("Finale")) {
        xml += `    <last-chance />\n`;
      }

      if (
        !isNew && !isLive && event.program.id && matchesPreviouslyShownPattern(event.program.id)
      ) {
        xml += `    <previously-shown`;
        if (event.program.originalAirDate) {
          const date = convOAD(event.program.originalAirDate);
          xml += ` start="${date}000000"`;
        }
        xml += ` />\n`;
      }

      if (event.tags && event.tags.length > 0) {
        if (event.tags.includes("Stereo")) {
          xml += `    <audio type="stereo" />\n`;
        }
        if (event.tags.includes("CC")) {
          xml += `    <subtitles type="teletext" />\n`;
        }
      }

      if (event.program.season && event.program.episode) {
        xml += `    <episode-num system="onscreen">${escapeXml(
          `S${event.program.season.padStart(2, "0")}E${event.program.episode.padStart(2, "0")}`,
        )}</episode-num>\n`;

        xml += `    <episode-num system="common">${escapeXml(
          `S${event.program.season.padStart(2, "0")}E${event.program.episode.padStart(2, "0")}`,
        )}</episode-num>\n`;

        if (/..\d{8}\d{4}/.test(event.program.id)) {
          xml += `    <episode-num system="dd_progid">${escapeXml(event.program.id)}</episode-num>\n`;
        }

        const seasonNum = parseInt(event.program.season, 10);
        const episodeNum = parseInt(event.program.episode, 10);

        // Apply zero-based indexing for xmltv_ns
        if (
          !isNaN(seasonNum) && !isNaN(episodeNum) &&
          seasonNum >= 1 && // Ensure season is at least 1 for zero-based conversion
          episodeNum >= 1   // Ensure episode is at least 1 for zero-based conversion
        ) {
          xml += `    <episode-num system="xmltv_ns">${seasonNum - 1}.${episodeNum - 1}.</episode-num>\n`;
        }
      }

      if (event.thumbnail) {
        const src = event.thumbnail.startsWith("http")
          ? event.thumbnail
          : "https://zap2it.tmsimg.com/assets/" + event.thumbnail + ".jpg";
        xml += `    <icon src="${escapeXml(src)}" />\n`;
      }

      xml += "  </programme>\n";
    }
  }

  return xml;
}

export function buildXmltv(data: GridApiResponse): string {
  console.log("Building XMLTV file");

  let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
  xml +=
    '<tv generator-info-name="jef/zap2xml" generator-info-url="https://github.com/jef/zap2xml">\n';
  xml += buildChannelsXml(data);
  xml += buildProgramsXml(data);
  xml += "</tv>\n";

  return xml;
}
