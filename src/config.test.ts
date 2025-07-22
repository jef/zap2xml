import { describe, it, expect } from "vitest";
import { processLineupId, getHeadendId } from "./config.js";

describe("processLineupId", () => {
  it("returns env LINEUP_ID if set", () => {
    process.env.LINEUP_ID = "USA-12345";
    expect(processLineupId()).toBe("USA-12345");
    delete process.env.LINEUP_ID;
  });

  it("returns argv --lineupId if set", () => {
    process.argv.push("--lineupId=USA-54321");
    expect(processLineupId()).toBe("USA-54321");
    process.argv = process.argv.filter((arg) => !arg.startsWith("--lineupId="));
  });

  it("returns default if nothing set", () => {
    expect(processLineupId()).toBe("USA-lineupId-DEFAULT");
  });

  it("returns default if lineupId contains OTA", () => {
    process.env.LINEUP_ID = "USA-OTA12345";
    expect(processLineupId()).toBe("USA-lineupId-DEFAULT");
    delete process.env.LINEUP_ID;
  });
});

describe("getHeadendId", () => {
  it("extracts headend from valid lineupId", () => {
    expect(getHeadendId("USA-OTA12345")).toBe("lineupId");
    expect(getHeadendId("USA-NY31587-L")).toBe("NY31587");
    expect(getHeadendId("CAN-OTAT1L0A1")).toBe("lineupId");
    expect(getHeadendId("CAN-0008861-X")).toBe("0008861");
  });

  it("returns 'lineup' if no match", () => {
    expect(getHeadendId("INVALID")).toBe("lineup");
    expect(getHeadendId("")).toBe("lineup");
  });
});
