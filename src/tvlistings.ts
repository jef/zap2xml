import { config } from "./config.js";

export interface Program {
  /** "title": "GMA3" */
  title: string;
  /** "id": "EP059182660025" */
  id: string;
  /** "tmsId": "EP059182660025" */
  tmsId: string;
  /** "shortDesc": "BIA performs; comic Zarna Garg; lifestyle contributor Lori Bergamotto; ABC News chief medical correspondent Dr. Tara Narula." */
  shortDesc: string;
  /** "season": "5" */
  season: string;
  /** "releaseYear": null */
  releaseYear: string | null;
  /** "episode": "217" */
  episode: string;
  /** "episodeTitle": null */
  episodeTitle: string | null;
  /** "seriesId": "SH05918266" */
  seriesId: string;
  /** "isGeneric": "0" */
  isGeneric: string;
}

export interface Event {
  /** "callSign": "KOMODT" */
  callSign: string;
  /** "duration": "60" */
  duration: string;
  /** "startTime": "2025-07-18T19:00:00Z" */
  startTime: string;
  /** "endTime": "2025-07-18T20:00:00Z" */
  endTime: string;
  /** "thumbnail": "p30687311_b_v13_aa" */
  thumbnail: string;
  /** "channelNo": "4.1" */
  channelNo: string;
  /** "filter": ["filter-news"] */
  filter: string[];
  /** "seriesId": "SH05918266" */
  seriesId: string;
  /** "rating": "TV-PG" */
  rating: string;
  /** "flag": ["New"] */
  flag: string[];
  /** "tags": ["Stereo", "CC"] */
  tags: string[];
  /** "program": {...} */
  program: Program;
}

export interface Channel {
  /** "callSign": "KOMODT" */
  callSign: string;
  /** "affiliateName": "AMERICAN BROADCASTING COMPANY" */
  affiliateName: string;
  /** "affiliateCallSign": "null" */
  affiliateCallSign: string | null;
  /** "channelId": "19629" */
  channelId: string;
  /** "channelNo": "4.1" */
  channelNo: string;
  /** "events": [...] */
  events: Event[];
  /** "id": "196290" */
  id: string;
  /** "stationGenres": [false] */
  stationGenres: boolean[];
  /** "stationFilters": ["filter-news", "filter-talk"] */
  stationFilters: string[];
  /** "thumbnail": "//zap2it.tmsimg.com/h3/NowShowing/19629/s28708_ll_h15_ac.png?w=55" */
  thumbnail: string;
}

export interface GridApiResponse {
  /** "channels": [...] */
  channels: Channel[];
}

function buildUrl() {
  const params = {
    lineupId: config.lineupId,
    timespan: config.timespan,
    headendId: "lineupId",
    country: config.country,
    timezone: config.timezone,
    postalCode: config.postalCode,
    isOverride: "true",
    pref: config.pref + "16,128" || "16,128",
    aid: "orbebb",
    languagecode: "en-us",
    time: Math.floor(Date.now() / 1000).toString(),
  };

  const urlParams = new URLSearchParams(params).toString();

  return `${config.baseUrl}?${urlParams}`;
}

export async function getTVListings(): Promise<GridApiResponse> {
  console.log("Fetching TV listings");

  const url = buildUrl();

  const response = await fetch(url, {
    headers: {
      "User-Agent": config.userAgent || "",
    },
  });

  if (!response.ok) {
    throw new Error(
      `Failed to fetch: ${response.status} ${response.statusText}`,
    );
  }

  return (await response.json()) as GridApiResponse;
}
