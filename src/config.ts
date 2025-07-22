import { UserAgent } from "./useragents.js";

export function processLineupId(): string {
  const lineupId =
    process.env["LINEUP_ID"] ||
    process.argv.find((arg) => arg.startsWith("--lineupId="))?.split("=")[1] ||
    "USA-lineupId-DEFAULT";

  if (lineupId.includes("OTA")) {
    return "USA-lineupId-DEFAULT";
  }

  return lineupId;
}

export function getHeadendId(lineupId: string): string {
  if (lineupId.includes("OTA")) {
    return "lineupId";
  }

  const match = lineupId.match(/^(USA|CAN)-(.*?)(?:-[A-Z]+)?$/);

  return match?.[2] || "lineup";
}

export function getConfig() {
  const lineupId = processLineupId();
  const headendId = getHeadendId(lineupId);

  return {
    baseUrl: "https://tvlistings.gracenote.com/api/grid",
    lineupId,
    headendId,
    timespan:
      process.env["TIMESPAN"] ||
      process.argv
        .find((arg) => arg.startsWith("--timespan="))
        ?.split("=")[1] ||
      "6",
    country:
      process.env["COUNTRY"] ||
      process.argv.find((arg) => arg.startsWith("--country="))?.split("=")[1] ||
      "USA",
    postalCode:
      process.env["POSTAL_CODE"] ||
      process.argv
        .find((arg) => arg.startsWith("--postalCode="))
        ?.split("=")[1] ||
      "30309",
    pref:
      process.env["PREF"] ||
      process.argv.find((arg) => arg.startsWith("--pref="))?.split("=")[1] ||
      "",
    timezone: process.env.TZ || "America/New_York",
    userAgent:
      process.env["USER_AGENT"] ||
      process.argv
        .find((arg) => arg.startsWith("--userAgent="))
        ?.split("=")[1] ||
      UserAgent,
    outputFile:
      process.env["OUTPUT_FILE"] ||
      process.argv
        .find((arg) => arg.startsWith("--outputFile="))
        ?.split("=")[1] ||
      "xmltv.xml",
  };
}
