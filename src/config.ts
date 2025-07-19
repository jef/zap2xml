import { UserAgent } from "./useragents.js";

export const config = {
  baseUrl: "https://tvlistings.gracenote.com/api/grid",
  lineupId:
    process.env["LINEUP_ID"] ||
    process.argv.find((arg) => arg.startsWith("--lineupId="))?.split("=")[1] ||
    "USA-lineupId-DEFAULT",
  timespan:
    process.env["TIMESPAN"] ||
    process.argv.find((arg) => arg.startsWith("--timespan="))?.split("=")[1] ||
    "3",
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
    process.argv.find((arg) => arg.startsWith("--userAgent="))?.split("=")[1] ||
    UserAgent,
  outputFile:
    process.env["OUTPUT_FILE"] ||
    process.argv
      .find((arg) => arg.startsWith("--outputFile="))
      ?.split("=")[1] ||
    "xmltv.xml",
};
