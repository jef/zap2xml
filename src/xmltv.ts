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

export function buildProgrammesXml(data: GridApiResponse): string {
  let xml = "";

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
        xml += `    <rating><value>${escapeXml(
          event.rating,
        )}</value></rating>\n`;
      }

      if (event.flag && event.flag.length > 0) {
        for (const flag of event.flag) {
          xml += `    <category>${escapeXml(flag)}</category>\n`;
        }
      }

      if (event.tags && event.tags.length > 0) {
        for (const tag of event.tags) {
          xml += `    <category>${escapeXml(tag)}</category>\n`;
        }
      }

      if (event.program.season) {
        xml += `    <episode-num system="season">${escapeXml(
          event.program.season,
        )}</episode-num>\n`;
      }

      if (event.program.episode) {
        xml += `    <episode-num system="episode">${escapeXml(
          event.program.episode,
        )}</episode-num>\n`;
      }

      if (event.program.seriesId) {
        xml += `    <episode-num system="series">${escapeXml(
          event.program.seriesId,
        )}</episode-num>\n`;
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

  let xml =
    '<?xml version="1.0" encoding="UTF-8"?>\n<tv generator-info-name="zap2it-grid">\n';
  xml += buildChannelsXml(data);
  xml += buildProgrammesXml(data);
  xml += "</tv>\n";

  return xml;
}
