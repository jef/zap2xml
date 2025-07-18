import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { GridApiResponse } from "./tvlistings.js";
import { getTVListings } from "./tvlistings.js";

// Mock fetch globally
const mockFetch = vi.fn();
global.fetch = mockFetch;

const mockGridApiResponse: GridApiResponse = {
  channels: [
    {
      callSign: "KOMODT",
      affiliateName: "AMERICAN BROADCASTING COMPANY",
      affiliateCallSign: null,
      channelId: "19629",
      channelNo: "4.1",
      events: [
        {
          callSign: "KOMODT",
          duration: "60",
          startTime: "2025-07-18T19:00:00Z",
          endTime: "2025-07-18T20:00:00Z",
          thumbnail: "p30687311_b_v13_aa",
          channelNo: "4.1",
          filter: ["filter-news"],
          seriesId: "SH05918266",
          rating: "TV-PG",
          flag: ["New"],
          tags: ["Stereo", "CC"],
          program: {
            title: "GMA3",
            id: "EP059182660025",
            tmsId: "EP059182660025",
            shortDesc:
              "BIA performs; comic Zarna Garg; lifestyle contributor Lori Bergamotto; ABC News chief medical correspondent Dr. Tara Narula.",
            season: "5",
            releaseYear: null,
            episode: "217",
            episodeTitle: "Special Episode",
            seriesId: "SH05918266",
            isGeneric: "0",
          },
        },
      ],
      id: "196290",
      stationGenres: [false],
      stationFilters: ["filter-news", "filter-talk"],
      thumbnail:
        "//zap2it.tmsimg.com/h3/NowShowing/19629/s28708_ll_h15_ac.png?w=55",
    },
  ],
};

describe("getTVListings", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("should successfully fetch TV listings", async () => {
    // Mock successful response
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockGridApiResponse,
    });

    const url = "https://tvlistings.gracenote.com/api/grid?test=123";
    const result = await getTVListings(url);

    expect(mockFetch).toHaveBeenCalledWith(url, {
      headers: {
        "User-Agent": expect.any(String),
      },
    });
    expect(result).toEqual(mockGridApiResponse);
    expect(result.channels).toHaveLength(1);
    expect(result.channels[0].callSign).toBe("KOMODT");
  });

  it("should include a User-Agent header in the request", async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockGridApiResponse,
    });

    await getTVListings("https://example.com/api");

    expect(mockFetch).toHaveBeenCalledWith("https://example.com/api", {
      headers: {
        "User-Agent": expect.any(String),
      },
    });

    const callArgs = mockFetch.mock.calls[0];
    const headers = callArgs[1].headers;
    expect(headers["User-Agent"]).toBeDefined();
    expect(typeof headers["User-Agent"]).toBe("string");
    expect(headers["User-Agent"].length).toBeGreaterThan(0);
  });

  it("should use a random User-Agent from the predefined list", async () => {
    const expectedUserAgents = [
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0",
      "Mozilla/5.0 (Linux; Android 13; SM-G991U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36",
      "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
    ];

    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockGridApiResponse,
    });

    await getTVListings("https://example.com/api");

    const callArgs = mockFetch.mock.calls[0];
    const userAgent = callArgs[1].headers["User-Agent"];
    expect(expectedUserAgents).toContain(userAgent);
  });

  it("should throw an error when response is not ok (4xx status)", async () => {
    mockFetch.mockResolvedValueOnce({
      ok: false,
      status: 404,
      statusText: "Not Found",
    });

    const url = "https://example.com/api";

    await expect(getTVListings(url)).rejects.toThrow(
      "Failed to fetch: 404 Not Found",
    );
    expect(mockFetch).toHaveBeenCalledWith(url, {
      headers: {
        "User-Agent": expect.any(String),
      },
    });
  });

  it("should throw an error when response is not ok (5xx status)", async () => {
    mockFetch.mockResolvedValueOnce({
      ok: false,
      status: 500,
      statusText: "Internal Server Error",
    });

    const url = "https://example.com/api";

    await expect(getTVListings(url)).rejects.toThrow(
      "Failed to fetch: 500 Internal Server Error",
    );
  });

  it("should throw an error when response is not ok (3xx status)", async () => {
    mockFetch.mockResolvedValueOnce({
      ok: false,
      status: 301,
      statusText: "Moved Permanently",
    });

    const url = "https://example.com/api";

    await expect(getTVListings(url)).rejects.toThrow(
      "Failed to fetch: 301 Moved Permanently",
    );
  });

  it("should handle empty channels array", async () => {
    const emptyResponse: GridApiResponse = {
      channels: [],
    };

    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => emptyResponse,
    });

    const result = await getTVListings("https://example.com/api");
    expect(result).toEqual(emptyResponse);
    expect(result.channels).toHaveLength(0);
  });

  it("should handle multiple channels in response", async () => {
    const multiChannelResponse: GridApiResponse = {
      channels: [
        {
          callSign: "KOMODT",
          affiliateName: "AMERICAN BROADCASTING COMPANY",
          affiliateCallSign: null,
          channelId: "19629",
          channelNo: "4.1",
          events: [],
          id: "196290",
          stationGenres: [],
          stationFilters: [],
          thumbnail: "",
        },
        {
          callSign: "KOMODT2",
          affiliateName: "AMERICAN BROADCASTING COMPANY",
          affiliateCallSign: null,
          channelId: "19630",
          channelNo: "4.2",
          events: [],
          id: "196300",
          stationGenres: [],
          stationFilters: [],
          thumbnail: "",
        },
      ],
    };

    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => multiChannelResponse,
    });

    const result = await getTVListings("https://example.com/api");
    expect(result.channels).toHaveLength(2);
    expect(result.channels[0].callSign).toBe("KOMODT");
    expect(result.channels[1].callSign).toBe("KOMODT2");
  });

  it("should handle network errors", async () => {
    const networkError = new Error("Network error");
    mockFetch.mockRejectedValueOnce(networkError);

    const url = "https://example.com/api";

    await expect(getTVListings(url)).rejects.toThrow("Network error");
  });

  it("should handle JSON parsing errors", async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => {
        throw new Error("Invalid JSON");
      },
    });

    const url = "https://example.com/api";

    await expect(getTVListings(url)).rejects.toThrow("Invalid JSON");
  });

  it("should handle malformed JSON response", async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => {
        throw new SyntaxError("Unexpected token < in JSON at position 0");
      },
    });

    const url = "https://example.com/api";

    await expect(getTVListings(url)).rejects.toThrow(
      "Unexpected token < in JSON at position 0",
    );
  });

  it("should preserve the exact URL passed to the function", async () => {
    const testUrl =
      "https://tvlistings.gracenote.com/api/grid?lineupId=USA-lineupId-DEFAULT&timespan=3&headendId=lineupId&country=USA&timezone=&device=-&postalCode=98107&isOverride=true&time=1752865200&pref=16,128&userId=-&aid=orbebb&languagecode=en-us";

    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockGridApiResponse,
    });

    await getTVListings(testUrl);

    expect(mockFetch).toHaveBeenCalledWith(testUrl, {
      headers: {
        "User-Agent": expect.any(String),
      },
    });
  });
});
