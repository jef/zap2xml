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
`);
    process.exit(0);
  }
}

async function main() {
  try {
    isHelp();

    console.log("Building XMLTV file");
    console.log(`Config: Country=${config.country}, PostalCode=${config.postalCode}, OutputFile=${config.outputFile}`);
    
    console.log("Fetching TV listings...");
    const data = await getTVListings();
    console.log(`Successfully fetched ${data.channels.length} channels`);
    
    console.log("Building XMLTV content...");
    const xml = buildXmltv(data);
    
    console.log(`Writing XMLTV to ${config.outputFile}...`);
    writeFileSync(config.outputFile, xml, { encoding: "utf-8" });
    console.log("XMLTV file created successfully!");
  } catch (err) {
    console.error("Error fetching or building XMLTV:", err);
    process.exit(1);
  }
}

void main();