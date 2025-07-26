import { getConfig } from "./config.js";

const config = getConfig();

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
  /** Add this if originalAirDate exists in your data */
  originalAirDate?: string;
  /** Genres extracted from filter or details */
  genres?: string[];
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
  filter?: string[];
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
  /** "thumbnail": "//zap2it.tmsimg.com/h3/NowShowing/19629/s28708_ll_h15_ac.png" */
  thumbnail: string;
}

export interface GridApiResponse {
  /** "channels": [...] */
  channels: Channel[];
}

function buildUrl(time: number, timespan: number): string {
  const params = {
    lineupId: config.lineupId,
    timespan: timespan.toString(),
    headendId: config.headendId,
    country: config.country,
    timezone: config.timezone,
    postalCode: config.postalCode,
    isOverride: "true",
    pref: config.pref + "16,128" || "16,128",
    aid: "orbebb",
    languagecode: "en-us",
    time: time.toString(),
    device: "X",
    userId: "-",
  };

  const urlParams = new URLSearchParams(params).toString();

  return `${config.baseUrl}?${urlParams}`;
}

export async function getTVListings(): Promise<GridApiResponse> {
  const totalHours = parseInt(config.timespan, 10);
  const chunkHours = 6;
  const now = Math.floor(Date.now() / 1000);
  const channelsMap: Map<string, Channel> = new Map();

  const fetchPromises: Promise<void>[] = [];

  for (let offset = 0; offset < totalHours; offset += chunkHours) {
    const time = now + offset * 3600;
    const url = buildUrl(time, chunkHours);

    const fetchPromise = fetch(url, {
      headers: {
        "User-Agent": config.userAgent || "",
      },
    })
      .then(async (response) => {
        if (!response.ok) {
          // Keep critical error logging for failed fetches, but remove debug noise
          const errorBody = await response.text();
          throw new Error(
            `Failed to fetch URL ${url}: ${response.status} ${response.statusText} - ${errorBody.substring(0, 200)}...`,
          );
        }
        return response.json() as Promise<GridApiResponse>;
      })
      .then((chunkData: GridApiResponse) => {
        for (const newChannel of chunkData.channels) {
          const processedEvents = newChannel.events.map(event => {
            const newProgram = { ...event.program };
            const currentGenres = new Set<string>(newProgram.genres || []);

            // Process genres from event.filter first
            if (event.filter && event.filter.length > 0) {
              event.filter.forEach(filterTag => {
                const genre = filterTag.replace(/filter-/i, '').toLowerCase();
                if (genre) {
                  currentGenres.add(genre);
                }
              });
            }

            // Apply the --includeSeriesGenre logic:
            // Add 'series' ONLY if the option is enabled,
            // AND it's not a movie,
            // AND NO other genres have been found from the 'filter' array yet.
            const isMovie = newProgram.id?.startsWith('MV');

            if (config.includeSeriesGenre && currentGenres.size === 0 && !isMovie) {
                // Ensure it's explicitly a series if seriesId is present and not '0'
                if (newProgram.seriesId && newProgram.seriesId !== '0') {
                    currentGenres.add('series');
                }
            }

            newProgram.genres = Array.from(currentGenres);

            return { ...event, program: newProgram };
          });

          if (!channelsMap.has(newChannel.channelId)) {
            channelsMap.set(newChannel.channelId, {
              ...newChannel,
              events: processedEvents,
            });
          } else {
            const existingChannel = channelsMap.get(newChannel.channelId)!;
            existingChannel.events.push(...processedEvents);
          }
        }
      })
      .catch(fetchError => {
        // Re-throw to ensure the main() function catches this error
        throw fetchError;
      });

    fetchPromises.push(fetchPromise);
  }

  await Promise.all(fetchPromises);

  return { channels: Array.from(channelsMap.values()) };
}