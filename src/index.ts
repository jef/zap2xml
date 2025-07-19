import { writeFileSync } from "node:fs";
import { getTVListings } from "./tvlistings.js";
import { buildXmltv } from "./xmltv.js";
import { config } from "./config.js";

function isHelp() {
  if (process.argv.includes("--help")) {
    console.log(`
Usage: node build/index.js [options]

Options:
--help           Show this help message
--lineupId=ID    Lineup ID (default: USA-lineupId-DEFAULT)
--timespan=NUM   Timespan in hours (default: 3)
--pref=LIST      User preferences, comma separated. Can be m, p, and h (default: empty)'
--country=CON    Country code (default: USA)
--postalCode=ZIP Postal code (default: 30309)
--userAgent=UA   Custom user agent string (default: Uses random if not specified)
--timezone=TZ    Timezone (default: America/New_York)
`);
    process.exit(0);
  }
}

async function main() {
  try {
    isHelp();

    const data = await getTVListings();
    const xml = buildXmltv(data);

    console.log("Writing XMLTV file");
    writeFileSync(config.outputFile, xml, { encoding: "utf-8" });
  } catch (err) {
    console.error("Error fetching GridApiResponse:", err);
  }
}

void main();
