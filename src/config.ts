import { UserAgent } from "./useragents.js";

// Inject CLI flags from environment variables
if (process.env["APPEND_ASTERISK"] === "true") {
  process.argv.push("--appendAsterisk");
}

if (process.env["MEDIA_PORTAL"] === "true") {
  process.argv.push("--mediaportal");
}

const validCountries = [
  "ABW", "AIA", "ARG", "ATG", "BHS", "BLZ", "BRA", "BRB", "BMU", "CAN", "COL", "CRI",
  "CUW", "CYM", "DMA", "DOM", "ECU", "GRD", "GTM", "GUY", "HND", "JAM", "KNA", "LCA",
  "MAF", "MEX", "PAN", "PER", "TCA", "TTO", "URY", "USA", "VCT", "VEN", "VGB"
];

export function processLineupId(): string {
  const country =
    process.env["COUNTRY"] ||
    process.argv.find((arg) => arg.startsWith("--country="))?.split("=")[1] ||
    "USA";

  const lineupId =
    process.env["LINEUP_ID"] ||
    process.argv.find((arg) => arg.startsWith("--lineupId="))?.split("=")[1] ||
    `${country}-lineupId-DEFAULT`;

  if (!validCountries.includes(country)) {
    throw new Error(`Invalid country code: ${country}`);
  }

  if (lineupId.includes("OTA")) {
    return `${country}-lineupId-DEFAULT`;
  }

  return lineupId;
}

export function getHeadendId(lineupId: string): string {
  if (lineupId.includes("OTA")) {
    return "lineupId";
  }

  const match = lineupId.match(/^(?:[A-Z]{3})-(.*?)(?:-[A-Z]+)?$/);

  return match?.[1] || "lineup";
}

export function getConfig() {
  const lineupId = processLineupId();
  const headendId = getHeadendId(lineupId);

  const country =
    process.env["COUNTRY"] ||
    process.argv.find((arg) => arg.startsWith("--country="))?.split("=")[1] ||
    "USA";

  if (!validCountries.includes(country)) {
    throw new Error(`Invalid country code: ${country}`);
  }

  return {
    baseUrl: "https://tvlistings.gracenote.com/api/grid",
    lineupId,
    headendId,
    timespan:
      process.env["TIMESPAN"] ||
      process.argv
        .find((arg) => arg.startsWith("--timespan="))
        ?.split("=")[1] ||
      "72",
    country,
    postalCode:
      process.env["POSTAL_CODE"] ||
      process.argv
        .find((arg) => arg.startsWith("--postalCode="))
        ?.split("=")[1] ||
      "-",
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
