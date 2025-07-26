import { writeFileSync } from "node:fs";
import { getTVListings } from "./tvlistings.js";
import { buildXmltv } from "./xmltv.js";
import { getConfig } from "./config.js";

const config = getConfig();

function isHelp() {
  if (process.argv.includes("--help")) {
    console.log(`
Usage: node dist/index.js [options]

Options:
--help           Show this help message
--lineupId=ID    Lineup ID (default: USA-lineupId-DEFAULT)
--timespan=NUM   Timespan in hours (up to 360 = 15 days, default: 6)
--pref=LIST      User preferences, comma separated. Can be m, p, and h (default: empty)'
--country=CON    Country code (default: USA)
--postalCode=ZIP Postal code (default: 30309)
--userAgent=UA   Custom user agent string (default: Uses random if not specified)
--timezone=TZ    Timezone (default: America/New_York)
--includeSeriesGenre Add "series" category to all non-movie programs if no other category is found
`);
    process.exit(0);
  }
}

async function main() {
  try {
    isHelp();

    // getTVListings now internally uses 'config', so no arguments needed here
    const data = await getTVListings();
    const xml = buildXmltv(data);

    writeFileSync(config.outputFile, xml, { encoding: "utf-8" });
  } catch (err) {
    console.error("Error fetching or building XMLTV:", err);
    process.exit(1); // Exit with a non-zero code to indicate an error
  }
}

void main();