# How I approached it

The brief leaves most of the product decisions open, so this file records the calls I made and why. Where I'd normally check with a PM or designer, I've written down the assumption and moved on.

## 1. Framing the problem

The user is someone planning a trip or a weekend. Their real question is "what should I do there this week, and which day?", not "what's the dew point on Thursday?".

That led to three product decisions:

- **Rank the activities, then show the best day for each.** A weekly score on its own hides the one great powder day in an otherwise grim week, and that's often the day that matters.
- **Every score comes with a reason.** "62" means nothing. "Light winds (11 km/h), high of 23°" is something you can trust or argue with. Each scorer returns a one-line summary next to its number.
- **Show the raw daily forecast under the rankings.** That way the scores can be checked against the weather they came from.

## 2. Scoring model

The mental model is a mixing desk. Each activity has a few sliders (snow, cold, wind, sky...). Each slider turns a raw weather value into 0–1 using a simple ramp or comfort band, and the weighted mix gives 0–100 for the day. The week's score is the mean of the days.

On top of the weights, a few **hard caps** stand in for "no amount of sunshine fixes this":

| Activity | Main factors (weight) | Hard rule |
|---|---|---|
| Skiing | fresh snow 0→10 cm (35%), cold: high 6°→-2° (30%), wind 50→20 km/h (20%), visibility (15%) | No new snow and minimum above 0° → capped at 10 |
| Surfing | light wind 40→12 km/h (40%), warmth 8°→24° (25%), dry 10→0 mm (20%), sun 0→8 h (15%) | Thunderstorm → capped at 5 (lightning and open water) |
| Outdoor sightseeing | comfort band 16–26° ±12° (30%), rain chance (20%), rain amount (15%), wind (15%), sky (20%) | Thunderstorm → capped at 15 |
| Indoor sightseeing | 50 + 40% of how bad the outdoor score is | −10 for storms or heavy snow (harder to get around) |

Why this shape:

- **Linear ramps and bands, not a clever model.** They're explainable in a review, tunable by changing one number, and easy to test. I'd tune them with real users or historical data before treating any weight as "right".
- **Indoor is derived from outdoor.** If they were separate, the two could disagree about what bad weather is. Building one on the other keeps them consistent.
- **Mean over the week.** It's simple and rewards consistency. The known weakness (a single standout day gets averaged away) is handled in the UI by showing the best day prominently, rather than by making the maths harder to explain.

The thresholds are judgement calls from general knowledge (lifts often stop around 50 km/h, for example), not researched standards. In a real team I'd check them with someone who skis or surfs.

## 3. Data assumptions and limits

- **Surfing has no wave data.** The brief names the Geocoding and Forecast APIs, and neither has swell. So the surf score answers "is it a nice day to be in the sea?", not "are there waves?". An inland city can score well for surfing, which is wrong. The UI says so in the section footer. **The next thing I'd build** is a call to Open-Meteo's Marine API (same provider, no key): use wave height and period as the main factors, and treat "no marine data for this location" as "not a surf destination".
- **Skiing has no snow base.** Daily forecast variables include snowfall but not snow depth (that's hourly only). A cold, dry day at a resort with a deep base gets under-rated. Hourly `snow_depth` would fix this at the cost of a bigger payload.
- **Missing values.** Open-Meteo returns parallel arrays and any element can be `null`. A day missing its condition or temperatures is dropped, because I'd rather show six honest days than seven with invented numbers. Missing secondary values (wind, rain, sunshine) default to zero, and a missing rain probability falls back to rainfall amount.
- **Time zones.** The request uses `timezone=auto`, so days run midnight to midnight where the place is. All date labels are formatted in that time zone, so "Today" means today in Tokyo when you're looking at Tokyo. A test covers this.
- **Units** are pinned (°C, km/h, mm) even though they're the defaults, so a change to the API defaults can't quietly skew the scores.

## 4. Architecture

```
SwiftUI View ──▶ @Observable ViewModel ──▶ UseCase ──▶ Repository protocol
   (App)          (Features, @MainActor)    (Domain)        (Domain)
                                                               ▲
                                    OpenMeteo services ────────┘ (Services)
                                    CachedForecastRepository (actor) decorates the forecast service
                                    APIClient ──▶ HTTPClient (URLSession)
```

- **Clean Architecture boundaries with MVVM on top.** The domain (models, scorers, use cases) depends only on protocols it defines. Open-Meteo is a detail behind `CityRepository` / `ForecastRepository`. Swapping providers, or adding the Marine API, doesn't touch scoring or UI.
- **Two modules.** Everything except SwiftUI views lives in a local Swift package. The point is speed and discipline: `swift test` runs in seconds with no simulator, and the package can't import SwiftUI by accident. The app target is a thin shell of views, styling and the composition root.
- **Dependency injection.** `AppContainer` is the only place that knows concrete types. It goes into the SwiftUI `Environment` and builds view models through factory methods. Every screen therefore shares the same cache, which is the "data sharing" part: revisiting a city is instant and costs nothing on the network.
- **No third-party dependencies.** Nothing here needed one, and every dependency is something to keep updated.
- **Xcode 16 synchronised folders.** The app target points at the `App/` folder rather than listing every file, so adding a file doesn't touch `project.pbxproj`. That avoids most of the merge conflicts XcodeGen is usually brought in to solve, without the extra tool.

## 5. Concurrency

- **Swift 6 language mode with strict concurrency.** Domain types are `Sendable` value types, view models are `@MainActor`, and services are `Sendable` structs.
- **One actor, used where it earns its place.** `CachedForecastRepository` holds mutable shared state (the cache) that several tasks can reach at once. It also **coalesces in-flight requests**: the first caller's `Task` is stored *before* the first `await`, so a second caller for the same city joins that request instead of starting another. Writing the entry before suspending is what makes this safe under actor re-entrancy, and a test checks that two concurrent calls make one upstream call. Failures are never cached.
- **Search.** A new keystroke cancels the previous task; the debounce is a cancellable `Task.sleep`. After every `await` the view model checks for cancellation, so a slow old response can't overwrite a newer one.
- **Cancellation isn't an error.** `URLError.cancelled` becomes `CancellationError`, and the view models ignore it rather than showing "Something went wrong" when you navigate away mid-load.
- **No `URLResponse` crosses an isolation boundary.** The HTTP seam returns our own `Sendable` `HTTPResponse`.

## 6. Testing

I used Swift Testing (`@Test`, `#expect`, parameterised arguments) against the package:

- **Scorers.** The expected numbers were worked out by hand from the weights, so changing a weight breaks a test on purpose. There are also tests for the caps and the summary wording.
- **Mapping and services.** Trimmed copies of real Open-Meteo payloads, including the "no `results` key" case and `null` values. Tests also check the exact query items sent.
- **API client.** Offline, time-out, cancellation and HTTP-status mapping.
- **Cache actor.** TTL hit and expiry with an injected clock, request coalescing, failures not cached.
- **View models.** Debounce and cancellation (only the last query is searched), empty, error and retry, and "load once even if the view reappears".
- **Time zones.** "Today" depends on the destination.

Not covered: SwiftUI views (snapshot tests would be next) and an end-to-end UI test of search → ranking.

## 7. What I'd do next, in order

1. Marine API for real surf scoring, and to hide surfing for inland places.
2. Hourly `snow_depth` for skiing.
3. Snapshot tests for the cards, plus one UI test of the happy path.
4. Recent searches, saved with SwiftData or `UserDefaults`.
5. Localisation (strings are English and inline for now) and a units setting.
6. Put the scoring weights in a config file so they can be tuned without a release.

## 8. How AI was used

> Fill this in with your own process. The brief says AI use is fine but poor verification isn't, so be specific about what you checked.

- What I generated with AI assistance: …
- What I checked myself and how (ran `swift test`, ran the app against real cities such as Chamonix, Biarritz, Pune and London, compared scores with the daily forecast, checked API field names against the Open-Meteo docs): …
- What I changed or rejected after review: …
